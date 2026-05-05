---
name: run-afk-in-loop
description: Loop through all unblocked AFK GitHub issues in order, implementing each with /tdd, updating BOARD.md at each step. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in sequence, updating `BOARD.md` after each state change.

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

Then update the board with the issue marked active:

```bash
echo "$issues" | ACTIVE_ISSUE=X bash skills/slash-only/run-afk-in-loop/scripts/update-board.sh
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
issues=$(gh issue list --state all --json number,title,body,state,labels --limit 100)
echo "$issues" | bash skills/slash-only/run-afk-in-loop/scripts/update-board.sh
```

Print: `[N/total] Closed #X ✓` — then return to step 1. The refreshed `$issues` from this step already reflects the closed issue, so blocker re-evaluation in step 1 is automatically up to date.

### Completion summary

When no unblocked AFK issues remain, print:

```
All AFK issues complete.
Awaiting your input (HITL): #A — <title>, #B — <title>, ...
Blocked (waiting on HITL): #C — <title>, ...
```

List any open HITL issues and any open AFK issues that are still blocked.

## Running with credit-exhaustion retry

For unattended execution, use the wrapper script instead of invoking the skill directly:

```bash
bash skills/slash-only/run-afk-in-loop/scripts/run-afk-loop.sh
```
