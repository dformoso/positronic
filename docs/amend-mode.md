# Amend mode — evolving an artifact after the first cut

positronic keeps one document per artifact type, flat in `definitions/`, each named for what it holds:

| File | Written by |
|---|---|
| `definitions/research.md` | `/research-market` |
| `definitions/ideas.md` | `/ideate` |
| `definitions/prd.md` | `/to-prd` |
| `definitions/journeys.md` | `/to-journeys` |
| `definitions/mockups.md` + `definitions/mockups.html` | `/to-mockups` |
| `definitions/harness.md` | `pick-harness-shape` |
| `definitions/mcp-servers.md` | `design-mcp-server` (one section per server) |
| `definitions/runtime.md` | `pick-harness-shape`, at the placement gate |
| `definitions/infrastructure.md` | `/to-infrastructure` (path, environments, gate ladder, CI/CD, infrastructure-as-code, one section per service) |
| `definitions/decisions.md` | `/clean-house`, `/improve-readability` (one section per decision) |
| `definitions/spec.md` | `/to-spec` |

Each one is a **whole-product** document that every consumer reads by name. There are no subdirectories, no timestamps, and no second copy — the file *is* the current truth, and git holds every version it used to be.

The last two work slightly differently: they are **append-and-supersede** rather than edit-in-place. A re-pick or a reversed decision adds a new section and marks the old one `**Superseded by:**`, leaving its body intact. Keeping the trail inside the file rather than only in git means one read recovers why a path was abandoned — which is the whole value of a decision record.

That leaves one trap. When a feature lands after the first cut, the tempting move is to regenerate the file around the new feature — and everything the product already did, which the change never touched, quietly disappears. Amend mode is the discipline that prevents it: read the file as **baseline**, change only the delta, leave the rest byte-for-byte alone. The product stays whole, the work stays incremental, and `git log -p definitions/prd.md` is the changelog.

## When it applies

| Situation | Path |
|---|---|
| Typo / bug, no behaviour-contract change | `diagnose` — no artifact change |
| A settled decision or tradeoff, no scope change | A section in `definitions/decisions.md` (or `definitions/infrastructure.md` for a service pick) |
| A scoped change: new, changed, or dropped capability | **Amend** the implicated artifact(s) |
| A pivot — the product is now a different product | Rewrite the file from scratch, **no** Amendment header |

**Pivot test (sharp line):** if the change rewrites the PRD's **Target User** or **Problem Statement**, it's a pivot — start fresh. Amend only while those two anchors hold; everything downstream is negotiable, those two are the product's identity.

## The change tier

Which artifacts a change must touch, decided once at the top of the PRD rather than inherited. Four tiers:

| Tier | What it is | Artifacts it touches |
|---|---|---|
| `fix` | A bug or a copy change. No contract moves | None. `diagnose` or `test-driven-dev`, straight to the code |
| `internal` | A refactor, a dependency swap, anything with no user-visible surface | `definitions/spec.md` only |
| `feature` | A new, changed, or dropped capability the user can see | PRD (if the promise moves) → journeys → mockups (if it has UI) → SPEC → issues |
| `launch` | First real traffic, a migration, a provider re-point, a new service | Everything in `feature`, plus the SPEC's Rollout runbook, `/go-live`, and a `/readout` date |

**Applying the heaviest tier to everything is the failure mode of a framework like this.** A copy change does not get a journey script, a redrawn mockup, and a cutover runbook; a datastore migration does not get to skip them. The tier is a judgment someone makes out loud, which is why it is a field and not a default.


## The protocol

1. **Read the baseline** — the artifact's file, whole.
2. **Read the change intent** — the increment's scope, from `define`'s increment frame or the conversation.
3. **Scope the delta** — name exactly which template sections the change touches.
4. **Edit in place, section by section** — targeted edits to the sections in scope. **Do not regenerate the file.** Rewriting it wholesale re-derives locked decisions you never meant to reopen (AGENTS.md §3, at the artifact level) and is how untouched capabilities go missing. **One exception:** if the delta *contradicts* an untouched section — a new feature that was a prior Non-Goal, a constraint the change breaks — that section is now in-scope. Reconcile it; never leave a document that contradicts itself.
5. **Update the Amendment header** — replace it with this amendment's, at the top of the file.
6. **Commit** — the diff is the changelog. No separate changelog file.

