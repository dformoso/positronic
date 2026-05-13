---
name: judge-idea
description: Adversarial pass on the most recent ideation winner (or PRD/SPEC). Enumerates weak assumptions, data gaps, logic holes, missed pivots; outputs verdict = proceed | loop-back-to-{research, ideate} | pivot. Use after /ideate, before /to-prd.
disable-model-invocation: true
---

Try to invalidate the chosen direction. Enumerate everything that could be wrong. Output a single named verdict with what to fix on the next iteration if loop-back is required.

## Inputs

By default, the most recent ideation winner: `ls ideas/[0-9]*/winner.md | sort | tail -1`. Plus the most recent research artifact for cross-reference.

Can also be run on a PRD or SPEC after the fact. If invoked after `/to-prd` or `/to-spec`, target the most recent `prds/` or `specs/` artifact instead.

If no target artifact exists, prompt the user for which artifact to judge and stop.

## Process

1. **Read the target artifact and its inputs.** Don't judge in isolation — evidence matters.

2. **Enumerate weaknesses across these axes:**

   | Axis | Question |
   |---|---|
   | Wrong assumptions | What does this assume about user behavior that the research doesn't actually support? |
   | Weak assumptions | What does it assume that's plausible but unverified — and what data would confirm or kill it? |
   | Data gaps | What did `/research-market` not cover that's load-bearing for this idea? |
   | Logic holes | Where do the steps from problem → solution skip a beat? |
   | Missed pivots | What adjacent problems did the rubric or ranking under-weight? |
   | Historical failures | Have similar bets failed before? Why? Does this idea repeat the pattern? |
   | Distribution risk | How will users actually find this? Is the channel cost-feasible? |
   | Defensibility | What stops a competitor copying this in a quarter? |

   For each axis, either name a specific concern *or* write "none found — here's why" (briefly justify, don't skip).

3. **Decide the verdict.**

   | Verdict | When | Loop-back target |
   |---|---|---|
   | **proceed** | No load-bearing concerns; minor risks documented and acceptable | User runs `/to-prd` |
   | **loop-back-to-research** | Data gaps make the decision unsafe | User re-runs `/research-market` with a sharpened scope |
   | **loop-back-to-ideate** | Rubric or ranking missed something; idea space wasn't properly explored | User re-runs `/ideate`; rubric likely needs editing |
   | **pivot** | Problem framing itself looks wrong | User loops back to `define` |

4. **Write the judgment.** Save as `judgments/YYYY-MM-DD-HH-mm-SS.md` (use `date +"%Y-%m-%d-%H-%M-%S"`; create the directory). Use the template below. Commit.

5. **Present verdict to user.** Show the judgment. The user decides whether to follow the recommendation or override and proceed anyway.

## Template

<judgment-template>

# Judgment: {{target artifact path}}

**Target.** {{ideas/.../winner.md, prds/..., specs/..., etc.}}

**Verdict.** {{proceed | loop-back-to-research | loop-back-to-ideate | pivot}}

**One-line reason.** {{...}}

## Findings

| Axis | Concern | Severity (low/med/high) | Fix on next iteration |
|---|---|---|---|
| Wrong assumptions | | | |
| Weak assumptions | | | |
| Data gaps | | | |
| Logic holes | | | |
| Missed pivots | | | |
| Historical failures | | | |
| Distribution risk | | | |
| Defensibility | | | |

## What to fix before re-running

(Only if verdict ≠ proceed. Concrete sharpening — not "do better research" but "specifically: fetch the last 12 months of churn complaints from Trustpilot for $competitor".)

</judgment-template>
