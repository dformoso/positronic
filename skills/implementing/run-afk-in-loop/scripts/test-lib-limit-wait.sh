#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-limit-wait.sh
. "$SCRIPT_DIR/lib-limit-wait.sh"

PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

# Build a "HH:MM" string $1 minutes from now, portable to BSD + GNU date.
future_hhmm() {
  local offset_min="$1"
  local target_epoch=$(( $(date '+%s') + offset_min * 60 ))
  date -j -f %s "$target_epoch" '+%H:%M' 2>/dev/null \
    || date -d "@$target_epoch" '+%H:%M' 2>/dev/null
}

# ── extract_reset_seconds ─────────────────────────────────────────────────────

# 24-hour format, no timezone.
target=$(future_hhmm 5)
result=$(extract_reset_seconds "Your limit will reset at ${target}")
if [ -n "$result" ] && [ "$result" -gt 0 ] && [ "$result" -lt 600 ]; then
  ok "extract_reset_seconds: 24h format ~5min in future"
else
  fail "extract_reset_seconds: 24h format ~5min in future (got '$result')"
fi

# 12-hour format with am/pm — use a time we know is later today, or tomorrow.
# Pick 23:59 if before noon, 00:01 (tomorrow) otherwise.
hour_now=$(date '+%H')
if [ "$hour_now" -lt 12 ]; then
  result=$(extract_reset_seconds "usage limit reached. resets at 11:59pm")
else
  result=$(extract_reset_seconds "usage limit reached. resets at 12:01am")
fi
[ -n "$result" ] && [ "$result" -gt 0 ] \
  && ok "extract_reset_seconds: 12h am/pm format" \
  || fail "extract_reset_seconds: 12h am/pm format (got '$result')"

# Bare 12-hour ("3pm" with no minutes).
result=$(extract_reset_seconds "limit will reset at 11pm")
[ -n "$result" ] && [ "$result" -gt 0 ] \
  && ok "extract_reset_seconds: bare-hour 12h format" \
  || fail "extract_reset_seconds: bare-hour 12h format (got '$result')"

# Timezone in parens.
result=$(extract_reset_seconds "reset at 11:59pm (UTC)")
[ -n "$result" ] && [ "$result" -gt 0 ] \
  && ok "extract_reset_seconds: with UTC timezone" \
  || fail "extract_reset_seconds: with UTC timezone (got '$result')"

result=$(extract_reset_seconds "reset at 11:59pm (America/Los_Angeles)")
[ -n "$result" ] && [ "$result" -gt 0 ] \
  && ok "extract_reset_seconds: with named timezone" \
  || fail "extract_reset_seconds: with named timezone (got '$result')"

# Case-insensitive ("Reset At").
target=$(future_hhmm 10)
result=$(extract_reset_seconds "Reset At ${target}")
[ -n "$result" ] && [ "$result" -gt 0 ] \
  && ok "extract_reset_seconds: case-insensitive" \
  || fail "extract_reset_seconds: case-insensitive (got '$result')"

# Empty when no reset hint.
result=$(extract_reset_seconds "everything is fine")
[ -z "$result" ] \
  && ok "extract_reset_seconds: empty for no hint" \
  || fail "extract_reset_seconds: empty for no hint (got '$result')"

# Empty for malformed time after "reset at".
result=$(extract_reset_seconds "will reset at some unknown time")
[ -z "$result" ] \
  && ok "extract_reset_seconds: empty for malformed time" \
  || fail "extract_reset_seconds: empty for malformed time (got '$result')"

# Times within the last minute should be treated as tomorrow, not negative.
target=$(future_hhmm -1)   # 1 min in the past
result=$(extract_reset_seconds "reset at ${target}")
if [ -n "$result" ] && [ "$result" -gt 80000 ]; then
  ok "extract_reset_seconds: past time rolls to tomorrow"
else
  fail "extract_reset_seconds: past time rolls to tomorrow (got '$result')"
fi

# ── detect_limit_wait_seconds ─────────────────────────────────────────────────

