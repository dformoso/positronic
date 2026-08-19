---
name: to-journeys
description: Expand each PRD journey into an executable script — preconditions, numbered steps, branches, and the end-state proof a test asserts — plus the reference tables the journeys run on. Saves definitions/journeys.md. Use after /to-prd, before to-mockups and /to-spec. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

Expand the PRD's journeys into scripts detailed enough to build from and to test against. Do NOT re-interview the user on *why* or *who* — the PRD settled those. Work from it, the codebase, and the conversation.

**Why journeys are the spine.** A journey is already this framework's unit of proof: `/to-spec`'s verification-fidelity axis drives a CUJ end to end, `/to-issues` slices vertically along one, `test-driven-dev` writes it as the tracer-bullet test, and AGENTS.md requires a real browser to walk one before UI work is done. But the PRD states each journey in two sentences, which is a story, not something you can assert on. This file is where a journey becomes executable — and the **end-state proof** at the bottom of each one is the assertion the first test makes.

The line against its neighbours:

| Question | Owner |
|---|---|
| Why build it, for whom, what outcome | `definitions/prd.md` |
| What the user does, step by step, and how you prove it worked | **this file** |
| How the app is arranged, how it looks, and what each screen shows | `definitions/mockups.md` + `definitions/mockups.html` (`to-mockups`) |
| How it is built | `definitions/spec.md` (`/to-spec`) |

## Amend mode

If `definitions/journeys.md` already exists and this run is a scoped change (not a from-scratch rebuild), run in amend mode per `${SKILL_DIR}/../../docs/amend-mode.md` (`${SKILL_DIR}` = the directory containing this file): read it as baseline, edit only the journeys and reference rows the change touches (reconcile any it contradicts), leave every other journey byte-for-byte alone, and update the Amendment header. Then name which downstream artifacts the touched sections implicate — new or changed steps → `definitions/mockups.md` and `definitions/mockups.html`; the autonomy matrix → `definitions/harness.md`; new channels or tools → `definitions/mcp-servers.md` — prompt only those, then `/to-spec`.

## Inputs

- `definitions/prd.md` — required. Its **Key User Journeys** section is the index: every journey here expands one entry there, by the same name and number. If it doesn't exist, prompt the user to run `/to-prd` first and stop.
- `definitions/research.md` and `definitions/ideas.md` if they exist — evidence behind a step or a rule.
- The codebase, if a project already exists.

## Process

1. **Expand every PRD journey, and only those.** The PRD owns which journeys exist; this file owns what happens inside them. A journey here with no PRD entry is scope creep — take it back to the PRD. A PRD journey nobody can expand is a journey nobody has thought through — say so.

2. **Write each journey as a script, not a story.** The format below is the point: preconditions the world must be in, the concrete data it runs on, numbered steps each with an actor and an *observable* result, the branches that leave the happy path, and one end-state proof. If a step's result isn't observable from outside the system, it isn't a step — it's implementation, and it belongs in `/to-spec`.

3. **Name shared segments once.** When two journeys both start with sign-in, write it once as its own short journey and reference it (`Precondition: J0 complete`). Three copies of the same six steps disagree with each other by the second increment — this is the one real cost of organising by journey, and naming segments is what pays it.

4. **Force the branches.** The failure this format invites is three beautiful happy paths, three green end-to-end tests, and every branch untested. Every journey needs its Branches table filled: what happens when the input is rejected, the dependency is down, the queue is empty, the limit is spent, the user abandons halfway. A journey with no branches is a journey you haven't finished.

5. **Then write the reference half** — what the journeys run on and what no journey touches. Data model, external channels, agent autonomy, queues, notifications, integrations, permissions. If a rule applies inside exactly one journey it belongs in that journey's Rules row; if it crosses journeys it is hoisted to the cross-journey table; if it belongs to no journey at all it goes under *Behaviour with no journey*.

6. **Every requirement carries an owner and a failure.** An owner you could trace it to — a person, a research finding, a judgment — and a failure you can name if it's dropped. "Best practice" and "the model suggested it" are departments, not owners. Rows without an answer go to the PRD's Out of Scope. (`/clean-house` re-asks both questions of every surviving row between versions.)

7. Save as `definitions/journeys.md` (create `definitions/` if missing). Commit it.

8. **Length and density.** As long as the product needs — this is the artifact that scales, and the PRD stays short precisely so this one can be complete. Tables wherever they carry the meaning; prose only when they can't.

9. **Style.** This is the technical tier — vendor names, SDK names, protocol mechanics, regulatory rules belong here, packed into cells rather than prose. One layer of detail per sentence. Use the same bolded product nouns the PRD used for surfaces; never mint a synonym for something the PRD already named.

