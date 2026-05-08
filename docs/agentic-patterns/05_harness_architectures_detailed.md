# Frontier: Harness Architectures — Detailed

## What "harness architecture" means in 2026

A harness architecture is a *named pattern* describing how an agent's runtime is structured: which loops, which roles, which memories, which gates, in what topology. Where Topic 1 (harness engineering) is the discipline, this is the *pattern catalog*.

The architecture is what you draw on a whiteboard when you describe how an agent works. ReAct loop. Planner-executor split. Reflexion retry. Multi-agent role decomposition. Skill library. Tree of thoughts.

By mid-2026 this catalog is rich but partially settled. Some patterns are universal substrates (ReAct). Some are dominant for specific task classes (planner-executor for long-horizon, ToT for search). Some are still contested (multi-agent vs. single-agent + tools).

## State of the frontier (mid-2026)

### Three pattern-level shifts

**1. ReAct is settled science.**

Yao et al.'s 2022 reason-act-observe loop is the universal substrate for tool-using agents. Every modern harness contains a ReAct loop somewhere — usually as the inner loop, with planning, reflection, and verification wrapping it.

The 2024 paper *On the Brittle Foundations of ReAct Prompting for Agentic Large Language Models* identifies failure modes (verbose reasoning, action drift, looping) but doesn't displace ReAct — it suggests the wrapping matters more than the inner loop.

The interesting question in 2026 is no longer "use ReAct?" — it's "what wraps it?"

**2. Planner-executor is the dominant long-horizon pattern.**

Tasks longer than ~20 actions consistently benefit from splitting *what to do* (planning) from *how to do it* (execution).

- **Plan-and-Act (2025)**: cleanest recent statement. Planner produces high-level steps; executor translates each into environment-specific actions.
- **Reason-Plan-ReAct (2025)**: hybrid where a Reasoner-Planner Agent handles planning and meta-analysis, while one or more Proxy-Execution Agents use ReAct for tool interactions. Adds a supervisory layer over execution.
- **PEAR (2025)**: the first dedicated benchmark for planner-executor robustness. Reveals a wide gap between models on this architecture.
- **Routine (2025)**: structural planning framework optimized for enterprise use cases.

The supervisor-on-top-of-executor pattern (Reason-Plan-ReAct) is increasingly common because pure planner-executor stalls when execution surprises the plan.

**3. Tool calling is now a layer.**

Toolformer (2023) and Gorilla (2023) seeded tool-use capability. By 2026, tool calling is standardized via MCP, with most major LLMs supporting structured function calling natively.

The frontier moves to:
- **Tool-selection robustness**: can the agent pick the right tool from 100+ options?
- **Tool composition**: chaining tools across calls.
- **Context-aware dispatch**: tool choice based on retrieved context.
- **Adversarial tool resistance**: 2025 *ToolTweak* shows tools can be manipulated to trigger wrong selection.

The 2025 *Robustness of Agentic Function Calling* paper benchmarks the space.

## Ranked techniques

### 1. ReAct loop

The universal substrate. Reason → Act → Observe, repeating until a stop condition.

**Use when**: any tool-using agent. Default.
**Source**: Yao et al. 2022.
**Notes**: Modern usage often replaces the explicit "Thought:" trace with model-internal chain-of-thought (especially on reasoning-tuned models like Claude with extended thinking, GPT-5 with reasoning effort, Gemini 2.5 thinking).

### 2. Planner / Executor split

Decompose plan-construction from plan-execution.

**Use when**: tasks expected to take >20 actions; multi-file edits; multi-step research.
**Source**: Plan-and-Act (2025).
**Notes**: Plan brittleness is the failure mode. Plans should be replan-able; one-shot plans fail on long horizons.

### 3. Reasoner-Planner-supervising-ReAct-Executor

A supervisor agent (planner) directs one or more executor agents (ReAct loops). Supervisor monitors results, replans on deviation.

**Use when**: enterprise tasks with both deliberation and reactive action; tasks where execution success isn't always knowable in advance.
**Source**: Reason-Plan-ReAct (2025).
**Notes**: This is the architecture most production systems converge on for non-trivial tasks.

