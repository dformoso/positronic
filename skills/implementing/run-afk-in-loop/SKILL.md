---
name: run-afk-in-loop
description: Loop through all unblocked AFK GitHub issues in parallel waves, implementing each with /test-driven-dev. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in parallel waves.

## Workflow

### 1. Fetch issues and identify the wave

```bash
issues=$(gh issue list --state all --json number,title,body,state,labels --limit 100)
```

From `issues`, find **all** open issues labeled `afk` where every "Blocked by #N" issue is already closed. This set is the **wave**. If the wave is empty, print the completion summary (see below) and stop.

### 2. Compute progress and announce the wave

Compute counts:

```bash
total=$(echo "$issues" | jq '[.[] | select(.labels[].name == "afk")] | length')
done_count=$(echo "$issues" | jq '[.[] | select(.labels[].name == "afk" and .state == "CLOSED")] | length')
```

Resolve the latest SPEC and PRD (if those directories exist):

```bash
spec_path=""
prd_path=""
[ -d specs ] && spec_path=$(ls specs/[0-9]*.md 2>/dev/null | sort | tail -1 || true)
[ -d prds ]  && prd_path=$(ls prds/[0-9]*.md 2>/dev/null | sort | tail -1 || true)
```

Print a rich announcement for the user. For each issue in the wave, fetch the body and surface the title, the "What to build" section, any "Exemplar to mirror" / "Decisions taken" / "Shared conventions" sections present, and the source documents that will be passed:

```
Wave [done_count+1..done_count+N]/total — N issues:

  #X — <title>
    What to build: <first paragraph from issue body>
    Exemplar to mirror: <if present in issue body>
    Decisions taken: <if present, one-line summary>
    Source documents: <spec_path>, <prd_path>
  #Y — <title>
    ...
```

This gives the user clear visibility into what each parallel agent is about to do, before any subprocesses start.

### 3. Implement wave issues in parallel

For each issue in the wave, fetch the full body, then build a `/test-driven-dev` prompt that includes the full issue body and pointers to the SPEC and PRD (when present). Redirect each subprocess's output to a per-issue log file so per-issue results can be surfaced after `wait`:

```bash
mkdir -p /tmp/afk-logs

for num in "${wave[@]}"; do
  title=$(echo "$issues" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
  body=$(gh issue view "$num" --json body | jq -r '.body')

  prompt="/test-driven-dev Implement GitHub issue #${num}: ${title}

Issue body:
${body}"

  if [ -n "$spec_path" ] || [ -n "$prd_path" ]; then
    prompt="${prompt}

Source documents to read before starting:"
    [ -n "$spec_path" ] && prompt="${prompt}
- Latest SPEC: ${spec_path}"
    [ -n "$prd_path" ] && prompt="${prompt}
- Latest PRD: ${prd_path}"
  fi

  claude --dangerously-skip-permissions --print "${prompt}" \
    > "/tmp/afk-logs/issue-${num}.log" 2>&1 &
done

wait
```

Passing the full body and source docs prevents AFK agents from re-deriving decisions captured in the SPEC. Per-issue log files keep parallel output untangled.

### 4. Surface per-issue results and close completed issues

For each issue in the wave, read its log, determine the outcome, and print a per-issue result block to the user:

```
─── #X — <title> ───
Outcome: ✓ completed   (or)   ✗ failed (<reason from log>)
Tail of agent output:
<last ~10 lines of /tmp/afk-logs/issue-X.log>
───
```

This gives per-issue feedback during the loop, not just a wave-level pass/fail.

Then close successful issues:

```bash
gh issue close X --comment "Completed by /run-afk-in-loop"
```

Print the wave summary:

```
Wave [N/total] complete — closed #X ✓, #Y ✓, #Z ✗ (manual recovery needed)
```

Then return to step 1.

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
bash skills/implementing/run-afk-in-loop/scripts/run-parallel.sh
```

Set `CONCURRENCY=N` (default: 4) to control how many issues run simultaneously per wave.

## Running with credit-exhaustion retry (sequential)

For sequential execution with automatic retry on credit exhaustion:

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-afk-loop.sh
```