10. Present the saved file and ask the user to review. Then prompt the next step:
    - If the product has persistent UI surfaces, prompt them to run `to-mockups` — it locks the identity and structure and draws every step and branch as a panel.
    - If the project involves a custom LLM/agent harness, prompt them to run `pick-harness-shape`.
    - Otherwise, prompt them to run `/to-spec`.

<journeys-template>

## Source PRD

`definitions/prd.md` — the PRD whose Key User Journeys these expand.

## Journey inventory

| # | Journey | Actor | Trigger | Surfaces | Tier | Status |
|---|---|---|---|---|---|---|

Tier: `feature` · `internal` · `fix`. Status: `planned` · `built` · `cut`. Every row matches a PRD journey by name.

## Journeys

One `###` section per row, in inventory order.

<journey-section>

### J1 — <Name, matching the PRD>

**Precondition.** The state the world is in before step 1. Include what does *not* exist yet.
**Data.** The concrete values this runs on — real names, real numbers, real timestamps. The same data `to-mockups` populates its panels with and the test fixtures use.
**Surfaces.** The bolded product nouns the user touches, in order.

| # | Actor | Action | Observable result | Panel |
|---|---|---|---|---|

The **Panel** column names the screen this step shows (`#convos-unread`); `to-mockups` draws one panel per row and per branch. Leave it blank for steps with no screen. Actor is a person, an external system, or the product itself — never a module.

**End-state proof.** One assertion. After the last step, what is observably true that wasn't before? Name the records, counts, and states a test can check. This is the tracer-bullet test `test-driven-dev` writes first, and the thing `/to-issues` copies into the slice's acceptance criteria.

**Branches**

| At step | When | Then | Panel |
|---|---|---|---|

Rejected input, dependency down, empty set, limit spent, timeout, user abandons. Each branch is also a test and also a panel.

**Rules**

Logic that decides, and applies only inside this journey. Validation, thresholds, precedence, timing. Anything that appears in a second journey moves to the cross-journey table below.

| Rule | Behaviour when satisfied | Behaviour when violated | Owner |
|---|---|---|---|

</journey-section>

## Cross-journey rules

Rules that hold everywhere. Stated once here rather than repeated per journey.

| Rule | Applies to | Behaviour | Owner |
|---|---|---|---|

## Behaviour with no journey

What the product does that no user walks through: retention sweeps, background sync, scheduled jobs, admin-only paths, data migration. Real behaviour that needs building and testing, and the section that stops journeys-first from quietly dropping it.

| Behaviour | Trigger | What it does | How it's observed |
|---|---|---|---|

## Reference

What the journeys run on. `/to-spec`, `pick-harness-shape`, and `design-mcp-server` read these directly.

**Data model.** Entities the user touches and what they hold. Implementation-level schema — indexes, constraints, migrations — goes to `/to-spec`.

| Entity | Key fields | Relationships | Created by / deleted by |
|---|---|---|---|

**External channels & touchpoints.** Every place the product receives input or emits output to the outside world: SMS, email, voice, API endpoints, push, webhooks. Internal app surfaces are `to-mockups`.

| Channel | Inbound behaviour | Outbound behaviour | Rate / quota | Notes |
|---|---|---|---|---|

**Agent autonomy matrix.** *(If AI is involved.)* For every action the agent can take: default, confidence gate, the trigger that hands it to a human. Anything that touches the user externally or commits resources defaults to human-in-the-loop until explicitly justified. This table is the cascade edge into `definitions/harness.md` — the gates there implement these rows.

| Action | Default | Confidence gate | Hands to human when | Irreversible? |
|---|---|---|---|---|

**Queues & approval flows.** *(If the product holds work for human review.)* What each queue holds and how an item moves through it. Where it is seen — badge counts, drawer vs. full page — is `to-mockups`.

| Queue | Holds | Enters when | Leaves when | Expiry / escalation |
|---|---|---|---|---|

**Notifications & digests.** *(If users get pushed updates.)* Modes available, the default, and what overrides it.

| Mode | Default? | Behaviour | Override |
|---|---|---|---|

**Integrations & migration.** Third parties the product reads from or writes to, and how users bring existing data in. Which vendor and why is a `docs/adr/` record via `/pick-cloud-services`.

| Integration | Direction | Behaviour | Auth | Failure behaviour |
|---|---|---|---|---|

**Permissions.** *(If more than one kind of user exists.)* One row per role.

| Role | Can read | Can write | Can approve | Can administer |
|---|---|---|---|---|

## Open questions

What couldn't be settled with current information, each naming what would settle it. Anything load-bearing enough to change the product belongs in the PRD's Risks table instead.

| Question | Blocks which journey | What would settle it |
|---|---|---|

</journeys-template>
