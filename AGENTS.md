# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- If you're about to use an unfamiliar API or pattern, verify it exists — read the code, the docs, or grep the codebase first. Don't invent.

**Grilling mode.** When the user says "grill me", "stress-test this", "interrogate my plan", or anything similar, and/or when you consider it appropriate, interview them one question at a time, walking each branch of the design tree and resolving dependencies between decisions one-by-one. For each question, propose options, highlight tradeoffs, recommend an answer, explain why. If a question can be answered by exploring the codebase, explore instead of asking.

## 2. Read Before You Write

**Ground every action in actual code, not remembered code.**

- Before editing a file, read it.
- Before calling an API or using a pattern, verify it exists — grep, read the docs, find an example in the codebase.
- If you catch yourself writing "from memory," stop and verify first.

## 3. Minimum Diff

**Every changed line traces to the request. For new code, write the minimum that solves it. For edits, touch only what you must.**

For new code:

- Before writing, stop at the first rung that holds: (1) does this need to exist? — if speculative, skip it and say so; (2) does the standard library do it? (3) a native platform feature? (4) an already-installed dependency? — never add a new one for what a few lines cover; (5) can it be one line? (6) only then, the minimum that works.
- No speculative features, abstractions, configurability, or error handling for scenarios that can't happen.
- If you wrote 200 lines and could write 50, rewrite.

For edits:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style, even if you'd write it differently.

For both:

- Remove orphans your changes created (unused imports, dead variables, dead functions, tests that exercised what you deleted).
- If you notice pre-existing dead code, mention it — don't delete it.
- Minimum diff bounds scope, not quality: within the lines you do write, take the option that needs the least explaining — precise name, guard clause, error defined away rather than handled twice. Small messes compound; don't leave one because the diff was small.

## 4. Plain Naming

**Functions, modules, and variables read like plain English.**

- Names describe intent — what the code does or holds, not what it's called or what type it is.
- No abbreviations, acronyms, or clever wordplay. `userCount` not `usrCnt`. `parsePayment` not `procPmt`.
- Module names describe the domain, not abstract patterns. `billing/` not `helpers/` or `utils/`.
- A reader who hasn't seen the code should understand intent from the name alone.
- One concept, one word — repo-wide. Reuse the CONTEXT.md term where one exists; never mint a synonym for a concept that already has a name.
- Names must not lie or wobble: booleans read as predicates (`is`/`has`/`can`, never negated); `get` is cheap — costly work is `compute`/`fetch`; ranges say `first/last` (inclusive) or `begin/end` (half-open). A name promising more, less, or the opposite of what the code does is a bug, not a style issue.

If you can't write a clear name, you don't yet understand the thing you're naming. Stop and clarify.

## 5. Goal-Driven Execution

**Define verifiable success. Loop until verified — or stop and surface what's blocking.**

**Driving forward.** Transform fuzzy tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**No shortcuts.** Within scope, pick the best approach — not the easiest to implement. Don't suppress errors, mock around real problems, pick an inferior API because the better one is harder, leave TODOs, or bypass type/lint/test gates to "get green." If the best approach is genuinely too expensive, stop and surface the tradeoff — don't silently downgrade.

**Gates are scripts.** Deterministic gates live in versioned, reviewed, tested scripts a human can run by hand; CI calls the identical scripts. Skills are reserved for judgment work. A skill wrapping what a script should do is a smell.

**Stopping.** If the path isn't working:

- If the same approach fails twice, stop. Surface the obstacle. Don't keep trying variations.
- If a test won't go green after a focused attempt, say what you tried and what's confusing.
- Sunk cost is not a reason to keep going.

## 6. Phase Awareness

**Name the phase before acting. Don't pick silently.**

