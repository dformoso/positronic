---
name: pick-surfaces
description: Pick the user-facing structural shape for a product with persistent UI surfaces. Invoked by define after /to-prd when the product has a UI. Walks nav, account, onboarding, settings, integration placement, error states, and compliance touchpoints — writes a versioned surfaces/ artifact that /to-spec reads. Use when the product has persistent UI surfaces (web app, mobile, dashboard, extension). Skip for CLI, API, library, or headless.
---

You are picking the user-facing structural shape for a product with persistent UI surfaces. These decisions — nav, account flow, onboarding, settings, error states — get skipped at the PRD level because they're not vision-shaping, and at the SPEC level because they're not implementation. They land here.

Ask one question at a time. Surface a recommended answer with each, grounded in the PRD's user, form factor, and constraints.

## 0. Skip check

If the product is a CLI, API, library, or otherwise headless (no persistent UI), stop here — there's no surface shape to pick. Tell the user and exit without writing an artifact.

Run pick-surfaces only when the user lives inside a persistent UI: web app, mobile app, dashboard, browser extension, or similar.

## 1. Read the PRD

Before any picks, read the most recent PRD: `ls prds/[0-9]*.md | sort | tail -1`. The PRD's target user, form factor, external channels, integrations, and any compliance constraints are the inputs that drive sections 2–9 — picking without them is picking blind.

If no PRD exists, stop and prompt the user to run `/to-prd` first.

Record the PRD path; it goes into the artifact (section 10).

## 2. Navigation & shell

The persistent chrome the user lives inside.

| Option | Best for |
|---|---|
| Top nav | Few top-level destinations; marketing-adjacent product |
| Sidebar (collapsible) | Many destinations; dashboard-style apps |
| Bottom tabs (mobile) | Mobile-first; 3–5 destinations max |
| Command-palette-first | Power-user tools; keyboard-native |
| Hybrid (sidebar + topbar) | Multi-tenant apps with workspace switching |

Also decide: global search? command palette? in-app notifications inbox (the bell icon, read/unread state)? help launcher? Per-device variations (mobile bottom tabs vs desktop sidebar)?

Per-device layout differences live here — not in the PRD.

## 3. Account & access lifecycle

For each moment, pick a mechanism and a default:

| Moment | Options |
|---|---|
| Sign-up | email+password / OAuth / magic-link / invite-only / SSO |
| Sign-in | same set; can differ from sign-up |
| Recovery | email reset / SMS / recovery codes / contact support |
| MFA | required / optional / off |
| Account deletion | self-serve / contact-support / disabled |
| Multi-user invites | open / approval required / domain-restricted / none |

For B2B/regulated products, lean toward SSO + required MFA. For consumer, lean toward OAuth + optional MFA. Read the PRD's target user and any compliance constraints (often in *Further Notes*) before recommending.

## 4. Onboarding & first-run

What the user sees before, during, and after the first CUJ.

| Moment | Trigger | What user sees | Skippable? |
|---|---|---|---|

Common moments to consider:

- First app load (cold)
- Account creation / signup
- Email verification
- Permission asks (notifications, mic, camera, location)
- Welcome screen / value-prop reminder
- Empty-state defaults (sample data, pre-filled workspace)
- First CUJ completion (next-step nudge)

Hard pushback on long tours: every tour step is a tax on time-to-value. Default to no tour; rely on empty states with inline CTAs.

## 5. Settings & preferences

One row per section, not per individual setting:

| Section | Contents | Default | Scope (user / workspace / org) |
|---|---|---|---|

Common sections:

- Profile (name, avatar, email, timezone, language)
- Notifications (channel toggles, cadence overrides)
- Integrations (connected services, OAuth tokens)
- Billing (plan, payment, invoices) — if commercial
- Security (password, MFA, sessions, devices, API keys)
- Workspace / org (members, roles, invites) — if multi-user
- Privacy (analytics opt-out, third-party sharing)
- Theme / accessibility (light/dark, font size, motion)
- Danger zone (delete workspace, delete account)

Default policy: ship privacy-protective defaults (analytics off, sharing off) and convenience defaults for productivity (autosave on).

## 6. Integration placement

For each integration named in the PRD's *Integrations & migration* table, decide where in the UX it surfaces and when it's presented:

