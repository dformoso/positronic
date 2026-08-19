---
name: pick-harness-shape
description: Pick the harness shape for an LLM/agent system. Invoked by define when the project may need reliability beyond conversational use — programmatic gates, contracts, audit, autonomous execution. First decides whether a custom harness is needed at all, then walks substrate, topology, memory, tools, gates and recovery, security, and observability. Use when the user is designing a system that doesn't fit a single LLM call or a deterministic pipeline.
---

You are picking the harness shape for an LLM/agent system. The harness is the runtime stack around the LLM — tool dispatch, scheduling, memory, verification gates, audit. It is what makes a system trustworthy when there's no human in the loop catching mistakes. Harness changes alone can swing benchmark scores 6× on the same model; these decisions are load-bearing.

Reference: `${SKILL_DIR}/../../docs/agentic-patterns/` (`${SKILL_DIR}` = the directory containing this file) carries the empirical foundation. Cite the named pattern and its evidence as you make recommendations. Pull the relevant brief for each section below.

Ask one question at a time. Surface your recommended answer with each.

## Amend mode

If `definitions/harness.md` already exists and this run is a scoped change (not a from-scratch rebuild), run in amend mode per `${SKILL_DIR}/../../docs/amend-mode.md`: read the harness artifact as baseline, edit only the sections the change touches (reconcile any it contradicts), leave every other section byte-for-byte alone, and update the Amendment header. If the tool layer (§5) changed, prompt `design-mcp-server`; then prompt `/to-spec`.

## 0. Read the PRD (and surfaces, if any)

Before any picks, read:

- The PRD: `definitions/prd.md`. The PRD's user, regulatory, and business constraints (on-prem requirements, sensitive code paths, multi-agent decomposition reasons, trust boundaries) are the inputs that drive sections 1–9 — picking without them is picking blind.
- The journeys artifact, if it exists: `definitions/journeys.md`. Its **Agent autonomy matrix** is the direct input to §6 (gates) and §7 (irreversible-action gating) — one row per action, with its default, its confidence gate, and what hands it to a human. Don't re-derive that table here; the gates you pick have to implement it.
- The surfaces artifact, if it exists: `definitions/mockups.md`. When the product has UI, the harness's tool layer (§5) and gates (§6) should slot into known surfaces rather than re-deriving them.

If no PRD exists, stop and prompt the user to run `/to-prd` first. **Exception:** if the harness IS the product or differentiator (case 6 in section 1), the picks may legitimately shape the PRD rather than follow from it. Surface this to the user and let them override before proceeding.

Record the PRD path (and surfaces path, if read); they go into the artifact (section 10).

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

If any "build" condition fires, continue through sections 2–9 to pick the shape. If none do, stop here and use the simpler thing.

## 2. Substrate

| Substrate | Best for |
|---|---|
| Claude Agent SDK | Anthropic-first; deepest tool integration |
| OpenAI Agents SDK | OpenAI-first; Responses API |
| Google ADK | Google Cloud / Gemini-first; strong eval integration |
| LangGraph / LangChain | Cross-provider; explicit graph-shaped control flow; largest tool ecosystem (Mastra is the TypeScript analog) |
| smolagents | Lightweight, hackable; research-grade |
| Thin custom loop (no framework) | Full control, minimal deps, you own every gate — when a framework's structure fights the task |
| Fork existing harness (pi.dev, OpenClaw) | On-prem; multi-tenant; deep modification of an existing agent |

Default to the SDK matching the provider already in use; reach for LangGraph when you need cross-provider routing or graph-shaped control flow, a thin custom loop when a framework's structure fights the task, and a fork only for on-prem / multi-tenant / regulated cases. (See `${SKILL_DIR}/../../docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 3. Topology — two axes

