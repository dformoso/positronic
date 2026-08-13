---
name: improve-readability
description: Supervised comprehension-and-reduction pass over an established codebase — find where the code costs its readers, and where it carries more machinery than the job needs, then fix both in gated slices: cut needless code and error paths, strip comments back to what the code and git can't say, delete spent docs, and rework the tests until they would actually catch a break. Use when the user says the code is hard to read, onboarding is slow, every change starts with archaeology, or asks to simplify the code, cut it down, strip the comments, clear out dead docs, or strengthen a weak test suite. Cutting whole features, requirements or modules belongs to /clean-house. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

# Improve Readability

Make the codebase cheap to understand. The metric is **time-till-understanding**: how long
the next reader — a new developer, a future agent context window — needs before they can
change the code safely.

**The largest term in that metric is how much code there is.** A line deleted is a line
nobody reads again, and an error path deleted is one fewer thing that can go wrong. So this
pass does not stop at explaining the code; it cuts the code down to what the job needs, then
makes the tests strong enough that the cutting was safe. Every move either lowers
time-till-understanding or is out of scope.

Grounding, one line per book (the full checklist is [CHECKS.md](CHECKS.md)):

- Complexity is whatever makes code hard to understand and change; it accumulates in small
  messes and it costs most where readers actually spend time (Ousterhout, *A Philosophy of
  Software Design*).
