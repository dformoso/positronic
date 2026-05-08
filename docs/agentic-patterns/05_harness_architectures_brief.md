# Frontier: Harness Architectures — Brief

**Scope.** Specific architectural patterns inside an agent harness: ReAct loops, planner-executor splits, reflection cycles, tool dispatch, multi-agent topologies. Where Topic 1 (harness engineering) is the *discipline*, this is the *catalog of named patterns*.

## State of the frontier

Three pattern-level shifts:

1. **The ReAct loop is settled science.** Yao et al.'s 2022 reason-act-observe pattern is the universal substrate. Every modern harness contains a ReAct loop somewhere. The interesting question is no longer "use ReAct?" but "what wraps it?".
2. **Planner-executor is the dominant long-horizon pattern.** Plan-and-Act (2025), Reason-Plan-ReAct (2025), and PEAR (2025) all converge on a planner that decomposes + an executor (often a ReAct loop) that runs sub-tasks. The supervisor on top is increasingly common (Reason-Plan-ReAct).
3. **Tool calling is a layer, not a feature.** Toolformer (2023) and Gorilla (2023) seeded tool use; in 2026 it's standardized via MCP. Agents are now reliably *function callers*. The frontier moves to tool-selection robustness and context-aware tool dispatch.

## Ranked techniques

| Rank | Pattern | Use when | Source |
|------|---------|----------|--------|
| 1 | **ReAct loop** (reason → act → observe) | Default substrate for any tool-using agent | Yao 2022 |
| 2 | **Planner / Executor split** | Tasks >20 actions, multi-file edits | Plan-and-Act 2025 |
| 3 | **Reasoner-Planner supervising ReAct executor** | Enterprise tasks needing both deliberation and reactive action | Reason-Plan-ReAct 2025 |
| 4 | **Reflection / Reflexion loop** | Bounded retry where failures are signal | Shinn 2023 |
| 5 | **Tree of Thoughts** (deliberate search) | Combinatorial / search problems with cheap eval | Yao 2023 |
| 6 | **Graph of Thoughts** (arbitrary thought graphs) | Refinement-heavy tasks | Besta 2023 |
| 7 | **Multi-agent (role decomposition)** | Workflows with distinct phases (PM/Eng/QA) | MetaGPT, AutoGen |
| 8 | **Voyager-style skill library** | Lifelong agents accumulating reusable code | Wang 2023 |
| 9 | **Self-consistency / sampling** | Reasoning tasks with verification | Wang 2022 |
| 10 | **Modular harness** (configurable components) | Game/multi-domain agents | General Modular Harness 2025 |

## Key tradeoffs

| Choice | Pro | Con |
|--------|-----|-----|
| **Pure ReAct loop** | Simple, debuggable, cheap | Drifts on long horizons; no global plan |
| **Planner-then-executor (one-shot)** | Cheap, fast | Plan brittleness; no replan on failure |
| **Iterative plan/replan** | Robust to surprises | Cost ∝ plan iterations |
| **Reflexion retry** | Costs only on failure | Needs failure signal; can loop |
| **Tree of Thoughts** | Big wins on search-y problems | N× cost; needs evaluator |
| **Graph of Thoughts** | Most general; refinement support | Engineering complexity |
| **Multi-agent (parallel)** | Specialization, parallelism | Coordination overhead, cost multiplies |
| **Multi-agent (sequential)** | Clean handoffs, debuggable | Slower; worse than parallel for independent subtasks |
| **Skill library (Voyager)** | Compounding gains over time | Skill management; mis-application risks |
| **Modular harness** | Easy to swap components | Risk of integration drift |

## Open questions on the frontier

- **When does multi-agent beat single-agent + tools?** Anthropic's recent essays argue *rarely*. Surveys show wins on heavy decomposable workflows. The threshold is not formalized.
- **How to choose between Tree-of-Thoughts and Reflexion?** ToT searches the space; Reflexion learns from failure. Both add cost — choosing remains heuristic.
- **Planner robustness**: planners hallucinate plans. PEAR (2025) is the first benchmark; still no SOTA defense.
- **Verification gates as hard or soft?** Hard gates stall on legitimate variation; soft gates miss errors. Adaptive gating is open.
- **Architectural search over harnesses**: MASS searches prompt + topology for multi-agent. Single-agent harness search (which patterns to combine) is less explored.

## Bottom line

If you're building a coding/CLI agent: ReAct + tools + Reflexion + planner over multi-step. If you're building a research/long-horizon agent: Reason-Plan-ReAct or planner+executor+supervisor with a memory layer. Skip multi-agent unless your task obviously decomposes (PM/eng/QA-style). For exotic search tasks: Tree-of-Thoughts. Avoid bolting on architectures without evidence — every layer adds cost and failure modes.
