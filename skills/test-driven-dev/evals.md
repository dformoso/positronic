# Evals: grading model behavior

The same red-green-refactor loop applies, but a slice whose acceptance criteria depend on
model behavior — an LLM call, an agent loop — needs two kinds of checks, split by seam:

- **Tests** grade the code around the model: parsing, tool dispatch, state, error paths.
  Deterministic, binary, model mocked (see [mocking.md](mocking.md)), run every cycle.
- **Evals** grade the model's behavior through your harness: did it take a sane path, is the
  output grounded, does it meet the bar. Scored against a threshold over a set of cases,
  run on the real model.

RED means the evalset exists and the implementation scores below threshold. GREEN means it
clears the threshold. REFACTOR — prompt and tool tweaks — reruns the evalset as the
regression gate. Without evals, only the deterministic shell is verified; the behavior the
user actually experiences ships unchecked.

Foundation: `${SKILL_DIR}/../../docs/agentic-patterns/07_eval_observability_brief.md` (`${SKILL_DIR}` = the directory containing this file)
— the ranked evidence behind these rules.

## 1. The SPEC already picked your signal

The SPEC's Eval / test signal section chose a rung: smoke asserts, held-out synthetic set,
or curated dataset with a graded metric. The eval slice implements that pick. Don't
re-derive it mid-slice — the upstream artifact is the contract, same as the issue.

## 2. Build the evalset like you build tests

Tracer bullet first: 5–10 cases, one per behavior the slice claims. Grow it one case per
cycle, plus one per discovered failure — a bad production trajectory becomes an eval case
the way a bug becomes a regression test. Bulk-authoring fifty imagined cases up front is
horizontal slicing with the same result: cases that grade the shape of the output, not the
behavior.

A case is an input plus the hardest expectation the behavior allows:

```jsonl
{"input": "refund order 123", "expect": {"tool_path": ["lookup_order", "check_policy"], "must_not_call": ["issue_refund"], "judge": "asks for confirmation before committing a refund"}}
{"input": "what's your refund policy?", "expect": {"tool_path": [], "judge": "answers from policy doc, no order lookup"}}
```

If a case needs a multimodal input (image, audio, document), invoke `generate-test-assets`
— same as any other fixture.

## 3. Grade the cheapest way that can fail honestly

| Grader | Use for | Watch out |
|---|---|---|
| Exact / schema match | classification, extraction, structured output | misses path quality entirely |
| Rule-based checks | tool order, citation present, format, step budget | brittle to phrasing; keep rules semantic |
| LLM-as-judge | groundedness, hallucination, task success, response quality | judge variance and bias; costs per run |

Climb only when the rung below can't fail honestly — a judge grading something a schema
check could catch is paying variance for nothing.

Judge discipline, when you do climb: anchored rubric (each score has a written description,
or binary per dimension), judge model pinned at temperature 0, judge cheaper than the agent
it grades, judge from a **different model family** than the one it grades (a judge grading
its own family marks its own homework), and hand-check its verdicts on the first run. A judge you disagree with on more
than ~1 in 10 verdicts is itself RED — fix the rubric before trusting the scores.

## 4. Grade the trajectory when the path is the behavior

A right answer reached via a wrong path fails under load. When the slice's claim is about
*how* the agent works — right tool, no loops, no unauthorized action — assert on the
trajectory, not the final text:

```python
def grade_trajectory(run, case):
    called = [step.tool for step in run.steps]
    assert called[:len(case.tool_path)] == case.tool_path
    assert not set(called) & set(case.must_not_call)
    assert len(run.steps) <= STEP_BUDGET  # a loop is a failure even if the answer lands
```

This requires the harness to log trajectories in the first place — if it doesn't, that's
the real first task of the eval slice.

## 5. GREEN is a threshold on a pinned model

A single passing run proves nothing about non-deterministic behavior. GREEN is a threshold
over the set — and the model under eval is pinned, or the suite measures provider drift
instead of your change:

Two kinds of cases, and the distinction is load-bearing: **hard gates** (safety and money —
a `must_not_call` violation, an unauthorized action) fail the suite outright no matter how
many other cases pass; **threshold cases** score against the bar. A corpus sum alone lets
one unauthorized-refund failure ship green behind eight cosmetic passes — improvements must
never average away a hard failure, and a case that reliably passed becoming reliably failing
is a regression even when the total score rises.

```python
MODEL = "model-id@YYYY-MM-DD"  # pinned; bumping it is its own diff with its own eval run

def test_refund_agent_evalset():
    results = [grade(run_agent(c.input, model=MODEL), c) for c in CASES]
    hard = [r.case_id for r in results if r.hard_gate and not r.ok]
    assert not hard, f"hard-gate failures (safety/money): {hard}"  # no threshold can excuse these
    passed = sum(r.ok for r in results)
    assert passed >= 8, f"{passed}/{len(CASES)}; failed: {[r.case_id for r in results if not r.ok]}"
```

For a case that flakes at the threshold, run it k times and score the majority — variance
is data about the behavior, not noise to rerun away.

## 6. Tier by cost

- **In-loop** (every red-green cycle): the tracer set, cheapest graders only.
- **CI gate** (per merge): the full evalset — this is the regression suite; a score drop
  blocks the same way a failing test does.
- **Nightly / pre-release**: judge-graded dimensions, multi-sample runs, anything too
  expensive per-merge.

Evals hit a paid API, so the environmental-skip rule from [tests.md](tests.md) applies
verbatim: skip on credit/rate-limit/auth failures, fail only on behavior regression. Record
those skips as **VOID, not PASS**, and report the VOID rate per run — a rising VOID rate is
an availability finding in its own right, and an arm with more VOIDs is paying an
availability cost the accuracy number hides.

Stack note: on Google ADK, the `google-agents-cli-eval` skill covers evalset schema and
runner mechanics. The rules here don't change — only the file format does.

## 7. Swapping the model: the comparison protocol

"Should we switch models?" is an eval question, not a vibes question. When a model change
is on the table:

- **Paired arms on identical cases.** Every arm runs the same evalset; only the component
  under test swaps (the main model, the judge, one prompt) — never two changes in one
  comparison.
- **Pin every arm to a dated snapshot id.** An alias that silently re-points mid-run
  measures provider drift, not the candidate.
- **Report cost beside accuracy.** Measured tokens priced per arm, projected to monthly
  spend at current volume — the verdict is a price/quality pair, never a score alone.
- **"As accurate or better" only if all three hold:** (1) no case that reliably passed
  becomes reliably failing — regressions are judged per case, never netted against
  improvements elsewhere; (2) zero new hard-gate (safety/money) failures; (3) VOID/retry
  rates no worse — availability is part of the result.
- The switch itself stays a human call, made on this report.

## What not to eval

- **Deterministic seams.** If a mock-model test can assert it, it's a test. Evals are for
  what only the real model produces.
- **The provider.** Benchmarking model capability is the vendor's job; you grade your
  prompt, tools, and harness on your task.
- **Nothing, at 100%.** An evalset that always passes grades nothing — if it's been green
  for weeks untouched, the hard cases are missing.
- **Your own tuning target.** If you iterate prompts against the evalset until green, hold
  out a few cases you never tune against — an optimizer with a cheap signal games the
  metric instead of improving the behavior.
