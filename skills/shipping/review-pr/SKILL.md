---
name: review-pr
description: Review the current branch against main before shipping. Includes a prompt-file audit when the diff touches prompts, SKILL.md bodies, or MCP tool descriptions. Use when the user wants a PR review, code quality check, or pre-merge sanity pass.
disable-model-invocation: true
---

# Review

Review the current branch before it ships. Focus on what's wrong or risky, not what's fine.

Positions within the shipping phase:

| Skill | Scope | When it fires | What it does |
|---|---|---|---|
| `/review-pr` (this) | Current diff | Before a branch ships | Catches what's wrong or risky in the change |
| `/audit-drift` | Doc graph | Shipping, on demand | Detects drift across PRDs/SPECs/ADRs |
| `/audit-failure-modes` | Whole system | Before a release cut | Lists latent failure modes; ranks by correctness/reliability/polish |

## Process

### 1. Orient

```
git diff main...HEAD --stat
git log main..HEAD --oneline
```

Understand the scope. If the diff is large, note which areas you'll prioritise.

### 2. Review

Read every changed file in full. For each, check against the AGENTS.md principles:

- **Simplicity** — is this the minimum code that solves the problem? Could it be 50 lines instead of 200?
- **Surgical** — does every changed line trace to the stated goal? Are there unrelated cleanups, refactors, or formatting changes mixed in?
- **No speculative code** — no features, abstractions, or error handling for scenarios that don't exist yet.
- **Security** — command injection, XSS, SQL injection, OWASP top 10. Flag anything that takes external input.
- **Correctness** — logic errors, off-by-ones, edge cases the tests don't cover.
- **Dead imports/variables** — orphans left by the change that weren't cleaned up.
- **Private-API reach** — flag any access to underscore-prefixed attributes across module boundaries. If a public surface needs the data, the underscore reach is a bug-in-waiting and the deepening opportunity should go to `/deepen-modules`.
- **User-facing reliability** — for new >2s operations, confirm a progress signal is shown; for new external calls, confirm failure paths map to actionable messages, not raw exception strings. AGENTS.md §7.
- **MCP-server changes** — if the diff adds or modifies an MCP tool / resource / prompt: `inputSchema` is the public contract (single-type fields, `description` per property, `enum`/`pattern` where the domain is finite, no `oneOf`/`anyOf` discriminators); tool name `[a-z0-9_]+` with no embedded server name; failures wrap as `CallToolResult(isError=True, content=[TextContent(...)])` — never thrown; `annotations` set (`readOnlyHint`, `idempotentHint`, `destructiveHint`, `openWorldHint`); capabilities advertised match what's implemented; `tools/list_changed` emitted on mutation; schemas validated at server startup. See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/06_mcp_design_brief.md`.
- **Trace-to-task** — every changed line traces to a sentence in the user's request. Pre-existing dirty state (files modified before the session started) gets surfaced explicitly — never quietly bundled.

### 2a. Coverage check (for cross-surface or removal diffs)

For diffs touching both halves of the stack or removing a feature, grep the whole repo (not just the changed files) for endpoint names, type names, route IDs, fixtures, demo data, prompt mentions, and doc references. Half-removed concepts won't show up in a file-by-file walk — they survive in the files the diff didn't touch.

### 2b. Prompt audit (when the diff touches prompt files)

Prompt files include system prompts, agent instructions, SKILL.md bodies, prompt templates, and MCP tool descriptions. LLM prompts are code that nothing else reviews — rules go vague, examples reference deleted features, tool lists drift from what's wired up. Four checks:

- **Rule sharpness** — every rule should answer when it fires, what the model does, and when it skips. "Be careful with X" or "prefer Y" are vibes — rewrite or delete.
- **Stale references** — grep for few-shot examples for deleted features, tool names no longer registered, renamed concepts, output fields no longer parsed downstream.
- **Tool-list drift** — if the prompt has a tool catalogue: every registered tool appears with a "call this when …" rule; every listed tool is actually registered; each tool has an example unless the rule is sharp enough.
- **Output-format drift** — if the prompt prescribes structured output: every parser-read field is described; every prompt-mentioned field is consumed (or marked optional); examples use exact parser field names.

**MCP tool descriptions also count.** Clients embed `f"{tool.name}: {tool.description}"` for semantic search — concrete domain nouns beat generic verbs ("Get GitHub pull request details" > "Use this tool to retrieve information about pull requests"). Tool name `[a-z0-9_]+`, no embedded server name (clients namespace as `${server}_${tool}`). Annotations (`readOnlyHint`, `idempotentHint`, `destructiveHint`, `openWorldHint`) drive client security gating; omission gets worst-case defaults. See `${CLAUDE_SKILL_DIR}/../../../docs/agentic-patterns/06_mcp_design_brief.md`.

### 3. Report

Output a review with two sections:

**Must fix** — things that are wrong, risky, or violate the principles above. Be specific: file, line, what's wrong, what to do instead. If there's nothing here, say so explicitly.

**Worth noting** — minor things that aren't blockers but the author should know. Keep this short. If it's purely stylistic with no functional impact, skip it.

Do not summarise what the code does. Do not praise things that are fine. The author can read the diff.

**Doc-graph nudge** — if `prds/`, `specs/`, or `docs/adr/` exist in the repo, append: "Consider `/audit-drift` next for whole-graph doc drift (glossary inconsistencies, dead refs, ADRs overtaken by SPEC, orphan ADRs). If you're approaching a release cut, also consider `/audit-failure-modes` to enumerate latent failure modes by surface."

### 4. Resolve

After the author responds to feedback, re-read the changed files and confirm each must-fix is resolved before signing off.
