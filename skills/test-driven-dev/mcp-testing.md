# Testing MCP servers

The same red-green-refactor loop applies, but the seams are unusual. Five rules — derived from how five popular clients actually test their MCP integration.

## 1. Don't mock the protocol; spawn a real server

The wrong seam is the `ClientSession` boundary. Mocking there hides every protocol bug.

The right seam is a real server, spawned as a subprocess (stdio) or in-process (HTTP). pydantic-ai, langgraph, mcp-use, and mastra all do this; mcp-agent mocks and pays for it.

For a Python server using FastMCP:

```python
# tests/fixtures/test_server.py
from mcp.server.fastmcp import FastMCP

server = FastMCP("test-server")

@server.tool()
def add(a: int, b: int) -> int:
    return a + b

if __name__ == "__main__":
    server.run()
```

For stdio, spawn it:

```python
# tests/test_my_server.py
from mcp.client.stdio import stdio_client, StdioServerParameters

async with stdio_client(StdioServerParameters(
    command="python", args=["-m", "tests.fixtures.test_server"]
)) as (read, write):
    async with ClientSession(read, write) as session:
        await session.initialize()
        result = await session.call_tool("add", {"a": 2, "b": 3})
        assert result.content[0].text == "5"
```

The assertion compares against `"5"` (string), not `5` (int): FastMCP wraps the return value as `TextContent`, so the wire format is always a string regardless of the declared return type. If you publish an `outputSchema`, also assert on `result.structuredContent` for the typed value.

For HTTP, run it in-process at a random localhost port (mastra's pattern, `client.test.ts` ~3000 lines).

## 2. Run the official conformance suite in CI

mcp-use's `tests/integration/test_conformance.py:74-138` shells out to:

```bash
npx @modelcontextprotocol/conformance server --url http://localhost:$PORT
npx @modelcontextprotocol/conformance client --command python -m my_server
```

Both directions, every CI run. This is the cheapest way to catch protocol drift — every tool/resource/prompt/error case the spec defines, against your real server.

Add it to the build as a single check that exits non-zero on any failure.

## 3. Validate every schema at server startup

mastra's per-server `try/catch` zeros out *every* tool if `tools/list` rejects. One bad `inputSchema` kills the whole server.

Add a startup test that walks every registered tool, calls `Draft7Validator.check_schema(tool.inputSchema)` (or your validator's equivalent), and fails loudly. Same for `outputSchema`.

```python
def test_all_tool_schemas_valid():
    from jsonschema import Draft7Validator
    for tool in server.list_tools():
        Draft7Validator.check_schema(tool.inputSchema)
        if tool.outputSchema:
            Draft7Validator.check_schema(tool.outputSchema)
```

This catches the most common production bug — a schema that's only ever exercised when an LLM calls it.

## 4. Fault-isolation: spawn one broken server next to healthy ones

mastra spawns one server with `command: 'nonexistent-binary-that-does-not-exist'` and asserts healthy servers still return tools (`configuration.e2e.test.ts:917-988`).

```python
async def test_broken_server_does_not_break_healthy_ones():
    client = MCPClient(servers={
        "healthy": {"command": "python", "args": ["-m", "tests.fixtures.test_server"]},
        "broken": {"command": "nonexistent-binary"},
    })
    tools = await client.list_tools()
    assert any(t.name.startswith("healthy_") for t in tools)
```

If your server is *consumed* in a multi-server context, write this test. Confirms one bad neighbor doesn't take down the room.

## 5. Pathological-schema fixture

Real schemas drift. mastra ships a 1013-line `fire-crawl-complex-schema.ts` fixture that exercises every edge case its team has hit: deeply nested `oneOf`, recursive references, mixed-type arrays, unconstrained `object`.

For each tool with a complex schema, add one focused test that builds an LLM-shaped argument dict and round-trips it through the server. Catches schema-vs-validator drift before a client does.

## What not to test

- **Don't test the client's behavior** (timeouts, retries, reconnect). The client is upstream; your tests should pin server behavior, not client behavior.
- **Don't snapshot the JSON-RPC wire format.** Snapshot the *result* of `call_tool` — the spec evolves; snapshots break for the wrong reason.
- **Don't test that capabilities you advertise actually work** via the protocol. Test the capability through its own interface (a real `read_resource` call) — protocol-level capability assertion is what the conformance suite is for.
