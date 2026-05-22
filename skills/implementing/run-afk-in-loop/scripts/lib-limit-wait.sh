#!/usr/bin/env bash
# Helpers for detecting Claude usage / session / rate limits in CLI output
# and pausing the caller until the limit resets — with user-visible heartbeats.
#
# Source this file; do not execute directly. No claude binary is invoked here:
# the reset time is parsed from claude's own stderr/stdout, via grep + date.
#
# Functions exposed:
#
#   extract_reset_seconds OUTPUT
#       Looks for a "reset(s) at <time> [(<tz>)]" hint in OUTPUT and echoes
#       the number of wall-clock seconds until that instant (with a 60s buffer
#       for clock skew). Echoes "" if no parsable hint is found.
#
#       Accepted time formats:
#         3pm           3:30pm         3:30 PM
#         15:00         15:00:00
#       Accepted optional timezone (parenthesised, trailing):
#         (UTC)         (America/Los_Angeles)
#
#   detect_limit_wait_seconds OUTPUT [TRANSIENT_FALLBACK] [SESSION_FALLBACK]
#       Inspects OUTPUT for a known limit signature and echoes the seconds
#       the caller should wait. Echoes "" if no limit was detected.
#         - If a "reset at <time>" hint is present, uses extract_reset_seconds.
#         - If a "usage limit" / "limit reached" message is present without a
#           reset hint, falls back to SESSION_FALLBACK (default 21600 = 6h).
#         - For transient errors (credit / quota / overload / rate-limit),
#           falls back to TRANSIENT_FALLBACK (default 1800 = 30m).
#
#   pause_with_heartbeat SECONDS [LABEL]
#       Sleeps SECONDS, emitting an initial line that names the wall-clock
#       resume time, a heartbeat every 60s (5m for waits >10m), and a final
#       "resuming" line. No-op if SECONDS <= 0 or WAIT_DISABLED=1.

# ── time parsing ──────────────────────────────────────────────────────────────

# Parse <date-string> in TZ <tz> to epoch seconds. Tries BSD `date -j -f`
# first (macOS), then GNU `date -d` (Linux). Empty TZ uses local time.
_to_epoch() {
  local fmt="$1" datetime="$2" tz="$3"
  if [ -n "$tz" ]; then
    TZ="$tz" date -j -f "$fmt" "$datetime" '+%s' 2>/dev/null \
      || TZ="$tz" date -d "$datetime" '+%s' 2>/dev/null \
      || echo ""
  else
    date -j -f "$fmt" "$datetime" '+%s' 2>/dev/null \
      || date -d "$datetime" '+%s' 2>/dev/null \
      || echo ""
  fi
}