| Integration | Where surfaced | When presented |
|---|---|---|

Where options: Settings → Integrations / top-level Integrations tab / inline in an onboarding step / contextual at first blocked action / background-only (no user touch).

When options: required at signup / required at first feature use / optional, prompted contextually / optional, discoverable only.

Status indicators (badges, health dashboards, broken-connection banners) decide here too.

## 7. Error & system states

What the user sees when things go wrong or aren't there yet.

| State | Trigger | What user sees | Recovery path |
|---|---|---|---|

Common states:

- 404 not found
- 403 forbidden
- 500 server error
- Network offline
- Rate limit hit
- Validation error (form-level)
- Session expired
- Maintenance mode
- Quota / plan limit exceeded

Recovery path matters more than copy: every error state needs a way out (retry, sign in, contact support, switch plan).

## 8. Help, support, status

Brief — where do users get help?

- In-app docs (drawer, linked-out, embedded search)
- Contact mechanism (chat widget, email, form)
- Public status page (yes / no; vendor: Statuspage, Better Stack, self-hosted)
- Changelog / what's new (in-app, blog, both)

Drop this section if the product is internal-only or pre-launch.

## 9. Compliance touchpoints

Drop if not regulated and not consumer-facing in regulated regions.

| Touchpoint | When | What user sees |
|---|---|---|

Common:

- TOS / Privacy Policy acceptance (signup)
- Cookie consent (first page load — EU/UK/CA)
- GDPR data export (in settings; user-triggered)
- GDPR data deletion (in settings; user-triggered)
- Age verification (signup, if applicable)
- Region / data residency selection (signup, for enterprise)

If the PRD names a regulated industry (financial, healthcare, government) or EU/UK users, this section is mandatory.

## 10. Save the artifact

Once the sections above have been answered, write the picks to `surfaces/YYYY-MM-DD-HH-mm-SS.md` (current local time; create `surfaces/` if missing). This file is the source of truth that `/to-spec` reads downstream — do not skip it, and do not paraphrase only in-conversation.

Length and density: as long as you need — preferably tight. Tables only, no prose, drop sections that don't apply. Every section must carry information: cite the PRD constraint that grounded the call, and record rejected alternatives so future agents don't re-open settled decisions. Commit the file.

<surfaces-template>

## Source PRD

`prds/<file>.md` — the PRD whose constraints drove these picks.

## TL;DR

One paragraph naming the nav shape, signup mechanism, settings section count, error-state strategy, and any compliance touchpoints. A reader should be able to skip the rest and still know the shape.

## Navigation & shell

**Picked:** top-nav | sidebar | bottom-tabs | command-palette-first | hybrid
**Per-device variation:** (if relevant)
**Global elements:** search? command palette? in-app notifications inbox? help launcher?
**Why:** one or two sentences. Cite the PRD constraint (form factor, target user).

## Account & access lifecycle

| Moment | Mechanism | Default | Notes |
|---|---|---|---|

## Onboarding & first-run

| Moment | Trigger | What user sees | Skippable? |
|---|---|---|---|

## Settings & preferences

| Section | Contents | Default | Scope |
|---|---|---|---|

## Integration placement

| Integration | Where surfaced | When presented |
|---|---|---|

## Error & system states

| State | Trigger | What user sees | Recovery path |
|---|---|---|---|

## Help, support, status

Brief — in-app docs surface, contact mechanism, status page.

## Compliance touchpoints

| Touchpoint | When | What user sees |
|---|---|---|

(Drop if not regulated.)

## Rejected alternatives

| Alternative | Why rejected |
|---|---|

Prevents future re-suggestion. Include at minimum the nav shape and account flow seriously considered.

## Open questions

Decisions deferred to `/to-spec` (e.g., exact module boundaries, schema for settings storage, OAuth provider implementation) or things that surfaced but couldn't be settled with current information.

</surfaces-template>

## Hand-off

Present the saved `surfaces/<file>.md` and ask the user to review. Once approved:

- If a custom LLM/agent harness is also on the table, prompt them to run `pick-harness-shape` next — it benefits from knowing the UI surfaces it slots into.
- Otherwise, prompt them to run `/to-spec` — it will read this file alongside the PRD automatically.
