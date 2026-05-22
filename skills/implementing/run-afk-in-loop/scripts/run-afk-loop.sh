#!/usr/bin/env bash
# Wraps a claude session running /run-afk-in-loop.
# Detects credit exhaustion from output and retries after a wait.
#
# Env vars:
#   CLAUDE_CMD                    override the claude binary (default: claude)
#   RETRY_WAIT_SECONDS            wait for transient errors / no reset hint (default: 1800)
#   SESSION_LIMIT_WAIT_SECONDS    fallback wait when limit has no parsable reset (default: 21600)
#   WAIT_DISABLED                 set to 1 to skip the pause (tests)
#   MAX_ATTEMPTS                  max total attempts before giving up (default: 20)
set -euo pipefail

CLAUDE_CMD="${CLAUDE_CMD:-claude}"
RETRY_WAIT="${RETRY_WAIT_SECONDS:-1800}"
SESSION_LIMIT_WAIT="${SESSION_LIMIT_WAIT_SECONDS:-21600}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-limit-wait.sh
. "$SCRIPT_DIR/lib-limit-wait.sh"

log() { echo "[run-afk-loop] $*"; }

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  log "attempt $attempt / $MAX_ATTEMPTS"

  set +e
  output=$("$CLAUDE_CMD" --dangerously-skip-permissions --print "/run-afk-in-loop" 2>&1)
  exit_code=$?
  set -e

  printf '%s\n' "$output"

  if [ "$exit_code" -eq 0 ]; then
    log "done"
    exit 0
  fi

  wait_seconds=$(detect_limit_wait_seconds "$output" "$RETRY_WAIT" "$SESSION_LIMIT_WAIT")
  if [ -n "$wait_seconds" ]; then
    log "usage limit detected"
    pause_with_heartbeat "$wait_seconds" "run-afk-loop"
    continue
  fi

  log "unexpected exit (code $exit_code) — stopping"
  exit "$exit_code"
done

log "max attempts ($MAX_ATTEMPTS) reached without completion"
exit 1
