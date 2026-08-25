---
sketch: 025
name: carousel-loading-repopulation
question: "Does a shelf repopulating after a filter change (a fast, frequent, localized moment) call for a different loading treatment than 009's page-load skeleton — flat skeleton reused as-is, a scoped shimmer, or a crossfade with no loading UI at all?"
winner: "B"
tags: [carousel, loading, skeleton, shimmer, crossfade, consistency]
---

# Sketch 025: Carousel Loading / Repopulation Feel

## Design Question
009 already decided against shimmer/pulse for full-page and initial loads — flat gray skeletons won
as "the more respectful choice," reasoning that a beginner-facing app should get out of the way
fast rather than over-explain a quick, low-stakes moment. This sketch deliberately retests that
decision in a **narrower, different context**: a single shelf repopulating after the page is already
loaded (e.g. a filter change), not the full-page cold-start 009 was scoped to. Netflix/Disney+
typically skip loading UI entirely for this specific moment and just crossfade the new content in.

## Grounding
Reuses 001-D's rail/card markup and 009-A's exact flat-skeleton shape/CSS (`.skel-card`, `.skel-art`,
`.skel-line`, `--color-border` fill) for variant A, and 009-B's exact shimmer keyframes for variant
B — both copied verbatim so this is a fair re-test of the same visual language, not a new proposal.
Research: skeleton screens are the established loading pattern generally, but Netflix/Disney+
specifically favor a crossfade over a skeleton for *incremental* row updates once the shell is
already on screen — this distinction (initial load vs. incremental update) is exactly what 009
didn't get to test, since it was scoped to page-level states.

## How to View
open .planning/sketches/025-carousel-loading-repopulation/index.html

Click **"🔀 Filtrar por Estrategia"** on any variant's shelf to simulate a real filter-triggered
repopulation — each click alternates between two card sets so you can trigger it repeatedly.

## Variants
- **A: 009's Flat Skeleton, Reused As-Is** — same no-shimmer gray blocks 009 validated, shown for a
  beat (~650ms) then swapped for the new cards. Consistent with the site's one established loading
  language everywhere else.
- **B: Shimmer, Scoped to This Moment Only** — 009's exact rejected shimmer treatment, applied only
  here. Tests whether the "trying too hard" objection from 009 was about shimmer itself, or about
  showing it on a big, attention-grabbing full-page moment specifically.
- **C: Crossfade-in-Place, No Skeleton** — old cards fade+shrink out (~180ms, staggered by index),
  new cards fade+rise in (~staggered), no loading UI at all. Closest to Netflix/Disney+'s actual
  behavior on a category/filter switch — the row never "goes away," it just changes.

## Winner
**B — Shimmer, scoped to repopulation only.** Confirmed that 009's "trying too hard" objection was
about showing shimmer on a big, attention-grabbing full-page moment — not about shimmer itself. On
this fast, small, expected repopulation, it reads as "the row is alive and working" rather than
over-explaining. 009's flat-skeleton decision for full-page/initial loads stands unchanged; this is
a separate, narrower context. A/C removed from `index.html` (B only); composed together with
022-C/023-B/024-A in sketch 026.

## What to Look For
- Trigger the filter repeatedly on A vs C — does C's crossfade feel more "alive" and native since
  nothing ever visually empties out, or does the brief hidden state in A/B feel more honest about
  "something is happening"?
- Does B's shimmer read differently here (fast, small, expected) than it did in 009's full-page
  context, or does the same "trying too hard" objection still apply?
- If C wins: does skipping skeleton entirely ever feel like nothing happened, especially on a slow
  connection where the real repopulation might take longer than this sketch's simulated 180ms?
- Would you want ONE consistent answer across full-page loads (009) and shelf repopulation (here), or
  is it fine for these to genuinely differ since they're different moments with different stakes?
