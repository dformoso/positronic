---
name: audit-drift
description: Audit the project's doc graph (definitions/, CONTEXT.md, docs/adr/) for drift. Surfaces glossary terms used inconsistently, dead cross-references, ADRs the current SPEC has overtaken, SPEC contracts the code has overtaken, mockup panels no journey still contains, and orphan ADRs. Reports must-fix and worth-noting; never auto-fixes. Use when the user wants a doc-health sweep before shipping or after a long defining phase. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

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

The defining artifacts are one file each, flat in `definitions/`. Any of them may be absent — skip what isn't there:

```text
definitions/prd.md
definitions/journeys.md
definitions/mockups.md
definitions/harness.md
definitions/runtime.md
definitions/mcp-servers.md
definitions/spec.md
```

Glossary sources:

- If `CONTEXT-MAP.md` exists at the root, parse the context list and use every `CONTEXT.md` it points to.
- Otherwise, use the root `CONTEXT.md` if it exists.

ADR sources:

- Root: `docs/adr/[0-9]*.md`
- Per-context: `*/docs/adr/[0-9]*.md` (when `CONTEXT-MAP.md` exists)

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

#### 2.3. ADRs overtaken by the latest SPEC — *must-fix*

For each ADR in `docs/adr/[0-9]*.md`:

- Skip if frontmatter `status` is `deprecated` or `superseded by ADR-NNNN`.
- Read the ADR body.
- Read the latest SPEC's `## Modules & interfaces` and `## Data model / schema` sections.
- If the ADR's decision is no longer reflected in the current SPEC, flag it.

This is the LLM-judgment check, not a grep. Be conservative — only flag when the contradiction is clear, not when the ADR and SPEC discuss different layers. Date-named service-pick records (from `pick-cloud-services`) are covered too, but their *freshness* is governed by their own `NEXT REVIEW:`/`TRIGGER:` lines — `/clean-house` sweeps those; here flag only a SPEC that contradicts the recorded decision.

#### 2.4. The latest SPEC overtaken by the code — *must-fix* (forward) / *worth-noting* (reverse)

Skip if there's no `definitions/spec.md` or no source code. The semantic mirror of 2.3, one layer down: 2.3 asks whether the SPEC still honours each ADR; this asks whether the **code** still honours each SPEC contract. Like 2.3, this is LLM-judgment, not a grep — be conservative, flag only a clear contradiction. It is the heaviest check here: it reads source, not just docs.

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

#### 2.6. Orphan ADRs — *worth-noting*

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
