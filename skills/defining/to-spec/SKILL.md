---
name: to-spec
description: Turn the most recent PRD and (if present) the most recent harness/ and surfaces/ artifacts into an implementation SPEC. Save it as a versioned local file in specs/. Use when the user wants to lock down the implementation contract beyond what /to-prd captured (modules, data model, API surface, agent harness specifics, product surfaces).
disable-model-invocation: true
---

Synthesize the most recent PRD and (if present) the most recent `harness/` and `surfaces/` artifacts into a SPEC. Do NOT re-interview — work from prior decisions.

The SPEC owns *how*: modules, schema, API contracts, test plan, rollout, observability, security. The PRD owns *what and why* — don't duplicate it here.

## Amend mode

If a prior `specs/[0-9]*.md` exists and an upstream artifact was amended (or this run is otherwise a scoped change, not a from-scratch rebuild), run in amend mode per `${CLAUDE_SKILL_DIR}/../../../docs/amend-mode.md`: read the latest SPEC as baseline, carry forward every untouched section *verbatim* (reconcile any the upstream change contradicts), apply the delta, and write a new complete snapshot with an Amendment header. Then prompt `/to-issues` for the new or changed slices only.

## Process

1. Read the most recent PRD: `ls prds/[0-9]*.md | sort | tail -1`. If none exists, prompt the user to run `/to-prd` first and stop.

2. Read the most recent harness artifact: `ls harness/[0-9]*.md | sort | tail -1`. If one exists, the SPEC's "Harness shape" section restates its picks (substrate, topology, memory, tool layer, gates, per-stage sampling) — do not re-derive them, and do not contradict them silently. If the SPEC needs to deviate, surface the conflict to the user before writing. If no harness artifact exists and the section matrix below indicates one is needed (custom agent / multi-agent / computer use), stop and prompt the user to run `pick-harness-shape` first.

3. Read the most recent surfaces artifact: `ls surfaces/[0-9]*.md | sort | tail -1`. If one exists, the SPEC's "Product surfaces" section restates its picks (visual identity, nav, account, onboarding, settings, integration placement, error states, compliance) and the SPEC's Modules section should reflect them — do not re-derive, and do not contradict silently. If the SPEC needs to deviate, surface the conflict before writing. If the product has persistent UI surfaces and no surfaces artifact exists, stop and prompt the user to run `pick-ui-surfaces` first.

4. Read all MCP-server designs (if any): `ls mcp-servers/*.md 2>/dev/null`. Multi-server projects keep one artifact per server (filename `<server-slug>-<ts>.md`); read every file. For each, the SPEC's "Tool layer / ACI" section adds a paragraph restating its picks (transport, auth, tool naming + schema discipline, return-shape policy, state model, testing strategy) plus a pointer to the file — do not re-derive, and do not contradict silently. If the SPEC describes an MCP server but no design artifact exists, stop and prompt the user to run `design-mcp-server` first.

5. Sketch modules and integration points. Look for opportunities to extract deep modules — small interface, deep implementation — that can be tested in isolation.

6. Confirm with the user which modules need tests; capture them in the Test plan section.

7. Pick the **verification fidelity** — how real development and verification are along five axes: data, external access, eval signal, CUJ verification, deploy. Show the rungs as a table, recommend one per axis, and let the user override per dependency. Default: build and unit/integration-test against the lowest *faithful* stand-in (fixtures plus mock or sandbox adapters at the external seams) so AFK slices run unattended, then schedule an explicit crossover before the release gate — a slice may not claim done on a mock when its PRD CUJ needs the real thing. Settle the crossover shape too: per-slice (true tracer bullet, real deps from the start, credentials needed early), phased (mock through MVP, dedicated crossover slices before launch), or hybrid per-axis (recommended). Capture the picks in the Verification fidelity section and the per-dependency rung in the External dependencies column.

8. Write the SPEC using the template below, including only the sections that apply (see the matrix). Save as `specs/YYYY-MM-DD-HH-mm-SS.md` (use `date +"%Y-%m-%d-%H-%M-%S"`; create `specs/` if missing). Commit it.

9. Length and density: As long as you need. Tables wherever ideal. Every sentence must carry information.

10. Present the saved SPEC and wait for the user's approval before they run `/to-issues`. (If the SPEC adds load-bearing decisions worth stress-testing, mention `/judge-idea` can run adversarially on it first — optional.)

## Section applicability

| Section | Web/CRUD | LLM pipeline | Custom agent | Multi-agent | Computer use |
|---|:---:|:---:|:---:|:---:|:---:|
| Harness shape (from pick-harness-shape) | | | ✓ | ✓ | ✓ |
| Product surfaces (from pick-ui-surfaces — UI products only) | ✓ | ✓ | ✓ | ✓ | ✓ |
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

Restate the picks from the most recent `harness/<file>.md` — substrate, topology, memory, tool layer, gate strategy, per-stage sampling. One paragraph max plus a pointer (`See harness/<file>.md`) so the full rationale and rejected alternatives are one click away. Cite which named patterns from `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/` were chosen.

## Product surfaces

Restate the picks from the most recent `surfaces/<file>.md` — nav, account lifecycle, onboarding, settings, integration placement, error/system states, compliance touchpoints. One paragraph plus a pointer (`See surfaces/<file>.md`) so the full rationale and rejected alternatives stay one click away. The Modules section below should reflect these surfaces (e.g., `onboarding/`, `settings/`) rather than scattering the logic.

