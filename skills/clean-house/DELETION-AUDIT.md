# Auditing One Target

The brief for a single read-only auditor: one target in, one verdict block out. The target is a file, a directory, or a named section of a file. Audit nothing else. Fix nothing.

`/clean-house` fans these out in step 2 and in targeted mode; `/improve-readability` fans them out over spent-doc candidates. The launcher coalesces the blocks and runs the approval gate — an auditor never edits.

**Default to deletion. The burden of proof is on keeping.** Guards, error paths and tests are the exception: those keep prove-before-deleting ([CHECKS.md](../improve-readability/CHECKS.md), [TESTS.md](../improve-readability/TESTS.md)), because a wrong cut there fails silently. When the deciding fact is one only the owner can settle — does anyone actually read this? — the default still holds: say delete, and put the question that would reverse it in NOT ASSESSED.

## The three questions

1. Will this knowledge or capability be needed again?
2. Is it recoverable elsewhere — another file, a gate that enforces it, the code itself, git history?
3. What does keeping it cost? Tokens every future agent burns reading it, and the chance it misleads one into the wrong move.

Spent → say delete. Live → name what specifically is live, and how you proved it.

## Judging on evidence

**A file's account of itself is not evidence.** "This is the only writer of X", "never delete this", "load-bearing" — hypotheses to test, never findings. A prose claim that something was done fails here the same way it fails in [`/go-live`](../go-live/SKILL.md); go find the thing that would be true if the claim were.

**Citations are a cost, not a reason.** N inbound references is a list of edits, not a justification — a stale thing that is widely cited does more damage, not less. What settles it is the deletion test ([LANGUAGE.md](LANGUAGE.md)), and it runs the same way on prose as on code: imagine the target gone. If each citing file would have to *grow* to replace what it took, the target was earning its keep. If they would only need their links repaired, the citations were never an argument — say "delete it and fix the N citations", and give the count and the `file:line` list.

**Check every factual claim against live state.** A runbook that says a procedure is owed: has it already been done? A script that configures something: does the config already match? Use the CLI, the test suite, the actual files. A claim that is now false is the strongest delete signal there is — a doc that is confidently wrong is worse than no doc.

**Setter or checker?** A one-shot script whose result is now the live state is decorative unless something re-runs it: it cannot detect drift. Ask whether anything would notice if the state it set were changed by hand. A hardcoded count, version or path in prose is the same shape — true today with nothing re-deriving it is a finding, even though the claim checks out.

For something that *is* a checker, ask the mirror question: can a run that found nothing be told apart from a run that looked nowhere? A checker that fails silently is as decorative as the trigger nothing sweeps — AGENTS.md §7, silent is not done.

**Enforced or asserted?** Where a gate, test, or type already enforces a rule, prose restating it is a second copy that will go stale — prefer the enforcement. Where nothing enforces it, the prose may be the only thing between a reader and an expensive mistake: keep it and say so. Exempt: restatement written for reader locality on purpose, the way [`/to-spec`](../to-spec/SKILL.md) copies locked values into the SPEC because the implementing agent reads the SPEC and not the source artifact.

**Measure.** Section sizes, line counts, last change date, whether the procedure it describes has already completed. Numbers, not impressions.

**Age means opposite things by kind.** Code nobody has touched is parked, not found — spend nothing on it. A doc, script or process nobody has touched is a suspect: nothing has forced it to stay true. Measure the gap against what the target describes, not against the calendar — a three-month-old doc for a subsystem that shipped twice since is staler than a two-year-old one for code nobody changed.

## Verdicts

| Verdict | When |
|---|---|
| `DELETE` | Spent. Nothing live survives it |
| `CUT-DOWN` | A live core inside dead bulk. Say exactly what survives |
| `MERGE-INTO <path>` | One target is a subsection of another, or two gates ask the same question from different ends. Say which absorbs which |
| `RELOCATE-TO <path>` | Live, but not here. Knowledge belongs where it binds — a rule about a variable beside that variable, a procedure beside the thing it operates, a doc cited by exactly one script inside that script's message |
| `KEEP` | Live, right shape, right place |

A directory target gets one block per file plus a roll-up block for the directory itself. On the roll-up, `DELETE` means the whole tree goes, `KEEP` means all of it stays, `CUT-DOWN` means some files go and some stay — the per-file blocks say which. Shared evidence and tree-wide flags belong in the roll-up, cross-referenced from the files rather than repeated in each. Judge each file against the tree as it stands, not the tree your other verdicts would leave behind; where one file's fate changes another's citation count, say so in COST TO DELETE.

The verdict answers what happens to the target — nothing else. Naming a destination is part of a `MERGE-INTO` or `RELOCATE-TO` verdict, not a second decision. But prose that should be a gate, a defect in something you are voting `KEEP` on, a fix that would make the cut safer: those are **flags**, never moves you make. They get their own field, and a `KEEP` carrying flags is still a finding.

## Constraints

- **No smuggling.** "Delete X" and "build Y" are two decisions the reader takes separately. If deleting X would be safer with a new check, that goes in FLAGS carrying its own justification — never folded into the verdict as its price.
- **No blind verdicts.** Name what you did not check: sections you never opened, files you only skimmed, verification you could not run without writing something. Checking may change your answer; if it does, say so plainly rather than defending the first take.
- **No tombstone in what survives.** When something goes, its mentions go with it. No "this used to be handled by X", no "retired on `<date>` because". The replacement text states what is true now — a working command, or nothing. The *why* has designated homes and still belongs in them: `definitions/decisions.md` ([DECISIONS-FORMAT.md](DECISIONS-FORMAT.md)), the PRD's Out of Scope entry with its *cut because* + *re-add trigger*, the commit message.
- **A comment explains the hazard, never the obituary.** What a comment may carry is already settled by [CHECKS.md](../improve-readability/CHECKS.md)'s allowlist — interface contracts and implementation *why* both earn their place. This adds only the direction: point the reader at the mistake still ahead of them, not the one already made.
- **Scale honestly.** Don't inflate to reach a bigger line count; don't soften to seem careful.

## Output — this shape, nothing else

```text
TARGET: <path or path#section>
VERDICT: DELETE | CUT-DOWN | MERGE-INTO <path> | RELOCATE-TO <path> | KEEP
SIZE: <current> -> <proposed> lines. For MERGE-INTO and RELOCATE-TO give both —
      what leaves here, what lands there. Another unit only where lines are
      meaningless, and say which and why

EVIDENCE
- <fact you verified, and how — a command, a query, a file you read>
- <claim the target makes about itself that turned out false, if any>

WHAT IS GENUINELY LIVE (empty if nothing)
- <the irreplaceable part, and where it belongs>

COST TO DELETE
- <N citations, by file:line>
- <what breaks, and the gate that would catch it — say so when none would>

FLAGS — separate decisions, not part of the verdict (empty if none)
- <the second thing, and the justification it stands on by itself>

NOT ASSESSED
- <what you did not open or could not verify, or "nothing">
```

Do not summarize what you checked. The launcher can read this brief.
