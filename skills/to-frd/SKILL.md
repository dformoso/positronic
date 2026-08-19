---
name: to-frd
description: Turn definitions/prd.md into a functional requirements document — every feature's behaviour, states, rules, and testable acceptance criteria — and save it as definitions/frd.md. Use after /to-prd, before pick-ui-surfaces and /to-spec. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

Expand `definitions/prd.md` into the behaviour of each feature. Do NOT re-interview the user on *why* or *who* — the PRD settled those. Work from it, the codebase, and the conversation.

**The split.** The PRD is the brief a person re-reads: problem, user, journeys, metrics, scope. The FRD is the detail an implementer works from: what each feature does with every input, in every state, under every rule. `/to-spec` turns this into modules and schema; `/to-issues` lifts the acceptance criteria straight into issues. Keep implementation out — no modules, no code-level schema, no API signatures, no test plan.

The line against its neighbours:

| Question | Owner |
|---|---|
| Why build it, for whom, what outcome | `definitions/prd.md` |
| What each feature does, in every state | **this file** |
| How the app is arranged and how it looks | `definitions/surfaces.md` (`pick-ui-surfaces`) |
| What the screens actually look like | `definitions/mockup.html` (`/to-mockup`) |
| How it is built | `definitions/spec.md` (`/to-spec`) |

Two error states, two owners: a **feature** state (this field rejects a past date; the queue is empty) is here. A **system** state (404, offline, session expired, rate limited) is `pick-ui-surfaces`.

## Amend mode

If `definitions/frd.md` already exists and this run is a scoped change (not a from-scratch rebuild), run in amend mode per `${SKILL_DIR}/../../docs/amend-mode.md` (`${SKILL_DIR}` = the directory containing this file): read the FRD as baseline, edit only the features the change touches (reconcile any it contradicts), leave every other feature byte-for-byte alone, and update the Amendment header. Then name which downstream artifacts the touched sections implicate — Agent autonomy → `definitions/harness.md`; new surfaces → `definitions/surfaces.md` and `definitions/mockup.html`; new channels or tools → `definitions/mcp-servers.md` — prompt only those, then `/to-spec`.

## Inputs

- `definitions/prd.md` — required. If it doesn't exist, prompt the user to run `/to-prd` first and stop.
- `definitions/research.md` and `definitions/ideas.md` if they exist — evidence behind a requirement.
- The codebase, if a project already exists.

## Process

1. **Derive the feature inventory from the PRD's Key User Journeys.** Every CUJ decomposes into the features it needs; every feature traces back to at least one CUJ. A feature with no CUJ is either scope creep or a missing journey — surface it, don't silently keep it. A CUJ with no feature is an unmet promise.

2. **Set each feature's change tier** (see `${SKILL_DIR}/../../docs/amend-mode.md`). On a greenfield FRD everything is `feature`; on an amend, tier each touched row so `/to-issues` knows what needs a full slice and what is a one-line fix.

3. **Write the product-wide tables first, then one section per feature.** The product-wide tables hold what cuts across features (entities, channels, autonomy, queues, notifications, integrations); the per-feature sections hold what belongs to exactly one. If a rule appears in two features, it is product-wide — hoist it, don't restate it.

4. **Every requirement carries an owner and a failure.** An owner you could trace it to — a person, a research finding, a judgment — and a failure you can name if it is dropped. "Best practice" and "the model suggested it" are departments, not owners. Rows without an answer go to the PRD's Out of Scope, not here. (`/clean-house` re-asks both questions of every surviving row between versions.)

5. **Write acceptance criteria as Given / When / Then.** These are the FRD's most valuable output: `/to-issues` copies them into issue acceptance criteria and `test-driven-dev` turns them into the red test. A criterion that can't be observed from outside the system is a design note, not a criterion — move it or cut it. Cover the happy path, the rules that reject, and the edges that surprised you.

6. Save as `definitions/frd.md` (create `definitions/` if missing). Commit it.

7. **Length and density.** As long as the product surface needs — this is the artifact that scales, and the PRD stays short precisely so this one can be complete. Tables wherever they carry the meaning; prose only when they can't. Every sentence must carry information.

8. **Style.** This is the technical tier — vendor names, SDK names, protocol mechanics, regulatory rules belong here, packed into cells rather than prose. One layer of detail per sentence. Name surfaces with the same product nouns the PRD bolded; never mint a synonym for something the PRD already named.

