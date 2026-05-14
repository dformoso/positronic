#!/usr/bin/env bash
# Parallel AFK wave executor.
# Identifies all unblocked open AFK issues, fans out to up to CONCURRENCY
# implement-issue.sh subprocesses (one per issue, each in its own worktree),
# then sequentially merges + closes successful issues before launching the next
# wave. Merge conflicts and blocked/failed issues are surfaced and left for
# manual inspection.
#
# Env vars:
#   CLAUDE_CMD          override claude binary (default: claude)
#   GH_CMD              override gh binary (default: gh)
#   GIT_CMD             override git binary (default: git)
#   CONCURRENCY         max parallel processes per wave (default: 4)
#   RETRY_WAIT_SECONDS  seconds between credit-exhaustion retries (default: 1800)
#   MAX_ATTEMPTS        max attempts per issue (default: 3)
#   IMPL_SCRIPT         override implement-issue.sh path (for testing)
#   LOGS_DIR            override per-issue logs dir (default: /tmp/afk-logs-$$)
#   AFK_WORKTREE        set to 0 to skip worktree + merge (default: 1)
set -euo pipefail

GH_CMD="${GH_CMD:-gh}"
GIT_CMD="${GIT_CMD:-git}"
CLAUDE_CMD="${CLAUDE_CMD:-claude}"
CONCURRENCY="${CONCURRENCY:-4}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPL_SCRIPT="${IMPL_SCRIPT:-"$SCRIPTS_DIR/implement-issue.sh"}"
LOGS_DIR="${LOGS_DIR:-/tmp/afk-logs-$$}"
AFK_WORKTREE="${AFK_WORKTREE:-1}"
export CLAUDE_CMD GH_CMD GIT_CMD AFK_WORKTREE

mkdir -p "$LOGS_DIR"

log() { echo "[run-parallel] $*"; }

# Print unblocked open AFK issue numbers, one per line.
get_unblocked() {
  local issues_json="$1"
  while IFS= read -r num; do
    [ -z "$num" ] && continue
    local body blocked=false
    body=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .body // ""')
    while IFS= read -r b; do
      [ -z "$b" ] && continue
      local bs
      bs=$(echo "$issues_json" | jq -r --argjson b "$b" '.[] | select(.number == $b) | .state')
      [ "$bs" = "OPEN" ] && blocked=true && break
    done < <(echo "$body" | grep -oE 'Blocked by #[0-9]+' | grep -oE '[0-9]+$' || true)
    $blocked || echo "$num"
  done < <(echo "$issues_json" | \
    jq -r '.[] | select(.labels[].name == "afk" and .state == "OPEN") | .number')
}

# integrate_issue <num> <title>
# Merges afk/issue-<num> into current HEAD, then closes the issue and removes
# the worktree. Returns non-zero on merge conflict or empty branch; the
# orchestrator surfaces the failure and leaves state intact for inspection.
integrate_issue() {
  local num="$1" title="$2"
  local branch="afk/issue-${num}"

  if [ "$AFK_WORKTREE" != "1" ]; then
    "$GH_CMD" issue close "$num" --comment "Completed by /run-afk-in-loop"
    return 0
  fi

  if ! "$GIT_CMD" rev-parse --verify "$branch" >/dev/null 2>&1; then
    log "#${num}: branch ${branch} not found — agent did not create one"
    return 1
  fi

  local base_sha head_sha
  base_sha=$("$GIT_CMD" merge-base HEAD "$branch" 2>/dev/null || echo "")
  head_sha=$("$GIT_CMD" rev-parse "$branch")
  if [ "$base_sha" = "$head_sha" ]; then
    log "#${num}: branch ${branch} has no commits beyond base — nothing to merge"
    return 1
  fi

  if "$GIT_CMD" merge --no-ff --no-edit -m "Merge afk/issue-${num}: ${title}" "$branch" >/dev/null 2>&1; then
    "$GH_CMD" issue close "$num" --comment "Completed by /run-afk-in-loop"
    local worktree_base worktree
    worktree_base="${WORKTREE_BASE:-$(dirname "$("$GIT_CMD" rev-parse --show-toplevel)")}"
    worktree="$worktree_base/wt-issue-${num}"
    "$GIT_CMD" worktree remove "$worktree" --force >/dev/null 2>&1 || true
    "$GIT_CMD" branch -d "$branch" >/dev/null 2>&1 || true
    return 0
  fi

  "$GIT_CMD" merge --abort >/dev/null 2>&1 || true
  log "#${num}: merge conflict on ${branch} — worktree preserved for inspection"
  return 1
}

