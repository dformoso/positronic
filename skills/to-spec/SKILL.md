---
name: to-spec
description: Turn the definitions/ artifacts — prd.md and journeys.md, plus mockups.md, harness.md, mcp-servers.md, runtime.md and infrastructure.md where they exist — into an implementation SPEC. Save it as definitions/spec.md. Use when the user wants to lock down the implementation contract beyond what /to-prd captured (modules, data model, API surface, harness specifics, product surfaces, verification fidelity, rollout, observability). User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

Synthesize the upstream definitions into a SPEC. Do NOT re-interview — work from prior decisions.

The SPEC owns *how*: modules, schema, API contracts, test plan, rollout, observability, security. The PRD owns *why and for whom*, the journeys artifact owns *what the user does and how you prove it worked*, and the mockups own *what the screens look like* — don't duplicate any of them here. Where the SPEC needs one of their facts, restate the minimum and point at the source.

## Amend mode

If `definitions/spec.md` exists and an upstream artifact was amended — or this is otherwise a scoped change rather than a rebuild — follow `${SKILL_DIR}/../../docs/amend-mode.md` (`${SKILL_DIR}` = the directory containing this file): edit only the sections the change touches, reconcile anything the upstream change contradicts, leave every other section byte-for-byte alone, update the Amendment header. Then prompt `/to-issues` for the new or changed slices only.

## Process

1. **Read the upstream artifacts.** Each one that exists is a *baseline*, not a suggestion: the SPEC **restates** its picks and never re-derives them, and never contradicts one silently. If the SPEC has to deviate, surface the conflict to the user before writing.

