---
name: generate-test-assets
description: Generate multimodal test fixtures (image, audio, video, text) with Gemini into test-assets/, so automated tests exercise real-shaped inputs instead of hand-stubbed blobs. Invoked by test-driven-dev when a slice's test needs a fixture it can assert on in code. Use when a test needs an image to classify, audio to transcribe, video to analyze, or a corpus to parse. Routes load-bearing and user-dependent verification to the human instead of fabricating it.
---

# Generate test assets

Manufacture the *input* side of a test — a real-shaped image, audio clip, video, or text corpus — so the test drives the production path instead of a planted blob. Gemini is the engine. Assets land in `test-assets/`, reproducible from a committed manifest.

This skill generates **stimuli, never verdicts.** Anything load-bearing or user-dependent is routed to the human, not fabricated. See "The line" below.

You write the generator in the target project's own language (Python, TypeScript, Go) — there is no shipped library. These instructions are the contract; pin the live model IDs and call shapes from the Gemini docs as you write it.

## Work from the locked fidelity pick

The SPEC's "Verification fidelity" section sets the **Data** axis rung. Generated fixtures are the faithful stand-in at the `fixtures` rung — read the rung and any per-dependency overrides, and generate only up to it. If the axis says `anonymized sample` or `prod data`, generation does **not** satisfy it: stop and route to the human (real data is theirs to provide).

Pre-spec fallback: no SPEC → default to the `fixtures` rung. Generate stand-ins, and flag any test whose realism is itself load-bearing.

## The line — generate vs. route to the human

| Generate (afk) | Route to the human (hitl) |
|---|---|
| Stimulus for a code-checkable oracle — image to OCR, audio to transcribe, video to scene-detect, corpus to parse — where the assertion is a regex / schema / field / threshold | The verdict itself — "does this look / sound right", "is this output natural", any subjective quality call |
| A wrong-but-plausible fixture still fails the test correctly | A real user journey — real browser, real device, real human acceptance (the CUJ axis, AGENTS.md §7 and the Web-UI stack rule) |
| Distribution doesn't have to be representative to exercise the path | Realism or privacy is load-bearing and the SPEC marked the data `anonymized sample` / `prod data` |
| System-under-test is provider-neutral | The product *is* a Gemini wrapper — don't let the generator grade its own model family (circularity) |

The split mirrors the issue tags: a fixture an `afk` slice asserts on → generate; anything an `hitl` slice owns → hand off. When in doubt, route to the human.

## What to generate, with which model

| Modality | Use it for | Gemini surface |
|---|---|---|
| Image | OCR, classify, detect, layout | Imagen |
| Video | scene / object / action over time | Veo |
| Speech audio | transcribe, diarize, wake-word | Gemini TTS |
| Text / structured | parse, extract, classify | Gemini (text) |

Pin the current model ID from <https://ai.google.dev/gemini-api/docs> **before calling** — IDs drift, and inventing one violates AGENTS.md §2. Don't invent endpoints or response shapes; read the docs or an SDK example first.

## test-assets/ layout

```text
test-assets/
  manifest.json    # source of truth: id, modality, prompt, seed, model, sha256, hitl
  images/  audio/  text/    # committed — small and deterministic
  video/                    # gitignored — regenerated from the manifest on demand
```

`manifest.json` plus the small assets (images, audio, text) are committed and reviewable. Video and anything large stay out of git — add `test-assets/video/` (and any oversized path) to the **target project's** `.gitignore`, and regenerate them from the manifest when missing. The manifest is the source of truth; an asset is valid only if its bytes hash to the `sha256` recorded for it.

## Generating

1. Read the slice's test plan; list the fixtures it needs.
2. For each, check the manifest — present and the file's hash matches → reuse, don't re-bill Gemini. Missing or stale → regenerate.
3. Generate with the pinned model; write the asset and its manifest row (use a deterministic seed where the API supports one, so the asset is reproducible).
4. Map Gemini failures to one actionable line — no key → "set GEMINI_API_KEY"; quota → "Gemini quota exhausted, retry or raise quota"; safety block → name what was blocked. Don't leak the raw provider error or stack trace (AGENTS.md §7).
5. Read the key from `GEMINI_API_KEY`. Never commit it, never log it (AGENTS.md §8).

Tests that consume these assets follow the same rule as any external-dependency test: skip on environmental failure (no key, quota), fail only on a real code regression (see `../test-driven-dev/tests.md`).

## Hand-off

When you route something to the human, emit a short checklist of exactly what they must verify and how — so a load-bearing test is never silently dropped. These are the `hitl` slices; the fixtures you generated are what let the `afk` slices run unattended.
