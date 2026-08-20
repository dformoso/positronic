---
name: to-infrastructure
description: Define how the software gets built, tested, deployed and run — the development-to-production path, the environment ladder (local / test / staging / prod), the gate ladder and which check blocks a merge, CI/CD, infrastructure-as-code, deploy, promotion and rollback mechanics — and choose every external service (compute, database, cache, queue, object storage, secrets, auth, email, SMS/voice, DNS/CDN, CI/CD, telemetry, error tracking, backups, feature flags, payments) from live research rather than memory. Writes definitions/infrastructure.md. Use on a greenfield project before /to-spec, when adding or re-picking any provider, or when the deploy path itself needs deciding. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# To Infrastructure

Decide how this software gets built, deployed and run, and write it down in one place: `definitions/infrastructure.md`. Two kinds of decision live here and they share a file because every consumer needs both at once.

- **The plumbing** — the development-to-production path, the environment ladder, the gate ladder, CI/CD, infrastructure-as-code, and how a merged commit becomes running code. Decided once, revisited on a trigger.
- **The services** — one entry per external provider, chosen the way `pick-harness-shape` chooses a harness: gate first, shortlist, decide against fixed criteria, lock a dated record. The method is shared and lives in one file — this skill is the walk; the doc is the law.

**This skill defines; `/go-live` verifies.** Everything written here is a promise about the running system — that prod refuses dev affordances, that rollback was rehearsed, that backups retain. `/go-live` is the gate that goes and checks whether those promises are true before real traffic. Producer and consumer: don't collapse them, or the launch has nothing independent to fail against.

## When to use

- On a greenfield project, after `/to-prd` and before `/to-spec` — greenfield mode below walks the path, the environments, the gate ladder, the build-and-deploy pipeline, and infrastructure-as-code in order.
- Choosing a provider for any infrastructure category — compute, relational store, cache, queue/events, object storage, secrets, auth, transactional email, SMS/voice, DNS/CDN/TLS, CI/CD, logs/metrics, error tracking, LLM observability, backups/DR, feature flags, payments.
- Re-picking because a vendor's pricing or terms changed, a free tier died, or a `NEXT REVIEW` / `TRIGGER` line fired.
- When the deploy path itself changes — a new environment, a new gate or a gate promoted to required, a pipeline rewrite, moving from console-clicked infrastructure to code.

**Skip when** the pick is already a dated record with an *unfired* revisit trigger and a *future* `NEXT REVIEW`. Don't relitigate a settled decision that nothing has disturbed — that's churn, not diligence.

## Read first

`${SKILL_DIR}/../../docs/selection-method.md` (`${SKILL_DIR}` = the directory containing this file) — the shared method: core principles, the verify-at-decision-time checklist, the disqualifiers, the agent-workload wrinkles, and the full development-to-production path. This skill *executes* that method one category at a time; it does not restate it. If the doc and this skill ever disagree, the doc wins.

`${SKILL_DIR}/pipeline.md` — the mechanics behind steps 3–5 below: the gate ladder, required-versus-advisory checks, pinning, promotion, the candidate-then-promote deploy, why an apply does not make configuration serve, the destroys gate, and the drift lane that needs a clock. Each shape comes with the trap that makes the obvious version wrong. Read it before answering those three steps; cite it rather than restating it.

## Greenfield mode — the plumbing, in order

On the **first** invocation for a new project, walk these five before any service pick. Each answers a question the next one depends on, so don't reorder them. Ask one at a time and recommend an answer.

### 1. Development-to-production path

Walk the method doc's 7 discriminating questions, then write the `## Development-to-production path` section (create the file and `definitions/` lazily):

- The picked route (local-first / cloud-first / hybrid) + the one-sentence trade-off.
- Answers to the 7 questions.
- The parity-discipline checklist you adopt — written as commitments, not aspirations.
- The armed `TRIGGER:` lines (line-start), drawn from the doc's trigger catalog.
- A `NEXT REVIEW: YYYY-MM-DD` line.

### 2. Environment ladder

Which environments exist, and what is *real* in each. The trap is an environment nobody can describe: "staging" that quietly holds production data, or a "test" that is one developer's laptop.

One row per environment — including the local one. Fewer rows is better: every environment is a thing to keep honest, and an unowned one drifts into a second production.

