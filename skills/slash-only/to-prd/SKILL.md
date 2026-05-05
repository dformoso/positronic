---
name: to-prd
description: Turn the current conversation context into a PRD and save it as a versioned local file. Use when user wants to create a PRD from the current context.
disable-model-invocation: true
---

Turn the current conversation and codebase understanding into a PRD. Do NOT interview the user — synthesize what you already know.

## Process

1. Explore the repo if you haven't already.

2. Sketch out the major modules you'll build or modify. Actively look for opportunities to extract deep modules that can be tested in isolation.

A deep module (as opposed to a shallow module) is one which encapsulates a lot of functionality in a simple, testable interface which rarely changes.

Check with the user that these modules match their expectations. Check with the user which modules they want tests written for.

3. Write the PRD using the template below. Save it as `docs/prd-YYYY-MM-DD.md` (today's date) and commit it. Do not submit it as a GitHub issue.

<prd-template>

## Problem Statement

The problem in the user's words.

## Solution

The solution in user-facing terms.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

The list should be extensive — cover every aspect of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Skip file paths and code snippets — they go stale fast.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art — similar tests already in the codebase

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
