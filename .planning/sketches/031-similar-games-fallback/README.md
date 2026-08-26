---
sketch: 031
name: similar-games-fallback
question: "How should 'Juegos similares' read when the same-band pool is sparse — copy and fallback treatment?"
winner: "C"
tags: [detail, similar-games, shelf, copy, gap-closure]
---

# Sketch 031: Similar Games Fallback

## Design Question
UAT gap G-01.2-7: "1-2 isn't acceptable. This 'juegos similares' must to be fulled. Maybe this
could be 'otras sugerencias' (otras opciones que te van a encantar)." Root-cause diagnosis
(`.planning/debug/G-01.2-7-similar-games-rail.md`) confirmed `Catalog.similar_games/1` has no
fallback/widening logic today — a deliberate, documented UI-SPEC backstop, not a bug — and with
the current catalog's real weight-band sizes (46/179/183 games) a literal 1-2-card rail cannot
happen today; this is a forward-looking guarantee request. The query-layer fix (widening the pool)
is out of scope here — this sketch explores the visual/copy question: how should the shelf
communicate when it's true same-band similarity vs. a broadened suggestion pool?

## How to View
open .planning/sketches/031-similar-games-fallback/index.html

Toggle "Simular banda dispersa" to preview the widened-pool state.

## Winner: C — Always-Full Guarantee
The shelf always shows a full row — the query-layer fix widens the pool (adjacent bands, broader
overlap) whenever the same-band pool is thin, so a sparse rail becomes structurally impossible.
The shelf layout never changes; a small "Ampliado" badge next to the title, plus a subtitle swap
to "Otras opciones que te van a encantar", is the only visible sign widening happened.

## Round history
- **Round 1** — three variants explored: **A Conditional Title Only** (chrome fixed, only
  title/subtitle swap), **B Sparse Compact Cluster** (drops full-rail chrome for a small cluster
  when genuinely sparse), **C Always-Full Guarantee** (query always widens enough to fill the
  shelf; layout is invariant). C picked directly — no revision needed.

## What to Look For
- Does the "Ampliado" badge + subtitle swap communicate "these are broader suggestions" clearly
  without needing to explain the mechanism to the visitor?
- Does "Juegos similares" stay the right title even when the badge is present, or should the title
  itself change to "Otras sugerencias" as originally proposed? (Current winner keeps the title
  fixed and only badges/subtitles the widened state — flag if that reads as insufficiently
  different from the true-match case.)
- This sketch is copy/visual-only — the actual query-layer widening (adjacent-band distance,
  dropped band filter, or `bgg_weight` proximity; see the debug doc's three candidate strategies)
  is a separate implementation decision for plan-phase.
