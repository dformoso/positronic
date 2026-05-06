---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me". Also use when the context is a vague product idea with no spec yet — shifts to assumption mapping and hypothesis definition.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

## When the context is a vague product idea (no spec yet)

Shift from stress-testing a plan to surfacing assumptions and understanding users before any spec exists. Work through these steps in order, one question at a time.

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

**Step 4 — Falsifiable hypothesis.** For the top assumption: "We believe [Target User] experiences [Specific Friction] because [Root Cause]. If we provide [Core Capability], then [Measurable Change in Behavior] will occur." Reject vague hypotheses. Set kill criteria: the exact threshold — a number and a behavior — that means pivot or die.

**Step 5 — Cheapest prototype.** What is the lowest-effort artifact that tests the top assumption? Options: static mock (value prop and mental model), interactive prototype (usability), Wizard of Oz (human-operated back-end, best for AI features before the algorithm exists), Concierge MVP (you deliver the service manually, no UI), Flintstoning (fake automation behind real UI).

**Step 6 — Hand off to discover.** If this is a genuine zero-to-one situation — no product exists yet, real market uncertainty — invoke the discover skill now. It runs the full generative research → prototype evaluation → trusted tester → PMF pipeline, anchored on the CUJs and user segments defined above. Otherwise, prompt the user to run `/to-prd`.
