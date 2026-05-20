# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
- If you're about to use an unfamiliar API or pattern, verify it exists — read the code, the docs, or grep the codebase first. Don't invent.

**Grilling mode.** When the user says "grill me", "stress-test this", "interrogate my plan", or anything similar, and/or when you consider it appropriate, interview them one question at a time, walking each branch of the design tree and resolving dependencies between decisions one-by-one. For each question, propose options, highlight tradeoffs, recommend an answer, explain why. If a question can be answered by exploring the codebase, explore instead of asking.

## 2. Read Before You Write

**Ground every action in actual code, not remembered code.**

- Before editing a file, read it.
- Before calling an API or using a pattern, verify it exists — grep, read the docs, find an example in the codebase.
- If you catch yourself writing "from memory," stop and verify first.

## 3. Minimum Diff

**Every changed line traces to the request. For new code, write the minimum that solves it. For edits, touch only what you must.**

For new code:

- No speculative features, abstractions, configurability, or error handling for scenarios that can't happen.
- If you wrote 200 lines and could write 50, rewrite.

For edits:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style, even if you'd write it differently.

For both:

- Remove orphans your changes created (unused imports, dead variables, dead functions).
- If you notice pre-existing dead code, mention it — don't delete it.

## 4. Plain Naming

**Functions, modules, and variables read like plain English.**

- Names describe intent — what the code does or holds, not what it's called or what type it is.
- No abbreviations, acronyms, or clever wordplay. `userCount` not `usrCnt`. `parsePayment` not `procPmt`.
- Module names describe the domain, not abstract patterns. `billing/` not `helpers/` or `utils/`.
- A reader who hasn't seen the code should understand intent from the name alone.

If you can't write a clear name, you don't yet understand the thing you're naming. Stop and clarify.

## 5. Goal-Driven Execution

**Define verifiable success. Loop until verified — or stop and surface what's blocking.**

**Driving forward.** Transform fuzzy tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**Stopping.** If the path isn't working:

- If the same approach fails twice, stop. Surface the obstacle. Don't keep trying variations.
- If a test won't go green after a focused attempt, say what you tried and what's confusing.
- Sunk cost is not a reason to keep going.

## 6. Phase Awareness

**Name the phase before acting. Don't pick silently.**

- **Defining** — fuzzy goal, no spec yet → run `define`. Once define converges:
  - **Zero-to-one with market uncertainty.** Prompt the user to run `/research-market` (forum + competitive evidence), `/ideate` (10 ranked one-pagers, user picks), `/judge-idea` (adversarial gate), then `/to-prd`, `/to-spec`, `/to-issues`.
  - **Established space.** Prompt the user to run `/to-prd`, `/to-spec`, `/to-issues` directly.
  - **Custom LLM harness on the table.** `define` also hands off to `pick-harness-shape` to surface harness-shape decisions before `/to-spec` (independent of which Defining path above was taken).
- **Implementing** — spec is decided → run `test-driven-dev` for a single issue. For the full backlog, prompt the user to run `/run-afk-in-loop`, which works through unblocked AFK issues in parallel waves. When implementing UI, `ui-taste` fires automatically.
- **Diagnosing** — something is broken or regressed → run `diagnose`.
- **Shipping** — PR prep, review, cleanup → prompt the user to run `/review-pr`. For projects with PRDs/SPECs/ADRs, also prompt `/audit-docs` to surface doc drift.

Skills prefixed with `/` are user-invoked. Don't run them yourself — prompt the user when the phase calls for it.

## 7. User-Facing Reliability

**The user must see what's happening and understand what failed.**

- For operations >2s, show progress (spinner, status line, streamed activity). Silent ≠ done — the user has already assumed it crashed.
- For external failures (LLM, HTTP, DB, filesystem), map raw exceptions to one-sentence messages naming **what went wrong** and **what to do next**. Don't leak provider stack traces. Pin tests against the actual production exception text you observed.

## 8. Secret & Data Hygiene

**Don't leak credentials or sensitive data, ever.**

- Never commit `.env`, API keys, tokens, or credential files.
- Never log, print, or echo credentials, PII, or auth headers — including in error messages and stack traces.
- If you find a secret already committed in code, stop and surface it. Don't paste it back in your output.

---

## Stack-specific rules

The rules above are universal. The rules below apply only when the stack matches.

### Cloud Deployments

**For Google ADK or Google Cloud projects, prompt the user to install — don't install yourself.**

When the project uses [Google ADK](https://adk.dev) or deploys to Google Cloud, prompt the user to install [`google-agents-cli`](https://github.com/google/agents-cli) and register the relevant skills. See the README for install commands and the skill list.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
