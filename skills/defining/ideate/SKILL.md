---
name: ideate
description: Generate, rank, and pick a product idea grounded in the most recent research artifact. Produces 10 one-page concepts, ranks against a user-approved rubric, presents top 3 with tradeoffs. Use after /research-market.
disable-model-invocation: true
---

Generate ten product concepts grounded in the most recent research artifact. Propose a rubric, get it approved, rank, present the top 3, let the user pick.

## Inputs

- Most recent research artifact: `ls research/[0-9]*/summary.md | sort | tail -1`. If none exists, prompt the user to run `/research-market` first and stop.
- Existing rubric (carried forward across runs): `ideas/rubric.md`. If none exists, propose a fresh one.

## Process

1. **Read the research artifact.** Both the customer pain and competitive landscape sections.

2. **Propose a rubric.** Draft 5–7 weighted criteria grounded in what the research surfaced. Examples (weights illustrative):

   | Criterion | Weight | Why |
   |---|---|---|
   | Severity of pain addressed | 25% | Research showed X is the highest-severity recurring pain |
   | Time to MVP | 15% | Speed matters at this stage |
   | Organic expansion path | 15% | Idea must start small and grow |
   | Defensibility | 15% | Competitive landscape shows low moats kill this category |
   | TAM / SAM | 10% | Market size floor |
   | Founder fit | 10% | Caps what we can execute well |
   | Distribution channel | 10% | How users will find the product |

   If `ideas/rubric.md` exists from a prior run, use it as the starting point and propose deltas based on new research.

   **Show the rubric to the user. Get approval or edits before ranking anything.** The rubric is the strategy — it must be user-owned.

3. **Generate 10 one-pagers in parallel.** Each ≤ 1 page, using the template below. Spread across pain themes — don't concentrate on one. Each idea should:
   - Start small (a focused MVP that solves one acute pain)
   - Have a credible organic expansion path (1–2 complementary features that ramp value)

4. **Rank against the approved rubric.** Score each one-pager on each criterion (1–5). Compute weighted total. Sort.

5. **Present the top 3 with tradeoffs.** Winner + 2 runners-up. For each: the idea in one sentence, why it ranked where it did, what the tradeoff is vs the others.

6. **User picks.** The user names the winner (may not be #1 — they may weigh tradeoffs differently). Save:
   - `ideas/YYYY-MM-DD-HH-mm-SS/rubric.md` (the approved rubric — also overwrite `ideas/rubric.md` for carry-forward)
   - `ideas/YYYY-MM-DD-HH-mm-SS/1.md` … `10.md` (one-pagers, in ranked order)
   - `ideas/YYYY-MM-DD-HH-mm-SS/winner.md` (the chosen idea, marked WINNER, with the user's reasoning if they overrode the ranking)

   Commit all of the above.

7. **Hand off.** Prompt the user to run `/judge-idea` to adversarially test the winner before `/to-prd` commits.

## One-pager template

<one-pager-template>

# {{Idea name}}

**Problem.** One sentence — which pain from research this addresses, citing the theme.

**Segment.** Which user / customer this is for. If multi-sided, name each side.

**MVP.** The smallest version that delivers value. 2–3 sentences.

**Organic expansion path.** 1–2 complementary features that ramp value once the MVP lands. Each ≤ 1 sentence.

**Differentiator.** What makes this different from the competitors in the research artifact. One sentence.

**Key risks.** Top 2–3 things that could kill it. Bullets.

**Score.**

| Criterion | Score (1–5) | Notes |
|---|---|---|
| | | |

**Weighted total.** {{N}}

</one-pager-template>
