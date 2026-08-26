---
sketch: 029
name: active-filters-chip-row
question: "What does an active-filters affordance look like in the Resultados header?"
winner: "C"
tags: [catalog, filter, chips, resultados, gap-closure]
---

# Sketch 029: Active Filters Chip Row

## Design Question
UAT gaps G-01.2-3/G-01.2-4 (sub-issue B): "Resultados shows something but there aren't any
affordance about which filters are been applied." Root-cause diagnosis
(`.planning/debug/G-01.2-3-4-search-reopen-filter-modal.md`) confirmed this is a pure missing-
feature gap — `index.ex:691-697`'s Resultados header renders only a heading and a result count,
with no chip/summary UI anywhere reflecting active filter state (the one existing proxy, a numeric
badge on the filter trigger, is itself trapped inside the broken collapsible search region covered
by a separate fix). This sketch explores what a removable active-filters chip row looks like.

## How to View
open .planning/sketches/029-active-filters-chip-row/index.html

Click a chip's × to see the remove interaction.

## Winner: C — Inline with Heading (Round 2 rebalanced)
Chips share the heading's row, right after the result count — most compact on desktop, wraps to
its own line only when space runs out on narrow widths.

## Round history
- **Round 1** — three placements explored: **A Wrapping Row** (chips below the heading, own row,
  wrap freely), **B Scrollable Row** (labeled "Filtros:" + horizontally-scrollable strip), **C
  Inline with Heading** (chips share the heading's row). All three reused sketch 019's filled
  pill-chip contract (solid `--color-primary` fill + shadow) verbatim.
- **Round 2** — feedback: picked C, but "chips are too heavy" — the solid filled pill + shadow,
  borrowed as-is from 019's filter-modal chips, competed with "Resultados" for visual weight on
  the same row. Rebalanced: chips now use a soft `--color-accent-bg`/`--color-accent-text` tint
  with a thin border and no shadow — same "applied filter" signal, without outweighing the
  heading. The × affordance also lightened (transparent by default, only fills red on hover, not
  a semi-opaque white circle at rest). A/B removed from `index.html` (C only).

## What to Look For
- Does "Resultados" still read as the dominant element on the row, with chips clearly secondary?
- Does it still read clearly as "these are your active filters, tap × to remove one"?
- Does it stay usable with 1 filter and with 5+ filters active (wraps under the heading on
  narrow/mobile)?
- Does "Limpiar filtros" read as a clear, separate action from removing one chip?
