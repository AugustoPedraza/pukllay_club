---
sketch: 024
name: row-position-indicator
question: "Does a shelf row benefit from an explicit position/pagination indicator (progress bar or segmented dashes), or does edge-fade + peek already communicate scroll position well enough, matching Netflix's own choice to have none?"
winner: "A"
tags: [carousel, pagination, indicator, netflix]
---

# Sketch 024: Row Position Indicator

## Design Question
The original request asked for "pagination" on the carousel. Netflix itself has none on its rows —
edge-fade is the only cue, and its rows run 20+ items where a fill/segment indicator would be nearly
meaningless. This app's shelves are shorter (8-10 cards, per `SHELVES` in 001), where "how far
through this row am I" is a more answerable question. This sketch tests whether a real indicator
earns its chrome cost here, or whether it's solving a problem the peek/edge-fade pattern (from 023)
already solves.

## Grounding
Reuses 001-D's rail/card markup verbatim, plus 023's `overscroll-behavior-x: contain` fix. Both
indicator variants are driven by a real `scroll` event listener reading `scrollLeft` /
`scrollWidth` — not decorative, they track actual rail position live as you drag or click arrows.

## How to View
open .planning/sketches/024-row-position-indicator/index.html

Drag a rail or click its arrows and watch the indicator under the row title update live in B/C.

## Variants
- **A: None (current shipped behavior)** — edge-fade only, matching Netflix exactly. Zero chrome
  cost, but this app's shorter rows may not need the restraint Netflix's 20-item rows do.
- **B: Thin Progress Bar** — a slim continuous track, fill width = `scrollLeft / (scrollWidth -
  clientWidth)`. Reads like a video seek bar — continuous position, not discrete "pages."
- **C: Segmented Dashes (Instagram Stories-style)** — one segment per arrow-click "page" (4
  segments for these row lengths), filling cumulatively as you scroll past each. Reads as "page 2 of
  4" — more discrete and countable than B's continuous fill.

## Winner
**A — None (edge-fade only).** Confirmed matching Netflix's own restraint — B/C's extra chrome
wasn't worth it once 023's peek-next-card affordance already signals scrollability. B/C removed
from `index.html` (A only); composed together with 022-C/023-B/025-B in sketch 026.

## What to Look For
- Scroll a row fully on B vs C — does B's continuous fill feel more precise, or does C's segmented
  count feel easier to read at a glance while browsing (not staring at the indicator)?
- Does either indicator add real value once you've already seen 023's peek-next-card affordance, or
  does it start to feel like redundant chrome once that's in place?
- On mobile viewport, does either indicator survive being genuinely useful, or does it just become
  another thin line competing for attention above a dense row of cards?
- Given Netflix explicitly chose none — is there a real reason this app's shorter, more finite
  shelves (vs. Netflix's much longer, less "completable" rows) justify diverging from that pattern?
