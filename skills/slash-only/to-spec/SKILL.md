---
name: to-spec
description: Turn the current conversation, the most recent PRD, and (if it ran) pick-harness-shape's decisions into an implementation SPEC. Save it as a versioned local file in specs/. Use when the user wants to lock down the implementation contract beyond what /to-prd captured (modules, data model, API surface, agent harness specifics).
disable-model-invocation: true
---

Synthesize the conversation, the most recent PRD, and (if it ran) pick-harness-shape's decisions into a SPEC. Do NOT re-interview — work from prior decisions.

## Process

1. Read the most recent PRD: `ls prds/[0-9]*.md | sort | tail -1`. If no PRD exists, prompt the user to run `/to-prd` first and stop.

2. If pick-harness-shape ran, restate the picked shape (substrate, topology, memory, tool layer, gates) at the top of the SPEC.

3. Sketch modules and integration points. Look for opportunities to extract deep modules — small interface, deep implementation — that can be tested in isolation.

4. Confirm with the user which modules need tests.

5. Write the SPEC using the template below, including only the sections that apply (see the matrix). Save it as `specs/YYYY-MM-DD-HH-mm-SS.md` (current local time; create `specs/` if it doesn't exist) and commit it.

Length and density: ≤ 5 pages. Tables wherever possible. Every sentence must carry information.

6. Present the saved SPEC and wait for the user's approval before they run `/to-issues`.

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
| Eval / test signal | ✓ | ✓ | ✓ | ✓ | ✓ |
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

## Eval / test signal

How correctness is verified. Per-task pass/fail. Trajectory metrics where applicable: length, cost, gate-hit rate. Where the signal runs (CI / nightly / in-loop).

## GUI / DOM contract

Selectors or anchor strategy. CAPTCHA / login handling. Drift-detection plan — the DOM will change.

## Out of scope

Patterns explicitly rejected and why. Prevents future re-suggestion.

</spec-template>
