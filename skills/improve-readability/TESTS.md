# Reworking an Existing Suite

The test half of `improve-readability`. [test-driven-dev](../test-driven-dev/SKILL.md)
covers writing a test for behavior you are about to build; this covers judging a suite that
already exists, deleting what protects nothing, and strengthening what's left.

Two reasons to run it, and the pass uses both:

- **As the licence.** The scope contract only lets this pass cut code where the tests would
  catch a break. Where they wouldn't, the test work *is* the slice — it lands green-to-green
  before any code moves.
- **As a deliverable.** A suite full of tests that pass no matter what the code does is
  worse than no suite: it's a false green that hides the next regression.

## The rubric — four things a test buys you

Judge every test against these. The framing is Khorikov's (*Unit Testing Principles*).

| Property | The question | Failure looks like |
|---|---|---|
| Catches regressions | If the behavior broke, does this go red? | Green when the feature is broken |
| Survives refactoring | If only the shape changed, does it stay green? | Red every time you rename something internal |
| Fast feedback | Does it answer within the edit loop? | A suite people run once a day, or not at all |
| Cheap to keep | Can a reader tell what it asserts, and does it stay working? | Setup nobody understands; a test rewritten every sprint |

**You can max three of the four, and *survives refactoring* is not the one to trade.** A
test that goes red on every internal change teaches the team to change the test instead of
reading it, so it stops catching regressions in practice regardless of what it asserts. That
is why this repo's position — test through public interfaces, don't mock what you own — is
not a style preference. It's the property that keeps the other three alive.

## Measuring, not guessing

Coverage tells you the line ran. It does not tell you the test noticed.

Break the code and see if the suite complains — mutation tooling if any is installed, hand
fault-injection otherwise (see step 0 of [SKILL.md](SKILL.md)). Every surviving fault is a
finding that carries its own proof: *this line can be changed to something wrong and nothing
in the suite objects.* That is stronger evidence than any percentage, and it names the exact
assertion to add.

## Smells

| Smell | Looks like | Move |
|---|---|---|
| Tests the mechanism | Asserts a mock was called, checks call counts or order, reaches a private method | Rewrite through the public interface. If that's impossible, the module is the wrong shape → `clean-house` |
| Can't fail | No assertion; asserts something the code can't violate; asserts only that nothing threw | Assert the observable outcome, or delete the test |
| Planted state | Setup writes state directly when production reaches it through a factory, endpoint, or upload | Build state the way production builds it (see [tests.md](../test-driven-dev/tests.md)) |
| Mystery guest | Depends on a fixture file, shared row, clock, or env var the test never shows | Make the input visible in the test |
| Eager test | One test exercising five behaviors; the name is a list | Split by behavior — one name, one claim |
| Branching test | `if` or loops deciding what to assert | Split into cases. A test with branches has untested branches |
| Assertion roulette | A dozen unlabeled assertions; a failure doesn't say which fact broke | One logical assertion per test, or label them |
| Over-mocked | Mocks standing in for code you own | Mock at system boundaries only ([mocking.md](../test-driven-dev/mocking.md)) |
| Duplicated setup | The same twenty lines at the head of every test | One builder shared by all — but never one that skips what production does |
| Snapshot blob | A large approved output nobody reads; every change re-approves it wholesale | Assert the few fields that carry meaning |
| Slow or flaky | Wall clock, or intermittently red | Fix it or quarantine it. A suite people ignore protects nothing |
| Orphan | Pins behavior that no longer exists, or re-pins something just removed | Delete it with the behavior it described |

## The workflow

Run it over the tests covering the hotspots, never the whole suite at once.

1. **Measure.** Fault injection over the hotspots. Record which faults survived.
2. **Delete.** Orphans, can't-fail tests, mock-assertion tests, and unit tests made redundant
   by an interface-level test covering the same behavior. *Replace, don't layer* — see
   [DEEPENING.md](../clean-house/DEEPENING.md).
3. **Raise.** A test reaching past the interface moves up to the interface. Same behavior
   asserted, fewer internals named. This is usually the move that makes step 2 safe.
4. **Strengthen.** For each surviving fault, add the assertion that would have caught it. For
   external dependencies, pin the message against text actually observed in production, not
   invented text.
5. **Re-measure.** The same faults are now caught. If they aren't, the rework didn't land.

## Guard-rails

- **Never delete a test without proving the behavior is still covered.** Break the code,
  confirm something else goes red, then delete. "Another test probably covers it" is not
  proof.
- **Never weaken an assertion to get green.** If a test is red, either the code is wrong or
  the assertion was wrong — decide which, out loud. Loosening the assertion to move on is
  how a suite dies.
- **Tests move with behavior.** Deleting a code path deletes its tests and fixtures in the
  same commit. An orphaned green test re-pins what was just removed.
- **Strengthening is not adding.** Chasing 100% coverage of untouched, low-traffic code is
  outside this pass. Strengthen what covers the hotspots; park the rest in the report.
- Test work lands in its own commit, before the code moves it licenses.
