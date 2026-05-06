---
name: review
description: Review the current branch against main before shipping. Use when the user wants a PR review, code quality check, or pre-merge sanity pass.
disable-model-invocation: true
---

# Review

Review the current branch before it ships. Focus on what's wrong or risky, not what's fine.

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

### 3. Report

Output a review with two sections:

**Must fix** — things that are wrong, risky, or violate the principles above. Be specific: file, line, what's wrong, what to do instead. If there's nothing here, say so explicitly.

**Worth noting** — minor things that aren't blockers but the author should know. Keep this short. If it's purely stylistic with no functional impact, skip it.

Do not summarise what the code does. Do not praise things that are fine. The author can read the diff.

### 4. Resolve

After the author responds to feedback, re-read the changed files and confirm each must-fix is resolved before signing off.
