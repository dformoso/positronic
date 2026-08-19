---
name: clean-house
description: Between-versions subtraction loop over a built system — question requirements against reality, delete what can't justify itself, deepen the modules that survive, accelerate the feedback loop, review automation in both directions; run as a single supervised pass, re-fired until a pass comes up dry. Use between versions when the system has accreted, when the user wants to find what to delete or simplify, asks to improve architecture, consolidate tightly-coupled modules, or make a codebase more testable, or says "clean the house". User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Clean the House

A five-step algorithm — question, delete, simplify, accelerate, automate — run as a single review pass over a built system. v1 exists; before defining v2, walk the steps over what is actually there. That is why this lives at the version hinge and not in the defining phase: pre-build, deletion runs on speculation; post-build, it runs on evidence — usage, drift, git history.

**The order is the content.** Each step is only safe applied to the survivors of the step before it. Never spend a later step on something that hasn't survived the earlier ones.

| # | Step | Guards against |
|---|---|---|
| 1 | Question every requirement | Requirements nobody can own anymore. Most dangerous when they came from an articulate source — a smart person, an LLM — because they arrived pre-rationalized |
| 2 | Delete the part or process | The default error: addition. The most common error of a smart engineer is optimizing a thing that should not exist; the most common error of an LLM is building it |
| 3 | Simplify — deepen what survived | Polishing zombies. A deepening pass that skips steps 1–2 will lovingly consolidate a dead feature's modules |
| 4 | Accelerate cycle time | Speeding up work the earlier steps should have removed. If you're digging your grave, don't dig faster |
| 5 | Automate last — and de-automate | Freezing a process that hasn't stabilized; keeping machinery whose process died |

Software sharpens the economics this loop was tuned for in hardware. A deletion is a revertible experiment — git holds the undo — while undeleted complexity is a recurring tax on every future context window: dead weight actively misleads the next agent that reads it. So cut past where it feels safe. **Calibration:** if no later pass or version ever re-adds a cut, you're cutting too shallow. (Rule of thumb: re-add at least 10% of what you cut, or you didn't cut enough.)

Neighbours — keep the questions distinct:

| Skill | Its question |
|---|---|
| `/clean-house` (this) | What shouldn't exist? Subtraction |
| `/audit-drift` | Do the documents still agree with each other and the code? Consistency — standalone at shipping, and run here at the end of each pass |
| `/audit-failure-modes` | What will break? Risk — the additive move; untouched by this skill |
| `/judge-idea` | Is the bet sound? Pre-build adversarial gate; runs on speculation, this runs on evidence |
| `/improve-readability` | Can the next person understand it, and is any of it needless? Comprehension and reduction *inside* the code that stays — cuts machinery, comments, spent docs and weak tests without changing what a caller sees; hands feature-level cuts and module reshaping here. **Runs after this pass**, on what survived |

## Glossary

Use these terms exactly. Don't drift into "component," "service," "API," or "boundary." Full definitions in [LANGUAGE.md](LANGUAGE.md).

- **Module** — anything with an interface and an implementation (function, class, package, slice).
- **Interface** — everything a caller must know to use the module: types, invariants, error modes, ordering, config. Not just the type signature.
- **Implementation** — the code inside.
- **Depth** — leverage at the interface: a lot of behaviour behind a small interface. **Deep** = high leverage. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can be altered without editing in place. (Use this, not "boundary.")
- **Adapter** — a concrete thing satisfying an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get from depth: change, bugs, knowledge concentrated in one place.

Key principles (see [LANGUAGE.md](LANGUAGE.md) for the full list):

- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

## Inputs

- The defining artifacts, whichever exist: `definitions/prd.md`, `definitions/journeys.md`, `definitions/spec.md`, `definitions/mockups.md`, `definitions/harness.md`, `definitions/runtime.md`, `definitions/mcp-servers.md`
- The most recent readouts: `ls docs/audits/*-readout.md 2>/dev/null | sort | tail -3` — these already asked, with real numbers, whether each shipped bet worked. Step 1 below is much sharper with them and mostly guesswork without; a `cut` verdict in one is a deletion candidate already argued
- `CONTEXT.md` (or `CONTEXT-MAP.md` + each `CONTEXT.md`), plus `definitions/decisions.md` and `definitions/infrastructure.md` — domain language names good seams; the decision files record what was settled, so don't re-litigate them. See [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md) and [DECISIONS-FORMAT.md](DECISIONS-FORMAT.md)
- The previous report: `ls docs/audits/*-clean-house.md 2>/dev/null | sort | tail -1` — proceed silently if none (first run)
- `git log` since the previous report — what shipped, what got reverted, what came back after a cut
- The codebase

If any of these don't exist, proceed silently — don't flag their absence. With no defining artifacts at all, steps 1 and 6 shrink to whatever docs exist; the rest of the loop still applies.

## Targeted mode

