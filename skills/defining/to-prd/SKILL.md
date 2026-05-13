---
name: to-prd
description: Turn the current conversation context into a PRD and save it as a versioned local file. Use when user wants to create a PRD from the current context.
disable-model-invocation: true
---

Turn the current conversation, codebase understanding, and (if they exist) the most recent ideation winner + research artifact into a PRD. Do NOT interview the user — synthesize what you already know.

The PRD answers *what and why*. Implementation decisions (modules, schema, API contracts) and detailed test plans live in `/to-spec`, not here.

## Inputs

- Current conversation
- `ideas/<latest>/winner.md` if it exists (chosen idea, grounded in research)
- `research/<latest>/summary.md` if it exists (supporting evidence)
- The codebase, if a project already exists

If `/judge-idea` ran on the winner, ensure its verdict was **proceed** before writing the PRD. If verdict was loop-back or pivot, prompt the user to address the judgment first and stop.

## Process

1. Explore the repo if you haven't already.

2. Write the PRD using the template below. Save as `prds/YYYY-MM-DD-HH-mm-SS.md` (current local time; create `prds/` if missing). Commit it. Do not submit it as a GitHub issue.

3. Length and density: ≤ 5 pages — preferably less. Every sentence must carry information. No padding, no repetition, no restating the obvious. Tables wherever possible.

4. Present the saved PRD and ask the user to review. Wait for approval before they run `/to-spec`.

<prd-template>

## Problem Statement

The problem in the user's words. Two to four sentences max.

## Solution

The solution in user-facing terms. Two to four sentences max.

## User Stories

A numbered list covering every significant actor and workflow. Each in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

Be comprehensive but not exhaustive — cut stories that are obvious consequences of others.

## Success Metrics

How we know the feature is delivered and working. One row per metric.

| Metric | Target | How measured |
|---|---|---|
| | | |

Behavioral and outcome metrics are stronger than activity metrics. "% of users completing first CUJ within 24h" beats "page views".

## Risks & Open Questions

| Item | Type (risk / open question) | Impact if wrong | Plan to resolve |
|---|---|---|---|
| | | | |

If `/judge-idea` produced findings worth carrying into implementation, list them here.

## Non-Goals

Who and what we are explicitly **not** serving with this PRD. Adjacent personas, use cases, and platforms that might seem in scope but aren't. Sharpens the segment.

## Out of Scope

Features explicitly not built in this PRD. Different from Non-Goals: this is about *what*, Non-Goals is about *who*. Both protect against scope creep.

## Further Notes

Any further notes about the feature.

</prd-template>