### 4. Reflection / Reflexion loop

After failure, the agent generates verbal self-feedback that's added to the next attempt's context.

**Use when**: tasks with bounded retry budget where failures carry signal.
**Source**: Shinn et al. 2023.
**Variants**: Multi-Agent Reflexion (2025) replaces self-critique with structured debate among personas; Agent-R (2025) trains the reflection capability via iterative self-training.
**Notes**: Doesn't help when failures are uninformative (rate limits, environmental noise).

### 5. Tree of Thoughts (ToT)

Maintain a search tree of partial reasoning paths; evaluate and expand promising branches.

**Use when**: combinatorial problems with cheap intermediate evaluation; planning, puzzles, game-tree problems.
**Source**: Yao et al. 2023.
**Variants**: Adaptive Graph of Thoughts (2025) unifies CoT/ToT/GoT; Atom of Thoughts (2025) for test-time scaling; Lateral Tree-of-Thoughts (2025) adds non-greedy exploration.
**Notes**: N× cost. Needs a usable evaluator. Often diminishing returns past depth ~5.

### 6. Graph of Thoughts (GoT)

Generalize ToT to arbitrary graph structures with refinement edges.

**Use when**: refinement-heavy tasks; problems where partial solutions can be merged.
**Source**: Besta et al. 2023.
**Notes**: Engineering complexity higher than ToT. Less common in production.

### 7. Multi-agent role decomposition

Split work across agents with non-overlapping roles.

**Use when**: workflows with clear phases (PM/Eng/QA, search/synthesize/critique).
**Sources**: MetaGPT (2023), AutoGen (2023), ChatDev (2023). Multiple 2025 surveys catalog patterns.
**Notes**: Recent industry consensus (Anthropic, OpenAI 2026 essays): use sparingly. Most "multi-agent benefits" come from clean role decomposition that can also be achieved with role-switching in a single agent.

### 8. Voyager-style skill library

Agent maintains an ever-growing library of executable code snippets ("skills") that can be reused across tasks.

**Use when**: lifelong agents; embodied agents; agents on repeated task families.
**Source**: Wang et al. 2023 (Voyager).
**Notes**: Skill-management itself is a sub-problem (when to add, when to consolidate, when to retire skills). The 2026 NLAH paper treats skills as part of harness logic.

### 9. Self-consistency / sampling

Sample multiple reasoning paths; aggregate via majority or learned voting.

**Use when**: reasoning tasks where the answer can be voted on.
**Source**: Wang et al. 2022.
**Notes**: N× cost. Diminishing returns past ~40 samples on most benchmarks.

### 10. Modular harness (configurable component architecture)

Harness as composition of swappable components: tool layer, memory layer, planner, executor, reflector, etc.

**Use when**: domain-spanning agents; gaming agents (the 2025 *General Modular Harness for Gaming Environments* paper); systems requiring rapid A/B testing of components.
**Source**: General Modular Harness (2025); OpenHands SDK (2025).
**Notes**: Right architecture for production. Risk: integration drift (components evolve incompatibly).

## Key tradeoffs

### Pure ReAct vs. wrapped ReAct (planner / supervisor)

| Aspect | Pure ReAct | Wrapped ReAct |
|--------|------------|--------------|
| Cost | 1× | 2-3× |
| Long-horizon | Drifts | Stays on plan |
| Debugging | Easy | Harder |
| Implementation | Simple | More moving parts |
| Best below | ~10 actions | ~10 actions |
| Best above | — | ~20+ actions |

### Plan-once vs. iterative plan/replan

| Aspect | Plan-once | Iterative |
|--------|-----------|-----------|
| Cost | 1× plan | N× plan |
| Robustness | Plan brittleness | Recovers from surprises |
| Determinism | High | Lower |
| Best for | Routine tasks | Open-ended tasks |

The pattern that wins in production: replan after each major sub-goal AND on verification failure.

### Reflexion (retry on failure) vs. Tree of Thoughts (search up front)