9. Present the saved FRD and ask the user to review. Then prompt the next step in this order:
   - If the product has persistent UI surfaces, prompt them to run `pick-ui-surfaces`.
   - If the project involves a custom LLM/agent harness, prompt them to run `pick-harness-shape` (after `pick-ui-surfaces`, if both apply).
   - If the product has UI and `definitions/surfaces.md` now exists, prompt them to run `/to-mockup` — it renders these features' states as screens before any product code exists.
   - Otherwise, prompt them to run `/to-spec`.

<frd-template>

## Source PRD

`definitions/prd.md` — the PRD these requirements expand. Name the CUJs covered.

## Feature inventory

Every feature, and the journey it serves. A reader should be able to skim this table and know the whole product surface.

| # | Feature | Serves CUJ | Surface(s) | Tier | Status |
|---|---|---|---|---|---|

Tier: `feature` (user-visible, full slice) · `internal` (no user-visible surface) · `fix`. Status: `planned` · `built` · `cut`.

## Data model

The entities the user touches and what they hold. Implementation-level schema — indexes, constraints, migrations — goes to `/to-spec`.

| Entity | Key fields | Relationships | Lifecycle (created by / deleted by) |
|---|---|---|---|

## External channels & touchpoints

Every place the product receives input or emits output to the outside world: SMS, email, voice, API endpoints, push notifications, webhooks. Internal app surfaces — nav, panes, screens — are `pick-ui-surfaces`.

| Channel | Inbound behaviour | Outbound behaviour | Rate / quota | Notes |
|---|---|---|---|---|

## Agent autonomy matrix

*(If AI is involved.)* For every action the agent can take: default behaviour, confidence gate, the trigger that hands it to a human. Anything that touches the user externally or commits resources defaults to human-in-the-loop until explicitly justified. This table is the cascade edge into `definitions/harness.md` — changing it implicates the harness.

| Action | Default | Confidence gate | Hands to human when | Irreversible? |
|---|---|---|---|---|

## Queues & approval flows

*(If the product holds work for human review.)* What each queue holds and how an item moves through it. Where it is seen — badge counts, drawer vs. full page — is `pick-ui-surfaces`.

| Queue | Holds | Enters when | Leaves when | Expiry / escalation |
|---|---|---|---|---|

## Notifications & digests

*(If users get pushed updates.)* Modes available, the default, and what overrides it. The in-app inbox itself — bell icon, read/unread — is `pick-ui-surfaces`.

| Mode | Default? | Behaviour | Override |
|---|---|---|---|

## Integrations & migration

Third parties the product reads from or writes to, and how users bring existing data in. Where in the app it surfaces is `pick-ui-surfaces`; which vendor and why is a `docs/adr/` record via `/pick-cloud-services`.

| Integration | Direction | Behaviour | Auth | Failure behaviour |
|---|---|---|---|---|

## Permissions

*(If more than one kind of user exists.)* Who can do what. One row per role; one column per capability class.

| Role | Can read | Can write | Can approve | Can administer |
|---|---|---|---|---|

## Features

One `###` section per feature in the inventory, in inventory order.

<feature-section>

### F1 — <Feature name>

**What it does.** Two sentences. The behaviour a user would describe.

**Serves.** CUJ 1, CUJ 3. **Surfaces.** **Convos**, **To-Approve**.

**Inputs → outputs**

| Input | Source | Output | Goes to |
|---|---|---|---|

**States**

Every state this feature can be in, and what moves it. Include the states people forget: empty, loading, partial, stale, over-limit. Each one is a screen `/to-mockup` must render.

| State | Entered when | What the user sees | Leaves when |
|---|---|---|---|

**Rules**

The logic that decides. Validation, thresholds, precedence, timing. One row per rule, each stated so a test could check it.

| Rule | Behaviour when satisfied | Behaviour when violated | Owner (who wants this) |
|---|---|---|---|

**Edge cases**

The cases that would otherwise be discovered in production. Concurrent edits, empty sets, the maximum, the duplicate, the retry, the timezone.

| Case | Expected behaviour |
|---|---|

**Acceptance criteria**

Testable from outside the system. `/to-issues` copies these into the issue; `test-driven-dev` turns them into the red test.

- [ ] **Given** <state> **when** <action> **then** <observable outcome>.
- [ ] …

</feature-section>

## Open questions

Requirements that could not be settled with current information, each naming who or what would settle it. Anything load-bearing enough to change the product belongs in the PRD's Risks table instead.

| Question | Blocks which feature | What would settle it |
|---|---|---|

</frd-template>
