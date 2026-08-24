---
sketch: 009
name: empty-loading-error-states
question: "What should the catalog/detail page's non-happy-path states (loading, no results, load error, 404) look like — utilitarian or on-brand illustrated?"
winner: "A"
tags: [empty-state, loading, error, 404, edge-case]
---

# Sketch 009: Empty / Loading / Error States

## Design Question
Every sketch so far (001–008) has designed the happy path — a catalog full of games, a detail page
for a game that exists. But the real app will hit: an initial page load before data arrives, a
filter combination (sketch 008) that matches nothing, a failed request, and a `/juegos/:id` for a
game that doesn't exist or was removed. None of these have been designed. This sketch asks whether
they deserve the same illustrated, human-first treatment as the rest of the catalog, or whether
plain/utilitarian is good enough for states most users will rarely see.

## Grounding
Skeleton-loader shape (poster block + caption line) mirrors the real card dimensions from sketch
002-D. Empty/error/404 copy is written in the same plain-Spanish, no-jargon voice established across
002 ("difficulty, not age") and 003/004's about-page copy. Filter-empty state anticipates sketch
008's filter UI landing on zero results.

## How to View
open .planning/sketches/009-empty-loading-error-states/index.html

Use the dashed **Estado** switcher to cycle each variant through: con resultados / cargando / sin
resultados / error de carga / 404 (detalle).

## Variants
- **A: Minimal / Utilitarian** — flat gray skeleton blocks (no shimmer), terse centered text for
  empty/error/404, one plain retry button. Cheapest to build, lowest risk, but doesn't reinforce the
  project's "teach the hobby, don't assume familiarity" tone at exactly the moments a new/casual
  user is most likely to feel lost or bail.
- **B: Illustrated / Friendly** — shimmering skeleton loaders, an emoji anchor + warmer conversational
  copy on every non-happy-path state, and — specifically on the empty-results state — suggestion
  chips offering a way forward (popular categories) instead of a dead end. Costs more (shimmer
  keyframes, a card treatment, extra copywriting for 3 distinct empty/error/404 messages) but is the
  more brand-consistent choice given the project's explicit "casual or new board-game player" target.

## Winner
**A — Minimal / Utilitarian.** Flat gray skeletons, terse centered copy, one plain retry button —
no shimmer, no emoji anchor, no illustrated card treatment. Confirmed as the direction after review.

## What to Look For
- Cycle through all 5 states on both variants — does B's warmth read as reassuring or as trying too
  hard for what should be a quick, low-stakes moment?
- On the empty-results state: does B's suggestion-chips escape hatch feel meaningfully more useful
  than A's plain "clear filters" button, or is it redundant once the user can just clear filters
  themselves?
- On loading: does B's shimmer read as "the page is alive and working," or is it just movement for
  movement's sake compared to A's static gray blocks?
- Given the project's core value is teaching a non-expert audience, does the extra design investment
  in B pay for itself here, or is this exactly the kind of moment where the simplest thing (A) is
  actually the more respectful choice — get out of the way fast, don't over-explain a dead end?
