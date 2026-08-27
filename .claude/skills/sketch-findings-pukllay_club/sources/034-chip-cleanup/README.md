---
sketch: 034
name: chip-cleanup
question: "Now that the redundant weight-band badge+description is dropped, what treatment gives the Mecánicas/Temáticas chips real border/background contrast?"
winner: "A"
tags: [detail, chips, mecanicas, tematicas, cleanup, gap-closure]
---

# Sketch 034: Chip Cleanup

## Design Question
UAT gap G-01.2-11, two related cleanups on the same block (`CatalogLive.Show`'s text column,
between the divider and "Ficha técnica"):

1. **"still it shows its 'category' pills with a description(remove it)"** — the weight-band badge
   (`GameChips.weight_band_badge`, `show_descriptor={true}`) renders a big "Nivel experto" badge
   plus an explanatory sentence ("Requiere varias partidas para dominarlo...") right after the
   editorial-tag row. This duplicates the same dificultad info already shown compactly in the
   facts row above the title (`GamePreview.facts_row`) — a prior round (G-01.2-10, D2) explicitly
   chose to *keep* this block; this round reverses that decision. Removed in all variants below.
2. **"the 'labesl' and 'values' for the mecanicas, tematicas isn't well balanced(has border to
   together to text and background don't constraint)"** — `GameChips.chip_row` (Mecánicas,
   Temáticas) renders plain daisyUI `badge badge-sm` chips with no custom `.pk-*` override
   (confirmed — no `.badge`/`.badge-sm` rule exists in `app.css`). The 3 tabs below are 3 different
   fixes for this: more breathing room, no border, or a grouped card treatment.

## Grounding
Real component/class names: `GameChips.weight_band_badge` (badge-secondary + descriptor `<p>`),
`GameChips.chip_row` (`badge badge-sm`, Mecánicas/Temáticas), `GameChips.editorial_tags`
(`badge-accent`, unchanged — the club hashtags are a separate, already-fine treatment). Section
019's "grouped accent-card sections" pattern (filter modal) reused for variant C. Sample content
continued from sketches 005/032/033.

## How to View
open .planning/sketches/034-chip-cleanup/index.html

Toggle 🌙/☀ in the bottom-right toolbar to check both themes — chip background contrast is exactly
the kind of thing that can look fine in one theme and wash out in the other (see sketch 033's
lightbox finding for a real example of that failure mode in this codebase).

## Winner: A — Bordered Outline, Soft Fill
Same shape as production (border + fill), roughly doubled padding for breathing room, background
token that actually reads against the page instead of nearly matching it.

## Round history
- **Round 1** — three chip treatments explored: **A Bordered Outline, Soft Fill** (today's shape,
  more padding + real background contrast); **B Solid Tonal Fill, No Border** (drops the border
  entirely); **C Section-Grouped Card** (wraps each row in its own bordered card, reusing sketch
  019's filter-modal grouping pattern). A picked directly, no revision. B/C removed from
  `index.html` (A only).
- The weight-band badge + description removal (separate cleanup, bundled into this same sketch)
  was applied identically in all three variants, not itself a variant axis — shown once as a
  struck-through "removed" callout for documentation, not re-litigated per tab.

## What to Look For
- Does the chip text now have real breathing room against its own border/edge?
- Does the chip background read as clearly distinct from the page in both themes, or still blend
  in?
- Does removing the weight-band badge+description leave an awkward gap, or does the tag row flow
  straight into "Mecánicas" cleanly?
- A/B/C: which chip treatment feels most consistent with the rest of the app's restrained,
  non-heavy chip language (facts pills, editorial tags)?
