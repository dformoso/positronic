---
name: run-afk-in-loop
description: Loop through unblocked AFK GitHub issues in parallel waves (capped by CONCURRENCY, default 4). Each issue runs /test-driven-dev in an isolated git worktree; outcome is parsed from a structured marker; successful branches are sequentially merged back and the issues closed. Use when user wants to run AFK issues automatically or says "run the loop".
disable-model-invocation: true
---

# Run AFK In Loop

Implement all unblocked AFK GitHub issues in parallel waves. Each issue runs in its own git worktree on its own branch. After the wave, the orchestrator sequentially merges successful branches back and closes the issues. Failed and blocked issues are left for inspection.

The inner agent runs under `claude --print`, which is non-interactive — see `AGENT_PREAMBLE.md` for the rules that prevent the agent from asking clarifying questions into the void.

## Context the agent sees

Each AFK agent runs `claude --print` inside its worktree. It auto-loads `CLAUDE.md` and `AGENTS.md` from the branch checkout, plus the skills registered in `.claude-plugin/plugin.json`. It does NOT see the orchestrator's conversation or cross-session auto-memory — the worktree at `../wt-issue-N` maps to a different `~/.claude/projects/...` slot, which is empty. Encode anything the agent must follow in AGENTS.md or the issue body. One exception to the empty slot: a gitignored `.env` at the repo root is copied into each worktree (step 3) so credentials provisioned by `/to-issues` are readable.

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

Resolve the latest SPEC and PRD (if those directories exist):

```bash
spec_path=""
prd_path=""
[ -d definitions/specs ] && spec_path=$(ls definitions/specs/[0-9]*.md 2>/dev/null | sort | tail -1 || true)
[ -d definitions/prds ]  && prd_path=$(ls definitions/prds/[0-9]*.md  2>/dev/null | sort | tail -1 || true)
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

# Load the preamble once. ${CLAUDE_SKILL_DIR} = this skill's install dir;
# fall back to the repo-relative path when run from the positronic checkout.
SKILL_DIR="${CLAUDE_SKILL_DIR:-skills/implementing/run-afk-in-loop}"
preamble=$(cat "$SKILL_DIR/AGENT_PREAMBLE.md")

for num in "${wave[@]}"; do
  title=$(echo "$issues" | jq -r --argjson n "$num" '.[] | select(.number == $n) | .title')
  body=$(gh issue view "$num" --json body | jq -r '.body')

  # Fresh worktree on a fresh branch, sibling of the repo.
  worktree="../wt-issue-${num}"
  branch="afk/issue-${num}"
  [ -d "$worktree" ] && git worktree remove "$worktree" --force 2>/dev/null || true
  git branch -D "$branch" 2>/dev/null || true
  git worktree add -b "$branch" "$worktree"

  # Local secrets are gitignored, so git won't carry them into the fresh worktree.
  # Copy them in so the non-interactive agent can read them (provisioned by /to-issues).
  [ -f .env ] && cp .env "$worktree/.env"

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

### 6. Pause if any agent hit a usage limit

Before returning to step 1, scan the wave's logs for a session-limit signature. If one is present, parse the reset time and sleep until then — otherwise the next wave will fast-fail every issue against the same limit and drain your next session window.

```bash
# shellcheck source=scripts/lib-limit-wait.sh
. "${CLAUDE_SKILL_DIR:-skills/implementing/run-afk-in-loop}/scripts/lib-limit-wait.sh"
combined=$(cat "$LOGS_DIR"/issue-*.log 2>/dev/null)
wait_seconds=$(detect_limit_wait_seconds "$combined")
if [ -n "$wait_seconds" ]; then
  pause_with_heartbeat "$wait_seconds" "run-afk-in-loop"
fi
```

This honors the same env vars as the wrapper scripts: `RETRY_WAIT_SECONDS` (transient errors / no reset hint, default 30m), `SESSION_LIMIT_WAIT_SECONDS` (fallback when the limit has no parsable reset, default 6h), and `WAIT_DISABLED=1` to skip the pause for tests.

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

For unattended parallel execution with per-issue usage-limit retry (run from your positronic checkout or by absolute path; the script acts on the git repo in your current directory):

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-parallel.sh
```

Set `CONCURRENCY=N` (default: 4) to control how many issues run simultaneously per wave. The script implements the same workflow described above, including worktree isolation, preamble injection, marker parsing, and sequential merge-back.

## Running with usage-limit retry (sequential)

For sequential execution wrapping the slash invocation in a retry loop (run from your positronic checkout or by absolute path; it acts on the git repo in your current directory):

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-afk-loop.sh
```

This invokes `claude --print "/run-afk-in-loop"` and retries the whole loop when a usage limit is hit. The slash command itself executes the workflow above.

## Usage-limit handling

The inline workflow (step 6) and both wrapper scripts share `lib-limit-wait.sh`, which parses claude's error output (no extra claude calls) and pauses until the limit resets, then auto-resumes:

- **Session limit with a reset hint** ("Your limit will reset at 3pm" / "15:00" / "(UTC)"): parses the wall-clock time and sleeps until then, with a 60s clock-skew buffer.
- **Usage / session limit without a parsable hint**: falls back to `SESSION_LIMIT_WAIT_SECONDS` (default `21600` = 6h) — long enough to outlast the 5-hour session window.
- **Transient errors** (credit, quota, overload, rate-limit): falls back to `RETRY_WAIT_SECONDS` (default `1800` = 30m).

While paused, the script prints `[label] usage limit hit — pausing until HH:MM (~N min). Will auto-resume.`, a heartbeat every 60s (or every 5m for waits >10m), and `resuming after usage-limit reset.` when the wait is over. In `run-parallel.sh`, the wave heartbeat labels each paused issue with its reset time so the orchestrator never goes silent.

Tests can set `WAIT_DISABLED=1` to skip the actual sleep while keeping the detection logic exercised.
