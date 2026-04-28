# dotclaude

A personal Claude Code framework. Karpathy's behavioral principles as the always-on floor, a curated set of Pocock-style workflow skills on top, and an `optional/` parking lot for skills kept around but not active.

## Layout

```text
.
├── CLAUDE.md                              # behavioral floor (always on)
├── .claude-plugin/plugin.json             # registers active skills
└── skills/
    ├── meta/write-a-skill/                # how to extend the framework
    ├── workflow/                          # model-invokable
    │   ├── diagnose/
    │   ├── tdd/
    │   └── grill-me/
    ├── slash-only/                        # disable-model-invocation: true
    │   ├── caveman/
    │   └── zoom-out/
    └── optional/                          # unregistered, dormant
        ├── grill-with-docs/
        ├── improve-codebase-architecture/
        ├── github-triage/
        ├── to-issues/
        ├── to-prd/
        ├── git-guardrails-claude-code/
        ├── migrate-to-shoehorn/
        ├── setup-pre-commit/
        └── scaffold-exercises/
```

The system prompt only ever sees `CLAUDE.md` plus the `description` fields of skills listed in `plugin.json`. `optional/` costs zero context until you promote a skill into a registered bucket.

## Install

### Option A: as your user-level Claude Code config

```bash
git clone https://github.com/<you>/dotclaude.git ~/.claude
```

If `~/.claude` already exists, clone elsewhere and selectively merge.

### Option B: as a Claude Code plugin

From within Claude Code:

```text
/plugin marketplace add <you>/dotclaude
/plugin install dotclaude
```

### Option C: per-project

Clone into a project and either symlink `CLAUDE.md` to the project root or copy the skills you want into the project's `.claude/` directory.

## Activating an optional skill

1. Move the skill folder out of `optional/` into the right bucket:
   - `workflow/` if it should auto-fire on relevant prompts
   - `slash-only/` if it should only run on `/skill-name` (also add `disable-model-invocation: true` to its frontmatter)
2. Add its path to the `skills` array in `.claude-plugin/plugin.json`.

## Adding a new skill

Use the `write-a-skill` skill itself, or follow the template in [skills/meta/write-a-skill/SKILL.md](skills/meta/write-a-skill/SKILL.md). New skills must not contradict the four principles in `CLAUDE.md`.

## Acknowledgments

This setup is inspired by two people whose thinking shaped it:

- **[Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876)** — for the observations on how LLMs fail at coding (wrong assumptions, overcomplication, drive-by edits, vague execution) that became the four principles in `CLAUDE.md`. Packaged into a Claude Code skill by [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills).
- **[Matt Pocock](https://github.com/mattpocock/skills)** — for the small, composable agent skills under `skills/` and the SKILL.md format with progressive disclosure and frontmatter triggers that keeps context lean.

Local edits I made on top of Matt's set: added `disable-model-invocation: true` to `caveman`, and extended `write-a-skill` with a behavioral-floor check and bucket-placement guidance.

## License

MIT — see [LICENSE](LICENSE). Upstream MIT copyright notices are preserved there.
