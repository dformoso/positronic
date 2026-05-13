#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARALLEL_SCRIPT="$SCRIPT_DIR/run-parallel.sh"
PASS=0; FAIL=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── fixtures ──────────────────────────────────────────────────────────────────

TWO_UNBLOCKED='[
  {"number":1,"title":"Issue one","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":2,"title":"Issue two","state":"OPEN","body":"","labels":[{"name":"afk"}]}
]'

ONE_OPEN_ONE_BLOCKED='[
  {"number":1,"title":"Blocker","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":2,"title":"Blocked","state":"OPEN","body":"## Blocked by\n\n- Blocked by #1\n","labels":[{"name":"afk"}]}
]'

ALL_DONE='[
  {"number":1,"title":"Done","state":"CLOSED","body":"","labels":[{"name":"afk"}]}
]'

FIVE_UNBLOCKED='[
  {"number":1,"title":"A","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":2,"title":"B","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":3,"title":"C","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":4,"title":"D","state":"OPEN","body":"","labels":[{"name":"afk"}]},
  {"number":5,"title":"E","state":"OPEN","body":"","labels":[{"name":"afk"}]}
]'

# ── helpers ───────────────────────────────────────────────────────────────────

# Mock gh: returns first_fixture on wave N=0,1, all_done thereafter.
# This lets the loop run exactly one wave then terminate.
make_gh() {
  local first_fixture="$1" counter_file="$2" call_log="${3:-/dev/null}"
  echo 0 > "$counter_file"
  local script="$tmp/gh_$RANDOM"
  cat > "$script" <<GHEOF
#!/usr/bin/env bash
echo "\$@" >> "$call_log"
case "\$1 \$2" in
  "issue list")
    n=\$(cat "$counter_file")
    echo \$((n+1)) > "$counter_file"
    if [ "\$n" -lt 1 ]; then
      echo '$first_fixture'
    else
      echo '$ALL_DONE'
    fi
    ;;
  "issue view") echo '{"body":""}' ;;
  "issue close") : ;;
  *) : ;;
esac
GHEOF
  chmod +x "$script"
  echo "$script"
}

# Mock impl script: log the launch, exit immediately
make_impl() {
  local exit_code="${1:-0}" launch_log="${2:-/dev/null}"
  local script="$tmp/impl_$RANDOM"
  printf '#!/usr/bin/env bash\necho "launched $@" >> "%s"\nexit %s\n' \
    "$launch_log" "$exit_code" > "$script"
  chmod +x "$script"
  echo "$script"
}

# ── test 1: exits 0 when no unblocked issues ──────────────────────────────────

counter1="$tmp/c1"; gh1=$(make_gh "$ALL_DONE" "$counter1")
impl1=$(make_impl 0 /dev/null)
GH_CMD="$gh1" IMPL_SCRIPT="$impl1" CONCURRENCY=4 \
  bash "$PARALLEL_SCRIPT" >/dev/null 2>&1 \
  && ok "exits 0 when no unblocked issues" \
  || fail "exits 0 when no unblocked issues"

# ── test 2: prints completion message ─────────────────────────────────────────

counter2="$tmp/c2"; gh2=$(make_gh "$ALL_DONE" "$counter2")
impl2=$(make_impl 0 /dev/null)
out2=$(GH_CMD="$gh2" IMPL_SCRIPT="$impl2" CONCURRENCY=4 bash "$PARALLEL_SCRIPT" 2>&1 || true)
echo "$out2" | grep -qi "complete" \
  && ok "prints completion message" || fail "prints completion message"

# ── test 3: launches one impl process per unblocked issue in the wave ─────────

launch_log3="$tmp/launches3.log"; touch "$launch_log3"
counter3="$tmp/c3"; gh3=$(make_gh "$TWO_UNBLOCKED" "$counter3")
impl3=$(make_impl 0 "$launch_log3")

GH_CMD="$gh3" IMPL_SCRIPT="$impl3" CONCURRENCY=4 \
  bash "$PARALLEL_SCRIPT" >/dev/null 2>&1 || true

count3=$(grep -c "launched" "$launch_log3" 2>/dev/null || true)
[ "$count3" -eq 2 ] \
  && ok "launches one process per unblocked issue (got $count3)" \
  || fail "launches one process per unblocked issue (got $count3)"

# ── test 4: passes issue number and title to impl script ──────────────────────

launch_log4="$tmp/launches4.log"; touch "$launch_log4"
counter4="$tmp/c4"; gh4=$(make_gh "$TWO_UNBLOCKED" "$counter4")
impl4=$(make_impl 0 "$launch_log4")

GH_CMD="$gh4" IMPL_SCRIPT="$impl4" CONCURRENCY=4 \
  bash "$PARALLEL_SCRIPT" >/dev/null 2>&1 || true

grep -q "1" "$launch_log4" && grep -q "Issue one" "$launch_log4" \
  && ok "passes issue number and title to impl" \
  || fail "passes issue number and title to impl"

# ── test 5: respects CONCURRENCY cap ─────────────────────────────────────────

launch_log5="$tmp/launches5.log"; touch "$launch_log5"
counter5="$tmp/c5"; gh5=$(make_gh "$FIVE_UNBLOCKED" "$counter5")
impl5=$(make_impl 0 "$launch_log5")

GH_CMD="$gh5" IMPL_SCRIPT="$impl5" CONCURRENCY=3 \
  bash "$PARALLEL_SCRIPT" >/dev/null 2>&1 || true

count5=$(grep -c "launched" "$launch_log5" 2>/dev/null || true)
[ "$count5" -le 3 ] \
  && ok "CONCURRENCY=3 caps wave at ≤3 launches (got $count5)" \
  || fail "CONCURRENCY=3 caps wave at ≤3 launches (got $count5)"

# ── test 6: blocked issue is not launched ─────────────────────────────────────

launch_log6="$tmp/launches6.log"; touch "$launch_log6"
counter6="$tmp/c6"; gh6=$(make_gh "$ONE_OPEN_ONE_BLOCKED" "$counter6")
impl6=$(make_impl 0 "$launch_log6")

GH_CMD="$gh6" IMPL_SCRIPT="$impl6" CONCURRENCY=4 \
  bash "$PARALLEL_SCRIPT" >/dev/null 2>&1 || true

# Only issue #1 is unblocked; issue #2 is blocked by #1
count6=$(grep -c "launched" "$launch_log6" 2>/dev/null || true)
[ "$count6" -eq 1 ] \
  && ok "blocked issue is skipped; only unblocked issue launched (got $count6)" \
  || fail "blocked issue is skipped; only unblocked issue launched (got $count6)"

grep -q " 1 " "$launch_log6" || grep -q " 1$" "$launch_log6" \
  && ok "correct (unblocked) issue was launched" \
  || fail "correct (unblocked) issue was launched"

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