ReAct (reason → act → observe, loop until a stop condition) is the universal substrate; every harness has one somewhere. The question is no longer "use ReAct?" but "what wraps it?" — and the wrapping moves along **two independent axes** with ReAct at the origin of both. Pick a rung on each; they compose freely (single-ReAct + bounded retry is the common coding-agent shape; Reason-Plan-ReAct + search is the common research shape). Climb only as far as task horizon and stakes demand — every rung adds cost and failure modes.

### Axis A — Division of labor (structure)

How many reasoning loci, and how is work split across them? Cost and coordination overhead climb monotonically down the table.

| Rung | What it adds over the rung above | Use when | Failure mode |
|---|---|---|---|
| **Single ReAct loop** | — (the substrate) | Default. Flat or independent work — one agent with many tools handles "multiple things" without coordination cost. Rule of thumb: up to ~10–20 actions for a frontier model (see note). | Drifts on long horizons — no global plan to return to. |
| **Planner / Executor** | Separates *what to do* (plan) from *how to do it* (execute) — one role-switching agent or two. | Steps interdepend or the task decomposes into sub-tasks — multi-file edits, research with sub-goals — or expected length nears the reliability ceiling (note). | Plan brittleness — a one-shot plan can't survive execution surprises; plans must be replan-able. |
| **+ Supervisor (Reason-Plan-ReAct)** | A supervisor watches execution and replans on deviation. | Non-trivial / enterprise tasks where execution success isn't knowable in advance. The pattern most production systems converge on. | Supervisor cost every turn; replan thrash on a noisy deviation signal. |
| **Multi-agent (orchestrator / hub-and-spoke)** | Multiple agents, non-overlapping roles, one orchestrator. | The workflow *obviously* decomposes into specialists **and** there's a real reason: independent lifecycles, trust boundaries, or parallelism gain > 2×. | Coordination overhead; cost multiplies; shared-state and message-channel failures. |
| **Multi-agent (peer-to-peer / A2A)** | Agents in separate runtimes coordinating over a protocol. | Cross-org agents that can't share a process or runtime. | All of the above, plus cross-agent prompt injection and protocol-level failure surface. |

**The action counts are derived, not a law.** Over N roughly-independent steps, whole-task success ≈ p^N (p = per-step reliability), so the horizon before you drop below a target success S is N ≈ ln(S) / ln(p). At a frontier model's ~99% per-step that's ~10 actions for 90% task success and ~20 for ~82% — which is where the band comes from. A weaker model, a harder task, or self-conditioning (models grow more error-prone after seeing their own mistakes) all pull the crossover into single digits, and the frontier keeps moving — so treat the count as the *output* of your per-step reliability and success target, and the real trigger as whether steps *interdepend*. (See `${SKILL_DIR}/../../docs/agentic-patterns/05_harness_architectures_brief.md`.)

**Hard pushback on multi-agent.** A single agent with multiple tools handles "multiple things" without coordination overhead, and industry consensus (Anthropic, OpenAI essays) is to use multi-agent sparingly — most "multi-agent wins" come from clean role decomposition that role-switching in one agent achieves just as well. Demand a real decomposition reason before leaving the single-agent rungs: independent lifecycles, trust boundaries, or measured parallelism gain > 2×. (See `${SKILL_DIR}/../../docs/agentic-patterns/05_harness_architectures_brief.md` and `${SKILL_DIR}/../../docs/agentic-patterns/02_role_design_brief.md`.)

### If Axis A is multi-locus: decompose the roles

Supervisor or either multi-agent rung means you now have more than one role. **Add roles as *phases* in one agent first** (planner → executor → critic) — cheaper, shared context, and `02_role_design` ranks this the right default for cost-sensitive systems. Split into separate *agents* only when §1's decomposition reason (independent lifecycles, trust boundaries, parallelism > 2×) actually demands it. These decisions feed §6 (gates), §7 (per-role tool scope), §8 (per-role sampling), and the artifact:

