# positronic

A personal AI-coding framework — opinionated, solo.

**What positronic does** — carries a software project from a fuzzy idea to shipped code across four concerns:

- **Product management** — surface the assumptions an idea depends on, lock them into a brief PRD, executable user journeys, drawn screens, a spec and issues, then go back weeks after launch and check whether the numbers moved.
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

You arrive with a fuzzy idea — "build X", "fix Y" — and no spec yet. Each stage writes one document the next one reads. The defining artifacts live in `definitions/`, one file per artifact type — later runs amend it in place, and git carries every version it used to be; the reports stages 11–14 produce land in `docs/audits/`.

| # | Stage | Run | Writes |
| --- | --- | --- | --- |
| 1 | Frame the problem | `define` (auto-fires) | a falsifiable hypothesis, kill criteria, a change tier, and a route |
| 2 | Research *(zero-to-one only)* | `/research-market` → `/ideate` → `/judge-idea` | `definitions/research.md`, a chosen idea |
| 3 | Lock *what & why* | `/to-prd` | `definitions/prd.md` — two pages |
| 4 | Script every journey | `/to-journeys` | `definitions/journeys.md` — steps, branches, end-state proofs |
| 5 | Design + draw the UI *(if it has one)* | `/to-mockups` | `definitions/mockups.md`, `definitions/mockups.html` |
| 6 | Lock the harness *(if custom)* | `pick-harness-shape` (+ `design-mcp-server`) | `definitions/harness.md`, `definitions/mcp-servers.md`, `definitions/runtime.md` *(placement gate)* |
| 7 | Lock the plumbing | `/to-infrastructure` | `definitions/infrastructure.md` — path, environments, gate ladder, CI/CD, infrastructure-as-code, service picks |
| 8 | Lock *how* | `/to-spec` | `definitions/spec.md` |
| 9 | Break into work | `/to-issues` | GitHub issues, tagged `afk` / `hitl` / `wave-N` |
| 10 | Build, in waves | `/run-wave` — each issue via `test-driven-dev` (+ `ui-taste`, `diagnose`) | merged code, a reconciled backlog |
| 11 | Ship | `/review-pr`, `/audit-drift`, `/audit-failure-modes` | review + drift findings |
| 12 | Go live *(first real traffic / one-way cutovers)* | `/go-live` | GO / NO-GO + ranked blockers |
| 13 | Read the result *(2–6 weeks after launch)* | `/readout` | keep / iterate / cut / pivot, `docs/audits/` |
| 14 | Clean the house *(between versions)* | `/clean-house` | cuts + deepenings, `docs/audits/` report |

When both apply, stage 5 runs before stage 6 — harness picks then slot into known surfaces. Stage 5 is itself a loop, not a gate: it picks the identity, draws it, and sends what the drawing reveals back up to stages 3–4 before redrawing.

**Not every change walks all fourteen.** The PRD's change tier decides how far a change travels — a copy fix touches no artifact at all, an internal refactor touches only the SPEC, and only a launch walks the whole chain. The ladder is in [amend-mode.md](docs/amend-mode.md).

Skip straight to the stage that fits: a bug report drops into `diagnose`, a known-good plan jumps to `/to-spec`, a finished branch goes to `/review-pr`; a service pick ("which email provider?") goes to `/to-infrastructure`; a first deployment or provider cutover goes to `/go-live`; an accreted system between versions goes to `/clean-house`.

## Skills

Organized by phase. **Invocation:** `model` = the agent auto-fires it when a prompt matches its description; `slash` = user-invoked only (zero per-turn context cost) — `/name` in Claude Code, `$name` in Codex, the `/name` workflow or ask-by-name in Antigravity, ask-by-name in Gemini CLI. Enforced by `disable-model-invocation` (Claude Code) and `agents/openai.yaml` (Codex); Antigravity and Gemini CLI have no invocation-control field, so those skills carry prompt-level guards instead. **Reads / Writes** name the artifacts each consumes and produces.

