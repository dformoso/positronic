---
name: readout
description: Post-launch readout — weeks after a change ships, check whether the PRD's success metrics actually moved and whether any kill criterion fired, then return keep / iterate / cut / pivot. Reads the real numbers from the instrumentation the SPEC's Observability section named. Use when the user asks whether a shipped feature worked, wants a post-launch review, or is deciding what to build next. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Readout

Weeks after a change ships, go and look at whether it worked.

This closes the only loop positronic otherwise leaves open. `define` frames a falsifiable hypothesis and sets kill criteria — an exact threshold that means pivot or die. `/to-prd` carries them. Then the thing ships and **nothing ever checks**. Without this step the PRD's success metrics are decoration: no number can fail, so shipping teaches nothing, and every next increment is chosen on vibes.

Report-only on the code — it changes nothing and fixes nothing. It writes one dated record and returns a verdict.

**When to run it.** At the date the PRD's kill-criteria table set, typically two to six weeks after the change reaches real users. Early enough that you can still act, late enough that the numbers mean something. Also run it at the version hinge, before defining the next increment — `clean-house` step 1 asks whether each requirement is exercised in reality, and this is the evidence that answers it.

## Process

### 1. Recover what was promised

| Source | What to take |
|---|---|
| `definitions/prd.md` — *Goals & Success Metrics* | The anchoring promise, the metrics, their targets, and the **kill criteria** with their dates |
| `definitions/spec.md` — *Observability* § product metrics | For each metric: the signal that measures it, where it's read, and the **baseline recorded before launch** |
| `definitions/prd.md` — *Risks & Open Questions* | What the team said might go wrong. Did it? |
| The `define` hypothesis, if it's in the git history of the PRD | The belief being tested, in its original words |

If the SPEC has no product-metric table, the metrics were never instrumented. That is itself the readout's first finding — report it plainly, note that this launch cannot be judged, and prompt an amend to the SPEC's Observability section so the *next* one can be. Don't substitute a number you can find for the number that was promised.

### 2. Read the actual numbers

Go and get them: run the query, open the dashboard, hit the endpoint, count the rows. **Cite what you ran.** A number you inferred, remembered, or estimated is not a reading, and putting it in the table poisons every decision downstream.

| Metric | Baseline | Target | Actual | Read by |
|---|---|---|---|---|

Rules that keep this honest:

- **A metric you can't read is a finding, not a blank.** Say which instrumentation is missing and what would produce it.
- **Small numbers stay small numbers.** Four users is not a percentage. Say "3 of 4 users completed the first journey", never "75%" — a rate computed off single digits reads as evidence and isn't. Name the denominator every time.
- **No substitution.** If the promised metric didn't move but a different one did, both go in the table and the promised one still governs the verdict. Reporting the metric that happened to move is the single clearest sign of a feature factory.
- **Check the counter-metrics.** Something that got worse while the target got better — support load, latency, cost per user, churn in a neighbouring segment. A win that quietly moved cost per user 4× is not a win.

### 3. Check the kill criteria first

Before weighing anything else. They were set in advance precisely so that a good story told after the fact can't talk past them.

| Kill criterion | Fired? | Evidence |
|---|---|---|

A fired criterion constrains the verdict no matter how good the rest looks. If you're about to argue around one, that argument is the finding — write it down and put it to the user rather than resolving it yourself.

### 4. Write down what surprised you

The qualitative half, and the part that most often produces the next thing worth building. Three or four bullets, concrete:

- What users did that nobody predicted — including the workaround they invented.
- What they ignored entirely. A shipped feature at zero usage is a `clean-house` candidate, and this is where that gets noticed.
- What broke, or nearly did.
- Which assumption from the PRD's Risks table turned out wrong.

### 5. Verdict

One of four, with a reason in one sentence:

| Verdict | Means | Route |
|---|---|---|
| **keep** | Metric hit target, no kill criterion fired. Leave it alone and go work on something else | Nothing. Resist polishing something that is already working |
| **iterate** | Direction is right, magnitude isn't. A specific, named change would plausibly close the gap | `define` in increment mode — frame just that change |
| **cut** | Nobody used it, or it costs more than it returns | `clean-house` in targeted mode, naming this feature |
| **pivot** | The hypothesis was wrong — a kill criterion fired against the bet, not against the execution | `define` from scratch. If the Target User or Problem Statement is what was wrong, the PRD is rewritten, not amended (`${SKILL_DIR}/../../docs/amend-mode.md`; `${SKILL_DIR}` = the directory containing this file) |

Refusing to pick is also a signal: if the numbers can't distinguish these four, the metrics were the wrong metrics. Say so, and fix them in the PRD before the next increment inherits them.

### 6. Save

**Write it in plain English** — short sentences, one idea each, concrete before abstract, jargon glossed on first use, readable by someone who wasn't in this conversation (AGENTS.md §4).

Always write the record — this one isn't optional, because a readout nobody can find is a readout that didn't happen:

`docs/audits/YYYY-MM-DD-readout.md`

Create `docs/audits/` lazily on first save. Commit it. Successive readouts are separate dated files, never edits to an earlier one — the sequence is the product's actual history, and an amended readout loses the thing that made it worth writing.

<readout-template>

# Readout — <what shipped> — YYYY-MM-DD

**Shipped:** <date> · **Window:** <how long it has been live> · **Verdict:** keep | iterate | cut | pivot

## The bet

The hypothesis and the anchoring promise, in the PRD's original words. One short paragraph.

## Metrics

| Metric | Baseline | Target | Actual | Read by |
|---|---|---|---|---|

## Kill criteria

| Criterion | Fired? | Evidence |
|---|---|---|

## Counter-metrics

| What could have got worse | Before | After |
|---|---|---|

## What surprised us

- …

## Verdict and route

One sentence for the verdict, one for what happens next, naming the skill that does it.

## Instrumentation gaps

Metrics that couldn't be read, and what would make them readable next time. Empty is a good answer; say so explicitly.

</readout-template>
