# Checks

The audit tables for `improve-readability`. Sweep hotspots, not the whole tree; mechanical
proxies flag candidates, judgment confirms; priority comes from reader traffic and machinery
removed, never from finding count. Distilled from Ousterhout (*A Philosophy of Software
Design*), Hermans (*The Programmer's Brain*), Fowler (*Refactoring*, 2nd ed), Beck (*Tidy
First?*), Boswell & Foucher (*The Art of Readable Code*), Seemann (*Code That Fits in Your
Head*), Hickey (*Simple Made Easy*), King (*Parse, Don't Validate*), and Feathers (*Working
Effectively with Legacy Code*) — restated in this repo's vocabulary; the books own the full
arguments.

## Lens 1 — Obscurity (mostly Ousterhout)

Symptom: the reader can't learn what's true from the code in front of them.

| Check | Looks like | Move |
|---|---|---|
| Vague name | `data`, `result`, `info`, `process`, `handle` — could name many things | Rename to what it holds or does |
| Hard to name | You (or the author, visibly) couldn't find a crisp name | The unit blends responsibilities — split along the concepts, or hand to `clean-house` if it's a module |
| Comment restates code | Reader learns nothing the next line doesn't say | Delete it; if something *was* worth saying (why, invariant, unit), say that instead |
| Interface comment leaks internals | Public doc explains *how* instead of *what a caller must know* | Rewrite as contract: inputs, outputs, invariants, error modes — no implementation |
| Hard to describe | An honest doc comment comes out long and hedged | The design is the problem — flag it; don't wordsmith the comment |
| Nonobvious code | You must mentally execute it to know what it does | Rewrite for the reader; if the cleverness is load-bearing, add the why-comment at a higher level than the code |
| Information leakage (code level) | Same format, constant, or assumption encoded in ≥2 places — change one, hunt the others | Give the decision one owner (constant, function, type); module-level leakage → `clean-house` |
| Special case in a general mechanism | `if (caller === X)` inside shared code; use-case names in a generic module | Pull the special case up to its caller |
| Conjoined functions | Can't understand A without B open in the other pane | Recombine, or redraw the split so each piece stands alone |
| Error handled everywhere | Same exception caught at every call site | Ladder: define the error out of existence (semantics where the case is a non-event — delete-absent is a no-op) → mask it low → aggregate it high → crash if unrecoverable |

## Lens 2 — Cognitive load (mostly Hermans, gates from Seemann)

Symptom: everything is knowable, but the reader's working memory overflows anyway.

| Check | Looks like | Move |
|---|---|---|
| Working-memory overload | Many live variables, deep nesting, long condition chains; you needed a variable table in step 2 | Guard clauses, explaining/summary variables, split loop, straighten phases |
| Complexity past the tripwire | Cyclomatic complexity > ~7 on a hot function — and prefer **cognitive** complexity where a tool offers it, since cyclomatic doesn't penalise nesting and nesting is what actually costs the reader | A *tripwire, not a law*: crossing it forces a look, not a mechanical split — never "fix" it by scattering sibling helpers |
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
| Scattered siblings | Three-line helpers that only make sense read together | **One pile** (Beck): inline them back into one unit, read it whole, then re-split honestly — or leave it whole |
| Speculative generality | Hooks, params, layers for futures that never came | Inline, collapse, delete — route module-level deletions to `clean-house` |
| Temporary field | Field meaningful only sometimes | Extract the variant, or introduce a special case object |
| Comment as deodorant | A comment apologizing for the block below | Fix the block (rename, extract, simplify); keep only what code can't say |

## Lens 4 — Excess machinery

Symptom: the code is clear and well-shaped, and there is simply more of it than the job
needs. Each row is code the reader must understand *and* something that can go wrong, so
removing it pays twice. This is the lens that cuts.

| Check | Looks like | Move |
|---|---|---|
| Impossible-state handling | A guard, `catch`, or branch for a state the types or the call sites make unreachable | Delete it. If it turns out to be reachable, the type is lying — fix the type, don't keep the guard |
| Validation at every layer | The same input checked at the edge, again in the service, again at the store | Parse once at the edge and carry the proof in the type; inner layers accept only the parsed value |
| Nullable that's never null | An `Optional` / `\| null` return whose callers all assert, default, or ignore it | Make the function total; if absence is real, push it into the one caller that means it |
| Setting with one value | A config knob, env var, or parameter with one observed value across the repo and its history | Inline the value. Note it in the report — a pattern of these is a config-surface finding for `clean-house` |
| Flag parameter | A boolean argument selecting between two behaviors | Split into two named functions; every caller already knows which one it wants |
| Retry around a retry | Backoff at the client *and* the caller *and* the queue | One owner for the policy; everything else propagates |
| Catch-log-rethrow | An exception caught only to log it and raise it again | Delete the handler; log once, where the decision to give up is made |
| Just-in-case fallback | A default that hides a failure instead of handling it (`except: return []`) | Fail loudly, or handle it where the caller can actually act |
| Forwarding wrapper | A function or class whose body is one call with the same arguments | Inline it (deletion test). If the layer is a whole module, route to `clean-house` |
| Two paths, one job | A flag, branch, or duplicate path where one side is dead or both now do the same thing | Delete the dead side; collapse the live one |
| Braided concerns | One unit that decides *and* performs; state mixed with time; domain mixed with transport | Separate the decision from the effect — the decision half then tests without mocks |
| Speculative extension point | Hooks, callbacks, generics, or params nothing supplies | Inline, collapse, delete |

