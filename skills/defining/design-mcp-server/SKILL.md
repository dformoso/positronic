---
name: design-mcp-server
description: Walk the design decisions for a new MCP (Model Context Protocol) server before any code is written. Covers transport, auth, tool-surface shape, schema discipline, state model, capability declaration, error model, annotations, and testing. Use when the user is designing an MCP server — not consuming one.
disable-model-invocation: true
---

You are picking the design for a new MCP server. The schema is the contract — no client will validate args for you. Pick deliberately.

Reference: `docs/agentic-patterns/06_mcp_design_brief.md` carries the empirical foundation, cross-cut from 5 popular agent frameworks (mastra, langgraph, pydantic-ai, mcp-use, mcp-agent). Cite ranked techniques as you make recommendations.

Ask one question at a time. Surface your recommended answer with each.

## 1. Confirm MCP is the right surface

Pick MCP when at least one applies:

- You want **multiple agent frameworks** to consume the same tools without per-framework adapters.
- You need an **out-of-process** capability (separate runtime, language, security boundary).
- You want to ship the server **as a product** that other teams or external users consume.

If none apply, a custom tool inside the agent's process (LangChain `BaseTool`, FastMCP-in-process, plain function) is cheaper and faster. Surface this and let the user decide before going deeper. If they confirm MCP is wanted, continue.

## 2. Transport

| Transport | Use when |
|---|---|
| **stdio** | Local-only consumer; no infra; tools run on the same machine as the agent. Cheapest to ship. |
| **Streamable HTTP** | Remote consumers; need session reuse, OAuth, multi-tenant. Default for hosted servers. |
| **SSE-only HTTP** | Legacy clients; one-way streams. End the URL with `/sse` so clients skip the Streamable probe (mastra `client.ts:409`). |
| **WebSocket** | Rare. Some clients support it (mcp-use); most don't. Avoid unless you have a specific reason. |

Default to **stdio for local tools, Streamable HTTP for everything else**. Both can coexist — many servers expose both.

For stdio: stdout is JSON-RPC only. Diagnostics go to stderr. mcp-agent ships a whole `filtered_stdio_client` module to filter setup chatter from misbehaving servers — don't be that server.

For HTTP: support Streamable HTTP if you support HTTP. Fail Streamable setup with `400`, `404`, or `405` so clients fall back to SSE — anything else throws with no fallback (mastra `client.ts:80, 432`).

## 3. Auth

| Option | Use when |
|---|---|
| **None** | Local stdio; trust boundary is the OS user. |
| **Static bearer token** | Internal HTTP server; same trust boundary as the network. |
| **OAuth 2.1 (PKCE, DCR/CIMD)** | Multi-tenant; user-scoped access; external consumers. |

If OAuth: publish `/.well-known/oauth-protected-resource`. Use `WWW-Authenticate: Bearer resource_metadata=...` on 401. Support either Dynamic Client Registration (RFC 7591) or Client ID Metadata Documents — clients prefer CIMD when both are advertised (mcp-use `oauth.py:316-353`). PKCE S256 is non-negotiable.

Without metadata discovery, every consumer hand-configures `authorization_server`, `scopes`, and `client_id` — and mcp-use silently disables OAuth on discovery failure (`http.py:152-156`), then 401s.

## 4. Tool surface

Five well-designed tools beat fifty. Decide:

- **Rough count and boundaries.** Each tool maps to a single user-meaningful action.
- **Naming.** `[a-z0-9_]+`. Verb_noun ordering (`pull_request_create`, not `create`). Never embed the server name (clients namespace as `${server}_${tool}` — a tool named `weather_today` inside the `weather` server becomes `weather_weather_today`).
- **Description.** Treat as embedding target, not boilerplate. mcp-use's server-manager mode picks tools via cosine similarity over `f"{tool.name}: {tool.description}"`. "Use this tool to do X" matches further from "github pull request" than "Get GitHub pull request details".

For each tool:

| Decision | Default |
|---|---|
| `inputSchema` | Single-type fields. `description` on every property. `enum`/`pattern` where the domain is finite. Avoid `oneOf`/`anyOf` discriminators (confuses model arg-generation). |
| `outputSchema` | Publish it. Lets agents chain tools; pydantic-ai forwards as `return_schema` (`mcp.py:748`). |
| Return shape | Emit `structuredContent` *consistently* — always when `outputSchema` declared, or never. mastra returns `structuredContent` if present and the full envelope otherwise; inconsistency surfaces as different shapes for the same tool (`client.ts:847`). |
| `annotations` | Always set `readOnlyHint`, `idempotentHint`, `destructiveHint`, `openWorldHint`. Drives client security policy (mastra `requireToolApproval`). Omit and you get the spec's worst-case defaults. |
| Failure mode | `CallToolResult(isError=True, content=[TextContent(...)])`. Don't throw — clients log generic errors and lose structure. |

