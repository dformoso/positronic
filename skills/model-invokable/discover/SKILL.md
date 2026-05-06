---
name: discover
description: Operational pipeline for zero-to-one product discovery. Invoked by grill-me once problem space, user segments, and CUJs are defined. Runs JTBD generative research → prototype evaluation → trusted tester → PMF loop.
---

You are running the product discovery pipeline. The problem space, user segments, and Critical User Journeys (CUJs) were defined in grill-me. Treat those as the north star throughout — every phase anchors on the CUJs.

State which CUJs you are working with at the start of each phase.

Phases run forward but discovery loops back. Each phase ends with a pivot condition — explicit permission to return to an earlier phase when evidence demands it.

---

## Phase 1 — Generative Discovery

Objective: confirm a real market exists and the pain is acute enough to build for. This is the cheapest exit point in the pipeline.

**Ecosystem mapping — before talking to users:**
- Audit competitors for UX debt. Where do users complain? (App reviews, Reddit, forums, support threads.) Don't just list features — find where existing solutions fail your CUJs.
- Identify proxy behaviors: how are users completing each CUJ today without your product? The clunkier the workaround, the stronger the signal.
- Estimate TAM/SAM/SOM. A real-but-tiny market kills an idea as surely as no market. Exit here if the SAM is too small.

**JTBD switch interviews — anchored on each CUJ:**
- Recruit extremes: desperate workarounders (built their own solution), apathetic abandoners (gave up and accepted the friction), and recent switchers (changed how they complete the CUJ in the last 90 days).
- Interview structure: anchor on the moment of switch. First thought → active looking → decision → first use → experience. For each moment, map the four forces: pull of new solution, push of old, anxiety about switching, habit of old.
- Mom Test guardrails: no questions about feelings toward your idea. No future-tense questions. Ask about specifics in their past. "Walk me through the last time you needed to do X — what did you do?" not "Would you use something that does X?"
- For each CUJ: ask the user to walk through their last real instance of it, step by step. What took the longest? Where did they get stuck? What did they do instead?
- Sample: 10–15 per distinct user segment, run to thematic saturation — stop when no new themes emerge.

**B2B stakeholder mapping:**
- Map every role in the procurement chain: economic buyer (signs the check), daily user (touches the product), internal champion (advocates for it), procurement blocker (security, legal, IT).
- Ask champions about security review requirements, data residency, and budget cycle early. These kill deals late if discovered late.
- A product the user loves but the buyer can't justify will fail to renew. A product the buyer loves but the user resents will fail at adoption.

**Synthesis:**
- Affinity diagram findings: cluster observations → themes → insights.
- JTBD forces map: aggregate push/pull/anxiety/habit forces across all interviewees. Identify the dominant forces per CUJ.
- Output: a ranked list of validated pain points per CUJ, each with a behavioral signature — not a quote.

Pivot condition: no acute, recurring pain across segments for any CUJ, or SAM too small → kill here.

---

## Phase 2 — Prototype Evaluation

Objective: test usability and desirability separately. They are independent risks — a product can pass usability and fail desirability, or vice versa.

**Choose the cheapest prototype that answers the top assumption:**

| Type | Effort | Tests |
|---|---|---|
| Static mock | Lowest | Value prop, mental model |
| Interactive prototype (Figma) | Low | Usability, navigation |
| Wizard of Oz | Low–medium | AI/algorithmic features before the algorithm exists |
| Concierge MVP | Low | Whether the outcome is wanted, no UI needed |
| Flintstoning | Medium | Full experience with deferred engineering |

Build one prototype per CUJ or per top assumption — whichever is cheaper to test first.

**Usability testing (N=5 per round):**
- Give users a task matching the CUJ — not a tour of the product.
- Think-aloud protocol: have them narrate their cognitive process. Hesitation marks where the design fails.
- For each CUJ: can the user complete it without intervention?
- Gate: 4 of 5 users complete the core CUJ without help. Fix blockers, test 5 new users. Repeat until gate passes.

**Desirability testing (signals separate from usability):**
- Unprompted referral: did they mention it to anyone after the session?
- Willingness to pay: fake-door pricing or "at $X/month, would you switch?"
- Behavioral commitment: waitlist signup, paid pre-order, calendar follow-up.
- Gate: ≥3 of 5 take a behavioral commitment and ≥2 articulate the value prop unprompted in their own words.

After each round, update the assumption map — evidence has shifted, so the importance × evidence ranking has moved.

Pivot conditions:
- Pass usability, fail desirability → the design works but no one wants the product. Return to Phase 1 (problem reframe).
- Pass desirability, fail usability → iterate and retest in Phase 2.
- Pass both → proceed to Phase 3.

---

## Phase 3 — Trusted Tester MVP (N=20+)

Objective: transition from controlled testing to operational reality. A trusted tester program is a structured research instrument, not a beta launch.

Timebox: 6–12 weeks per cycle.

**Cohort structure:**
- 20–100 users. Explicit written contract: white-glove support and early access in exchange for rigorous feedback.
- Recruit your core segment plus one adjacent segment. Avoid recruiting only friendlies — they pass desirability tests for social reasons.
- B2B: recruit by role across accounts, not just by account. Track buyer, champion, and user separately. A churning champion predicts account churn before product telemetry does.

**Per-CUJ tracking:**
- Pair quantitative dropout (where in the CUJ does the user abandon?) with qualitative intercept (why at that moment?).
- Diary studies over 2–4 weeks: how does the product feel after novelty wears off?
- Run focused 3-day sprints per CUJ rather than open-ended "how is the app?" feedback.

**Finetuning loop:**
- Triage feedback: (1) critical CUJ blockers — fix immediately; (2) usability friction — fix next sprint; (3) feature requests — log for roadmap.
- Close the loop with testers when their reported issues ship. Builds trust, maintains engagement for future rounds.

Pivot condition: retention curves not flattening by week 4–6 → value isn't sticking. Return to the Phase 1 assumption map — likely a value risk assumption was wrong, not a usability one.

---

## Phase 4 — Build–Measure–Learn / PMF

Objective: verify product-market fit before scaling spend. Do not assume Phase 3 success implies PMF.

**PMF signals:**
- Retention curve (Balfour): plot cohort retention over time. PMF = curve flattens at an asymptote above zero. Decays to zero = you have early adopters, not a market.
- Sean Ellis score: ≥40% of active users say they'd be "very disappointed" if the product disappeared. Use alongside retention curves, not as a standalone signal.

**Metrics by stage:**

| Category | Key metrics |
|---|---|
| Activation | Time to first value; % completing first CUJ |
| Engagement | Frequency of core CUJ action; feature adoption rate |
| Retention | N-day retention, MAU, churn rate |
| Revenue | Conversion rate, ARR, LTV/CAC |
| Guardrail | Cancellation rate, refund rate, support ticket volume |

**Continuous discovery at scale:**
- Churn autopsies: JTBD switch-interview structure in reverse — what pulled them away? What did they switch to?
- Adjacent user research: who signs up but fails to complete the first CUJ? That's the next segment to unlock.
- Cohort decay: compare retention curves across acquisition cohorts. Newer cohort decays faster → product is regressing or the early-adopter pool is exhausted.

Pivot condition: retention curve bends down or Ellis score drops below 40% across two consecutive cohorts → run churn autopsies before scaling further. Return to the assumption map.

---

When Phase 4 PMF signals are positive, prompt the user to run `/to-prd` to lock down the full product spec.