Guard-rails for this lens specifically:

- **Removing machinery must never remove capability.** If you cannot say which caller stops
  being served, you are removing machinery. If you can, stop — that's `clean-house`.
- **Prove unreachability before deleting a guard.** Grep the call sites, check the type, or
  leave the guard and log the finding. "It looks impossible" is not proof.
- A deleted error path must be *impossible*, not merely *unlikely*. Unlikely-but-possible is
  a reliability question for `/audit-failure-modes`, not a reduction.

## Lens 5 — Line level (Boswell & Foucher)

Symptom: each line costs slightly more than it should; the tax compounds.

| Check | Rule |
|---|---|
| Names carry payload | Units in names (`delaySecs`, `sizeMb`); danger in names (`unsanitizedInput`, `plaintextSecret`); specific verbs (`fetchPage`, not `getPage`, if it hits the network) |
| Unambiguous conventions | `min/max` = limits; `first/last` = inclusive; `begin/end` = half-open; booleans `is/has/can`, never negated (`useSsl`, not `disableSsl`) |
| Name length ∝ scope | Single letters only in tightest scopes; public names spell it out |
| Control flow reads forward | Guard clauses over nesting; the interesting/positive case first; no clever ternaries or short-circuit tricks doing real work |
| Expressions fit in one breath | Explaining variable for any subexpression you had to parse twice; rewrite negated compounds as positives |
| Variable hygiene | Declare at first use, shrink scope, prefer write-once; delete no-value intermediates |
| Comments earn space | High info-to-space; why-comments on constants; pitfalls advertised; input/output example where a signature is opaque — see the comment policy below |
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

## Comment policy (one table set, used by every lens)

What a comment is allowed to be:

| Kind | Carries | Never |
|---|---|---|
| Interface comment (public surface) | The contract: what it does, inputs/outputs, invariants, units, error modes — at a higher abstraction than the code | Implementation detail |
| Implementation comment | Why, and the non-obvious what: tradeoffs, rejected alternatives, invariants mid-flow | A restatement of the next line |

Delete on sight — these carry nothing a reader can use:

| Kind | Looks like | Why it goes |
|---|---|---|
| History comment | `// changed 2024-03 to fix the timeout`, `// was: oldName()`, a changelog block at the file head, an author/date banner | Git already holds this, more accurately, and the comment goes stale the moment it's wrong |
| Commented-out code | Any disabled block kept "in case" | Git holds it. Live code shouldn't carry a graveyard the reader has to step over |
| Boilerplate docstring | `"""Returns the user."""` above `get_user()`; `@param id The id` | Says nothing the signature doesn't. Either state the contract or delete the block |
| Decorative banner | `# ---- helpers ----`, ASCII rules, section art | Structure should come from the structure. If a file needs internal signposts, it's doing too much |
| Stale directive | `TODO` / `FIXME` / `HACK` older than a year; `@deprecated` on something nothing plans to remove | Triage each: do it now, file it as an issue, or delete it. Accreted directives train readers to ignore all of them |
| Redundant type comment | `# str: the name` beside an already-typed parameter | The type says it |

Order of preference for placing knowledge: type → name → structure → comment → commit
message → doc. Push each fact as high up that ladder as it can live; what's left over is
what comments are for — that residue is legitimate and required, not a failure. **History
lives at the commit-message rung**, which is why a comment recording *when* or *by whom*
something changed is a ladder violation by construction.

## Mechanical proxies

Flag, never auto-fix. Use what's already installed; never add a dependency for this pass.

| Signal | Tools |
|---|---|
| Test strength (does a break get caught?) | `mutmut`, `cosmic-ray` (Python); `Stryker` (JS/TS); `PIT` (JVM); `cargo-mutants` (Rust); `go-mutesting` (Go) — scope to hotspots; hand fault-injection if none installed |
| Duplication | `jscpd`, PMD-CPD |
| Dead exports | `knip`, `ts-prune`, `vulture` |
| Complexity | `lizard`, `radon`, eslint `complexity` / `max-params`; `sonarjs/cognitive-complexity` where available |
| Commented-out code | `eradicate` / `flake8-eradicate`; else `grep` for long runs of commented lines |
| History comments | `grep -rnE '^\s*(//|#|\*)\s*(was:|previously|changed |updated |modified |[0-9]{4}-[0-9]{2})'` |
| Machinery | `grep` for chains `(\.\w+\(\)){3,}`, repeated `switch` on one type, exported mutable state, `except.*:\s*(pass\|return \[\]\|return None)` |
