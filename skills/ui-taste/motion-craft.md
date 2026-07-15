# Motion craft

Reach for this when [ui-taste](SKILL.md) rule 11 ("Motion has a job") isn't enough — real animation, drawers, gestures, transitions. Same footing as the rest of ui-taste: safe defaults, not laws. Break them with a reason, and say the reason.

## 1. Should this animate at all?

The first decision, and usually the answer is no.

| How often the user sees it | Decision |
|---|---|
| 100+×/day (shortcuts, command palette) | No animation. Ever. |
| Tens×/day (hover, list nav) | Remove or drastically reduce |
| Occasional (modal, drawer, toast) | Standard animation |
| Rare / first-time (onboarding, success) | Can add delight |

Never animate keyboard-initiated actions — they repeat hundreds of times a day and animation makes them feel slow. Raycast has no open/close animation; that's correct. If you can't name what the animation tells the user, delete it.

## 2. Easing

- Entering or exiting → **ease-out** (fast start = instant feedback).
- Moving / morphing on screen → **ease-in-out**. Hover or colour change → **ease**. Constant motion (marquee, progress) → **linear**.
- **Never `ease-in` for UI.** It delays the first moment — the moment the user is watching. A 300ms `ease-in` dropdown feels slower than 300ms `ease-out`.
- Built-in curves are too weak. Use custom ones:

```css
--ease-out: cubic-bezier(0.23, 1, 0.32, 1);      /* UI in / out */
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);  /* on-screen movement */
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);   /* iOS-like drawer */
```

- Never `transition: all`. Name the property: `transition: transform 200ms ease-out`.

## 3. Duration

| Element | Duration |
|---|---|
| Button press feedback | 100–160ms |
| Tooltip, small popover | 125–200ms |
| Dropdown, select | 150–250ms |
| Modal, drawer | 200–500ms |
| Marketing / explanatory | longer is fine |

UI animation stays **under 300ms**, and exit is faster than enter. A faster spinner makes the app feel faster even when load time is identical — perceived speed is real.

## 4. Patterns that compound

Individually invisible; in aggregate they're why an interface feels right.

- **Press feedback.** `transform: scale(0.97)` on `:active`, ~160ms ease-out. Any pressable element.
- **Never animate from `scale(0)`.** Nothing in the real world appears from nothing. Start at `scale(0.95)` + `opacity: 0`.
- **Origin-aware popovers.** Scale from the trigger, not centre: `transform-origin: var(--radix-popover-content-transform-origin)`. Modals are the exception — they stay centred.
- **Tooltips skip the delay after the first.** Once one is open, adjacent ones open instantly, no delay, no animation.
- **Enter with `@starting-style`** rather than a JS `mounted` flag, where browser support allows.

## 5. Transitions vs keyframes

For anything triggered rapidly (toasts, toggles, interruptible state), use **CSS transitions** — they retarget mid-flight. Keyframes restart from zero and look broken under rapid triggering. Keep keyframes for predetermined, non-interruptible motion.

## 6. Springs

Springs settle by physics — no fixed duration. Use for drag / momentum, interruptible gestures, and elements that should feel alive. Avoid for precise, functional UI.

```js
{ type: "spring", duration: 0.5, bounce: 0.2 }   // Apple style, easy to reason about
```

Keep bounce 0.1–0.3, usually none. Springs keep velocity when interrupted (keyframes don't), so they're right for gestures the user can reverse mid-motion.

## 7. Performance

- **Animate only `transform` and `opacity`.** They skip layout and paint and run on the GPU. Width/height/padding/margin trigger all three.
- **CSS beats JS under load.** CSS animation runs off the main thread; rAF-based libraries drop frames while the page is loading. CSS for predetermined motion, JS for dynamic/interruptible.
- **Framer Motion `x` / `y` / `scale` shorthands are not hardware-accelerated.** Under load, use the full `transform` string.

## 8. Accessibility

- **`prefers-reduced-motion` = fewer and gentler, not zero.** Keep opacity/colour transitions that aid comprehension; drop movement and position changes.
- **Gate hover animation** behind `@media (hover: hover) and (pointer: fine)` — touch devices fire hover on tap.

## 9. Gestures (drawers, swipe-to-dismiss)

- Dismiss on **velocity**, not just distance — a quick flick should be enough (`|distance| / elapsed > ~0.11`).
- **Damp past boundaries** — the more they over-drag, the less it moves. Real things slow before they stop.
- **Capture the pointer** during a drag; **ignore extra touches** after the first.

## 10. Going further

clip-path reveals (tabs, hold-to-delete, comparison sliders), 3D transforms for depth, WAAPI for programmatic motion at CSS performance, `translateY(100%)` for size-independent offsets. Reach for these when the interaction needs them; the rules above still hold.

## Review format

When reviewing motion, output a **Before / After / Why** table — one row per issue, never a prose list:

| Before | After | Why |
|---|---|---|
| `transition: all 300ms` | `transition: transform 200ms ease-out` | Name properties; `all` animates layout too |
| `transform: scale(0)` | `scale(0.95); opacity: 0` | Nothing appears from nothing |
| `ease-in` on dropdown | `ease-out` + custom curve | `ease-in` delays the watched moment |
| no `:active` state | `scale(0.97)` on `:active` | Press must feel heard |
| animation on a keyboard action | none | Repeated 100s×/day; animation reads as lag |

## Debugging

- Play at 2–5× slow motion (DevTools → Animations) — timing bugs invisible at full speed show up.
- Review the next day with fresh eyes.
