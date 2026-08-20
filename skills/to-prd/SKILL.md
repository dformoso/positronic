---
name: to-prd
description: Turn the current conversation context into a two-page PRD — problem, target user, metrics with kill criteria, journeys named in two sentences each, scope, and the change tier that decides how far the change travels — and save it as definitions/prd.md. Use when the user wants to create or amend a PRD. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

Turn the current conversation, codebase understanding, and (if they exist) the most recent ideation winner + research artifact into a PRD. Do NOT interview the user — synthesize what you already know.

The PRD answers *what and why*, and nothing else. Keep it short enough that a person actually re-reads it before every increment — that is the job it does that no other artifact does.

Everything downstream has its own home. Don't write here what belongs there:

| Detail | Owner |
|---|---|
| What the user does step by step, and how you prove it worked — plus entities, channels, autonomy matrix, queues, rules | `definitions/journeys.md` (`/to-journeys`) |
| How the app is arranged, how it looks, and what every screen shows | `definitions/mockups.md` + `definitions/mockups.html` (`/to-mockups`) |
| How it is built — modules, code-level schema, API contracts, test plan, rollout, observability | `definitions/spec.md` (`/to-spec`) |

## Amend mode

If `definitions/prd.md` exists and this is a scoped change rather than a rebuild, follow `${SKILL_DIR}/../../docs/amend-mode.md` (`${SKILL_DIR}` = the directory containing this file): edit only the sections the change touches, reconcile anything it contradicts, leave every other section byte-for-byte alone, update the Amendment header. Then name which downstream artifacts the touched sections implicate — any change to what the product does → `definitions/journeys.md`; Solution Overview surfaces / form factor → `definitions/mockups.md`; Goals & Success Metrics or kill criteria → the SPEC's Observability product-metric table and the `/readout` date — and prompt only those, then `/to-spec`.

## Inputs

- Current conversation
- `definitions/ideas.md` if it exists — the section marked WINNER (chosen idea, grounded in research)
- `definitions/research.md` if it exists (supporting evidence)
- `judgments/<latest>.md` if it exists (verdict on the winner from `/judge-idea`): `ls judgments/[0-9]*.md | sort | tail -1`
- The codebase, if a project already exists

If the latest judgment targets the current winner, ensure its `**Verdict.**` line reads `proceed` before writing the PRD. If the verdict was `loop-back-to-research`, `loop-back-to-ideate`, or `pivot`, prompt the user to address the judgment first and stop.

## Process

1. Explore the repo if you haven't already.

2. **Test-surface check.** If the solution implies a high-friction form factor (native mobile, hardware, browser extension, app-store-gated), surface the tradeoff before writing: is there a cheaper surface (web app, CLI, hosted prototype) that validates the same hypothesis first? Get the user's call. Document the decision in the PRD.

3. Write the PRD using the template below. Save as `definitions/prd.md` (create `definitions/` if missing). Commit it. Do not submit it as a GitHub issue.

4. Length and density: ≤ 2 pages. Target User + Solution Overview together must fit in ≤ 1 page: tight but comprehensive. These two anchor the contract every downstream artifact is built against; drift from them produces unusable output. Nothing here scales with product surface — that is `/to-journeys`'s job, and it is why this document can stay short. Every sentence must carry information. No padding, no repetition, no restating the obvious.

5. **Style.** One register throughout: plain English a person matching the target persona could follow without a glossary. Short sentences, one idea each, concrete before abstract, every term of art glossed on first use (AGENTS.md §4).

   - No vendor, SDK, protocol, or regulatory jargon anywhere. "Twilio Voice SDK", "CallKit-integrated", "OAuth flow" belong in `definitions/journeys.md`. This document says what the user experiences; the journeys say how.
   - One layer of detail per sentence — no inline tutorials, nested parentheticals, or em-dash asides inside parentheses. More layers means a bullet list or table row.
   - Name concrete artifacts, not abstract actions. "Drafts customers, jobs, quotes, invoices" beats "structures inbound". Offenders: *absorbs*, *structures*, *processes*, *handles* — usually a sign you haven't named the artifact yet.
   - Cross-cutting / multi-channel behaviour → short lede + one bullet per channel.
   - Name surfaces with real product nouns (Convos, Triage, Ledger, To-Approve — not "data pane / agent pane"). Bold every mention in Solution Overview and Key User Journeys.

6. Present the saved PRD and ask the user to review. Then prompt for the next step in this order:
   - Prompt them to run `/to-journeys` — it expands each journey above into an executable script with steps, branches, and the end-state proof a test asserts. Everything after this reads that file, so it is the default next step, not an optional one.
   - On greenfield (this is the project's first PRD), also prompt them to run `/to-infrastructure` in greenfield mode — it locks the dev-to-prod path as the first section of `definitions/infrastructure.md`; the SPEC's Rollout section cites it.
   - For a `fix`- or `internal`-tier change that adds no new behaviour, `/to-journeys` can be skipped — go straight to `/to-spec`.

   (`/judge-idea` can also gate the finished PRD before `/to-spec` if a bet feels unverified — optional.)

<prd-template>

## Change tier

One word, at the top, decided rather than inherited — it names which artifacts this change must touch. The full ladder is in `${SKILL_DIR}/../../docs/amend-mode.md`.

`fix` · `internal` · `feature` · `launch`

Applying the heaviest tier to everything is the failure mode of a framework like this. A copy change is a `fix`; it does not get a journey script, a redrawn mockup, and a cutover runbook.

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

**Kill criteria.** The exact threshold — a number and a behaviour — that means pivot or die. `define` set this when the hypothesis was framed; carry it here, because this is the document `/readout` reads weeks after launch to decide keep / iterate / cut / pivot. A metric with no kill criterion is decoration: nothing can ever fail it, so nothing is ever learned from it.

| Kill criterion | By when | What we do if it fires |
|---|---|---|
| | | |

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

## Risks & Open Questions

**Top 5 only.** The load-bearing risks and open questions — the ones that, if wrong, change the product.

| Item | Type (risk / open question) | Impact if wrong | Plan to resolve |
|---|---|---|---|
| | | | |

If `/judge-idea` produced findings worth carrying into implementation, list them here.

## Further Notes

Any further notes about the feature — pricing direction, distribution thinking, UX constraints, compliance, the 12-month directional bet, source research pointers. **Half a page max.**

</prd-template>
