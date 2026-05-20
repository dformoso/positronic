---
name: audit-docs
description: Audit the project's doc graph (prds/, specs/, CONTEXT.md, docs/adr/) for drift. Surfaces glossary terms used inconsistently, dead cross-references, ADRs the current SPEC has overtaken, and orphan ADRs. Reports must-fix and worth-noting; never auto-fixes. Use when the user wants a doc-health sweep before shipping or after a long defining phase.
disable-model-invocation: true
---

# Audit Docs

Static sweep across the project's doc graph. Detects drift. Reports only — never auto-fixes. Mirrors `/review-pr`'s posture.

Complementary, not redundant, with two existing skills:

| Skill | When it fires | What it does |
|---|---|---|
| `align-with-docs` | Defining, interview-driven | **Prevents** drift — sharpens terms inline as decisions crystallize |
| `judge-idea` | After PRD/SPEC | **Stress-tests** the idea — adversarial pass on the artifact |
| `audit-docs` (this) | Shipping, on demand | **Detects** drift across the full doc graph — finds what the others missed |

## Process

### 1. Resolve inputs

```bash
latest_prd=$(ls prds/[0-9]*.md 2>/dev/null | sort -V | tail -1)
latest_spec=$(ls specs/[0-9]*.md 2>/dev/null | sort -V | tail -1)
```

Glossary sources:

- If `CONTEXT-MAP.md` exists at the root, parse the context list and use every `CONTEXT.md` it points to.
- Otherwise, use the root `CONTEXT.md` if it exists.

ADR sources:

- Root: `docs/adr/[0-9]*.md`
- Per-context: `*/docs/adr/[0-9]*.md` (when `CONTEXT-MAP.md` exists)

If both `latest_prd` and `latest_spec` are empty, stop and say so — there's nothing to audit yet. (Empty `prds/` or `specs/` directories slip past a directory-existence check.)

### 2. Run checks

#### 2.1. Glossary drift — *worth-noting*

For each `CONTEXT.md` line of the form `_Avoid_: term1, term2, …`, search the latest PRD and SPEC for those terms:

```bash
grep -nE "\b(term1|term2)\b" "$latest_prd" "$latest_spec"
```

Report each hit with the canonical term to use instead. Skip hits inside fenced code blocks.

#### 2.2. Dead cross-references — *must-fix*

Walk every markdown file in `prds/`, `specs/`, `docs/`, plus root `CONTEXT.md` and `CONTEXT-MAP.md`. For each `[text](path)`:

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

This is the LLM-judgment check, not a grep. Be conservative — only flag when the contradiction is clear, not when the ADR and SPEC discuss different layers.

#### 2.4. Orphan ADRs — *worth-noting*

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

- **PRD-SPEC scope coverage.** Hard, judgment-heavy, and `/judge-idea` covers neighbouring ground.
- **ADR completeness.** ADR format is intentionally minimal — there's no required-section list to enforce.
- **Issue traceability.** Couples to GitHub and only useful immediately after `/to-issues`.
- **Auto-fix.** Mirrors `/review-pr` — detection, not repair.