- Confusion is diagnosable. Every stumble is a shortage of **knowledge** (don't know what a
  thing means), **information** (know it, but must fetch it from somewhere else), or
  **processing power** (too much to hold at once) — and each shortage has a different fix
  (Hermans, *The Programmer's Brain*).
- Most excess machinery is braided concerns that could stand apart — deciding tangled with
  performing, state with time, validation with transport (Hickey, *Simple Made Easy*).
- Failure paths are interface surface. The strongest fix is making the bad state
  unrepresentable, not handling it (Ousterhout's *define errors out of existence*; King,
  *Parse, Don't Validate*).
- The fixes are small, named, behavior-preserving moves, kept in their own commits, worth
  applying where change actually happens (Fowler, *Refactoring*; Beck, *Tidy First?*).

Neighbours — keep the questions distinct:

| Skill | Its question |
|---|---|
| `/improve-readability` (this) | Can the next person understand it, and is any of it needless? Comprehension and reduction, inside the code that stays |
| `/clean-house` | What shouldn't exist *at all*? Cutting features, requirements, dependencies, modules, process |
| `/review-pr` | Is this diff safe to ship? A gate on the change, not a pass over the codebase |
| `/audit-failure-modes` | What will break? Enumerates risk and adds handling; this pass removes the failures worth removing |
| `diagnose` | Why is it broken? Bugs found here route there; obscurity found there routes here |

## Scope contract — three rules, no exceptions

1. **Remove machinery, never remove capability.** The contract a caller depends on comes out
   the far side unchanged: same inputs accepted, same outputs, same errors a caller catches.
   Inside that contract you may delete freely. Found a bug? Log it and route to `diagnose` —
   never fix it mid-pass. Structural commits carry no behavior change (two hats).
2. **You may only cut where the tests would catch you.** See step 0 and step 5. This licence
   is earned per area, never assumed. Where it isn't earned, the area is comments and docs
   only.
3. **Code altitude, not product altitude.** Reshaping interfaces, merging module clusters,
   moving seams, dropping a feature or a requirement — hand those to `/clean-house` as named
   candidates with the evidence attached. If a target smells deletable *as a whole*, don't
   polish it and don't shrink it: flag it and move on.

Vocabulary: **module / interface / seam / depth** as defined in
[../clean-house/LANGUAGE.md](../clean-house/LANGUAGE.md). Two terms of this skill's own:

- **Confusion log** — a running table of reader stumbles: *where / what confused / type
  (knowledge · information · processing) / fix candidate*. The type names the fix:
  knowledge → glossary, docs, domain terms in names; information → bring it to the point of
  use (rename, inline, comment where the question arises); processing → shrink what must be
  held at once (guard clauses, explaining variables, straighten control flow).
- **Machinery** — code that exists to manage the code rather than to do the job: error paths
  for states that can't occur, checks repeated at every layer, settings with one observed
  value, wrappers that only forward, a retry around a retry, a flag splitting one function
  into two paths. Machinery is what this pass cuts. Capability is what it never touches.

## Inputs

- `CONTEXT.md` and the PRD (`definitions/prd.md`) — the
  domain vocabulary and the top user journey, which is also the top *reading* journey
- The previous report: `ls docs/audits/*-readability.md 2>/dev/null | sort | tail -1` —
  proceed silently if none
- `git log` since the previous report — churn tells you where readers and changes go
- The test suite and how to run it in one command; the coverage command if one exists
- The codebase

If any of these don't exist, proceed silently — don't flag their absence.

## The pass

One pass per invocation; the report carries state forward; re-fire until dry. Hunting
(steps 0–3) is read-only — fan out subagents freely. Execution (step 4 on) is gated — edits
happen only after the user approves, never silently.

### 0. Baseline and safety net

Run the suite. Record wall clock and whether it is green *before* you touch anything.

Then find out whether the suite can actually catch you. **Coverage tells you the line ran.
It does not tell you the test noticed.** Get the stronger signal — measuring only the
hotspots step 1 picks out, so run the two together rather than in strict order:

- If a mutation-testing tool is already installed (`mutmut`, `cosmic-ray`, `Stryker`, `PIT`,
  `cargo-mutants`, `go-mutesting`), run it scoped to those files — a whole-repo run is too
  slow to be worth it. Surviving mutants are findings that carry their own proof.
- Otherwise, inject faults by hand: pick the three busiest functions, break one line in each
  (flip a comparison, drop a call, return a constant), run the suite, put it back. This is
  the [stash-and-fail](../test-driven-dev/tests.md) discipline pointed at the existing suite
  instead of a new test. Five minutes; most of the signal.

Never install a mutation tool for this pass — absence of one is an answer, and hand
injection covers it.

Sort every area you might touch into a lane. The lane caps the moves:

| Lane | Evidence | Allowed moves |
|---|---|---|
| Pinned | A test at the interface goes red when you break the code | Everything in CHECKS.md, including cutting machinery and collapsing error paths |
| Pinned on paper | Lines run under test, but the injected fault survived | The test is decorative. Strengthening it **is** the slice ([TESTS.md](TESTS.md)); then re-lane |
| Unpinned, load-bearing | No test reaches it | Characterization tests first (Feathers — pin what it *does*, not what it should do); then re-lane |
| Text only | Unpinned, low traffic, not worth pinning this pass | Comments, docs, tooling-verified renames — nothing that can change behavior |

### 1. Hotspots

Rank files by churn × size (`git log --format= --name-only | sort | uniq -c`, cross with
line counts or a complexity tool if one is already installed). Cross that with where bugs
actually landed — `git log --grep=fix --name-only` — because that is where the failure
points really are, not where you imagine they are. Take the top handful plus every file on
the main journey. **A finding in code nobody has touched for a year is not a finding** —
park it in the report, spend nothing on it.

### 2. Fresh-eyes read → confusion log

The skill's sensor, run *before* the checklist so findings come from real stumbles, not
smell-counting. Walk two journeys as if new to the repo:

- the top CUJ path end-to-end (entry point → core module → persistence/exit), and
- the first change a newcomer would plausibly be asked to make.

Per file: one 60-second first-glance note (what draws the eye, what the file seems to be
for), then the careful read. Log every stumble in the confusion log with its type. Where a
hotspot resists reading entirely, trace it with a variable table (one column per variable,
one row per step) — if *you* need the table, that's a processing-power finding in itself.

### 3. Sweep the checklists over the hotspots

Three sweeps, parallel read-only subagents per lens or per area:

- **[CHECKS.md](CHECKS.md)** — five lenses: obscurity, cognitive load, change-resistance,
  **excess machinery**, line level, plus the comment policy. Apply the guard-rails section
  while sweeping — the pass must not manufacture fragmentation, and must not cut capability
  while cutting machinery.
- **[TESTS.md](TESTS.md)** — over the tests covering those hotspots. Weak tests are findings
  in their own right, not only a gate on other work.
- **Spent docs** — every `.md` that is no longer read. Superseded plans, finished migration
  guides, how-tos for cut features, `docs/audits/` reports older than the latest per kind,
  READMEs describing a layout that changed. One auditor per candidate carrying
  [../clean-house/DELETION-AUDIT.md](../clean-house/DELETION-AUDIT.md) — readership is only
  half of it; a doc still cited but no longer true is the worse find. **Never touch
  decision records**: `docs/adr/` and the `definitions/` artifacts
  are supersede-never-edit by design — superseded is not spent.

Merge into findings: *file:line / check / evidence / responding move / lane*. A
confusion-log entry corroborated by a check outranks either alone.

### 4. Gate

Present findings ranked by **reader traffic × severity, plus machinery removed, discounted
by risk** — a slice with a negative diff outranks a same-severity slice that only moves text
around. Batch into slices of one intent each ("collapse the three retry layers in sync.ts",
"rename the ingest vocabulary to CONTEXT.md terms", "raise the parser tests to the public
interface", "delete the 2024 migration guides"). The user picks. Nothing is deleted,
including docs and tests, without this gate.

### 5. Apply in slices

Per approved slice, in this order:

1. **Earn the licence.** Confirm the lane from step 0 still holds for the exact lines you
   are about to change. If the slice is in *Pinned on paper* or *Unpinned*, the test work
   from [TESTS.md](TESTS.md) is the first half of the slice, landing green-to-green before
   any code moves.
2. **Make the moves by name** — rename, extract/inline, collapse, guard clauses, explaining
   variable, move function, delete the error path, comment repair. CHECKS.md maps each
   finding to its move.
3. **Small steps, suite green after each.** The slice lands as its own structural commit,
   no behavior change mixed in. For a reduction too large to land at once, strangle it: new
   shape beside old, callers moved over one at a time, old shape deleted last.
4. **Route what isn't yours.** Module-level and deletion candidates → `/clean-house`
   (targeted mode) with the evidence; bugs → `diagnose`.
5. **Rejected with a load-bearing reason** → offer an ADR
   (see [../clean-house/ADR-FORMAT.md](../clean-house/ADR-FORMAT.md)) so later passes don't
   re-suggest it. Skip ephemeral reasons.

### 6. Newcomer artifacts

Inventory what a new reader gets for free, fill only what has a predictable reader — an
artifact nobody will open is doc litter, and this pass just spent a step deleting that:

- **CONTEXT.md** — every load-bearing domain term the confusion log hit that isn't defined
  yet (create the file lazily; see [../clean-house/CONTEXT-FORMAT.md](../clean-house/CONTEXT-FORMAT.md))
- **Naming molds** — the repo's answer to case style, part order (`fooCount` vs `countFoo`),
  boolean prefixes, `get` = cheap / `compute` = costly; one short section in CONTEXT.md
- **Map of the code** — entry points, module map in LANGUAGE.md terms, suggested reading
  order; a short section in the README or `docs/`
- **Starter tasks** — 2–3 issues labeled for newcomers, each scoped to a *single* activity
  (read-and-summarize, or transcribe-a-known-plan — never "understand, design, and change"
  in one task)

### 7. Verify, then report

Re-walk the confusion log on the changed areas: each entry is **resolved** (the stumble is
gone without insider knowledge) or **remaining**. Re-run step 0's fault injection on the
changed areas — the net must be at least as strong as it was. Suite green. Then measure:
lines removed, branches removed, error paths removed, tests deleted / raised / strengthened.

**Dry or wet?** No new must-fix finding, no new high-severity stumble on the re-walk, no
machinery left flagged → **dry**: stop. Otherwise **wet**: write the report, list what's
open, tell the user to re-fire `/improve-readability` when ready. One pass per invocation —
never loop silently.

## Report

Always write `docs/audits/YYYY-MM-DD-readability.md` (create `docs/audits/` lazily); print
the same to chat. The next run reads it for calibration. Delete the previous readability
report as part of the spent-docs sweep — only the latest is ever read.

```text
## Result
{dry — reads clean, or wet — re-fire recommended, with why}

## Safety net
{how it was measured; which areas were pinned, decorative, unpinned; net before → after}

## Confusion log
- {where} — {stumble} — {type} — {resolved by <commit/move> | remaining}

## Slices applied
- {intent} — {moves} — {files} — {commit}

## Removed
- code: {lines, branches, error paths, config knobs}
- comments: {history/commented-out/boilerplate stripped, where}
- docs: {spent .md deleted}
- tests: {deleted / raised to the interface / strengthened}

## Handed off
- {candidate} → {/clean-house targeted | diagnose} — {evidence}

## Newcomer artifacts
- {added/updated, or "none needed — say why"}

## Parked (low-traffic)
- {finding} — {why it doesn't earn a slice yet}

## Left for the next pass
{open items, or "none — dry pass"}
```

Do not summarize what was checked. The user can read the skill.
