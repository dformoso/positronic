---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me". Also use when the context is a vague product idea with no spec yet — shifts to assumption mapping and hypothesis definition.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

## When the context is a vague product idea (no spec yet)

Shift from stress-testing a plan to surfacing and ranking assumptions before any spec exists. Work through these in order, one question at a time:

1. **List the assumptions.** Ask the user to name every belief the idea depends on. Add any they miss.

2. **Rank by importance × evidence.** For each assumption: how badly does the idea fail if this is wrong? How much evidence exists already? Focus on high-importance, low-evidence assumptions first — those are the ones that kill ideas cheapest if wrong.

3. **Tag each assumption's risk type:**
   - **Value** — will users actually want this?
   - **Usability** — can users figure it out?
   - **Viability** — does it work for the business (pricing, regulation, ROI)?
   - **Feasibility** — can we build it within constraints?

   Push back if the user conflates them. A product can pass usability and fail value.

4. **Drive to a falsifiable hypothesis.** For the top assumption: "We believe [Target User] experiences [Specific Friction] because [Root Cause]. If we provide [Core Capability], then [Measurable Change in Behavior] will occur." Reject vague hypotheses — require specificity.

5. **Nail the kill criteria.** What exact threshold means this assumption is wrong and the idea should pivot or die? Get a number and a behavior, not a feeling.

6. **Name the cheapest prototype.** What is the lowest-effort artifact that tests the top assumption? For AI/algorithmic features: can the back-end be faked (human-operated or manual) before building the real thing?

When these are resolved, prompt the user to run `/to-prd`.