**Validate every schema at server startup.** mastra's per-server `try/catch` zeros out every tool if `tools/list` rejects (`configuration.ts:767`). One bad schema kills the whole server.

## 5. Resources, prompts, and other primitives

| Primitive | Default |
|---|---|
| **Tools** | Always. The lingua franca; every framework consumes them. |
| **Resources** | Yes if your data is read-only and URI-addressable. Skip if everything is a tool with a return value. |
| **Resource templates** | Only if you also expose them as tools — langgraph's `client.get_resources()` skips templated resources (`resources.py:70`), so they're invisible to default discovery. |
| **Prompts** | Skip unless a specific consumer asks. pydantic-ai never calls `prompts/list`. Other clients vary. |
| **Sampling** | Only if your server genuinely needs the agent's model to make a sub-call. Always populate `modelPreferences` — mcp-agent's local handler raises if you don't (`sampling_handler.py:207`). |
| **Server `instructions`** | Skip as the primary docs surface. pydantic-ai's `include_instructions` defaults `False` — most clients ignore it. Load-bearing usage guidance belongs in tool descriptions. |

## 6. State and lifecycle

| Pattern | Use when |
|---|---|
| **Stateless** | Each tool call is independent. Recommended default — survives langgraph's per-call session model (`client.py:33-42`). |
| **Per-session state** (Streamable HTTP) | You need cross-call context (auth handshake, partial uploads, multi-turn flows). Honor `Mcp-Session-Id` on both sides — hand back at init *and* accept on every subsequent call. |
| **Persistent stdio process** | Long-running model, DB connection, file watcher. Document per-call latency for stateless consumers. |

Constraints regardless:

- **Fast cold-start.** Lazy-init heavy resources at first request, not at process start.
- **Graceful shutdown under SIGTERM.** pydantic-ai bounds shutdown at 3 seconds (`mcp.py:356`) — slower servers get force-cancelled mid-flight.
- **Emit `tools/list_changed` and `resources/list_changed`** when your surface mutates. Clients cache by default; without notifications, mutations require restart.

## 7. Capability declaration

Advertise in `initialize` only what you actually implement. Under-declare and clients skip discovery silently (mcp-agent gates every list call on declared capabilities — `mcp_aggregator.py:1259`). Over-declare and clients 404 to empty list — also silent.

For "not supported", return `ErrorCode.MethodNotFound` and nothing else. mastra short-circuits resource/prompt `list()` to `[]` only on `MethodNotFound` (`actions/resource.ts:58`). Any other code logs and skips — degraded UX.

Honor `nextCursor`. Identical, infinite, or empty-with-cursor pages brick discovery — langgraph bails with `RuntimeError` after 1000 iterations (`tools.py:67`).

## 8. Testing strategy

The default — confirm with the user once you've drafted it:

1. **Conformance suite in CI.** Shell out to `npx @modelcontextprotocol/conformance server --url ...` on every push. mcp-use does this (`tests/integration/test_conformance.py:74`). Cheapest protocol-drift catch.
2. **Real-server integration tests, not mocks.** Spawn the server as a subprocess (stdio) or in-process (HTTP). pydantic-ai, langgraph, mcp-use, mastra all do this. mcp-agent mocks at the `ClientSession` boundary and pays for it.
3. **Pathological-schema fixture.** mastra ships a 1013-line `fire-crawl-complex-schema.ts` fixture that exercises edge-case schemas (`configuration.e2e.test.ts:645`). One per known-tricky tool.
4. **Fault-isolation test.** Spawn one broken server alongside healthy ones; assert healthy ones still serve (mastra `:917-988`).
5. **Startup schema validation.** Fail loudly on boot if any tool's `inputSchema` is malformed. Catches drift before clients see it.

See `skills/implementing/test-driven-dev/mcp-testing.md` for code patterns.

## 9. Observability

| Surface | Default |
|---|---|
| **Logs** | Structured JSON to stderr (stdio) or stdout (HTTP). Tag each line with `tool`, `session_id`, `request_id`. Never log credentials, PII, or auth headers (AGENTS.md §8). |
| **`_meta` on responses** | Include `request_id`, timing, and any trace-context. langgraph carries `_meta` into LangChain `metadata` (`tools.py:416`); surfaces to LangSmith automatically. |
| **`logging/setLevel` handler** | If your server emits internal logs at runtime, accept the spec's `setLevel` so clients can throttle. |
| **Error message text** | Make reconnect-able. mastra's `isReconnectableMCPError` is a substring match on `error.message.toLowerCase()` for `'session'`, `'not connected'`, etc. (`error-utils.ts`). JSON-RPC codes with no recognisable text never trigger retry. |

## 10. Hand-off

Summarise the picked shape: transport, auth, tool surface (count + naming convention), other primitives, state model, capability set, error model, annotation policy, testing strategy. Then prompt the user to run `/to-prd` (if not yet done) and `/to-spec`. The SPEC's `Tool layer / ACI` section is where this lands as a versioned contract.
