# positronic

A personal AI-coding framework — opinionated, solo.

**What positronic does** — carries a software project from a fuzzy idea to shipped code across four concerns:

- **Product management** — surface the assumptions an idea depends on, then lock them into versioned PRDs, specs, and issues.
- **Software engineering** — a behavioral floor (below) plus test-driven development that verifies behavior through public interfaces, not implementation details.
- **Agent-harness engineering** — decide whether a custom LLM/agent harness is warranted (the cut-line is reliability beyond conversational use), then lock its load-bearing shape.
- **Product-surface engineering** — for products with a UI, lock the structure and visual identity once, before any screen is built.

**The behavioral floor** — eight rules Claude follows on every turn:

1. **Think Before Coding** — state assumptions, ask when uncertain, push back on overcomplication.
2. **Read Before You Write** — ground every action in actual code; verify APIs and patterns before using them.
3. **Minimum Diff** — every changed line traces to the request; minimum code for new work, surgical edits for changes.
4. **Plain Naming** — functions, modules, variables read like plain English; names describe intent.
5. **Goal-Driven Execution** — define verifiable success; loop until verified, or stop and surface what's blocking.
6. **Phase Awareness** — name the phase (defining / implementing / diagnosing / shipping) before acting.
7. **User-Facing Reliability** — show progress on operations >2s; map external failures to one-sentence actionable messages, not raw exceptions.
8. **Secret & Data Hygiene** — never commit secrets; never log credentials, PII, or auth headers.

