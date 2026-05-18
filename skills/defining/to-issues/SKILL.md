---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable GitHub issues using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
disable-model-invocation: true
---

# To Issues

Break a plan into independently-grabbable GitHub issues using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from what's already in the conversation. If a `specs/` directory exists with files, read the most recent SPEC (`ls specs/[0-9]*.md | sort | tail -1`) as the primary source — the SPEC carries the implementation contract and is what issues should decompose. Otherwise, if `prds/` exists, read the most recent PRD (`ls prds/[0-9]*.md | sort | tail -1`) as the source. If the user passes a GitHub issue number or URL as an argument, fetch it with `gh issue view <number>` (with comments).

### 2. Explore the codebase (optional)

If you haven't explored the codebase, do so.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices need human input (architectural decisions, design review). AFK slices can be merged without it. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

**Template-first pattern.** If multiple slices share the same shape (e.g., one standardizer per entity type, one extractor per data source), identify which slice *establishes* the shape and mark the others as `Blocked by` it. This serializes the mirror slices behind a working in-repo example and prevents parallel AFK agents from drifting into divergent shapes. The shape-establishing slice is often a good candidate for HITL (do it inline) so subsequent AFK agents can reference a finished file.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short, plain-English task description — written as something a human would say, not a file path or module name. Good: "Build the login page". Bad: "api/auth.py — JWT handler + middleware".
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?
- Is there a shape-establishing slice that others should mirror? If so, are the mirrors `Blocked by` it?

Iterate on user feedback.

### 5. Create the GitHub issues

First, ensure the labels exist (idempotent — safe to run even if they already exist):

```bash
gh label create afk  --color "#9ca3af" --force
gh label create hitl --color "#3b82f6" --force
```

For each approved slice, create a GitHub issue using `gh issue create --label afk` or `gh issue create --label hitl` based on the slice type. Use the issue body template below.

Create issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

<issue-template>
## Parent

#<parent-issue-number> (if the source was a GitHub issue, otherwise omit this section)

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

## Source spec

Pointer into the SPEC this issue implements: section name or anchor in `specs/<latest>.md`. Omit this section if no SPEC exists.

## Exemplar to mirror

Path of a file whose shape this issue should follow (e.g., `backend/app/extractors/standardize.py`). Omit this section if this issue establishes a new pattern rather than mirroring one.

## Decisions taken

- Decisions and rejected alternatives that constrain this issue, so the implementer doesn't re-open them.
- Omit this section if no load-bearing decisions apply.

## Shared conventions

- Cross-issue invariants this issue must respect (naming, shape, error handling).
- Omit this section if no shared conventions apply.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- Blocked by #<issue-number> (if any)

Or "None - can start immediately" if no blockers.

</issue-template>

Do NOT close or modify any parent issue.
