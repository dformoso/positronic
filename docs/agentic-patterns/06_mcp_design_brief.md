# Frontier: MCP Server Design — Brief

**Scope.** Designing an MCP (Model Context Protocol) server that agents can consume reliably. Distinct from the agent harness (covered in brief 01) and from MCP clients themselves. Grounded in a 2026 cross-cut of five popular agent frameworks consuming MCP: mastra (TS, 24K★), langgraph + langchain-mcp-adapters (Py, 32K★), pydantic-ai (Py, 17K★), mcp-use (Py, 10K★), mcp-agent (Py, 8K★).

## State of the frontier

Three things crystallized by mid-2026:

1. **The schema is the contract — no client will validate args for you.** Even the type-safety-first framework (pydantic-ai) hard-wires a permissive `dict[str, any]` validator (`mcp.py:342`) because stable Python types can't be built from arbitrary remote JSON Schema. mcp-agent, langgraph, mastra all forward `inputSchema` to the model unchanged. **An MCP server is a public API, not an internal tool.** This single observation reframes every downstream decision.
2. **Clients differ on stateful vs. stateless consumption.** langchain-mcp-adapters dropped persistent sessions in 0.1.0 — `__aenter__` raises `NotImplementedError` (`client.py:33-42`); every tool invocation opens a fresh session. For stdio that means a subprocess spawn per call. mcp-agent and mastra keep long-lived sessions. Servers can't assume either pattern — fast cold-start is now table stakes.
3. **The official MCP conformance suite is a usable CI artifact.** mcp-use shells out to `npx @modelcontextprotocol/conformance` on every CI run (`tests/integration/test_conformance.py:74-138`) as both server and client. Running it against your own server is the cheapest way to catch protocol drift.

## Ranked techniques (by impact / adoption / evidence)

| Rank | Technique | Why it matters | Confirmed by |
|---|---|---|---|
| 1 | **Clean `inputSchema`** — single-type fields, `description`, `enum`, `pattern`; avoid `oneOf`/`anyOf` discriminators | The schema *is* the contract; clients forward it to the model unchanged | All 5 |
| 2 | **`[a-z0-9_]+` tool names; never embed the server name** | Clients namespace as `${server}_${tool}` with underscores; embedded server names alias silently | 4 of 5 |
| 3 | **Declare capabilities truthfully in `initialize`** | Under-declare → silent skip; over-declare → silent empty list | 4 of 5 |
| 4 | **`isError: true` + `TextContent`, not exceptions** | Exceptions fall through to generic formatters and lose structure | 3 of 5 |
| 5 | **Validate every schema at server startup** | One bad schema can zero out `tools/list` for the whole server | mastra |
| 6 | **Publish `outputSchema`; emit `structuredContent` consistently** | Lets agents chain tools; inconsistent inclusion surfaces as different shapes for the same tool | 4 of 5 |
| 7 | **Emit `tools/list_changed` and `resources/list_changed`** | Clients cache by default; without notifications, mutations require restart | 4 of 5 |
| 8 | **stdio: stdout = JSON-RPC only; stderr = diagnostics** | mcp-agent ships a 130-line `filtered_stdio_client` module to clean up after misbehaving servers | 3 of 5 explicit |
| 9 | **Fast cold-start** | Stateless clients spawn a subprocess per call | langgraph |
| 10 | **Publish `.well-known/oauth-protected-resource`; PKCE S256; DCR or CIMD** | Without metadata discovery, every user hand-configures OAuth | 3 of 5 |
| 11 | **Honor `Mcp-Session-Id` on both sides** | If you hand back a session id at init but don't accept it on subsequent calls (or vice versa), persistent connections silently break | mcp-agent |
| 12 | **Honor `nextCursor` pagination** | Identical, infinite, or empty-with-cursor pages brick discovery | 2 of 5 |
| 13 | **Emit annotations: `readOnlyHint`, `idempotentHint`, `destructiveHint`, `openWorldHint`** | Annotations drive client security policy; omitting them gets the spec's worst-case defaults | mastra, langgraph |

## Key tradeoffs

