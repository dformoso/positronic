# Amend mode — evolving an artifact after the first cut

positronic keeps one document per artifact type, flat in `definitions/`, each named for what it holds:

| File | Written by |
|---|---|
| `definitions/research.md` | `/research-market` |
| `definitions/ideas.md` | `/ideate` |
| `definitions/prd.md` | `/to-prd` |
| `definitions/surfaces.md` | `pick-ui-surfaces` |
| `definitions/harness.md` | `pick-harness-shape` |
| `definitions/mcp-servers.md` | `design-mcp-server` (one section per server) |
| `definitions/runtime.md` | `pick-harness-shape`, at the placement gate |
| `definitions/spec.md` | `/to-spec` |

Each one is a **whole-product** document that every consumer reads by name. There are no subdirectories, no timestamps, and no second copy — the file *is* the current truth, and git holds every version it used to be.

That leaves one trap. When a feature lands after the first cut, the tempting move is to regenerate the file around the new feature — and everything the product already did, which the change never touched, quietly disappears. Amend mode is the discipline that prevents it: read the file as **baseline**, change only the delta, leave the rest byte-for-byte alone. The product stays whole, the work stays incremental, and `git log -p definitions/prd.md` is the changelog.

## When it applies

| Situation | Path |
|---|---|
| Typo / bug, no behaviour-contract change | `diagnose` — no artifact change |
| A settled decision or tradeoff, no scope change | ADR (`docs/adr/`) — existing |
| A scoped change: new, changed, or dropped capability | **Amend** the implicated artifact(s) |
| A pivot — the product is now a different product | Rewrite the file from scratch, **no** Amendment header |

**Pivot test (sharp line):** if the change rewrites the PRD's **Target User** or **Problem Statement**, it's a pivot — start fresh. Amend only while those two anchors hold; everything downstream is negotiable, those two are the product's identity.

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
- **Change:** Add seat-based team workspaces so a buyer can invite members — closes the top churn risk.
- **Sections touched:** Solution Overview; Functional Requirements (Data model, Agent autonomy)
- **Carried forward unchanged:** all others
```

**This header is the increment's record** — it plays the role `define`'s hypothesis frame plays for greenfield. There is no separate change-request artifact.

It describes the **latest** amendment only, and each amend replaces it. Earlier ones aren't lost: `git log -p definitions/prd.md` walks the whole chain, each entry carrying the header that was current at the time. A document written from scratch — greenfield or pivot — has no header until its first amend.

## The cascade rule

What stops "rewrite five artifacts per feature." An amended artifact forces a downstream amend **only** where a touched section feeds it. The amending skill names the implicated artifacts and prompts only those:

| Touched in the PRD | Implicates |
|---|---|
| Agent autonomy matrix / autonomy contract / multi-agent decomposition | `definitions/harness.md` (`pick-harness-shape`) |
| Solution Overview surfaces / form factor | `definitions/surfaces.md` (`pick-ui-surfaces`) |
| External channels & touchpoints / new agent tools | `definitions/mcp-servers.md` (`design-mcp-server`, if the tool layer is MCP) |

**Termination:** any amended upstream artifact (`definitions/prd.md`, `definitions/surfaces.md`, `definitions/harness.md`, `definitions/mcp-servers.md`, `definitions/runtime.md`) implies a `/to-spec` amend; a `/to-spec` amend implies `/to-issues`. The cascade ends at `/to-issues` — the executable unit. A change confined to one section travels one edge, not the whole graph.

**Mid-graph edge:** an amended `definitions/harness.md` whose Topology (trigger classes), Gates (waits), Security (residency, sandbox posture), or Substrate sections changed implicates `definitions/runtime.md` — the placement profile, when one exists (written at `pick-harness-shape`'s placement gate). Service-level vendor picks are ADRs (`docs/adr/`, via `pick-cloud-services`) and sit outside this cascade; their revisit triggers are swept by `/clean-house` instead.

This is also the path a production-learning loop takes: brief 07's optimizer amends `definitions/harness.md` directly → cascades to `/to-spec` → `/to-issues`. Same machinery, different trigger.

## What does not change

Every execution and read-only skill already reads the artifact by filename and keeps working untouched: `/to-issues`, `/to-spec` (reading upstream), `/review-pr`, `/audit-drift`, `test-driven-dev`, `judge-idea`. Amend mode is purely an *authoring* convention — it changes how a document is edited, never how it is read. That is why it is low-risk.
