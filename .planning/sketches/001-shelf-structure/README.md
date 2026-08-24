---
sketch: 001
name: shelf-structure
question: "Does the page read as distinct Netflix-style shelves with a real nav bar, or one continuous scroll?"
winner: "D"
tags: [layout, navigation, carousel]
---

# Sketch 001: Shelf Structure

## Design Question
Does the catalog browse page read as distinct, well-separated Netflix-style shelves (with a real
top nav) — or does it still feel like one continuous scrollable grid, which is the current
production complaint?

## Grounding
Built against the real D-09 shelf list and 01-VOCABULARY.md copy (Destacados del club, Descubre el
hobby, Ingenio estratega, Nivel experto, the 3 editorial hashtags, Recientemente añadidos) and the
real brand tokens in `assets/css/app.css` (via `../themes/default.css`). The current production
implementation (`lib/pukllay_club_web/components/carousel_row.ex`) has no visible scroll cue beyond
hover-revealed prev/next buttons — its own code comment admits this reads as "an unresponsive grid."
Cards here are deliberately minimal (poster + title only) — card content is sketch 002's question,
not this one.

## How to View
open .planning/sketches/001-shelf-structure/index.html

## Variants
- **A: Minimal Separation** — adds a real top nav (logo, section anchor links, search) over the
  current spacing-only row separation. Closest to today's structure, cheapest to ship.
- **B: Boxed Shelves** — each row sits inside a tinted, rounded container — an explicit "shelf"
  boundary so scroll extent is unambiguous even without hovering.
- **C: Netflix Edge-Fade** — full-bleed rows (break out of the content max-width), gradient fade at
  each rail's edges hints at scrollability without needing hover, hero shelf gets a wash background,
  nav goes translucent-blurred on scroll (Netflix's own pattern).
- **D: Edge-Fade — Refined** — synthesis of C after first-round feedback. Fixes: nav padding now
  matches the row content's edge (the misalignment made the search box look off); hero wash dropped
  (the light-lavender panel read as muddy against white, replaced with a plain heading + thin
  divider); nav-on-scroll is a flat translucent tint with no blur (borrowed from B's clarity);
  mobile gets a horizontally-scrollable category chip row beneath the nav (the anchor links don't
  fit under ~480px, so chips become the mobile navigation dimension) and denser card sizing so
  ~3.3 cards peek per row on a 390px viewport (iPhone 12 Pro width), hinting scrollability without
  edge-fade alone; each rail ends in a dashed "Ver todo {categoría}" tile — an explicit way to go
  deeper into a shelf's full category instead of just scrolling further.

## Follow-up / Open Question
Raised during review: possible horizontal/vertical scroll ambiguity on touch devices when swiping
diagonally across a horizontal rail (a real concern for any touch-scrollable row, distinct from the
desktop-only interactions this HTML sketch can fully exercise). Worth explicit device testing once
this ships as real Phoenix/LiveView markup — a CSS `touch-action: pan-y` scoped to outside the rail
(and `pan-x` inside it) is the standard mitigation, not something a static sketch can prove out.

## What to Look For
- Scroll upward through each variant — which one makes it obvious where one shelf ends and the next
  begins, at a glance, without hovering?
- Try the nav's anchor links — do they feel like real navigation or decoration?
- In variant D, shrink the viewport to ~390px wide (iPhone 12 Pro) — do the mobile chips read as a
  second nav dimension, and does the card density feel right (not 2, closer to 3+ peeking)?
- In variant D, scroll the page and watch the nav — confirm it's a flat tint, not a blur.
- Check that the desktop search box's right edge now lines up with the row content's right edge.
- Scroll to the end of any rail in variant D — does the "Ver todo" tile read as a natural stopping
  point, or does it feel tacked on?
