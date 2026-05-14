#!/usr/bin/env bash
# Implements a single AFK GitHub issue inside an isolated git worktree.
# Reports outcome via exit code; does NOT close the issue or merge — the
# orchestrator (run-parallel.sh or the SKILL.md slash flow) integrates after the
# wave.
#
# Exit codes:
#   0  success (AFK-RESULT: success marker present in agent output)
#   2  blocked (AFK-RESULT: blocked marker present)
#   1  failed (no marker, claude crashed, or max retries exhausted)
#
# Usage: implement-issue.sh <issue-number> <title>
#
# Env vars:
#   CLAUDE_CMD          override claude binary (default: claude)
#   GH_CMD              override gh binary (default: gh)
#   GIT_CMD             override git binary (default: git)
#   MAX_ATTEMPTS        max attempts before giving up (default: 3)
#   RETRY_WAIT_SECONDS  seconds between credit-exhaustion retries (default: 1800)
#   WORKTREE_BASE       parent dir for worktrees (default: parent of repo root)
#   AFK_WORKTREE        set to 0 to run in cwd without a worktree (default: 1)
set -euo pipefail

NUM="$1"
TITLE="$2"
CLAUDE_CMD="${CLAUDE_CMD:-claude}"
GH_CMD="${GH_CMD:-gh}"
GIT_CMD="${GIT_CMD:-git}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
RETRY_WAIT="${RETRY_WAIT_SECONDS:-1800}"
AFK_WORKTREE="${AFK_WORKTREE:-1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREAMBLE_FILE="$(cd "$SCRIPT_DIR/.." && pwd)/AGENT_PREAMBLE.md"

log() { echo "[implement-issue] $*"; }

# ── build the prompt ──────────────────────────────────────────────────────────

body=$(${GH_CMD} issue view "${NUM}" --json body | jq -r '.body')

spec_path=""
prd_path=""
[ -d specs ] && spec_path=$(ls specs/[0-9]*.md 2>/dev/null | sort -V | tail -1 || true)
[ -d prds ]  && prd_path=$(ls prds/[0-9]*.md  2>/dev/null | sort -V | tail -1 || true)

preamble=""
[ -f "$PREAMBLE_FILE" ] && preamble=$(cat "$PREAMBLE_FILE")

prompt="/test-driven-dev Implement GitHub issue #${NUM}: ${TITLE}

${preamble}

---

Issue body:
${body}"

if [ -n "$spec_path" ] || [ -n "$prd_path" ]; then
  prompt="${prompt}

Source documents to read before starting:"
  [ -n "$spec_path" ] && prompt="${prompt}
- Latest SPEC: ${spec_path}"
  [ -n "$prd_path" ] && prompt="${prompt}
- Latest PRD: ${prd_path}"
fi

# ── set up the worktree ───────────────────────────────────────────────────────

branch="afk/issue-${NUM}"
run_dir="$(pwd)"

if [ "$AFK_WORKTREE" = "1" ]; then
  repo_root=$("$GIT_CMD" rev-parse --show-toplevel)
  WORKTREE_BASE="${WORKTREE_BASE:-$(dirname "$repo_root")}"
  worktree="$WORKTREE_BASE/wt-issue-${NUM}"

  if [ -d "$worktree" ]; then
    "$GIT_CMD" worktree remove "$worktree" --force >/dev/null 2>&1 || rm -rf "$worktree"
  fi
  "$GIT_CMD" branch -D "$branch" >/dev/null 2>&1 || true
  "$GIT_CMD" worktree add -b "$branch" "$worktree" >/dev/null
  run_dir="$worktree"
fi

log "#${NUM}: starting — ${TITLE} (dir: ${run_dir})"

# ── run the agent (retry on credit exhaustion) ────────────────────────────────

attempt=0
exit_code=1
output=""
while [ "$attempt" -lt "$MAX_ATTEMPTS" ]; do
  attempt=$((attempt + 1))
  set +e
  output=$(cd "$run_dir" && "${CLAUDE_CMD}" --dangerously-skip-permissions --print "${prompt}" 2>&1)
  exit_code=$?
  set -e

  printf '%s\n' "$output"

  [ "$exit_code" -eq 0 ] && break

  if echo "$output" | grep -qiE "credit|insufficient.fund|quota|overload|rate.limit"; then
    log "#${NUM}: credit exhaustion — waiting ${RETRY_WAIT}s (attempt ${attempt}/${MAX_ATTEMPTS})"
    sleep "${RETRY_WAIT}"
    continue
  fi

  log "#${NUM}: claude exited ${exit_code} (attempt ${attempt}/${MAX_ATTEMPTS})"
  break
done

# ── parse the AFK-RESULT marker ───────────────────────────────────────────────

if echo "$output" | grep -q "^=== AFK-RESULT: success ===$"; then
  log "#${NUM}: success marker present — branch ${branch} ready for merge"
  exit 0
fi

if echo "$output" | grep -q "^=== AFK-RESULT: blocked ===$"; then
  reason=$(echo "$output" | awk '
    /^=== AFK-RESULT: blocked ===$/ { found=1; next }
    found && /^Reason:/ { sub(/^Reason:[[:space:]]*/, ""); print; exit }
  ')
  log "#${NUM}: blocked — ${reason:-<no reason given>}"
  exit 2
fi

log "#${NUM}: failed — no AFK-RESULT marker (claude exit ${exit_code})"
exit 1
