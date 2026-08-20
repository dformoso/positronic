# The pipeline: gates, deploys, and applies

Reference for the author answering `/to-infrastructure`'s greenfield steps 3–5 — the gate ladder, the build-and-deploy pipeline, and infrastructure as code. The skill walks the decisions; this file carries the shape to choose between and the trap that makes the obvious version wrong. Continuous integration (CI) here means the checks a provider runs automatically on a change; continuous delivery (CD) means the path that turns a merged commit into running code.

Two verbs run through all of it, and keeping them apart is most of the design:

- **Deploy** ships **code** — a new artifact built from a commit.
- **Apply** ships **configuration** — environment variables, scaling, identities, networking, storage, secrets wiring.

Different tools, different identities, different approvals. Where the two blur, the failures below start.

## 1. The gate ladder

Every automated check the project owns, ordered by what running it costs. One folder holds the entry points; one word runs each.

| Level | When it runs | What it proves | Cost | Blocks a merge? |
|---|---|---|---|---|
| 0 — while coding | every few minutes, on the affected tests only | the edit didn't break what it touched | free · seconds | no |
| 1 — the merge gate | on every change | all deterministic code is correct in isolation — no network, no money, no clock | free · a minute or two | **yes — this is the required check** |
| 2 — assembled system | when the diff touches what it covers | the real processes boot together and survive a restart · the shipped image builds and carries no baked secret · a real browser drives the real product · a real backup actually restores | free · minutes to half an hour | no — advisory |
| 3 — non-deterministic behavior | on demand, and before shipping a prompt, model, or routing change | judgment didn't regress | money per run | no — advisory |
| 4 — the deployed stack | before a cutover | the deployed system works against real providers | money, small | no — it gates the switch, not the merge |
| 5 — operated | before a launch | the journeys a person has to watch happen | operator time | no — it prints a checklist |

What makes the ladder worth having:

- **Every gate is a script you can run by hand, and CI runs the identical script.** A gate that exists only inside a CI configuration cannot be run locally, so it cannot be debugged, and it cannot itself be tested (AGENTS.md §5). Local, CI, and agent then cannot drift into disagreeing.
- **A level's verdict means something only while the cheaper levels are green.** Say so where the ladder is written down, or a green level 2 will be read as covering a red level 1.
- **Money gates confirm before spending, and name the price in the prompt.**
- **Levels 4 and 5 are operated, not headless.** Their machine legs pass or fail on their own; their provider legs are attested by the person at the keyboard, one prompt at a time. A leg answered "skip" fails the run — an attestation nobody answered is not one that passed. Give it its own exit code so the difference is visible in a log.
- **A missing tool must fail, never skip.** A scan that quietly drops one leg hands back a clean bill of health over something it never read. Exit non-zero and name the tool.

Levels 4 and 5 are what `/go-live` consumes: it cites their output as evidence rather than re-deriving the checks. Build them as runnable scripts for that reason.

## 2. Required checks, advisory checks, and the aggregator

Branch protection — the setting that stops a merge until named checks pass — pins check *names*, and those names are configuration living outside the repository. Design so it rarely has to change.

- **Pin as few names as possible, and make one of them an aggregator.** An aggregator is one job that depends on every real job and asserts each finished green *or skipped*. Adding, renaming, or splitting a gate then edits the aggregator's dependency list inside the repository, and never touches the protection settings.
- **Never put a path filter on a required check.** A filter that skips the whole workflow means the check never reports, and a required check that never reports leaves the change waiting forever. Instead compute the change flags in one small job, and let each heavy job skip *itself* with a job-level condition: a **skipped** job satisfies a required check, a **never-started** one does not. A documentation-only change then merges in seconds without anyone weakening the gate.
- **A lane whose verdict can change with no code change must stay advisory.** Dependency advisories and live vendor state go red on a morning nobody committed. Requiring them blocks unrelated work over something its author did not cause, which is how a gate teaches people to route around it.
- **Every advisory lane needs a notifier, or it is decoration.** The failure mode is not a missing gate — it is a red run that reaches nobody for weeks. Have the lane open **one** tracking issue and add a comment per red run. Never one issue per run: a notification that arrives every night stops being read. Closing the issue is the person saying "triaged", and the next red run opens a fresh one.
- **Name what the notifier cannot see.** Anything that kills the run before the notifier job — the runner never starting, billing blocked, invalid workflow syntax — is invisible to it. The provider's own failed-run email is the only cover, and it is an account setting the repository cannot assert. Write that down rather than assuming coverage.

