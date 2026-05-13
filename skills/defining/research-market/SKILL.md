---
name: research-market
description: Run secondary research on customer pain and competitive landscape. Mines forums, articles, and reviews to produce a versioned research artifact in research/. Use when the user wants market evidence before ideating.
disable-model-invocation: true
---

Run secondary research over the problem space. Produce one document covering customer pain *and* competitive landscape — they share the same source pool, and the synthesis cuts across both anyway (pain × who-already-solves-it).

## Inputs

The problem space, segments, and pain hypotheses defined in `define` (in-context). If those aren't defined, prompt the user to run `define` first and stop.

## Process

1. **Estimate and confirm.** Print a one-line cost/runtime estimate based on the floor and ceiling below. Ask the user to confirm before fetching. This is long-running work that costs real money — surprise bills are bad. Order-of-magnitude guidance: ~10–30 min, ~$3–8.

2. **Build a source list.** Pick the 5 most relevant sources for this project type — places where the target users actually complain or compare tools (forums, review sites, app stores, domain-specific communities). Then **test each one** by attempting to fetch a sample page with `WebFetch` or `WebSearch`. If a source blocks scraping, requires login, or returns empty/captcha content, drop it and pick a replacement until 5 viable sources are in hand. The web is a moving target — encode the rule, not yesterday's site list.

   Final list should cover ≥3 distinct platforms or persona segments.

3. **Fetch loop.** Use `WebFetch` and `WebSearch`. Stop when **all three** gates fire:
   - **Floor.** ≥50 sources collected.
   - **Saturation.** Last 10 sources added no new themes.
   - **Diversity.** ≥3 distinct platforms or persona segments sampled.

   For non-deterministic content (forums), prefer recent + high-engagement threads. Save raw fetched content under `research/<run-id>/raw/<source>-<n>.txt` for reproducibility. **On first run, append `research/*/raw/` to `.gitignore`** — raw content is regenerable and carries ToS risk if redistributed.

4. **Synthesize.** Cluster observations into themes. For each theme, capture:
   - The pain itself (one sentence)
   - Direct quotes (≥2) with citation URLs
   - Approximate volume (low / medium / high based on what you saw)
   - Severity (annoyance / costly / blocker)
   - Who's affected (segment)

   For competitive landscape, capture:
   - Direct competitors (named, with what they do well/poorly)
   - Indirect competitors (workarounds, adjacent tools)
   - Holes — what's complained about across competitors
   - Historical failures — what killed similar companies, if visible

5. **Write the artifact.** Save as `research/YYYY-MM-DD-HH-mm-SS/summary.md` (use `date +"%Y-%m-%d-%H-%M-%S"`; create the directory). Two top-level sections: **Customer pain** and **Competitive landscape**. Tables wherever possible. ≤ 8 pages.

6. **Commit summary.** `git add research/<run-id>/summary.md` and commit. Do not commit `raw/`.

7. **Present and hand off.** Show the summary to the user. Once approved, prompt them to run `/ideate`.

## Output template

<summary-template>

## Customer pain

| Theme | Severity | Volume | Segment | Representative quote |
|---|---|---|---|---|
| | | | | |

(One row per theme. Severity = annoyance / costly / blocker. Volume = low / medium / high relative to what you saw.)

### Top quotes (with citations)

- "..." — [source URL](...)
- "..." — [source URL](...)

## Competitive landscape

| Competitor | Type (direct/indirect) | Strengths | Weaknesses | Holes (where users complain) |
|---|---|---|---|---|
| | | | | |

### Historical failures

What killed similar companies / products in this space, if visible from the research.

### Mapping pain ↔ competitors

For each top pain: which competitors address it well, which poorly, where the gap is. This is the bridge to `/ideate`.

</summary-template>
