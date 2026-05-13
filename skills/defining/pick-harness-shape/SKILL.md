---
name: pick-harness-shape
description: Pick the harness shape for a custom LLM/agent system. Invoked by define when the project smells like a custom harness. Walks substrate, loop topology, memory, tool layer, and gate strategy — picking a custom harness when it's genuinely useful, an off-the-shelf one otherwise. Use when the user is designing an agentic system that doesn't fit a single LLM call or a deterministic pipeline.
---

You are picking the harness shape for a custom LLM/agent system. The harness is the runtime stack around the LLM: tool dispatch, scheduling, memory, verification gates. Harness changes alone can swing benchmark scores 6× on the same model — these decisions are load-bearing.

Reference: `docs/agentic-patterns/` carries the empirical foundation. Cite the named pattern and its evidence as you make recommendations. Pull the relevant brief for each section below.

Ask one question at a time. Surface your recommended answer with each.

## 1. Custom vs. off-the-shelf

Pick a custom harness when it's genuinely useful — otherwise an off-the-shelf coding agent (Claude Code, Cursor, Codex, Cline) does the job with less cost and less to maintain.

Cases where custom is genuinely useful:

- Regulated industry (financial, healthcare, government) requiring on-prem or audit
- Sensitive code paths needing custom routing (local model for sensitive files, frontier model for the rest)
- Non-coding agent work (support, ops, research, drafting) where coding agents don't apply
- Multi-agent workflow with independent lifecycles or trust boundaries — not just "multiple things happen"

If none of these apply, surface that an off-the-shelf coding agent likely fits and let the user decide before going deeper. If they confirm custom is wanted, continue.

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

## 7. Per-stage sampling & model choice

Harness behavior depends as much on per-stage parameters as on topology. Provider defaults (often `T=1.0`, latest frontier model, no reasoning budget) are rarely optimal — planner and verifier stages in particular benefit from explicit, lower-variance settings.

For each stage in the topology picked in section 3, decide:

- **Model tier** — frontier / mid / cheap
- **Temperature** (and/or top-p)
- **Reasoning effort** — if the model exposes it (Claude extended thinking, GPT-5 reasoning levels)
- **Max tokens per step** — implicit bound on how much an executor can do per turn

Sensible defaults by stage type:

| Stage type | Temperature | Model tier | Why |
|---|---|---|---|
| Planner / decomposer | 0.0–0.2 | Frontier | Stable decomposition; one good plan beats N drifty ones |
| Executor / tool caller | 0.0–0.2 | Mid–frontier | Deterministic tool dispatch; schema adherence collapses at high T |
| Generator (code, prose) | 0.3–0.7 | Frontier | Some variance is the point; too low produces stilted output |
| Self-consistency sampler | 0.7–1.0 | Mid | High T *is* the mechanism — without it you get N copies of the same answer |
| Verifier-LM | 0.0–0.2 | Mid (cheaper than the agent it verifies) | Consistent judgments; the verifier shouldn't be a flaky test |
| Brainstormer / ideator | 0.7–1.0 | Frontier | Variance is wanted |

Reasoning effort: bump for planner and verifier stages; default off for executor (latency cost rarely pays back on tool calls). Max tokens: tighter caps force more loop iterations and finer-grained recovery — useful when verification gates are strong, harmful when they're weak.

Cost compounds: a planner running frontier+high-reasoning at every turn is the single fastest way to a surprise bill. Pick the tier per stage, not per harness. (See `docs/agentic-patterns/04_prompt_management_brief.md` for self-consistency sampling cost.)

## Hand-off

Summarise the picked shape: substrate, topology, memory model, rough tool layer, gate strategy, and per-stage model + sampling choices. Then prompt the user to run `/to-prd` (if not yet done) and `/to-spec` to document the decisions.
