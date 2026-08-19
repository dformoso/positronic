---
name: ui-taste
description: Opinionated taste rules for visual interface work — avoids the generic, cookie-cutter look. Use when the user is building or styling frontend components, dashboards, marketing pages, design tokens, or anything users will see. Triggers on React/Vue/Svelte/HTML/CSS work, Tailwind, design system additions, or when the user says "make this look better", "style this", "design this screen", or shows a screenshot of something to improve.
---

# UI taste

Opinionated visual rules. Apply them when you write or change UI. If three or more are wrong on a screen, it looks generic — fix those first.

These rules are safe defaults, not laws. Break them when you have a reason; surface the reason.

## Work from the locked style

The visual identity — register, who, feel, signature, accent, neutrals, spacing base, fonts, depth/motion — is decided once, up front, by `/to-mockups` and restated in the SPEC's "Product surfaces" section. **Read it and apply it. Do not re-pick it per surface** — that is what makes parallel-built screens diverge.

**State the design read first.** Before building a surface, say in one line what you're building and how it should feel — "Reading this as: a settings page for a B2B admin (product register), restrained, state-rich, familiar patterns." It catches a wrong direction before any code.

**Register sets the defaults.** The locked identity names a register:

- **Product** (app, dashboard, tool — design *serves* the task): restrained colour, state-rich (hover / focus / active / disabled / loading / error), familiar patterns are a feature, motion only to communicate. The rules below are tuned for this.
- **Brand** (marketing, landing, portfolio — design *is* the product): can afford ambitious first-load motion, a committed or drenched palette, per-section art direction, asymmetric layout. The rules still hold, but rule 2 (greyscale-first) and rule 11 (motion budget) loosen deliberately — say so when you lean on that.