| Choice | Pro | Con |
|---|---|---|
| **stdio transport** | Simple to ship; zero infra | Per-call subprocess spawn under stateless clients; stdout discipline required |
| **Streamable HTTP transport** | Long-lived sessions; connection reuse; SSE-compatible | Real HTTP infrastructure; session-id contract; OAuth metadata expected |
| **SSE-only HTTP** | Simpler than full Streamable HTTP | Clients try Streamable first and fall back only on 400/404/405; end your URL with `/sse` to skip the probe |
| **Single broad tool with many params** | Fewer tools to discover | Big schema, ambiguous selection, fragile model arg-generation |
| **Many narrow tools** | Sharp selection, clean schemas, easy to gate via annotations | Surface bloats; namespace collisions if names aren't disciplined |
| **Permissive `inputSchema` (loose types, missing constraints)** | Quick to ship | Burden shifts to the model and the server; clients won't catch drift |
| **Strict `inputSchema` (`enum`, `pattern`, `description`)** | Server-side validation cheap; better model arg-generation | More upfront design |
| **Exceptions on tool failure** | Conventional in most languages | Adapter wrappers lose structure; clients log generic errors |
| **`isError: true` + `TextContent`** | Survives every client; structured downstream | Servers must catch and wrap; adds boilerplate |
| **`structuredContent` always (when `outputSchema` declared)** | Predictable shape for downstream nodes | Servers must serialize twice (text + structured) |
| **Server `instructions`** | Spec-supported usage guidance | pydantic-ai's `include_instructions` defaults `False` — most clients ignore it. Load-bearing info belongs in tool descriptions |
| **Templated resources** | Native spec primitive | langgraph's `client.get_resources()` skips them — invisible to default discovery. Expose as tools if discoverability matters |
| **Persistent session pool (server-side)** | Cheap repeat calls | Stateless clients won't use it; cold-start still pays the bill |

## Open questions on the frontier

- **Code-mode consumption.** mcp-use's `CodeModeConnector` exposes only `execute_code` + `search_tools`, then runs LLM-authored Python where each MCP server is an attribute namespace (`code_executor.py:19-106`). If this pattern proliferates, server naming and idempotency get *more* load-bearing, not less. How should servers anticipate being consumed as Python modules?
- **Schema validation gap.** Type-safe clients can't enforce. Servers can. But every server reimplements validation. Is there a shared validator middleware emerging?
- **Embedding-based tool selection.** mcp-use's server-manager mode picks tools via fastembed cosine similarity over `f"{tool.name}: {tool.description}"`. Tool descriptions are no longer prose for humans; they're embedding targets. Style guides for description-as-embedding don't exist yet.
- **Annotations as policy primitives.** `readOnlyHint` and `destructiveHint` drive client security gating (mastra's `requireToolApproval`). They're not yet a stable interop contract — different clients gate on different combinations.
- **Per-call subprocess cost.** langgraph's stateless model is bracingly clean but trades repeated cold-start for connection-pool complexity. The right server posture isn't settled.

## Bottom line

If you're building an MCP server today:

1. Treat `inputSchema` and `outputSchema` as your public API contract. Single-type fields, `description`, `enum`, `pattern`. Validate every schema at server startup.
2. Tool names match `[a-z0-9_]+`; verb_noun ordering; never embed the server name.
3. Capability advertisement matches reality. Use `ErrorCode.MethodNotFound` for "not supported" — clients only recognise that one.
4. Tool failures wrap in `CallToolResult(isError=True, content=[TextContent(...)])`. No throwing.
5. If your runtime has state changes (new tools, resources), emit `list_changed` notifications. Don't expect agents to poll.
6. stdio: stdout is JSON-RPC only. Diagnostics to stderr.
7. HTTP: support Streamable HTTP. Publish `.well-known/oauth-protected-resource`. PKCE S256.
8. Always emit `readOnlyHint`, `idempotentHint`, `destructiveHint`, `openWorldHint` annotations.
9. Run the official conformance suite (`npx @modelcontextprotocol/conformance`) on every CI run.

If you're optimizing for the next 12 months: invest in `structuredContent` + `outputSchema` everywhere, and watch the code-mode consumption pattern — the gap between "server I wrote" and "Python module the LLM imports" is closing.