## The Amendment header

Directly under the artifact's title, so the document is self-describing about its most recent delta:

```
## Amendment — 2026-03-01
- **Increment:** team-workspaces                    (optional human label)
- **Tier:** feature
- **Change:** Add seat-based team workspaces so a buyer can invite members — closes the top churn risk.
- **Sections touched:** Solution Overview; Key User Journeys (CUJ 4)
- **Carried forward unchanged:** all others
```

Each artifact's header names its own sections — the example above is a PRD's. The same amendment's journeys header would name what it touched (`Reference (Data model, Permissions); J7 — Invite a teammate`), and its mockups header the panels re-rendered.

**This header is the increment's record** — it plays the role `define`'s hypothesis frame plays for greenfield. There is no separate change-request artifact.

It describes the **latest** amendment only, and each amend replaces it. Earlier ones aren't lost: `git log -p definitions/prd.md` walks the whole chain, each entry carrying the header that was current at the time. A document written from scratch — greenfield or pivot — has no header until its first amend.

## The cascade rule

What stops "rewrite five artifacts per feature." An amended artifact forces a downstream amend **only** where a touched section feeds it. The amending skill names the implicated artifacts and prompts only those:

| Touched | Implicates |
|---|---|
| PRD — Solution Overview, Key User Journeys, or anything that changes what the product does | `definitions/journeys.md` (`/to-journeys`) |
| PRD — Solution Overview surfaces / form factor | `definitions/mockups.md` (`/to-mockups`) |
| PRD — Goals & Success Metrics or kill criteria | the SPEC's Observability § product-metric table — and the `/readout` date |
| journeys — Agent autonomy matrix | `definitions/harness.md` (`pick-harness-shape`) |
| journeys — External channels & touchpoints / new agent tools | `definitions/mcp-servers.md` (`design-mcp-server`, if the tool layer is MCP) |
| journeys — any journey's steps or branches | `definitions/mockups.html` (`/to-mockups`) — the panels for those steps |
| mockups — the visual identity | every other panel in `definitions/mockups.html` — they all inherit it, so an identity change re-renders the file |

**Termination:** any amended upstream artifact (`definitions/prd.md`, `definitions/journeys.md`, `definitions/mockups.md`, `definitions/harness.md`, `definitions/mcp-servers.md`, `definitions/runtime.md`) implies a `/to-spec` amend; a `/to-spec` amend implies `/to-issues`; `/to-issues` hands to `/run-wave`. The cascade ends at `/to-issues` — the executable unit, and the last place a stale issue can be caught. A change confined to one section travels one edge, not the whole graph.

**Mid-graph edge:** an amended `definitions/harness.md` whose Topology (trigger classes), Gates (waits), Security (residency, sandbox posture), or Substrate sections changed implicates `definitions/runtime.md` — the placement profile, when one exists (written at `pick-harness-shape`'s placement gate). Service-level vendor picks are sections of `definitions/infrastructure.md` (via `/to-infrastructure`) and sit outside this cascade; their revisit triggers are swept by `/clean-house` instead.

This is also the path a production-learning loop takes: brief 07's optimizer amends `definitions/harness.md` directly → cascades to `/to-spec` → `/to-issues`. Same machinery, different trigger.

## What does not change

Every execution and read-only skill already reads the artifact by filename and keeps working untouched: `/to-issues`, `/run-wave`, `/to-spec` (reading upstream), `/review-pr`, `/audit-drift`, `/readout`, `test-driven-dev`, `judge-idea`. Amend mode is purely an *authoring* convention — it changes how a document is edited, never how it is read. That is why it is low-risk.