| Decision | Default | Why / cite |
|---|---|---|
| **Role set & count** | 3–5 non-overlapping roles; name each (planner, executor, critic/verifier, retriever/researcher, router, synthesizer) | More than ~5 adds cost without specialization gain; fewer under-specializes. `02_role_design_brief.md` |
| **Contract per role, not persona** | Inputs, outputs, allowed tools, stop condition, prohibitions | Free-form "you are an expert X" is near-random and can *hurt* accuracy (PRISM, "Helpful Assistant"). Contracts win. |
| **Boundaries & comms** | Hard boundaries + artifact passing for repeatable workflows; dialog only for prototypes | MetaGPT (artifacts) beats AutoGen (dialog) on repeatable pipelines; dialog drifts and bleeds roles. |
| **Topology shape** | Sequential pipeline if stages are ordered; parallel workers only for *independent* sub-tasks; hierarchical past ~5 roles | Parallel beats sequential only when sub-tasks are genuinely independent. `05_harness_architectures_brief.md` |
| **Cross-role memory** | Artifacts only — role A sees role B's deliverable, not its reasoning | Lower coupling, higher specialization than shared dialog history. |
| **Assignment** | Static for production; dynamic routing only for heterogeneous query mixes | Dynamic adds routing-failure modes and a harder eval surface. |

Treat role + tool privilege as one design: a role's contract bounds which §5 tools it may call, and that binding *is* the trust boundary §7 names. (See `${SKILL_DIR}/../../docs/agentic-patterns/02_role_design_brief.md`.)

### Axis B — Improvement & recovery loop (iteration)

How does the system beat a single forward pass? Each rung extends the reach of the improvement loop — within-step → within-task → across a task family → across harness versions — and each needs a stronger eval signal than the one above (which is why §9 is load-bearing here). Orthogonal to Axis A: pick independently.

| Rung | What it adds | Use when | Cost / caveat |
|---|---|---|---|
| **None** | Single forward pass per step. | Cheap, well-verified steps; failures are uninformative (rate limits, noise). | — |
| **Reflexion (retry with feedback)** | On failure, the agent writes verbal self-feedback into the next attempt's context. | Bounded-retry tasks where failures carry signal. The cheapest real win above plain ReAct. | Needs an informative failure signal and a retry ceiling (§6) or it loops. |
| **Search (Tree / Graph of Thoughts, self-consistency)** | Explore multiple branches/paths, evaluate, prune. | Combinatorial / search problems with *cheap evaluation of partial states*. | N× cost; needs a usable evaluator; diminishing returns past depth ~5 / ~40 samples. |
| **Skill library (Voyager)** | Agent accumulates reusable code/skills across tasks. | Lifelong or repeated-task-family agents. | Skill management is its own sub-problem — when to add, consolidate, retire. |
| **Harness self-optimization (Meta-Harness / AutoHarness)** | The harness itself becomes the search target — topology, prompts, gates. | Repeated workload with a strong, transferable eval signal. | Bottlenecked entirely on eval quality; cheap evals overfit the harness. |

Most projects pick **None** or **Reflexion** and stop; Search and above are for narrow task classes. Name the reason in the artifact if you climb past Reflexion. (See `${SKILL_DIR}/../../docs/agentic-patterns/05_harness_architectures_brief.md`.)

## 4. Memory & state

- **None** — single-shot, stateless tools. Skip section.
- **Long context only** — ≤ ~50K active tokens. Watch for "lost in the middle" and memory inflation.
- **Memory-as-action** — agent decides what to store/retrieve via tool calls. Dominant pattern in 2026 papers.
- **Hierarchical / virtual context** (MemGPT-style) — survives unbounded sessions.
- **Episodic + semantic + procedural split** — only when more than one type is genuinely needed.

Compaction policy: when does context get summarized vs. truncated? Pick one and document it. (See `${SKILL_DIR}/../../docs/agentic-patterns/03_context_management_brief.md`.)

## 5. Tool layer / ACI

Five well-designed tools beat fifty. Decide:

