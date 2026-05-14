#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMPL_SCRIPT="$SCRIPT_DIR/implement-issue.sh"
PASS=0; FAIL=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── helpers ───────────────────────────────────────────────────────────────────

# make_claude EXIT_CODE OUTPUT_LINES...
# Each output line becomes a separate `echo` so newlines are preserved.
make_claude() {
  local exit_code="$1"; shift
  local script="$tmp/claude_$RANDOM"
  {
    echo '#!/usr/bin/env bash'
    for line in "$@"; do
      printf 'echo %q\n' "$line"
    done
    echo "exit ${exit_code}"
  } > "$script"
  chmod +x "$script"
  echo "$script"
}

make_gh() {
  local body="$1" close_log="$2"
  local script="$tmp/gh_$RANDOM"
  cat > "$script" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
  "issue view") echo '$body' ;;
  "issue close") echo "\$@" >> "$close_log" ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$script"
  echo "$script"
}

BODY_JSON='{"body":"## Acceptance criteria\n- [ ] user can log in\n"}'

# Default env for all tests: skip worktree setup; fast retry.
run_impl() {
  AFK_WORKTREE=0 MAX_ATTEMPTS="${MAX_ATTEMPTS:-1}" RETRY_WAIT_SECONDS=0 \
    bash "$IMPL_SCRIPT" "$@"
}

# ── test 1: exits 0 when claude emits success marker ──────────────────────────

close_log="$tmp/close1.log"; touch "$close_log"
claude=$(make_claude 0 "done" "=== AFK-RESULT: success ===" "Files: x.py" "Tests: pytest passed" "Commit: abc123")
gh=$(make_gh "$BODY_JSON" "$close_log")

CLAUDE_CMD="$claude" GH_CMD="$gh" run_impl 42 "Add login" >/dev/null 2>&1 \
  && ok "exits 0 when claude emits success marker" \
  || fail "exits 0 when claude emits success marker"

[ ! -s "$close_log" ] \
  && ok "does NOT close issue (orchestrator's job)" \
  || fail "does NOT close issue (orchestrator's job)"

# ── test 2: exits 1 when claude exits 0 but emits no marker ───────────────────

close_log2="$tmp/close2.log"; touch "$close_log2"
claude_no_marker=$(make_claude 0 "I need clarification on requirement X")
gh2=$(make_gh "$BODY_JSON" "$close_log2")

CLAUDE_CMD="$claude_no_marker" GH_CMD="$gh2" run_impl 42 "Add login" >/dev/null 2>&1 \
  && fail "exits non-zero when marker is absent" \
  || ok "exits non-zero when marker is absent"

# ── test 3: exits 2 when claude emits blocked marker ──────────────────────────

close_log3="$tmp/close3.log"; touch "$close_log3"
claude_blocked=$(make_claude 0 "I cannot proceed" "=== AFK-RESULT: blocked ===" "Reason: missing dependency foo")
gh3=$(make_gh "$BODY_JSON" "$close_log3")

set +e
CLAUDE_CMD="$claude_blocked" GH_CMD="$gh3" run_impl 42 "Add login" >/dev/null 2>&1
blocked_exit=$?
set -e

[ "$blocked_exit" -eq 2 ] \
  && ok "exits 2 on blocked marker (got $blocked_exit)" \
  || fail "exits 2 on blocked marker (got $blocked_exit)"

[ ! -s "$close_log3" ] \
  && ok "does not close issue on blocked" \
  || fail "does not close issue on blocked"

# ── test 4: exits non-zero on unexpected claude failure ──────────────────────

close_log4="$tmp/close4.log"; touch "$close_log4"
claude_fail=$(make_claude 1 "unexpected error")
gh4=$(make_gh "$BODY_JSON" "$close_log4")

CLAUDE_CMD="$claude_fail" GH_CMD="$gh4" run_impl 42 "Add login" >/dev/null 2>&1 \
  && fail "exits non-zero on claude failure" \
  || ok "exits non-zero on claude failure"

[ ! -s "$close_log4" ] \
  && ok "does not close issue on claude failure" \
  || fail "does not close issue on claude failure"

# ── test 5: retries on credit exhaustion, succeeds on second attempt ─────────

counter="$tmp/counter5"
echo 0 > "$counter"
cat > "$tmp/claude_retry" <<EOF
#!/usr/bin/env bash
n=\$(cat "$counter"); echo \$((n+1)) > "$counter"
if [ "\$n" -eq 0 ]; then echo "Your credit balance is too low"; exit 1; fi
echo "done"
echo "=== AFK-RESULT: success ==="
echo "Files: x.py"
echo "Tests: pytest passed"
echo "Commit: abc123"
exit 0
EOF
chmod +x "$tmp/claude_retry"

close_log5="$tmp/close5.log"; touch "$close_log5"
gh5=$(make_gh "$BODY_JSON" "$close_log5")

CLAUDE_CMD="$tmp/claude_retry" GH_CMD="$gh5" \
  MAX_ATTEMPTS=3 run_impl 42 "Add login" >/dev/null 2>&1 \
  && ok "retries on credit exhaustion and succeeds" \
  || fail "retries on credit exhaustion and succeeds"

# ── test 6: stops after MAX_ATTEMPTS with persistent credit exhaustion ────────

