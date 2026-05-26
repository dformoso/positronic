---
name: pick-harness-shape
description: Pick the harness shape for a custom LLM/agent system. Invoked by define when the project smells like a custom harness. Walks substrate, loop topology, memory, tool layer, and gate strategy — picking a custom harness when it's genuinely useful, an off-the-shelf one otherwise. Use when the user is designing an agentic system that doesn't fit a single LLM call or a deterministic pipeline.
---

You are picking the harness shape for a custom LLM/agent system. The harness is the runtime stack around the LLM: tool dispatch, scheduling, memory, verification gates. Harness changes alone can swing benchmark scores 6× on the same model — these decisions are load-bearing.

Reference: `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/` carries the empirical foundation. Cite the named pattern and its evidence as you make recommendations. Pull the relevant brief for each section below.

Ask one question at a time. Surface your recommended answer with each.

## 0. Read the PRD

Before any picks, read the most recent PRD: `ls prds/[0-9]*.md | sort | tail -1`. The PRD's user, regulatory, and business constraints (on-prem requirements, sensitive code paths, multi-agent decomposition reasons, trust boundaries) are the inputs that drive sections 1–7 — picking without them is picking blind.

If no PRD exists, stop and prompt the user to run `/to-prd` first. **Exception:** if the harness IS the product or differentiator (case 6 in section 1), the picks may legitimately shape the PRD rather than follow from it. Surface this to the user and let them override before proceeding.

Record the PRD path; it goes into the artifact (section 8).

## 1. Custom vs. off-the-shelf

Lean custom whenever it offers a real advantage. Off-the-shelf coding agents (Claude Code, Cursor, Codex, Cline) are the fallback — pick one only when the work is plain code editing in a familiar stack and none of the cases below apply.

Cases where custom is the right call:

- Tool surface, routing, memory, or verification gates that an off-the-shelf agent can't expose
- Regulated industry (financial, healthcare, government) requiring on-prem or audit
- Sensitive code paths needing custom routing (local model for sensitive files, frontier model for the rest)
- Non-coding agent work (support, ops, research, drafting) where coding agents don't apply
- Multi-agent workflow with independent lifecycles or trust boundaries — not just "multiple things happen"
- Harness behavior is itself the product or differentiator

If any apply, go custom. If none do, surface that off-the-shelf likely fits — but when in doubt, lean custom.

## 2. Substrate

| Substrate | Best for |
|---|---|
| Claude Agent SDK | Anthropic-first; deepest tool integration |
| OpenAI Agents SDK | OpenAI-first; Responses API |
| Google ADK | Google Cloud / Gemini-first; strong eval integration |
| smolagents | Lightweight, hackable; research-grade |
| Fork existing harness (pi.dev, OpenClaw) | Cross-provider routing; on-prem; multi-tenant |

Default to the SDK matching the provider already in use. Forking is for genuinely cross-provider or regulated cases. (See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 3. Loop topology

| Topology | Use when |
|---|---|
| Single ReAct loop with tools | Default. Coordination overhead of multi-agent rarely earns its cost. |
| Planner / Executor split | Tasks >20 steps; multi-file edits; research with sub-tasks |
| Planner + Executor + Supervisor (Reason-Plan-ReAct) | Enterprise tasks needing both deliberation and reactive action |
| Multi-agent (orchestrator / hub-and-spoke) | Workflow obviously decomposes into specialists with non-overlapping responsibilities AND distinct lifecycles or trust boundaries |
| Multi-agent (peer-to-peer / A2A) | Cross-org agents in separate runtimes |

Hard pushback on multi-agent: a single agent with multiple tools handles "multiple things" without coordination overhead. Demand a real decomposition reason — independent lifecycles, trust boundaries, or parallelism gain >2×. (See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/05_harness_architectures_brief.md` and `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/02_role_design_brief.md`.)

## 4. Memory & state

- **None** — single-shot, stateless tools. Skip section.
- **Long context only** — ≤ ~50K active tokens. Watch for "lost in the middle" and memory inflation.
- **Memory-as-action** — agent decides what to store/retrieve via tool calls. Dominant pattern in 2026 papers.
- **Hierarchical / virtual context** (MemGPT-style) — survives unbounded sessions.
- **Episodic + semantic + procedural split** — only when more than one type is genuinely needed.

Compaction policy: when does context get summarized vs. truncated? Pick one and document it. (See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/03_context_management_brief.md`.)

## 5. Tool layer / ACI

Five well-designed tools beat fifty. Decide:

- Rough tool count and boundaries
- MCP server vs. custom — if MCP, invoke `design-mcp-server` next to walk transport, auth, tool surface, schema discipline, error model, and testing strategy. See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/06_mcp_design_brief.md` for the empirical foundation
- For each tool: what shape does the *agent* see (not the human)?
- Permission scope per tool
- Idempotency

ACI (Agent–Computer Interface) quality dominates raw model capability for coding agents. (See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 6. Verification gates

For each gate:

- Format and schema
- Hard or soft?
- Verifier-LM (cheaper model) or rule-based?
- The failure mode it prevents

Hard gates stall on legitimate variation; soft gates miss errors. Pick one and instrument it. (See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/05_harness_architectures_brief.md`.)

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

