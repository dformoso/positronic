# positronic

A personal AI-coding framework: a cross-tool behavioral floor in [`AGENTS.md`](AGENTS.md) plus skills for Claude Code. Solo, opinionated — fork to adapt.

**The behavioral floor** — five rules Claude follows on every turn:

1. **Think Before Coding** — state assumptions, ask when uncertain, push back on overcomplication.
2. **Simplicity First** — minimum code that solves the problem; no speculative features.
3. **Surgical Changes** — touch only what you must; clean up only your own mess.
4. **Goal-Driven Execution** — define verifiable success criteria; loop until met.
5. **Phase Awareness** — name the phase (defining / implementing / diagnosing / shipping) before acting.

`AGENTS.md` is read by Claude Code, [Google Antigravity](https://antigravity.codes/blog/antigravity-agents-md-guide) (since v1.20.3), and Cursor. The `skills/` system is Claude Code only — for cross-tool skill reach, use [`google-agents-cli`](#google-cloud-and-adk). Cloud lean: [Google Cloud](https://cloud.google.com/) + [Google ADK](https://adk.dev).

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

## Skills

| Skill | Bucket | What it does |
| --- | --- | --- |
| `diagnose` | model-invokable | Disciplined loop for hard bugs and performance regressions |
| `tdd` | model-invokable | Test-driven development with red-green-refactor |
| `grill-me` | model-invokable | Interview the user about a design until shared understanding |
| `terse` | slash-only | Ultra-compressed mode (~75% token savings) |
| `zoom-out` | slash-only | Step back and give broader context |
| `to-prd` | slash-only | Synthesize the current conversation into a PRD on GitHub |
| `to-issues` | slash-only | Break a plan into independently-grabbable GitHub issues; labels each `afk` or `hitl` |
| `run-afk-in-loop` | slash-only | Work through all unblocked AFK issues in order, updating `BOARD.md` at each step |
| `setup-git-guardrails` | slash-only | Install hooks that block dangerous git commands |
| `improve-codebase-architecture` | slash-only | Find shallow modules and propose how to deepen them |
| `grill-with-docs` | slash-only | Grill against domain docs; update CONTEXT.md / ADRs inline |
| `write-a-skill` | slash-only | Create new agent skills with proper structure |
| `github-triage` | dormant | Triage GitHub issues through a label-based state machine |
| `setup-pre-commit` | dormant | Set up Husky + lint-staged + Prettier pre-commit hooks |

The system prompt sees `AGENTS.md` plus descriptions of model-invokable skills only. Slash-only loads on invoke; dormant is unregistered until promoted — both cost **zero per-turn context**.

## Layout

```text
.
├── AGENTS.md          # behavioral floor (cross-tool, always on)
├── CLAUDE.md          # @AGENTS.md import (Claude Code)
├── .claude-plugin/    # plugin.json registers skills
└── skills/
    ├── model-invokable/   # auto-fires on relevant prompts
    ├── slash-only/        # disable-model-invocation: true
    └── dormant/           # unregistered, inert
```

## AFK loop

`/to-issues` tags each issue `afk` or `hitl`. `/run-afk-in-loop` then works through all unblocked AFK issues in order — picking the next one, implementing it with `/tdd`, closing it, and looping until done.

**Progress board** — `BOARD.md` at the project root is a Mermaid dependency graph updated on every state change. Open it in VS Code with Cmd+K V for a live split-pane view. Nodes show issue number, title, type, deliverable, and acceptance criteria; edges show blocking relationships; colors show status (done / active / ready / blocked / HITL).

**Unattended runs with credit-exhaustion retry:**

```bash
bash skills/slash-only/run-afk-in-loop/scripts/run-afk-loop.sh
```

Env vars: `RETRY_WAIT_SECONDS` (default 1800), `MAX_ATTEMPTS` (default 20).

## Adding or promoting a skill

Use `/write-a-skill` or follow [its template](skills/slash-only/write-a-skill/SKILL.md). To promote a dormant skill: move its folder to `model-invokable/` (auto-fires) or `slash-only/` (ensure `disable-model-invocation: true` in frontmatter), then add the path to `.claude-plugin/plugin.json`.

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

## Acknowledgments

- [Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876) — observations on LLM coding failure modes (four of the five `AGENTS.md` principles, packaged into a Claude Code skill by [forrestchang](https://github.com/forrestchang/andrej-karpathy-skills)).
- [Matt Pocock](https://github.com/mattpocock/skills) — small composable skills and the SKILL.md format with progressive disclosure.

## License

MIT — see [LICENSE](LICENSE). Upstream MIT notices preserved.