- Rough tool count and boundaries
- MCP server vs. custom — if MCP, record the rough count and naming convention here; `design-mcp-server` runs *after* this skill completes to walk transport, auth, schema discipline, error model, and testing strategy in depth and write its own section in `definitions/mcp-servers.md`. See `${SKILL_DIR}/../../docs/agentic-patterns/06_mcp_design_brief.md` for the empirical foundation
- For each tool: what shape does the *agent* see (not the human)?
- Permission scope per tool
- Idempotency

ACI (Agent–Computer Interface) quality dominates raw model capability for coding agents. (See `${SKILL_DIR}/../../docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 6. Verification gates, recovery & budget

Gates are the trust substrate for everything above plain ReAct on both axes — you can't safely retry, prune a search branch, or let an agent act unattended without a verifier. For each gate:

- Format and schema
- Hard or soft?
- Verifier-LM (cheaper model) or rule-based?
- The failure mode it prevents
- **What happens when it fires** — the recovery action (retry with feedback, replan, escalate to a human, abort) and the **retry ceiling** before giving up. A gate with no defined recovery just stalls.

Hard gates stall on legitimate variation; soft gates miss errors. Pick one per gate and instrument it. (See `${SKILL_DIR}/../../docs/agentic-patterns/05_harness_architectures_brief.md`.)

**Global stop & budget envelope.** Separate from per-gate retries, set hard outer bounds or the harness runs away:

- **Max loop iterations** / actions per task
- **Token budget** per task, plus a **child-agent quota** if Axis A is multi-agent
- **Wall-clock** ceiling
- **Terminal stop condition** — what counts as done, and what the agent does when it hits a bound unfinished (return partial and flag, or hard-fail)

ReAct is *defined* as "loop until a stop condition" — name that condition here instead of leaving it implicit.

## 7. Security & trust boundary

§1 justified the harness partly on irreversible side effects, regulated domains, and trust boundaries — so design for them rather than leaving permissions at the per-tool granularity of §5. Decide:

- **Sandbox / blast radius** — what can the agent's execution actually touch (filesystem, network, secrets, prod vs. staging), and what's the damage if a tool call goes wrong?
- **Irreversible-action gating** — which actions are irreversible or high-stakes (writes, payments, deletes, external sends), and what gates them: a hard gate (§6), human approval, or a dry-run-first contract?
- **Prompt-injection posture** — untrusted input (tool results, retrieved docs, user content) can carry instructions. What's the defense: input provenance, restricted tool scope on untrusted turns, output filtering?
- **Multi-agent surface** — if Axis A is multi-agent, cross-agent prompt injection and message-channel tampering are live risks. Name the trust boundary between agents, and bind each role to only the §5 tools its contract allows — that per-role scope is the boundary.
- **Audit trail** — for regulated or auditable deployments, what's logged immutably, and is it enough to reconstruct any decision after the fact?

Skip the rows that don't apply, but say *why* — "no irreversible actions; all tools read-only" is a real answer that belongs in the artifact. (See `${SKILL_DIR}/../../docs/agentic-patterns/01_harness_engineering_brief.md`.)

## 8. Per-stage sampling & model choice

Harness behavior depends as much on per-stage parameters as on topology. Provider defaults (often `T=1.0`, latest frontier model, no reasoning budget) are rarely optimal — planner and verifier stages in particular benefit from explicit, lower-variance settings.

For each role/stage in §3's role set (planner, executor, verifier, …), decide:

- **Model tier** — frontier / mid / cheap
- **Temperature** (and/or top-p)
- **Reasoning effort** — if the model exposes it (Claude extended thinking, GPT reasoning levels)
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

Cost compounds: a planner running frontier+high-reasoning at every turn is the single fastest way to a surprise bill. Pick the tier per stage, not per harness. (See `${SKILL_DIR}/../../docs/agentic-patterns/04_prompt_management_brief.md` for self-consistency sampling cost.)

## 9. Observability & evaluation

The shape above is a hypothesis until you can watch it run and measure whether it works — harness changes alone swing benchmark scores up to 6× on the same model, so you can't tune blind. Decide the *posture* now; the mechanism can defer to `/to-spec`, the way §5 defers tool internals to `design-mcp-server`.

- **Trajectory instrumentation** — is every model call, tool call, gate result, and replan logged and replayable? Replay is the single most valuable debugging tool; without it you can't tell which §3 rung you actually need.
- **Success signal** — what's the verifiable definition of a good run? Tie it to the PRD's CUJs and any eval the project already has.
- **Harness-level eval** — is there a held-out task set the harness runs against before changes ship? Per-task metrics don't transfer between harnesses; budget for building this signal.
- **Production monitoring** — for an always-on harness: cost-per-success, trajectory length, gate hit-rate, drift, and the threshold that pages someone.

For most teams this is the highest-leverage layer beyond ReAct — the instrument that tells you whether climbing §3 helped. Don't optimize topology before it exists. (See `${SKILL_DIR}/../../docs/agentic-patterns/07_eval_observability_brief.md` for the eval dimensions, the offline → online progression, and OTEL as the telemetry standard.)

## 10. Save the artifact

Once the sections above have been answered, write the picks to `definitions/harness.md` (create `definitions/` if missing). This file is the source of truth that `/to-spec` reads downstream — do not skip it, and do not paraphrase only in-conversation.

Use the template below. Every section must carry information: cite the pattern brief that grounded the call, and record rejected alternatives so future agents don't re-open settled decisions. Commit the file.

<harness-template>

## Sources

- `definitions/prd.md` — the PRD whose constraints drove these picks. (Or "harness-first override: no PRD yet" with a one-sentence reason, if section 0's exception applied.)
- `definitions/journeys.md` — if read in §0, the autonomy matrix these gates implement.
- `definitions/mockups.md` — if read in §0, the UI surfaces these tool/gate picks slot into.

## TL;DR

One paragraph naming the picked substrate, the Axis A structure and Axis B improvement loop, memory model, rough tool count, gate + recovery strategy, security posture, observability plan, and the planner's model tier. A reader should be able to skip the rest and still know the shape.

## Why a custom harness

**Triggers from §1:** which "build" condition(s) fired.
**One-sentence reason:** the specific reliability requirement (or domain / differentiation reason) that made the simpler path insufficient.

## Substrate

**Picked:** Claude Agent SDK | OpenAI Agents SDK | Google ADK | LangGraph | smolagents | thin custom loop | fork of `<harness>`
**Why:**
**Cited pattern:** `docs/agentic-patterns/01_harness_engineering_brief.md`

## Topology

**Axis A — structure:** Single ReAct | Planner-Executor | Reason-Plan-ReAct | Multi-agent (orchestrator) | Multi-agent (A2A)
**Axis B — improvement loop:** None | Reflexion | Search (ToT / GoT / self-consistency) | Skill library | Harness self-optimization
**Why:** for multi-agent, name the real decomposition reason — independent lifecycles, trust boundaries, or parallelism gain >2×. For any Axis B rung past Reflexion, name the reason.
**Cited pattern:** `docs/agentic-patterns/05_harness_architectures_brief.md`, `docs/agentic-patterns/02_role_design_brief.md`

## Role decomposition

*(Only if Axis A is Supervisor or multi-agent; otherwise "single role — N/A".)*

| Role | Contract (in → out · allowed tools · stop) | Phase or separate agent? | Model tier (→ §8) |
|---|---|---|---|

**Topology shape:** sequential | parallel workers | hierarchical | conversational — and why.
**Communication:** artifacts | dialog; what each role sees of others.
**Assignment:** static | dynamic.
**Cited pattern:** `docs/agentic-patterns/02_role_design_brief.md`

## Memory & state

**Approach:** None | Long context | Memory-as-action | Hierarchical | Episodic+semantic+procedural
**Compaction policy:** when context gets summarized vs. truncated.
**Cited pattern:** `docs/agentic-patterns/03_context_management_brief.md`

## Tool layer / ACI

**Rough count and boundaries:**
**MCP vs custom:** if MCP, note that `design-mcp-server` will run after this skill to write its section of `definitions/mcp-servers.md`.
**Per-tool agent-facing shape:** brief notes — what the *agent* sees, not the human.
**Permissions & idempotency:**
**Cited pattern:** `docs/agentic-patterns/01_harness_engineering_brief.md`, `docs/agentic-patterns/06_mcp_design_brief.md` (if MCP)

## Verification gates, recovery & budget

| Gate | Format / schema | Hard / Soft | Verifier-LM or rule | Failure mode prevented | Recovery action + retry ceiling |
|---|---|---|---|---|---|

**Stop & budget envelope:** max iterations / actions, token budget (+ child-agent quota if multi-agent), wall-clock ceiling, terminal stop condition.
**Cited pattern:** `docs/agentic-patterns/05_harness_architectures_brief.md`

## Security & trust boundary

**Sandbox / blast radius:**
**Irreversible-action gating:**
**Prompt-injection posture:**
**Multi-agent trust surface:** (if Axis A is multi-agent)
**Audit trail:** (if regulated / auditable)
Skip rows that don't apply — state why.
**Cited pattern:** `docs/agentic-patterns/01_harness_engineering_brief.md`

## Per-stage sampling & model choice

| Stage | Model tier | Temperature | Reasoning effort | Max tokens / step |
|---|---|---|---|---|

**Cited pattern:** `docs/agentic-patterns/04_prompt_management_brief.md`

## Observability & evaluation

**Trajectory instrumentation:** what's logged and replayable.
**Success signal:** verifiable definition of a good run (ties to PRD CUJs).
**Harness-level eval:** held-out task set, or note it's deferred to `/to-spec`.
**Production monitoring:** (if always-on) cost-per-success, trajectory length, gate hit-rate, drift thresholds.
**Cited pattern:** `docs/agentic-patterns/07_eval_observability_brief.md`

## Rejected alternatives

| Alternative | Why rejected |
|---|---|

Prevents future re-suggestion. Include at minimum the "no harness" path (and why it was rejected) along with any topology / substrate seriously considered.

## Open questions

Decisions deferred to `/to-spec` (e.g., exact module boundaries, schema specifics) or things that surfaced but couldn't be settled with current information.

</harness-template>

## Hand-off

Present the saved `definitions/harness.md` and ask the user to review. Once approved:

- If the tool layer (§5) chose MCP, prompt them to run `design-mcp-server` next — it writes `definitions/mcp-servers.md`, which `/to-spec` reads.
- **Placement gate** — if the system runs autonomously in the cloud (always-on triggers, scheduled work, inbound webhooks) and its production placement isn't already settled: derive a workload profile from this artifact (max single-run duration, state across waits, trigger shape, executes generated code y/n, concurrency, residency constraint, irreversible side effects) and ask the gate question: *does this need more than one boring compute service?* If runs fit platform timeouts, state lives in the project's own store, and no generated code executes — the answer is no: record the verdict + profile in `definitions/runtime.md` (one page: gate verdict, workload profile, revisit `TRIGGER:` lines — each at the start of its own line, list markers fine; the sweep greps for them) so the decision isn't reopened. If the gate trips, the placement questions in `${SKILL_DIR}/../../docs/selection-method.md` drive the same artifact section by section (per-pick evidence + exit line, residency-exceptions table, cost envelope + kill switch). This artifact records *where the loop runs*; individual service picks stay `docs/adr/` records via `pick-cloud-services`. Amend-mode applies (`definitions/runtime.md` is in the cascade).
- Then prompt them to run `/to-spec` — it reads this file (and the placement profile, if one exists) alongside the PRD automatically.
