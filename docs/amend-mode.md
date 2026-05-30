# Amend mode — evolving an artifact after the first cut

positronic's artifacts (`prds/`, `surfaces/`, `harness/`, `mcp-servers/`, `specs/`) are immutable, timestamped, **whole-product** snapshots; every consumer reads the latest via `ls <dir>/[0-9]*.md | sort | tail -1`. Right for the first build, wrong for the trilemma it forces after:

- rewrite the whole product per feature → huge diffs, drift, near-duplicate snapshots;
- write a feature-scoped snapshot → `tail -1` truncates the product to its newest slice;
- skip the pipeline → the artifacts rot into fiction.

Amend mode is the third way. Read the latest snapshot as **baseline**, change only the delta, write a **new complete snapshot**. The product stays whole, the work stays incremental, and `git diff <parent> <new>` is the changelog. **No new directories, and no change to any consumer** — `tail -1` still returns the whole current truth.

## When it applies

| Situation | Path |
|---|---|
| Typo / bug, no behaviour-contract change | `diagnose` — no artifact change |
| A settled decision or tradeoff, no scope change | ADR (`docs/adr/`) — existing |
| A scoped change: new, changed, or dropped capability | **Amend** the implicated artifact(s) |
| A pivot — the product is now a different product | New from-scratch snapshot, **no** Amendment header |

**Pivot test (sharp line):** if the change rewrites the PRD's **Target User** or **Problem Statement**, it's a pivot — start fresh. Amend only while those two anchors hold; everything downstream is negotiable, those two are the product's identity.

## The protocol

1. **Read the baseline** — the latest snapshot of *this* artifact type (`tail -1` of its dir).
2. **Read the change intent** — the increment's scope, from `define`'s increment frame or the conversation.
3. **Scope the delta** — name exactly which template sections the change touches.
4. **Carry forward verbatim** — copy untouched sections byte-for-byte. **Do not re-derive or "improve" them** — re-deriving an untouched section silently rewrites a locked decision (AGENTS.md §3, at the artifact level). **One exception:** if the delta *contradicts* an untouched section — a new feature that was a prior Non-Goal, a constraint the change breaks — that section is now in-scope. Reconcile it; never ship a snapshot that contradicts itself.
5. **Write a new complete snapshot** — new timestamp, whole-product, Amendment header on top.
6. **The diff is the changelog** — `git diff <parent> <new>`. No separate changelog file.

## The Amendment header

Directly under the artifact's title, so every snapshot is self-describing about its delta:

```
## Amendment
- **Increment:** team-workspaces                    (optional human label — walk the chain without diffing)
- **Amends:** prds/2026-03-01-09-12-44.md           (immediate parent snapshot)
- **Change:** Add seat-based team workspaces so a buyer can invite members — closes the top churn risk.
- **Sections touched:** Solution Overview; Functional Requirements (Data model, Agent autonomy)
- **Carried forward unchanged:** all others
```

**This header is the increment's record** — it plays the role `define`'s hypothesis frame plays for greenfield. There is no separate change-request artifact; the chain of `Amends:` pointers *is* the product's evolution history. A from-scratch snapshot (greenfield or pivot) omits the header.

## The cascade rule

What stops "rewrite five artifacts per feature." An amended artifact forces a downstream amend **only** where a touched section feeds it. The amending skill names the implicated artifacts and prompts only those:

| Touched in the PRD | Implicates |
|---|---|
| Agent autonomy matrix / autonomy contract / multi-agent decomposition | `harness/` (`pick-harness-shape`) |
| Solution Overview surfaces / form factor | `surfaces/` (`pick-ui-surfaces`) |
| External channels & touchpoints / new agent tools | `mcp-servers/` (`design-mcp-server`, if the tool layer is MCP) |

**Termination:** any amended upstream artifact (`prds/`, `surfaces/`, `harness/`, `mcp-servers/`) implies a `/to-spec` amend; a `/to-spec` amend implies `/to-issues`. The cascade ends at `/to-issues` — the executable unit. A change confined to one section travels one edge, not the whole graph.

This is also the path a production-learning loop takes: brief 07's optimizer amends `harness/` directly → cascades to `/to-spec` → `/to-issues`. Same machinery, different trigger.

## What does not change

Every execution and read-only skill already reads `tail -1` and keeps working untouched: `/to-issues`, `/to-spec` (reading upstream), `/run-afk-in-loop`, `/review-pr`, `/audit-drift`, `test-driven-dev`, `judge-idea`. Amend mode is purely an *authoring* convention — it changes how snapshots are written, never how they are read. That is why it is low-risk.
