---
name: research-market
description: Run secondary research on customer pain and competitive landscape. Mines forums, articles, and reviews to produce a versioned research artifact in research/. Use when the user wants market evidence before ideating.
disable-model-invocation: true
---

Run secondary research over the problem space. Produce one document covering customer pain *and* competitive landscape — they share the same source pool, and the synthesis cuts across both anyway (pain × who-already-solves-it).

## Inputs

The problem space, segments, and pain hypotheses defined in `define` (in-context). If those aren't defined, prompt the user to run `define` first and stop.

## Process

1. **Estimate, and pick the depth.** Default to the **quick path** — interactive `WebFetch`/`WebSearch`, prose synthesis. Step up to the **structured tier** (step 4) when either holds: (a) the market is *multi-sided* — distinct stakeholder voices whose interests diverge (buyers vs sellers, clinicians vs admins, customers vs tradies); or (b) you expect enough volume that counts beat impressions and every claim should cite a specific record. Print a one-line cost/runtime estimate and confirm before fetching — surprise bills are bad. Quick path: ~10–30 min, ~$3–8. Structured tier: materially more — scripted bulk fetch is cheap, but extracting and tagging the corpus scales with its size; estimate from the expected record count and re-confirm.

2. **Build a source list.** Pick the 5 most relevant sources for this project type — places where the target users actually complain or compare tools (forums, review sites, app stores, domain-specific communities). Then **test each one** by attempting to fetch a sample page with `WebFetch` or `WebSearch`. If a source blocks scraping, requires login, or returns empty/captcha content, drop it and pick a replacement until 5 viable sources are in hand. The web is a moving target — encode the rule, not yesterday's site list.

   Final list should cover ≥3 distinct platforms **or** persona segments — breadth across sources, or justified depth in one. A single dominant watering hole mined deep satisfies this when it yields ≥3 distinct persona segments (e.g., buyers, sellers, sub-segments); for a geo- or community-specific market, depth in the right forum beats three shallow sources.

3. **Fetch loop.** Use `WebFetch` and `WebSearch`. Stop when **all three** gates fire:
   - **Floor.** ≥50 sources collected.
   - **Saturation.** Last 10 sources added no new themes.
   - **Diversity.** ≥3 distinct platforms or persona segments sampled — depth in one dominant forum satisfies this when it spans ≥3 persona segments (see step 2).

   For non-deterministic content (forums), prefer recent + high-engagement threads. Save raw fetched content under `research/<run-id>/raw/<source>-<n>.txt` for reproducibility. For the structured tier, fetch with a small saved script (committed under `scripts/`) rather than one-off calls — that's what makes a large corpus reproducible — and save the resolved source/thread list alongside it.

   **Optional URL cleanup.** Before saving article-shaped pages, check `which defuddle 2>/dev/null`. If installed, run `defuddle <url>` and save that output instead of the raw `WebFetch` markdown — strips ads, nav, and footers; typically saves 40–60% tokens. Fall back silently to `WebFetch` if missing. Install: `npm install -g defuddle` (the old `defuddle-cli` package was merged into `defuddle`). Skip defuddle for non-article sources (forum threads, app-store reviews) — it can over-trim.

   **On first run, append `research/*/raw/` and `research/*/corpus.jsonl` to `.gitignore`** — both hold verbatim third-party content (ToS/copyright risk) and both regenerate from `scripts/`.

4. **Extract and tag — structured tier only.** Between fetch and synthesis, turn raw content into one atomic record per observation (a single complaint, request, or comparison). Write them to `research/<run-id>/corpus.jsonl`, one JSON object per line:

   ```json
   {"id": "wp_1237067_p033", "url": "https://...", "voice": "tradie", "segment": "electrician", "pain_category": "billing_invoicing", "quote": "..."}
   ```

   Then project the metadata (every field *except* `quote`) to `research/<run-id>/index.csv`. The corpus carries the verbatim text and stays local; the index is facts (URLs + tags) and is safe to commit — it's what lets volume be counted and any claim be audited by following its URL. Capture `voice` only for multi-sided markets, and capture enough author/thread identity that you can later check a theme isn't one loud poster repeated.

   Skip this step on the quick path — go straight to synthesis off what you read.

5. **Synthesize.** Cluster observations into themes. For each theme, capture:
   - The pain itself (one sentence)
   - Direct quotes (≥2) with citation URLs (structured tier: cite by record `id`)
   - Volume — on the structured tier, **count** from `index.csv` (e.g., "billing: 2308 records, 41%") and note the denominator; on the quick path, fall back to low / medium / high. Count voices, not raw posts — one user complaining fifty times is one voice.
   - Severity (annoyance / costly / blocker)
   - Who's affected (segment), and for multi-sided markets the **voice** speaking (e.g., customer vs tradie). Rank pain within each voice, then surface where the voices conflict — the *tension view* (voice A wants X / voice B wants Y / gap Z) is the sharpest hand-off to `/ideate`.

   For competitive landscape, capture:
   - Direct competitors (named, with what they do well/poorly)
   - Indirect competitors (workarounds, adjacent tools)
   - Holes — what's complained about across competitors
   - Historical failures — what killed similar companies, if visible

6. **Write the artifact.** Save as `research/YYYY-MM-DD-HH-mm-SS/summary.md` (use `date +"%Y-%m-%d-%H-%M-%S"`; create the directory). Two top-level sections: **Customer pain** and **Competitive landscape**. Tables wherever possible. For multi-sided markets, include a **tension matrix** (below). When two dimensions are both strong (e.g., pain × segment), an optional cross-tab heat-map — counts in a grid — beats flat tables. ≤ 8 pages.

7. **Commit the method, not just the summary.** `git add` the `summary.md`, and — if the structured tier ran — the `index.csv`, the `scripts/`, and the resolved source/thread list, then commit. These make the run re-runnable and auditable. Do **not** commit `raw/` or `corpus.jsonl` — both carry verbatim third-party content and both regenerate from `scripts/`. The committed index (URLs + tags) plus the quotes cited in the summary are enough to audit any claim.

8. **Present and hand off.** Show the summary to the user. Once approved, prompt them to run `/ideate`.

## Output template

<summary-template>

## Customer pain

| Theme | Voice | Severity | Volume | Segment | Representative quote |
|---|---|---|---|---|---|
| | | | | | |

(One row per theme. Voice = which stakeholder is speaking — drop the column for single-sided markets. Severity = annoyance / costly / blocker. Volume = a count from `index.csv` on the structured tier, else low / medium / high.)

### Tension matrix (multi-sided markets)

| Pain area | Voice A says | Voice B says | Opportunity / gap |
|---|---|---|---|
| | | | |

(Where the voices disagree is where the product opportunity lives — this is the sharpest bridge to `/ideate`. Stop here: candidate journeys / CUJs are `/ideate`'s and `/to-prd`'s job, not this skill's.)

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

For each top pain: which competitors address it well, which poorly, where the gap is. Together with the tension matrix, this is the bridge to `/ideate`.

</summary-template>
