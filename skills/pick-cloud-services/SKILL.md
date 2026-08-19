---
name: pick-cloud-services
description: Choose an external or cloud service for a category — hosting/compute, database, cache, queue, object storage, secrets, auth, transactional email, SMS/voice/telephony, DNS/CDN, CI/CD, logs/metrics, error tracking, LLM observability, backups, feature flags, or payments — from live research rather than memory, and lock it as a dated entry in definitions/infrastructure.md. Also use to re-pick when a vendor's pricing or terms change or a free tier dies, and — on a greenfield project — to decide the development-to-production path (local-first / cloud-first / hybrid) before any service pick. Use when choosing or re-choosing a provider for any infrastructure category. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Pick cloud services

Choose an external service for a category the way `pick-harness-shape` chooses a harness: gate first, shortlist, decide against fixed criteria, lock a dated record. The method is shared and lives in one file — this skill is the walk; the doc is the law.

## When to use

- Choosing a provider for any infrastructure category — compute, relational store, cache, queue/events, object storage, secrets, auth, transactional email, SMS/voice, DNS/CDN/TLS, CI/CD, logs/metrics, error tracking, LLM observability, backups/DR, feature flags, payments.
- Re-picking because a vendor's pricing or terms changed, a free tier died, or a `NEXT REVIEW` / `TRIGGER` line fired.
- On a greenfield project — deciding the development-to-production path *before* any service pick (greenfield mode below).

**Skip when** the pick is already a dated record with an *unfired* revisit trigger and a *future* `NEXT REVIEW`. Don't relitigate a settled decision that nothing has disturbed — that's churn, not diligence.

## Read first

`${SKILL_DIR}/../../docs/selection-method.md` (`${SKILL_DIR}` = the directory containing this file) — the shared method: core principles, the verify-at-decision-time checklist, the disqualifiers, the agent-workload wrinkles, and the full development-to-production path. This skill *executes* that method one category at a time; it does not restate it. If the doc and this skill ever disagree, the doc wins.

## Greenfield mode — path first

On the **first** invocation for a new project, before any service pick, decide the development-to-production path. Walk the method doc's 7 discriminating questions, then write the path record as the project's first decision record:

the `## Development-to-production path` section of `definitions/infrastructure.md` (create the file and `definitions/` lazily), containing:

- The picked route (local-first / cloud-first / hybrid) + the one-sentence trade-off.
- Answers to the 7 questions.
- The parity-discipline checklist you adopt — written as commitments, not aspirations.
- The armed `TRIGGER:` lines (line-start), drawn from the doc's trigger catalog.
- A `NEXT REVIEW: YYYY-MM-DD` line.

Then proceed category by category through the stack's needs, each as its own anytime-mode decision — one `##` section each, appended to the same file.

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
6. **Lock the record.** Write it (below). The decision is not made until it is recorded.

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
