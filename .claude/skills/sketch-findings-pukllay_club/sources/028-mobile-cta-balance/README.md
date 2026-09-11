---
sketch: 028
name: mobile-cta-balance
question: "How should the mobile fixed-bottom CTA bar balance the reserve button against the share control?"
winner: "D"
tags: [detail, cta-bar, mobile, buttons, gap-closure]
---

# Sketch 028: Mobile CTA Bar Balance

## Design Question
UAT gap G-01.2-6: "This need a better balanced layout" (mobile fixed bottom CTA bar). Root-cause
diagnosis (`.planning/debug/G-01.2-6-cta-bar-balance.md`) found this is a pre-existing condition,
not a regression: at ~390px width the `flex-1` reserve button occupies ~87% of the bar's content
width against a fixed 44px circular share button (~13%), a ~7:1 ratio, compounded by a stylistic
mismatch (solid `btn-primary` fill vs. a barely-visible `btn-outline` circle against the bar's own
background). This sketch explores concrete rebalancing directions.

## How to View
open .planning/sketches/028-mobile-cta-balance/index.html

Narrow the real browser window to ~390px to judge the ratio at the actual repro width; widen past
1100px to confirm the bar aligns under the content column instead of stretching edge-to-edge.

## Winner: D — Stacked
Reserve button takes the full bar width on its own row; share drops to a smaller, quiet secondary
row below it as an outline pill. Trades ~40px of extra bar height for an unambiguous primary
action and a share control that still reads as intentional, not squeezed into a leftover sliver.

## Round history
- **Round 1** — three side-by-side variants explored rebalancing the existing row layout: **A
  Width Cap** (reserve capped at 75%, share becomes an equal-height rectangle), **B Matched
  Weight** (kept the 87/13 ratio and circle shape, gave the circle a solid fill), **C Paired
  Pills** (both controls as rounded rectangles, 68/32, share labeled "Compartir"). None felt
  right — feedback was "not sure of any of those," plus two new directions requested (stacked
  layout; a floating contrasted share circle), and a global fix: the bar's content must match the
  page column's width at desktop instead of stretching edge-to-edge across the raw browser window.
- **Round 2** — added **D Stacked** and **E Floating Share FAB** (share detached from the row,
  positioned 24px above the bar as an elevated circle, echoing 027's buy-box share placement).
  Also applied the width-match fix globally: `.cta-bar-inner` now caps to 1100px and centers,
  matching 027's masthead column, a no-op below 1100px (every real mobile width).
  Feedback: "The floating share is over the image carousel" — the overhang was fixed screen space
  (the bar itself is `position: fixed`), so at some scroll positions it could land directly over
  content scrolled underneath, unlike 027's share icon which lives in normal document flow inside
  one bounded panel.
- **Round 3** — fixed E: pulled the circle back fully inside the bar's own box (no overhang);
  "elevated" now comes from a shadow + contrast ring instead of position, so it can never overlap
  page content above it.
- **Decision** — D (Stacked) picked over the fixed E. A/B/C/E removed from `index.html` (D only).

## What to Look For
- Does the reserve button unambiguously read as the primary action?
- Does the share control still read as reachable and intentional, not an afterthought, despite
  being visually smaller/secondary?
