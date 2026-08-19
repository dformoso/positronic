---
name: audit-failure-modes
description: Pre-mortem of the system. Spawns parallel agents per failure surface (external deps, concurrency, persistence, resource, config, security, frontend, LLM/agent surface), buckets findings MECE, and ranks P0/P1/P2 with explicit framing. Reports only — never auto-fixes. Use before a release cut or when hardening a maturing system. User-invoked only — never activate autonomously; if it seems relevant, tell the user it exists and wait.
disable-model-invocation: true
---

Run only on explicit invocation — by name, slash/dollar command, or workflow stub. Otherwise stop: say this skill exists, and wait.

# Audit Failure Modes

Prospective diagnosis. Walk the system and list how it could break — before it does. Reports only — never auto-fixes. Mirrors `/review-pr`'s and `/audit-drift`'s posture.

Scope is the **whole system, read from code**. The one worth keeping straight is `/go-live`: it verifies runtime evidence no code-read can see — whether the secret is actually set, whether backups are actually retaining, whether an alert actually fires. Enumerate here; verify there.

## Process

### 1. Orient

Read the entry point and top-level layout. Identify the surfaces in play:

- **External boundaries** — HTTP/RPC calls, LLM providers, subprocesses, MCP servers, third-party SDKs
- **Concurrency surfaces** — background workers, async tasks, server lifecycle, cancellation paths
- **Persistence layer** — files on disk, databases, caches
- **Resource pressure points** — uploads, queues, log files, in-memory buffers
- **Config & startup** — env vars, secrets, health/readiness, container topology
- **Security surfaces** — file permissions, secret storage, user-facing error paths
- **Frontend** — only if there's a UI
- **LLM / agent surface** — only if model calls or an agent loop exist: prompt inputs, tool dispatch, spend paths

Skip categories with no surface.

### 2. Parallel exploration

For each surface present, dispatch one read-only explorer subagent with the matching category brief from §3. Agents run in parallel.

Each agent reads its assigned surface end-to-end and returns concrete failure modes with `file:line` citations. The agent's job is **enumerate, not rank** — ranking happens centrally in §4.

For small projects (one binary, no frontend, single store), do this serially in one pass instead.

### 3. Category briefs

#### A. External dependencies

For every external call (HTTP, RPC, LLM, subprocess):
- Timeout set? Retry with backoff?
- Streaming heartbeat for long calls?
- Response shape validated, or trusted blindly? (e.g. `response.choices[0]` with no `len(choices)` check)
- Error path produces a one-sentence actionable message, or silently `return []` / `return False`?
- LLM-specific: empty-choices, token-limit, content-filter — all handled?
- Subprocesses: SIGKILL cleanup? Hang detection?

#### B. Concurrency & lifecycle

- What persists `in_flight=True` across restarts? On boot, is it cleaned up?
- Cancellation: propagates to live HTTP/LLM/subprocess calls, or just flips a flag?
- Race conditions between submit / cancel / resubmit?
- Append-only logs replayed on conversational re-runs — duplicates?
- Parallel writes to the same record — last-write-wins?

#### C. Persistence & data integrity

- Every file write: atomic (tmp + fsync + rename), or raw `write_text` that corrupts on crash?
- Every file read: skip-and-warn on bad file, or crash the whole load?
- Multi-step writes (blob + metadata): transactional, or orphans possible?
- Schema version field on records and caches?
- `ENOSPC` caught anywhere?
- Re-ingest of the same input — dedupe?

#### D. Resource exhaustion

- Uploads / requests: streamed to disk, or buffered fully in memory?
- ZIP / archive expansion: capped?
- Aggregate disk quota on the data directory?
- Append-only logs rotated?
- Worker concurrency limit set?
- Process supervision — if one child dies, does the sibling die too?

#### E. Configuration & startup

- API keys validated at startup, or only on first user request (raw SDK trace)?
- `/health` vs `/ready` — does `/ready` actually probe the things the container needs?
- Default values that bypass security (e.g. `DISABLE_AUTH=1` in the Dockerfile)?
- Prodness declared, not inferred — and does a production boot **refuse** dev/test affordances by construction (a prod start with a dev-only flag set must fail loudly, not run with the flag live)?
- Proxy timeout vs backend timeout — proxy ≥ backend, or does it abandon live requests?
- Structured (JSON) logs, or unparseable line-based?

#### F. Security & data hygiene

