#!/usr/bin/env bash
# Implements a single AFK GitHub issue by invoking /tdd, then closes it.
# Retries on credit exhaustion up to MAX_ATTEMPTS times.
#
# Usage: implement-issue.sh <issue-number> <title>
#
# Env vars:
#   CLAUDE_CMD          override claude binary (default: claude)
#   GH_CMD              override gh binary (default: gh)
#   MAX_ATTEMPTS        max attempts before giving up (default: 3)
#   RETRY_WAIT_SECONDS  seconds between credit-exhaustion retries (default: 1800)
set -euo pipefail

NUM="$1"
TITLE="$2"
CLAUDE_CMD="${CLAUDE_CMD:-claude}"
GH_CMD="${GH_CMD:-gh}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
RETRY_WAIT="${RETRY_WAIT_SECONDS:-1800}"

log() { echo "[implement-issue] $*"; }

criteria=$(${GH_CMD} issue view "${NUM}" --json body | jq -r '.body' | \
  awk '/^## Acceptance criteria/{f=1;next} f && /^## /{exit} f && /- \[/{print}')

prompt="Implement GitHub issue #${NUM}: ${TITLE}

Acceptance criteria:
${criteria}"

attempt=0
while [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
  attempt=$((attempt + 1))
  set +e
  output=$("${CLAUDE_CMD}" --dangerously-skip-permissions --print "/tdd ${prompt}" 2>&1)
  exit_code=$?
  set -e

  printf '%s\n' "$output"

  if [ "$exit_code" -eq 0 ]; then
    ${GH_CMD} issue close "${NUM}" --comment "Completed by /run-afk-in-loop"
    log "#${NUM} closed ✓"
    exit 0
  fi

  if echo "$output" | grep -qiE "credit|insufficient.fund|quota|overload|rate.limit"; then
    log "#${NUM}: credit exhaustion — waiting ${RETRY_WAIT}s (attempt ${attempt}/${MAX_ATTEMPTS})"
    sleep "${RETRY_WAIT}"
    continue
  fi

  log "#${NUM}: failed (exit ${exit_code}, attempt ${attempt}/${MAX_ATTEMPTS})"
  exit 1
done

log "#${NUM}: max attempts (${MAX_ATTEMPTS}) reached"
exit 1