| Environment | Exists to | Data | External services | Who/what deploys to it | Lifetime |
|---|---|---|---|---|---|

Four rules the table has to satisfy. The first three are from `${SKILL_DIR}/../to-spec/rollout.md` §7:

- **Every environment is a config profile over one SHA-tagged artifact.** A demo is a profile, never a forked build. That includes the local one: it runs the same images that ship, not a hand-started server pair no deployment ever runs (`${SKILL_DIR}/pipeline.md` §14).
- **Prodness is declared, not inferred** from a hostname or a missing variable — and a production boot with a dev/test flag set must fail loudly rather than run with the flag live. Bake the production declaration into the artifact, so a container that declares nothing arms the safety gates rather than disarming them, and make every non-production profile opt out in writing.
- **Synthetic data outside production.** If a non-production environment needs real records, say which, why, and what masks them; an unmasked copy makes that environment production for custody purposes.
- **One configuration, one variable file per environment.** Never fork the configuration per environment — and remember that the variable file does not select where state lives, which is the mistake that plans to destroy a whole environment (`${SKILL_DIR}/pipeline.md` §8).

Name the SPEC's **Verification fidelity** Deploy rung this ladder implies (local / staging / prod-flagged) so `/to-spec` inherits it rather than re-deriving it.

### 3. The gate ladder

Which automated checks exist, what each costs, and which single one a merge waits on. Decide this before the deploy pipeline: promotion is only as trustworthy as the check it reads a verdict from.

Walk `${SKILL_DIR}/pipeline.md` §1–§3, then settle:

| Decision | The question that settles it |
|---|---|
| Which levels this project runs | What can break here that a cheap deterministic check cannot see? Every level you keep must prove something the one below it can't |
| The one entry point per level | AGENTS.md §5: gates are versioned scripts a human runs by hand, and CI runs the identical script. A gate that exists only inside a CI config is unrunnable locally and untestable |
| Which check names branch protection pins | As few as possible, and one of them an aggregator — so adding a gate edits a list in the repo, never the protection settings |
| Which lanes are advisory | Anything whose verdict can change with no code change. Requiring those blocks unrelated work over something its author didn't cause |
| The notifier for each advisory lane | An advisory red that reaches nobody is decoration. One tracking issue, a comment per red run — never one issue per run |
| Which lane needs a clock | Only the state a person changes from a vendor console, with no commit to attach a run to. Everything else is change-triggered |
| What every pin is pinned to | The version pins the name; the digest pins the bytes. Name what enforces it, or say that review is the only thing that does |

Record as `## Gate ladder` — the level table, the pinned check names, the advisory lanes with their notifier, and the scheduled lane with what it reads back.

### 4. Build & deploy pipeline

How a commit becomes running code. Decide, in this order:

| Decision | Options | The question that settles it |
|---|---|---|
| CI provider | The host's built-in (GitHub Actions, GitLab CI) · a dedicated service · none yet | Where does the code already live? Bundled wins unless minutes pricing or a self-host requirement forces otherwise |
| What CI runs | The gate ladder from step 3 | Nothing new is decided here — CI calls those same scripts |
| Trigger | On change · on merge to the mainline · on tag | Does a merge deploy, or does a tag? Say which, once |
| Artifact | Container image · language package · source deploy | One SHA-tagged artifact promoted across environments, never rebuilt per environment |
| Promotion | Automatic to the lower environment on green · deliberate for production | Automatic promotion to production needs the rollback rehearsal already done. Production refuses rather than trusts: not on the mainline, gate didn't pass, lower-environment deploy didn't succeed — three checks the job runs on itself (`${SKILL_DIR}/pipeline.md` §5) |
| Deploy shape | Candidate at zero traffic, then promote · replace in place · blue-green | Can a release be proved *before* it takes traffic? If the platform can hold one at zero traffic, use it — a red candidate then needs no rollback (`${SKILL_DIR}/pipeline.md` §6) |
| Schema migrations | Own step, own identity, before the new code takes traffic | Expand/contract, per `${SKILL_DIR}/../to-spec/rollout.md` §5. Who runs the migration, and does that identity hold anything else? |
| Serving applied config | A separate verb after an apply · nothing, because the platform serves it immediately | On any platform where traffic is pinned to a named release, an apply creates a release holding no traffic — and every cheap check agrees with you. Answer this explicitly (`${SKILL_DIR}/pipeline.md` §7) |
| Mutation ordering | One shared concurrency group across every lane that changes an environment | What happens when a deploy and an infrastructure apply land together? Queue, never cancel |
| Secrets in CI | The host's secret store · the cloud's secret manager | Never in the config file, never echoed in logs (AGENTS.md §8) |
| Rollback | Re-point to the previous release · redeploy the previous tag · flag flip | It must be rehearsed once for real before automatic promotion to production is allowed. `/go-live` asks for the dated rehearsal note, so produce one |

