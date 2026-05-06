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

make_claude() {
  local exit_code="$1" output="$2"
  local script="$tmp/claude_$RANDOM"
  printf '#!/usr/bin/env bash\necho "%s"\nexit %s\n' "$output" "$exit_code" > "$script"
  chmod +x "$script"
  echo "$script"
}

make_gh() {
  # gh view returns a body; gh close records the call
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

# ── test 1: exits 0 and closes issue when claude succeeds ─────────────────────

close_log="$tmp/close1.log"
touch "$close_log"
claude=$(make_claude 0 "done")
gh=$(make_gh "$BODY_JSON" "$close_log")

PATH="$tmp:$PATH" CLAUDE_CMD="$claude" GH_CMD="$gh" \
  MAX_ATTEMPTS=1 RETRY_WAIT_SECONDS=0 \
  bash "$IMPL_SCRIPT" 42 "Add login" >/dev/null 2>&1 \
  && ok "exits 0 on claude success" || fail "exits 0 on claude success"

grep -q "issue close" "$close_log" \
  && ok "closes the issue on success" || fail "closes the issue on success"

grep -q "42" "$close_log" \
  && ok "closes the correct issue number" || fail "closes the correct issue number"

# ── test 2: exits non-zero on unexpected claude failure ───────────────────────

close_log2="$tmp/close2.log"; touch "$close_log2"
claude_fail=$(make_claude 1 "unexpected error")
gh2=$(make_gh "$BODY_JSON" "$close_log2")

PATH="$tmp:$PATH" CLAUDE_CMD="$claude_fail" GH_CMD="$gh2" \
  MAX_ATTEMPTS=1 RETRY_WAIT_SECONDS=0 \
  bash "$IMPL_SCRIPT" 42 "Add login" >/dev/null 2>&1 \
  && fail "exits non-zero on claude failure" || ok "exits non-zero on claude failure"

[ ! -s "$close_log2" ] \
  && ok "does not close issue on failure" || fail "does not close issue on failure"

# ── test 3: retries on credit exhaustion and succeeds on second attempt ───────

counter="$tmp/counter3"
echo 0 > "$counter"
cat > "$tmp/claude_retry" <<EOF
#!/usr/bin/env bash
n=\$(cat "$counter"); echo \$((n+1)) > "$counter"
if [ "\$n" -eq 0 ]; then echo "Your credit balance is too low"; exit 1; fi
echo "done"; exit 0
EOF
chmod +x "$tmp/claude_retry"

close_log3="$tmp/close3.log"; touch "$close_log3"
gh3=$(make_gh "$BODY_JSON" "$close_log3")

PATH="$tmp:$PATH" CLAUDE_CMD="$tmp/claude_retry" GH_CMD="$gh3" \
  MAX_ATTEMPTS=3 RETRY_WAIT_SECONDS=0 \
  bash "$IMPL_SCRIPT" 42 "Add login" >/dev/null 2>&1 \
  && ok "retries on credit exhaustion and succeeds" \
  || fail "retries on credit exhaustion and succeeds"

grep -q "issue close" "$close_log3" \
  && ok "closes issue after retry success" || fail "closes issue after retry success"

# ── test 4: stops after MAX_ATTEMPTS with persistent credit exhaustion ─────────

counter4="$tmp/counter4"
echo 0 > "$counter4"
cat > "$tmp/claude_always_credit" <<EOF
#!/usr/bin/env bash
n=\$(cat "$counter4"); echo \$((n+1)) > "$counter4"
echo "credit balance too low"; exit 1
EOF
chmod +x "$tmp/claude_always_credit"

close_log4="$tmp/close4.log"; touch "$close_log4"
gh4=$(make_gh "$BODY_JSON" "$close_log4")

PATH="$tmp:$PATH" CLAUDE_CMD="$tmp/claude_always_credit" GH_CMD="$gh4" \
  MAX_ATTEMPTS=3 RETRY_WAIT_SECONDS=0 \
  bash "$IMPL_SCRIPT" 42 "Add login" >/dev/null 2>&1 \
  && fail "exits non-zero after max attempts" || ok "exits non-zero after max attempts"

call_count=$(cat "$counter4")
[ "$call_count" -eq 3 ] \
  && ok "attempts exactly MAX_ATTEMPTS=3 times (got $call_count)" \
  || fail "attempts exactly MAX_ATTEMPTS=3 times (got $call_count)"

[ ! -s "$close_log4" ] \
  && ok "does not close issue after max attempts exhausted" \
  || fail "does not close issue after max attempts exhausted"

# ── test 5: /tdd prompt includes issue number, title, and criteria ────────────

prompt_log="$tmp/prompt5.log"
cat > "$tmp/claude_log_prompt" <<EOF
#!/usr/bin/env bash
echo "\$*" > "$prompt_log"
exit 0
EOF
chmod +x "$tmp/claude_log_prompt"

close_log5="$tmp/close5.log"; touch "$close_log5"
gh5=$(make_gh "$BODY_JSON" "$close_log5")

PATH="$tmp:$PATH" CLAUDE_CMD="$tmp/claude_log_prompt" GH_CMD="$gh5" \
  MAX_ATTEMPTS=1 RETRY_WAIT_SECONDS=0 \
  bash "$IMPL_SCRIPT" 42 "Add login" >/dev/null 2>&1

grep -q '42' "$prompt_log" \
  && ok "prompt includes issue number" || fail "prompt includes issue number"
grep -q 'Add login' "$prompt_log" \
  && ok "prompt includes issue title" || fail "prompt includes issue title"
grep -q '/tdd' "$prompt_log" \
  && ok "prompt uses /tdd" || fail "prompt uses /tdd"

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