**Change filters are an optimization that can silently disable a lane.** A filter is safe when a lane can only break from one direction. It is a lie when the two breakage routes run opposite ways — something being added and something being removed — because a filter over either misses the other. Those gates run unconditionally. Decide the rest by what the filters actually save, measured from the provider's billing figures rather than projected from commit counts, and check what the first pattern excludes: a filter written as "everything except the documentation folders" makes a root-level markdown edit count as code.

## 3. Pinning what runs

**The version pins the name; the digest pins the bytes.** A tag is a mutable pointer: whoever controls it can re-point every pipeline in the repository at once, and nobody needs write access here to do it.

Pin to an immutable identifier — a content digest, or a full-length commit identifier — everything the pipeline executes from off the machine: reusable CI actions, base images, service container images, the local development data store, downloaded tool binaries (by checksum), and dated model identifiers. Carry the human-readable release as a trailing comment beside the pin, plus the date it was resolved, and move the two together.

Two consequences worth writing down. First, **the host usually does not enforce this** — check whether it can, say so either way, and add a repository gate that reads every pin, because review is otherwise the only thing holding the rule. Second, **an unpinned dependency changes the answer without changing the code**: a scanner one minor version behind may silently ignore configuration keys it does not recognize, quietly widening every exemption it was given.

## 4. Mutation lanes take turns

Two pipelines that change the same environment must not run at once. Give every mutating workflow the **same** concurrency-group string — a label the provider uses to serialize runs — and set cancel-in-progress to false. The shared string is the whole coupling, so a refactor that computes it differently in one file silently un-couples the two.

Cancelling a superseded run is right on a change branch and wrong on the mainline. On the mainline, work lands in bursts: a documentation-only push two minutes behind a code push cancels the code run, then legitimately skips the heavy jobs on its own diff — leaving the code commit tested by nothing while the branch reads green. Queue mainline runs; supersede branch runs.

Key the group on the *event* as well as the branch when one event acts on one environment and another acts on another. Otherwise a deliberate production action queues behind an ordinary merge, and providers that keep only one pending run per group will discard it.

## 5. Promotion is a ledger, not a trigger

One artifact, built once, promoted across environments. The lower environment deploys itself on every mainline commit that passed the gate. Production is a deliberate act that names a commit.

The production job then **refuses** rather than trusts. Each refusal is a check it runs on itself:

- the commit is not on the mainline branch → refuse.
- the commit's merge gate did not conclude success → refuse. Read the gate run's verdict, not the branch's current color.
- the commit's lower-environment deploy did not succeed → refuse. Production ships only what a lower environment already ran.

**Coupling by display name is silent.** Where one workflow triggers on another's *name*, renaming the first raises no error, no failed run, and no diff — just a lane that never starts again. Add a gate that compares the two strings, so the rename goes red on the change that makes it.

## 6. Deploy in two beats: candidate, then promote

Every step ends on something **observed**, never on the previous command returning zero.

1. Resolve the full-length commit identifier every artifact is tagged with, and ask the environment which services it actually has. A deploy that infers its own target list from a name is one rename away from building the wrong set.
2. Build and push one image per artifact, tagged with that commit.
3. Run the schema migration as its own step, under its own identity, and read the execution back. Migrations run before the new code takes traffic, and follow expand/contract — add and backfill now, drop in a later release (`../to-spec/rollout.md` §5).
4. Deploy a **candidate** release that takes **no traffic**.
5. The candidate gate: the release reports ready, it carries the image this run just built (compare digests, not tags), and one real request reached it and named the commit it is running.
6. Move traffic, then **read the traffic split back** and assert it.

