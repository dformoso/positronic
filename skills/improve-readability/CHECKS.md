# Checks

The audit tables for `/improve-readability`. Sweep hotspots, not the whole tree; mechanical
proxies flag candidates, judgment confirms; priority comes from reader traffic, never from
finding count. Distilled from Ousterhout (*A Philosophy of Software Design*), Hermans
(*The Programmer's Brain*), Fowler (*Refactoring*, 2nd ed), Boswell & Foucher (*The Art of
Readable Code*), and Seemann (*Code That Fits in Your Head*) — restated in this repo's
vocabulary; the books own the full arguments.

## Lens 1 — Obscurity (mostly Ousterhout)

Symptom: the reader can't learn what's true from the code in front of them.

| Check | Looks like | Move |
|---|---|---|
| Vague name | `data`, `result`, `info`, `process`, `handle` — could name many things | Rename to what it holds or does |
| Hard to name | You (or the author, visibly) couldn't find a crisp name | The unit blends responsibilities — split along the concepts, or hand to `/clean-house` if it's a module |
| Comment restates code | Reader learns nothing the next line doesn't say | Delete it; if something *was* worth saying (why, invariant, unit), say that instead |
| Interface comment leaks internals | Public doc explains *how* instead of *what a caller must know* | Rewrite as contract: inputs, outputs, invariants, error modes — no implementation |
| Hard to describe | An honest doc comment comes out long and hedged | The design is the problem — flag it; don't wordsmith the comment |
| Nonobvious code | You must mentally execute it to know what it does | Rewrite for the reader; if the cleverness is load-bearing, add the why-comment at a higher level than the code |
| Information leakage (code level) | Same format, constant, or assumption encoded in ≥2 places — change one, hunt the others | Give the decision one owner (constant, function, type); module-level leakage → `/clean-house` |
| Special case in a general mechanism | `if (caller === X)` inside shared code; use-case names in a generic module | Pull the special case up to its caller |
| Conjoined functions | Can't understand A without B open in the other pane | Recombine, or redraw the split so each piece stands alone |
| Error handled everywhere | Same exception caught at every call site | Ladder: define the error out of existence (semantics where the case is a non-event — delete-absent is a no-op) → mask it low → aggregate it high → crash if unrecoverable |

## Lens 2 — Cognitive load (mostly Hermans, gates from Seemann)

Symptom: everything is knowable, but the reader's working memory overflows anyway.

| Check | Looks like | Move |
|---|---|---|
| Working-memory overload | Many live variables, deep nesting, long condition chains; you needed a variable table in step 2 | Guard clauses, explaining/summary variables, split loop, straighten phases |
| Complexity past the tripwire | Cyclomatic complexity > ~7 on a hot function | A *tripwire, not a law*: crossing it forces a look, not a mechanical split — never "fix" it by scattering sibling helpers |
| Name that lies | `is*` that isn't boolean, `get*` that mutates or costs, name promising more/less/opposite of the behavior | Rename to the truth — worse than a vague name, because the reader trusts it |
| Synonym drift | `fetch`/`get`/`load` (or two domain words) for one concept | One concept, one word, repo-wide — CONTEXT.md decides |
| Mold inconsistency | `fooCount` here, `countFoo` there; mixed case styles | Pick one mold per pattern, document in CONTEXT.md, converge as files are touched |
| Beacon-poor region | No summary line or telling name at a module entry; reading starts token-by-token | One high-level summary comment per entry point; capture hard-won understanding as a name or summary *while you have it* |
| Hidden dependencies | Globals, action at a distance, mutation behind an innocent call, temporal coupling ("must call init first" — unwritten) | Make them visible: parameters over globals, or a stated invariant at the interface |
| Query that mutates | A read that writes | Separate query from modifier |

## Lens 3 — Change-resistance (Fowler smells, curated)

Symptom: the code is readable line-by-line but fights every modification. Full catalog at
refactoring.com; these earn a row because they show up in comprehension passes.

