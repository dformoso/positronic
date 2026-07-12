---
name: audit-drift
description: Audit the project's doc graph (definitions/prds/, definitions/harness/, definitions/surfaces/, definitions/mcp-servers/, definitions/runtime/, definitions/specs/, CONTEXT.md, docs/adr/) for drift. Surfaces glossary terms used inconsistently, dead cross-references, ADRs the current SPEC has overtaken, SPEC contracts the code has overtaken, and orphan ADRs. Reports must-fix and worth-noting; never auto-fixes. Use when the user wants a doc-health sweep before shipping or after a long defining phase.
disable-model-invocation: true
---

# Audit Drift

Static sweep across the project's doc graph (and the code it describes). Detects drift. Reports only — never auto-fixes. Mirrors `/review-pr`'s posture.

Positions within the shipping phase:

| Skill | Scope | When it fires | What it does |
|---|---|---|---|
| `/review-pr` | Current diff | Before a branch ships | Catches what's wrong or risky in the change |
| `/audit-drift` (this) | Doc graph | Shipping, on demand | Detects drift across PRDs/SPECs/ADRs |
| `/audit-failure-modes` | Whole system | Before a release cut | Lists latent failure modes; ranks by correctness/reliability/polish |

Complementary, not redundant, with `judge-idea` from the defining phase — that adversarially stress-tests an artifact, while audit-drift detects mechanical drift across the full doc graph.

Also runs inside `/clean-house` at the end of each pass: after a pass's cuts and reshapes, this sweep reconciles the doc graph, and findings the pass's edits don't explain feed the next pass's questioning.

## Process

### 1. Resolve inputs

```bash
latest_prd=$(ls definitions/prds/[0-9]*.md 2>/dev/null | sort | tail -1)
latest_harness=$(ls definitions/harness/[0-9]*.md 2>/dev/null | sort | tail -1)
latest_surfaces=$(ls definitions/surfaces/[0-9]*.md 2>/dev/null | sort | tail -1)
latest_runtime=$(ls definitions/runtime/[0-9]*.md 2>/dev/null | sort | tail -1)
latest_spec=$(ls definitions/specs/[0-9]*.md 2>/dev/null | sort | tail -1)
mcp_files=$(ls definitions/mcp-servers/*.md 2>/dev/null)   # multiple files possible — one per server
```

Glossary sources:

- If `CONTEXT-MAP.md` exists at the root, parse the context list and use every `CONTEXT.md` it points to.
- Otherwise, use the root `CONTEXT.md` if it exists.

ADR sources:

- Root: `docs/adr/[0-9]*.md`
- Per-context: `*/docs/adr/[0-9]*.md` (when `CONTEXT-MAP.md` exists)

If both `latest_prd` and `latest_spec` are empty, stop and say so — there's nothing to audit yet. (Empty `definitions/prds/` or `definitions/specs/` directories slip past a directory-existence check.)

### 2. Run checks

#### 2.1. Glossary drift — *worth-noting*

