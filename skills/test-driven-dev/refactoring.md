# Refactor Candidates

Runs after GREEN, never while RED. Two rules frame every move:

- **Two hats** — a refactor commit contains no behavior change; a behavior commit contains
  no refactoring. Swap hats as often as you like, never wear both in one commit.
- **Preparatory refactoring** — when the next slice resists the current structure, first
  make the change easy (its own green-to-green commit), then make the easy change.

After each cycle, look for:

| Smell | Looks like | Move |
|---|---|---|
| Duplication | Third occurrence of the same logic (tolerate two) | Extract function/class |
| Mysterious name | Name doesn't say what it does, or promises the wrong thing | Rename — a lying name is a bug |
| Long function | Narrates as a list of tasks | Extract whole sub-tasks with honest names — see guard-rails |
| Long parameter list | Params travel as a pack; boolean flag args | Parameter object; split the flagged function |
| Shallow module | Interface as complex as the implementation | Combine or deepen — see [deep-modules.md](deep-modules.md) |
| Feature envy | Logic camped on another module's data | Move it to where the data lives |
| Primitive obsession | Domain concept as a bare string/number | Introduce the value type |
| Data clumps | Same field trio recurring | Extract the concept |
| Repeated switches | Same discriminator switched twice+ | Polymorphism or one dispatch table |
| Speculative generality | Hooks for futures that never came | Inline / delete |
| Scattered siblings | Small helpers that only make sense read together | One pile: inline them back, read it whole, then re-split honestly — or leave it whole |
| Excess machinery | An error path for a state that can't occur; a wrapper that only forwards; a flag arg picking between two behaviors | Delete the path; inline the wrapper; split the flagged function |
| Comment as deodorant | Comment apologizing for the block below | Fix the block; keep only what code can't say |
| Comment git already holds | `// was: oldName()`, a date-stamped change note, commented-out code | Delete — history lives in the commit, and the comment goes stale the moment it's wrong |
| Existing code | The new code reveals a problem in old code | Fix here if small; else flag for `/improve-readability` or `/clean-house` |

Guard-rails — refactoring must not fragment:

- Extract only what earns an honest name and reads alone (if understanding the extracted
  piece still requires its caller open beside it, recombine).
- Duplication is cheaper than the wrong abstraction — rule of three.
- No splitting on raw line count; a deep function beats a swarm of three-line helpers.