### 5. Infrastructure as code

| Rung | When it's right | Cost of staying here |
|---|---|---|
| **Console-clicked, undocumented** | Never past the first week | Nothing is reproducible; the environment is a single point of failure with no backup |
| **Console-clicked, written down** | A genuinely tiny surface — one service, one database | Drift between the doc and reality is invisible until a rebuild |
| **Declarative, in the repo** (Terraform, Pulumi, OpenTofu, CDK, or the platform's own manifest) | The default once more than one service or more than one environment exists | Real learning cost; state has to live somewhere durable |

If declarative, settle six things that bite later and are expensive to change:

| Decision | The question that settles it |
|---|---|
| Where state lives | A remote backend with locking and versioning — never a laptop, never unversioned. Create the state store by hand: the tool must never manage its own state |
| Where the apply runs | In CI over a short-lived token, or on a laptop holding a long-lived key? Prefer CI: nothing to leak, and every apply is attributable |
| Who may apply, and how production differs | The lower environment applies itself on merge. Production takes two deliberate acts — a plan somebody reads, then an apply naming *that plan*, re-planning nothing |
| The destroys gate | A proposed destroy is a stop unless its exact resource address sits in that environment's approvals file. The gate needs its own tests, and every lane waits on them — an untested gate is a gate that agrees with you |
| What is *not* in code, and why | Secret values, the applier's own permissions, anything holding live hand-built records. Each is silent when skipped, so each needs a check that notices (`${SKILL_DIR}/pipeline.md` §10) |
| What the code must ignore | The image tag and the traffic split, so an ordinary apply cannot drag traffic back to "latest" and silently undo a rollback |

Record the picks as `## Environments`, `## Gate ladder`, `## Build & deploy`, and `## Infrastructure as code` sections. Then proceed category by category through the stack's needs, each as its own anytime-mode decision — one `##` section each, appended to the same file.

## Anytime mode — one decision

1. **Requirements sheet — 5 lines.** Capability needed; scale now + at 12 months; residency requirement; budget ceiling (absolute *and* per-account); the one non-negotiable.
2. **Shortlist via live research.** This skill *refuses to shortlist from memory.* Search the current landscape at decision time. Include the primary cloud's bundled option plus 2–4 challengers. Fetch each candidate's *own* pricing and terms pages — never trust a search summary or a third-party pricing page for a number.
3. **Verify + disqualify.** Run the method doc's verify-at-decision-time checklist and disqualifiers against every survivor. Any disqualifier kills the candidate.
4. **Quick-score the 8 axes.** Green / amber / red each:

   | Axis | Red means |
   |---|---|
   | Unit cost at 1× and 10× | Cost breaks the ceiling at projected scale |
   | Lock-in / exit cost | No described exit for non-re-derivable data |
   | Ops burden | You'd babysit it instead of building |
   | Maturity / longevity | Fails the startup-vendor rule with no escape hatch |
   | Hard limits / quotas vs the 10× projection | A published limit sits below your 10× peak |
   | SLA on *your* tier | The SLA you'd actually be on, not the enterprise one |
   | Data residency (control plane *and* inference) | Can't pin to the required region |
   | Security / compliance gating | Single sign-on or audit logging is paywalled above your tier |

   Any **red** is either justified in the record or kills the candidate.
5. **Tie ⇒ spike.** A time-boxed spike (≤ 1 day) with kill criteria *written before* the spike starts. No open-ended evaluations.
6. **Lock the record.** Write it (below). The decision is not made until it is recorded. **Write it in plain English** — short sentences, one idea each, concrete before abstract, jargon glossed on first use, readable by someone who wasn't in this conversation (AGENTS.md §4).

## The record

One `##` section per category in `definitions/infrastructure.md`, headed `## <Category> — <choice> (YYYY-MM-DD)`. The file is amended in place per `${SKILL_DIR}/../../docs/amend-mode.md`: a later re-pick **appends the new section and marks the old one superseded** — it never deletes it. The trail of what was chosen before, and why it stopped being right, is the asset; keeping it in the file rather than in git means one read recovers it.

```
## Transactional email — <choice> (2026-08-20)
**Superseded by:** <choice> (2027-02-11)     ← added when re-picked; the body stays
```

Every section carries these mandatory fields:

- **Requirements sheet** — the 5 lines.
- **Shortlist with research provenance** — every fact tagged with its source page + the date fetched.
- **Scorecard** — the 8 axes, green / amber / red, every red justified.
- **Decision + the one-sentence trade-off** — "optimizing X, sacrificing Y"; security and residency are never Y.
- **Cost model** — at 1×, at 10×, per-account.
- **Exit plan** — escape hatch, egress path, honest rewrite estimate. (For the greenfield path record, this field *is* the trigger list.)
- **Revisit triggers** — `TRIGGER:` lines at line-start.
- `NEXT REVIEW: YYYY-MM-DD`.
- **Alternatives rejected + why** — so a later pass doesn't re-suggest them.
- **Sources** — each with the date fetched.

## Category questions

Ask only the 2–3 that gate the pick. **Governing default, every row: take what your primary platform already bundles, unless a discriminating question forces otherwise.** The per-category default sharpens that below.

| Category | Default posture | The 2–3 that gate a change |
|---|---|---|
| Compute | What the platform bundles | Long-running or scale-to-zero? Stateful? Cold-start tolerance? |
| Relational store | The platform's managed store | Point-in-time recovery? Read-scale path? Residency? |
| Cache | None — until a profiler says so | Is the store genuinely the bottleneck? |
| Queue / events | The database | Do scale-to-zero economics actually demand a broker yet? |
| Object storage | The platform's bucket | Egress price (the trap) · lifecycle tiering · residency |
| Secrets | The platform's secret manager | Rotation · access audit · blast radius on leak |
| Auth / identity | Platform, or a standard-protocol provider | Re-pointable protocol? Single sign-on tier-gated? Residency? |
| Transactional email | A dedicated provider — never the app server | Deliverability · a data-processing agreement · bounce handling |
| SMS / voice / telephony | A dedicated provider | Number provisioning · per-message cost at 10× · regional reach |
| DNS / CDN / TLS | What the platform bundles | Cert automation · cache-invalidation cost · egress |
| CI/CD | What the platform bundles | Minutes pricing · self-host escape hatch · secrets handling |
| Logs / metrics / alerts | The platform's bundled telemetry | Ingest / retention pricing (the trap) · cardinality limits |
| Error tracking | A dedicated provider | Event-volume pricing · PII scrubbing · retention window |
| Backups / DR | The managed store's point-in-time recovery | Does compliance demand cross-region or longer retention? |
| Feature flags | Env vars / a config table (solo) | Does a team now need a shared UI + audit? |
| Payments | Hosted checkout | Minimum card-data scope — never touch raw card numbers |

## Anti-patterns

| Anti-pattern | The tell |
|---|---|
| Free-tier trap | Adopting on the free tier without pricing the unit *past* the cliff |
| Egress trap | Cheap to store, expensive to leave — priced only on the way in |
| Resume-driven choice | Picking the exciting tool to learn it, not because the pick needs it |
| Premature multi-cloud | Two clouds "for resilience" — one cloud plus a written exit beats it |
| Marketplace / reseller lock-in | Buying through a layer that owns both the contract and the exit |
| Per-seat pricing under agent load | Seat pricing that explodes when agents, not humans, are the users |
| Enterprise-gated table stakes | Single sign-on, audit logs, or residency locked above your tier |
| "We'll migrate later" | An adoption with no written exit — the migration never gets cheaper |

## Freshness & sweep wiring

Every fact in a section is dated at the point it was fetched. `/clean-house` sweeps every `NEXT REVIEW:`/`TRIGGER:` line each pass (its step-1 sweep owns the canonical check, covering `definitions/infrastructure.md`, `definitions/decisions.md`, and `definitions/runtime.md`) — and a fired path trigger is the input to the `/go-live` gate. This skill names **no vendor, product, price, or version** on purpose: if one ever appears here, it is a bug in an example, never the method. Fix the example; leave the method alone.
