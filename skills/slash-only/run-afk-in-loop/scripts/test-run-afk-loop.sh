#!/usr/bin/env bash
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/run-afk-loop.sh"
PASS=0; FAIL=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# ── test 1: exits 0 when claude succeeds immediately ─────────────────────────

cat > "$tmp/claude_success" <<'EOF'
#!/usr/bin/env bash
echo "All AFK issues complete."
exit 0
EOF
chmod +x "$tmp/claude_success"

CLAUDE_CMD="$tmp/claude_success" RETRY_WAIT_SECONDS=0 MAX_ATTEMPTS=3 \
  bash "$SCRIPT" > /dev/null 2>&1 \
  && ok "exits 0 on immediate success" || fail "exits 0 on immediate success"

# ── test 2: retries on credit exhaustion, succeeds on second attempt ─────────

COUNTER="$tmp/counter1"
echo 0 > "$COUNTER"
cat > "$tmp/claude_retry" <<EOF
#!/usr/bin/env bash
n=\$(cat "$COUNTER"); echo \$((n+1)) > "$COUNTER"
if [ "\$n" -eq 0 ]; then echo "Your credit balance is too low"; exit 1; fi
echo "All AFK issues complete."; exit 0
EOF
chmod +x "$tmp/claude_retry"

CLAUDE_CMD="$tmp/claude_retry" RETRY_WAIT_SECONDS=0 MAX_ATTEMPTS=3 \
  bash "$SCRIPT" > /dev/null 2>&1 \
  && ok "retries on credit exhaustion and succeeds" || fail "retries on credit exhaustion and succeeds"

# ── test 3: exits non-zero on unexpected (non-exhaustion) failure ─────────────

cat > "$tmp/claude_fail" <<'EOF'
#!/usr/bin/env bash
echo "segmentation fault"; exit 2
EOF
chmod +x "$tmp/claude_fail"

CLAUDE_CMD="$tmp/claude_fail" RETRY_WAIT_SECONDS=0 MAX_ATTEMPTS=3 \
  bash "$SCRIPT" > /dev/null 2>&1 \
  && fail "exits non-zero on unexpected failure" || ok "exits non-zero on unexpected failure"

# ── test 4: stops at MAX_ATTEMPTS when credit exhaustion persists ─────────────

COUNTER="$tmp/counter2"
echo 0 > "$COUNTER"
cat > "$tmp/claude_always_credit" <<EOF
#!/usr/bin/env bash
n=\$(cat "$COUNTER"); echo \$((n+1)) > "$COUNTER"
echo "credit balance too low"; exit 1
EOF
chmod +x "$tmp/claude_always_credit"

CLAUDE_CMD="$tmp/claude_always_credit" RETRY_WAIT_SECONDS=0 MAX_ATTEMPTS=3 \
  bash "$SCRIPT" > /dev/null 2>&1 \
  && fail "exits non-zero after max attempts" || ok "exits non-zero after max attempts"

call_count=$(cat "$COUNTER")
[ "$call_count" -eq 3 ] \
  && ok "invoked exactly MAX_ATTEMPTS=3 times (got $call_count)" \
  || fail "invoked exactly MAX_ATTEMPTS=3 times (got $call_count)"

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
