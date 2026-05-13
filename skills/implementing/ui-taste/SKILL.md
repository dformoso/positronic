---
name: ui-taste
description: Opinionated taste rules for visual interface work — avoids the generic "AI-generated UI" look. Use when the user is building or styling frontend components, dashboards, marketing pages, design tokens, or anything users will see. Triggers on React/Vue/Svelte/HTML/CSS work, Tailwind, design system additions, or when the user says "make this look better", "style this", "design this screen", or shows a screenshot of something to improve.
---

# UI taste

Opinionated visual rules. Apply them when you write or change UI. If three or more are wrong on a screen, it looks AI-generated — fix those first.

These rules are safe defaults, not laws. Break them when you have a reason; surface the reason.

## 1. One primary thing per surface

Every screen has one job. Establish the primary element with size, weight, and contrast — not just colour. Demote everything else. If two buttons look equal, neither is primary.

- One filled primary button per view. Secondary actions are outlined or text-only.
- Destructive actions get their own treatment and sit away from the primary.
- Three levels of hierarchy max (primary / secondary / tertiary). More than three and the eye stops sorting.

## 2. Design in greyscale first

Strip colour before you start. Force the layout to work on hierarchy alone — size, weight, spacing, contrast. Add colour last, sparingly, and only where it carries meaning (brand accent, semantic state, data category). Colour is not decoration.

## 3. Spacing is hierarchy

Related things sit closer. Unrelated things sit farther. Inner padding ≤ outer margin. Use a fixed scale — `4, 8, 12, 16, 24, 32, 48, 64` — and never invent arbitrary values. Pick a base (8 for consumer, 4 for dense tools like Linear/Raycast) and commit.

Uniform spacing is the #1 tell of generic UI. Vary it deliberately.

## 4. No pure black, no pure white

`#000` on `#fff` is harsh and flat. Body text wants near-black (e.g. `#111`–`#1f2937`). Background neutrals want a slight tint — warm or cool, pick one. Dark mode surfaces start at `#121212`, never `#000`; raise lightness with elevation, don't add shadows.

## 5. Two fonts max, four sizes max

One font for body, optionally one for display. System font stacks are fine — most users won't notice, and you skip a network request.

- Body text ≥ 16px. Body line-height ~1.5. Heading line-height ~1.2.
- Line length 45–75 characters. Wider than 80 and the eye loses the next line.
- Four type sizes covers almost any interface. Five is already a smell.

## 6. Colour is a system, not picks

One accent hue, expressed at multiple lightness steps (50–950 ramp). Semantic roles defined once — success, warning, danger, info — and reused. Saturated colour only on small areas (badges, focus rings, charts), never large surfaces. In dark mode, drop saturation by ~20 points so colours don't vibrate.

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
- Exit: 150–200ms, ease-in.
- Big distance = longer duration. Linear easing feels robotic — use a curve.
- Respect `prefers-reduced-motion`.

If you can't name what the animation tells the user, delete it.

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

Skim the screen and look for these tells. Each one is a deduction:

- Everything centred, lots of equal-weight cards in a grid.
- Multiple equally prominent buttons.
- Uniform spacing — everything 16px from everything.
- Pure black text on pure white background.
- Default sans-serif at default size, no scale.
- Five+ shades of grey with no system.
- Gradients on buttons "to make them pop".
- No empty state, no error state, no loading state.
- Decorative emoji or icons that don't carry meaning.
- Tooltips containing essential information.

Three or more = generic. Fix the worst before anything else.
