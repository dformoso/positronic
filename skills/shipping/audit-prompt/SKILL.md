---
name: audit-prompt
description: Audit an LLM prompt for clarity, stale references, and drift from the surrounding code. Use when changes touch a prompt file (system prompt, agent instructions, skill body, prompt template), or when adding/removing tools the prompt mentions.
disable-model-invocation: true
---

# Audit Prompt

LLM prompts are code that nothing else reviews. Rules go vague, examples reference things that no longer exist, and tool lists drift from what's actually wired up. This skill catches those four common failures.

Run it on any prompt: a system prompt, an agent's instructions, a SKILL.md body, a prompt template in a repo.

## Inputs

- The prompt file (or files) being audited
- If the prompt mentions tools or an output format, the place those are defined in the surrounding code

If the surrounding code can't be located, audit clarity and stale references only and say so in the report.

## The four checks

### 1. Is every rule sharp?

For each rule or instruction in the prompt, it should answer:

- **When does this fire?** What input or situation triggers it?
- **What does the model do?** The action, concretely.
- **When should it skip?** Cases where the rule doesn't apply.

Rules that say "be careful with X" or "prefer Y" without saying when or how are vibes. Rewrite or delete them.

### 2. Does anything in the prompt no longer exist?

Grep the prompt for things that may have been removed or renamed:

- Few-shot examples that reference deleted features
- Tool names no longer registered
- Concept names that have since been renamed or merged
- Output fields no longer parsed downstream

Every dangling reference is an invitation for the model to hallucinate the removed feature in production.

### 3. If the prompt lists tools, does the list match the code?

When the prompt has a tool catalogue (or otherwise tells the model what tools exist):

- Every tool registered in the code should appear in the prompt, with an explicit "call this when …" rule.
- Every tool in the prompt should actually be registered in the code.
- Each tool should appear in at least one example, unless the rule is sharp enough that an example would be redundant.

### 4. If the prompt prescribes an output format, does it match the parser?

When the prompt asks for structured output (JSON, an envelope, named sections):

- Every field the parser reads should be described in the prompt.
- Every field the prompt mentions should be consumed somewhere (or marked optional).
- Examples should use the exact field names the parser expects.

## Report

Output one review with these sections — write "none" for any empty section, no filler:

- **Vague rules** — rules without a clear when/what/skip.
- **Stale references** — prompt mentions of things that no longer exist in the code.
- **Tool drift** — tools in the prompt but not the code, or vice versa.
- **Output drift** — fields the parser reads but the prompt doesn't describe, or vice versa.
