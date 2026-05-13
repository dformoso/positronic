# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## Production-Path Coverage

**Tests must exercise the same call shape production uses.** The most expensive bug is a green suite hiding a broken codepath because the test set up state via a shortcut that production never takes.

Smell: your test sets up state with a constructor / private helper / direct file write, when production gets to the same state via `add_record(...)` / a REST call / a real upload. If the production path adds something the shortcut doesn't (a metadata sidecar, a side-effecting hook, a default value), your test cannot catch a regression in that something.

```python
# BAD: planted state, easy to forget what production actually produces
def test_finalize_clean():
    uploads = tmp_path / "uploads"
    uploads.mkdir()
    (uploads / "rogue").write_text("orphan")  # bare file, no .md sidecar
    finalize_views(uploads_dir=uploads, ...)  # check passes for the wrong reason

# GOOD: state built the way production builds it
def test_finalize_clean():
    store.add_upload(content=b"%PDF...", filename="x.pdf", mimetype="application/pdf")
    finalize_views(uploads_dir=store.uploads_dir, ...)
```

Rule: if your test setup doesn't go through the same factory / builder / public method production uses, you have a coverage hole. Use the real entry point unless you have a stated reason not to.

## Stash-and-Fail Before Fix

When you write a regression test for a bug, **stash the fix and run the test alone**. Confirm it fails with the production error message, not just any error.

```bash
git stash push -- path/to/the/fix.py
pytest path/to/the/new_test.py -x
# read the failure. is it the actual production symptom?
git stash pop
```

A test that passes for the wrong reason is worse than no test — it gives false confidence the bug is locked down when it isn't. If the stashed-fix run fails with a different error than what the user reported, your test is exercising the wrong path; rewrite it.

## External Dependencies Need Failure-Mode Tests

Every external call your code makes (LLM, HTTP, DB, filesystem, subprocess) has a failure mode the user can hit. For each, write a test that simulates the failure and asserts the user-facing surface is **actionable**, not a stack trace.

```python
def test_llm_credit_exhausted_surfaces_friendly_message():
    raw = (
        'litellm.BadRequestError: AnthropicException - '
        '{"error":{"message":"Your credit balance is too low..."}}'
    )
    msg = friendly_llm_error(RuntimeError(raw), model_name="claude")
    assert "credit" in msg.lower()
    assert "Settings" in msg
    assert "AnthropicException" not in msg  # raw exception class doesn't leak
```

Pin the test against the **actual exception text you observed in production**. That way, when a provider changes its error format, the test fails before the user does.

## Skip on Environmental Failure, Fail on Code Regression

Tests that hit a paid API, network service, or OS-level resource must distinguish "environment unavailable" (skip) from "code under test produces wrong output" (fail). Otherwise the suite is noise the moment your account expires.

```python
for err in result.errors:
    blob = " ".join(str(v) for v in err.values()).lower()
    if "credit balance" in blob or "rate limit" in blob or "invalid_api_key" in blob:
        pytest.skip(f"environment unavailable: {err['error']}")
```

A test that fails on credit exhaustion teaches the team to ignore failures; the next real regression hides in the noise.
