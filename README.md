# positronic

A personal AI-coding framework — opinionated, solo.

**What positronic does** — three layers across the lifecycle of a software project:

- **Product management** — the `define` skill surfaces assumptions before any code is written; `/to-prd`, `/to-spec`, `/to-issues` lock them down as versioned artifacts. For zero-to-one work, an optional research arc precedes the PRD: `/research-market` → `/ideate` → `/judge-idea`.
- **Software engineering** — eight behavioral rules (below) and test-driven development (red → green → refactor) where tests verify behavior through public interfaces, not implementation details.
- **Agent harness engineering** — `pick-harness-shape` plus a reference corpus of frontier briefs (`docs/agentic-patterns/`) help pick a custom harness when it's genuinely useful (and an off-the-shelf one otherwise), then surface the load-bearing decisions.

**The behavioral floor** — eight rules Claude follows on every turn:

1. **Think Before Coding** — state assumptions, ask when uncertain, push back on overcomplication.
2. **Read Before You Write** — ground every action in actual code; verify APIs and patterns before using them.
3. **Minimum Diff** — every changed line traces to the request; minimum code for new work, surgical edits for changes.
4. **Plain Naming** — functions, modules, variables read like plain English; names describe intent.
5. **Goal-Driven Execution** — define verifiable success; loop until verified, or stop and surface what's blocking.
6. **Phase Awareness** — name the phase (defining / implementing / diagnosing / shipping) before acting.
7. **User-Facing Reliability** — show progress on operations >2s; map external failures to one-sentence actionable messages, not raw exceptions.
8. **Secret & Data Hygiene** — never commit secrets; never log credentials, PII, or auth headers.