# Transient (credit / quota / overload / rate-limit) → transient_fallback.
result=$(detect_limit_wait_seconds "Your credit balance is too low" 60 6000)
[ "$result" = "60" ] \
  && ok "detect_limit: credit → transient fallback" \
  || fail "detect_limit: credit → transient fallback (got '$result')"

result=$(detect_limit_wait_seconds "anthropic api overloaded" 60 6000)
[ "$result" = "60" ] \
  && ok "detect_limit: overload → transient fallback" \
  || fail "detect_limit: overload → transient fallback (got '$result')"

# "Usage limit reached" with no reset hint → session_fallback.
result=$(detect_limit_wait_seconds "Claude usage limit reached." 60 6000)
[ "$result" = "6000" ] \
  && ok "detect_limit: usage limit without hint → session fallback" \
  || fail "detect_limit: usage limit without hint → session fallback (got '$result')"

# "Usage limit reached" + reset hint → computed wait, not fallback.
target=$(future_hhmm 5)
result=$(detect_limit_wait_seconds "Claude usage limit reached. Your limit will reset at ${target}" 60 6000)
if [ -n "$result" ] && [ "$result" -gt 0 ] && [ "$result" -lt 600 ]; then
  ok "detect_limit: usage limit + reset hint → parsed wait"
else
  fail "detect_limit: usage limit + reset hint → parsed wait (got '$result')"
fi

# Empty when nothing matches.
result=$(detect_limit_wait_seconds "All AFK issues complete." 60 6000)
[ -z "$result" ] \
  && ok "detect_limit: empty when nothing matches" \
  || fail "detect_limit: empty when nothing matches (got '$result')"

# Default fallbacks (no args) match documented defaults.
result=$(detect_limit_wait_seconds "credit balance too low")
[ "$result" = "1800" ] \
  && ok "detect_limit: default transient fallback is 1800" \
  || fail "detect_limit: default transient fallback is 1800 (got '$result')"

result=$(detect_limit_wait_seconds "usage limit reached")
[ "$result" = "21600" ] \
  && ok "detect_limit: default session fallback is 21600" \
  || fail "detect_limit: default session fallback is 21600 (got '$result')"

# ── pause_with_heartbeat ──────────────────────────────────────────────────────

# WAIT_DISABLED=1 returns immediately even for a huge wait.
start=$(date +%s)
WAIT_DISABLED=1 pause_with_heartbeat 9999 "test" > /dev/null 2>&1
elapsed=$(( $(date +%s) - start ))
[ "$elapsed" -lt 2 ] \
  && ok "pause: WAIT_DISABLED=1 short-circuits" \
  || fail "pause: WAIT_DISABLED=1 short-circuits (took ${elapsed}s)"

# SECONDS=0 returns immediately.
start=$(date +%s)
pause_with_heartbeat 0 "test" > /dev/null 2>&1
elapsed=$(( $(date +%s) - start ))
[ "$elapsed" -lt 2 ] \
  && ok "pause: 0s short-circuits" \
  || fail "pause: 0s short-circuits (took ${elapsed}s)"

# Short wait actually sleeps.
start=$(date +%s)
pause_with_heartbeat 1 "test" > /dev/null 2>&1
elapsed=$(( $(date +%s) - start ))
[ "$elapsed" -ge 1 ] && [ "$elapsed" -lt 4 ] \
  && ok "pause: 1s wait actually sleeps" \
  || fail "pause: 1s wait actually sleeps (took ${elapsed}s)"

# Output contains the label, "pausing until", and "resuming".
output=$(pause_with_heartbeat 1 "mytest" 2>&1)
echo "$output" | grep -q "mytest" \
  && ok "pause: output includes the label" \
  || fail "pause: output includes the label"
echo "$output" | grep -q "pausing until" \
  && ok "pause: output includes 'pausing until'" \
  || fail "pause: output includes 'pausing until'"
echo "$output" | grep -q "resuming" \
  && ok "pause: output includes 'resuming'" \
  || fail "pause: output includes 'resuming'"

# ── summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