When another skill hands over specific candidates — `diagnose` after a fix (no good test seam, tangled callers), `/review-pr` on a private-API reach, `/improve-readability` on a module-level candidate (shallow cluster, leaked decision needing one owner) — skip the pass. Apply the kill question to each candidate first (is the right move deleting the surrounding feature rather than deepening it?), then run step 3's grilling on what survives. No report.

When the *user* names the targets instead — `/clean-house docs/runbooks/`, `/clean-house infra/main.tf#backend` — skip the pass and audit exactly what they named, one file, directory or section per target. Fan out one read-only auditor each carrying [DELETION-AUDIT.md](DELETION-AUDIT.md); coalesce the verdict blocks and run step 2's approval gate over them. No report.

## The pass

Run the five steps once, in order. A pass already takes a while and the report carries state forward, so **re-running is the loop** — one pass per invocation. Each pass changes the system, exposing what the last couldn't see: cutting a feature turns a module into a pass-through; deepening one reveals config nothing reads. Re-fire `/clean-house` to chase what a pass exposed; stop when a pass comes up dry.

Hunting is read-only — fan out subagents and parallelize freely. Execution is gated — cuts and reshapes happen only after the user approves, never silently. Don't batch the whole pass into one approval; gate at the step boundaries below. Automating the approval gate away would be this skill committing its own step-5 mistake.

### 1. Question requirements against reality

For every requirement row in the latest PRD, journeys artifact and SPEC (and each locked decision in the mockups / harness artifacts), ask:

- **Exercised?** Does evidence show it's used — routes hit, feature touched, code path reachable, tests that exist for a reason?
- **Owned?** Can it still name who wants it and the observable failure if dropped? "Best practice", "the framework expects it", and "the model suggested it" are departments, not names.
- **Overtaken?** Did what actually got built, or how it's actually used, contradict it?

Drift is evidence here: a doc section that diverged long ago with nobody noticing is a strong signal nobody needed what it described.

**Fired triggers are evidence too.** Sweep the dated decision machinery: run `${SKILL_DIR}/scripts/freshness-sweep.sh` (`${SKILL_DIR}` = the directory containing this file) and read its output — it emits past-due `NEXT REVIEW:` lines and every `TRIGGER:` line across `definitions/infrastructure.md`, `definitions/decisions.md`, and `definitions/runtime.md`. A past-due `NEXT REVIEW:` date or a fired `TRIGGER:` condition (on a service pick or the development-to-production path) is a decision whose ground truth moved — flag it, and the fix is the trigger's own named action (re-run `/to-infrastructure` on that section, start the migration step, formalize custody). A trigger nothing sweeps is decorative; this step is the sweep.

Output: flagged requirements, each with its evidence. These feed step 2.

### 2. Delete

Hunt cut candidates at every layer:

| Layer | Hunt for |
|---|---|
| Requirements / features | Step-1 flags: unexercised, unowned, overtaken |
| Code | Dead paths, unreachable branches, exports nothing imports |
| Dependencies | Unused; single-call deps a small function replaces; two deps doing one job |
| Config surface | Options with one observed value; flags nobody flips |
| Abstractions | Pass-throughs (deletion test); one-adapter seams nothing else will use; layers with one caller |
| Process | CI stages, hooks, scripts, doc artifacts, skills nobody runs |
| Tests | Suites green against nothing: tests for features already cut, tests asserting mocks of deleted seams, implementation-detail pins that break on refactor rather than regression (tests.md red flags). Cut them here; *strengthening* the survivors is `/improve-readability`'s pass — see [`../improve-readability/TESTS.md`](../improve-readability/TESTS.md) |
| Spent docs | `.md` files nothing reads anymore: executed plans, finished migration guides, how-tos for cut features, superseded audit reports, READMEs describing a layout that changed. **Never** the `definitions/` artifacts — they are amended rather than deleted, and the trail of why is the asset |
| Method docs / skills / prompts | Embedded perishable facts in files meant to be durable method — vendor names, prices, model versions, "as of" status lines (`grep -rnE '\$[0-9]|20[0-9]{2}|as of' <skill/prompt dirs>`). Each is rot: replace with the category plus a verify-live instruction; dated facts belong only in provenance-stamped records |

Send each candidate to its own read-only auditor carrying [DELETION-AUDIT.md](DELETION-AUDIT.md) — one target per auditor, verdict block back. Self-description doesn't count as evidence there, and a claim the target makes that turns out false is the strongest signal you'll get.

Present cuts ranked by blast radius, each with **what / evidence / re-add trigger** — the observable signal that would justify bringing it back. Then the gate:

- **Approved** → execute now: the thing, its tests, its docs, its orphans, in one stroke. Requirement-level cuts also land in step 6's amendments.
- **Rejected with a load-bearing reason** → offer a record in `definitions/decisions.md` so later passes and future reviews don't re-suggest it (see [DECISIONS-FORMAT.md](DECISIONS-FORMAT.md)). Skip ephemeral reasons ("not right now") and self-evident ones.

