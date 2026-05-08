# Frontier Documents Index

Two versions of each document: a 2-page **brief** and a longer **detailed** version. All ranking and tradeoffs are based on the 54 papers in `../`.

## The five topics

| # | Topic | Brief | Detailed |
|---|-------|-------|----------|
| 1 | Agentic Harness Engineering | [Brief](01_harness_engineering_brief.md) | [Detailed](01_harness_engineering_detailed.md) |
| 2 | Role Design & Multi-Agent Specialization | [Brief](02_role_design_brief.md) | [Detailed](02_role_design_detailed.md) |
| 3 | Context Management & Memory | [Brief](03_context_management_brief.md) | [Detailed](03_context_management_detailed.md) |
| 4 | Prompt Management & Optimization | [Brief](04_prompt_management_brief.md) | [Detailed](04_prompt_management_detailed.md) |
| 5 | Harness Architectures | [Brief](05_harness_architectures_brief.md) | [Detailed](05_harness_architectures_detailed.md) |

## Reading order suggestions

**For a quick orientation (~30 min)**: read all five briefs in order.

**For practitioners building an agent**: detailed #1 (engineering) → detailed #5 (architectures) → detailed #3 (memory) → detailed #4 (prompts) → detailed #2 (roles). The first two cover what to build; the next two cover how to maintain it; the last is the most contested area.

**For researchers**: detailed #3 (context/memory — most active research area) → detailed #1 (engineering — newest sub-field) → others.

**For decision-makers**: briefs only. Each ends with a "bottom line" paragraph.

## Where the rankings come from

Each doc ranks techniques by:

1. **Empirical evidence** in the 2024-2026 papers (cited inline).
2. **Adoption signal**: which patterns appear across multiple recent papers / production systems.
3. **Performance datapoints**: specific benchmark numbers where available (SWE-Bench, HumanEval, GSM8K, etc.).
4. **Tradeoff clarity**: what's gained vs. what's lost.

Open questions sections flag where rankings would shift if a particular question gets answered.

## Cross-references

The briefs and detailed docs are paired but standalone. The detailed versions cite specific papers inline; the briefs synthesize without overwhelming citation density.