# print_outcome <num> <title> <impl_exit_code> <log_file>
print_outcome() {
  local num="$1" title="$2" code="$3" log_file="$4"
  echo "─── #${num} — ${title} ───"
  case "$code" in
    0)  echo "Outcome: ✓ agent succeeded (marker present)" ;;
    2)  local reason
        reason=$(grep -A1 '^=== AFK-RESULT: blocked ===$' "$log_file" 2>/dev/null \
                 | tail -1 | sed 's/^Reason:[[:space:]]*//')
        echo "Outcome: ⏸ blocked — ${reason:-<no reason given>}" ;;
    *)  echo "Outcome: ✗ failed (exit ${code}, no marker)" ;;
  esac
  echo "Tail of agent output:"
  tail -10 "$log_file" 2>/dev/null || true
  echo "───"
}

# ── main loop ─────────────────────────────────────────────────────────────────

while true; do
  issues_json=$(${GH_CMD} issue list --state all --json number,title,body,state,labels --limit 100)

  wave=()
  while IFS= read -r num; do
    wave+=("$num")
    [ "${#wave[@]}" -ge "$CONCURRENCY" ] && break
  done < <(get_unblocked "$issues_json")

  if [ "${#wave[@]}" -eq 0 ]; then
    log "All AFK issues complete."
    open_hitl=$(echo "$issues_json" | \
      jq -r '.[] | select(.labels[].name == "hitl" and .state == "OPEN") | "  #\(.number) — \(.title)"' || true)
    remaining=$(echo "$issues_json" | \
      jq -r '.[] | select(.labels[].name == "afk" and .state == "OPEN") | "  #\(.number) — \(.title)"' || true)
    [ -n "$open_hitl" ] && echo "Awaiting your input (HITL):" && echo "$open_hitl"
    [ -n "$remaining" ] && echo "Blocked (waiting on HITL):" && echo "$remaining"
    break
  fi

  log "Wave: ${wave[*]}"

  declare -A num_to_title
  declare -A pid_to_num
  pids=()
  for num in "${wave[@]}"; do
    title=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
    num_to_title["$num"]="$title"
    bash "$IMPL_SCRIPT" "$num" "$title" > "$LOGS_DIR/issue-${num}.log" 2>&1 &
    pid=$!
    pids+=("$pid")
    pid_to_num["$pid"]="$num"
  done

  declare -A num_to_exit
  for pid in "${pids[@]}"; do
    set +e
    wait "$pid"
    code=$?
    set -e
    num_to_exit["${pid_to_num[$pid]}"]=$code
  done

  marks=()
  for num in "${wave[@]}"; do
    title="${num_to_title[$num]}"
    code="${num_to_exit[$num]}"
    print_outcome "$num" "$title" "$code" "$LOGS_DIR/issue-${num}.log"

    if [ "$code" -eq 0 ]; then
      if integrate_issue "$num" "$title"; then
        marks+=("#${num} ✓")
      else
        marks+=("#${num} ✗ merge")
      fi
    elif [ "$code" -eq 2 ]; then
      marks+=("#${num} ⏸ blocked")
    else
      marks+=("#${num} ✗ failed")
    fi
  done

  log "Wave complete — ${marks[*]}"
  unset num_to_title pid_to_num num_to_exit
done
