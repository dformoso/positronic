---
name: run-afk-in-loop
description: Loop through all unblocked AFK GitHub issues in parallel waves, implementing each with /test-driven-dev inside an isolated git worktree. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in parallel waves. Each issue runs in its own git worktree on its own branch. After the wave, the orchestrator sequentially merges successful branches back and closes the issues. Failed and blocked issues are left for inspection.

The inner agent runs under `claude --print`, which is non-interactive — see `AGENT_PREAMBLE.md` for the rules that prevent the agent from asking clarifying questions into the void.

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

Resolve the latest SPEC and PRD (if those directories exist). Use `sort -V` so `10.md` ranks above `2.md`:

```bash
spec_path=""
prd_path=""
[ -d specs ] && spec_path=$(ls specs/[0-9]*.md 2>/dev/null | sort -V | tail -1 || true)
[ -d prds ]  && prd_path=$(ls prds/[0-9]*.md  2>/dev/null | sort -V | tail -1 || true)
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

### 3. Implement wave issues in parallel, each in its own worktree

For each issue in the wave: create a fresh worktree on a new branch `afk/issue-<N>`, then run `/test-driven-dev` in that worktree. The agent's prompt MUST include the contents of `AGENT_PREAMBLE.md` so the agent knows it cannot ask the user and must emit a result marker.

```bash
mkdir -p /tmp/afk-logs

# Load the preamble once.
preamble=$(cat skills/implementing/run-afk-in-loop/AGENT_PREAMBLE.md)

for num in "${wave[@]}"; do
  title=$(echo "$issues" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
  body=$(gh issue view "$num" --json body | jq -r '.body')

  # Fresh worktree on a fresh branch, sibling of the repo.
  worktree="../wt-issue-${num}"
  branch="afk/issue-${num}"
  [ -d "$worktree" ] && git worktree remove "$worktree" --force 2>/dev/null || true
  git branch -D "$branch" 2>/dev/null || true
  git worktree add -b "$branch" "$worktree"

  prompt="/test-driven-dev Implement GitHub issue #${num}: ${title}

${preamble}

---

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

  ( cd "$worktree" && claude --dangerously-skip-permissions --print "${prompt}" ) \
    > "/tmp/afk-logs/issue-${num}.log" 2>&1 &
done

wait
```

Worktrees isolate each agent: their `git add` / `git commit` / test runs / file edits never collide. The preamble forbids clarifying questions and requires a structured marker at the end of the agent's output.

### 4. Parse markers, surface per-issue outcomes

For each issue in the wave, scan its log for `=== AFK-RESULT: success ===` or `=== AFK-RESULT: blocked ===`. Treat absence of a marker as failure regardless of exit code.

Print a per-issue result block:

```
─── #X — <title> ───
Outcome: ✓ agent succeeded (marker present)
         (or)   ⏸ blocked — <reason from marker>
         (or)   ✗ failed (no marker)
Tail of agent output:
<last ~10 lines of /tmp/afk-logs/issue-X.log>
───
```

### 5. Sequentially merge successes back, close issues, clean up

Iterate the wave **in order**, one issue at a time (not in parallel — merges must serialize on the current branch):

```bash
for num in "${wave[@]}"; do
  log="/tmp/afk-logs/issue-${num}.log"
  if ! grep -q '^=== AFK-RESULT: success ===$' "$log"; then
    continue   # blocked or failed — leave worktree + branch alone
  fi

  branch="afk/issue-${num}"
  base=$(git merge-base HEAD "$branch" 2>/dev/null || echo "")
  head=$(git rev-parse "$branch")
  if [ "$base" = "$head" ]; then
    echo "#${num}: marker claimed success but branch has no commits — leaving as-is"
    continue
  fi

  if git merge --no-ff --no-edit -m "Merge afk/issue-${num}" "$branch"; then
    gh issue close "$num" --comment "Completed by /run-afk-in-loop"
    git worktree remove "../wt-issue-${num}" --force
    git branch -d "$branch"
  else
    git merge --abort
    echo "#${num}: merge conflict — worktree preserved at ../wt-issue-${num}"
  fi
done
```

On merge conflict: abort the merge, leave the worktree and branch alone, do NOT close the issue. The user resolves manually.

Print the wave summary:

```
Wave [N/total] complete — #X ✓, #Y ⏸ blocked, #Z ✗ failed
```

Then return to step 1.

### Completion summary

When no unblocked AFK issues remain, print:

```
All AFK issues complete.
Awaiting your input (HITL): #A — <title>, #B — <title>, ...
Blocked (waiting on HITL): #C — <title>, ...
```

List any open HITL issues and any open AFK issues that are still blocked (e.g. by a HITL issue or a still-failing AFK issue).

## Running in parallel (unattended)

For unattended parallel execution with per-issue credit-exhaustion retry:

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-parallel.sh
```

Set `CONCURRENCY=N` (default: 4) to control how many issues run simultaneously per wave. The script implements the same workflow described above, including worktree isolation, preamble injection, marker parsing, and sequential merge-back.

## Running with credit-exhaustion retry (sequential)

For sequential execution wrapping the slash invocation in a credit-retry loop:

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-afk-loop.sh
```

This invokes `claude --print "/run-afk-in-loop"` and retries the whole loop on credit exhaustion. The slash command itself executes the workflow above.