| Skill | Invocation | Phase | Reads | Writes | What it does |
| --- | --- | --- | --- | --- | --- |
| `define` | model | defining | — | — | Surface assumptions, frame a hypothesis, route to the right path |
| `research-market` | slash | defining | — | `definitions/research.md` | Mine forums + competitive landscape |
| `ideate` | slash | defining | `definitions/research.md` | `definitions/ideas.md` | Ten ranked one-pagers; you pick the winner |
| `judge-idea` | slash | defining | `definitions/ideas.md` winner / PRD / journeys / SPEC | `judgments/<timestamp>.md` | Adversarial gate: proceed, loop-back, or pivot |
| `to-prd` | slash | defining | conversation | `definitions/prd.md` | Synthesize the *what & why*, in two pages |
| `to-journeys` | slash | defining | `definitions/prd.md` | `definitions/journeys.md` | Script each journey: steps, branches, end-state proof |
| `to-mockups` | slash | defining | `definitions/prd.md`, `definitions/journeys.md` | `definitions/mockups.md`, `definitions/mockups.html` | Lock the UI's structure + visual identity, then draw every screen |
| `pick-harness-shape` | model | defining | `definitions/prd.md`, `definitions/journeys.md`, `definitions/mockups.md` | `definitions/harness.md` (+ `definitions/runtime.md` at the placement gate) | Decide + shape a custom LLM harness |
| `design-mcp-server` | model | defining | `definitions/prd.md`, `definitions/journeys.md`, `definitions/harness.md` | `definitions/mcp-servers.md` | Design an MCP server you'll build |
| `to-infrastructure` | slash | defining / anytime | PRD, `docs/selection-method.md`, live vendor pages | `definitions/infrastructure.md` | Define the dev-to-prod path, environments, the gate ladder, CI/CD, infrastructure-as-code and deploy mechanics; pick every external service via live research |
| `to-spec` | slash | defining | `definitions/prd.md`, `definitions/journeys.md`, `definitions/mockups.md`, `definitions/harness.md`, `definitions/mcp-servers.md`, `definitions/runtime.md`, `definitions/infrastructure.md` | `definitions/spec.md` | Lock the implementation contract |
| `to-issues` | slash | defining | `definitions/spec.md`, `definitions/journeys.md` | GitHub issues | Break the SPEC into `afk` / `hitl` slices, ranked into waves |
| `run-wave` | slash | implementing | GitHub issues, `definitions/spec.md`, `definitions/journeys.md` | merged code, reconciled backlog | Run one wave in parallel, then re-judge every remaining issue |
| `test-driven-dev` | model | implementing | `definitions/spec.md` | code + tests, `test-assets/` | Red-green-refactor on one issue; generates multimodal fixtures when a test needs one |
| `ui-taste` | model | implementing | `definitions/spec.md` § Product surfaces | styled UI | Apply the locked visual identity + taste rules |
| `diagnose` | model | diagnosing | — | fix + regression test | Reproduce → minimise → fix hard bugs |
| `review-pr` | slash | shipping | the diff | findings | Flag must-fix / worth-noting before shipping |
| `audit-drift` | slash | shipping | doc graph | drift report | Sweep the `definitions/` artifacts and the code for drift |
| `audit-failure-modes` | slash | shipping | the system | P0/P1/P2 list | Pre-mortem of latent failure modes |
| `go-live` | slash | operating | `definitions/infrastructure.md`, runbooks, gate scripts, the deployed environment | GO/NO-GO report | Verify the running system actually matches what `to-infrastructure` promised, before first traffic or a one-way cutover |
| `readout` | slash | operating | `definitions/prd.md` metrics, live instrumentation | `docs/audits/` readout | Weeks post-launch: did the number move? keep / iterate / cut / pivot |
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

The 18 `slash` skills ship `agents/openai.yaml` (`allow_implicit_invocation: false`) — Codex won't auto-fire them; invoke explicitly with `$name`. Floor: copy `AGENTS.md` to `~/.codex/AGENTS.md` (global) or keep it at the project root — Codex reads it natively (no `@import` support; 32 KiB default cap).

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