A red candidate needs no rollback — it fails before promotion with zero traffic moved.

Three things a deploy script must not do. It must not apply infrastructure — a targeted apply leaves state partly converged. It must not pass environment variables, identities, scaling, or networking, because the infrastructure code owns those and one of the two will silently overwrite the other. It must not roll back: keep rollback a one-liner outside the script, and have the run print it filled in.

## 7. Applying configuration does not make it serve

On any platform where traffic is pinned to a named release, this is the most expensive surprise available:

> **An apply creates a new release and gives it none of the traffic.**

The old release keeps serving, with the old environment, the old scaling, the old everything. Every cheap check agrees with you: the resource reads back updated (that is the template for the *next* release), the health endpoint returns 200 (of the old release), and the apply honestly reported success.

Two things follow.

- **Tell the infrastructure code to ignore the image tag and the traffic split.** Otherwise an ordinary apply drags traffic back to "latest" and silently undoes a rollback.
- **Make "serve the applied configuration" a separate verb**, run after an apply. Have it work from **observed** input — ask which services have a newest release that is not the serving one — rather than from a list of targets it was told. It then cannot drift, and it is safe to run when nothing changed. Per service: refuse if the two releases run different images (that is a deploy, not a configuration change), refuse if the new one is not ready, show the environment diff, promote, read the split back, and prove a real request was served by the new release.

## 8. Infrastructure changes run in CI, not on a laptop

**No long-lived cloud key exists anywhere.** CI exchanges its own run identity for a short-lived token scoped to one applying identity; a person who needs to read state impersonates that identity rather than holding its key. Every apply is then attributable, and there is no private key to leak.

- **The lower environment applies itself** on every mainline merge that touches the infrastructure directory.
- **Production takes two deliberate acts**: a plan run that changes nothing and that somebody reads, then an apply that names *that plan's run identifier* and re-plans nothing. The local command is a thin wrapper that dispatches the run and watches it — the infrastructure tool never runs on the laptop, and the person's own credentials are never what changes production.
- **Pin the tool version.** A saved plan records the version that produced it, and the tool refuses to apply a plan made by a different one. With plan and apply in separate runs, an unpinned "latest" breaks that handoff the day the vendor releases.
- **One configuration, one variable file per environment, one state prefix per environment.** Do not fork the configuration per environment.
- **The trap that eats an environment:** a variable file does not select the state backend. Production's variables against the lower environment's state plans to destroy every resource there and recreate it under the production identifiers. Re-select the backend every time you switch, and read the state listing before typing an import.
- **Create the state store by hand.** The tool must never manage its own state.
- **Reading state locally is fine; applying locally is not.**

## 9. The destroys gate, and testing the gate

Read the plan; a proposed destroy is a stop, not a shrug. Make that a script: it reads the machine-readable plan and fails on any destroy whose exact resource address is not listed in that environment's approvals file. A deliberate removal is then a reviewed line in a file, in the open.

**The gate needs its own tests, and every lane depends on them.** An untested gate is a gate that agrees with you. The tell: a flag documented as being "so the gate can be run against a fixture" is an affordance built for a test nobody ever wrote. Run the gate's self-test first, cheap and credential-free, and have the plan and apply lanes wait on it, so a broken gate blocks an apply instead of waving it through.

## 10. What the infrastructure code deliberately does not own

Each of these is a checked-in script or a written step, and **each is silent when skipped** — which is why each needs a check that notices.

