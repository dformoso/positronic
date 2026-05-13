#!/usr/bin/env bash
# Wraps a claude session running /run-afk-in-loop.
# Detects credit exhaustion from output and retries after a wait.
#
# Env vars:
#   CLAUDE_CMD          override the claude binary (default: claude)
#   RETRY_WAIT_SECONDS  seconds to wait after credit exhaustion (default: 1800)
#   MAX_ATTEMPTS        max total attempts before giving up (default: 20)
set -euo pipefail

CLAUDE_CMD="${CLAUDE_CMD:-claude}"
RETRY_WAIT="${RETRY_WAIT_SECONDS:-1800}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-20}"

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

  if echo "$output" | grep -qiE "credit|insufficient.fund|quota|overload|rate.limit"; then
    log "credit exhaustion detected — waiting ${RETRY_WAIT}s"
    sleep "$RETRY_WAIT"
    continue
  fi

  log "unexpected exit (code $exit_code) — stopping"
  exit "$exit_code"
done

log "max attempts ($MAX_ATTEMPTS) reached without completion"
exit 1
