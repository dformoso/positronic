---
name: pick-harness-shape
description: Pick the harness shape for an LLM/agent system. Invoked by define when the project may need reliability beyond conversational use — programmatic gates, contracts, audit, autonomous execution. First decides whether a custom harness is needed at all, then walks substrate, loop topology, memory, tool layer, and gate strategy. Use when the user is designing a system that doesn't fit a single LLM call or a deterministic pipeline.
---

You are picking the harness shape for an LLM/agent system. The harness is the runtime stack around the LLM — tool dispatch, scheduling, memory, verification gates, audit. It is what makes a system trustworthy when there's no human in the loop catching mistakes. Harness changes alone can swing benchmark scores 6× on the same model; these decisions are load-bearing.

Reference: `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/` carries the empirical foundation. Cite the named pattern and its evidence as you make recommendations. Pull the relevant brief for each section below.

Ask one question at a time. Surface your recommended answer with each.

## 0. Read the PRD (and surfaces, if any)

Before any picks, read:

- The most recent PRD: `ls prds/[0-9]*.md | sort | tail -1`. The PRD's user, regulatory, and business constraints (on-prem requirements, sensitive code paths, multi-agent decomposition reasons, trust boundaries) are the inputs that drive sections 1–7 — picking without them is picking blind.
- The most recent surfaces artifact, if any: `ls surfaces/[0-9]*.md | sort | tail -1`. When the product has UI, the harness's tool layer (§5) and gates (§6) should slot into known surfaces rather than re-deriving them.

If no PRD exists, stop and prompt the user to run `/to-prd` first. **Exception:** if the harness IS the product or differentiator (case 6 in section 1), the picks may legitimately shape the PRD rather than follow from it. Surface this to the user and let them override before proceeding.

Record the PRD path (and surfaces path, if read); they go into the artifact (section 8).

## 1. Do you need a custom harness at all?

A custom harness exists to make an LLM system reliable when there's no human in the verification loop — gates, contracts, programmatic verification, audit, structured routing. If your system doesn't need that, don't build one.

**Skip the harness when:**

- You're a dev doing dev work — Claude Code, Cursor, Codex, and Cline already are the harness. Use them.
- Your application needs one LLM call (generation, summarization, classification, extraction) — hit the API directly.
- Your application is a chat surface where the user is the verification loop — minimal chat loop, no harness machinery.

**Build a custom harness when:**

- The system runs without a human in the loop — scheduled jobs, background workers, autonomous bots, customer-facing agents
- Bounded failure modes are mandatory — regulated industry (financial, healthcare, government), audit trails, irreversible side effects
- Verification must be programmatic — gates, schema checks, verifier-LM judgments the agent can't skip
- The agent picks its own next step across multiple turns with tool calls and feedback
- Multi-agent with real decomposition — independent lifecycles, trust boundaries, or parallelism gain >2×
- The harness itself is the product or differentiator

If any "build" condition fires, continue through sections 2–7 to pick the shape. If none do, stop here and use the simpler thing.

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
- MCP server vs. custom — if MCP, record the rough count and naming convention here; `design-mcp-server` runs *after* this skill completes to walk transport, auth, schema discipline, error model, and testing strategy in depth and write its own `mcp-servers/<file>.md` artifact. See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/06_mcp_design_brief.md` for the empirical foundation
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

## Why a custom harness

**Triggers from §1:** which "build" condition(s) fired.
**One-sentence reason:** the specific reliability requirement (or domain / differentiation reason) that made the simpler path insufficient.

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
**MCP vs custom:** if MCP, note that `design-mcp-server` will run after this skill to write its own `mcp-servers/<file>.md` artifact.
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

Prevents future re-suggestion. Include at minimum the "no harness" path (and why it was rejected) along with any topology / substrate seriously considered.

## Open questions

Decisions deferred to `/to-spec` (e.g., exact module boundaries, schema specifics) or things that surfaced but couldn't be settled with current information.

</harness-template>

## Hand-off

Present the saved `harness/<file>.md` and ask the user to review. Once approved:

- If the tool layer (§5) chose MCP, prompt them to run `design-mcp-server` next — it writes a versioned `mcp-servers/<file>.md` that `/to-spec` reads.
- Otherwise, prompt them to run `/to-spec` — it will read this file alongside the PRD automatically.