extract_reset_seconds() {
  local output="$1"

  # First snippet on a line containing "reset at <time>" — case-insensitive.
  # Allows "resets at" plural and optional trailing parenthesised timezone.
  local snippet
  snippet=$(printf '%s\n' "$output" \
    | grep -ioE 'reset(s)? at [0-9]{1,2}(:[0-9]{2})?( ?[ap]m)?( ?\([^)]+\))?' \
    | head -1)
  [ -z "$snippet" ] && { echo ""; return; }

  local time_part tz_part
  time_part=$(echo "$snippet" | sed -E 's/^[Rr][Ee][Ss][Ee][Tt][sS]? [Aa][Tt] //; s/ ?\([^)]+\) ?$//' \
    | tr -d ' ' | tr '[:upper:]' '[:lower:]')
  tz_part=$(echo "$snippet" | grep -oE '\([^)]+\)' | tr -d '()')

  # hour, minute, period from "15:00" / "3:30pm" / "3pm"
  local hour minute period
  if [[ "$time_part" =~ ^([0-9]{1,2})(:([0-9]{2}))?(am|pm)?$ ]]; then
    hour="${BASH_REMATCH[1]}"
    minute="${BASH_REMATCH[3]:-00}"
    period="${BASH_REMATCH[4]:-}"
  else
    echo ""
    return
  fi

  if [ "$period" = "pm" ] && [ "$hour" -lt 12 ]; then
    hour=$((hour + 12))
  elif [ "$period" = "am" ] && [ "$hour" -eq 12 ]; then
    hour=0
  fi

  local today datetime_str epoch
  if [ -n "$tz_part" ]; then
    today=$(TZ="$tz_part" date '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
  else
    today=$(date '+%Y-%m-%d')
  fi
  datetime_str=$(printf '%s %02d:%s:00' "$today" "$hour" "$minute")
  epoch=$(_to_epoch '%Y-%m-%d %H:%M:%S' "$datetime_str" "$tz_part")
  [ -z "$epoch" ] && { echo ""; return; }

  # If the parsed instant is in the past, it must mean tomorrow.
  local now_epoch wait_seconds
  now_epoch=$(date '+%s')
  wait_seconds=$((epoch - now_epoch))
  if [ "$wait_seconds" -lt 60 ]; then
    wait_seconds=$((wait_seconds + 86400))
  fi

  # 60s buffer for clock skew between this host and Anthropic's clock.
  echo $((wait_seconds + 60))
}

detect_limit_wait_seconds() {
  local output="$1"
  local transient_fallback="${2:-1800}"
  local session_fallback="${3:-21600}"

  # Session-window limit with a reset hint — wait until reset.
  if printf '%s\n' "$output" | grep -qiE 'reset(s)? at [0-9]'; then
    local s
    s=$(extract_reset_seconds "$output")
    if [ -n "$s" ] && [ "$s" -gt 0 ]; then
      echo "$s"
      return
    fi
    echo "$session_fallback"
    return
  fi

  # "Usage limit reached" without a reset hint — still a long-window limit.
  if printf '%s\n' "$output" | grep -qiE 'usage[ _-]?limit[[:space:]]+(reached|exceeded|hit)|limit[[:space:]]+reached'; then
    echo "$session_fallback"
    return
  fi

  # Transient: credit / overload / rate-limit / quota.
  if printf '%s\n' "$output" | grep -qiE 'credit|insufficient.fund|quota|overload|rate.limit'; then
    echo "$transient_fallback"
    return
  fi

  echo ""
}

# ── pause UX ─────────────────────────────────────────────────────────────────

pause_with_heartbeat() {
  local wait_seconds="$1"
  local label="${2:-claude}"

  if [ "${WAIT_DISABLED:-0}" = "1" ] || [ "$wait_seconds" -le 0 ]; then
    return 0
  fi

  local now_epoch resume_epoch resume_at
  now_epoch=$(date '+%s')
  resume_epoch=$((now_epoch + wait_seconds))
  resume_at=$(date -j -f %s "$resume_epoch" '+%H:%M' 2>/dev/null \
           || date -d "@$resume_epoch" '+%H:%M' 2>/dev/null \
           || echo '?')

  local mins=$((wait_seconds / 60))
  echo "[${label}] usage limit hit — pausing until ${resume_at} local (~${mins} min). Will auto-resume."

  local heartbeat=60
  [ "$wait_seconds" -gt 600 ] && heartbeat=300

  local elapsed=0
  while [ "$elapsed" -lt "$wait_seconds" ]; do
    local remaining=$((wait_seconds - elapsed))
    local chunk=$heartbeat
    [ "$chunk" -gt "$remaining" ] && chunk=$remaining
    sleep "$chunk"
    elapsed=$((elapsed + chunk))
    local rem_min=$(( (wait_seconds - elapsed) / 60 ))
    if [ "$elapsed" -lt "$wait_seconds" ] && [ "$rem_min" -gt 0 ]; then
      echo "[${label}] still paused — ~${rem_min} min until auto-resume."
    fi
  done

  echo "[${label}] resuming after usage-limit reset."
}