- **Defining** — a fuzzy goal with no spec yet, *or a scoped change to an existing product when a PRD/spec already exists* → run `define`. Don't silently start coding a feature request on an existing product — name the phase first. Once define converges:
  - **Increment on an existing product.** A new / changed / dropped capability when artifacts already exist. Frame just the change, then amend the affected artifacts — a new complete snapshot per artifact, cascading only along the edges the change touches — before implementing. A trivial tweak or bug fix skips to Implementing / Diagnosing; a change that rewrites the Target User or Problem Statement is a pivot, so start fresh.
  - **Zero-to-one with market uncertainty.** Prompt the user to run `/research-market` (forum + competitive evidence), `/ideate` (10 ranked one-pagers, user picks), `/judge-idea` (adversarial gate), then `/to-prd`, `/to-spec`, `/to-issues`.
  - **Established space.** Prompt the user to run `/to-prd`, `/to-spec`, `/to-issues` directly.
  - **Custom LLM harness on the table.** When the system needs to run reliably without a human in the verification loop — programmatic gates, contracts, audit, autonomous execution beyond conversational — off-the-shelf coding agents stop being enough. After `/to-prd`, `define` hands off to `pick-harness-shape`, which first decides whether a custom harness is needed and then walks substrate, topology and role decomposition, memory, tools, and gates, writing a versioned `definitions/harness/` artifact that `/to-spec` reads. When the tool layer chooses MCP, `design-mcp-server` runs after `pick-harness-shape` and writes its own versioned `definitions/mcp-servers/` artifact, also read by `/to-spec`. **Exception:** when the harness IS the product or differentiator, invoke `pick-harness-shape` *before* `/to-prd` so its picks can shape the PRD.
  - **UI product on the table.** When the product has persistent user-facing surfaces (web app, mobile, dashboard, browser extension), the shape of those surfaces — visual identity (feel, signature, accent, type) plus structure (nav, onboarding, settings, account lifecycle, error states) — needs locking down before SPEC. After `/to-prd`, `define` hands off to `pick-ui-surfaces`, which walks the load-bearing decisions and writes a versioned `definitions/surfaces/` artifact that `/to-spec` reads. If both this and `pick-harness-shape` apply, run `pick-ui-surfaces` first so harness picks can slot into known surfaces.
  - **Greenfield infrastructure path.** First PRD on a new project → after `/to-prd`, prompt the user to run `/pick-cloud-services` in greenfield mode: it locks the development-to-production path — local-first vs cloud-first vs hybrid — as the project's first `docs/adr/` record, before `/to-spec`. Individual service picks stay anytime decisions (see Operating).
- **Implementing** — spec is decided → run `test-driven-dev` for a single issue. When a slice touches UI, `test-driven-dev` invokes `ui-taste`, which applies the visual identity locked by `pick-ui-surfaces`. When a test needs a multimodal fixture, it invokes `generate-test-assets`, which generates the stand-in (audio, image, video, text) with Gemini and routes load-bearing / user-dependent checks to the human.
- **Diagnosing** — something is broken or regressed → run `diagnose` (live and affecting real users → its Phase 0 triage first: mitigate, preserve evidence, then reproduce).
- **Shipping** — PR prep, review, cleanup → prompt the user to run `/review-pr` (which also audits prompt files in the diff). For projects with PRDs/SPECs/ADRs, also prompt `/audit-drift` to sweep the doc graph. Before a release cut on a maturing system, prompt `/audit-failure-modes` to enumerate latent failure modes by surface.
- **Operating** — real users are (about to be) live. Before first production traffic or any one-way cutover — a domain/DNS move, a datastore migration, re-pointing a provider that holds data or serves inference — prompt the user to run `/go-live`: an evidence gate that verifies runtime facts (secrets actually set, backups actually retaining, alerts actually firing) by consuming the project's own runbooks and gate scripts, never re-deriving them. Choosing any external/cloud service goes through `/pick-cloud-services`, which writes dated decision records to `docs/adr/` whose `NEXT REVIEW`/`TRIGGER` lines `/clean-house` sweeps each pass.
- **Maintaining** — a version has shipped and the system has accreted → prompt the user to run `/clean-house`, which walks the built system in a supervised pass — question requirements against reality, delete what can't justify itself, deepen the modules that survive, accelerate the feedback loop, review automation in both directions — reconciling the doc graph (`/audit-drift`) before the pass ends. One pass per run; re-fire until a pass comes up dry. Runs at the version hinge, before defining the next increment. When the complaint is comprehension rather than accretion — code hard to read, onboarding slow, every change starts with archaeology — prompt the user to run `/improve-readability`: a behavior-preserving comprehension pass, runnable any time (not just the version hinge), which hands module reshaping to `/clean-house` targeted mode.
- **Cross-cutting (no phase)** — inbound GitHub issues → prompt the user to run `/github-triage`, the label-based triage state machine; it serves every phase and belongs to none.

