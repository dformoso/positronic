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

# Pre-flight: worktree commits will fail loudly mid-wave without identity.
# Fail fast here with a clearer message than git's "Please tell me who you are".
if [ "$AFK_WORKTREE" = "1" ]; then
  if ! "$GIT_CMD" config user.email >/dev/null 2>&1 \
     || ! "$GIT_CMD" config user.name  >/dev/null 2>&1; then
    log "git user.name and user.email must be set before launching a wave."
    log "Run: git config --global user.email \"you@example.com\""
    log "     git config --global user.name  \"Your Name\""
    exit 1
  fi
fi

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
    done < <(echo "$body" | grep -ioE 'Blocked by #[0-9]+' | grep -oE '[0-9]+$' || true)
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
    local head_sha
    head_sha=$("$GIT_CMD" rev-parse HEAD 2>/dev/null || echo "")
    "$GH_CMD" issue close "$num" --comment "Completed by /run-afk-in-loop${head_sha:+ in $head_sha}"
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
    local merge_sha
    merge_sha=$("$GIT_CMD" rev-parse HEAD)
    "$GH_CMD" issue close "$num" --comment "Completed by /run-afk-in-loop in $merge_sha"
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
        # Print the reason that follows the LAST blocked marker, in case the
        # agent quoted the preamble (with placeholder text) earlier in its output.
        reason=$(awk '
          /^=== AFK-RESULT: blocked ===$/ { found=1; next }
          found && /^Reason:/ { sub(/^Reason:[[:space:]]*/, ""); current=$0; found=0 }
          END { print current }
        ' "$log_file" 2>/dev/null)
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

  total_afk=$(echo "$issues_json" | jq '[.[] | select(.labels[].name == "afk")] | length')
  done_afk=$(echo "$issues_json" | jq '[.[] | select(.labels[].name == "afk" and .state == "CLOSED")] | length')

  spec_path=""; prd_path=""
  [ -d specs ] && spec_path=$(ls specs/[0-9]*.md 2>/dev/null | sort -V | tail -1 || true)
  [ -d prds ]  && prd_path=$(ls prds/[0-9]*.md  2>/dev/null | sort -V | tail -1 || true)

  n=${#wave[@]}
  log "Wave $((done_afk + 1))..$((done_afk + n))/$total_afk — $n issues:"
  for num in "${wave[@]}"; do
    title=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
    body=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .body // ""')
    what=$(echo "$body"     | awk '/^## What to build/{f=1;next}/^## /{f=0}f && NF{print;exit}')
    exemplar=$(echo "$body" | awk '/^## Exemplar to mirror/{f=1;next}/^## /{f=0}f && NF{print;exit}')
    decisions=$(echo "$body"| awk '/^## Decisions taken/{f=1;next}/^## /{f=0}f && NF{print;exit}')
    echo "  #${num} — ${title}"
    [ -n "$what" ]      && echo "    What to build: ${what}"
    [ -n "$exemplar" ]  && echo "    Exemplar to mirror: ${exemplar}"
    [ -n "$decisions" ] && echo "    Decisions taken: ${decisions}"
    if [ -n "$spec_path" ] || [ -n "$prd_path" ]; then
      sep=""; [ -n "$spec_path" ] && [ -n "$prd_path" ] && sep=", "
      echo "    Source documents: ${spec_path}${sep}${prd_path}"
    fi
  done

  declare -A num_to_title
  declare -A pid_to_num
  pids=()
  first=1
  for num in "${wave[@]}"; do
    title=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
    num_to_title["$num"]="$title"
    # Stagger spawns to avoid a synchronized burst against the API.
    [ "$first" = "1" ] && first=0 || sleep 0.3
    bash "$IMPL_SCRIPT" "$num" "$title" > "$LOGS_DIR/issue-${num}.log" 2>&1 &
    pid=$!
    pids+=("$pid")
    pid_to_num["$pid"]="$num"
  done

  # Heartbeat: every 60s, name which wave issues are still running.
  # Closes the AGENTS.md §7 "show progress for >2s ops" gap — without it the
  # orchestrator goes silent for the duration of the slowest agent.
  wave_started=$(date +%s)
  (
    while sleep 60; do
      elapsed_min=$(( ($(date +%s) - wave_started) / 60 ))
      still=""
      for p in "${pids[@]}"; do
        if kill -0 "$p" 2>/dev/null; then
          still+="${still:+ }#${pid_to_num[$p]}"
        fi
      done
      [ -n "$still" ] && echo "[run-parallel] still running (${elapsed_min}m elapsed): $still"
    done
  ) &
  hb_pid=$!

  declare -A num_to_exit
  for pid in "${pids[@]}"; do
    set +e
    wait "$pid"
    code=$?
    set -e
    num_to_exit["${pid_to_num[$pid]}"]=$code
  done

  kill "$hb_pid" 2>/dev/null || true
  wait "$hb_pid" 2>/dev/null || true

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
