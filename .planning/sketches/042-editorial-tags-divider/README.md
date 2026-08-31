---
sketch: 042
name: editorial-tags-divider
question: "Where do editorial hashtag pills sit relative to the description and the ficha-técnica divider, and does that divider still earn its place?"
winner: "A, rebalanced — tags before the divider, in their own reading-section for full 32px rhythm"
tags: [detail, editorial-tags, divider, gap-closure]
---

# Sketch 042: Editorial Tags & Divider

## Design Question
Phase 01.3 UAT gap G-01.3-1's original complaint: editorial hashtags (`#DuelosMemorables`-style)
render as a bare, unlabelled pill row today, positioned *after* the divider (between it and
Mecánicas). User's suggestion: give it a real "category section," or move it before the divider.
Also open since sketch 040 dropped "Sobre el juego"'s own heading: does the divider still earn its
place, now that this reading column increasingly relies on small labels + rhythm instead of dividing
lines?

## Winner
**Variant A, rebalanced.** Tags move up to sit right after the description, still with no label
(closest to the user's literal suggestion, picked over B's "Categorías" label and C's fold-into-grid).
Round 1 had the tag row crammed inside the same reading-section as title+description, only 8px from
the description text — too tight. Promoted to its own `.reading-section`, so it now gets the full
32px between-section rhythm both above (from the description) and below (to the divider) — reads as
its own beat instead of a tacked-on line under the prose.

## Round History
- **A: Move Before Divider, Still Bare** (picked) — tags before the divider, no label.
- B: Labelled "Categorías," No Divider — dropped.
- C: Folded Into the Fact Grid — dropped.
- Round 2 — "I want to see it with a better balance": tag row promoted from sharing the
  title/description section (8px gap) to its own section (32px gap both sides).

## How to View
open .planning/sketches/042-editorial-tags-divider/index.html

## What to Look For
- Does the tag row now read as a clear, separate beat between the description and the divider, or
  does the 32px gap make it feel disconnected from the description it's tagging?
- Divider still present here (only B/C removed it) — worth a final check once this is composed with
  039/040/041 together: does it still earn its place, or is it now one boundary too many?
