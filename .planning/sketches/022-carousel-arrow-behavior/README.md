---
sketch: 022
name: carousel-arrow-behavior
question: "How should the shelf-row prev/next arrows behave across mouse, touch, and hybrid devices — hover-reveal, always-visible, or CSS-gated to pointer-fine devices only?"
winner: "C"
tags: [carousel, arrows, navigation, touch, netflix, mobile]
---

# Sketch 022: Carousel Arrow Behavior

## Design Question
Production's shelf rows (`carousel_row.ex`, validated in 001-D) reveal prev/next arrows only on
`:hover` — a desktop-only affordance. Netflix's own web catalog does the same thing: arrows are a
mouse-user convenience, touch users get pure swipe + edge-fade. Given this app's audience is
explicitly a *casual/new* board-game player (not assumed tech-savvy), is hiding the arrow entirely
on touch the right call, or does it leave first-time mobile users without an obvious "there's more
here" cue beyond the edge-fade?

## Grounding
Reuses 001-D's real rail/card markup and CSS (`.rail-wrap`, `.rail`, `.card`, edge-fade
`::before/::after`) verbatim — this sketch is not re-litigating card or rail visual design, only
the arrow-control layer on top of it. Real shelf titles/subtitles from `01-VOCABULARY.md` (via
001's `SHELVES` data, trimmed to 2 rows since this question doesn't need all 8). Netflix's own
hover-reveal pattern confirmed via research (see MANIFEST/session notes): "Cards are activated by
hover controls... arrows are a mouse-hover convenience" — [UX Planet](https://uxplanet.org/next-episode-the-design-patterns-and-flows-of-netflix-592b63741f89).

## How to View
open .planning/sketches/022-carousel-arrow-behavior/index.html

Use the **"Simular dispositivo táctil"** checkbox to force the no-hover state a real phone already
has natively — it lets you feel the difference in a desktop browser without needing a real touch
device.

## Variants
- **A: Hover-Reveal (current shipped behavior)** — arrows fade in only when the mouse hovers the
  rail. Zero chrome cost, matches Netflix web exactly, but a touch user never sees an arrow at all.
- **B: Always Visible, Subtle** — arrows are always present with a soft background scrim, low
  opacity at rest, full opacity on hover/focus. More chrome on every device, but never invisible —
  a first-time touch user sees an explicit "there's a control here" cue.
- **C: Pointer-Fine-Only (CSS-gated)** — `@media (hover: hover) and (pointer: fine)` removes the
  arrow from the DOM's rendered layout entirely on touch, not just visually — no dead tap target
  sitting invisibly over the rail edge. Functionally identical end-state to A on touch, but touch
  devices pay zero cost (no hidden 44px hit-target eating into swipe area) and the gate is the same
  signal browsers use internally, not a JS guess.

## Winner
**C — Pointer-Fine-Only (CSS-gated).** `@media (hover: hover) and (pointer: fine)` removes the
arrow from the rendered layout entirely on touch, not just visually — no dead 44px tap target
sitting invisibly over the rail edge. Mouse users keep the familiar hover-reveal arrow. A/B removed
from `index.html` (C only); this is now composed together with 023-B/024-A/025-B in sketch 026.

## What to Look For
- On desktop, hover a rail on A vs B vs C — does B's constant presence feel helpful or like visual
  noise next to A/C's clean hover-reveal?
- Toggle "Simular táctil" — A and C both go arrow-less (matching a real phone); does B's still-
  visible arrow read as more usable there, or does it just look like unnecessary chrome once you
  know swipe works?
- On the Mobile viewport preset, does B's arrow ever get in the way of tapping a card near the rail
  edge?
- Given this app's audience may not know board-game catalogs behave like Netflix at all — does the
  edge-fade alone (A/C) communicate "swipe me" clearly enough, or is that an assumption worth
  testing with an even more explicit affordance (peek-next-card, covered in sketch 023, may already
  solve this without arrows at all)?
