---
name: audit-drift
description: Audit the project's doc graph (definitions/, CONTEXT.md) for drift. Surfaces glossary terms used inconsistently, dead cross-references, decisions the current SPEC has overtaken, SPEC contracts the code has overtaken, mockup panels no journey still contains, and journeys the SPEC never designed. Reports must-fix and worth-noting; never auto-fixes. Use when the user wants a doc-health sweep before shipping or after a long defining phase.
---

# Audit Drift

Static sweep across the project's doc graph (and the code it describes). Detects drift. Reports only — never auto-fixes. Mirrors `/review-pr`'s posture.

Scope is the **doc graph**, not the diff (`/review-pr`) and not system risk (`/audit-failure-modes`). Distinct from `/judge-idea` too: that stress-tests one artifact's argument, this detects mechanical drift across all of them.

Also runs inside `clean-house` at the end of each pass: after a pass's cuts and reshapes, this sweep reconciles the doc graph, and findings the pass's edits don't explain feed the next pass's questioning.

## Process

### 1. Resolve inputs

The defining artifacts are one file each, flat in `definitions/`. Any of them may be absent — skip what isn't there:

```text
definitions/prd.md
definitions/journeys.md
definitions/mockups.md
definitions/harness.md
definitions/runtime.md
definitions/mcp-servers.md
definitions/infrastructure.md
definitions/decisions.md
definitions/spec.md
```

Glossary sources:

- If `CONTEXT-MAP.md` exists at the root, parse the context list and use every `CONTEXT.md` it points to.
- Otherwise, use the root `CONTEXT.md` if it exists.

If neither `definitions/prd.md` nor `definitions/spec.md` exists, stop and say so — there's nothing to audit yet. (Check the files themselves; an empty `definitions/` directory slips past a directory-existence check.)

### 2. Run checks

#### 2.1. Glossary drift — *worth-noting*

For each `CONTEXT.md` line of the form `_Avoid_: term1, term2, …`, search every defining artifact for those terms:

```bash
grep -rnE "\b(term1|term2)\b" definitions/ 2>/dev/null
```

Report each hit with the canonical term to use instead. Skip hits inside fenced code blocks.

#### 2.2. Dead cross-references — *must-fix*

Walk every markdown file in `definitions/` and `docs/`, plus `plans/` when it exists (living plan documents drift too), plus root `CONTEXT.md` and `CONTEXT-MAP.md`. For each `[text](path)`:

- Skip if `path` starts with `http`.
- If `path` contains `#`, split into file + anchor. Verify the file exists and the anchor matches a heading (slugified: lowercase, spaces → hyphens, punctuation stripped).
- Otherwise verify the file exists.

Report each broken link as `source:line → target`.

#### 2.3. Decisions overtaken by the latest SPEC — *must-fix*

For each `##` section in `definitions/decisions.md` and `definitions/infrastructure.md`:

- Skip any section carrying a `**Superseded by:**` line.
- Read the SPEC's `## Modules & interfaces` and `## Data model / schema` sections.
- If the recorded decision is no longer reflected in the current SPEC, flag it.

LLM judgment, not a grep. Be conservative — flag only a clear contradiction, not a section and a SPEC discussing different layers. A record's *freshness* is governed by its own `NEXT REVIEW:`/`TRIGGER:` lines, which `clean-house` sweeps; here flag only a SPEC that contradicts what was recorded.

#### 2.4. The latest SPEC overtaken by the code — *must-fix* (forward) / *worth-noting* (reverse)

Skip if there's no `definitions/spec.md` or no source code. The semantic mirror of 2.3, one layer down: 2.3 asks whether the SPEC still honours each recorded decision; this asks whether the **code** still honours each SPEC contract. Like 2.3, this is LLM-judgment, not a grep — be conservative, flag only a clear contradiction. It is the heaviest check here: it reads source, not just docs.

From the latest SPEC, take the named, checkable contracts:

- `## Modules & interfaces` — module / directory names
- `## Data model / schema` — entities, tables, key fields
- `## API contracts` — endpoints, method signatures
- `## Tool layer / ACI` — tool names
- `## Verification gates` — named gates

For each, grep the codebase and judge:

- **Forward — *must-fix*.** The SPEC names a contract the code clearly no longer honours: module deleted, endpoint gone, field renamed, gate removed. The doc graph now lies. (This is also where a `diagnose` fix that changed behaviour without updating the SPEC surfaces.)
- **Reverse — *worth-noting*.** A *major* surface present in code — a whole module directory, route group, or public tool — that the latest SPEC never mentions. The signature of accumulated drift across many small PRs. Flag surfaces, never individual functions, or this floods.

Also read `definitions/harness.md` where it names topology, gates, or tools the code should implement, and apply the same conservative compare. Do the same with the `definitions/runtime.md` profile where it names placement constraints the SPEC restates (residency exceptions, telemetry backend, cost envelope / kill switch) — flag a SPEC that contradicts the profile, conservatively. Keep every finding to a divergence you can point at — when in doubt, don't flag.

#### 2.5. Mockup panels vs. journey steps — *must-fix*

Skip if there's no `definitions/mockups.md`. Mechanical, in both directions:

- Every row of its **Panel inventory** must have a matching `id` in `definitions/mockups.html`.
- Every journey step and branch in `definitions/journeys.md` that names a panel must appear as a panel row.
- No panel may name a journey the file no longer contains.

A drawing of a screen the product doesn't have misleads the next implementer more than no drawing at all, which is why this is must-fix rather than worth-noting. Report each gap as the missing panel id or the unmatched step.

#### 2.6. Journey coverage and capability list vs. the journeys — *must-fix*

Skip both halves if there's no `definitions/journeys.md`, and the SPEC half if there's no `definitions/spec.md`. Mechanical, in both directions:

- The SPEC's **Journey coverage** table needs one row per journey and per reference row in `definitions/journeys.md`, and no cell may be empty.
- No coverage row may name a journey the file no longer contains, and no module in `## Modules & interfaces` may be missing from every row.
- The journeys file's **What the product does** table must place every `feature`-tier journey in the Journey inventory in at least one row's *Where it happens*.
- No capability row may name a journey id or `background` behaviour the file doesn't contain.

An empty cell is a journey nobody designed and a module in no row is work nobody asked for — both are missing decisions, not untidy docs, which is why this is must-fix rather than worth-noting. Report each gap as the uncovered journey, the unclaimed module, or the dangling id.

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

**Write it in plain English** — short sentences, one idea each, concrete before abstract, jargon glossed on first use, readable by someone who wasn't in this conversation (AGENTS.md §4).

Default no. Create `docs/audits/` lazily on first save.

## Out of scope

Named so they aren't re-litigated:

- **PRD-SPEC scope coverage, beyond the journeys.** Whether the SPEC covers what the PRD promised outside its journeys — success metrics, kill criteria, scope lines (forward completeness) — distinct from 2.4, which checks whether the code still *honours* the SPEC (backward conformance). Still hard and judgment-heavy, and `/judge-idea` covers neighbouring ground. The journeys half is mechanical now, and 2.6 does it.
- **Deployed-vs-artifact harness drift.** Prod model swaps, added gates, or topology changes not visible in the repo. Brief-07 production-monitoring territory, not a static sweep.
- **Decision-record completeness.** The format is intentionally minimal — there's no required-section list to enforce.
- **Orphan decisions.** Records live in two known files, not scattered ones; a section in a file everything already reads can't be orphaned.
- **Issue traceability.** Couples to GitHub and only useful immediately after `/to-issues`.
- **Auto-fix.** Mirrors `/review-pr` — detection, not repair.
