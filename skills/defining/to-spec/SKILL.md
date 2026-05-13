---
name: to-spec
description: Turn the current conversation, the most recent PRD, and (if it ran) pick-harness-shape's decisions into an implementation SPEC. Save it as a versioned local file in specs/. Use when the user wants to lock down the implementation contract beyond what /to-prd captured (modules, data model, API surface, agent harness specifics).
disable-model-invocation: true
---

Synthesize the conversation, the most recent PRD, and (if it ran) pick-harness-shape's decisions into a SPEC. Do NOT re-interview — work from prior decisions.

The SPEC owns *how*: modules, schema, API contracts, test plan, rollout, observability, security. The PRD owns *what and why* — don't duplicate it here.

## Process

1. Read the most recent PRD: `ls prds/[0-9]*.md | sort | tail -1`. If none exists, prompt the user to run `/to-prd` first and stop.

2. If `pick-harness-shape` ran, restate the picked shape (substrate, topology, memory, tool layer, gates) at the top of the SPEC.

3. Sketch modules and integration points. Look for opportunities to extract deep modules — small interface, deep implementation — that can be tested in isolation.

4. Confirm with the user which modules need tests; capture them in the Test plan section.

5. Write the SPEC using the template below, including only the sections that apply (see the matrix). Save as `specs/YYYY-MM-DD-HH-mm-SS.md` (current local time; create `specs/` if missing). Commit it.

6. Length and density: ≤ 5 pages. Tables wherever possible. Every sentence must carry information.

7. Present the saved SPEC and wait for the user's approval before they run `/to-issues`.

## Section applicability

| Section | Web/CRUD | LLM pipeline | Custom agent | Multi-agent | Computer use |
|---|:---:|:---:|:---:|:---:|:---:|
| Harness shape (from pick-harness-shape) | | | ✓ | ✓ | ✓ |
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

Substrate, topology, memory, tool layer, gate strategy. One paragraph max. Cite which named patterns from `docs/agentic-patterns/` were chosen.

## Modules & interfaces

For each module: name, responsibility, interface (inputs / outputs), depth (deep vs shallow). Look for opportunities to extract deep modules that can be tested in isolation.

## Data model / schema

Tables, fields, constraints, relationships. Include only fields that change behavior — skip filler.

## API contracts

For each endpoint or method boundary: signature, contract (preconditions, postconditions), error modes.

## Pipeline DAG

Nodes + edges. For each node: input, output, LLM-or-not, retry policy, idempotency.

## Tool layer / ACI

For each tool: name, MCP / custom, the shape the *agent* sees (not the human), idempotency, permission scope. Five well-designed tools beat fifty.

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

## Test plan

Which modules are tested and at what seam (unit / integration / e2e). Prior art — similar tests already in the codebase. Test types per module. Tests verify external behavior, not implementation details.

| Module | Seam | Type | Prior art |
|---|---|---|---|

## Eval / test signal

How correctness is verified at the system level. Per-task pass/fail. Trajectory metrics where applicable: length, cost, gate-hit rate. Where the signal runs (CI / nightly / in-loop).

## External dependencies

| Dependency | Purpose | Failure mode if down | Mitigation |
|---|---|---|---|

Includes third-party APIs, hosted models, MCP servers, payment processors. Anything outside our control.

## Rollout / migration

How the change reaches production safely. For schema changes: forward/backward compatibility, backfill plan, locking behavior, staged rollout. For new features: feature flag, canary cohort, kill switch.

## Observability

Logs (what gets logged, at what level), metrics (counters, latencies), traces (spans). Dashboards or alerts that need to exist before launch. Never log credentials, PII, or auth headers.

## Security / authn / authz

Who can do what. Authentication mechanism. Authorization checks at boundaries. Secrets handling. Threat surface introduced by this change.

## GUI / DOM contract

Selectors or anchor strategy. CAPTCHA / login handling. Drift-detection plan — the DOM will change.

For frontend implementation, `ui-taste` will fire automatically and apply the visual rules. No need to restate them here — flag any project-specific overrides only.

## Out of scope

Patterns explicitly rejected and why. Prevents future re-suggestion.

</spec-template>
