---
name: run-afk-in-loop
description: Loop through all unblocked AFK GitHub issues in parallel waves, implementing each with /tdd, updating BOARD.md at each step. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in parallel waves, updating `BOARD.md` after each wave.

## Workflow

### 1. Fetch issues and identify the wave

```bash
issues=$(gh issue list --state all --json number,title,body,state,labels --limit 100)
```

From `issues`, find **all** open issues labeled `afk` where every "Blocked by #N" issue is already closed. This set is the **wave**. If the wave is empty, print the completion summary (see below) and stop.

### 2. Compute progress and print status

```bash
total=$(echo "$issues" | jq '[.[] | select(.labels[].name == "afk")] | length')
done_count=$(echo "$issues" | jq '[.[] | select(.labels[].name == "afk" and .state == "CLOSED")] | length')
```

Output:

```
Wave [done_count/total]: #X — <title>, #Y — <title>, ...  →  [BOARD.md](BOARD.md)
```

### 3. Mark all wave issues active and update board

```bash
ACTIVE_ISSUES="X Y Z" bash skills/slash-only/run-afk-in-loop/scripts/update-board.sh
```

### 4. Implement wave issues in parallel

For each issue in the wave, build a `/tdd` prompt and spawn a `claude` subprocess:

```bash
claude --dangerously-skip-permissions --print "/tdd Implement GitHub issue #X: <title>

Acceptance criteria:
<acceptance criteria lines from the issue body>" &
```

Then wait for all spawned processes:

```bash
wait
```

### 5. Close completed issues and update board

For each issue that finished successfully:

```bash
gh issue close X --comment "Completed by /run-afk-in-loop"
```

Then refresh the board:

```bash
bash skills/slash-only/run-afk-in-loop/scripts/update-board.sh
```

Print: `Wave [N/total] complete — closed #X ✓, #Y ✓` — then return to step 1.

### Completion summary

When no unblocked AFK issues remain, print:

```
All AFK issues complete.
Awaiting your input (HITL): #A — <title>, #B — <title>, ...
Blocked (waiting on HITL): #C — <title>, ...
```

List any open HITL issues and any open AFK issues that are still blocked.

## Running in parallel (unattended)

For unattended parallel execution with per-issue credit-exhaustion retry:

```bash
bash skills/slash-only/run-afk-in-loop/scripts/run-parallel.sh
```

Set `CONCURRENCY=N` (default: 4) to control how many issues run simultaneously per wave.

## Running with credit-exhaustion retry (sequential)

For sequential execution with automatic retry on credit exhaustion:

```bash
bash skills/slash-only/run-afk-in-loop/scripts/run-afk-loop.sh
```
