# Motion System

## Design Decisions

**The shipped duration/easing tokens were chosen deliberately, not incidentally.** Sketches 001/002
picked 120/220/360ms with a standard ease-in-out while building layout and card interactions — never
as a considered system. Sketch 006 tested that baseline (**A: Minimal/Snappy**) against two
alternatives — **B: Expressive/Springy** (180/320/480ms, back-out overshoot, leans into a
welcoming/teach-the-hobby tone) and **C: Cinematic/Soft** (200/420/620ms, slow soft ease-out, closer
to a premium streaming feel) — then synthesized a fourth option after review.

**Winner: D — Subtle/Soft.** "The animation must be subtle and have a soft transition" — faster than
all three tested options (100/180/280ms, the fastest set), paired with C's no-overshoot soft ease-out
curve (not B's overshoot — reads as unpolished on frequent actions like row-scroll), and a *smaller*
hover-lift amplitude on top of the faster timing: restraint isn't only a timing question, the movement
itself needs to be smaller too.

**This is already the live system, not just a validated proposal.** Applied directly to
`themes/default.css` (both the light palette and the merged dark palette) during a 2026-08-20
consistency pass — confirm any new component reads `var(--duration-fast/base/slow)` and
`var(--ease-standard)`/`var(--ease-out-soft)` rather than hardcoding a timing value, so it inherits
this system automatically instead of drifting from it.

**Real drift found and fixed the same day:** the interactive card's hover-lift
(`.card:hover`/`.poster-card:hover`) was independently declared in three places (001, 002, 007) and
none of them had been updated to D's smaller amplitude — all three still used the pre-006
`translateY(-4px)`. Corrected to `-3px` in all three. (006's own demo baseline of "shared -6px
scale(1.03)" was never something the real component shipped — that number only ever existed inside
006's own comparison demo, so the real correction is -4px → -3px, not -6px → -3px. Don't cite -6px
as a prior value when implementing.)

## CSS Patterns

```css
:root {
  --duration-fast: 100ms;
  --duration-base: 180ms;
  --duration-slow: 280ms;
  --ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-out-soft: cubic-bezier(0.16, 1, 0.3, 1); /* no-overshoot soft ease-out, D's curve */
}

.card:hover, .poster-card:hover {
  transform: translateY(-3px); /* D's validated amplitude — not -4px, not -6px */
  transition: transform var(--duration-base) var(--ease-out-soft);
}
```

Row-scroll (rail arrow clicks) needs a custom `requestAnimationFrame` scroller driven by the same
easing function, not native `scroll-behavior: smooth` — the browser's built-in smooth-scroll has one
fixed curve/duration and can't express a variant's specific overshoot or settle feel. Only relevant if
row-scroll timing is ever revisited; the shipped winner (D) has no overshoot, so this doesn't block
using native smooth-scroll today.

## What to Avoid

- **Don't hardcode timing values in new components** — always reference the `--duration-*`/`--ease-*`
  tokens so a future system-wide tuning pass (like the one 006 did) propagates automatically instead
  of requiring a per-component hunt for hardcoded numbers (exactly what happened with the three
  independently-declared `-4px` hover-lifts).
- **Don't reach for an overshoot/back-out ease on frequent actions** (row-scroll, hover) — variant B's
  "pop" read as unpolished specifically because users trigger these constantly while browsing; save
  expressive motion (if ever used) for rare, celebratory moments, not the browsing loop.
- **Don't assume a slower/cinematic feel matches the Netflix reference point better** — variant C
  (the most literal Netflix-timing match) lost specifically because row-scroll is triggered
  constantly, and its slow settle felt sluggish exactly there, even though it looked good in isolated
  single-trigger tests.

## Origin
Synthesized from sketch: 006
Source file available in: sources/006-motion-system/