`AGENTS.md` is read by Claude Code and [Google Antigravity](https://antigravity.codes/blog/antigravity-agents-md-guide) (since v1.20.3); other tools (Cursor, Codex) are converging on the same convention. The `skills/` system is Claude Code only.

## A typical user journey

You arrive with a fuzzy idea — "build X", "fix Y" — and no spec yet. Each stage writes a versioned artifact the next one reads:

| # | Stage | Run | Writes |
| --- | --- | --- | --- |
| 1 | Frame the problem | `define` (auto-fires) | a falsifiable hypothesis + a route |
| 2 | Research *(zero-to-one only)* | `/research-market` → `/ideate` → `/judge-idea` | `definitions/research/`, a chosen idea |
| 3 | Lock *what & why* | `/to-prd` | `definitions/prds/` |
| 4 | Lock the UI *(if it has one)* | `pick-ui-surfaces` | `definitions/surfaces/` |
| 5 | Lock the harness *(if custom)* | `pick-harness-shape` (+ `design-mcp-server`) | `definitions/harness/`, `definitions/mcp-servers/` |
| 6 | Lock *how* | `/to-spec` | `definitions/specs/` |
| 7 | Break into work | `/to-issues` | GitHub issues, tagged `afk` / `hitl` |
| 8 | Build | `/run-afk-in-loop` → `test-driven-dev` (+ `ui-taste`, `generate-test-assets`, `diagnose`) | merged code |
| 9 | Ship | `/review-pr`, `/audit-drift`, `/audit-failure-modes` | review + drift findings |

When both apply, stage 4 runs before stage 5 — harness picks then slot into known surfaces. Skip straight to the stage that fits: a bug report drops into `diagnose`, a known-good plan jumps to `/to-spec`, a finished branch goes to `/review-pr`.

## Skills

Organized by phase. **Invocation:** `model` = Claude auto-fires it when a prompt matches its description; `slash` = you type `/name` (zero per-turn context cost). **Reads / Writes** name the versioned artifacts each consumes and produces.

| Skill | Invocation | Phase | Reads | Writes | What it does |
| --- | --- | --- | --- | --- | --- |
| `define` | model | defining | — | — | Surface assumptions, frame a hypothesis, route to the right path |
| `research-market` | slash | defining | — | `definitions/research/` | Mine forums + competitive landscape |
| `ideate` | slash | defining | `definitions/research/` | — | Ten ranked one-pagers; you pick the winner |
| `judge-idea` | slash | defining | winner / PRD / SPEC | — | Adversarial gate: proceed, loop-back, or pivot |
| `to-prd` | slash | defining | conversation | `definitions/prds/` | Synthesize the *what & why* |
| `pick-ui-surfaces` | model | defining | `definitions/prds/` | `definitions/surfaces/` | Lock the UI's structure + visual identity |
| `pick-harness-shape` | model | defining | `definitions/prds/`, `definitions/surfaces/` | `definitions/harness/` | Decide + shape a custom LLM harness |
| `design-mcp-server` | model | defining | `definitions/prds/`, `definitions/harness/` | `definitions/mcp-servers/` | Design an MCP server you'll build |
| `to-spec` | slash | defining | `definitions/prds/`, `definitions/harness/`, `definitions/surfaces/`, `definitions/mcp-servers/` | `definitions/specs/` | Lock the implementation contract |
| `to-issues` | slash | defining | `definitions/specs/` | GitHub issues | Break the SPEC into `afk` / `hitl` issues |
| `test-driven-dev` | model | implementing | `definitions/specs/` | code + tests | Red-green-refactor on one issue |
| `ui-taste` | model | implementing | `definitions/surfaces/` | styled UI | Apply the locked visual identity + taste rules |
| `generate-test-assets` | model | implementing | `definitions/specs/`, test plan | `test-assets/` | Generate multimodal test fixtures with Gemini; route load-bearing checks to the human |
| `run-afk-in-loop` | slash | implementing | issues, `definitions/specs/` | merged code | Work the AFK backlog in parallel waves |
| `diagnose` | model | diagnosing | — | fix + regression test | Reproduce → minimise → fix hard bugs |
| `review-pr` | slash | shipping | the diff | findings | Flag must-fix / worth-noting before shipping |
| `audit-drift` | slash | shipping | doc graph | drift report | Sweep PRDs/SPECs/ADRs for drift |
| `audit-failure-modes` | slash | shipping | the system | P0/P1/P2 list | Pre-mortem of latent failure modes |
| `github-triage` | slash | meta | GitHub issues | labels | Label-based triage state machine |
| `deepen-modules` | slash | meta | code | proposals | Find shallow modules and deepen them |

The system prompt sees `AGENTS.md` plus the descriptions of `model` skills only; `slash` skills load on invoke.

## AFK loop

`/to-issues` tags each issue `afk` or `hitl`. `/run-afk-in-loop` then works through all unblocked AFK issues in order — picking the next one, implementing it with `/test-driven-dev`, closing it, and looping until done.

**Unattended runs with credit-exhaustion retry** — run from your positronic checkout (or by absolute path), with your target project as the current directory:

```bash
bash skills/implementing/run-afk-in-loop/scripts/run-afk-loop.sh
```

Env vars: `RETRY_WAIT_SECONDS` (default 1800), `MAX_ATTEMPTS` (default 20).

## MCP servers

[MCP](https://modelcontextprotocol.io/) servers add Claude Code capabilities. Same lean-context discipline as skills: install only what you use.

| Server | Use | Install |
| --- | --- | --- |
| [Playwright](https://github.com/microsoft/playwright-mcp) | Browser automation, UI verification | `claude mcp add playwright npx '@playwright/mcp@latest'` |
| [GitHub](https://github.com/github/github-mcp-server) | Issues, PRs, repo search | See the official install guide |

Add others (Postgres, SQLite, Context7) per-project. User-level MCPs go in `~/.claude.json`; project-level in `.mcp.json`.

## Install

Examples use `dformoso/positronic`; substitute your username if forked.

The two pieces install independently — most users want both.

### 1. Skills (Claude Code plugin)

```text
/plugin marketplace add dformoso/positronic
/plugin install skills@positronic
```

This also ships the `docs/agentic-patterns/` reference corpus — several skills cite it at runtime via `${CLAUDE_SKILL_DIR}`-resolved paths, so no separate copy is needed.

### 2. Behavioral floor (AGENTS.md)

Ask your coding agent to copy `AGENTS.md` (and `CLAUDE.md` if Claude Code is your primary tool) from this repo into either:

- `~/.claude/` — applies the floor globally to every project
- a project root — applies it just to that project

Both files are plain text with no dependencies; `curl` works too.

## Acknowledgments

- [Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876) — observations on LLM coding failure modes that seeded the `AGENTS.md` floor, packaged into a skill by [forrestchang](https://github.com/forrestchang/andrej-karpathy-skills).
- [Matt Pocock](https://github.com/mattpocock/skills) — the small composable SKILL.md format with progressive disclosure.
- Jobs-to-be-Done (*Competing Against Luck*), the strategy kernel (*Good Strategy / Bad Strategy*), zero-to-one thinking (*Zero to One*), and Build–Measure–Learn (*The Lean Startup*) — shape how `define` and the `/research-market` → `/ideate` arc frame the problem.

## License

MIT — see [LICENSE](LICENSE). Upstream MIT notices preserved.