### 3. Deepen what survived

Only now, and only on survivors of step 2.

**Explore.** Fan out parallel read-only explorer subagents (your harness's subagent mechanism; read sequentially if it lacks one) to walk the codebase. Don't follow rigid heuristics. Note where you hit friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

**Present candidates.** A numbered list of deepening opportunities. For each: **Files** — which files/modules are involved; **Problem** — why the current architecture is causing friction; **Solution** — plain English description of what would change; **Benefits** — explained in terms of locality and leverage, and in how tests would improve.

Use `CONTEXT.md` vocabulary for the domain and [LANGUAGE.md](LANGUAGE.md) vocabulary for the architecture. If `CONTEXT.md` defines "Order," talk about "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**Decision conflicts**: only surface a candidate that contradicts a recorded decision when the friction is real enough to revisit it. Mark it clearly (_"contradicts the event-sourcing record — but worth reopening because…"_). Don't list every refactor a record forbids.

Do NOT propose interfaces yet. Ask the user: "Which of these would you like to explore?"

**Grilling loop.** Once the user picks a candidate, walk the design tree — constraints, dependencies (see [DEEPENING.md](DEEPENING.md) for the four dependency categories, seam discipline, and the *replace-don't-layer* testing rule), the shape of the deepened module, what sits behind the seam, what tests survive. Side effects happen inline as decisions crystallize:

- **Naming a deepened module after a concept not in `CONTEXT.md`?** Add the term to `CONTEXT.md` (see [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md)). Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term during the conversation?** Update `CONTEXT.md` right there.
- **User rejects the candidate with a load-bearing reason?** Offer a record in `definitions/decisions.md` so future passes don't re-suggest it. Skip ephemeral and self-evident reasons.
- **Want to explore alternative interfaces for the deepened module?** See [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md).

### 4. Accelerate — sweep, not redesign

Measure the feedback loop on surviving paths only: test-suite wall clock, CI duration, build time, the slowest edit-to-signal edge. Flag the worst offenders. A fix that's one approval away — a cache, a parallel split, deleting a redundant CI stage (deletion again) — executes with approval; anything larger becomes an issue, not a detour. Never accelerate a path step 2 still has questions about.

### 5. Review automation, both directions — sweep

- **Automate**: a manual step performed the same way ≥3 times since the last report, with stable inputs and visible failures → propose the hook / CI gate / cron / script. Only now — automation freezes a process, so only freeze one that's been questioned, cut, simplified, and run by hand.
- **De-automate**: machinery serving a process that step 2 deleted or that changed shape — hooks, CI stages, cron jobs, harness gates → propose removing it. Automation that outlives its process doesn't just waste cycles; it enforces the old shape.

### 6. Reconcile

The pass's cuts and reshapes made the doc graph stale; leave each pass consistent.

- **Amendments.** Approved requirement-level cuts are dropped capabilities — prompt the user to run `/to-prd` (amend mode picks up automatically), with the cuts as the change intent. Each cut lands in the PRD's Out of Scope with *cut because* + *re-add trigger*. The cascade rule in `${SKILL_DIR}/../../docs/amend-mode.md` carries it downstream only along touched edges.
- **Drift sweep.** Execute the checks in `${SKILL_DIR}/../audit-drift/SKILL.md` — the `/clean-house` invocation covers this; don't re-prompt. Fix the must-fix drift this pass's edits caused. Any drift the pass's edits *don't* explain is evidence for the next pass's step 1.

### Dry or wet?

No new approved cut + no new deepening candidate + no unexplained drift → the pass is **dry**: the house is clean, write the report, stop. Otherwise it's **wet**: write the report, list what's still open under **Left for the next pass**, and tell the user to re-run `/clean-house` when ready. One pass per invocation — never loop silently.

## Report

Always write `docs/audits/YYYY-MM-DD-clean-house.md` (create `docs/audits/` lazily) — the next run reads it for calibration. Print the same to chat.

**Write it in plain English** — short sentences, one idea each, concrete before abstract, every term of art glossed on first use. Someone who wasn't in this conversation has to follow it without asking (AGENTS.md §4).

```text
## Result
{dry — house clean, or wet — re-run recommended, with why}

## Cuts executed
- {what} — {evidence} — re-add trigger: {signal}

## Cuts rejected
- {what} — {reason} — {recorded in decisions.md, or "not recorded"}

## Re-adds since last report
- {what came back, why}
{None across two consecutive reports? Say so: cutting too shallow.}

## Deepenings
- {candidate} — {reshaped | rejected (recorded) | deferred}

## Accelerations & automation changes
- {what changed, including de-automations}

## Left for the next pass
{open items, or "none — dry pass"}
```

Do not summarize what was checked. The user can read the skill.
