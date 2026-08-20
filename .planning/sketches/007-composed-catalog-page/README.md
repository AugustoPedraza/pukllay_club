---
sketch: 007
name: composed-catalog-page
question: "Does the real shell (003-C) hold together once it wraps the real, winning shelves (001-D) and cards (002-D) — instead of the shell's own placeholder skeleton — and what drift shows up when they're actually composed?"
winner: "single composed view (consistency check, not a design alternative)"
tags: [consistency, layout, navigation, card, carousel, shell]
---

# Sketch 007: Composed Catalog Page

## Design Question
Frontier-mode consistency check. Sketch 003 (page-shell) proved the header/footer *shape* works
across catalog/detail/about, but its own catalog view was a light placeholder skeleton
(`.pk-shelf`/`.pk-rail`/`.pk-poster-card` — new, independently-declared classes, only 2 references
to anything resembling a real card in the whole file). It was never actually composed with the real
winning shelves (001-D) and the real winning interactive card (002-D). This sketch does that
composition for real and documents what didn't line up.

## Grounding
Nav markup/CSS is copied verbatim from `001-shelf-structure` variant D (`.app-nav`, `.links`,
`.search`, edge-fade `.rail-wrap`, `.mobile-chip-nav`). Card markup/CSS, hover-portal, and mobile
sheet are copied verbatim from `002-card-hierarchy` variant D (`.card`, `.pill`, `.difficulty`,
`.hover-portal`, `.mobile-sheet`). Footer is copied verbatim from `003-page-shell` variant C
(`.footer-c`, mission band + utility bar, BGG badge). Detail/about pages stay as light skeletons —
their full designs are sketches 005/004, already validated elsewhere; this sketch's job is proving
the shell + real catalog content compose cleanly, not re-litigating those.

## How to View
open .planning/sketches/007-composed-catalog-page/index.html

Use the dashed **Sketch control** bar to switch Catálogo / Detalle / Acerca de — watch the same
`.app-nav` element adapt (full links+search → breadcrumb → static label) instead of a second header
implementation taking over.

## Real drift found while composing (not hypothetical)
Building this side by side surfaced two places where "the same" element had quietly diverged, the
exact failure mode this design direction has repeatedly flagged (see sketch 001/002's own findings):

1. **Shell reimplemented the nav and card instead of reusing them.** 003's skeleton used its own
   `.pk-nav`/`.pk-shelf`/`.pk-poster-card` classes with different values (`--pk-gutter: 2rem` custom
   var vs. 001's `--space-6` token, a different card aspect-ratio, no hover-portal at all) rather
   than the real, already-settled components. Harmless as a shape proof, but if it had shipped as
   the literal LiveView markup, the app would have ended up with two independently-declared "catalog
   card" implementations. Fixed here by using 001/002's real classes directly; the only genuinely
   new CSS this sketch adds is the header's quiet-state grafting (`.crumb`, `.quiet-label`) and the
   footer (which had nothing to drift from — no other sketch defines a footer).
2. **001-D and 002-D disagreed with each other on the resting card's own dimensions.** 001's
   `.poster-card` was `width: 160px` with `gap: var(--space-3)` (16px) between cards; 002's `.card`
   — built two sketches later, specifically to design the card's content — was `width: 190px` with
   `gap: var(--space-4)` (24px), despite 002's own README claiming it "matches sketch 001 variant
   D's card exactly." It matched the poster/caption *markup* exactly, but not the sizing. Standardized
   on 002's values here (190px / 24px) since 002 is the deliberately-tuned iteration and its wider
   gap gives the hover-portal room to pop forward without crowding its neighbor.

Both fixes are called out inline in the CSS comments (search for "CORRECTED" and "VERBATIM").

## What to Look For
- Switch Catálogo → Detalle → Acerca de — does the nav read as one component adapting, or does
  anything visually snap/jump between states?
- Hover a card (desktop) — confirm the portal pops forward exactly like it did in isolation in
  sketch 002, now that it's nested inside the shell's sticky nav and real footer below it.
- Scroll to the bottom of a long shelf list — does the Two-Tier footer feel proportionate under real
  shelf content, or too heavy/light compared to how it read under 003's skeleton?
- Shrink to mobile width — chip nav, edge-fade, and card density should all match 001-D's mobile
  behavior exactly, now inside the shell.
- This composition is the reference to carry into the real `Layouts.app` + `CatalogLive.Index` —
  if anything here still looks off, it's cheaper to fix in HTML than after it's real LiveView markup.