| Smell | Looks like | Move |
|---|---|---|
| Duplicated code | Near-identical logic in ≥3 places (tolerate two — rule of three) | Extract function; slide statements together first |
| Long function | Does several things; you narrate it as a list | Extract *whole sub-tasks with honest names* — see guard-rails before splitting |
| Long parameter list | Params travel as a pack, flag args | Introduce parameter object; remove flag argument (split the function) |
| Divergent change | One file edited for many unrelated reasons | Split by reason for change |
| Shotgun surgery | One decision edited across many files | Move the pieces to one owner |
| Feature envy | Function mostly reads another module's data | Move it to where the data lives |
| Data clumps | Same field trio recurring | Extract the concept they form |
| Primitive obsession | Domain concepts passed as bare strings/numbers | Introduce the value type |
| Repeated switches | Same discriminator switched in many places | Replace conditional with polymorphism (or one dispatch table) |
| Message chains | `a.b().c().d()` — the reader learns the whole topology | Hide the delegate, or move the function to the end of the chain |
| Speculative generality | Hooks, params, layers for futures that never came | Inline, collapse, delete — route deletions to `/clean-house` |
| Temporary field | Field meaningful only sometimes | Extract the variant, or introduce a special case object |
| Comment as deodorant | A comment apologizing for the block below | Fix the block (rename, extract, simplify); keep only what code can't say |

Mechanical proxies (flag, never auto-fix): a duplication tool if present (`jscpd`, PMD-CPD);
dead-export tools (`knip`, `ts-prune`, `vulture`); complexity (`lizard`, `radon`, eslint
`max-params`/`complexity`); grep for chains `(\.\w+\(\)){3,}`, repeated `switch` on one
type, exported mutable state.

## Lens 4 — Line level (Boswell & Foucher)

Symptom: each line costs slightly more than it should; the tax compounds.

| Check | Rule |
|---|---|
| Names carry payload | Units in names (`delaySecs`, `sizeMb`); danger in names (`unsanitizedInput`, `plaintextSecret`); specific verbs (`fetchPage`, not `getPage`, if it hits the network) |
| Unambiguous conventions | `min/max` = limits; `first/last` = inclusive; `begin/end` = half-open; booleans `is/has/can`, never negated (`useSsl`, not `disableSsl`) |
| Name length ∝ scope | Single letters only in tightest scopes; public names spell it out |
| Control flow reads forward | Guard clauses over nesting; the interesting/positive case first; no clever ternaries or short-circuit tricks doing real work |
| Expressions fit in one breath | Explaining variable for any subexpression you had to parse twice; rewrite negated compounds as positives |
| Variable hygiene | Declare at first use, shrink scope, prefer write-once; delete no-value intermediates |
| Comments earn space | High info-to-space; why-comments on constants; pitfalls advertised; input/output example where a signature is opaque; TODO/FIXME/HACK triaged, not accreted |
| Similar looks similar | Parallel code laid out in parallel; one argument/field ordering everywhere |

## Guard-rails — the pass must not create fragmentation

The informed critique of the extract-till-tiny school (see the public Ousterhout–Martin
dialogue): radical splitting scatters information, multiplies shallow interfaces, and
produces sibling functions none of which is understandable alone.

- **Extraction license**: extract only when the piece gets an honest name and can be
  understood *without* reading its siblings. A single-caller helper with a tortured name is
  the smell, not the fix.
- **Entanglement test**: if understanding A still requires B open beside it, the split
  failed — recombine.
- Duplication is cheaper than the wrong abstraction — wait for the third occurrence.
- Never gate on raw line count; length is fine when the function is one coherent task
  (deep functions with paragraph comments beat swarms of three-line helpers).
- Predicate-shaped names hiding mutation, and instance fields used as hidden parameters
  between extracted siblings, are bugs introduced *by* over-extraction — check for them
  after any split.
- Thresholds (complexity, params, length) are tripwires that force attention; overriding
  one consciously is fine, drifting past it silently is not.

## Comment policy (one table, used by every lens)

| Kind | Carries | Never |
|---|---|---|
| Interface comment (public surface) | The contract: what it does, inputs/outputs, invariants, units, error modes — at a higher abstraction than the code | Implementation detail |
| Implementation comment | Why, and the non-obvious what: tradeoffs, rejected alternatives, invariants mid-flow | A restatement of the next line |

Order of preference for placing knowledge: type → name → structure → comment → commit
message → doc. Push each fact as high up that ladder as it can live; what's left over is
what comments are for — that residue is legitimate and required, not a failure.
