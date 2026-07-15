# Deep Modules

**Deep module** = small interface, lots of behavior behind it

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
│                     │
└─────────────────────┘
```

**Shallow module** = interface nearly as complex as the implementation (avoid)

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing interfaces, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

Design rules that produce depth:

- **Somewhat general-purpose**: the interface serves the plausible class of uses
  (`delete(range)`), the implementation serves only today's. Use-case names in a general
  module are the tell of the reverse.
- **Pull complexity downward**: better the module author sweats than every caller —
  sensible defaults over required config, absorb the hard case inside.
- **Define errors out of existence**: error modes are interface surface. Prefer semantics
  where the special case is a non-event; then mask low; then aggregate high; crash only
  for the unrecoverable.

Red-flag tells while implementing: a method that forwards to a same-signature method
(pass-through — delete the layer or give it its own abstraction); a required parameter most
callers fill with the same value (overexposure — default it). And the counterweight: depth
is not tininess — never split a coherent function into sibling fragments that only make
sense together.
