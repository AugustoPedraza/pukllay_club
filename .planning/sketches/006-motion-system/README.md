---
sketch: 006
name: motion-system
question: "Is a dedicated motion system worth it, and what should hover-expand / row-scroll / page-transition / focus transitions feel like?"
winner: "D"
tags: [motion, interaction]
---

# Sketch 006: Motion System

## Design Question
Carried forward as an open item since the very first wrap-up (2026-08-19): the shipped duration/
easing tokens in `themes/default.css` (120/220/360ms, standard cubic-bezier) were chosen
incidentally while building sketches 001/002, never as a deliberate system. This sketch asks the
question directly: does the current minimal/snappy feel serve the brand, or does the poster-forward,
human-first, hobby-teaching direction call for something more expressive?

## Grounding
Uses the real difficulty-dot/pill/card visual language settled in 001/002 for the demo cards (kept
intentionally simplified — no hover-portal, no mobile sheet — since this sketch's only variable is
*timing*, not content, which is already settled). Four demo surfaces per variant, each driven by
CSS custom properties scoped to that variant's root (`--m-dur-fast/base/slow`, `--m-ease`):

1. **Row hover + peek** — hover a card, watch a small info popup ease in above it.
2. **Row-scroll easing** — click the rail arrows. Native `scroll-behavior: smooth` has one fixed
   browser curve/duration and can't express variant B's overshoot or C's slow settle, so this is
   driven by a small custom `requestAnimationFrame` scroller using each variant's own easing
   function — the only way to make the three variants' scroll actually *feel* different from each
   other, not just look different in a demo.
3. **Page-transition feel** — click "Ver detalle" to simulate the catalog→detail hand-off (a
   crossfade/slide, standing in for a real LiveView navigation transition).
4. **Focus-ring transition** — tab through the three chips to feel the keyboard-focus ring's timing.

## How to View
open .planning/sketches/006-motion-system/index.html

## Variants
- **A: Minimal / Snappy** — the timing already implicit in `default.css` today (120/220/360ms,
  standard ease-in-out, no overshoot). Utilitarian, gets out of the way, cheapest to keep as-is.
- **B: Expressive / Springy** — longer (180/320/480ms) with a back-out overshoot ease, so motion has
  a felt "pop." Leans into the brand's welcoming, teach-the-hobby tone rather than a neutral utility
  feel — risk: overshoot can read as unpolished if overused on frequent actions.
- **C: Cinematic / Soft** — slow (200/420/620ms), soft ease-out with no overshoot, closer to a
  premium streaming-service feel (matches the Netflix reference point directly). Risk: may feel
  sluggish specifically on row-scroll, which users will trigger constantly while browsing.

## Winner
**D — Subtle / Soft (synthesis)**, added after reviewing A/B/C: "the animation must be subtle and
have a soft transition" — not A's plain standard ease (not soft enough), not B's overshoot (not
subtle), and faster than C's slow settle (not subtle in duration). D combines the fastest durations
of the three (100/180/280ms) with C's no-overshoot ease-out curve, plus a smaller hover-lift
amplitude (`translateY(-3px)` vs the shared `-6px scale(1.03)`) so restraint isn't only a timing
question — the movement itself is smaller too.

**Applied (2026-08-20, frontier consistency pass):** this winner was validated here but never
actually landed in the shared theme — `themes/default.css`/`dark-purple.css` still carried the
original incidental 120/220/360ms values. Both theme files now use D's validated 100/180/280ms for
`--duration-fast/base/slow`. Since 004's about-carousel and 005's detail-carousel/lightbox already
build their transitions from `var(--duration-*)`/`var(--ease-*)` tokens rather than hardcoded
values, this correction lands on them automatically — no per-file changes needed there. The one
concrete drift found: the real interactive card's hover-lift (`001-shelf-structure`,
`002-card-hierarchy`, `007-composed-catalog-page`, all independently declaring
`.card:hover`/`.poster-card:hover { transform: translateY(-4px); }`) had never been updated to D's
smaller `-3px` amplitude — fixed in all three now. (006's own comparison baseline of "shared -6px
scale(1.03)" was itself never the real component's value — that number only ever existed as this
sketch's own demo-card default, not something 001/002/007 actually shipped — so the real
before/after is -4px → -3px, not -6px → -3px.)

## What to Look For
- Click the row-scroll arrows several times in a row on each variant — does the timing still feel
  good on the 5th click, or does it start to feel like it's fighting your intent to browse quickly?
- Hover several cards in a row (not just one) — does the peek popup's entrance/exit timing feel
  responsive, or does it lag behind your cursor?
- Trigger the page-transition on all three — which one would you want to see dozens of times a day
  browsing the real catalog?
- Is a dedicated system worth the implementation cost at all, or does variant A (already the
  default) mean this is a non-issue and the real tokens don't need to change?
