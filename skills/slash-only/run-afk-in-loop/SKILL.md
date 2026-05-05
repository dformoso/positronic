---
name: run-afk-in-loop
description: Loop through all unblocked AFK GitHub issues in order, implementing each with /tdd, updating BOARD.md at each step. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in sequence, updating `BOARD.md` after each state change.

## Board invariant

**Every board update must show the complete issue list — all issues, all states, all dependencies — not just the issue currently being worked on.** Always re-fetch from GitHub immediately before writing the board; never pass a cached variable. This ensures the board is always a faithful snapshot of the full project state.

The helper for board updates is:

```bash
update_board() {
  local active="${1:-}"
  gh issue list --state all --json number,title,body,state,labels --limit 100 \
    | ACTIVE_ISSUES="$active" bash skills/slash-only/run-afk-in-loop/scripts/update-board.sh
}
```

`ACTIVE_ISSUES` is a space-separated list of issue numbers currently being implemented (supports future concurrent execution). Pass empty string when no issue is active.

## Workflow

### 1. Fetch issues and find next

```bash
issues=$(gh issue list --state all --json number,title,body,state,labels --limit 100)
```

From `issues`, find open issues with label `afk`. For each candidate, extract "Blocked by #N" lines from the body and check if any referenced issue N is still `OPEN` — if so, skip it. Pick the lowest number from the remaining unblocked set. If none exist, print the completion summary (see below) and stop.

### 2. Compute progress counter

```bash
total=$(echo "$issues" | jq '[.[] | select(.labels[].name == "afk")] | length')
done_count=$(echo "$issues" | jq '[.[] | select(.labels[].name == "afk" and .state == "CLOSED")] | length')
n=$((done_count + 1))
```

### 3. Print status line and mark active

Output exactly:

```
[N/total] Starting #X — <title>  →  [BOARD.md](BOARD.md)
```

Then re-fetch and update the board with the issue marked active:

```bash
update_board X
```

### 4. Implement with /tdd

Invoke `/tdd` with this prompt:

> Implement GitHub issue #X: **<title>**
>
> Acceptance criteria:
> <paste the acceptance criteria lines verbatim from the issue body>

### 5. Close the issue and update board

```bash
gh issue close X --comment "Completed by /run-afk-in-loop"
update_board
```

Print: `[N/total] Closed #X ✓` — then return to step 1.

### Completion summary

When no unblocked AFK issues remain, print:

```
All AFK issues complete.
Awaiting your input (HITL): #A — <title>, #B — <title>, ...
Blocked (waiting on HITL): #C — <title>, ...
```

List any open HITL issues and any open AFK issues that are still blocked.

## Documentation updates

After setting up a new project's GitHub issues, update two files so future contributors know `/run-afk-in-loop` is the final step and understand what `BOARD.md` shows.

### README.md

Add a section that describes the full pipeline and the board. Example:

```markdown
## Workflow

This project uses [positronic](https://github.com/dmformoso/positronic) for AI-assisted development.

| Step | Command | What it does |
|------|---------|--------------|
| 1 | `/grill-me` | Self-interviews the idea, produces Assumption Log |
| 2 | `/to-prd` | Synthesizes Q&A into a PRD |
| 3 | `/to-issues` | Decomposes PRD into GitHub issues (AFK / HITL) |
| 4 | `/run-afk-in-loop` | Implements all unblocked AFK issues in sequence |

After step 3, `BOARD.md` in the repo root shows the full issue tree: every issue, its
AFK/HITL badge, its dependency edges, and its current state (○ READY, ▶ ACTIVE,
✗ BLOCKED, ◈ HITL, ✓ DONE). Run `/run-afk-in-loop` to start step 4; the board
updates automatically as issues are completed.
```

### AGENTS.md

Add `/run-afk-in-loop` to the **Phase Awareness** table (§5) under the *Implementing* row, and add a note that `BOARD.md` is the live issue tree:

```markdown
- **Implementing** — spec is decided → run `tdd` for individual issues, or `/run-afk-in-loop`
  to implement all unblocked AFK issues automatically. `BOARD.md` (repo root) is the live
  issue tree: edges are blockers, badges are AFK/HITL, state symbols show progress.
```

## Running with credit-exhaustion retry

For unattended execution, use the wrapper script instead of invoking the skill directly:

```bash
bash skills/slash-only/run-afk-in-loop/scripts/run-afk-loop.sh
```
