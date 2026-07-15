---
name: improve-readability
description: Supervised comprehension pass over an established codebase — find where the code costs its readers (names that mislead, functions that overload working memory, comments that restate or lie, missing newcomer docs) and fix it in behavior-preserving slices. Use when the user says the code is hard to read or understand, onboarding is slow, new developers struggle, every change starts with archaeology, or asks to make a codebase readable, approachable, or easier to iterate on. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

# Improve Readability

Make the codebase cheap to understand. The metric is **time-till-understanding**: how long
the next reader — a new developer, a future agent context window — needs before they can
change the code safely. Every move in this pass either lowers that time or is out of scope.

Grounding, one line per book (the full checklist is [CHECKS.md](CHECKS.md)):

- Complexity is whatever makes code hard to understand and change; it accumulates in small
  messes and it costs most where readers actually spend time (Ousterhout, *A Philosophy of
  Software Design*).
- Confusion is diagnosable. Every stumble is a shortage of **knowledge** (don't know what a
  thing means), **information** (know it, but must fetch it from somewhere else), or
  **processing power** (too much to hold at once) — and each shortage has a different fix
  (Hermans, *The Programmer's Brain*).
- The fixes are small, named, behavior-preserving moves, worth applying only where change
  actually happens (Fowler, *Refactoring*).

Neighbours — keep the questions distinct:

| Skill | Its question |
|---|---|
| `/improve-readability` (this) | Can the next person understand it? Comprehension |
| `/clean-house` | What shouldn't exist? Subtraction — plus module-level reshaping (its step 3) |
| `/review-pr` | Is this diff safe to ship? A gate on the change, not a pass over the codebase |
| `diagnose` | Why is it broken? Bugs found here route there; obscurity found there routes here |

## Scope contract — three rules, no exceptions

1. **Behavior-preserving only.** Every edit is a refactoring: names, comments, structure,
   docs. Found a bug? Log it and route to `diagnose` — never fix it mid-pass. Refactor
   commits contain no behavior change (two hats).
2. **Code altitude, not module altitude.** Reshaping interfaces, merging shallow module
   clusters, moving seams — hand those to `/clean-house` targeted mode as named candidates.
   This pass works inside the shapes that exist.
3. **Subtraction outranks readability.** A module that shouldn't exist doesn't deserve a
   comment pass. If a target smells deletable, flag it for `/clean-house` and don't polish it.

Vocabulary: **module / interface / seam / depth** as defined in
[../clean-house/LANGUAGE.md](../clean-house/LANGUAGE.md). One term of this skill's own:

- **Confusion log** — a running table of reader stumbles: *where / what confused / type
  (knowledge · information · processing) / fix candidate*. The type names the fix:
  knowledge → glossary, docs, domain terms in names; information → bring it to the point of
  use (rename, inline, comment where the question arises); processing → shrink what must be
  held at once (guard clauses, explaining variables, straighten control flow).

## Inputs

- `CONTEXT.md` and the latest PRD (`ls definitions/prds/[0-9]*.md | sort | tail -1`) — the
  domain vocabulary and the top user journey, which is also the top *reading* journey
- The previous report: `ls docs/audits/*-readability.md 2>/dev/null | sort | tail -1` —
  proceed silently if none
- `git log` since the previous report — churn tells you where readers and changes go
- The test suite and how to run it in one command
- The codebase

If any of these don't exist, proceed silently — don't flag their absence.

## The pass

One pass per invocation; the report carries state forward; re-fire until dry. Hunting
(steps 1–3) is read-only — fan out subagents freely. Execution (step 4 on) is gated — edits
happen only after the user approves, never silently.

### 0. Baseline

Run the suite. Sort every area you might touch into a lane; the lane caps the moves:

| Lane | Condition | Allowed moves |
|---|---|---|
| Covered | Behavior pinned by tests | Everything in CHECKS.md |
| Pin first | Uncovered, but load-bearing | Write characterization tests (pin what it *does*, not what it should do), then everything |
| Text only | Uncovered, not worth pinning this pass | Comments, docs, tooling-verified renames — nothing that can change behavior |

### 1. Hotspots

Rank files by churn × size (`git log --format= --name-only | sort | uniq -c`, cross with
line counts or a complexity tool if one is already installed). Take the top handful plus
every file on the main journey. **A finding in code nobody has touched for a year is not a
finding** — park it in the report, spend nothing on it.

### 2. Fresh-eyes read → confusion log

The skill's sensor, run *before* the checklist so findings come from real stumbles, not
smell-counting. Walk two journeys as if new to the repo:

- the top CUJ path end-to-end (entry point → core module → persistence/exit), and
- the first change a newcomer would plausibly be asked to make.

Per file: one 60-second first-glance note (what draws the eye, what the file seems to be
for), then the careful read. Log every stumble in the confusion log with its type. Where a
hotspot resists reading entirely, trace it with a variable table (one column per variable,
one row per step) — if *you* need the table, that's a processing-power finding in itself.

### 3. Sweep CHECKS.md over the hotspots

Run the four lenses in [CHECKS.md](CHECKS.md) — obscurity, cognitive load,
change-resistance, line level — over the hotspot list. Parallel read-only subagents per
lens or per area. Merge into findings: *file:line / check / evidence / responding move /
lane*. A confusion-log entry corroborated by a check outranks either alone. Apply the
guard-rails section while sweeping — the pass must not manufacture fragmentation.

### 4. Gate, then apply in slices

Present findings ranked by **reader traffic × severity, discounted by risk**, batched into
slices of one intent each ("rename the ingest vocabulary to CONTEXT.md terms", "flatten the
retry pyramid in sync.ts"). The user picks. Then, per approved slice:

- small steps, suite green after each; slice lands as its own refactor-only commit
- moves by name (rename, extract/inline, guard clauses, explaining variable, move function,
  comment repair — CHECKS.md maps each finding to its move)
- module-level candidates and deletion candidates route to `/clean-house` (targeted mode)
  with the evidence attached; bugs route to `diagnose`
- **Rejected with a load-bearing reason** → offer an ADR
  (see [../clean-house/ADR-FORMAT.md](../clean-house/ADR-FORMAT.md)) so later passes don't
  re-suggest it. Skip ephemeral reasons.

### 5. Newcomer artifacts

Inventory what a new reader gets for free, fill only what has a predictable reader — an
artifact nobody will open is doc litter, not kindness:

- **CONTEXT.md** — every load-bearing domain term the confusion log hit that isn't defined
  yet (create the file lazily; see [../clean-house/CONTEXT-FORMAT.md](../clean-house/CONTEXT-FORMAT.md))
- **Naming molds** — the repo's answer to case style, part order (`fooCount` vs `countFoo`),
  boolean prefixes, `get` = cheap / `compute` = costly; one short section in CONTEXT.md
- **Map of the code** — entry points, module map in LANGUAGE.md terms, suggested reading
  order; a short section in the README or `docs/`
- **Starter tasks** — 2–3 issues labeled for newcomers, each scoped to a *single* activity
  (read-and-summarize, or transcribe-a-known-plan — never "understand, design, and change"
  in one task)

### 6. Verify, then report

Re-walk the confusion log on the changed areas: each entry is **resolved** (the stumble is
gone without insider knowledge) or **remaining**. Suite green. Write the report.

**Dry or wet?** No new must-fix finding, no new high-severity stumble on the re-walk →
**dry**: stop. Otherwise **wet**: write the report, list what's open, tell the user to
re-fire `/improve-readability` when ready. One pass per invocation — never loop silently.

## Report

Always write `docs/audits/YYYY-MM-DD-readability.md` (create `docs/audits/` lazily); print
the same to chat. The next run reads it for calibration.

```text
## Result
{dry — reads clean, or wet — re-fire recommended, with why}

## Confusion log
- {where} — {stumble} — {type} — {resolved by <commit/move> | remaining}

## Slices applied
- {intent} — {moves} — {files} — {commit}

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
