#!/usr/bin/env bash
# Reads gh issue list JSON from stdin, writes BOARD.md to repo root.
# Usage:
#   gh issue list --state all --json number,title,body,state,labels --limit 100 | bash update-board.sh
#   cat fixture.json | bash update-board.sh   # for testing
set -euo pipefail

BOARD_FILE="${BOARD_FILE:-BOARD.md}"
ACTIVE_ISSUE="${ACTIVE_ISSUE:-}"  # set by run-afk-in-loop skill when working an issue

issues=$(cat)

# ── helpers ──────────────────────────────────────────────────────────────────

# Extract first sentence from "## What to build" section
deliverable() {
  local body="$1"
  echo "$body" \
    | awk '/^## What to build/{found=1; next} found && /^## /{exit} found && NF{print; exit}' \
    | sed 's/\. .*/\./' \
    | sed "s/[\"'\`]//g"
}

# Extract up to 4 acceptance criteria lines
criteria() {
  local body="$1"
  echo "$body" \
    | awk '/^## Acceptance criteria/{found=1; next} found && /^## /{exit} found && /- \[/{print}' \
    | head -4 \
    | sed 's/- \[x\]/✓/' \
    | sed 's/- \[ \]/○/' \
    | sed "s/[\"'\`]//g"
}

# Extract blocked-by issue numbers from body
blockers() {
  local body="$1"
  echo "$body" | grep -oE 'Blocked by #[0-9]+' | grep -oE '[0-9]+$' || true
}

# Determine status class for a node
status_class() {
  local number="$1" state="$2" label="$3" blocker_numbers="$4"
  if [ "$state" = "CLOSED" ]; then
    echo "done"
    return
  fi
  if [ "$label" = "hitl" ]; then
    echo "hitl"
    return
  fi
  if [ -n "$ACTIVE_ISSUE" ] && [ "$number" = "$ACTIVE_ISSUE" ]; then
    echo "active"
    return
  fi
  # Check if any blocker is still open
  for b in $blocker_numbers; do
    blocker_state=$(echo "$issues" | jq -r --argjson n "$b" '.[] | select(.number == $n) | .state')
    if [ "$blocker_state" = "OPEN" ]; then
      echo "blocked"
      return
    fi
  done
  echo "ready"
}

# ── build node and edge lists ─────────────────────────────────────────────────

nodes=""
edges=""
class_assignments=""

while IFS= read -r issue; do
  number=$(echo "$issue" | jq -r '.number')
  title=$(echo "$issue"  | jq -r '.title' | sed "s/[\"'\`]//g")
  state=$(echo "$issue"  | jq -r '.state')
  body=$(echo "$issue"   | jq -r '.body // ""')
  label=$(echo "$issue"  | jq -r '[.labels[].name] | map(select(. == "afk" or . == "hitl")) | first // ""')

  # Skip issues with no afk/hitl label (e.g. parent PRD issues)
  [ -z "$label" ] && continue

  blocker_nums=$(blockers "$body")

  sc=$(status_class "$number" "$state" "$label" "$blocker_nums")

  # State symbol
  case "$sc" in
    done)    state_str="✓  DONE"    ;;
    ready)   state_str="○  READY"   ;;
    blocked) state_str="✗  BLOCKED" ;;
    active)  state_str="▶  ACTIVE"  ;;
    hitl)    state_str="◈  HITL"    ;;
    *)       state_str="${sc^^}"    ;;
  esac

  # Build node label
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