| Artifact | What the SPEC does with it | If it's missing |
|---|---|---|
| `definitions/prd.md` | The *what & why* every section below serves | Stop — prompt `/to-prd` |
| `definitions/journeys.md` | The primary *what* this turns into *how*. Modules carry every journey and every reference row, with nothing left over and nothing invented; each journey's **end-state proof** becomes the Test plan's end-to-end row | Stop and prompt `/to-journeys` on a `feature`- or `launch`-tier change (the PRD's Change tier field). A `fix`- or `internal`-tier change proceeds without one |
| `definitions/mockups.md` | Its picks — visual identity, nav, account, onboarding, settings, integration placement, error states, compliance — become **Product surfaces**, and Modules reflect them. Its agreed panel inventory is the UI contract: every panel is a state some slice renders, and the Test plan names how each is checked. Don't restate the panels; point at the file and let `/to-issues` carry the panel ids into acceptance criteria | Stop and prompt `/to-mockups` if the product has persistent UI surfaces |
| `definitions/harness.md` | Its picks — substrate, topology, memory, tool layer, gates, per-stage sampling — become **Harness shape** | Stop and prompt `pick-harness-shape` if the section matrix below marks one needed (custom agent / multi-agent / computer use) |
| `definitions/mcp-servers.md` | One `##` section per server; read every one. Each adds a paragraph to **Tool layer / ACI** restating its picks — transport, auth, tool naming + schema discipline, return-shape policy, state model, testing strategy — plus a pointer to that section | Stop and prompt `design-mcp-server` if the SPEC describes an MCP server |
| `definitions/runtime.md` | The placement profile folds into existing sections: residency exceptions into Security, telemetry backend into Observability, cost envelope + kill switch into Rollout | Proceed |
| `definitions/infrastructure.md` | Holds every service-level vendor pick. Name the capability and point at the section; never restate the vendor rationale | Proceed |

2. Sketch modules and integration points. Assign each module the design decision it hides — if two modules must agree on a format or assumption, that's leakage; pick one owner. Look for opportunities to extract deep modules — small interface, deep implementation — that can be tested in isolation, and state per interface which error modes are defined out of existence (semantics that make the special case a non-event) versus surfaced.

3. Confirm with the user which modules need tests; capture them in the Test plan section.

4. Pick the **verification fidelity** — how real development and verification are along five axes: data, external access, eval signal, CUJ verification, deploy. Show the rungs as a table, recommend one per axis, let the user override per dependency.

   Default: build and test against the lowest *faithful* stand-in — fixtures plus mock or sandbox adapters at the external seams — so AFK slices run unattended. Then schedule an explicit crossover before the release gate; a slice may not claim done on a mock when its journey needs the real thing.

   Settle the crossover shape too: per-slice (true tracer bullet, real deps from the start, credentials needed early), phased (mock through MVP, dedicated crossover slices before launch), or hybrid per-axis (recommended). Picks go in the Verification fidelity section; the per-dependency rung goes in the External dependencies column.

5. Write the SPEC using the template below, including only the sections that apply (see the matrix). Save as `definitions/spec.md` (create `definitions/` if missing). Commit it.

6. Length and density: As long as you need. Tables wherever ideal. Every sentence must carry information, in plain English — short sentences, one idea each, concrete before abstract, every term of art glossed on first use (AGENTS.md §4).

7. Present the saved SPEC and wait for the user's approval before they run `/to-issues`. (If the SPEC adds load-bearing decisions worth stress-testing, mention `/judge-idea` can run adversarially on it first — optional.)

## Section applicability

| Section | Web/CRUD | LLM pipeline | Custom agent | Multi-agent | Computer use |
|---|:---:|:---:|:---:|:---:|:---:|
| Harness shape (from pick-harness-shape) | | | ✓ | ✓ | ✓ |
| Product surfaces (from /to-mockups — UI products only) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Modules & interfaces | ✓ | ✓ | ✓ | ✓ | ✓ |
| Data model / schema | ✓ | ✓ | ✓ | ✓ | ✓ |
| API contracts | ✓ | ✓ | ✓ | ✓ | ✓ |
| Pipeline DAG | | ✓ | | | |
| Tool layer / ACI | | | ✓ | ✓ | ✓ |
| Memory & state | | | ✓ | ✓ | ✓ |
| Roles / contracts | | | ✓ (one) | ✓ | ✓ |
| Coordination protocol | | | | ✓ | |
| Verification gates | | ✓ | ✓ | ✓ | ✓ |
| Failure taxonomy | ✓ | ✓ | ✓ | ✓ | ✓ |
| Verification fidelity | ✓ | ✓ | ✓ | ✓ | ✓ |
| Test plan | ✓ | ✓ | ✓ | ✓ | ✓ |
| Eval / test signal | ✓ | ✓ | ✓ | ✓ | ✓ |
| External dependencies | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rollout / migration | ✓ | ✓ | ✓ | ✓ | ✓ |
| Observability | ✓ | ✓ | ✓ | ✓ | ✓ |
| Security / authn / authz | ✓ | ✓ | ✓ | ✓ | ✓ |
| GUI / DOM contract | | | | | ✓ |
| Out of scope | ✓ | ✓ | ✓ | ✓ | ✓ |

<spec-template>

## Harness shape

Restate the picks from `definitions/harness.md` — substrate, topology, memory, tool layer, gate strategy, per-stage sampling. One paragraph max plus a pointer (`See definitions/harness.md`) so the full rationale and rejected alternatives are one click away. Cite which named patterns from `${SKILL_DIR}/../../docs/agentic-patterns/` were chosen.

## Product surfaces

Restate the picks from `definitions/mockups.md` — nav, account lifecycle, onboarding, settings, integration placement, error/system states, compliance touchpoints — plus a pointer to its **Panel inventory**, which is the UI contract each slice satisfies. One paragraph plus a pointer (`See definitions/mockups.md`) so the full rationale and rejected alternatives stay one click away. The Modules section below should reflect these surfaces (e.g., `onboarding/`, `settings/`) rather than scattering the logic.

Restate the **visual identity** inline as a table (register, who, feel, signature, accent + ramp, neutrals, spacing base, fonts, depth/motion) — not just a pointer. The implementing agent reads this SPEC, not the mockups artifact, so the locked values must live here for every UI issue to inherit one identity; `ui-taste` reads them at build time and applies them.

## Modules & interfaces

For each module: name, responsibility, what it hides (the design decision that lives only here), interface (inputs / outputs), depth (deep vs shallow). Look for opportunities to extract deep modules that can be tested in isolation.

**Anti-pattern: one module per data type or REST resource.** `users/`, `orders/`, `products/` is a shallow-module trap — each becomes a CRUD passthrough with no real behavior, and every workflow has to coordinate across all of them. Group by domain function instead (`checkout/`, `billing/`, `reconciliation/`) — each owns multiple data types internally and exposes a small interface that does meaningful work. If a module's name is a noun lifted from your schema, suspect it.

## Data model / schema

Tables, fields, constraints, relationships. Include only fields that change behavior — skip filler.

## API contracts

For each endpoint or method boundary: signature, contract (preconditions, postconditions), error modes.

## Pipeline DAG

Nodes + edges. For each node: input, output, LLM-or-not, retry policy, idempotency.

## Tool layer / ACI

For each tool: name, MCP / custom, the shape the *agent* sees (not the human), idempotency, permission scope. Five well-designed tools beat fifty.

If `definitions/mcp-servers.md` exists, add one paragraph per server restating its picks plus a pointer (`See definitions/mcp-servers.md § <server-slug>`) so the full rationale and rejected alternatives stay one click away. Multi-server projects keep one section per server — restate each.

If the SPEC is for an MCP **server** (you're producing tools other agents consume), the per-tool public contract — name, description, schemas, return shape, annotations, failure mode — is locked by `design-mcp-server` and recorded in `definitions/mcp-servers.md`. Restate the picks, don't re-derive the rules; the rules themselves live in `${SKILL_DIR}/../../docs/agentic-patterns/06_mcp_design_brief.md`. If the server hasn't been designed yet, invoke `design-mcp-server` first.

## Memory & state

What persists across calls. Compaction policy. Episodic / semantic / procedural split (only if more than one is needed).

## Roles / contracts

For each role: contract — inputs, outputs, allowed tools, stop conditions. Not personas. "You are an expert" is not a contract.

## Coordination protocol

Orchestrator / hub-and-spoke vs. A2A. Message format. Routing rules. Trust boundaries. Failure isolation.

## Verification gates

For each gate: format, schema, test, verifier-LM or rule-based, hard or soft. State the failure mode being optimised for.

## Failure taxonomy

| Error mode | Detection | Recovery action | Retry budget |
|---|---|---|---|

## Verification fidelity

How real development and verification are, per axis — the rung each is built and checked against, and where it crosses dummy → real. Test plan, Eval / test signal, External dependencies, and Rollout below implement these picks; `/to-issues` reads this section to set per-slice acceptance criteria and decide which crossovers become their own slices.

| Axis | Rung (dummy → real) | Crossover trigger |
|---|---|---|
| Data | fixtures (hand- or Gemini-generated) / anonymized sample / prod data | |
| External access | mock adapter / sandbox key / live creds | |
| Eval signal | smoke asserts / held-out synthetic set / curated dataset + graded metric | |
| CUJ verification | unit-integration / scripted e2e on mocks / driven on real deps | |
| Deploy | local / staging / prod (flagged) | |

A slice may not claim done on a mock when its PRD CUJ needs the real thing. Generated fixtures (`test-driven-dev`'s [test-assets.md](../test-driven-dev/test-assets.md)) raise the Data axis only — never the CUJ axis; a user-dependent journey stays human-verified. List crossovers that are their own unit of work — build eval set, swap `<dep>` mock→live, deploy to staging, drive `<CUJ>` end-to-end — so `/to-issues` makes each a slice (often HITL, often the shape-establishing anchor others mirror).

## Test plan

Which modules are tested and at what seam (unit / integration / e2e). Prior art — similar tests already in the codebase. Test types per module. Tests verify external behavior, not implementation details.

| Module | Seam | Type | Prior art |
|---|---|---|---|

## Eval / test signal

How correctness is verified at the system level. Per-task pass/fail. Trajectory metrics where applicable: length, cost, gate-hit rate. Where the signal runs (CI / nightly / in-loop). See `${SKILL_DIR}/../../docs/agentic-patterns/07_eval_observability_brief.md` for eval dimensions (tool-path, groundedness, hallucination) and the offline → online progression.

Close the section with a **residual blind spots** list: the ways this verification can still show a wrong green (detection limits on rare failures, curated-corpus bias, mock-vs-reality gaps), each priced-in rather than forgotten — a gate that can't name how it lies gets trusted past its warranty.

## External dependencies

| Dependency | Purpose | Dev/test fidelity | Failure mode if down | Mitigation |
|---|---|---|---|---|

Includes third-party APIs, hosted models, MCP servers, payment processors. Anything outside our control. The Dev/test fidelity column records how each is stood up while building — mock adapter, sandbox / test-mode key, or live creds (see Verification fidelity).

For any dependency whose setup involves an external clock — quota approvals, identity/carrier verification, certificate provisioning, review queues — note the **earliest-confirmable date**: these uncompressible waits dominate real cutover calendars, and naming them keeps the schedule honest.

## Rollout / migration

How the change reaches production safely. For reversible changes a paragraph suffices: feature flag, canary cohort, kill switch. Anything **one-way** — a provider re-point, a datastore migration, first production traffic — needs a stepped cutover runbook written per [rollout.md](rollout.md). That means per-step Verify and Rollback clauses, one-way doors marked and placed late, thin-slice-first phasing, a risk register where every risk names the phase that closes it, and a scripted exit gate per step — the evidence `/go-live` later verifies.

For schema changes, state the expand/contract contract — destructive changes (drops, renames) land only once no shipped release reads the old shape — and name its enforcement gate (boot the previous release against the migrated store) in the Test plan.

**Environments.** The ladder from a dev machine to production is recorded in four places, each owning one part; cite them here rather than restating any of them. [rollout.md §7](rollout.md#7-environments) has the map.

## Observability

Write this section per [observability.md](observability.md) — it carries the four tables (telemetry set, service level objectives, alert routing, and the PRD-metric instrumentation that `/readout` later reads) and the rules for filling them.

This section is the **plan-of-record for what telemetry exists**. `pick-harness-shape` §9 owns only the posture, `design-mcp-server` §9 only server-internal logs, and any placement profile (`definitions/runtime.md`) only where the telemetry backend lives — none of them redefines the telemetry set; they point here.

| Table | Answers |
|---|---|
| Telemetry set | What gets logged, counted, and traced — and at what level |
| Service level objectives | What "working" means as a number, and the error budget that follows |
| Alerts | Which threshold pages a human, where it goes, and what they do first |
| Product metrics | For each PRD metric and kill criterion: the signal that measures it, and where `/readout` reads it |

The last table is the one that is always missing. A PRD metric with no instrumentation row can never be checked, so the kill criterion attached to it can never fire — which means the product cannot fail, which means nothing is learned from shipping it. Never log credentials, PII, or auth headers.

## Security / authn / authz

Who can do what. Authentication mechanism. Authorization checks at boundaries. Secrets handling. Threat surface introduced by this change.

## GUI / DOM contract

Selectors or anchor strategy. CAPTCHA / login handling. Drift-detection plan — the DOM will change.

For frontend implementation, `test-driven-dev` invokes `ui-taste`, which reads the locked visual identity (from the Product surfaces section above) and applies the visual rules. No need to restate the rules here — flag any project-specific overrides only.

## Out of scope

Patterns explicitly rejected and why. Prevents future re-suggestion.

</spec-template>
