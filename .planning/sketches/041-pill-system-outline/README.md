---
sketch: 041
name: pill-system-outline
question: "How far should the outline pill tone from 039/040 spread across the site's real pill/chip call sites?"
winner: "Outline everywhere; selected/active state = primary border + primary text (no fill)"
tags: [detail, catalog, pills, chips, design-system, consistency]
---

# Sketch 041: Pill System, Site-Wide

## Design Question
039/040 moved the detail page's informational pills (creators, Mecánicas, Temáticas) to production's
`.pk-pill-outline` tone. Feedback: "definitely the new pills look a lot cleaner, I want to be sure we
will update it to be consistent everywhere." Scope confirmed as "everything, including
filter/selection chips."

## Real call-site inventory (verified against the code, not assumed)
Every place `.pk-pill*` actually renders today:
1. `GameChips.chip_row/1` (Mecánicas/Temáticas) — `pk-pill-neutral` → resolved to outline in 040.
2. `GameChips.editorial_tags/1` (hashtags) — `pk-pill-accent`, intentionally kept separate (curated
   category, not a structured fact) — not touched by this sketch.
3. `GamePreview.facts_row/1` (players/playtime/difficulty pills — browse-card hover preview +
   masthead) — `pk-pill-neutral` → resolved to outline.
4. `filter_modal.ex`'s `chip_class/1` — unselected = `pk-pill-outline` **already**; selected was
   `pk-pill-selected` (solid primary fill + soft shadow) → resolved below.
5. `catalog_live/index.ex`'s active-filter chip row (Resultados header, tap-to-remove ×) — was
   `pk-pill-accent` → resolved below.

## Round 1 — literal outline everywhere
Tested making selected/active chips exactly the same outline tone as passive pills. **Feedback:
"literal outline looks clear"** — accepted at first pass.

## Round 2 — caught before finalizing
Flagged directly: with literal outline, panel 3's selected chip ("Experto") rendered **pixel-identical**
to the unchecked chips right next to it in the same control — no way to tell which filter option was
chosen. Confirmed: selected/active does need a distinguishing signal.

## Winner
Selected/active stays in the outline family (no fill, no shadow) but permanently carries the pill's
own **hover treatment** — primary-colored border + primary-colored text — instead of inventing a new
style. Applied to both filter-modal's selected chips and the active-filter chip row, since they're the
same underlying signal ("this is currently filtering your results").

## How to View
open .planning/sketches/041-pill-system-outline/index.html

## What to Look For
- Panel 3: is "Experto" now clearly distinguishable from its unchecked siblings at a glance?
- Panel 4: does the active-filter row read as clearly "applied, tap × to remove" against the plain
  Resultados heading next to it?
- Check both themes (🌙/☀ toggle) — primary-on-transparent contrast in dark mode.
