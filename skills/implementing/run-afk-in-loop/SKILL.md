---
name: run-afk-in-loop
description: Loop through unblocked AFK GitHub issues in parallel waves (capped by CONCURRENCY, default 4). Each issue runs /test-driven-dev in an isolated git worktree; outcome is parsed from a structured marker; successful branches are sequentially merged back and the issues closed. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in parallel waves. Each issue runs in its own git worktree on its own branch. After the wave, the orchestrator sequentially merges successful branches back and closes the issues. Failed and blocked issues are left for inspection.

The inner agent runs under `claude --print`, which is non-interactive — see `AGENT_PREAMBLE.md` for the rules that prevent the agent from asking clarifying questions into the void.

## Context the agent sees

Each AFK agent runs `claude --print` inside its worktree. It auto-loads `CLAUDE.md` and `AGENTS.md` from the branch checkout, plus the skills registered in `.claude-plugin/plugin.json`. It does NOT see the orchestrator's conversation or cross-session auto-memory — the worktree at `../wt-issue-N` maps to a different `~/.claude/projects/...` slot, which is empty. Encode anything the agent must follow in AGENTS.md or the issue body.

## Workflow

### 1. Fetch issues and identify the wave

The wave is the first `CONCURRENCY` (default 4) unblocked open AFK issues. An issue is unblocked when every "Blocked by #N" in its body refers to a closed issue. If the wave is empty, print the completion summary (see below) and stop.

```bash
CONCURRENCY="${CONCURRENCY:-4}"
issues=$(gh issue list --state all --json number,title,body,state,labels --limit 100)

# Print unblocked open AFK issue numbers, one per line.
get_unblocked() {
  local issues_json="$1"
  while IFS= read -r num; do
    [ -z "$num" ] && continue
    local body blocked=false
    body=$(echo "$issues_json" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .body // ""')
    while IFS= read -r b; do
      [ -z "$b" ] && continue
      local bs
      bs=$(echo "$issues_json" | jq -r --argjson b "$b" '.[] | select(.number == $b) | .state')
      [ "$bs" = "OPEN" ] && blocked=true && break
    done < <(echo "$body" | grep -ioE 'Blocked by #[0-9]+' | grep -oE '[0-9]+$' || true)
    $blocked || echo "$num"
  done < <(echo "$issues_json" | \
    jq -r '.[] | select(.labels[].name == "afk" and .state == "OPEN") | .number')
}

wave=()
while IFS= read -r num; do
  wave+=("$num")
  [ "${#wave[@]}" -ge "$CONCURRENCY" ] && break
done < <(get_unblocked "$issues")
```

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
LOGS_DIR="${LOGS_DIR:-/tmp/afk-logs-$$}"
mkdir -p "$LOGS_DIR"

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
    > "$LOGS_DIR/issue-${num}.log" 2>&1 &
done

wait
```

Worktrees isolate each agent: their `git add` / `git commit` / test runs / file edits never collide. The preamble forbids clarifying questions and requires a structured marker at the end of the agent's output.

### 4. Parse markers, surface per-issue outcomes

For each issue in the wave, find the **last** marker line in its log — only the final marker counts, so the agent quoting the preamble earlier in its output can't shadow the real outcome. Treat absence of a marker as failure regardless of exit code.

```bash
for num in "${wave[@]}"; do
  log="$LOGS_DIR/issue-${num}.log"
  last_marker=$(grep -E '^=== AFK-RESULT: (success|blocked) ===$' "$log" | tail -1)
  # branch on last_marker (success / blocked / empty) and print the per-issue result block below
done
```

Print a per-issue result block:

```
─── #X — <title> ───
Outcome: ✓ agent succeeded (marker present)
         (or)   ⏸ blocked — <reason from marker>
         (or)   ✗ failed (no marker)
Tail of agent output:
<last ~10 lines of $LOGS_DIR/issue-X.log>
───
```

### 5. Sequentially merge successes back, close issues, clean up

Iterate the wave **in order**, one issue at a time (not in parallel — merges must serialize on the current branch):

```bash
for num in "${wave[@]}"; do
  log="$LOGS_DIR/issue-${num}.log"
  last_marker=$(grep -E '^=== AFK-RESULT: (success|blocked) ===$' "$log" | tail -1)
  if [ "$last_marker" != "=== AFK-RESULT: success ===" ]; then
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
    merge_sha=$(git rev-parse HEAD)
    gh issue close "$num" --comment "Completed by /run-afk-in-loop in $merge_sha"
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
