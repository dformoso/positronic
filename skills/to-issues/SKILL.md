---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable GitHub issues using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# To Issues

Break a plan into independently-grabbable GitHub issues using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from what's already in the conversation, plus whichever of these exist:

| Source | What it supplies |
|---|---|
| `definitions/spec.md` | The implementation contract — the primary source, and what the slices decompose |
| `definitions/journeys.md` | Each journey's **end-state proof** and branches. **Copy them into acceptance criteria; do not invent new ones.** If a slice needs a criterion the journeys artifact doesn't have, that's a gap there — amend it, so the next increment inherits the fix |
| `definitions/mockups.md` | Panel ids. A UI slice's acceptance criteria name the panels it must render (`#j1-step4`), which is also what a Playwright check screenshots |
| `definitions/prd.md` | Fall back to this only if there's no SPEC |

If the user passes a GitHub issue number or URL as an argument, fetch it with `gh issue view <number>` (with comments).

Read the SPEC's **Verification fidelity** section — its per-axis rung (data, external access, eval signal, CUJ verification, deploy) and crossover list drive which slices verify against mocks vs. real deps, which credentials step 5 provisions, and which crossovers become their own slices. If the SPEC predates this section (or there's no SPEC), ask the user the per-axis fidelity and crossover question now, before drafting — default to building against faithful stand-ins (fixtures plus mock/sandbox adapters) with an explicit crossover before the release gate.

