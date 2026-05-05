#!/usr/bin/env bash
# Fetches current GitHub issue state and writes BOARD.md to the repo root.
#
# Environment:
#   BOARD_FILE       destination file (default: BOARD.md)
#   ACTIVE_ISSUES    space-separated issue numbers currently being worked
#   ACTIVE_ISSUE     (deprecated) single issue number — use ACTIVE_ISSUES
#   ISSUES_JSON      pre-fetched issues JSON (skips gh call; useful for testing)
#   STRICT_SANITIZE  set to 1 for aggressive label sanitization (auto-set on retry)
set -euo pipefail

BOARD_FILE="${BOARD_FILE:-BOARD.md}"
ACTIVE_ISSUES="${ACTIVE_ISSUES:-${ACTIVE_ISSUE:-}}"
STRICT="${STRICT_SANITIZE:-0}"

issues="${ISSUES_JSON:-$(gh issue list --state all --json number,title,body,state,labels --limit 100)}"

# ── helpers ───────────────────────────────────────────────────────────────────

sanitize() {
  if [ "$STRICT" = "1" ]; then
    tr -cd 'a-zA-Z0-9 #·/\-.!?(),'
  else
    sed "s/[]\"'\`[<>&|{}]//g"
  fi
}

deliverable() {
  local body="$1"
  echo "$body" \
    | awk '/^## What to build/{found=1; next} found && /^## /{exit} found && NF{print; exit}' \
    | sed 's/\. .*/\./' \
    | sanitize
}

criteria() {
  local body="$1"
  echo "$body" \
    | awk '/^## Acceptance criteria/{found=1; next} found && /^## /{exit} found && /- \[/{print}' \
    | head -4 \
    | sed 's/- \[x\]/✓/' \
    | sed 's/- \[ \]/○/' \
    | sanitize
}

blockers() {
  local body="$1"
  echo "$body" | grep -oE 'Blocked by #[0-9]+' | grep -oE '[0-9]+$' || true
}

is_active() {
  local num="$1"
  for a in $ACTIVE_ISSUES; do
    [ "$a" = "$num" ] && return 0
  done
  return 1
}

status_class() {
  local number="$1" state="$2" label="$3" blocker_numbers="$4"
  if [ "$state" = "CLOSED" ]; then echo "done"; return; fi
  if [ "$label" = "hitl" ]; then echo "hitl"; return; fi
  if is_active "$number"; then echo "active"; return; fi
  for b in $blocker_numbers; do
    bs=$(echo "$issues" | jq -r --argjson n "$b" '.[] | select(.number == $n) | .state')
    [ "$bs" = "OPEN" ] && echo "blocked" && return
  done
  echo "ready"
}

# ── build node and edge lists ─────────────────────────────────────────────────

nodes=""
edges=""
class_assignments=""

while IFS= read -r issue; do
  number=$(echo "$issue" | jq -r '.number')
  title=$(echo "$issue"  | jq -r '.title' | sanitize)
  state=$(echo "$issue"  | jq -r '.state')
  body=$(echo "$issue"   | jq -r '.body // ""')
  label=$(echo "$issue"  | jq -r '[.labels[].name] | map(select(. == "afk" or . == "hitl")) | first // ""')

  [ -z "$label" ] && continue

  blocker_nums=$(blockers "$body")
  sc=$(status_class "$number" "$state" "$label" "$blocker_nums")

  case "$sc" in
    done)    state_str="✓  DONE"    ;;
    ready)   state_str="○  READY"   ;;
    blocked) state_str="✗  BLOCKED" ;;
    active)  state_str="▶  ACTIVE"  ;;
    hitl)    state_str="◈  HITL"    ;;
    *)       state_str="${sc^^}"    ;;
  esac

  label_text="#${number}  ·  ${title}\n(${label^^})  ${state_str}"
  nodes="${nodes}  ${number}[\"${label_text}\"]\n"

  for b in $blocker_nums; do
    edges="${edges}  ${b} --> ${number}\n"
  done

  class_assignments="${class_assignments}  class ${number} ${sc}\n"

done < <(echo "$issues" | jq -c '.[]')

# ── write BOARD.md ────────────────────────────────────────────────────────────

updated_at=$(date '+%Y-%m-%d %H:%M')

cat > "$BOARD_FILE" <<BOARD
# Issue Board

> Last updated: ${updated_at}

\`\`\`mermaid
graph TD
  classDef done    fill:#22c55e,color:#fff,stroke:none
  classDef active  fill:#eab308,color:#fff,stroke:none
  classDef ready   fill:#9ca3af,color:#fff,stroke:none
  classDef blocked fill:#6b7280,color:#fff,stroke:#ef4444,stroke-width:2px
  classDef hitl    fill:#3b82f6,color:#fff,stroke:none

$(printf '%b' "$nodes")
$(printf '%b' "$edges")
$(printf '%b' "$class_assignments")
\`\`\`
BOARD

echo "BOARD.md updated (${updated_at})"

# ── mermaid validation ────────────────────────────────────────────────────────
# Only on first pass; STRICT mode is already the fix.

if [ "$STRICT" != "1" ]; then
  valid=true

  if command -v mmdc &>/dev/null; then
    tmp_svg=$(mktemp /tmp/board-validate-XXXXXX.svg)
    mmdc -i "$BOARD_FILE" -o "$tmp_svg" >/dev/null 2>&1 || valid=false
    rm -f "$tmp_svg"
  else
    # Text check: [ or ] or < or > inside a node label opening line
    if grep -qE '^ +[0-9]+\["[^"]*[<>\[\]]' "$BOARD_FILE" 2>/dev/null; then
      valid=false
    fi
  fi

  if ! $valid; then
    echo "WARN: mermaid validation failed — retrying with strict label sanitization"
    exec env STRICT_SANITIZE=1 ISSUES_JSON="$issues" bash "${BASH_SOURCE[0]}"
  fi
fi
