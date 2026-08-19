---
name: define
description: Defining-phase orchestrator. Surfaces assumptions, frames a falsifiable hypothesis, then routes to the right next step (research-market / ideate / judge-idea / to-prd / to-journeys / to-mockups / pick-harness-shape). Use when the user has a fuzzy product or feature idea — whether greenfield (no PRD/SPEC yet) or a scoped change (increment) to an existing product.
---

Entry point for the Defining phase — for both a greenfield idea and a scoped change to an existing product. Surface the assumptions the idea depends on, frame a falsifiable hypothesis, and route to the right path. Work through the steps in order, one question at a time. For each question, recommend an answer.

If a question can be answered by exploring the codebase or existing docs, explore instead of asking.

**Step 0 — Greenfield or increment?** `ls definitions/prd.md definitions/spec.md 2>/dev/null`.

- **None →** greenfield. Proceed with Steps 1–8. (One decision deliberately lands later, not here: the development-to-production path — local-first, cloud-first, or hybrid — is decided by `/to-infrastructure` in greenfield mode after `/to-prd`, when integrations and CUJs are known; the method is `${SKILL_DIR}/../../docs/selection-method.md` — `${SKILL_DIR}` = the directory containing this file.)
- **A PRD/SPEC already exists →** this is an **increment**, not a new product. Don't re-run the whole-product assumption map. Frame just the *change*: what's new, why now, which existing CUJs / surfaces / harness / modules it touches, and its kill criterion. Name its **change tier** — `fix` / `internal` / `feature` / `launch` — which decides how many artifacts it touches at all; the ladder is in `${SKILL_DIR}/../../docs/amend-mode.md`. Then route the authoring skills in **amend mode**, cascading only along the edges the change implicates. Run the full Step 1–5 walk only for a genuine pivot — a change that rewrites the Target User or Problem Statement.

**Step 1 — Classify.** What kind of project is this? (Consumer app, B2B SaaS, internal tool, API/platform, product strategy question, data product, hardware/software.) One question, one answer. The type determines which dimensions below to prioritise.

**Step 2 — Probe relevant dimensions.** Pick 3–5 based on project type. Ask 2–3 tight questions per dimension before moving to the next.

*Clarification & Scoping*
Should we solve this at all, or is this a symptom of a different problem? Is it a one-sided or multi-sided market? Internal or external facing? New product or improvement to an existing one? Startup or legacy context? Geo, regulatory, or seasonality constraints?

*User & Customer Segmentation*
Who exactly is the user? Who is the customer (the one paying)? Are they different people? In B2B: who is the economic buyer, the daily user, the internal champion, the procurement blocker? Which segment do we serve first, and why them over others?

*UX & Critical User Journeys* — probe this for every product idea, regardless of type
This is the most important dimension. Go deep and stay specific.
- What does the target user do today, without this product? Walk through their typical day or week as it relates to this problem. Be concrete — what tools, steps, and people are involved?
- What triggers the need? What just happened that makes them go looking for a solution?
- Name the 2–3 Critical User Journeys (CUJs). For each: who is the user, what are they trying to accomplish, and what are the exact steps from trigger to outcome?
- For each CUJ: what pages, screens, or surfaces are required? What does the user provide as input? What do they get back?
- What is the interface style — and why? (Consumer mobile, web dashboard, CLI, API, embedded widget, voice, email.)
- What does a great experience feel like to this user? What would make them tell a colleague?
- Any existing design system, brand constraints, or accessibility requirements?

*UXR Intent*
What do we most need to learn, and at what stage? (Foundational: what to build. Iterative: how to build it. Evaluative: did it work.) What proxy behaviors show the problem exists today — spreadsheets, manual workarounds, Slack pings? Where do frustrated users talk about this publicly?

*Business & Viability*
How large is the market (TAM/SAM)? How does this make money — subscription, freemium, transaction fees, ads, licensing? Who are the direct and indirect competitors, and what is the actual differentiator? Regulatory, security, or compliance constraints?

