---
sketch: 035
name: detail-page-rhythm
question: "How much space should separate the header from the masthead, and the \"Juegos similares\" shelf from the footer, once the stacked/buggy spacing is collapsed to one deliberate value at each end?"
winner: "D"
tags: [detail, spacing, rhythm, whitespace, gap-closure]
---

# Sketch 035: Detail Page Rhythm

## Design Question
UAT gap G-01.2-11: "there are too many space from where the details starts and from the header"
and "after the caoursel 'juegos recomendados' there are also too much whitespace until the footer."
Grounding this in the real code found two concrete, additive causes — not just "add more taste":

- **Top:** `#detail-title-echo` (the sticky title bar that fades in once the real title scrolls out
  of view) is unconditionally rendered and hidden only via `opacity: 0` — as a `position: sticky`
  element it still occupies its own box in normal document flow even while invisible, adding
  roughly 60-70px of dead space on top of `<main>`'s own `pt-8 sm:pt-20` (32-80px) before the
  masthead's pills/poster even start.
- **Bottom:** three independent spacing declarations stack on top of each other: `<main>`'s own
  `pb-20` (80px) + `.pk-footer`'s `margin-top: 3rem` (48px) + `.pk-footer-row`'s own
  `padding-top: 1.5rem` (24px) = 152px combined — each reasonable in isolation, additive together.
  This is the same class of bug `page-shell.md` already documents elsewhere in this codebase
  (independently-declared values that should share one source).

## Grounding
`lib/pukllay_club_web/live/catalog_live/show.ex` (`#detail-title-echo`, the `space-y-4` content
wrapper), `assets/css/app.css` (`.pk-title-echo`, `main`'s Tailwind utility classes in
`layouts.ex`, `.pk-footer`/`.pk-footer-row`). All three variants below assume BOTH bugs get fixed
in code (title-echo excluded from flow while hidden; bottom collapsed to one shared value) — they
only differ in the resulting total gap size, which is the actual design question here.

## How to View
open .planning/sketches/035-detail-page-rhythm/index.html

The dashed columns mark the gap being measured at each tab. Numbers in the tab labels are the
TOTAL gap after the fix, not a value to add on top of what exists today.

## Winner: D — Equal (24px top / 24px bottom)
Same value at both ends — a uniform, minimal rhythm instead of telegraphing "content vs. chrome"
with a bigger bottom gap.

## Round history
- **Round 1** — three asymmetric scales explored: **A Snug** (24px top / 48px bottom), **B
  Balanced** (40px / 72px), **C Generous** (56px / 96px, closest to today's likely *intended*
  breathing room before the stacking bug). User leaned toward A but asked why top/bottom weren't
  equal — discussed the rationale (top separates content from persistent chrome, so tight is
  conventional; bottom separates content from the footer, a "page ending" cue that commonly gets
  more room) versus a simpler uniform rhythm, and agreed it was worth comparing directly rather
  than settling by discussion alone.
- **Round 2** — added **D Equal** (24px / 24px, same top figure as A, bottom dropped to match).
  Picked directly over A. A/B/C removed from `index.html` (D only).

## What to Look For
- Does the masthead now feel like it starts promptly under the header, without feeling cramped
  against it?
- Does the transition from the "Juegos similares" shelf into the footer feel like a clean page
  ending, without a dead empty band first?
- Is the bottom gap noticeably larger than the top gap in every variant (intentional — a page
  ending typically wants more breathing room than a section-to-section transition) — does that
  ratio feel right, or should top/bottom move closer together?
