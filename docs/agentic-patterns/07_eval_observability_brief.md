# Frontier: Evaluation, Observability & Optimization — Brief

**Scope.** Once an agent runs without you watching, the *run* — the trajectory — becomes the unit of work: you instrument it, score it, monitor it, and learn from it. This is the operating loop. Distinct from harness engineering (brief 01, which builds the thing) and harness architectures (brief 05, the patterns it's built from). Harness changes swing task completion up to 6× on the same model (brief 01) — but the swing is invisible without an eval signal, so this layer is the instrument that makes every other harness decision measurable. It is also the layer the enterprise platforms (Vertex/Gemini Agent Eval, Google ADK) have productized first.

## State of the frontier

Three things crystallized in 2025-2026:

1. **Telemetry has a standard: OpenTelemetry GenAI semantic conventions.** Trajectories — model calls, tool calls, agent steps, token and cost — are emitted as OTEL spans, and Google ADK is OTEL-native. The bespoke trajectory log is obsolete the way the bespoke tool protocol became obsolete with MCP (brief 06): every viewer, backend, and eval harness already speaks it.
2. **Eval moved from final-answer to trajectory to live traffic.** Vertex/Gemini Agent Eval scores hallucination, tool-use accuracy, and groundedness — not just task success. Multi-turn auto-raters grade whole conversations; simulation generates synthetic-persona scenarios; online eval samples production continuously. The graded unit moved from "answer" → "trajectory" → "live stream."
3. **Optimization is closing the loop.** Meta-Harness / AutoHarness (brief 01) treat the harness as a search target; Gemini's Agent Optimizer clusters real production failures and proposes refined instructions. The bottleneck is uniform — optimization is only ever as good as the eval signal feeding it.

## Ranked techniques (by impact / adoption / evidence)

| Rank | Technique | Why it matters | Evidence |
|---|---|---|---|
| 1 | **Trajectory telemetry as OTEL spans** | You cannot eval, debug, or optimize what you can't replay | OTEL GenAI conventions; OpenHands; ADK |
| 2 | **Held-out eval set + explicit success signal** | Per-task metrics don't transfer between harnesses — you must own the signal and run it in CI before any change | the 6× claim (brief 01) |
| 3 | **LLM-as-judge on trajectory dimensions** (tool-path, groundedness, hallucination) | A right answer reached via a wrong path fails under load; final-answer match misses it | Gemini Agent Eval; LLM-as-judge lit |
| 4 | **Reflexion-style in-loop repair** | Turns a failure into next-attempt context | Shinn 2023 (brief 05) |
| 5 | **Production monitoring + alert thresholds** (cost-per-success, trajectory length, gate hit-rate, drift) | Always-on agents fail silently otherwise | production agents |
| 6 | **Multi-turn / simulation eval** (synthetic personas) | Single-turn tests miss conversational drift | Gemini auto-raters |
| 7 | **Online eval** (live-traffic sampling) | The only signal that sees real inputs | Vertex online eval |
| 8 | **Retrospective failure clustering → harness deltas** | Learns the failure modes instead of guessing them | Gemini Agent Optimizer; AutoHarness |

## Key tradeoffs

| Choice | Pro | Con |
|---|---|---|
| **Exact-match eval** | Cheap, deterministic, no judge variance | Only works where outcomes are exact; misses path quality |
| **LLM-as-judge** | Scores fuzzy dimensions (groundedness, tone) | The judge has its own variance and bias; needs a lower-temp, cheaper model than the agent it grades |
| **Offline held-out set** | Reproducible; gates changes pre-ship | Drifts from the real input distribution over time |
| **Online (live-traffic) eval** | Sees real inputs; catches drift early | Cost + privacy surface; needs sampling + redaction |
| **OTEL standard spans** | Every viewer / backend reads it for free | Conventions still stabilizing; attribute names shift between versions |
| **Bespoke trajectory log** | Full control of shape | A viewer you now have to maintain forever |
| **Prospective audit (pre-mortem)** | Catches failures before any user does | Guesses; can't see what actually breaks in production |
| **Retrospective clustering (post-mortem)** | Reads failure modes off real logs | Needs production volume + the telemetry from rank 1 |

## Open questions on the frontier

- **Eval-signal transfer.** Per-task metrics often don't survive a harness change; harness-level evals are still open (brief 01).
- **Who grades the grader?** LLM-as-judge reliability, bias, and self-preference are unresolved; ensembles and rubric anchoring help but don't close it.
- **OTEL GenAI conventions are still moving** — span and attribute names differ across versions; pinning matters.
- **Optimizer overfitting.** A cheap eval lets an optimizer game the metric instead of improving the agent — the AutoHarness risk, restated for production loops.
- **Governance at scale.** Agent registry, cryptographic agent identity, and partner certification are enterprise primitives with no agreed open standard. Whether single-team systems need any of the machinery — versus just the principles (identity, gated irreversible actions, screened input) — is unsettled.

## Bottom line

If you're building an agent today: instrument the trajectory as OTEL spans *before* tuning anything; define one verifiable success signal and a small held-out set you run in CI; score tool-path and groundedness with a cheap verifier-LM, not just final-answer match. If it's always-on, alert on cost-per-success and drift, not just crashes.

If you're optimizing for the next 12 months: close the loop — cluster real production failures into concrete harness deltas (a sharpened prompt, a new gate, a new failure-taxonomy row). Adopt the governance *principles* as harness decisions and skip the enterprise platform unless you're genuinely multi-tenant. The scarce resource is never the topology — it's the eval signal everything else stands on.
