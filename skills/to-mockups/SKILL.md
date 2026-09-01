---
name: to-mockups
description: Design the user-facing shape of a product with persistent UI, then draw it. Picks visual identity (feel, signature, accent, type, spacing), nav, account, onboarding, settings, integration placement, error states and compliance into definitions/mockups.md, then renders every journey step and branch as annotated panels in one self-contained definitions/mockups.html. Use after /to-journeys when the product has a UI; skip for CLI, API, library, or headless. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

You are designing the user-facing shape of a product with persistent UI surfaces, in two halves that belong to one activity:

- **Pick** (sections 1–10) — the **visual identity** every surface inherits, and the **structure** it lives in: nav, account flow, onboarding, settings, error states. These get skipped at the PRD level because they're not vision-shaping, and at the SPEC level because they're not implementation.
- **Draw** (sections 11–14) — those picks and every journey step rendered as real screens, in one self-contained HTML file, before any product code exists.

They are one skill because the dependency runs one way and runs all the way: you cannot draw a panel without an identity, and the identity's only proof is the drawing. Picking in one session and drawing in another means finding out the nav is wrong after it's been written down as settled. Here, a drawing that doesn't work sends you back up to section 3 in the same breath.

Ask one question at a time through the picking half. Surface a recommended answer with each, grounded in the PRD's user and the journeys the surfaces have to carry.

## 0. Skip check

If the product is a CLI, API, library, or otherwise headless (no persistent UI), stop here — there's no surface shape to design. Tell the user and exit without writing an artifact.

Run this only when the user lives inside a persistent UI: web app, mobile app, dashboard, browser extension, or similar.

## Amend mode

If `definitions/mockups.md` exists and this is a scoped UI change rather than a rebuild, follow `${SKILL_DIR}/../../docs/amend-mode.md` (`${SKILL_DIR}` = the directory containing this file): edit only the sections the change touches, reconcile anything it contradicts, leave every other section byte-for-byte alone, update the Amendment header.

The drawing amends too, in step with the picks. Add or edit only the panels the change touches and leave the rest byte-for-byte alone — except when the **visual identity** changed, which re-renders everything, because every panel inherits it. A change that touches no journey step and no identity field draws nothing; that's a correct outcome, not a skipped step. Deleting a journey deletes its panels: a drawing of a screen the product no longer has misleads worse than no drawing at all. Then prompt `/to-spec`.

## 1. Read the PRD and the journeys

Before any picks, read both:

- `definitions/prd.md` — target user, form factor, compliance constraints. If it doesn't exist, stop and prompt `/to-prd`.
- `definitions/journeys.md` — the journey scripts whose steps name the screens they show, plus the channels, integrations, queues and notification modes these surfaces have to hold. If it doesn't exist, stop and prompt `/to-journeys`; picking a nav shape without knowing what the user walks through is picking blind, and the drawing half has no panel list at all.

Record both paths; they go into the artifact.

## 2. Visual identity

The look every surface inherits — decided once here so parallel implementers don't each invent one (they would diverge). `ui-taste` reads these picks at build time and applies them; it does not re-pick them per screen. Recommend a feel and signature grounded in the PRD's user before asking — don't start the user from blank.

| Field | Pick | Note |
|---|---|---|
| Register | brand or product | brand = design *is* the product (marketing, landing, portfolio); product = design *serves* the task (app, dashboard, tool). Gates motion budget, colour boldness, and how much familiar-pattern reuse is a feature. `ui-taste` branches on it. |
| Who | the actual user, one line | not "users" — a teacher at 7am ≠ a dev at midnight |
| Feel | specific words ("warm like a notebook") | never "clean and modern" — every AI says that |
| Signature | one element only this product would have | visual, structural, or interactive; can't name one? keep digging |
| Accent | one hue + 50–950 ramp; semantic roles (success/warning/danger/info) | saturated colour on small areas only |
| Neutrals | warm or cool tint; near-black + off-white | never #000/#fff; dark surfaces start at #121212 |
| Spacing base | 4 (dense tools) or 8 (consumer) | one scale: 4, 8, 12, 16, 24, 32, 48, 64 |
| Fonts | body + optional display, two max | system stack is fine; body ≥16px |
| Depth & motion | one border colour, two shadow sizes, motion budget | elevation as hierarchy; animate only to communicate |

## 3. Navigation & shell

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

## 4. Account & access lifecycle

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

## 5. Onboarding & first-run

What the user sees before, during, and after the first CUJ.

| Moment | Trigger | What user sees | Skippable? |
|---|---|---|---|

Cover cold first load, signup and verification, every permission ask, empty-state defaults, and the nudge after the first CUJ completes.

