# positronic

A personal AI-coding framework. Karpathy's behavioral principles as the always-on floor (in `AGENTS.md`, the cross-tool standard read by Claude Code, Google Antigravity, and Cursor), a curated set of Pocock-style skills on top for Claude Code, and a `dormant/` parking lot for skills kept around but not active.

**Cloud lean:** built for Google Cloud and [Google ADK](https://adk.dev). See [Google Cloud and ADK](#google-cloud-and-adk) below.

**Quick install (skills only, from inside Claude Code):**

```text
/plugin marketplace add <you>/positronic
/plugin install skills@positronic
```

For the full framework (skills + behavioral floor), see [Install](#install) below.

## Layout

```text
.
├── AGENTS.md                              # behavioral floor (cross-tool, always on)
├── CLAUDE.md                              # one-line `@AGENTS.md` import (for Claude Code)
├── .claude-plugin/plugin.json             # registers active skills (Claude Code only)
└── skills/                                # Claude Code only
    ├── model-invokable/                   # auto-fires on relevant prompts
    │   ├── diagnose/
    │   ├── tdd/
    │   ├── grill-me/
    │   └── write-a-skill/
    ├── slash-only/                        # disable-model-invocation: true
    │   ├── caveman/
    │   ├── zoom-out/
    │   ├── to-prd/
    │   ├── to-issues/
    │   └── git-guardrails-claude-code/
    └── dormant/                           # unregistered, inert
        ├── grill-with-docs/
        ├── improve-codebase-architecture/
        ├── github-triage/
        ├── migrate-to-shoehorn/
        ├── setup-pre-commit/
        └── scaffold-exercises/
```

The system prompt only ever sees `AGENTS.md` plus the `description` fields of skills listed in `plugin.json`. `dormant/` costs zero context until you promote a skill into a registered bucket.

## Multi-tool support

`AGENTS.md` is a cross-tool convention now read by Claude Code, [Google Antigravity](https://antigravity.codes/blog/antigravity-agents-md-guide) (since v1.20.3, March 2026), and Cursor. The repo is structured so the same behavioral floor reaches every tool:

| Tool | What it reads |
| --- | --- |
| Claude Code | `CLAUDE.md` (one-line `@AGENTS.md` import) + `skills/` registered in `.claude-plugin/plugin.json` |
| Google Antigravity | `AGENTS.md`. Optionally add a `GEMINI.md` next to it for Antigravity-specific overrides (Antigravity gives `GEMINI.md` higher priority than `AGENTS.md`). |
| Cursor | `AGENTS.md`. Add `.cursor/rules/` for Cursor-specific overrides. |

The `skills/` system is Claude-Code-specific (relies on the SKILL.md frontmatter format and Claude Code's skill picker). Other tools won't auto-load them; if you want a workflow from a skill available everywhere, lift its content into `AGENTS.md` or a tool-specific override file.

## Install

Two paths, depending on whether you want the full framework or just the skills:

### Full framework — clone as your user-level Claude Code config

```bash
git clone https://github.com/<you>/positronic.git ~/.claude
```

You get the behavioral floor (`AGENTS.md` via `CLAUDE.md` import) **and** the six registered skills. If `~/.claude` already exists, clone elsewhere and selectively merge.

### Skills only — install as a Claude Code plugin

From within Claude Code:

```text
/plugin marketplace add <you>/positronic
/plugin install skills@positronic
```

One-time, per-user — once installed, the skills are available across all projects without per-project setup. **Caveat:** plugins only register what's declared in `plugin.json` (skills, hooks, agents, MCP servers); they do **not** load `AGENTS.md`. If you also want the behavioral floor, use the user-level clone above instead, or copy `AGENTS.md` into your own `~/.claude/CLAUDE.md`.

## Activating a dormant skill

1. Move the skill folder out of `dormant/` into the right bucket:
   - `model-invokable/` if it should auto-fire on relevant prompts
   - `slash-only/` if it should only run on `/skill-name` (also add `disable-model-invocation: true` to its frontmatter)
2. Add its path to the `skills` array in `.claude-plugin/plugin.json`.

## Adding a new skill

Use the `write-a-skill` skill itself, or follow the template in [skills/model-invokable/write-a-skill/SKILL.md](skills/model-invokable/write-a-skill/SKILL.md). New skills must not contradict the five principles in `AGENTS.md`.

## MCP servers

[Model Context Protocol](https://modelcontextprotocol.io/) servers add capabilities to Claude Code (browser automation, GitHub access, database queries, etc.). Same lean-context discipline as skills: install only what you actively use.

### Recommended starter set

| Server | Use | Install |
| --- | --- | --- |
| **[Playwright](https://github.com/microsoft/playwright-mcp)** | Browser automation, UI verification, end-to-end testing | `claude mcp add playwright npx '@playwright/mcp@latest'` |
| **[GitHub](https://github.com/github/github-mcp-server)** | Issues, PRs, repo search, triage | See the official install guide — supports OAuth and token auth |

The Playwright MCP exposes ~26 tools (~3,600 tokens of schema). Claude Code's MCP Tool Search lazy-loads them, but it's still the heaviest browser MCP — switch to a lighter alternative like Playwriter only if you hit context pressure.

### Add as needs arise

- **Database MCPs** (Postgres, SQLite) — install per-project when working on a database-backed app. Don't carry globally.
- **Docs MCPs** (e.g. Context7) — useful if you hit "this API doesn't exist" hallucinations on third-party libraries.
- **Sequential Thinking** — optional; Claude's extended thinking already covers most of what it offers.

### Where MCP config lives

- **User-level** (all projects): `claude mcp add <name> ...` writes to `~/.claude.json`.
- **Project-level** (committed): create `.mcp.json` in the project root for MCPs specific to that project. Keep secrets out of the file — use env vars or `claude mcp add` per-developer.

### Curation principle

Each server costs picker context, even with Tool Search. Don't install MCPs you won't use. Skip MCPs that duplicate Claude Code built-ins (filesystem, basic shell). One server per capability — tool name collisions confuse the picker.

## Google Cloud and ADK

This framework leans toward [Google Cloud](https://cloud.google.com/) for deployment and [Google ADK](https://adk.dev) for custom agent harnesses. For projects that need either, install [`google-agents-cli`](https://github.com/google/agents-cli) — a CLI plus a set of skills your coding agent uses end-to-end.

### Install agents-cli

Full CLI + skills (recommended):

```bash
uvx google-agents-cli setup
```

Skills only (skip the CLI):

```bash
npx skills add google/agents-cli
```

Install per project — same lean-context discipline as MCP servers. Don't carry globally if you don't need it on every project.

### Skills

| Skill | What it covers |
| --- | --- |
| `google-agents-cli-workflow` | Development lifecycle, code preservation, model selection |
| `google-agents-cli-adk-code` | ADK Python API — agents, tools, orchestration, callbacks, state |
| `google-agents-cli-scaffold` | Project scaffolding (`create`, `enhance`, `upgrade`) |
| `google-agents-cli-eval` | Evaluation — metrics, evalsets, LLM-as-judge, trajectory scoring |
| `google-agents-cli-deploy` | Deployment to Agent Runtime, Cloud Run, GKE, CI/CD, secrets |
| `google-agents-cli-publish` | Gemini Enterprise registration |
| `google-agents-cli-observability` | Cloud Trace, logging, third-party integrations |

### Sample agents (reference, not skills)

[`google/adk-samples`](https://github.com/google/adk-samples) is a collection of sample ADK agents in Python, Java, Go, and TypeScript. Useful as reference implementations when building your own — clone the relevant subdirectory rather than installing as a skill.

## Acknowledgments

This setup is inspired by two people whose thinking shaped it:

- **[Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876)** — for the observations on how LLMs fail at coding (wrong assumptions, overcomplication, drive-by edits, vague execution) that became the four principles in `AGENTS.md`. Packaged into a Claude Code skill by [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills).
- **[Matt Pocock](https://github.com/mattpocock/skills)** — for the small, composable agent skills under `skills/` and the SKILL.md format with progressive disclosure and frontmatter triggers that keeps context lean.

## License

MIT — see [LICENSE](LICENSE). Upstream MIT copyright notices are preserved there.