`AGENTS.md` is read by Claude Code and [Google Antigravity](https://antigravity.codes/blog/antigravity-agents-md-guide) (since v1.20.3); other tools (Cursor, Codex) are converging on the same convention. The `skills/` system is Claude Code only — for cross-tool skill reach, use [`google-agents-cli`](#google-cloud-and-adk). Cloud lean: [Google Cloud](https://cloud.google.com/) + [Google ADK](https://adk.dev).

## A typical user journey

You arrive with a fuzzy idea — "build X", "fix Y" — and no spec yet.

1. **`define` fires automatically.** It interviews you on the problem, surfaces hidden assumptions, frames a falsifiable hypothesis, and routes you to the right pre-PRD path.
2. **`define` picks the route based on what it heard:**
   - **Zero-to-one with market uncertainty** → it prompts `/research-market` (forum + competitive evidence into `research/`) → `/ideate` (ten ranked one-pagers, you pick) → `/judge-idea` (adversarial gate; verdict is proceed, loop-back, or pivot) → `/to-prd`.
   - **Established space** → it prompts `/to-prd` directly; the research arc is skipped.
3. **If a custom LLM harness is on the table**, `pick-harness-shape` fires before `/to-spec` and walks the load-bearing decisions (substrate, loop topology, memory, tool layer, gates) — biased toward off-the-shelf when one fits.
4. **`/to-spec`** synthesizes the PRD plus harness decisions into a versioned implementation SPEC in `specs/`. **`/align-with-docs`** is an optional detour to reconcile the plan against project domain docs (CONTEXT.md, ADRs).
5. **`/to-issues`** breaks the SPEC into independently-grabbable GitHub issues, labeling each `afk` (Claude can do it solo) or `hitl` (needs you in the loop).
6. **`/run-afk-in-loop`** works through unblocked `afk` issues in parallel waves. Each issue runs through `test-driven-dev`, which auto-fires on implementation work. UI work also triggers `ui-taste`; bugs during implementation auto-fire `diagnose`.
7. **`/review-pr`** before the branch ships — flags must-fix and worth-noting items. `/audit-prompt` if the change touched an LLM agent prompt.

Skip steps when the phase is already clear: a bug report drops straight into `diagnose`; a known-good plan can jump to `/to-spec`; a finished branch can go right to `/review-pr`.

## Skills

Skills are organized by phase (per AGENTS.md §6). Invocation modes: `model-invokable` = Claude auto-fires the skill when a prompt matches its description; `slash-only` = user types `/skill-name` to invoke, zero per-turn context cost.

| Skill | Invocation | Phase | What it does |
| --- | --- | --- | --- |
| `define` | model-invokable | defining | Defining-phase orchestrator — surfaces assumptions, frames a falsifiable hypothesis, routes to the right pre-PRD path |
| `pick-harness-shape` | model-invokable | defining | Pick the harness shape for an LLM/agent system — custom when genuinely useful, off-the-shelf otherwise |
| `research-market` | slash-only | defining | Mine forums + competitive landscape into a versioned `research/` artifact |
| `ideate` | slash-only | defining | Generate, rank, and pick a product idea grounded in `research/` |
| `judge-idea` | slash-only | defining | Adversarial pass on a winner / PRD / SPEC; verdict is proceed, loop-back, or pivot |
| `to-prd` | slash-only | defining | Synthesize the current conversation into a versioned PRD in `prds/` |
| `to-spec` | slash-only | defining | Synthesize the latest PRD + harness decisions into a versioned implementation SPEC in `specs/` |
| `to-issues` | slash-only | defining | Break a plan into independently-grabbable GitHub issues; labels each `afk` or `hitl` |
| `align-with-docs` | slash-only | defining | Reconcile a plan against the project's domain docs; update CONTEXT.md / ADRs inline |
| `test-driven-dev` | model-invokable | implementing | Test-driven development with red-green-refactor |
| `ui-taste` | model-invokable | implementing | Opinionated visual rules; fires on UI work; avoids the generic, cookie-cutter look |
| `run-afk-in-loop` | slash-only | implementing | Work through all unblocked AFK issues in parallel waves |
| `diagnose` | model-invokable | diagnosing | Disciplined loop for hard bugs and performance regressions |
| `review-pr` | slash-only | shipping | Review the current branch before it ships; flags must-fix and worth-noting items |
| `audit-prompt` | slash-only | shipping | Audit an LLM agent prompt for tool-catalogue coverage, dead references, and rule sharpness |
| `add-a-skill` | slash-only | meta | Create new agent skills with proper structure |
| `github-triage` | slash-only | meta | Triage GitHub issues through a label-based state machine |
| `deepen-modules` | slash-only | meta | Find shallow modules and propose how to deepen them |

The system prompt sees `AGENTS.md` plus descriptions of `model-invokable` skills only. `slash-only` skills load on invoke — **zero per-turn context cost**.

## Layout

```text
.
├── AGENTS.md          # behavioral floor (cross-tool, always on)
├── CLAUDE.md          # @AGENTS.md import (Claude Code)
├── .claude-plugin/    # plugin.json registers skills
├── docs/              # reference corpus (frontier briefs on agentic patterns)
└── skills/               # organized by phase (defining / implementing /
    ├── defining/         #   diagnosing / shipping / meta). Each SKILL.md
    ├── implementing/     #   sets `disable-model-invocation: true` for
    ├── diagnosing/       #   slash-only; absence = auto-fires on relevant
    ├── shipping/         #   prompts.
    └── meta/
```

## AFK loop

`/to-issues` tags each issue `afk` or `hitl`. `/run-afk-in-loop` then works through all unblocked AFK issues in order — picking the next one, implementing it with `/test-driven-dev`, closing it, and looping until done.

**Unattended runs with credit-exhaustion retry:**

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-afk-loop.sh
```

Env vars: `RETRY_WAIT_SECONDS` (default 1800), `MAX_ATTEMPTS` (default 20).

## Adding a skill

Use `/add-a-skill` or follow [its template](skills/meta/add-a-skill/SKILL.md). Place the folder under the right phase (`defining/`, `implementing/`, `diagnosing/`, `shipping/`, `meta/`), pick the invocation mode via frontmatter (`disable-model-invocation: true` for slash-only; omit for auto-fires), then register the path in `.claude-plugin/plugin.json`.

## MCP servers

[MCP](https://modelcontextprotocol.io/) servers add Claude Code capabilities. Same lean-context discipline as skills: install only what you use.

| Server | Use | Install |
| --- | --- | --- |
| [Playwright](https://github.com/microsoft/playwright-mcp) | Browser automation, UI verification | `claude mcp add playwright npx '@playwright/mcp@latest'` |
| [GitHub](https://github.com/github/github-mcp-server) | Issues, PRs, repo search | See the official install guide |

Add others (Postgres, SQLite, Context7) per-project. User-level MCPs go in `~/.claude.json`; project-level in `.mcp.json`.

## Google Cloud and ADK

For Google Cloud or [Google ADK](https://adk.dev) projects, install [`google-agents-cli`](https://github.com/google/agents-cli) per-project — multi-tool by construction (Claude Code, Gemini CLI, Codex, Antigravity).

```bash
uvx google-agents-cli setup       # full CLI + skills
npx skills add google/agents-cli  # skills only
```

Skills (all prefixed `google-agents-cli-`):

| Skill | What it does |
| --- | --- |
| `workflow` | Development lifecycle, code preservation, model selection |
| `adk-code` | ADK Python API — agents, tools, orchestration, callbacks |
| `scaffold` | Project scaffolding (`create`, `enhance`, `upgrade`) |
| `eval` | Evaluation — metrics, evalsets, LLM-as-judge, trajectory |
| `deploy` | Deployment to Agent Runtime, Cloud Run, GKE, CI/CD |
| `publish` | Gemini Enterprise registration |
| `observability` | Cloud Trace, logging, third-party integrations |

[`google/adk-samples`](https://github.com/google/adk-samples): sample ADK agents in Python / Java / Go / TypeScript. Reference implementations — clone what you need; don't install as a skill.

## Install

Examples use `dformoso/positronic`; substitute your username if forked.

The two pieces install independently — most users want both.

### 1. Skills (Claude Code plugin)

```text
/plugin marketplace add dformoso/positronic
/plugin install skills@positronic
```

### 2. Behavioral floor (AGENTS.md)

Ask your coding agent to copy `AGENTS.md` (and `CLAUDE.md` if Claude Code is your primary tool) from this repo into either:

- `~/.claude/` — applies the floor globally to every project
- a project root — applies it just to that project

Both files are plain text with no dependencies; `curl` works too.

## Acknowledgments

- [Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876) — observations on LLM coding failure modes (four of the five `AGENTS.md` principles, packaged into a Claude Code skill by [forrestchang](https://github.com/forrestchang/andrej-karpathy-skills)).
- [Matt Pocock](https://github.com/mattpocock/skills) — small composable skills and the SKILL.md format with progressive disclosure.
- *Competing Against Luck* — Clayton Christensen, Taddy Hall, Karen Dillon, David Duncan. Jobs-to-be-Done methodology. Shapes how `define` frames the problem and the `/research-market` → `/ideate` arc.
- *Good Strategy / Bad Strategy* — Richard Rumelt. The strategy kernel: diagnosis → guiding policy → coherent action. Mirrored in `define`'s insistence on surfacing assumptions and naming the phase before any code is written.
- *Zero to One* — Peter Thiel. Zero-to-one product thinking and contrarian truths. Frames the zero-to-one branch in `define` that triggers the `/research-market` → `/ideate` → `/judge-idea` research arc.
- *The Lean Startup* — Eric Ries (2011). Build–Measure–Learn and the validated-learning loop. Informs `define`'s falsifiable-hypothesis framing and `/judge-idea`'s proceed / loop-back / pivot verdict.

## License

MIT — see [LICENSE](LICENSE). Upstream MIT notices preserved.
