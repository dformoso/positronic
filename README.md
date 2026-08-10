# positronic

A personal AI-coding framework — opinionated, solo.

**What positronic does** — carries a software project from a fuzzy idea to shipped code across four concerns:

- **Product management** — surface the assumptions an idea depends on, then lock them into versioned PRDs, specs, and issues.
- **Software engineering** — a behavioral floor (below) plus test-driven development that verifies behavior through public interfaces, not implementation details.
- **Agent-harness engineering** — decide whether a custom LLM/agent harness is warranted (the cut-line is reliability beyond conversational use), then lock its load-bearing shape.
- **Product-surface engineering** — for products with a UI, lock the structure and visual identity once, before any screen is built.

**The behavioral floor** — nine rules the coding agent follows on every turn:

1. **Think Before Coding** — state assumptions, ask when uncertain, push back on overcomplication.
2. **Read Before You Write** — ground every action in actual code; verify APIs and patterns before using them.
3. **Minimum Diff** — every changed line traces to the request; minimum code for new work, surgical edits for changes.
4. **Plain Naming, Plain Language** — names read like plain English, and so does every sentence a person reads: concrete before abstract, jargon glossed on first use.
5. **Goal-Driven Execution** — define verifiable success; loop until verified, or stop and surface what's blocking.
6. **Phase Awareness** — name the phase (defining / implementing / diagnosing / shipping / operating / maintaining) before acting.
7. **User-Facing Reliability** — show progress on operations >2s; map external failures to one-sentence actionable messages, not raw exceptions.
8. **Secret & Data Hygiene** — never commit secrets; never log credentials, PII, or auth headers.
9. **Parallel by Default** — split independent work, fan out agents at once, coalesce the results, re-wave until done.