Restate the **visual identity** inline as a table (who, feel, signature, accent + ramp, neutrals, spacing base, fonts, depth/motion) — not just a pointer. The implementing agent reads this SPEC, not the surfaces artifact, so the locked values must live here for every UI issue to inherit one identity; `ui-taste` reads them at build time and applies them.

## Modules & interfaces

For each module: name, responsibility, interface (inputs / outputs), depth (deep vs shallow). Look for opportunities to extract deep modules that can be tested in isolation.

**Anti-pattern: one module per data type or REST resource.** `users/`, `orders/`, `products/` is a shallow-module trap — each becomes a CRUD passthrough with no real behavior, and every workflow has to coordinate across all of them. Group by domain function instead (`checkout/`, `billing/`, `reconciliation/`) — each owns multiple data types internally and exposes a small interface that does meaningful work. If a module's name is a noun lifted from your schema, suspect it.

## Data model / schema

Tables, fields, constraints, relationships. Include only fields that change behavior — skip filler.

## API contracts

For each endpoint or method boundary: signature, contract (preconditions, postconditions), error modes.

## Pipeline DAG

Nodes + edges. For each node: input, output, LLM-or-not, retry policy, idempotency.

## Tool layer / ACI

For each tool: name, MCP / custom, the shape the *agent* sees (not the human), idempotency, permission scope. Five well-designed tools beat fifty.

If `mcp-servers/<file>.md` artifacts exist, add one paragraph per server restating its picks plus a pointer (`See mcp-servers/<file>.md`) so the full rationale and rejected alternatives stay one click away. Multi-server projects produce multiple files (one per server) — restate each.

If the SPEC is for an MCP **server** (you're producing tools other agents consume), the entry also locks down the public-API contract:

| Field | What to lock down |
|---|---|
| `name` | `[a-z0-9_]+`; verb_noun; never embed the server name (clients namespace as `${server}_${tool}`) |
| `description` | Embedding target — clients pick tools via semantic search. Concrete domain nouns beat generic "use this to..." |
| `inputSchema` | Single-type fields, `description` per property, `enum`/`pattern` where the domain is finite. Avoid `oneOf`/`anyOf` discriminators |
| `outputSchema` | Publish it. Lets agents chain tools |
| Return shape | `structuredContent` *consistently* — always when `outputSchema` is declared, or never |
| `annotations` | All four: `readOnlyHint`, `idempotentHint`, `destructiveHint`, `openWorldHint` |
| Failure mode | `CallToolResult(isError=True, content=[TextContent(...)])`. No throwing |

For the empirical foundation and per-decision tradeoffs, see `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/06_mcp_design_brief.md`. If the server hasn't been designed yet, invoke `design-mcp-server` first.

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

A slice may not claim done on a mock when its PRD CUJ needs the real thing. Generated fixtures (`generate-test-assets`) raise the Data axis only — never the CUJ axis; a user-dependent journey stays human-verified. List crossovers that are their own unit of work — build eval set, swap `<dep>` mock→live, deploy to staging, drive `<CUJ>` end-to-end — so `/to-issues` makes each a slice (often HITL, often the shape-establishing anchor others mirror).

## Test plan

Which modules are tested and at what seam (unit / integration / e2e). Prior art — similar tests already in the codebase. Test types per module. Tests verify external behavior, not implementation details.

| Module | Seam | Type | Prior art |
|---|---|---|---|

## Eval / test signal

How correctness is verified at the system level. Per-task pass/fail. Trajectory metrics where applicable: length, cost, gate-hit rate. Where the signal runs (CI / nightly / in-loop). See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/07_eval_observability_brief.md` for eval dimensions (tool-path, groundedness, hallucination) and the offline → online progression.

## External dependencies

| Dependency | Purpose | Dev/test fidelity | Failure mode if down | Mitigation |
|---|---|---|---|---|

Includes third-party APIs, hosted models, MCP servers, payment processors. Anything outside our control. The Dev/test fidelity column records how each is stood up while building — mock adapter, sandbox / test-mode key, or live creds (see Verification fidelity).

## Rollout / migration

How the change reaches production safely. For schema changes: forward/backward compatibility, backfill plan, locking behavior, staged rollout. For new features: feature flag, canary cohort, kill switch.

## Observability

Logs (what gets logged, at what level), metrics (counters, latencies), traces (spans) — prefer OpenTelemetry GenAI semantic conventions for agent traces (model call, tool call, agent step as spans). Dashboards or alerts that need to exist before launch. Never log credentials, PII, or auth headers. See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/07_eval_observability_brief.md`.

## Security / authn / authz

Who can do what. Authentication mechanism. Authorization checks at boundaries. Secrets handling. Threat surface introduced by this change.

## GUI / DOM contract

Selectors or anchor strategy. CAPTCHA / login handling. Drift-detection plan — the DOM will change.

For frontend implementation, `test-driven-dev` invokes `ui-taste`, which reads the locked visual identity (from the Product surfaces section above) and applies the visual rules. No need to restate the rules here — flag any project-specific overrides only.

## Out of scope

Patterns explicitly rejected and why. Prevents future re-suggestion.

</spec-template>
