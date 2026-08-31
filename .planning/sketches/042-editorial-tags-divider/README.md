---
sketch: 042
name: editorial-tags-divider
question: "Where do editorial hashtag pills sit relative to the description and the ficha-técnica divider, and does that divider still earn its place?"
winner: "Ghost Chip (11px, invisible until hover), own row 24px above/below, before the divider"
tags: [detail, editorial-tags, divider, gap-closure]
---

# Sketch 042: Editorial Tags & Divider

## Design Question
Phase 01.3 UAT gap G-01.3-1's original complaint: editorial hashtags (`#DuelosMemorables`-style)
render as a bare, unlabelled pill row today, positioned *after* the divider (between it and
Mecánicas). User's suggestion: give it a real "category section," or move it before the divider.
Also open since sketch 040 dropped "Sobre el juego"'s own heading: does the divider still earn its
place?

## Winner
Hashtags sit right after the description, before the divider, as **Ghost Chip** — the same pill
shape/tap-target as every other pill on the page, but fully transparent at rest; a soft accent tint
only appears on hover/focus. The row's own margin is 24px above/below (not the page's standard 32px
section gap) — a deliberate exception, since an invisible-at-rest element otherwise reads as dead
whitespace rather than deliberate rhythm.

## Round History
- **Round 1 — placement:** A (move before divider, still bare) picked over B (labelled "Categorías,"
  no divider) and C (folded into fact grid).
- **Round 2 — rhythm:** tag row promoted from sharing the title/description section (8px gap) to its
  own section (32px gap both sides).
- **Round 3 — color:** solid accent-fill pill ("too heavy") softened to a semi-transparent tint, no
  border.
- **Round 4 — shape:** "wondering if those still should look like pills since are hashtags." Four
  options — A (the round-3 pill, reference), B (plain text), **C (Ghost Chip — picked)**, D (flat
  underline label).
- **Round 5 — social-hashtag scale:** "should them be more like a social network hashtag?" C's 11px
  is a UI-label size, not how a hashtag reads in a caption. Three body-scale follow-ups tested — E
  (C's hover-reveal at `text-sm`), F (bold, `text-base`, tightly packed — closest to Instagram), G
  (always-underlined, `text-sm`, solves touch-discoverability). **All three rejected — the original
  11px Ghost Chip (C) was picked as "the best."**
- **Round 6 — rhythm again:** "improve spacing (top and below)." The winning ghost chip's full 32px
  surrounding gap read as excess dead space, since nothing is visible there at rest. Attempted fix: a
  negative margin on the tag row, stacked on top of `.text-col`'s shared 32px flex `gap`, to fake a
  24px result. **This broke the rendered layout** ("that last change killed the design of details").
- **Round 7 — misdiagnosed fix:** first assumed the negative-margin technique itself was the problem
  and replaced it with an explicit-`margin-top` model (`.rhythm-24`/`.rhythm-32` classes, no shared
  `gap`). Still reported broken — a screenshot showed the *actual* fault: the fact grid and Comunidad
  BGG had fallen back to unstyled browser `<dl>` defaults (stacked, indented, no gaps between BGG
  stats). The real root cause was that the round-6 rewrite (finalizing "C only") had **silently
  dropped** `.spec-list`/`.fact-cols`/`.fact-col dt`/`.bgg-link`/`.bgg-label`/`.bgg-row`/`.bgg-stat`/
  `.bgg-foot` from the stylesheet entirely — a copy-paste omission, not a spacing/margin bug at all.
- **Round 8 — actual fix:** restored the missing CSS block verbatim. The explicit-margin rhythm model
  from round 7 was correct and is kept; the fact grid and Comunidad BGG render with their intended
  styling again.

## How to View
open .planning/sketches/042-editorial-tags-divider/index.html

## What to Look For
- Does the 24px gap read as a clear, deliberate beat now, or does it need to go tighter/looser still?
- The row is invisible until hover/focus — no permanent affordance. This was accepted after round 5
  explicitly tested (and rejected) alternatives that solved touch-discoverability (G's permanent
  underline) — worth a final gut check on mobile specifically, where there's no hover to reveal it.
- Divider still present here — worth a final check once this is composed with 039/040/041 together:
  does it still earn its place, or is it now one boundary too many?
