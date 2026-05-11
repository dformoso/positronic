---
name: audit-prompt
description: Audit an LLM agent prompt for tool-catalogue coverage, dead references, and rule sharpness. Use when changes touch a prompt file or when adding / removing agent tools.
disable-model-invocation: true
---

# Audit Prompt

LLM prompts are code that nothing else reviews. Tools get registered without instructions telling the model when to call them. Few-shot demos survive the deletion of the feature they referenced. Rules drift from the running code. This skill catches that.

## Process

### 1. Locate the surfaces

For each prompt file in scope:

- The prompt itself (e.g. `prompts/system.md`).
- The tool registration site (where the runtime hands the LLM its tool list).
- The runtime emitter for any `kind` / `phase` / `mode` enum the prompt references (run kinds, trigger kinds, etc.).

### 2. Tool-catalogue ↔ instructions coverage

For every tool actually registered with the agent:

- [ ] Listed in the prompt's tool catalogue section.
- [ ] Has a "when to call" rule explicit enough to fire reliably ("call X when Y arrived", not "X is available").
- [ ] Appears in at least one few-shot demo, OR the rule is sharp enough that a demo would be redundant.

For every tool listed in the prompt catalogue:

- [ ] Actually registered at the tool-registration site. (Catch dangling docs for deleted tools.)

### 3. Dead-reference grep

Grep the prompt for references to types, features, run-kinds, or specialties that may have been deleted:

- Few-shot demos referencing deleted features (e.g. a demo for `appointment-pre` after Appointments is removed).
- Reasoning-guidance lines naming run kinds the runtime no longer emits.
- Tool catalogue entries for tools no longer registered.
- "Hard guardrails" naming concepts that have been renamed or merged.

Each dangling reference is a hallucination invitation — the model will reach for the removed feature in production.

### 4. Rule sharpness

For each behavioural rule in the prompt, check it answers all of:

- **When**: under what observable input does this rule fire?
- **What**: what does the model do when it fires?
- **Why not**: what would make the model skip it?

Rules that fail the "when" test are vibes. Rewrite them or delete them.

### 5. Output schema ↔ runtime parser

If the prompt prescribes an output schema (envelope, JSON shape, structured reply):

- [ ] Every field the parser reads is described in the prompt.
- [ ] Every field the prompt mentions is consumed somewhere (or explicitly noted as optional).
- [ ] Few-shot demos use the exact field names the parser expects.

## Report

Output a single review with:

- **Dangling references** — prompt mentions of things that no longer exist in code.
- **Untriggered tools** — registered tools with no "when to call" rule.
- **Unimplemented rules** — prompt rules without a runtime hook to enforce or surface them.
- **Schema drift** — fields the parser reads but the prompt doesn't describe, or vice versa.

No filler. If a section is empty, write "none".
