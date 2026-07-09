# Rollout / migration: writing the SPEC's cutover plan

Instructions to the spec author for the SPEC's **Rollout / migration** section. This section owns *how the change reaches production without a one-way regret*. `/go-live` later verifies the evidence this section promises — every Verify clause you write here is a check that gate consumes.

## 1. Thin default vs. stepped runbook

Most changes need only the **thin default**: one paragraph naming the feature flag, the canary cohort, and the kill switch. Enough when the change is reversible by flipping a flag.

A **stepped runbook** is required whenever the change has a one-way door: a provider re-point, a datastore migration, a domain/DNS move, or first production traffic. Anything that holds data or serves inference and cannot be undone by a flag flip earns the full runbook.

## 2. Stepped-runbook discipline

- **Number the steps.** The runbook is an ordered list, not prose.
- **Every step gets a Verify clause and a Rollback clause.** Verify is an observable check — ideally a script the repo carries, because `/go-live` consumes exactly these scripts as its evidence (you produce it; the gate reads it). Rollback says how to undo *this* step.
- **Order for monotonic reversibility.** Sequence steps so every early step's worst case is "delete the new thing and carry on." Reversibility decays toward the cutover; it never recovers mid-runbook.
- **Mark the one-way doors.** Explicitly flag the step after which rollback stops being a clean re-point. Place one-way doors as late as the plan allows — everything reversible happens first.

Producer/consumer: this section *produces* the evidence (the Verify scripts); `/go-live` *verifies* it. A Verify clause with no backing script is a wish.

## 3. Thin-slice first

Cut the plan so the **smallest end-to-end slice** ships first — one real user, one real path — and the fleet/scale work is a **separate later phase**. Over-building the platform before the one-person slice works is the classic failure. Name the split in the SPEC: what's in the first slice, what's deferred, and the trigger that promotes the next phase.

## 4. Risk register

Each risk is three columns — no fewer:

| Risk | Counter-measure | Phase that closes it |
|---|---|---|

A risk with no closing phase is a hope, not a plan. If you can't name the phase, the plan isn't done.

## 5. Expand/contract schema contract (review rule)

State it as a rule the SPEC's test plan enforces:

- Destructive schema changes — drops, renames — land **only once no shipped release reads the old shape**. Add-and-backfill first; drop later, in a separate release.
- **The previous release must boot against the migrated store.** Name the enforcement gate in the test plan: a boot-the-previous-image proof. That gate is what `/go-live`'s release-mechanics row cites.

## 6. Environments

Every environment is a **config profile over one SHA-tagged artifact** — a demo is a profile, never a fork. Production **declares itself** (a profile flag, not a hostname guess) and **refuses dev/test affordances by construction**. Write this into the SPEC so the build can't drift into a forked prod.

## 7. External clocks

Name the uncompressible waits in the SPEC's schedule — they dominate real cutover timelines and no engineering shortens them:

- quota / limit-increase approvals
- certificate provisioning
- verification / review queues
- soak / bake windows

A schedule that omits these is fiction. Put each on the calendar against the actor you're waiting on.

## 8. Dev-to-prod path

One line citing the project's path record — the ADR in `docs/adr/` written by `pick-cloud-services` — and its armed `TRIGGER:` lines. The Verification-fidelity **Deploy** axis defaults to the rung that path implies (local / staging / prod-flagged); inherit it here, don't re-derive it.
