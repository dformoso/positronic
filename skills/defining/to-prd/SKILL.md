---
name: to-prd
description: Turn the current conversation context into a PRD and save it as a versioned local file. Use when user wants to create a PRD from the current context.
disable-model-invocation: true
---

Turn the current conversation, codebase understanding, and (if they exist) the most recent ideation winner + research artifact into a PRD. Do NOT interview the user — synthesize what you already know.

The PRD answers *what and why* — including the product surface behaviour under Functional Requirements (data shapes the user sees, external channels, autonomy rules, queues, integrations). UX shape and visual identity (nav, onboarding, settings, account lifecycle, error states; feel, accent, type) live in `pick-ui-surfaces`. Implementation decisions (modules, code-level schema, API contracts, test plans, rollout, observability) live in `/to-spec`, not here.

## Amend mode

If a prior `definitions/prds/[0-9]*.md` exists and this run is a scoped change (not a from-scratch rebuild), run in amend mode per `${CLAUDE_SKILL_DIR}/../../../docs/amend-mode.md`: read the latest PRD as baseline, carry forward every untouched section *verbatim* (reconcile any the change contradicts), apply the delta, and write a new complete snapshot with an Amendment header. Then name which downstream artifacts the touched sections implicate (Agent autonomy → `definitions/harness/`; Solution Overview surfaces / form factor → `definitions/surfaces/`; new channels or tools → `definitions/mcp-servers/`) and prompt only those, then `/to-spec`.

## Inputs

- Current conversation
- `definitions/ideas/<latest>/winner.md` if it exists (chosen idea, grounded in research)
- `definitions/research/<latest>/summary.md` if it exists (supporting evidence)
- `judgments/<latest>.md` if it exists (verdict on the winner from `/judge-idea`): `ls judgments/[0-9]*.md | sort | tail -1`
- The codebase, if a project already exists

If the latest judgment targets the current winner, ensure its `**Verdict.**` line reads `proceed` before writing the PRD. If the verdict was `loop-back-to-research`, `loop-back-to-ideate`, or `pivot`, prompt the user to address the judgment first and stop.

## Process

1. Explore the repo if you haven't already.

2. **Test-surface check.** If the solution implies a high-friction form factor (native mobile, hardware, browser extension, app-store-gated), surface the tradeoff before writing: is there a cheaper surface (web app, CLI, hosted prototype) that validates the same hypothesis first? Get the user's call. Document the decision in the PRD.

3. Write the PRD using the template below. Save as `definitions/prds/YYYY-MM-DD-HH-mm-SS.md` (use `date +"%Y-%m-%d-%H-%M-%S"`; create `definitions/prds/` if missing). Commit it. Do not submit it as a GitHub issue.

4. Length and density: ≤ 5 pages — preferably less. Target User + Solution Overview together must fit in ≤ 1 page: tight but comprehensive. These two anchor the contract `/to-spec` and implementation work against; drift from them produces unusable output. Functional Requirements is the section that scales with product surface — drop tables that don't apply. Every sentence must carry information. No padding, no repetition, no restating the obvious.

5. **Style.** Two registers. **Functional Requirements** is the technical tier — vendor names, SDK names, regulatory mechanics, OAuth flows, MMS pricing — packed into tables, not prose. Every other section is plain English: someone matching the target persona could follow it without a glossary.

   - No vendor, SDK, protocol, or regulatory jargon outside Functional Requirements. "Twilio Voice SDK", "CallKit-integrated", "OAuth flow" belong in cells. Solution Overview says what the user experiences; Functional Requirements says how.
   - One layer of detail per sentence — no inline tutorials, nested parentheticals, or em-dash asides inside parentheses. More layers means a bullet list or table row.
   - Name concrete artifacts, not abstract actions. "Drafts customers, jobs, quotes, invoices" beats "structures inbound". Offenders: *absorbs*, *structures*, *processes*, *handles* — usually a sign you haven't named the artifact yet.
   - Cross-cutting / multi-channel behaviour → short lede + one bullet per channel.
   - Name surfaces with real product nouns (Convos, Triage, Ledger, To-Approve — not "data pane / agent pane"). Bold every mention in Solution Overview and Key User Journeys.

6. Present the saved PRD and ask the user to review. Then prompt for the next step in this order:
   - If the product has persistent UI surfaces, prompt them to run `pick-ui-surfaces`.
   - If the project involves a custom LLM/agent harness, prompt them to run `pick-harness-shape` (after `pick-ui-surfaces`, if both apply).
   - Otherwise, prompt them to run `/to-spec`.

   (`/judge-idea` can also gate the finished PRD before `/to-spec` if a bet feels unverified — optional.)

<prd-template>

## Problem Statement

The problem in the user's words. Two to four sentences max.

## Target User