| Aspect | Reflexion | Tree of Thoughts |
|--------|-----------|------------------|
| When cost happens | After failure | Always |
| Failure signal needed | Yes | No |
| Search structure | Linear | Tree |
| Best for | Cheap-eval-after-execution | Cheap-eval-on-partial-state |

These are complementary. Reflexion + ToT in the same harness isn't unusual.

### Multi-agent (parallel) vs. multi-agent (sequential) vs. single-agent

| Aspect | Parallel MA | Sequential MA | Single-agent |
|--------|-------------|---------------|--------------|
| Wallclock | Fast | Slow | Medium |
| Cost | High | Medium | Low |
| Coordination overhead | High | Low | None |
| Specialization | High | High | Low |
| Debug | Hardest | Hard | Easy |
| Right when | Independent subtasks | Pipeline workflow | Default |

### Voyager skill library vs. flat tool list

| Aspect | Skill library | Flat tools |
|--------|---------------|------------|
| Compounding gains | Yes | No |
| Storage / consolidation | Required | None |
| Mis-application risk | Yes | Lower |
| Best for | Lifelong / embodied | Episodic |

### Modular harness vs. monolithic

| Aspect | Modular | Monolithic |
|--------|---------|------------|
| Component swap | Easy | Hard |
| Integration drift | Risk | None |
| Debugging | Component-level | Whole-system |
| Production fit | High | Demos / one-offs |

## Empirical anchors

- **OpenHands SDK on SWE-Bench Verified**: 72% (Nov 2025).
- **MetaGPT on HumanEval**: 85.9% Pass@1.
- **Multi-Agent Reflexion on HumanEval**: 76.4 → 82.6.
- **Tree of Thoughts on Game of 24**: GPT-4 + ToT solves 74% vs ~4% with CoT (in original Yao 2023 paper).
- **Voyager on Minecraft**: orders of magnitude more skills accumulated than baselines.
- **AutoHarness on TextArena**: 100% illegal-move prevention across 145 games.
- **Reflexion on HumanEval**: ~22% absolute improvement over ReAct baseline (in 2023 paper).
- **PEAR (2025)**: planner-executor systems show ~20-30% gap between strong and weak planners on the benchmark.
- **SWE-Bench Pro (2025)**: best models resolve only ~21% (vs ~65% on Verified) — the long-horizon gap is real.

## Open questions on the frontier

### When does multi-agent beat single-agent + tools?

The dominant 2026 question. Evidence:

- **For multi-agent**: MetaGPT 85.9% on HumanEval, ChatDev's coherent code generation, MA-RAG's complex QA gains.
- **Against multi-agent**: Anthropic's recent essays argue that single-agent + tools matches multi-agent on most workloads, with less complexity. Claude Code's design is explicitly single-agent.

The threshold isn't formalized. Heuristic: if the workflow has 3+ clearly distinct phases that need different expertise, multi-agent helps. If the workflow is a sequence of similar reasoning steps with tools, single-agent + tools wins.

### Tree-of-Thoughts vs. Reflexion choice

ToT searches up front; Reflexion iterates on failure. Both add cost. When to choose?

- ToT requires *cheap evaluation of partial states*.
- Reflexion requires *informative failure signals*.

Real systems often use both: ToT for branching exploration, Reflexion for retry. But the literature lacks principled guidance.

### Planner robustness

Planners hallucinate plans. PEAR (2025) is the first dedicated benchmark, revealing wide gaps between models. No standard defense yet:

- Plan-then-verify (LM-as-judge on the plan).
- Plan-then-test (run plan in a simulator).
- Replan-on-failure.
- Hierarchical planning (high-level abstract plan, low-level executable plan).

All are heuristics; no principled method.

### Hard vs. soft verification gates

Hard gates (tests must pass, types must check) stall on legitimate variation. Soft gates (LM-judge approval) miss errors.

Adaptive gating — the gate's strictness scales with stakes — is open. Some 2026 work explores this; no standard.

### Architectural search over harnesses

MASS searches prompt + topology for multi-agent. Single-agent harness search (which patterns to combine, when, in what order) is less explored. Meta-Harness and AutoHarness do this but for narrower spaces.