Hard pushback on long tours: every tour step is a tax on time-to-value. Default to no tour; rely on empty states with inline CTAs.

## 6. Settings & preferences

One row per section, not per individual setting:

| Section | Contents | Default | Scope (user / workspace / org) |
|---|---|---|---|

The usual set — profile, notifications, integrations, security, privacy, theme, danger zone, plus billing if commercial and workspace if multi-user. Two that get mis-scoped: **theme** here is the user-facing switch, not the palette (that's §2), and **danger zone** must reach every store the account touches, or §10's deletion touchpoint is a lie.

Default policy: ship privacy-protective defaults (analytics off, sharing off) and convenience defaults for productivity (autosave on).

## 7. Integration placement

For each integration named in the journeys artifact's *Integrations & migration* table, decide where in the UX it surfaces and when it's presented:

| Integration | Where surfaced | When presented |
|---|---|---|

Where options: Settings → Integrations / top-level Integrations tab / inline in an onboarding step / contextual at first blocked action / background-only (no user touch).

When options: required at signup / required at first feature use / optional, prompted contextually / optional, discoverable only.

Status indicators (badges, health dashboards, broken-connection banners) decide here too.

## 8. Error & system states

What the user sees when things go wrong or aren't there yet.

**Only system states belong here** — the ones that look the same whatever the user was doing. A state that belongs to one journey (this field rejects a past date; the approval queue is empty; the plan's monthly limit is spent) is a **branch** in `definitions/journeys.md` and lives there. Both sets get drawn in section 12.

| State | Trigger | What user sees | Recovery path |
|---|---|---|---|

Cover the standard set: 404, 403, 500, offline, rate-limited, session expired, maintenance, quota exceeded.

Recovery path matters more than copy: every error state needs a way out (retry, sign in, contact support, switch plan).

## 9. Help, support, status

Brief — where do users get help?

- In-app docs (drawer, linked-out, embedded search)
- Contact mechanism (chat widget, email, form)
- Public status page (yes / no; vendor: Statuspage, Better Stack, self-hosted)
- Changelog / what's new (in-app, blog, both)

Drop this section if the product is internal-only or pre-launch.

## 10. Compliance touchpoints

Drop if not regulated and not consumer-facing in regulated regions.

| Touchpoint | When | What user sees |
|---|---|---|

Terms and privacy acceptance at signup, cookie consent on first load (EU/UK/CA), user-triggered data export and deletion in settings, plus age verification and residency selection where they apply.

If the PRD names a regulated industry (financial, healthcare, government) or EU/UK users, this section is mandatory.

## 11. Write the picks down

Once the sections above have been answered, write them to `definitions/mockups.md` (create `definitions/` if missing). This file is the source of truth `/to-spec` reads and `ui-taste` applies at build time — do not skip it, and do not paraphrase only in-conversation. Leave *Panel inventory* and *What the drawing changed* empty for now; section 12 fills them.

Length and density: as long as you need — preferably tight. Tables only, no prose, drop sections that don't apply. Plain English in every cell — no jargon a reader outside this conversation would have to look up (AGENTS.md §4). Every section must carry information: cite the PRD or journey constraint that grounded the call, and record rejected alternatives so future agents don't re-open settled decisions.

<mockups-template>

## Sources

`definitions/prd.md` — the user, form factor, and constraints that drove these picks.
`definitions/journeys.md` — the journey steps and branches these surfaces carry and the drawing renders.
`definitions/mockups.html` — the drawing these picks produced.

## TL;DR

One paragraph naming the feel + signature, nav shape, signup mechanism, settings section count, error-state strategy, and any compliance touchpoints. A reader should be able to skip the rest and still know the shape.

## Visual identity

| Field | Picked |
|---|---|
| Register | |
| Who | |
| Feel | |
| Signature | |
| Accent + ramp | |
| Neutrals (tint, near-black, off-white) | |
| Spacing base | |
| Fonts (body / display) | |
| Depth & motion | |

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

## Panel inventory

| Panel id | Renders | Viewport | What it locks |
|---|---|---|---|

Every row must exist as an `id` in `definitions/mockups.html`, and every journey step and branch that names a panel must appear as a row; no row may name a step or journey the journeys artifact no longer has. A gap in either direction is drift — `audit-drift` check 2.5 reconciles the rows against the ids and against the steps that name panels, but fix it before committing. A step with no screen names no panel and gets no row. A step the user watches happen does have a screen, so a blank Panel cell there is drift in `definitions/journeys.md`, not licence to skip a panel here.

## What the drawing changed

The findings that turned into amendments. This is the section that proves the drawing earned its cost; an empty one after a real product's first render usually means nobody looked hard enough.

| Finding | Artifact amended | Change |
|---|---|---|

## Rejected alternatives

| Alternative | Why rejected |
|---|---|

Prevents future re-suggestion. Include at minimum the feel, nav shape, and account flow seriously considered, plus any layout that was drawn and discarded.

## Open questions

Decisions deferred to `/to-spec` (e.g., exact module boundaries, schema for settings storage, OAuth provider implementation) or things that surfaced but couldn't be settled with current information.

</mockups-template>

## 12. Draw it

Now make the picks real. **The drawing is a decision instrument, not a deliverable** — its output is the amendments it provokes: the branch nobody had thought about, the journey that needs four taps, the identity that looked fine in a table and wrong on a page.

**Build the panel inventory before drawing anything.** One panel per row of every journey's step table that names a panel, one per row of every Branches table, plus the system states section 8 owns (404, 403, 500, offline, session expired, rate limited, maintenance, quota exceeded) and each onboarding moment from section 5. A step whose Panel cell is blank has nothing on screen — a background job, an external system's move — and is the only row that skips; every branch draws, because branches are where panels get skipped. Then add the states everyone forgets and nobody specified: first-run empty, single item, long-list overflow, longest realistic string, loading, partial failure, and the smallest viewport the PRD says is used. Show the inventory to the user and get it agreed **before** writing HTML — rendering the wrong set of screens beautifully is the expensive mistake here.

Then write one file: `definitions/mockups.html`. Self-contained — no build step, no framework, no CDN, no network request of any kind. It must open correctly from a `file://` URL on a machine with no toolchain.

- **Identity comes from section 2, not from taste.** Declare it once as CSS custom properties at the top and let every panel inherit them. A value invented here and not written back to section 2 is drift you are creating on purpose.
- **Content is real.** Use the Data line from each journey — the actual names, numbers, and timestamps it already specifies. Never lorem ipsum, never "Item 1 / Item 2": fake-shaped content hides the layout problems the drawing exists to find. A list that looks fine at three rows and breaks at forty is exactly what you are looking for.
- **Every panel is annotated, in the page** — visible in the browser, not buried in an HTML comment. Which journey step or branch it renders (`J1 · step 4`, `J1 · branch: carrier rejects`), what it locks, and the open question it raises if it raises one.
- **Structure for both readers.** A person needs a sticky index rail to jump between journeys. Automation needs a stable hook: give every panel `id="<journey>-<step-or-branch>"` and `data-state="…"`, matching the Panel column in `definitions/journeys.md`, so a Playwright check can screenshot a named state directly. Group panels by journey, in inventory order.
- Keep the CSS honest to what a real implementation would do — flexbox and grid, relative units, a real focus ring, the actual minimum tap target. A drawing that cheats with absolute pixel positioning teaches nothing about whether the layout works.

## 13. Look at it

Open the file and look at every panel before showing the user — in a real browser, at the real viewports the PRD names. Playwright is already this project's UI verification tool (AGENTS.md's web-UI rule); use it here to screenshot each panel and read your own output. An unviewed drawing is a guess with extra steps.

Check what only shows up rendered: text overflowing its container, two states that look identical, contrast failing against the chosen neutrals, a primary action below the fold at the smallest viewport, a panel whose annotation and drawing disagree.

## 14. Walk the user through it, and settle

Present `definitions/mockups.html` and ask them to open it. Then walk the journeys — for each one, name the panels in step order and ask whether that is the flow they wanted. This is the review the whole skill exists for, so make it easy to say no.

Sort what comes back:

| Finding | Action |
|---|---|
| Identity or structure is wrong on the page | Go back to sections 2–10, re-pick, re-render everything the change touches |
| A step or branch nobody specified | Amend `definitions/journeys.md`, then draw the new panel |
| The journey needs different steps | Amend the PRD's CUJ, then cascade down |
| Only this drawing is wrong | Fix the panel; no artifact change |

Re-render and re-present until the user has no findings. Then fill in the artifact's *Panel inventory* and *What the drawing changed* sections, and commit both files together — they are one decision and their diffs should sit in one commit.

## Hand-off

Once the user approves both files:

- If a custom LLM/agent harness is also on the table, prompt them to run `pick-harness-shape` next — it benefits from knowing the UI surfaces it slots into.
- Then prompt them to run `/to-spec` — it reads `definitions/mockups.md` alongside the PRD and journeys automatically, restates the visual identity inline so every UI issue inherits one identity, and treats the agreed panel inventory as the UI contract each slice must satisfy.
