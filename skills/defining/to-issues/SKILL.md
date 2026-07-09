---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable GitHub issues using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
disable-model-invocation: true
---

# To Issues

Break a plan into independently-grabbable GitHub issues using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from what's already in the conversation. If a `definitions/specs/` directory exists with files, read the most recent SPEC (`ls definitions/specs/[0-9]*.md | sort | tail -1`) as the primary source — the SPEC carries the implementation contract and is what issues should decompose. Otherwise, if `definitions/prds/` exists, read the most recent PRD (`ls definitions/prds/[0-9]*.md | sort | tail -1`) as the source. If the user passes a GitHub issue number or URL as an argument, fetch it with `gh issue view <number>` (with comments).

Read the SPEC's **Verification fidelity** section — its per-axis rung (data, external access, eval signal, CUJ verification, deploy) and crossover list drive which slices verify against mocks vs. real deps, which credentials step 5 provisions, and which crossovers become their own slices. If the SPEC predates this section (or there's no SPEC), ask the user the per-axis fidelity and crossover question now, before drafting — default to building against faithful stand-ins (fixtures plus mock/sandbox adapters) with an explicit crossover before the release gate.

**Increment reconciliation.** If the latest SPEC carries an `## Amendment` header, the open backlog predates it — reconcile before creating anything. List open issues (`gh issue list --state open`) and map each to the amended SPEC. An issue whose capability the amendment dropped or reshaped is closed with a one-line comment naming the superseding snapshot ("Obsoleted by `definitions/specs/<new>.md` — <reason>"); an issue whose contract changed gets its body updated. Only then draft new slices, scoped to the Amendment header's "Sections touched" list. Never leave an open issue implementing a capability the SPEC no longer contains — the cascade ends here, so this is the last place stale work can be caught.

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

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short, plain-English task description — written as something a human would say, not a file path or module name. Good: "Build the login page". Bad: "api/auth.py — JWT handler + middleware".
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **Journeys covered**: which Key User Journeys (or user stories, if older format) this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?
- Is there a shape-establishing slice that others should mirror? If so, are the mirrors `Blocked by` it?

Iterate on user feedback.

### 5. Provision credentials for AFK

AFK agents run non-interactively in isolated worktrees — they can't open a dashboard, clear an OAuth consent screen, or ask you for a key. Any AFK slice whose tests or end-to-end check need a real secret will emit `blocked` unless that secret is already on disk. Front-load them here so the backlog runs unattended.

From the SPEC's **External dependencies** and **Security / authn / authz** sections (plus any integration the slices touch), list every credential the AFK slices need — but only for dependencies the **Verification fidelity** section marks **sandbox** or **live**. A dependency kept at the **mock** rung needs no credential and no `.env` entry; skip it here (its swap-to-live crossover, if any, carries its own credential when that slice runs). For each credential, work out:

- **Env var** — the name the code reads (`STRIPE_SECRET_KEY`), matching the SPEC or existing code.
- **Used by** — the slice(s) that need it.
- **How to obtain** — a few steps plus the provider's credentials URL. Use the canonical console URL when you know it (Stripe → `https://dashboard.stripe.com/apikeys`, Anthropic → `https://console.anthropic.com/settings/keys`, OpenAI → `https://platform.openai.com/api-keys`); when you don't, link the provider's docs or credentials page rather than guessing a deep link. Flag any that need a paid plan, org-admin rights, or a consent flow — those often have to stay HITL.

Then:

1. Make sure the env file is gitignored, and commit the ignore rule so it reaches the worktree checkouts — without this, an unattended run sees the `.env` as an untracked file, flags the worktree dirty, and downgrades every slice to blocked (never commit secrets — AGENTS.md §8):

   ```bash
   if ! grep -qxF '.env' .gitignore 2>/dev/null; then
     echo '.env' >> .gitignore
     git add .gitignore && git commit -m "Ignore .env for AFK credentials"
   fi
   ```

2. Write a gitignored `.env` at the repo root (or extend the project's existing one) with one commented block per credential: the purpose and the how-to-obtain steps + link as comments, and an empty assignment for the user to fill. Append only missing keys — never overwrite a value already present, and never write or print a real secret value yourself.

   <credentials-guide>
   # STRIPE_SECRET_KEY — charges + webhooks for the checkout slice (#12)
   # Get it: Stripe Dashboard → Developers → API keys → reveal "Secret key"
   #   https://dashboard.stripe.com/apikeys   (a test-mode key is fine for CI)
   STRIPE_SECRET_KEY=
   </credentials-guide>

3. Show the user the same how-to-obtain list and ask them to fill in the file, then tell you which they could and couldn't get. You write the template and the guide; the user supplies the values — so no secret lands in git or the transcript.

4. Re-classify: a slice stays `afk` only once every credential it needs is filled in and nothing about its setup is interactive (no consent screen, no dashboard toggle the agent can't reach). Otherwise mark it `hitl`. Tell the user which slices moved and why.

### 6. Create the GitHub issues

First, ensure the labels exist (idempotent — safe to run even if they already exist):

```bash
gh label create afk  --color "#9ca3af" --force
gh label create hitl --color "#3b82f6" --force
```

For each approved slice, create a GitHub issue using `gh issue create --label afk` or `gh issue create --label hitl` based on the slice type. Use the issue body template below.

Create issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

<issue-template>
## Parent

#<parent-issue-number> (if the source was a GitHub issue, otherwise omit this section)

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

## Source spec

Pointer into the SPEC this issue implements: section name or anchor in `definitions/specs/<latest>.md`. Omit this section if no SPEC exists.

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

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- Blocked by #<issue-number> (if any)

Or "None - can start immediately" if no blockers.

</issue-template>

Do NOT close or modify any parent issue.

### 7. Hand off

Hand the backlog off to implementation: the unblocked `afk` issues can be worked unattended, each with `/test-driven-dev`. `hitl` issues (and any `afk` issue still blocked by one) need you in the loop — name them so the user knows what's waiting.