- **Secret values.** The code creates the containers; the values go in by hand. Reading a secret version as a data source persists the value into state. Keep the declared list of secret names as the checklist, and gate on *presence and version*, never on value — a check that reads a secret to verify it is a check that logs it.
- **The applier's own permissions.** The applying identity cannot grant itself, so it is bootstrapped by hand. The general rule worth carrying: **every time the configuration gains a service class it has never touched, the first apply fails on a missing role** — and the error names the service, not the missing grant, so it reads like a broken resource. Check the identity's roles against the services a change introduces, before applying it.
- **Anything holding live records that were built by hand** — most often a domain zone carrying live mail. Read it as a data source so the tool can never write it, and let the records it must not touch be declared nowhere and imported nowhere. A resource that names them is the failure this prevents.
- **Counts.** Never write a count into prose. Every count goes stale within a day of an apply; each is one command away, and the command cannot rot.

## 11. The lane that needs a clock

Most scheduled runs earn their place by catching a broken change filter or an unpinned dependency — fix those and the clock has no job left. One class survives: **state a person changes from a vendor console, with no commit anywhere to attach a run to.** No change-triggered lane can ever see it.

Give that class its own scheduled workflow and its own notifier. What it reads back, each against what the repository declares: services enabled in the account, the vendor's product and price catalog, which secrets hold a real value rather than a placeholder, whether the deployed estate still matches the declaration, and whether two environments sharing one vendor registration still hold matching credentials.

Run it **weekly while a backlog is expected**, not nightly — a red that arrives every morning stops being read, and a lane nobody reads is a lane nobody owns. Raise the cadence once a red means something new happened. Expect the first run red, and read that as the backlog it is. The one thing that must not happen is widening an allowlist to clear a finding: an entry added to quieten today's red silences every future finding that lands on the same name.

## 12. Secret scanning

- **Scan full history, not the tip**, and scan the built image as well as the tree — a secret can be baked in at build time by a file the tree never carried.
- **A structural false positive belongs in the scanner's configuration, not its ignore file.** An ignore entry pins one commit and one line; a history scan re-mints a new one on every commit whose patch re-adds the value, and a whitespace-only reformat is enough to do it. Reserve the ignore file for a genuinely one-off historical blob.
- **Scope every exemption three ways** — to one rule, to one path, and to the exact benign pattern, combined so all three must hold. A blanket path exemption for a public identifier hides the credential half that lives beside it.
- **Surface a committed secret; never hide it.** Production source files get no blanket exemption. If a real secret is found, stop and tell the user (AGENTS.md §8) — do not echo the value.

## 13. Proof, not plan

Two rehearsals belong in the pipeline rather than in a runbook, because a rehearsal nobody has run is fiction. The SPEC's cutover plan promises both (`../to-spec/rollout.md` §5 and §6) and `/go-live` cites them; what follows is how to make each one a check that can actually fail.

- **The previous release still boots against the migrated store.** Resolve the previous shipped release from the deploy history — not from the merge base — and run it. Fire this whenever the diff touches migrations. If the deploy history cannot be read, the check must go **red**, not fall back quietly: a fallback that still reports green is the same defect wearing a different hat.
- **A real backup actually restores.** Restore into a throwaway store and drop it. **Row counts cannot be the verdict** — a restore loads every row before it builds constraints, so counts match on both sides of a restore that died. Read the dump's own table of contents as the manifest instead.

## 14. The local environment

The local stack runs the **same images that ship**, not a hand-started server pair that no deployment ever runs. It is one more profile over the same artifact (`../to-spec/rollout.md` §7), so it belongs in the environment ladder as a row like any other.

- **Every local service declares its environment explicitly.** That declaration is the auditable opt-out of the image's baked production default — which is what makes a container that forgets to declare anything arm the production safety gates rather than disarm them.
- **Give every published port its own variable**, so a second checkout on the same machine can run beside the first. The data store is where two stacks collide first.
- **Local credentials are obviously local**, and marked as such where they are written.
- **Do not start a public tunnel with the stack.** A tunnel is a real public route to a laptop; it belongs to a session someone opens on purpose.