counter6="$tmp/counter6"
echo 0 > "$counter6"
cat > "$tmp/claude_always_credit" <<EOF
#!/usr/bin/env bash
n=\$(cat "$counter6"); echo \$((n+1)) > "$counter6"
echo "credit balance too low"; exit 1
EOF
chmod +x "$tmp/claude_always_credit"

close_log6="$tmp/close6.log"; touch "$close_log6"
gh6=$(make_gh "$BODY_JSON" "$close_log6")

CLAUDE_CMD="$tmp/claude_always_credit" GH_CMD="$gh6" \
  MAX_ATTEMPTS=3 run_impl 42 "Add login" >/dev/null 2>&1 \
  && fail "exits non-zero after max attempts" \
  || ok "exits non-zero after max attempts"

call_count=$(cat "$counter6")
[ "$call_count" -eq 3 ] \
  && ok "attempts exactly MAX_ATTEMPTS=3 times (got $call_count)" \
  || fail "attempts exactly MAX_ATTEMPTS=3 times (got $call_count)"

# ── test 7: prompt includes issue number, title, preamble, /test-driven-dev ──

prompt_log="$tmp/prompt7.log"
cat > "$tmp/claude_log_prompt" <<EOF
#!/usr/bin/env bash
echo "\$*" > "$prompt_log"
echo "=== AFK-RESULT: success ==="
echo "Files: x"; echo "Tests: pass"; echo "Commit: abc"
exit 0
EOF
chmod +x "$tmp/claude_log_prompt"

close_log7="$tmp/close7.log"; touch "$close_log7"
gh7=$(make_gh "$BODY_JSON" "$close_log7")

CLAUDE_CMD="$tmp/claude_log_prompt" GH_CMD="$gh7" \
  run_impl 42 "Add login" >/dev/null 2>&1

grep -q '42'              "$prompt_log" && ok "prompt includes issue number" || fail "prompt includes issue number"
grep -q 'Add login'       "$prompt_log" && ok "prompt includes issue title"  || fail "prompt includes issue title"
grep -q '/test-driven-dev' "$prompt_log" && ok "prompt uses /test-driven-dev" || fail "prompt uses /test-driven-dev"
grep -q 'non-interactive' "$prompt_log" && ok "prompt includes preamble"     || fail "prompt includes preamble"
grep -q 'AFK-RESULT'      "$prompt_log" && ok "prompt references AFK-RESULT marker" || fail "prompt references AFK-RESULT marker"

# ── test 8: worktree mode creates branch afk/issue-N in a fresh worktree ─────

repo="$tmp/repo8"
git init -q "$repo"
(
  cd "$repo"
  git config user.email "test@test"; git config user.name "Test"
  echo "initial" > README.md
  git add README.md
  git commit -q -m "initial"
)

# Agent stub: runs in the worktree, makes a commit, emits success marker.
cat > "$tmp/claude_commit" <<EOF
#!/usr/bin/env bash
echo "doing work"
echo "feature" > feature.txt
git add feature.txt
git commit -q -m "add feature"
echo "=== AFK-RESULT: success ==="
echo "Files: feature.txt"; echo "Tests: pass"; echo "Commit: \$(git rev-parse HEAD)"
exit 0
EOF
chmod +x "$tmp/claude_commit"

close_log8="$tmp/close8.log"; touch "$close_log8"
gh8=$(make_gh "$BODY_JSON" "$close_log8")

(
  cd "$repo"
  AFK_WORKTREE=1 CLAUDE_CMD="$tmp/claude_commit" GH_CMD="$gh8" \
    MAX_ATTEMPTS=1 RETRY_WAIT_SECONDS=0 \
    bash "$IMPL_SCRIPT" 99 "feature" >/dev/null 2>&1
) && ok "worktree mode: exits 0 on agent success" || fail "worktree mode: exits 0 on agent success"

[ -d "$tmp/wt-issue-99" ] \
  && ok "worktree mode: created worktree at expected sibling path" \
  || fail "worktree mode: created worktree at expected sibling path"

(cd "$repo" && git rev-parse --verify "afk/issue-99" >/dev/null 2>&1) \
  && ok "worktree mode: created branch afk/issue-99" \
  || fail "worktree mode: created branch afk/issue-99"

# ── test 9: worktree mode reuses path after cleaning up stale state ──────────

# Leave a stale dir at the worktree path (as if a prior run left it behind).
# implement-issue.sh should remove it and create fresh state.
(
  cd "$repo"
  git worktree remove "$tmp/wt-issue-99" --force >/dev/null 2>&1 || true
  git branch -D "afk/issue-99" >/dev/null 2>&1 || true
  mkdir -p "$tmp/wt-issue-99"
  echo "stale" > "$tmp/wt-issue-99/stale.txt"

  AFK_WORKTREE=1 CLAUDE_CMD="$tmp/claude_commit" GH_CMD="$gh8" \
    MAX_ATTEMPTS=1 RETRY_WAIT_SECONDS=0 \
    bash "$IMPL_SCRIPT" 99 "feature" >/dev/null 2>&1
) && ok "worktree mode: succeeds even with stale worktree path" \
  || fail "worktree mode: succeeds even with stale worktree path"

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
