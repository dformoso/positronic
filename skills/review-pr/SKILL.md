---
name: review-pr
description: Review the current branch against main before shipping. Includes a prompt-file audit when the diff touches prompts, SKILL.md bodies, or MCP tool descriptions. Use when the user wants a PR review, code quality check, or pre-merge sanity pass. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Review

Review the current branch before it ships. Focus on what's wrong or risky, not what's fine.

Scope is the **current diff**. Whole-system risk is `/audit-failure-modes`; doc-graph drift is `/audit-drift`.

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
- **Tests move with behavior** — a diff that fixes a bug carries the test that reproduces it (it must fail without the fix — stash-and-fail) and patches the existing test that let the bug ship; a diff that removes behavior deletes that behavior's tests and fixtures. An orphaned green test re-pins what was just removed.
- **Comprehension** — could a reader outside this change follow it? Flag: names that lie (`is*` non-boolean, `get*` that mutates or costs, a name promising more/less/opposite of the behavior); vague names (`data`, `result`, `process`); a new public surface without an interface comment, or one that leaks implementation / restates code; a new wrapper that adds interface without hiding anything (deletion test); the same constant/format/assumption now encoded in two places; nesting a guard clause would flatten. Judgment, not gates — and don't demand fragmentation: a deep function with a paragraph comment passes.
- **Needless machinery** — an error path, guard, or `catch` for a state the types or call sites make unreachable; validation repeated at a layer that already received parsed input; a new setting with one possible value; a boolean flag argument selecting between two behaviors. The cheapest failure mode is the one that can't occur.
- **Comments git already holds** — history notes (`// was: oldName()`, dated change annotations, changelog blocks at a file head), commented-out code, docstrings that restate the signature. Flag them for deletion; the commit message is where history belongs.
- **Private-API reach** — flag any access to underscore-prefixed attributes across module boundaries. If a public surface needs the data, the underscore reach is a bug-in-waiting and the deepening opportunity should go to `/clean-house` (targeted mode).
- **User-facing reliability** — for new >2s operations, confirm a progress signal is shown; for new external calls, confirm failure paths map to actionable messages, not raw exception strings. AGENTS.md §7.
- **MCP-server changes** — if the diff adds or modifies an MCP tool / resource / prompt, check it against `${SKILL_DIR}/../../docs/agentic-patterns/06_mcp_design_brief.md` (`${SKILL_DIR}` = the directory containing this file) and against `definitions/mcp-servers.md` if the project has one. Flag drift from either, plus the three the brief can't see from a schema: advertised capabilities that aren't implemented, `tools/list_changed` missing on mutation, schemas not validated at startup.
- **Trace-to-task** — every changed line traces to a sentence in the user's request. Pre-existing dirty state (files modified before the session started) gets surfaced explicitly — never quietly bundled.

### 2a. Coverage check (for cross-surface or removal diffs)

For diffs touching both halves of the stack or removing a feature, grep the whole repo (not just the changed files) for endpoint names, type names, route IDs, fixtures, tests that exercise the removed behavior, demo data, prompt mentions, and doc references. Half-removed concepts won't show up in a file-by-file walk — they survive in the files the diff didn't touch.

### 2b. Prompt audit (when the diff touches prompt files)

Prompt files include system prompts, agent instructions, SKILL.md bodies, prompt templates, and MCP tool descriptions. LLM prompts are code that nothing else reviews — rules go vague, examples reference deleted features, tool lists drift from what's wired up. Four checks:

- **Rule sharpness** — every rule should answer when it fires, what the model does, and when it skips. "Be careful with X" or "prefer Y" are vibes — rewrite or delete.
- **Stale references** — grep for few-shot examples for deleted features, tool names no longer registered, renamed concepts, output fields no longer parsed downstream.
- **Tool-list drift** — if the prompt has a tool catalogue: every registered tool appears with a "call this when …" rule; every listed tool is actually registered; each tool has an example unless the rule is sharp enough.
- **Output-format drift** — if the prompt prescribes structured output: every parser-read field is described; every prompt-mentioned field is consumed (or marked optional); examples use exact parser field names.

**MCP tool descriptions also count.** Clients embed `f"{tool.name}: {tool.description}"` for semantic search, so a vague description is a discoverability bug — concrete domain nouns beat generic verbs ("Get GitHub pull request details" > "Use this tool to retrieve information about pull requests"). Everything else about the tool surface is checked by the bullet above.

### 3. Report

Output a review with two sections:

**Must fix** — things that are wrong, risky, or violate the principles above. Be specific: file, line, what's wrong, what to do instead. If there's nothing here, say so explicitly.

**Worth noting** — minor things that aren't blockers but the author should know. Keep this short. If it's purely stylistic with no functional impact, skip it.

Do not summarise what the code does. Do not praise things that are fine. The author can read the diff.

**Doc-graph nudge** — if `definitions/` exists in the repo, append: "Consider `/audit-drift` next for whole-graph doc drift (glossary inconsistencies, dead refs, decisions overtaken by the SPEC, mockup panels no journey contains). If you're approaching a release cut, also consider `/audit-failure-modes` to enumerate latent failure modes by surface."

### 4. Resolve

After the author responds to feedback, re-read the changed files and confirm each must-fix is resolved before signing off.
