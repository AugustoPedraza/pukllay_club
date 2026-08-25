---
sketch: 023
name: carousel-scroll-physics
question: "What should the shelf row's scroll physics feel like — proximity snap, free momentum (Netflix's own approach), or mandatory snap — and does the peek-next-card affordance hold across all three?"
winner: "B"
tags: [carousel, motion, touch, scroll-snap, momentum, netflix]
---

# Sketch 023: Carousel Scroll Physics

## Design Question
The highest-risk question in this batch (per the decomposition table) — not how the rail looks,
but how it physically *feels* to drag/flick. Netflix's real row carousel uses free momentum with
**no hard snap**; cards partially crop at the rail edges (peek) as the only scroll affordance. This
app's shelves are shorter (8-10 cards vs. Netflix's 20+), so it's worth testing whether a snap assist
serves this catalog better, or whether matching Netflix's actual (unsnapped) feel is still right.

## Grounding
Reuses 001-D's rail/card markup verbatim. Also fixes a real bug flagged as an open question in
001's own README: diagonal touch scroll could chain a horizontal rail's fling into the page's
vertical scroll — `overscroll-behavior-x: contain` (confirmed as the standard mitigation via
research) is applied to all three variants here. Variant B's arrow-click easing reuses 006-D's
validated soft ease-out curve (`1 - (1-t)^5`, 200ms) rather than the browser's fixed
`scroll-behavior: smooth`, so arrow-driven and touch-driven motion feel like one system, not two.

Research grounding: Netflix's card carousel is "a horizontal ScrollView... with
`scroll-behaviour: smooth`" and no scroll-snap — [Medium/Chanon Roy](https://chanonroy.medium.com/building-a-netflix-style-card-carousel-in-react-native-649afcd8d78e).
CSS scroll-snap `proximity` vs `mandatory` and `overscroll-behavior-x: contain` are documented,
zero-JS-cost platform features — [Sitepoint](https://www.sitepoint.com/scrolldriven-css-in-2026-building-carousels-without-javascript/).

## How to View
open .planning/sketches/023-carousel-scroll-physics/index.html

**Use a laptop trackpad (two-finger horizontal swipe over a rail) or a real phone** to feel the
actual difference — mouse-wheel scrolling alone won't show it. This is real browser physics per
variant, not a JS simulation.

## Variants
- **A: Proximity Snap** — `scroll-snap-type: x proximity`. Only settles to a card boundary if a
  gesture already ended near one; a fling that stops mid-card just stays there. A light "assist,"
  not a hard rule.
- **B: Free Momentum (Netflix's own approach)** — no `scroll-snap-type` at all. Pure native
  momentum on touch/trackpad; arrow clicks use the custom eased scroll described above so the two
  input methods feel consistent with each other.
- **C: Mandatory Snap, Card-by-Card** — `scroll-snap-type: x mandatory`, every gesture (fling or
  arrow click) resolves to an exact card boundary. Most "app-like" and predictable; risk is a fast
  fling feeling like it fights your hand if it snaps back past your intended stop point.

## Winner
**B — Free Momentum (Netflix's own approach).** No `scroll-snap-type` — pure native momentum,
matching Netflix's actual row behavior. Arrow clicks use the custom eased scroll (006-D's soft
ease-out, 200ms) so both input methods feel like one system. A/C removed from `index.html` (B
only); now composed together with 022-C/024-A/025-B in sketch 026.

## What to Look For
- Two-finger swipe a rail hard (fast flick) on A vs C — does C's mandatory snap feel like it's
  "correcting" you, or does it feel satisfying/precise?
- Same fast flick on B — does the lack of any snap feel loose/uncontrolled, or exactly like the
  native feel this whole sketch batch is chasing?
- Click the arrows repeatedly on B — does the custom-eased scroll feel meaningfully different from
  A/C's native `scroll-behavior: smooth`, or is the difference too subtle to matter?
- At the end of any rail — does the partial "peek" card (present in all three, it's a property of
  content width not fitting the container evenly) read as an intentional affordance, or does it feel
  incidental? Worth a dedicated follow-up if peek needs to be deliberately engineered rather than
  left to chance.
- Which variant would you want to use dozens of times a day browsing the real catalog?