**Increment reconciliation.** If `definitions/spec.md` carries an `## Amendment` header *and* was last changed after the newest open issue was filed, the backlog predates the amendment — reconcile before creating anything. Both dates are one command each: `git log -1 --format=%cs -- definitions/spec.md` and `gh issue list --state open --limit 1 --json createdAt`. (The header alone won't do — it stays on the file after every amendment, so it says an amendment happened, never whether the backlog has caught up.) To reconcile: list open issues (`gh issue list --state open`) and map each to the amended SPEC. An issue whose capability the amendment dropped or reshaped is closed with a one-line comment naming the amendment that killed it ("Obsoleted by the `<increment>` amendment to `definitions/spec.md` — <reason>"); an issue whose contract changed gets its body updated. Only then draft new slices, scoped to the Amendment header's "Sections touched" list. Never leave an open issue implementing a capability the SPEC no longer contains — the cascade ends here, so this is the last place stale work can be caught.

### 2. Explore the codebase (optional)

If you haven't explored the codebase, do so.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices need human input (architectural decisions, design review). AFK slices can be merged without it. Prefer AFK over HITL where possible. A slice that needs a secret or interactive setup to verify (API key, OAuth consent) is HITL until that's provided — step 5 front-loads those credentials so most such slices can run AFK instead.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

**Fidelity and crossover slices.** Each slice's verification fidelity comes from the SPEC's Verification fidelity section, and that rung resolves the tracer-bullet tension: a slice still cuts every layer end-to-end, but whether its outer edge lands on a mock adapter or a real dependency is the rung's call — and that sets the slice's acceptance criteria (*verified against fake adapter* vs. *verified against sandbox key, CUJ driven*). Turn each crossover the section lists into its own slice — build the eval set, swap `<dep>` mock→live, deploy to staging, drive `<CUJ>` end-to-end — often HITL and good shape-establishing anchors others are `Blocked by`. Don't downgrade a UI slice to a mocked check when AGENTS.md already requires its CUJ driven in a real browser before done.

**Template-first pattern.** If multiple slices share the same shape (e.g., one standardizer per entity type, one extractor per data source), identify which slice *establishes* the shape and mark the others as `Blocked by` it. This serializes the mirror slices behind a working in-repo example and prevents parallel AFK agents from drifting into divergent shapes. The shape-establishing slice is often a good candidate for HITL (do it inline) so subsequent AFK agents can reference a finished file.

### 3b. Rank by certainty, then cut the waves

Issues are worked in **waves** — batches run in parallel, most certain first, with a review between each. Order matters because uncertainty is not evenly spread: the code that exists after wave 1 answers questions wave 2 would otherwise have had to guess at. Doing the least certain work last is how you avoid building on a guess.

Score every slice:

| Band | All of these hold | Goes to |
|---|---|---|
| **Certain** | The SPEC or journey it implements is unambiguous · an exemplar exists to mirror, or this slice *is* the shape-establisher · every dependency is available at its fidelity rung (a mock, or a credential already filled) · no PRD open question or risk touches it | Wave 1 |
| **Likely** | The contract is clear but one support is soft — no exemplar yet, or a sandbox dependency nobody has exercised | Wave 2 |
| **Unclear** | It depends on an unresolved open question, a decision the user hasn't made, or a dependency whose real behaviour nobody has seen | Last wave — and say so out loud, because the honest move may be to settle the question instead of scheduling the guess |

Then cut waves from that ranking, subject to two hard constraints:

- **No blocker crosses into its own wave.** A slice `Blocked by` another lands in a later wave than its blocker. The shape-establishing slice of any template-first group is always in an earlier wave than its mirrors.
- **No two slices in one wave edit the same files.** They run concurrently (AGENTS.md §9); colliding slices are a merge conflict you scheduled deliberately. When two certain slices collide, push one to the next wave.

A wave of one is fine. A wave of fifteen is fine if none of them collide. Size the wave to the work, not to a number.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short, plain-English task description — written as something a human would say, not a file path or module name. Good: "Build the login page". Bad: "api/auth.py — JWT handler + middleware".
- **Type**: HITL / AFK
- **Wave**: 1, 2, 3 … and the certainty band that put it there
- **Blocked by**: which other slices (if any) must complete first
- **Journeys covered**: which Key User Journeys (or user stories, if older format) this addresses

Also show the wave cut: which slices are in wave 1, 2, 3, and one line on why anything landed in a late wave.

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?
- Is there a shape-establishing slice that others should mirror? If so, are the mirrors `Blocked by` it?
- Is anything in wave 1 less certain than it looks — and is anything in a late wave actually blocked on a decision the user could make right now?

Iterate on user feedback.

### 5. Provision credentials for AFK

AFK agents run non-interactively in isolated worktrees — they can't open a dashboard, clear an OAuth consent screen, or ask you for a key. Any AFK slice whose tests or end-to-end check need a real secret will emit `blocked` unless that secret is already on disk. Front-load them here so the backlog runs unattended.

From the SPEC's **External dependencies** and **Security / authn / authz** sections (plus any integration the slices touch), list every credential the AFK slices need — but only for dependencies the **Verification fidelity** section marks **sandbox** or **live**. A dependency kept at the **mock** rung needs no credential and no `.env` entry; skip it here (its swap-to-live crossover, if any, carries its own credential when that slice runs). For each credential, work out:

For each: the **env var** the code reads, the **slices** that need it, and **how to obtain it** — a few steps plus the provider's own credentials page. Link the canonical console URL when you know it, the provider's docs when you don't; never guess a deep link. Flag any needing a paid plan, org-admin rights, or a consent flow — those usually stay HITL.

Then:

1. Make sure the env file is gitignored, and commit the ignore rule so it reaches the worktree checkouts — without this, an unattended run sees the `.env` as an untracked file, flags the worktree dirty, and downgrades every slice to blocked (never commit secrets — AGENTS.md §8):

   ```bash
   if ! grep -qxF '.env' .gitignore 2>/dev/null; then
     echo '.env' >> .gitignore
     git add .gitignore && git commit -m "Ignore .env for AFK credentials"
   fi
   ```

2. Write a gitignored `.env` at the repo root (or extend the existing one), one commented block per credential in this shape. Append only missing keys — never overwrite a value already present, and never write or print a real secret value yourself.

   <credentials-guide>
   # STRIPE_SECRET_KEY — charges + webhooks for the checkout slice (#12)
   # Get it: Stripe Dashboard → Developers → API keys → reveal "Secret key"
   #   https://dashboard.stripe.com/apikeys   (a test-mode key is fine for CI)
   STRIPE_SECRET_KEY=
   </credentials-guide>

3. Ask the user to fill the file in and say which they could and couldn't get. You write the template; they supply the values — so no secret lands in git or the transcript.

4. Re-classify: a slice stays `afk` only once every credential it needs is filled and nothing about its setup is interactive (no consent screen, no dashboard toggle the agent can't reach). Otherwise mark it `hitl`, and say which slices moved and why.

### 6. Create the GitHub issues

First, ensure the labels exist (idempotent — safe to run even if they already exist):

```bash
gh label create afk  --color "#9ca3af" --force
gh label create hitl --color "#3b82f6" --force
for w in $(seq 1 <highest-wave>); do
  gh label create "wave-$w" --color "#a78bfa" --force
done
```

For each approved slice, create a GitHub issue with two labels: `afk` or `hitl` for its type, and `wave-N` for its wave. Use the issue body template below.

Create issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

The wave label is the only scheduling state that lives in GitHub, and `/run-wave` both reads and rewrites it — an issue the between-wave review re-scopes gets relabelled rather than re-filed.

<issue-template>
## Parent

#<parent-issue-number> (if the source was a GitHub issue, otherwise omit this section)

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

## Source spec

Pointer into the SPEC this issue implements: section name or anchor in `definitions/spec.md`. Omit this section if no SPEC exists.

## Exemplar to mirror

Path of a file whose shape this issue should follow (e.g., `backend/app/extractors/standardize.py`). Omit this section if this issue establishes a new pattern rather than mirroring one.

## Decisions taken

- Decisions and rejected alternatives that constrain this issue, so the implementer doesn't re-open them.
- Omit this section if no load-bearing decisions apply.

## Shared conventions

- Cross-issue invariants this issue must respect (naming, shape, error handling).
- Omit this section if no shared conventions apply.

## Credentials / setup

- Env vars this slice needs, already provisioned in the repo's gitignored env file (e.g. `.env`): `STRIPE_SECRET_KEY`, `…`. Names and purpose only — never the values.
- Read them from the environment as the existing code does; do not hardcode.
- Omit this section if the slice needs no credentials.

## Acceptance criteria

Copied from `definitions/journeys.md` — the journey's end-state proof plus the branches this slice covers. For a UI slice, name the panel ids it must render.

- [ ] End state: <the journey's proof, asserted>
- [ ] Branch: **when** … **then** …
- [ ] …

## Scope discipline

- Fix bugs you find inside this slice, in place, in this issue. Do not open new issues for them.
- A bug **outside** this slice: leave it alone and report it in your final message. Do not open an issue for it, and do not fix it — the between-wave review decides what happens to it.
- The one exception: a bug that makes a shipped user journey fail or loses data. Stop and ask the user before doing anything about it.
- See `test-driven-dev` § Bugs found along the way for why.

## Blocked by

- Blocked by #<issue-number> (if any)

Or "None - can start immediately" if no blockers.

</issue-template>

Do NOT close or modify any parent issue.

### 7. Hand off

Prompt the user to run `/run-wave`. It launches wave 1 in parallel, reviews the backlog against what the wave actually built, and re-fires until the backlog is empty — that loop, not this skill, is where issues get worked.

Name what's waiting: how many issues in each wave, which are `hitl` (they need the user in the loop, along with any `afk` issue blocked by one), and any slice whose wave placement the user should reconsider before the first wave starts. A single issue can still be worked directly with `test-driven-dev`; `/run-wave` is for the backlog.
