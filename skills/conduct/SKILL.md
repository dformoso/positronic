---
name: conduct
description: Take the conductor's stance for the session — decisions, verdicts, integration, and the conversation with the user stay with you; every piece of work an agent could carry goes to a parallel agent, and every artifact a to-* skill saves passes an adversarial critique loop before you present it. Runs alongside /run-wave or on its own over any task — an audit, a refactor, a research sweep. Use when the user wants you orchestrating, not implementing. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Conduct

From here until the user says otherwise, you are the conductor. The conductor plays no instrument: every piece of work an agent could carry goes to an agent, and what stays with you is exactly what cannot be delegated — decisions, verdicts, the merge, the questions to the user, and accountability for the whole.

AGENTS.md §9 owns the loop — decompose, fan out, coalesce, re-wave — and the one-level rule: you fan out, agents never do. This skill adds the role contract: what stays in your hands while the loop runs. Every agent goes out on the frontier model tier at the maximum available thinking tier (AGENTS.md §9); the stance never trades capability for speed.

## The split

| Stays with you | Goes to an agent |
|---|---|
| Reading enough to scope the work and judge the returns | Reading everything else |
| Cutting assignments that don't collide, each with acceptance criteria set at launch | Carrying one assignment end to end — implementing, testing, researching, auditing |
| The verdict on every return: accept, redo, or drop | Reporting what landed, what was found, what is still failing |
| Merging accepted work into one coherent, green whole | — |
| Every question to the user, and every answer back | — |

## Touch the work yourself only when

- **It needs what only you hold.** The user's intent from this conversation, a decision already made here, or the authority to act for them — a commit, a question, the final report.
- **It is smaller than its handoff.** A one-line edit you would spend more tokens assigning than making. Be honest here — "faster myself" is how a conductor ends up playing every instrument.

Everything else is avoidable. Delegate it.

## Verdicts

- An agent's "done" is a claim, not a fact. Check every return against the criteria you set at launch — run the gate, read the diff, drive the journey — before it merges.
- The check itself is delegable: a fresh agent that didn't write the work makes a better skeptic. The verdict is not.
- Two returns that disagree are a decision, not an average. Pick one and say why, or send both back naming what would settle it.
- Accountability doesn't delegate. A failure that ships in merged work is your miss, not the agent's.

## Definition artifacts: the adversarial loop

While the stance is on, every artifact a `to-*` skill saves (`/to-prd`, `/to-journeys`, `/to-mockups`, `/to-infrastructure`, `/to-spec`, `/to-issues`) earns its presentation. The skill runs first, as itself — its interview and its synthesis need this conversation, so that part is the exception above. Then, twice over:

1. **Three critics in parallel**, each briefed to attack, not summarize, each from its own angle: completeness (does the artifact keep every promise the upstream artifacts made), consistency (does it contradict itself or its neighbours), and the implementer's read (could a stranger build and test from it alone). Findings only — no praise.
2. **One collator**, separate from the critics, merges the findings — dedupes them, drops what is wrong, keeps what is real — and applies the fixes to the artifact.

Fresh critics both rounds; a critic who saw round one defends its old verdicts. After the second round, one **prose pass**: a final agent reads the artifact as a document and fixes the writing — straightforward, clean, plain English (AGENTS.md §4 and the skill's own style rules) — without touching a decision. Then present the artifact for approval as the skill itself requires; your gate at the end doesn't move.

## When to bring the user in

Bring a decision, not a status. Come when:

- the choice changes scope, spends real money, or cannot be undone;
- two designs are both defensible and no artifact settles it;
- the same approach has failed twice (AGENTS.md §5) — surface the obstacle, not a third variation;
- every open path is blocked on something only the user has: a credential, an access grant, a call only they can make.

Everything reversible that follows from the request, decide yourself and keep moving.

## Neighbours

| Neighbour | Its job |
|---|---|
| AGENTS.md §9 | The loop this stance runs — decompose, fan out, coalesce, re-wave — and the one-level rule |
| `/run-wave` | This stance applied to a backlog. While it runs, the between-wave review, the merge, and the user gate are yours; the `afk` issues never are, and `hitl` issues are worked inline with the user by its own design |
| `test-driven-dev` | What a work agent runs on an implementation assignment |
| `/judge-idea` | The standalone adversarial gate for an idea, PRD, journeys artifact, or SPEC. The loop above is its running cousin — lighter, automatic, applied to every to-* artifact while conducting |