`AGENTS.md` is read natively by Claude Code (via `CLAUDE.md`'s import), Codex, and [Google Antigravity](https://antigravity.codes/blog/antigravity-agents-md-guide); Gemini CLI reads it once `context.fileName` is set (see Install). The `skills/` system follows the open [Agent Skills](https://agentskills.io) standard — flat `skills/<name>/SKILL.md` folders — and works in all four tools; the in-repo `.agents/skills` symlink makes them discoverable zero-config when this repo itself is opened.

## A typical user journey

You arrive with a fuzzy idea — "build X", "fix Y" — and no spec yet. Each stage writes a versioned artifact the next one reads:

| # | Stage | Run | Writes |
| --- | --- | --- | --- |
| 1 | Frame the problem | `define` (auto-fires) | a falsifiable hypothesis + a route |
| 2 | Research *(zero-to-one only)* | `/research-market` → `/ideate` → `/judge-idea` | `definitions/research/`, a chosen idea |
| 3 | Lock *what & why* | `/to-prd` | `definitions/prds/` |
| 4 | Lock the UI *(if it has one)* | `pick-ui-surfaces` | `definitions/surfaces/` |
| 5 | Lock the harness *(if custom)* | `pick-harness-shape` (+ `design-mcp-server`) | `definitions/harness/`, `definitions/mcp-servers/`, `definitions/runtime/` *(placement gate)* |
| 6 | Lock *how* | `/to-spec` | `definitions/specs/` |
| 7 | Break into work | `/to-issues` | GitHub issues, tagged `afk` / `hitl` |
| 8 | Build | `test-driven-dev` (+ `ui-taste`, `generate-test-assets`, `diagnose`) | merged code |
| 9 | Ship | `/review-pr`, `/audit-drift`, `/audit-failure-modes` | review + drift findings |
| 10 | Go live *(first real traffic / one-way cutovers)* | `/go-live` | GO / NO-GO + ranked blockers |
| 11 | Clean the house *(between versions)* | `/clean-house` | cuts + deepenings, `docs/audits/` report |

When both apply, stage 4 runs before stage 5 — harness picks then slot into known surfaces. Skip straight to the stage that fits: a bug report drops into `diagnose`, a known-good plan jumps to `/to-spec`, a finished branch goes to `/review-pr`; a service pick ("which email provider?") goes to `/pick-cloud-services`; a first deployment or provider cutover goes to `/go-live`; an accreted system between versions goes to `/clean-house`.

## Skills

Organized by phase. **Invocation:** `model` = the agent auto-fires it when a prompt matches its description; `slash` = user-invoked only (zero per-turn context cost) — `/name` in Claude Code, `$name` in Codex, the `/name` workflow or ask-by-name in Antigravity, ask-by-name in Gemini CLI. Enforced by `disable-model-invocation` (Claude Code) and `agents/openai.yaml` (Codex); Antigravity and Gemini CLI have no invocation-control field, so those skills carry prompt-level guards instead. **Reads / Writes** name the versioned artifacts each consumes and produces.

| Skill | Invocation | Phase | Reads | Writes | What it does |
| --- | --- | --- | --- | --- | --- |
| `define` | model | defining | — | — | Surface assumptions, frame a hypothesis, route to the right path |
| `research-market` | slash | defining | — | `definitions/research/` | Mine forums + competitive landscape |
| `ideate` | slash | defining | `definitions/research/` | `definitions/ideas/` | Ten ranked one-pagers; you pick the winner |
| `judge-idea` | slash | defining | `definitions/ideas/` winner / PRD / SPEC | — | Adversarial gate: proceed, loop-back, or pivot |
| `to-prd` | slash | defining | conversation | `definitions/prds/` | Synthesize the *what & why* |
| `pick-ui-surfaces` | model | defining | `definitions/prds/` | `definitions/surfaces/` | Lock the UI's structure + visual identity |
| `pick-harness-shape` | model | defining | `definitions/prds/`, `definitions/surfaces/` | `definitions/harness/` (+ `definitions/runtime/` at the placement gate) | Decide + shape a custom LLM harness |
| `design-mcp-server` | model | defining | `definitions/prds/`, `definitions/harness/` | `definitions/mcp-servers/` | Design an MCP server you'll build |
| `pick-cloud-services` | slash | defining / anytime | PRD (greenfield), `docs/selection-method.md`, live vendor pages | `docs/adr/` decision records | Pick any external/cloud service via live research; on greenfield, decide the dev-to-prod path first |
| `to-spec` | slash | defining | `definitions/prds/`, `definitions/harness/`, `definitions/surfaces/`, `definitions/mcp-servers/`, `definitions/runtime/` | `definitions/specs/` | Lock the implementation contract |
| `to-issues` | slash | defining | `definitions/specs/` | GitHub issues | Break the SPEC into `afk` / `hitl` issues |
| `test-driven-dev` | model | implementing | `definitions/specs/` | code + tests | Red-green-refactor on one issue |
| `ui-taste` | model | implementing | `definitions/surfaces/` | styled UI | Apply the locked visual identity + taste rules |
| `generate-test-assets` | model | implementing | `definitions/specs/`, test plan | `test-assets/` | Generate multimodal test fixtures with Gemini; route load-bearing checks to the human |
| `diagnose` | model | diagnosing | — | fix + regression test | Reproduce → minimise → fix hard bugs |
| `review-pr` | slash | shipping | the diff | findings | Flag must-fix / worth-noting before shipping |
| `audit-drift` | slash | shipping | doc graph | drift report | Sweep PRDs/SPECs/ADRs for drift |
| `audit-failure-modes` | slash | shipping | the system | P0/P1/P2 list | Pre-mortem of latent failure modes |
| `go-live` | slash | operating | runbooks, gate scripts, the deployed environment | GO/NO-GO report | Evidence gate before first real traffic or a one-way cutover |
| `github-triage` | slash | meta | GitHub issues | labels | Label-based triage state machine |
| `clean-house` | slash | maintaining | doc graph, code | cuts, deepenings, `docs/audits/` report | Question → delete → deepen → accelerate → automate, in rounds until dry |
| `improve-readability` | slash | maintaining / anytime | code, tests, `CONTEXT.md`, git churn | smaller code, stronger tests, `docs/audits/` report | Fresh-eyes confusion log → checklist sweep → cut needless code, comments and docs, rework the tests, until dry |

The system prompt sees `AGENTS.md` plus the descriptions of `model` skills only; `slash` skills load on invoke.

## MCP servers

[MCP](https://modelcontextprotocol.io/) servers add capabilities to any of the four tools. Same lean-context discipline as skills: install only what you use.

| Server | Use | Install (Claude Code) |
| --- | --- | --- |
| [Playwright](https://github.com/microsoft/playwright-mcp) | Browser automation, UI verification | `claude mcp add playwright npx '@playwright/mcp@latest'` |
| [GitHub](https://github.com/github/github-mcp-server) | Issues, PRs, repo search | See the official install guide |

Add others (Postgres, SQLite, Context7) per-project. Claude Code: user-level MCPs go in `~/.claude.json`, project-level in `.mcp.json`. Codex: `~/.codex/config.toml`. Antigravity: MCP settings UI. Gemini CLI: `gemini mcp add`.

## Install

Examples use `dformoso/positronic`; substitute your username if forked.

Two pieces install independently — the skills and the behavioral floor (`AGENTS.md`) — most users want both. Each skill cites the `docs/agentic-patterns/` briefs, shared method docs, and sibling skills via `${SKILL_DIR}`-relative paths (`${SKILL_DIR}` = the skill's own directory); these resolve through symlinks, so prefer symlink installs over copies. A deeper detailed tier (indexed in [INDEX.md](docs/agentic-patterns/INDEX.md)) serves human deep-dives.

### Claude Code

```text
/plugin marketplace add dformoso/positronic
/plugin install skills@positronic
```

On an existing install, run `/plugin marketplace update positronic` before `/plugin update skills@positronic` so the flattened `skills/` layout is picked up.

Floor: copy `AGENTS.md` + `CLAUDE.md` into `~/.claude/` (global) or the project root.

### Codex

```bash
codex plugin marketplace add dformoso/positronic
```

Or clone and symlink (also serves Gemini CLI; only if `~/.agents/skills` isn't already in use — otherwise symlink individual skill folders):

```bash
git clone https://github.com/dformoso/positronic.git
ln -s "$(pwd)/positronic/skills" ~/.agents/skills
```

The 14 `slash` skills ship `agents/openai.yaml` (`allow_implicit_invocation: false`) — Codex won't auto-fire them; invoke explicitly with `$name`. Floor: copy `AGENTS.md` to `~/.codex/AGENTS.md` (global) or keep it at the project root — Codex reads it natively (no `@import` support; 32 KiB default cap).

### Antigravity

```bash
git clone https://github.com/dformoso/positronic.git
ln -s "$(pwd)/positronic/skills" ~/.gemini/config/skills   # global
# or per-project: ln -s <repo>/skills <project>/.agents/skills
```

Workflows: copy the stubs you want from this repo's `.agents/workflows/` into your project's `.agents/workflows/` (or `~/.gemini/antigravity/global_workflows/`) to invoke the `slash` skills as `/name`. Floor: `AGENTS.md` at the project root is read natively. Antigravity has no per-skill invocation control — the `slash` skills carry prompt-level guards instead.

### Gemini CLI

Served by the same `~/.agents/skills` symlink as Codex, or register without moving: `/skills link <repo>/skills`. Floor: add to `~/.gemini/settings.json`:

```json
{ "context": { "fileName": ["AGENTS.md", "GEMINI.md"] } }
```

Avoid `gemini skills install` (copy mode): copies lose the shared `docs/agentic-patterns/` corpus and cross-skill references — symlink instead.

### Notes

- The in-repo `.agents/skills` symlink makes the repo itself discoverable when opened in Codex / Antigravity / Gemini CLI. Windows checkouts without `core.symlinks` see a plain text file there — harmless.
- No `GEMINI.md` ships on purpose: Antigravity gives `GEMINI.md` precedence over `AGENTS.md`, so a stub would shadow the real floor.

## Acknowledgments

- [Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876) — observations on LLM coding failure modes that seeded the `AGENTS.md` floor, packaged into a skill by [forrestchang](https://github.com/forrestchang/andrej-karpathy-skills).
- [Matt Pocock](https://github.com/mattpocock/skills) — the small composable SKILL.md format with progressive disclosure.
- Jobs-to-be-Done (*Competing Against Luck*), the strategy kernel (*Good Strategy / Bad Strategy*), zero-to-one thinking (*Zero to One*), and Build–Measure–Learn (*The Lean Startup*) — shape how `define` and the `/research-market` → `/ideate` arc frame the problem.

## License

MIT — see [LICENSE](LICENSE). Upstream MIT notices preserved.