Cost compounds: a planner running frontier+high-reasoning at every turn is the single fastest way to a surprise bill. Pick the tier per stage, not per harness. (See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/04_prompt_management_brief.md` for self-consistency sampling cost.)

## 8. Save the artifact

Once the seven sections above have been answered, write the picks to `harness/YYYY-MM-DD-HH-mm-SS.md` (current local time; create `harness/` if missing). This file is the source of truth that `/to-spec` reads downstream — do not skip it, and do not paraphrase only in-conversation.

Use the template below. Every section must carry information: cite the pattern brief that grounded the call, and record rejected alternatives so future agents don't re-open settled decisions. Commit the file.

<harness-template>

## Source PRD

`prds/<file>.md` — the PRD whose constraints drove these picks. (Or "harness-first override: no PRD yet" with a one-sentence reason, if section 0's exception applied.)

## TL;DR

One paragraph naming the picked substrate, topology, memory model, rough tool count, gate strategy, and the planner's model tier. A reader should be able to skip the rest and still know the shape.

## Custom vs off-the-shelf

**Picked:** custom | off-the-shelf (`<which agent>`)
**Why:** one or two sentences. If custom, which case(s) from section 1 applied.

## Substrate

**Picked:** Claude Agent SDK | OpenAI Agents SDK | Google ADK | smolagents | fork of `<harness>`
**Why:**
**Cited pattern:** `docs/agentic-patterns/01_harness_engineering_brief.md`

## Loop topology

**Picked:** Single ReAct | Planner-Executor | Reason-Plan-ReAct | Multi-agent (orchestrator) | Multi-agent (A2A)
**Why:** for multi-agent, name the real decomposition reason — independent lifecycles, trust boundaries, or parallelism gain >2×.
**Cited pattern:** `docs/agentic-patterns/05_harness_architectures_brief.md`, `docs/agentic-patterns/02_role_design_brief.md`

## Memory & state

**Approach:** None | Long context | Memory-as-action | Hierarchical | Episodic+semantic+procedural
**Compaction policy:** when context gets summarized vs. truncated.
**Cited pattern:** `docs/agentic-patterns/03_context_management_brief.md`

## Tool layer / ACI

**Rough count and boundaries:**
**MCP vs custom:** if MCP, note whether `design-mcp-server` should fire next.
**Per-tool agent-facing shape:** brief notes — what the *agent* sees, not the human.
**Permissions & idempotency:**
**Cited pattern:** `docs/agentic-patterns/01_harness_engineering_brief.md`, `docs/agentic-patterns/06_mcp_design_brief.md` (if MCP)

## Verification gates

| Gate | Format / schema | Hard / Soft | Verifier-LM or rule | Failure mode prevented |
|---|---|---|---|---|

**Cited pattern:** `docs/agentic-patterns/05_harness_architectures_brief.md`

## Per-stage sampling & model choice

| Stage | Model tier | Temperature | Reasoning effort | Max tokens / step |
|---|---|---|---|---|

**Cited pattern:** `docs/agentic-patterns/04_prompt_management_brief.md`

## Rejected alternatives

| Alternative | Why rejected |
|---|---|

Prevents future re-suggestion. Include at minimum the off-the-shelf option (if custom was picked) and any topology / substrate seriously considered.

## Open questions

Decisions deferred to `/to-spec` (e.g., exact module boundaries, schema specifics) or things that surfaced but couldn't be settled with current information.

</harness-template>

## Hand-off

Present the saved `harness/<file>.md` and ask the user to review. Once approved, prompt them to run `/to-spec` — it will read this file alongside the PRD automatically.