For each `CONTEXT.md` line of the form `_Avoid_: term1, term2, …`, search the latest PRD, harness, surfaces, runtime profile, SPEC, and every MCP-server design file for those terms (skip any var that's empty):

```bash
# $mcp_files intentionally unquoted: word-splits into multiple grep file args
grep -nE "\b(term1|term2)\b" "$latest_prd" "$latest_harness" "$latest_surfaces" "$latest_runtime" "$latest_spec" $mcp_files 2>/dev/null
```

Report each hit with the canonical term to use instead. Skip hits inside fenced code blocks.

#### 2.2. Dead cross-references — *must-fix*

Walk every markdown file in `definitions/prds/`, `definitions/harness/`, `definitions/surfaces/`, `definitions/mcp-servers/`, `definitions/runtime/`, `definitions/specs/`, `docs/`, plus `plans/` when it exists (living plan documents drift too), plus root `CONTEXT.md` and `CONTEXT-MAP.md`. For each `[text](path)`:

- Skip if `path` starts with `http`.
- If `path` contains `#`, split into file + anchor. Verify the file exists and the anchor matches a heading (slugified: lowercase, spaces → hyphens, punctuation stripped).
- Otherwise verify the file exists.

Report each broken link as `source:line → target`.

#### 2.3. ADRs overtaken by the latest SPEC — *must-fix*

For each ADR in `docs/adr/[0-9]*.md`:

- Skip if frontmatter `status` is `deprecated` or `superseded by ADR-NNNN`.
- Read the ADR body.
- Read the latest SPEC's `## Modules & interfaces` and `## Data model / schema` sections.
- If the ADR's decision is no longer reflected in the current SPEC, flag it.

This is the LLM-judgment check, not a grep. Be conservative — only flag when the contradiction is clear, not when the ADR and SPEC discuss different layers. Date-named service-pick records (from `pick-cloud-services`) are covered too, but their *freshness* is governed by their own `NEXT REVIEW:`/`TRIGGER:` lines — `/clean-house` sweeps those; here flag only a SPEC that contradicts the recorded decision.

#### 2.4. The latest SPEC overtaken by the code — *must-fix* (forward) / *worth-noting* (reverse)

Skip if there's no `latest_spec` or no source code. The semantic mirror of 2.3, one layer down: 2.3 asks whether the SPEC still honours each ADR; this asks whether the **code** still honours each SPEC contract. Like 2.3, this is LLM-judgment, not a grep — be conservative, flag only a clear contradiction. It is the heaviest check here: it reads source, not just docs.

From the latest SPEC, take the named, checkable contracts:

- `## Modules & interfaces` — module / directory names
- `## Data model / schema` — entities, tables, key fields
- `## API contracts` — endpoints, method signatures
- `## Tool layer / ACI` — tool names
- `## Verification gates` — named gates

For each, grep the codebase and judge:

- **Forward — *must-fix*.** The SPEC names a contract the code clearly no longer honours: module deleted, endpoint gone, field renamed, gate removed. The doc graph now lies. (This is also where a `diagnose` fix that changed behaviour without updating the SPEC surfaces.)
- **Reverse — *worth-noting*.** A *major* surface present in code — a whole module directory, route group, or public tool — that the latest SPEC never mentions. The signature of accumulated drift across many small PRs. Flag surfaces, never individual functions, or this floods.

Also read the latest `definitions/harness/` artifact where it names topology, gates, or tools the code should implement, and apply the same conservative compare. Do the same with the latest `definitions/runtime/` profile where it names placement constraints the SPEC restates (residency exceptions, telemetry backend, cost envelope / kill switch) — flag a SPEC that contradicts the profile, conservatively. Keep every finding to a divergence you can point at — when in doubt, don't flag.

#### 2.5. Orphan ADRs — *worth-noting*

For each ADR file `docs/adr/NNNN-slug.md`:

```bash
grep -rln --include='*.md' --include='*.py' --include='*.ts' --include='*.tsx' --include='*.js' "NNNN-slug" .
```

If the only file returned is the ADR itself, it's an orphan. ADRs newer than 7 days are exempt — they may not have been referenced yet.

### 3. Report

Print to chat. Match `/review-pr`'s format:

```text
## Must fix
- {file:line} — {what's wrong, what to do instead}

## Worth noting
- {file:line} — {what's odd, why it matters}
```

If a tier is empty, say so explicitly. Do not summarize what was checked. The user can read the skill.

### 4. Save (optional)

After printing the report, ask:

> Save the report to `docs/audits/YYYY-MM-DD-doc-audit.md`? (y/N)

Default no. Create `docs/audits/` lazily on first save.

## Out of scope

Named so they aren't re-litigated:

- **PRD-SPEC scope coverage.** Whether the SPEC covers everything the PRD *promised* (forward completeness) — distinct from 2.4, which checks whether the code still *honours* the SPEC (backward conformance). Hard, judgment-heavy, and `/judge-idea` covers neighbouring ground.
- **Deployed-vs-artifact harness drift.** Prod model swaps, added gates, or topology changes not visible in the repo. Brief-07 production-monitoring territory, not a static sweep.
- **ADR completeness.** ADR format is intentionally minimal — there's no required-section list to enforce.
- **Issue traceability.** Couples to GitHub and only useful immediately after `/to-issues`.
- **Auto-fix.** Mirrors `/review-pr` — detection, not repair.
