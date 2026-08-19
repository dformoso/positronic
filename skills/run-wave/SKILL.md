---
name: run-wave
description: Work the issue backlog in waves — launch one wave of issues in parallel, then review every remaining issue against what the wave actually built (close what's done, re-scope what changed, drop what's moot), then fire the next wave. Re-run until the backlog is empty. Use when the user wants to work the backlog, run the next wave, or implement the issues /to-issues created. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Run Wave

Work the backlog in **waves**: a batch of non-colliding issues run in parallel, then a review of everything still open, then the next batch. This is AGENTS.md §9 — decompose, fan out, coalesce, re-wave — with the GitHub backlog as the work-list.

**One wave per invocation.** Re-firing is the loop, the same way `/clean-house` re-fires. Each wave changes the codebase, and the review that follows is only possible *because* the code changed — an issue written against an imagined module reads differently once the real one exists. Batching all waves into one run would skip every review, which is the part that keeps the backlog honest.

**The order is the point.** Certain work first, uncertain work last. A wave doesn't just deliver its own issues — it converts guesses in later issues into facts. Running a low-certainty issue early wastes that.

Neighbours:

| Skill | Its job |
|---|---|
| `/to-issues` | Cuts the backlog and assigns the initial waves. Runs once per increment |
| `/run-wave` (this) | Works one wave, reconciles the rest, hands back. Runs until the backlog is empty |
| `test-driven-dev` | What each agent actually runs on its issue. Also fine standalone for a single issue |
| `/review-pr` | Reviews a finished branch. Runs on what a wave produced, before it ships |

## Process

### 0. Orient

```bash
gh issue list --state open --json number,title,labels,body --limit 200
```

Read `definitions/spec.md` and `definitions/journeys.md` if they exist — the review in step 4 judges issues against them, and you cannot judge relevance without knowing what the product is currently defined to be.

**No wave labels?** The backlog predates this loop. Assign waves now using the certainty bands in `${SKILL_DIR}/../to-issues/SKILL.md` §3b (`${SKILL_DIR}` = the directory containing this file), show the user the cut, and get their agreement before launching anything.

**Backlog out of date?** If `definitions/spec.md` was amended after the newest issue was filed, stop and prompt the user to run `/to-issues` first — it owns increment reconciliation. Don't reconcile an amendment here; that would put the same job in two skills.

### 1. Pick the wave

The wave is the open issues carrying the lowest `wave-N` label that still has any. Drop from it:

- Anything `Blocked by` an issue that is still open. If that leaves the wave empty, the labels are wrong — say so and stop rather than launching a wave that can't work.
- Anything whose credentials aren't provisioned (`/to-issues` §5). Move it to `hitl` and say why.

Split the remainder:

- **`hitl` issues** — the user works these with you, inline, before the fan-out. They are usually the shape-establishing slices, and the parallel agents will mirror whatever they produce, so getting them right first is what makes the rest cheap.
- **`afk` issues** — the fan-out batch.

Show the user the wave: issue numbers, titles, which are HITL, and anything you dropped. Get their go-ahead before launching.

### 2. Launch the wave

One agent per `afk` issue, all launched together, each in its own git worktree so concurrent edits can't collide. Run every agent on the frontier model tier at the maximum available thinking tier (AGENTS.md §9) — never a cheaper tier to save tokens.

**One level only.** You fan out; the agents don't. A subagent works its issue and returns. If its scope turns out to be bigger than the issue, it says so in its report — it does not recruit help and does not touch a sibling's issue.

Each agent's brief:

- The issue body, whole. It already carries the source spec pointer, the exemplar to mirror, shared conventions, acceptance criteria, and the scope discipline.
- Run `test-driven-dev` on it. The acceptance criteria are the tests.
- Stay inside the slice. **Do not create GitHub issues** — see step 3.
- Report back: what landed, which acceptance criteria are met, what's still failing, and anything noticed outside the slice.

While the wave runs, keep the user informed — which agents are still working, which have returned (AGENTS.md §7: silent is not the same as done).

### 3. Land the work and collect what the wave saw

Coalesce — this is yours, not the agents' (AGENTS.md §9). Merge each agent's branch, reconcile overlaps, resolve conflicts, and run the full test suite on the merged result. **A wave isn't done when the agents return; it's done when their output is integrated and green.** An agent whose work doesn't merge cleanly gets its issue reopened with what conflicted, not a silent revert.

Then collect the out-of-scope observations the agents reported. They worked under `test-driven-dev` § Bugs found along the way: fix inside the slice, report outside it, interrupt for anything that breaks a shipped journey or loses data. Holding the outside-the-slice reports until step 4 is what keeps the backlog converging — half of what would get filed mid-wave is made moot by a later slice in the same wave.

### 4. Review every remaining issue

The heart of the loop, and the reason waves beat a flat backlog. The codebase is now different from the one every remaining issue was written against. Walk each open issue and ask, in order:

| Question | If yes |
|---|---|
| **Already satisfied?** Does the merged code meet its acceptance criteria — because a wave slice covered it, or an in-place fix absorbed it? | Close it, with a comment naming what satisfied it |
| **Still wanted?** Is the capability still in the current journeys artifact and SPEC? | If not, close it citing the artifact that dropped it |
| **Still correct?** Does it still name the right module, exemplar, interface, or convention? The wave may have moved all four | Edit the body. Don't file a replacement |
| **Still in the right wave?** The wave resolved unknowns — some later issues are now certain. It may also have exposed new ones | Relabel `wave-N`. Promote what got certain; demote what got murky |

Then decide the out-of-scope reports from step 3, one at a time:

- **Fold into an open issue** whose scope already covers it — preferred, and usually right.
- **File a new issue** — this is the *only* place in the loop where a new issue is created, because it's the only place a human is looking at the whole backlog at once. Give it a wave label like any other.
- **Drop it**, with a one-line reason. Say so out loud; a silently dropped observation is how a known bug becomes a surprise.

**Gated, not silent.** Show the user the full set of proposed closes, edits, relabels, and new issues — with reasons — and execute only what they approve. Closing an issue nobody agreed to close is the failure mode this gate exists for.

### 5. Report and re-fire

Print:

```text
## Wave N — done
- Merged: #12, #14, #15 · Suite: green
- Reopened: #13 (merge conflict in billing/, see comment)

## Backlog reconciled
- Closed as done: #21 — covered by #14's in-place fix
- Dropped: #24 — capability cut by the `team-workspaces` amendment
- Re-scoped: #26 — now mirrors billing/reconcile.py, not the old sketch
- Promoted to wave 2: #29 — the schema it was waiting on now exists
- Filed: #31 — timezone bug seen from #15, outside its slice

## Next
Wave 2: #26, #29, #31 (2 afk, 1 hitl) — re-run /run-wave
```

If open issues remain, tell the user to re-fire. If none do, say the backlog is empty and prompt the shipping phase: `/review-pr`, then `/audit-drift`.