A specific, named persona (or representative composite) that captures who this product is for. Their work, their world, the moments where this product enters their life, the constraints that shape their choices. Concrete beats generic — *"Nathan: a solo plumber in metropolitan or peri-urban Australia, 5–25 years in the trade, already pays for ServiceM8 or Tradify, hands wet/dirty/gloved during the day"* beats *"small business owner"*. **Half a page max.**

## Goals & Success Metrics

Lead with an **anchoring promise** — one sentence naming the visceral outcome the user feels ("no admin after 5pm", "ship in under 60 seconds", "never lose a customer to silence"). Then **at most three** metrics. No more — pick the ones that, if they move, the product is working.

| Metric | Target | How measured |
|---|---|---|
| | | |

Behavioral and outcome metrics are stronger than activity metrics. "% of users completing first CUJ within 24h" beats "page views".

## Solution Overview

What we're building, in user-facing terms. Form factor (web app / PWA / CLI / API / native), the structural pieces (the panes, surfaces, or objects the user sees), and — if AI is involved — the autonomy contract (what the agent does without asking, what it always asks first). Enough detail to anchor scope, not enough to lock implementation. **Half a page max.**

## Key User Journeys

Numbered CUJs. Each named, **two sentences max**, naming actor + trigger + flow + outcome. **Every journey names the surface(s) the user touches** (bolded — `**Convos**`, `**To-Approve**`, etc.) and the device when it differs from the surface's default. A reader should be able to point at which tab the user is on at each step. Comprehensive but not exhaustive — cut journeys that are obvious consequences of others.

1. **<Short name>.** <Two sentences max, surface-stamped, device-stamped where it matters>.

<cuj-example>
1. **First inbound from a new customer.** Mrs Chen rings at 2:14pm; Nathan doesn't answer, so AI voicemail takes the message and the agent sends an acknowledgement SMS in **Convos**. At the 4pm digest Nathan opens **To-Approve** on his phone, taps the draft reply card, and sends.
</cuj-example>

## Non-Goals

**Top 5 only.** Who and what we are explicitly **not** serving with this PRD. Adjacent personas, use cases, and platforms that might seem in scope but aren't. Sharpens the segment.

## Out of Scope

**Top 5 only.** Features explicitly not built in this PRD. Different from Non-Goals: this is about *what*, Non-Goals is about *who*. Both protect against scope creep. Entries cut by `/clean-house` carry *cut because* and *re-add trigger* — the observable signal that would justify building it after all — and don't count against the five.

## Functional Requirements

The product surface defined component-by-component, in tables. Cover every relevant component so `/to-spec` has unambiguous "what" to turn into "how". Use the table set below as a checklist — include the ones that apply, drop the rest, add domain-specific ones if needed. Prose only when a table can't carry the meaning. Every row needs an owner you could trace it to — a person, a research finding, a judgment — and a failure you can name if it's dropped; "best practice" and "the model suggested it" are departments, not owners. Rows without an answer go to Out of Scope. (`/clean-house` re-asks both questions of every surviving row between versions.)

**Data model.** The entities the user touches and what they hold. Implementation-level schema (indexes, constraints, migrations) goes to `/to-spec`.

| Entity | Key fields | Relationships |
|---|---|---|
| | | |

**External channels & touchpoints.** Every place the product receives input or emits output to the outside world (SMS, email, voice, API endpoints, push notifications, webhooks). Internal app surfaces (nav, panes, screens) → `pick-ui-surfaces`.

| Channel | Inbound behaviour | Outbound behaviour | Notes |
|---|---|---|---|
| | | | |

**Agent autonomy matrix.** (If AI is involved.) For every action the agent can take: default behaviour, confidence gate, HITL trigger. Anything that touches the user externally or commits resources defaults to HITL until explicitly justified.

| Action | Default | Confidence gate | HITL trigger |
|---|---|---|---|
| | | | |

**Queues / approval flows.** (If the product holds work for human review.) What each queue holds and its lifecycle. UX placement (where seen, badge counts, full-page vs drawer) → `pick-ui-surfaces`.

| Queue | Holds | Lifecycle |
|---|---|---|
| | | |

**Notification / digest cadence.** (If users get pushed updates.) Available modes, default, and override rules. The in-app notifications inbox (bell icon, read/unread state) → `pick-ui-surfaces`.

| Mode | Default? | Behaviour |
|---|---|---|
| | | |

**Integrations & migration.** Third parties the product reads from or writes to, plus how users bring existing data in. UX placement (where in the app, when presented) → `pick-ui-surfaces`.

| Integration | Direction | MVP behaviour |
|---|---|---|
| | | |

## Risks & Open Questions

**Top 5 only.** The load-bearing risks and open questions — the ones that, if wrong, change the product.

| Item | Type (risk / open question) | Impact if wrong | Plan to resolve |
|---|---|---|---|
| | | | |

If `/judge-idea` produced findings worth carrying into implementation, list them here.

## Further Notes

Any further notes about the feature — pricing direction, distribution thinking, UX constraints, compliance, the 12-month directional bet, source research pointers. **Half a page max.**

</prd-template>
