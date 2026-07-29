---
name: go-live
description: Evidence GO/NO-GO gate before real users or real traffic reach a deployment for the first time, or before any one-way cutover — a domain/DNS move, a datastore migration, or re-pointing any provider that holds data or serves inference. Report-only, never auto-fixes. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

If the user did not explicitly invoke this skill — by name, by slash/dollar command, or via its workflow stub — stop: say it exists and wait for them to invoke it.

# Go Live

Verify the deployment is ready in the *running environment*, not on paper. A GO/NO-GO gate over runtime facts. Reports only — never auto-fixes. Mirrors `/review-pr`'s posture.

| Skill | Reads | When it fires | What it checks |
|---|---|---|---|
| `/audit-failure-modes` | The code | Before a release cut | How the system *could* break (pre-mortem) |
| `/go-live` (this) | The running deployment | Before first traffic or a one-way cutover | Whether the facts a launch depends on are *actually true* |

**The split is epistemic.** `/audit-failure-modes` reads code to enumerate what could break; no code-read can tell whether the secret is set in the deployed environment, whether point-in-time recovery is actually retaining, whether a synthetic crash actually reached the error tracker, or whether the last restore drill is recent. Those are runtime facts. Run `/audit-failure-modes` for the code pre-mortem; run this for the evidence.

## Process

### 0. Orient — consume, don't re-derive

Inventory what the project already wrote: deploy and verify scripts, runbooks, the cron/schedule inventory, the secrets doc, and the SPEC's Rollout section (`${SKILL_DIR}/../to-spec/rollout.md`; `${SKILL_DIR}` = the directory containing this file). Every gate row below is settled by **citing evidence** — a command the repo already carries, a runbook Verify clause, a dated drill record — never by re-checking from memory. If the project carries a pre-switch gate script, **run it and read its output**; do not re-implement its checks. Gates are scripts (versioned, reviewed, tested); this skill adds judgment, not a duplicate check.

### 1. The gate

Each row: the check · the evidence that settles it · pass/fail. A row with no citable evidence fails — "should be fine" is not evidence. Evidence must also be *current*: a dated record older than the last change it vouches for (schema change, provider re-point, cert rotation) fails the row the same as no record. Action rows ("attempt one", "flip it", "drive one to the cap") require a reproducible token — the command run and its output, a trace id, or a dated record path; a prose claim that it was done fails. Strike an area only via §3.

**(a) Environments & config**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Prod is a config profile over the same SHA-tagged artifact as every environment — never a forked build | release provenance; profile diff | |
| Prodness is *declared*, not inferred from a hostname or a missing var | the flag that declares it | |
| Production boot refuses dev/test affordances by construction | attempt one — confirm it is refused | |
| Config parity diffed against the last-good environment | the diff | |

**(b) Secrets**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Custody documented — who holds what, where | the secrets doc | |
| Rotation path exists and has been walked once | dated rotation record | |
| Nothing secret in images, repos, or infrastructure state | scan output | |
| The deployed environment holds the live values | boot gate or probe proves the load-bearing ones are set — never read values aloud | |

**(c) Domains / DNS / TLS**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Certificate is active, not still provisioning | live handshake | |
| DNS TTLs lowered ahead of a cutover | the record's TTL | |
| Rollback re-point rehearsed | dated rehearsal note | |

**(d) Data**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Backups enabled and verified | backup config + one verified snapshot | |
| Point-in-time recovery window confirmed | the retention setting | |
| A restore drill performed, with a dated record | the `docs/audits/…` drill record — an unrehearsed runbook is fiction | |
| The restore fence written down — what re-arms after restore (cursors, rotated tokens, webhooks) | the fence doc | |

**(e) Monitoring**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Uptime probe on the public endpoint | the probe config | |
| Budget alert armed | the alert | |
| Error tracking proven by one synthetic crash reaching it | the crash visible in the tracker | |
| Readiness endpoint reports the serving version | hit it — read the version back | |

**(f) Release mechanics**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Deploy traceable to a SHA | the deployed revision's SHA | |
| Rollback to the previous revision rehearsed once for real | dated rehearsal note | |
| Schema-change contract honored — the previous release boots against the migrated store (expand/contract) | the boot-the-previous-image proof (see rollout.md) | |
| Kill switch for the riskiest new surface | flip it in a non-prod profile | |

**(g) Cost guardrails**

| Check | Evidence | ✓/✗ |
|---|---|---|
| Spend caps set from real prices, not placeholders | the cap config | |
| Per-account and global caps, if an agent/LLM surface exists | the cap config | |
| Billing export / alerts on | the export or alert | |

**(h) Support & legal**

| Check | Evidence | ✓/✗ |
|---|---|---|
| A support channel that reaches a human | the address/inbox | |
| Privacy policy + data export/deletion path exist | the pages/endpoints | |
| Recording/consent disclosures wired, if any surface records | the disclosure in the flow | |

### 2. Agent-surface rows

Only when an LLM/agent surface exists:

| Check | Evidence | ✓/✗ |
|---|---|---|
| Model ids pinned to dated snapshots | the pinned ids | |
| Runaway-loop caps proven — a capped account actually halts | drive one to the cap | |
| Prompt-injection posture stated for every channel where customer-controlled text reaches a prompt | the stated posture, per channel | |
| One end-to-end run on the deployed stack | the run's trace | |

Injection *depth* — per-channel treatment — belongs to `/audit-failure-modes`' agent-surface category; cite it, don't duplicate it here.

### 3. Pushback

Not every row applies at every scale. Strike a row **with a one-line reason** — a solo pre-revenue product may strike the status page or the multi-region rollback, and that's honest. But a struck row that guards a catastrophe class — data loss, bill shock, prolonged downtime, breach, lock-in — gets argued back: name the catastrophe it guards and restore it. A solo product may strike the status page; it may never strike the backup drill.

If nothing is struck, say so. Don't manufacture pushback.

### 4. Verdict

Print to chat:

```text
## Verdict: GO / NO-GO

## Blockers
### P0 — no traffic until fixed
- {area-row} — {the missing evidence, and what produces it}
### P1 — fix within days
- {…}

## Struck (with reason)
- {area-row} — {why it doesn't apply at this scale}
```

NO-GO if any P0 stands. A failed — or struck — row that guards a catastrophe class (§3: data loss, bill shock, prolonged downtime, breach, lock-in) is P0 by definition: it may not be filed P1 and may not appear under Struck. Struck is for rows that don't apply at this scale, never for rows that failed. Don't summarize what the deploy does — cite evidence or its absence.

### 5. Save (optional)

After printing, ask:

> Save to `docs/audits/YYYY-MM-DD-go-live.md`? (y/N)

Default no. Create `docs/audits/` lazily on first save.

A fired `TRIGGER:` line in the project's path record (`docs/adr/`, written by `pick-cloud-services`; method in `${SKILL_DIR}/../../docs/selection-method.md`) is a standing reason to run this gate before the next cutover.
