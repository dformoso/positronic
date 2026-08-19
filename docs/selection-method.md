# Selecting external services — the method

How to choose an external service or provider for a category — and re-choose when the market moves — repeatably enough that the choice survives a changing landscape. This method ranks **how** to choose, never **who**. Every principle below is durable; every vendor, product, price, and limit is not. Any specific name a consuming skill mentions is a *dated example to re-verify live* — when it dies or changes, fix the skill's example, never bend the method.

## Core principles

- **Reversibility grades research depth.** A two-way door — cheap to walk back — gets a fast decision on sensible defaults; save the research for one-way doors, where reversing costs a rewrite. Spend the effort where the mistake is expensive, not everywhere.
- **~3 innovation tokens per project; boring everywhere else.** You get about three places to pick the exciting, unproven option. "Boring" is not old — it's the option your tools and model already know best and that *you* can debug when it breaks at the worst possible time. Spend a token only where the novelty is the point.
- **Build core, buy context, rent commodity.** Build what differentiates you. Buy what supports it but isn't yours to invent. Rent the undifferentiated utilities (compute, mail, DNS) from whoever runs them most cheaply and reliably.
- **Exit before entry.** Write the exit paragraph — escape hatch, egress path, honest rewrite cost — *before* you adopt anything. No exit answer means no adoption, for anything holding data you can't re-derive. If leaving isn't describable, you haven't finished choosing.
- **Records supersede, never edit.** Each decision is one dated section in `definitions/infrastructure.md`. When it changes, append a *new* section and mark the old one superseded; never rewrite it — the trail of why is the asset.
- **Keep a personal Hold list.** A vendor or product that burned you goes on a written list: nothing new starts on this. Past pain is data; don't pay to re-learn it.
- **Instrument unit economics before launch.** Know the cost per customer per month before the first customer, not after the bill. Wire budget alerts at 50 / 80 / 100% of the ceiling. For every free tier, write down the unit price *past the cliff* — a free tier is a loan, and the overage rate is the interest.
- **The startup-vendor rule.** Assume a young infrastructure vendor is gone, acquired, or frozen within ~18 months unless it has an escape hatch: an open-source core you can self-host, a standard protocol you can re-point, or a drop-in rival you could swap to. The newer the vendor, the further it must sit from your core data path.
- **Live-fetch before ranking.** Memory is a hypothesis, not evidence. Fetch the vendor's *own* pricing and terms pages at decision time — search-result summaries and third-party pricing blogs routinely disagree with the vendor's own page, and it's the vendor's page that bills you.
- **One sentence of trade-off per decision.** Name it out loud: "optimizing X, sacrificing Y." Security and data residency are *never* the Y — if a pick trades those away, it's disqualified, not a trade-off.

## Verify at decision time

Per shortlisted candidate, confirm freshly — not from memory:

- **Pricing page and its date** — the live page, and when you fetched it.
- **Free-tier fine print and the post-cliff price** — what the tier excludes, and what the first unit past it costs.
- **Egress / exit fees** — the cost to get your data *out*, not just to keep it in.
- **Deprecation-notice policy and changelog freshness** — do they promise notice before breaking you, and is the changelog recently touched?
- **Rate limits vs projected peak** — the published limits against your 10× peak, not your average.
- **Status-page history** — not that one exists, but what its incident record actually shows.
- **Terms** — do they train on your data? who is the named data processor? can residency pin to the region you need?
- **Funding / acquisition signals** — a recent raise, layoffs, or acquisition rumor: is this vendor about to change shape?

**Disqualifiers** — any one kills the candidate outright:

- No data-processing agreement for anything holding PII.
- Trains on your data with no opt-out.
- No deprecation-notice policy.
- No status page.
- Residency can't pin to the required region.
- No exit path for data you can't re-derive.

## Agent-workload wrinkles

- **Token cost dominates infra cost.** For an LLM/agent product the model bill dwarfs the servers. Optimize prompts, caching, and model tier before you trim server costs — and pick infra for reliability and residency, not unit-compute price.
- **Rate limits are architecture.** Provider limits, not your servers, are the real ceiling. Design the gateway, backpressure, and failover seam on day one — retrofitting it after the first throttle storm is a rewrite.
- **Model deprecation is a fast cadence.** Pin dated model ids, keep a swap seam behind them, and treat the provider's deprecation-notice policy as a first-class selection criterion — models retire faster than servers.
- **Managed agent runtimes bill on top of tokens.** A hosted agent or session runtime charges per session or per compute-unit *in addition to* the model tokens it spends. Model both lines, or the second one surprises you.
- **Provider concentration risk.** Leaning your whole stack on one provider's model, gateway, and runtime is a single point of failure and a single point of price hikes. Keep at least one swap seam.

