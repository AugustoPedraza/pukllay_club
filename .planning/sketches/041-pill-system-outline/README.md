---
sketch: 041
name: pill-system-outline
question: "How far should the outline pill tone from 039/040 spread across the site's real pill/chip call sites?"
winner: null
tags: [detail, catalog, pills, chips, design-system, consistency]
---

# Sketch 041: Pill System, Site-Wide

## Design Question
039/040 moved the detail page's informational pills (creators, Mecánicas, Temáticas) to production's
`.pk-pill-outline` tone. Feedback: "definitely the new pills look a lot cleaner, I want to be sure we
will update it to be consistent everywhere." Asked to confirm scope; picked "everything, including
filter/selection chips."

## Real call-site inventory (verified against the code, not assumed)
Every place `.pk-pill*` actually renders today:
1. `GameChips.chip_row/1` (Mecánicas/Temáticas) — `pk-pill-neutral` → resolved to outline in 040.
2. `GameChips.editorial_tags/1` (hashtags) — `pk-pill-accent`, intentionally kept separate (curated
   category, not a structured fact) — not touched by this sketch.
3. `GamePreview.facts_row/1` (players/playtime/difficulty pills — browse-card hover preview +
   masthead) — `pk-pill-neutral`.
4. `filter_modal.ex`'s `chip_class/1` — unselected = `pk-pill-outline` **already**; selected =
   `pk-pill-selected` (solid primary fill + soft shadow).
5. `catalog_live/index.ex`'s active-filter chip row (Resultados header, tap-to-remove ×) —
   `pk-pill-accent`.

## Finding
Items 1 and 3 are pure display — no state to lose, outline applies with no tradeoff. Items 4 and 5
carry **real app state**: they're the only visual signal that "this filter is currently applied."
Literal outline everywhere makes a selected/active chip render **identically** to an inert Mecánicas
chip — the panel 3/4 toggle in this sketch shows the actual visual result of both options side by
side, not just a description of the risk.

## How to View
open .planning/sketches/041-pill-system-outline/index.html — the top toggle swaps panels 3-4 between
today's production behavior (filled/distinct selected state) and literal outline everywhere.

## What to Look For
- Panels 1-2: confirm these read as clean, consistent with 039/040 — no real decision left here.
- Panels 3-4 with the toggle on "Literal outline everywhere": can you still tell which filters are
  currently applied at a glance, or does it blend into the rest of the page's now-uniform pill look?
- If outline-everywhere doesn't work for 3-4, is there a middle tone worth exploring for "selected"
  (e.g. an outline pill with a filled dot, or a primary-colored border only) rather than reverting to
  today's full solid fill?
