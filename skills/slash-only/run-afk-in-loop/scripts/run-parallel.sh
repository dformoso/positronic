#!/usr/bin/env bash
# Parallel AFK wave executor.
# Identifies all unblocked open AFK issues, fans out to up to CONCURRENCY
# claude processes in parallel (one per issue), waits for the wave, then
# re-evaluates and launches the next wave.
#
# Env vars:
#   CLAUDE_CMD          override claude binary (default: claude)
#   GH_CMD              override gh binary (default: gh)
#   CONCURRENCY         max parallel processes per wave (default: 4)
#   RETRY_WAIT_SECONDS  seconds between credit-exhaustion retries (default: 1800)
#   MAX_ATTEMPTS        max attempts per issue (default: 3)
#   IMPL_SCRIPT         override implement-issue.sh path (for testing)
set -euo pipefail

GH_CMD="${GH_CMD:-gh}"
CLAUDE_CMD="${CLAUDE_CMD:-claude}"
CONCURRENCY="${CONCURRENCY:-4}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPL_SCRIPT="${IMPL_SCRIPT:-"$SCRIPTS_DIR/implement-issue.sh"}"
export CLAUDE_CMD GH_CMD

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

# ── main loop ─────────────────────────────────────────────────────────────────

while true; do
  issues_json=$(${GH_CMD} issue list --state all --json number,title,body,state,labels --limit 100)

  wave=()
  while IFS= read -r num; do
    wave+=("$num")
    [ "${#wave[@]}" -ge "$CONCURRENCY" ] && break
  done < <(get_unblocked "$issues_json")

  if [ "${#wave[@]}" -eq 0 ]; then
    ISSUES_JSON="$issues_json" bash "$SCRIPTS_DIR/update-board.sh" 2>/dev/null || true
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
  ACTIVE_ISSUES="${wave[*]}" ISSUES_JSON="$issues_json" \
    bash "$SCRIPTS_DIR/update-board.sh" 2>/dev/null || true

  pids=()
  for num in "${wave[@]}"; do
    title=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
    bash "$IMPL_SCRIPT" "$num" "$title" &
    pids+=($!)
  done

  for pid in "${pids[@]}"; do
    wait "$pid" || true
  done
done
