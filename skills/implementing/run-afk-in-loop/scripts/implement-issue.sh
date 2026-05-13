#!/usr/bin/env bash
# Implements a single AFK GitHub issue by invoking /test-driven-dev, then closes it.
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

body=$(${GH_CMD} issue view "${NUM}" --json body | jq -r '.body')

spec_path=""
prd_path=""
if [ -d specs ]; then
  spec_path=$(ls specs/[0-9]*.md 2>/dev/null | sort | tail -1 || true)
fi
if [ -d prds ]; then
  prd_path=$(ls prds/[0-9]*.md 2>/dev/null | sort | tail -1 || true)
fi

prompt="Implement GitHub issue #${NUM}: ${TITLE}

Issue body:
${body}"

if [ -n "$spec_path" ] || [ -n "$prd_path" ]; then
  prompt="${prompt}

Source documents to read before starting:"
  if [ -n "$spec_path" ]; then
    prompt="${prompt}
- Latest SPEC: ${spec_path}"
  fi
  if [ -n "$prd_path" ]; then
    prompt="${prompt}
- Latest PRD: ${prd_path}"
  fi
fi

log "#${NUM}: starting — ${TITLE}"

attempt=0
while [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
  attempt=$((attempt + 1))
  set +e
  output=$("${CLAUDE_CMD}" --dangerously-skip-permissions --print "/test-driven-dev ${prompt}" 2>&1)
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
