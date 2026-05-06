#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOARD_SCRIPT="$SCRIPT_DIR/update-board.sh"
PASS=0; FAIL=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

FIXTURE_BASIC='[
  {"number":1,"title":"Add login","state":"OPEN","body":"## Acceptance criteria\n- [ ] user can log in\n\n## Blocked by\n\nNone","labels":[{"name":"afk"}]},
  {"number":2,"title":"Add signup","state":"CLOSED","body":"","labels":[{"name":"afk"}]},
  {"number":3,"title":"Design review","state":"OPEN","body":"","labels":[{"name":"hitl"}]},
  {"number":4,"title":"No label issue","state":"OPEN","body":"","labels":[]}
]'

FIXTURE_BLOCKED='[
  {"number":1,"title":"Blocker","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":2,"title":"Blocked child","state":"OPEN","body":"## Blocked by\n\n- Blocked by #1\n","labels":[{"name":"afk"}]}
]'

FIXTURE_BRACKETS='[
  {"number":1,"title":"[BUG] Fix login","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":2,"title":"Add <script> tag","state":"OPEN","body":"","labels":[{"name":"afk"}]}
]'

run_board() {
  local board="$tmp/BOARD-$RANDOM.md"
  BOARD_FILE="$board" ISSUES_JSON="$1" bash "$BOARD_SCRIPT" "${@:2}" > /dev/null 2>&1
  echo "$board"
}

# ── test 1: mermaid block is written ─────────────────────────────────────────

board=$(run_board "$FIXTURE_BASIC")
grep -q '```mermaid' "$board" \
  && ok "writes mermaid block" || fail "writes mermaid block"

# ── test 2: afk/hitl issues appear; unlabeled issue is skipped ───────────────

board=$(run_board "$FIXTURE_BASIC")
grep -q '1\[' "$board" && grep -q '2\[' "$board" && grep -q '3\[' "$board" \
  && ok "afk and hitl issues appear" || fail "afk and hitl issues appear"
grep -qv '4\[' "$board" \
  && ok "unlabeled issue skipped" || fail "unlabeled issue skipped"

# ── test 3: closed issue gets class done ─────────────────────────────────────

board=$(run_board "$FIXTURE_BASIC")
grep -q 'class 2 done' "$board" \
  && ok "closed issue has class done" || fail "closed issue has class done"

# ── test 4: open unblocked afk issue gets class ready ────────────────────────

board=$(run_board "$FIXTURE_BASIC")
grep -q 'class 1 ready' "$board" \
  && ok "open unblocked afk gets class ready" || fail "open unblocked afk gets class ready"

# ── test 5: hitl issue gets class hitl ───────────────────────────────────────

board=$(run_board "$FIXTURE_BASIC")
grep -q 'class 3 hitl' "$board" \
  && ok "hitl issue has class hitl" || fail "hitl issue has class hitl"

# ── test 6: blocked issue gets class blocked ─────────────────────────────────

board=$(run_board "$FIXTURE_BLOCKED")
grep -q 'class 2 blocked' "$board" \
  && ok "blocked issue has class blocked" || fail "blocked issue has class blocked"

# ── test 7: ACTIVE_ISSUES marks a single issue active ────────────────────────

board=$(ACTIVE_ISSUES="1" run_board "$FIXTURE_BASIC")
grep -q 'class 1 active' "$board" \
  && ok "ACTIVE_ISSUES single marks active" || fail "ACTIVE_ISSUES single marks active"

# ── test 8: ACTIVE_ISSUES marks multiple issues active ───────────────────────

FIXTURE_TWO_READY='[
  {"number":1,"title":"Issue one","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":2,"title":"Issue two","state":"OPEN","body":"","labels":[{"name":"afk"}]}
]'
board=$(ACTIVE_ISSUES="1 2" run_board "$FIXTURE_TWO_READY")
grep -q 'class 1 active' "$board" && grep -q 'class 2 active' "$board" \
  && ok "ACTIVE_ISSUES space-separated marks multiple active" \
  || fail "ACTIVE_ISSUES space-separated marks multiple active"

# ── test 9: ACTIVE_ISSUE (singular, deprecated) still works ──────────────────

board=$(ACTIVE_ISSUE="1" run_board "$FIXTURE_BASIC")
grep -q 'class 1 active' "$board" \
  && ok "ACTIVE_ISSUE singular (deprecated) still works" \
  || fail "ACTIVE_ISSUE singular (deprecated) still works"

# ── test 10: brackets and angle brackets in titles are stripped ───────────────

board=$(run_board "$FIXTURE_BRACKETS")
# The original [BUG] and <script> strings should not appear in the output
if grep -qF '[BUG]' "$board" || grep -qF '<script>' "$board"; then
  fail "brackets/angles stripped from node labels"
else
  ok "brackets/angles stripped from node labels"
fi

# ── test 11: STRICT_SANITIZE=1 strips all non-safe chars ─────────────────────

board="$tmp/BOARD-strict.md"
BOARD_FILE="$board" \
  ISSUES_JSON='[{"number":1,"title":"[BUG] <Fix> login","state":"OPEN","body":"","labels":[{"name":"afk"}]}]' \
  STRICT_SANITIZE=1 bash "$BOARD_SCRIPT" >/dev/null 2>&1
if grep -qF '[BUG]' "$board" || grep -qF '<Fix>' "$board"; then
  fail "STRICT_SANITIZE=1 strips all problematic chars"
else
  ok "STRICT_SANITIZE=1 strips all problematic chars"
fi

# ── test 12: edge is written for blocked-by relationship ─────────────────────

board=$(run_board "$FIXTURE_BLOCKED")
grep -q '1 --> 2' "$board" \
  && ok "edge written for blocker relationship" || fail "edge written for blocker relationship"

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