Skills prefixed with `/` are user-invoked — Claude Code: `/name`; Codex: `$name`; Antigravity/Gemini: ask for it by name (or its `/name` workflow where provided). Never fire them yourself — name the one the phase calls for and wait for the user.

## 7. User-Facing Reliability

**The user must see what's happening and understand what failed.**

- For operations >2s, show progress (spinner, status line, streamed activity). Silent ≠ done — the user has already assumed it crashed.
- For external failures (LLM, HTTP, DB, filesystem), map raw exceptions to one-sentence messages naming **what went wrong** and **what to do next**. Don't leak provider stack traces. Pin tests against the actual production exception text you observed.

## 8. Secret & Data Hygiene

**Don't leak credentials or sensitive data, ever.**

- Never commit `.env`, API keys, tokens, or credential files.
- Never log, print, or echo credentials, PII, or auth headers — including in error messages and stack traces.
- If you find a secret already committed in code, stop and surface it. Don't paste it back in your output.
- Prodness is declared, never inferred — and a production boot refuses dev/test affordances by construction: starting with a dev-only flag set fails loudly instead of running with the flag live. Every environment is a config profile over the same SHA-tagged artifact; a demo is a profile, never a forked build.

## 9. Parallel by Default

**Split the work, fan out parallel agents to do it, coalesce the results, repeat until done.**

When a task splits into independent pieces, run them at once instead of one at a time.

- **Decompose.** Break the work into independent workstreams — pieces that don't touch the same files or depend on each other's output. Name them before you start.
- **Fan out.** Launch one agent per workstream, as many as the work needs — scale the count to the work, don't serialize what can run at once. Run every agent — in a wave or solo — on nothing below your harness's frontier tier (max Opus on Claude, GPT Terra on Codex, Gemini Pro on Gemini), at the maximum available thinking tier — never a cheaper tier to save tokens. The only cap is real: agents that would collide on the same files, or a tool's concurrency limit.
- **One level only.** Only the agent holding the user's request fans out. A subagent does its assigned scope and returns — it never spawns a wave of its own, and never watches, waits on, or coalesces a sibling. If its scope turns out to be too big, it says so in its report rather than recruiting. Depth is not a workstream: "as many as the work needs" counts agents beside you, never below you.
- **Coalesce.** When the wave returns, merge its findings, edits, and checks into one result — reconcile overlaps, resolve conflicts, dedupe. This is the launcher's job, not the wave's. A wave isn't done until its outputs are integrated, not just collected.
- **Re-wave.** Spawn the next wave for whatever the first surfaced — follow-ups, newly-unblocked work, the remaining split — and loop until the goal is verified done (§5).

Skip it when the work is trivial or inherently sequential — when each step depends on the last, one agent in order is correct. Don't fan out agents that will collide on the same files.

---

## Stack-specific rules

The rules above are universal. The rule below applies only when the stack matches.

**Web UI — if the project renders in a browser (website, webapp, or web-mocked mobile app), install Playwright and verify at least one critical user journey before reporting work complete.**

- Pick a CUJ from the PRD, or invent one if none is specified — surface which you chose.
- "It compiles" and "tests pass" are not verification for UI work. Drive the actual flow in a real browser.