*Technical Feasibility*
Stack constraints, build vs. buy, existing integrations? Timeline, team size, data residency, or partner dependencies that affect scope?

**Step 3 — Assumption map.** List every belief the idea depends on. Rank by importance × evidence — how badly does the idea fail if this is wrong, and how much do we already know? Tag each:
- **Value** — will users want it?
- **Usability** — can users figure it out?
- **Viability** — does it work for the business?
- **Feasibility** — can we build it within constraints?

Test high-importance, low-evidence assumptions first. Push back if the user conflates risk types — a product can pass usability and fail value.

**Step 4 — Falsifiable hypothesis.** For the top assumption: "We believe [Target User] experiences [Specific Friction] because [Root Cause]. If we provide [Core Capability], then [Measurable Change in Behavior] will occur." Reject vague hypotheses. Set kill criteria: the exact threshold — a number and a behavior — that means pivot or die, and the date it gets checked. These travel into the PRD's *Goals & Success Metrics*, get instrumented by the SPEC's Observability section, and are read back by `/readout` weeks after launch. Set them as if someone will hold you to them, because that is now the design.

**Step 5 — Cheapest prototype.** What is the lowest-effort artifact that tests the top assumption? Options: static mock (value prop and mental model — `/to-mockups` produces this later in the chain, so a heavy separate one here is usually waste), interactive prototype (usability), Wizard of Oz (human-operated back-end, best for AI features before the algorithm exists), Concierge MVP (you deliver the service manually, no UI), Flintstoning (fake automation behind real UI). If the eventual product implies a high-friction form factor (native mobile, hardware, browser extension, app-store-gated), also ask: should we validate on a cheaper surface (web app, CLI, hosted prototype) before committing to the expensive one? Surface the tradeoff and let the user decide.

**Step 6 — Route to the right pre-PRD path.** Based on what surfaced above:

- **Zero-to-one with market uncertainty.** Prompt the user to run `/research-market` (mines forums and competitive landscape into `definitions/research.md`), then `/ideate` (10 ranked one-pagers, user picks the winner), then `/judge-idea` (adversarial gate that returns proceed | loop-back | pivot), then `/to-prd`.
- **Established space, user knows the market well.** Prompt the user to run `/to-prd` directly.

Either way `/to-prd` is followed by `/to-journeys`, which expands each journey into a script with steps, branches, and the end-state proof a test asserts. Everything downstream reads that file — `/to-mockups` draws one panel per step, `/to-issues` copies the proofs into acceptance criteria, `test-driven-dev` writes them as the first test — so name it as the next step rather than leaving it implicit. Only a `fix`- or `internal`-tier change skips it.

**Step 7 — Prompt `/to-mockups`.** If the product has persistent UI surfaces (web app, mobile, dashboard, browser extension), prompt the user to run it *after* `/to-journeys`, so the UI picks ground on the PRD's user and the journeys the surfaces have to carry. It picks the visual identity and structure into `definitions/mockups.md`, then draws every journey step and branch as annotated panels in `definitions/mockups.html` — the first point at which anyone can argue with the product rather than with a table. Its findings amend the PRD and journeys in the normal way; the chain is a loop, not a waterfall. Skip for CLI, API, library, or headless products.

**Step 8 — Hand off to pick-harness-shape, then the SPEC.** If the system needs to run reliably without a human in the verification loop — programmatic gates, contracts, audit, autonomous execution — or falls into a non-coding domain (support, ops, research, drafting), invoke pick-harness-shape *after* `/to-journeys` (and after Step 7, if it applied — harness picks then know which UI surfaces they're slotting into), so the harness picks ground on the PRD's constraints and the journeys' autonomy matrix. It writes `definitions/harness.md`, which `/to-spec` reads downstream, so this is not optional when a custom harness is needed. (Exception: if the harness IS the product or differentiator, picks may shape the PRD rather than follow from it — pick-harness-shape will surface this and offer the override.)

Once the steps that apply have run, prompt `/to-spec`.