- File modes for sensitive data — `0o600`, or world-readable?
- Secrets at rest — encrypted, or plaintext on disk?
- Stack traces from external SDKs reaching the UI before sanitization?
- Credentials / PII / auth headers ever logged?
- Regulated data has a retention/deletion path — every PII store reachable from the account-deletion flow, export before erase?
- Recordings / transcripts / message bodies purged on their stated schedule, or accreting forever?

#### G. Frontend resilience (UI only)

- Every fetch: timeout? `AbortController` on unmount / tab close?
- Every poller: stops when `document.hidden`? Backoff?
- Optimistic UI: rollback / toast on send failure?
- Page-level backend check: fires only at mount, or re-checks on focus?
- Global `ErrorBoundary` / `error.tsx`?
- Polling that depends on a monotonic ID — handled if backend logs roll over?

#### H. LLM & agent surface (only when model calls or an agent loop exist)

- **Prompt injection:** every channel where customer-controlled text reaches a prompt (messages, email bodies, voicemail transcripts, uploaded documents) — are tool calls acting on that text gated, or can injected instructions trigger actions?
- **Data-to-model flows:** what PII reaches a third-party model provider, under what retention terms, and where is the redaction point? Is the data-processor identity known per flow?
- **Spend:** per-account and global runaway caps present and enforced across events, not just per call? Any unmetered model call sites (paths that bypass the meter)?
- **Autonomy boundaries:** anything the agent can send or commit outward without human approval? A model-triggered action with irreversible or money side effects behind a single gate?
- **Kill switch:** one reversible lever that stops the agent surface without stopping the product?

### 4. Bucket and prioritize

Consolidate agent reports. Each failure mode lands in exactly one category. If something spans two, pick the dominant one and note the other in the description.

**Before proposing a handler, ask whether the failure can be removed instead.** Every fix
this skill reaches for is additive — a timeout, a retry, a check — and the cheapest failure
mode is the one that can't occur: make the bad state unrepresentable in the type, parse once
at the edge and carry the proof inward, or pick semantics where the case is a non-event.
When that's the answer, say so instead of specifying a handler, and route it to
`/improve-readability` (excess-machinery lens) rather than adding a guard here.

Rank each finding:

- **P0** — correctness, data-loss, privacy. Unambiguous must-fix before another user hits it.
- **P1** — reliability under realistic stress. Will bite under load or real production conditions.
- **P2** — polish, defense-in-depth. Worth doing when there's slack.

A finding without a clear tier is one you don't understand yet. Sharpen the framing or drop it.

### 5. Pushback

Surface findings that *look* like failure modes but are actually fine for this project's real usage profile. Examples: cross-record locking on a single-user local app; auto-dedup that would silently swallow legitimate re-uploads. Be concrete about *why* it's not worth fixing — cost-of-fix vs realistic blast radius.

If there's nothing to push back on, say so. Don't manufacture pushback.

### 6. First-PR bundle

Identify P0s that share scaffolding — typically a single helper introduced once, then reused across call sites (e.g. `_secure_write_text` covers atomic notebook + atomic cache + sensitive file mode in one go). Propose a single PR that ships them together. Optional; skip if no natural bundle exists.

### 7. Report

Print to chat. Match this format:

```text
## Categories audited
{list with surface notes}

## A. External dependencies
| # | Failure mode | Where |
|---|---|---|
| A1 | … | file:line |

{repeat per category present}

## Prioritized

### P0 (correctness / data-loss / privacy)
- {Axx, Bxx, …} — {one-sentence fix}

### P1 (reliability under realistic stress)
- {…}

### P2 (polish)
- {…}

## Pushback
- {finding} — {why it's not worth fixing yet}

## Suggested first PR
{bundle, or "no natural bundle"}
```

Do not summarize what the system does. The user can read the code.

### 8. Save (optional)

After printing, ask:

> Save the report to `docs/audits/YYYY-MM-DD-failure-modes.md`? (y/N)

**Write it in plain English** — short sentences, one idea each, concrete before abstract, every term of art glossed on first use. Someone who wasn't in this conversation has to follow it without asking (AGENTS.md §4).

Default no. Create `docs/audits/` lazily on first save.

## Out of scope

- **Auto-fix.** Mirrors `/review-pr` and `/audit-drift` — detection, not repair.
- **Test-coverage audit.** Different lens; absence of evidence, not a failure mode. A suite that stays green when the code breaks belongs to `/improve-readability` — see [`../improve-readability/TESTS.md`](../improve-readability/TESTS.md).
- **Performance regression hunting.** `diagnose` territory once a regression exists.
- **Doc-graph drift.** `/audit-drift`.