If no identity is recorded (the SPEC has none and there's no `definitions/mockups.md`), you're working pre-identity: name the register, who, feel, and signature yourself — feel in specific words ("warm like a notebook," never "clean and modern"), signature being one element only this product would have — record them so the next surface inherits them, then proceed.

Skip this for isolated tweaks (one button colour, a typo) where the direction is already set.

## 1. One primary thing per surface

Every screen has one job. Establish the primary element with size, weight, and contrast — not just colour. Demote everything else. If two buttons look equal, neither is primary.

- One filled primary button per view. Secondary actions are outlined or text-only.
- Destructive actions get their own treatment and sit away from the primary.
- Three levels of hierarchy max (primary / secondary / tertiary). More than three and the eye stops sorting.

## 2. Design in greyscale first

Strip colour before you start. Force the layout to work on hierarchy alone — size, weight, spacing, contrast. Add colour last, sparingly, and only where it carries meaning (brand accent, semantic state, data category). Colour is not decoration.

## 3. Spacing is hierarchy

Related things sit closer. Unrelated things sit farther. Inner padding ≤ outer margin. Apply the spacing base from the locked identity (4 or 8) on the fixed scale — `4, 8, 12, 16, 24, 32, 48, 64` — and never invent arbitrary values.

Uniform spacing is the #1 tell of generic UI. Vary it deliberately.

## 4. No pure black, no pure white

`#000` on `#fff` is harsh and flat. Body text wants near-black (e.g. `#111`–`#1f2937`). Background neutrals carry the warm-or-cool tint from the locked identity. Dark mode surfaces start at `#121212`, never `#000`; raise lightness with elevation, don't add shadows.

## 5. Two fonts max, four sizes max

Use the body and optional display fonts from the locked identity (two max). System font stacks are fine — most users won't notice, and you skip a network request.

- Body text ≥ 16px. Body line-height ~1.5. Heading line-height ~1.2.
- Line length 45–75 characters — use `max-width: 65ch` as a default. Wider than 80 and the eye loses the next line.
- Four type sizes covers almost any interface. Five is already a smell.

## 6. Colour is a system, not picks

Apply the accent hue and its 50–950 ramp from the locked identity; reuse the semantic roles it defines — success, warning, danger, info. Saturated colour only on small areas (badges, focus rings, charts), never large surfaces. In dark mode, drop saturation by ~20 points so colours don't vibrate.

## 7. WCAG AA is the floor

- 4.5:1 contrast for body text. 3:1 for large text (≥18px or ≥14px bold) and for UI components (borders, icons, focus rings).
- Verify with a tool, don't eyeball. Placeholder text and disabled states are the usual offenders.
- Colour is never the only signal — pair it with an icon, label, or pattern.

## 8. Three states per data fetch, not one

The happy path is ~70% of the work, not 100%. For anything that loads:

- **Loading.** Skeleton screen if you know the final shape; spinner only for unknown short waits. Skeletons reduce perceived wait and prevent layout shift.
- **Empty.** Never blank. Explain what could be here and give one action to populate it.
- **Error.** Say what went wrong in plain language and what to do next (retry button, link to support). Never leak stack traces.

## 9. Focus is visible

Every interactive element gets a real focus ring. If you set `outline: none`, you owe a replacement that meets 3:1 contrast against both the element and the background. Test with keyboard only — Tab through the whole page.

## 10. Touch targets ≥ 44×44px

Apple, Google, and WCAG 2.5.5 all agree. Includes invisible padding around small visual hits (icon buttons, links in dense text). On desktop you can go smaller, but never below 24×24 for anything clickable.

## 11. Motion has a job

Animate to communicate state change, not to decorate.

- Entry: 200–300ms, ease-out.
- Exit: 150–200ms, ease-out — faster than entry.
- Big distance = longer duration. Linear easing feels robotic — use a curve.
- Respect `prefers-reduced-motion`.

If you can't name what the animation tells the user, delete it. For real motion work — drawers, gestures, transitions, springs — see [motion-craft.md](motion-craft.md).

## 12. Borders, shadows, and depth

- One border colour, two shadow sizes. Not 5 of each.
- Cards lift a little; modals lift more; tooltips/popovers lift most. Treat elevation as a hierarchy tool, not a default style.
- Real shadows are multi-layer and offset slightly down (light comes from above). Default `0 1px 3px rgba(0,0,0,0.1)` is fine; pure black `box-shadow` is not.

## 13. Forms

- Labels above inputs, not inside (placeholders are not labels — they vanish on focus and fail accessibility).
- Inline validation on blur, not on every keystroke. Error message next to the field, in plain language ("Email needs an @" beats "Invalid input").
- Required fields marked clearly. One column for related fields. Submit button reflects the action ("Create account", not "Submit").

## 14. Modals are a last resort

Use a modal only for: destructive confirmation, blocking critical input, or a focused single-task flow. Never for promotion, walkthroughs the user didn't ask for, or content they might want to reference while browsing. No modal on top of a modal.

## 15. Test it in the browser

Type-checks and tests don't catch ugly. Before declaring UI work done:

- Open the page in a browser. Try the happy path and at least one edge case (empty state, error, narrow viewport).
- Tab through with the keyboard. Check focus rings.
- Toggle dark mode if it exists.
- If you can't run the UI, say so — don't claim success.

## Quick smell test

Skim the screen. Each tell is a deduction; three or more and it reads as generic — fix the worst first.

**Structure & hierarchy**

- Everything centred; equal-weight cards in a grid; four identical cards in a row (same icon position, number style, trend).
- Multiple equally prominent buttons — nothing is primary.
- Uniform spacing — everything 16px from everything.
- Squint and the hierarchy collapses, or borders and colours jump out harshly.

**Current-era AI tells** *(time-bound — these are the 2026 defaults; refresh as they shift)*

- **Colour:** AI-purple/violet glow; neon gradients; pure black on pure white; five+ greys with no system; the warm cream/beige body background (`#f5f1ea`, `#faf7f1`, "paper/sand/bone") reached for by default.
- **Type:** default Inter at default size with no scale; a display serif (`Fraunces`, `Instrument Serif`, `Playfair`) reached for because the brief "feels editorial."
- **Scaffolding:** a tiny uppercase tracked **eyebrow above every section**; numbered section markers (`01 / 02 / 03`); gradient text (`background-clip: text`); a coloured side-stripe border on cards or alerts; the big-number hero-metric template.
- **Copy:** em-dashes as a flourish; marketing buzzwords (streamline / empower / supercharge / seamless); the aphoristic "Not a X. A Y." cadence repeated across sections.
- **Decoration:** gradients on buttons "to make them pop"; emoji or icons that carry no meaning; infinite micro-animations on every card.

**Missing the unhappy paths**

- No empty state, no error state, no loading state.
- Tooltips holding essential information.

**Two swap tests**

- *Element swap:* replace the typeface or accent with the obvious alternative. If no one would notice, you defaulted.
- *Category-reflex (run twice):* could someone guess the palette and type from the **category alone** ("cookware → warm beige + brass", "AI tool → purple + Inter")? That's the first reflex — rework it. Then: could they guess it from **category-plus-the-obvious-anti-reference** ("AI tool that's *not* purple → editorial serif")? That's the trap one tier deeper. Rework until neither is obvious.

Three or more tells = generic. Fix the worst before anything else.
