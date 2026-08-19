---
name: to-mockup
description: Render the product's screens — every feature state from definitions/frd.md, wearing the visual identity from definitions/surfaces.md — as one annotated, self-contained definitions/mockup.html plus a definitions/mockup.md index. Use after /to-frd and pick-ui-surfaces, before /to-spec, so the screens can be argued with before any product code exists. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

Draw the product before building it. Until now the UI exists only as tables: `definitions/surfaces.md` says the accent is amber and the nav is a sidebar, `definitions/frd.md` says the approval queue has an empty state and an over-limit state. Nobody has seen a screen. This is where they do.

**The mockup is a decision instrument, not a deliverable.** Its real output is the amendments it provokes — the state nobody had thought about, the journey that needs four taps, the identity that looked fine in a table and wrong on a page. Ship the findings back into `definitions/frd.md` and `definitions/surfaces.md` through amend mode, then re-render. What survives is what `/to-spec` builds against.

## 0. Skip check

If the product is a CLI, API, library, or otherwise headless, stop — there is nothing to draw. Tell the user and exit without writing anything.

## Amend mode

If `definitions/mockup.html` already exists and this run is a scoped change, run in amend mode per `${SKILL_DIR}/../../docs/amend-mode.md` (`${SKILL_DIR}` = the directory containing this file): keep the file as baseline, add or edit only the panels the change touches, leave every other panel byte-for-byte alone, and update the Amendment header in `definitions/mockup.md`. Deleting a feature deletes its panels — a mockup showing a screen the FRD no longer contains is worse than no mockup.

## 1. Read the inputs

| File | What it supplies | If missing |
|---|---|---|
| `definitions/frd.md` | The screen list. Every row of every feature's **States** table is one panel | Stop; prompt `/to-frd` |
| `definitions/surfaces.md` | The identity every panel wears, plus nav shell, error states, onboarding | Stop; prompt `pick-ui-surfaces` |
| `definitions/prd.md` | The persona and CUJs the panels are populated with | Stop; prompt `/to-prd` |

## 2. Build the panel inventory before drawing anything

One panel per FRD state, plus the states `pick-ui-surfaces` owns that the FRD doesn't: 404, 403, 500, offline, session expired, rate limited, maintenance, quota exceeded — and each onboarding moment. Then add the states everyone forgets and nobody specified: first-run empty, single-item, long-list overflow, longest realistic string, loading, partial failure, and the smallest supported viewport for any surface the PRD says is used on a phone.

Show the inventory to the user and get it agreed **before** writing HTML. Rendering the wrong set of screens beautifully is the expensive mistake here.

## 3. Draw it

One file: `definitions/mockup.html`. Self-contained — no build step, no framework, no CDN, no network request of any kind. It must open correctly from a `file://` URL on a machine with no toolchain.

**Identity comes from the artifact, not from taste.** Declare the `definitions/surfaces.md` visual identity once as CSS custom properties at the top of the file — accent ramp, neutrals, spacing scale, fonts, radius, the two shadow sizes — and let every panel inherit them. This is the first place those picks become real; `ui-taste` reads the same values from the SPEC later, so a value invented here and not written back to `surfaces.md` is drift you are creating on purpose. When the identity is missing something a panel needs, amend `surfaces.md` — never hardcode past it.

**Content is real.** Populate panels with the PRD's persona, their actual data, plausible names, plausible dates, plausible volumes. Never lorem ipsum, never "Item 1 / Item 2" — fake-shaped content hides the layout problems the mockup exists to find. A list that looks fine at three rows and breaks at forty is exactly what you are looking for.

**Every panel is annotated, in the page.** Beside each screen, visible in the browser, not buried in an HTML comment:

- Which FRD feature and state it renders (`F3 · over-limit`).
- Which CUJ step it sits in, if any.
- What it locks — the decision this drawing settles.
- The open question it raises, if it raises one. These become the `mockup.md` findings.

**Structure for both readers.** A person needs a sticky index rail to jump between features. A browser automation needs a stable hook: give every panel `id="<feature-id>-<state>"` and `data-state="<state>"` so a Playwright check can screenshot a named state directly. Group panels by feature, in FRD inventory order.

Keep the CSS honest to what a real implementation would do — flexbox and grid, relative units, a real focus ring, the actual minimum tap target. A mockup that cheats with absolute pixel positioning teaches nothing about whether the layout works.

## 4. Look at it

Open the file and look at every panel before showing the user — in a real browser, at the real viewports the PRD names. Playwright is already the project's UI verification tool (AGENTS.md's web-UI rule); use it here to screenshot each panel and read your own output. An unviewed mockup is a guess with extra steps.

Check the things that only show up rendered: text that overflows its container, a state that is visually identical to a different state, contrast that fails against the chosen neutrals, a primary action below the fold at the smallest viewport, a panel whose annotation and drawing disagree.

## 5. Walk the user through it

Present `definitions/mockup.html` and ask them to open it. Then walk the CUJs — for each journey in the PRD, name the panels in order and ask whether that is the flow they wanted. This is the review the whole skill exists for, so make it easy to say no.

Sort what comes back:

| Finding | Action |
|---|---|
| A state nobody specified | Amend `definitions/frd.md`, then re-render the panel |
| Identity is wrong on the page | Amend `definitions/surfaces.md`, then re-render everything |
| The journey needs different steps | Amend `definitions/prd.md`'s CUJ, then cascade |
| Just this drawing is wrong | Fix the panel; no artifact change |

Re-render and re-present until the user has no findings. Then write `definitions/mockup.md` and commit both files.

## 6. Hand off

Prompt the user to run `/to-spec` — it reads `definitions/mockup.md` alongside the PRD, FRD, and surfaces, and treats the agreed panel inventory as the UI contract each slice must satisfy.

<mockup-index-template>

## Sources

`definitions/prd.md` · `definitions/frd.md` · `definitions/surfaces.md` — and `definitions/mockup.html`, the drawing this file indexes.

## TL;DR

One paragraph: how many panels, which features they cover, what the drawing changed upstream, and what is still open.

## Panel inventory

| Panel id | Feature · state | CUJ step | Viewport | What it locks |
|---|---|---|---|---|

Every row must exist as an `id` in `definitions/mockup.html`, and every FRD state must appear as a row. A gap in either direction is drift — fix it before committing.

## What the mockup changed

The findings that turned into amendments. This is the section that proves the mockup earned its cost.

| Finding | Artifact amended | Change |
|---|---|---|

## Rejected drawings

| Alternative | Why rejected |
|---|---|

Layouts and treatments that were drawn and discarded. Prevents re-drawing them next increment.

## Open questions

What the drawing surfaced and the review could not settle, each naming what would settle it. Anything load-bearing goes to the PRD's Risks table instead.

</mockup-index-template>
