---
name: pick-harness-shape
description: Pick the harness shape for a custom LLM/agent system. Invoked by grill-me when the project smells like a custom harness. Opens with an off-the-shelf gate (use Claude Code / Cursor / etc. instead, where possible), then walks substrate, loop topology, memory, tool layer, and gate strategy. Use when the user is designing an agentic system that doesn't fit a single LLM call, a deterministic pipeline, or off-the-shelf coding agents.
---

You are picking the harness shape for a custom LLM/agent system. The harness is the runtime stack around the LLM: tool dispatch, scheduling, memory, verification gates. Harness changes alone can swing benchmark scores 6× on the same model — these decisions are load-bearing.

Reference: `docs/agentic-patterns/` carries the empirical foundation. Cite the named pattern and its evidence as you make recommendations. Pull the relevant brief for each section below.

Ask one question at a time. Surface your recommended answer with each.

## 1. Off-the-shelf gate

Off-the-shelf wins for repo-coding work: Claude Code, Cursor, Codex, Cline. The startup that ships features daily uses Claude Code, doesn't fork it. Building a custom coding harness in-house is the most expensive failure mode in agent projects.

Confirm the user has a load-bearing reason for custom:

- Regulated industry (financial, healthcare, government) requiring on-prem or audit
- Sensitive code paths needing custom routing (local model for sensitive files, frontier model for the rest)
- Non-coding agent work (support, ops, research, drafting) where coding agents don't apply
- Multi-agent workflow you can already justify with independent lifecycles or trust boundaries — not just "multiple things happen"

If none apply, push back: prompt the user to use Claude Code / Cursor / Cline and stop.

## 2. Substrate

| Substrate | Best for |
|---|---|
| Claude Agent SDK | Anthropic-first; deepest tool integration |
| OpenAI Agents SDK | OpenAI-first; Responses API |
| Google ADK | Google Cloud / Gemini-first; strong eval integration |
| smolagents | Lightweight, hackable; research-grade |
| Fork existing harness (pi.dev, OpenClaw) | Cross-provider routing; on-prem; multi-tenant |

Default to the SDK matching the provider already in use. Forking is for genuinely cross-provider or regulated cases. (See `docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 3. Loop topology

| Topology | Use when |
|---|---|
| Single ReAct loop with tools | Default. Coordination overhead of multi-agent rarely earns its cost. |
| Planner / Executor split | Tasks >20 steps; multi-file edits; research with sub-tasks |
| Planner + Executor + Supervisor (Reason-Plan-ReAct) | Enterprise tasks needing both deliberation and reactive action |
| Multi-agent (orchestrator / hub-and-spoke) | Workflow obviously decomposes into specialists with non-overlapping responsibilities AND distinct lifecycles or trust boundaries |
| Multi-agent (peer-to-peer / A2A) | Cross-org agents in separate runtimes |

Hard pushback on multi-agent: a single agent with multiple tools handles "multiple things" without coordination overhead. Demand a real decomposition reason — independent lifecycles, trust boundaries, or parallelism gain >2×. (See `docs/agentic-patterns/05_harness_architectures_brief.md` and `02_role_design_brief.md`.)

## 4. Memory & state

- **None** — single-shot, stateless tools. Skip section.
- **Long context only** — ≤ ~50K active tokens. Watch for "lost in the middle" and memory inflation.
- **Memory-as-action** — agent decides what to store/retrieve via tool calls. Dominant pattern in 2026 papers.
- **Hierarchical / virtual context** (MemGPT-style) — survives unbounded sessions.
- **Episodic + semantic + procedural split** — only when more than one type is genuinely needed.

Compaction policy: when does context get summarized vs. truncated? Pick one and document it. (See `docs/agentic-patterns/03_context_management_brief.md`.)

## 5. Tool layer / ACI

Five well-designed tools beat fifty. Decide:

- Rough tool count and boundaries
- MCP server vs. custom
- For each tool: what shape does the *agent* see (not the human)?
- Permission scope per tool
- Idempotency

ACI (Agent–Computer Interface) quality dominates raw model capability for coding agents. (See `docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 6. Verification gates

For each gate:

- Format and schema
- Hard or soft?
- Verifier-LM (cheaper model) or rule-based?
- The failure mode it prevents

Hard gates stall on legitimate variation; soft gates miss errors. Pick one and instrument it. (See `docs/agentic-patterns/05_harness_architectures_brief.md`.)

## Hand-off

Summarise the picked shape: substrate, topology, memory model, rough tool layer, gate strategy. Then prompt the user to run `/to-prd` (if not yet done) and `/to-spec` to document the decisions.