The space is combinatorial (which patterns × which orderings × which parameters), so exhaustive search is impractical. Bayesian optimization, evolutionary search, or RL over harness designs are all possible directions.

### Composition of architectures

Can you take "ReAct + Reflexion" and "Planner-Executor" and produce a composed "Plan / Reflexion-Executor" that retains the strengths of both?

Currently this composition is done by hand. Compositional architecture languages would help. Anthropic's NLAH proposes natural language as the substrate; whether NL is expressive enough for compositional semantics is an open question.

### Skill-library management at scale

Voyager-style skill libraries grow without bound. Skill consolidation, retirement, and recall efficiency become bottlenecks. Several 2025-2026 papers address sub-aspects (skill verification, skill retrieval) but no holistic solution exists.

### Tool-selection robustness

With 100+ tools available, the agent must reliably pick the right one. Failure modes:

- **Description sensitivity**: agent picks based on description wording.
- **Adversarial tool injection** (ToolTweak 2025).
- **Tool overlap**: ambiguous calls to similar tools.
- **Stale tool descriptions**: tool semantics change without description updates.

Current defense: high-quality descriptions, retrieval-based tool dispatch (give the agent only the top-K relevant tools).

## Recommendations for practitioners

If you're building a coding/CLI agent (the most common use case):

1. **Substrate**: ReAct loop.
2. **Tool layer**: MCP-based, with carefully designed ACI.
3. **Wrapping**: planner over multi-step tasks; supervisor on top for high-stakes.
4. **Retry**: Reflexion-style on failure, bounded budget.
5. **Memory**: episodic + semantic split, memory-as-action ideally.
6. **Verification**: hard gates (tests pass) + soft gates (LM-judge).
7. **Skip**: multi-agent unless the workflow obviously decomposes.

If you're building a research / long-horizon agent:

1. **Substrate**: ReAct + planner-executor.
2. **Add**: Reason-Plan-ReAct supervisor.
3. **Memory**: emphasis on long-term memory; external knowledge stores; hierarchical context.
4. **Reflection**: on every major failure; consider Multi-Agent Reflexion for diverse critique.
5. **Skill library**: if domain-stable, accumulate Voyager-style.

If you're building a search / planning / puzzle agent:

1. **Substrate**: Tree of Thoughts (or Graph of Thoughts).
2. **Wrapping**: Reflexion on dead-ends.
3. **Pruning**: aggressive; run a critic on each branch.
4. **Skip**: heavy memory unless task is multi-stage.

General advice:

- **Don't bolt on architectures without evidence.** Every layer adds cost and failure modes.
- **Instrument trajectory replay** before optimizing architecture. You can't fix what you can't see.
- **Test on long-horizon benchmarks** (SWE-Bench Pro, GAIA) — short-horizon evals miss the problems your architecture is designed to solve.

## Recommended reading order

1. *ReAct* (Yao 2022) — the substrate.
2. *Reflexion* (Shinn 2023) — the retry pattern.
3. *Tree of Thoughts* (Yao 2023) — the search pattern.
4. *Voyager* (Wang 2023) — the skill-library pattern.
5. *Toolformer* (2023) and *Gorilla* (2023) — tool calling foundations.
6. *MetaGPT* (Hong 2023) and *AutoGen* (Wu 2023) — multi-agent baselines.
7. *Plan-and-Act* (2025) — planner-executor.
8. *Reason-Plan-ReAct* (2025) — the production architecture.
9. *PEAR* (2025) — planner-executor benchmark.
10. *General Modular Harness for LLM Agents* (2025) — modular architecture.
11. *Routine* (2025) — enterprise structural planning.
12. *Graph of Thoughts* (Besta 2023) — generalized search.

## Bottom line

Harness architecture in 2026 is a settled vocabulary with contested choices. ReAct is universal. Planner-executor wins long-horizon. Reflexion adds value on signal-bearing failures. Tree-of-Thoughts wins search-y problems. Multi-agent has narrow but real wins. The interesting next 12 months are architectural search over harnesses, composition theory, and the multi-agent vs. single-agent debate's empirical resolution.
