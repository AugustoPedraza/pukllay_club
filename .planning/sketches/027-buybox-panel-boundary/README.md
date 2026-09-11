---
sketch: 027
name: buybox-panel-boundary
question: "Does the buy-box read as one self-contained panel distinct from the reading column, on desktop and mobile?"
winner: "B"
tags: [detail, buybox, boundary, panel, gap-closure]
---

# Sketch 027: Buy-box Panel Boundary

## Design Question
UAT gap G-01.2-5: "The layout for game details on desktop isn't correct (and mobile is even
worse)." Root-cause diagnosis (`.planning/debug/G-01.2-5-buybox-layout.md`) found two contributing
causes: (1) a CSS cascade-layer bug that breaks the share control's positioning below 768px — a
code fix, out of scope for this sketch — and (2) the panel's only boundary against the page is a
`bg-base-200`/`bg-base-100` fill pair independently measured elsewhere in this codebase at
1.415:1 (light) / 1.086:1 (dark) contrast, well under the app's own 3:1 non-text floor. This
sketch explores (2): what visual treatment makes the buy-box read as a bounded, self-contained
decision panel distinct from the reading column?

## How to View
open .planning/sketches/027-buybox-panel-boundary/index.html

Resize the real browser window below 768px (or use devtools' device toolbar) to see the mobile
stack — the toolbar's viewport buttons are an approximation only (see sketch 005's own note on
why `@media` can't respond to a capped `max-width` wrapper).

## Variants
- **A: Defined Border** — keeps the current fill, adds a visible primary-tinted hairline border
  instead of relying on the flat surface pair alone.
- **B: Elevated Shadow** — drops the fill difference, lifts the panel with a soft shadow on a
  plain background instead.
- **C: Stronger Fill** — no border, no shadow (keeps 01.2-04's original "fill-only, lowest-risk
  boundary" plan constraint), but swaps the flat `base-200` wash for the accent tint already used
  elsewhere for emphasis, which sits further from the page background.

## What to Look For
- Does the panel read as clearly separate from the reading column at a glance, on both desktop
  (side-by-side) and mobile (stacked)?
- Does the share icon read as anchored to the cover art/panel, not floating loose?
- Which treatment best matches the "self-contained decision panel, reserve button as the single
  primary action" intent from the original UI-SPEC — border, shadow, or a stronger fill alone?
- Note: the actual position bug (share button pinned to the page instead of the panel below
  768px) is a code fix, not something this sketch can misrepresent or fix — this sketch shows the
  *intended* correct positioning so the boundary question can be judged on its own.