## Do not import (dies at team size one)

Enterprise procurement rituals that cost more than they return for a solo dev:

| Heavyweight ritual | Do this instead |
|---|---|
| Weighted scoring matrix beyond ~8 axes | The 2–3 axes that actually gate *this* pick |
| A committee / sign-off chain | Sleep on one-way doors; write the record |
| A formal request-for-proposal | A time-boxed spike |
| A multi-option bake-off | Shortlist 2, spike the leader, name the runner-up as fallback |
| Multi-year total-cost modeling | Cost at today's volume and at 10× — two numbers |

## The development-to-production path

Before any single service pick on a greenfield project, choose the **path** from development to production. It is the first and most load-bearing infrastructure decision, and every later pick slots into it.

| Route | Optimizes | Defers | Failure mode |
|---|---|---|---|
| **Local-first** | Iteration speed; zero spend before signal | Deploy, ops, data custody | Migration debt compounds silently; a "temporary" dev-machine prod accretes real data, customers, and integrations until moving it is a project |
| **Cloud-first** | Production parity; always-on from day one | Nothing operationally — you pay now | Every iteration pays the deploy tax; spend before signal; console config drifts from anything reproducible |
| **Hybrid thin-staging** | A stable external URL without full migration | The full cloud migration | Two environments to keep honest; staging silently becomes a second prod |

**Reversible only if disciplined.** The path stays a two-way door *only while the parity disciplines below hold*. Skip them and it calcifies into a one-way door — the migration you deferred becomes a rewrite.

**The 7 discriminating questions** — each with the smell that answers it:

1. Do providers need public URLs / webhooks from week one? — *a tunnel from the dev machine is the smell that local-first is being propped up.*
2. When does real third-party data or PII first arrive? — *the hard custody trigger; the moment it lands, the machine holding it is production.*
3. How coupled is the design to managed services with no faithful local equivalent? — *a local stand-in that lies is worse than none.*
4. Does a demo, stakeholder, or partner need an always-on URL? — *if yes, something must be deployed and stay up.*
5. Edit-frequency × deploy-tax — *how often you change code times what each deploy costs; high × high is where cloud-first bleeds.*
6. Cost-of-delay of a later migration vs cost-of-drag of cloud-first — *delay grows with data, integrations, and customers; drag is flat per iteration. Compare the curves, not a single point.*
7. Will more than one person touch running infra soon? — *shared infra needs a shared place; a laptop isn't one.*

**Parity disciplines — local-first** (these are what keep it reversible):

- Containerize on day one — the *same image* runs locally and in prod.
- A dependency-injection seam at every external boundary — swapping mock → live *at the seam* is what makes an eventual migration a re-point, not a rewrite.
- Config by environment only — no baked-in hostnames, paths, or keys.
- No `localhost` assumptions in code — reconstruct URLs from the request or config.
- Prodness is *declared, never inferred* — a production boot with a dev/test flag set refuses to start.
- Secrets never live in files that would move with the code.
- Write a grep-able debt-ledger line for every local-only shortcut taken.

**Parity disciplines — cloud-first:**

- Keep a full local inner loop — iterating must never require a deploy.
- One-command ephemeral environments — a branch spins up its own.
- No console hand-edits — infrastructure as code, or codify it immediately after.

**Parity disciplines — hybrid:**

- Staging is a skeleton deploy plus a smoke check — nothing more.
- Synthetic data only — never real PII in staging.
- Disposable and reproducible — if it drifts, delete and recreate rather than repair.

**Trigger catalog** — arm these in the path record; each names its own action:

```
TRIGGER: first paying customer → start the migration plan
TRIGGER: first real PII record → formalize data custody now
TRIGGER: first always-on external integration → stand up a thin cloud endpoint (go hybrid)
TRIGGER: demo needs a stable URL → thin cloud staging
TRIGGER: more than one person touches running infra → shared cloud
TRIGGER: deploy or rollback feels manual and risky → deploy automation + a rollback contract
```

A fired trigger is the input to the `/go-live` gate. `/to-infrastructure` in greenfield mode records this path as the **first** section of `definitions/infrastructure.md`, and that section's exit-plan field *is* this trigger list. All revisit machinery is grep-able: sections carry a `NEXT REVIEW: YYYY-MM-DD` line and `TRIGGER:` lines each at the start of its own line; `/clean-house`'s step-1 sweep (the canonical check) flags past-due reviews and fired triggers each pass.

## This doc is method

If a consuming skill names a service that is dead, renamed, or changed its terms, fix that skill's example — never bend the method to fit a name. The names rot; the method doesn't.
