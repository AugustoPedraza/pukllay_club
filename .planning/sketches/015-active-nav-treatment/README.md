---
sketch: 015
name: active-nav-treatment
question: "aria-current=\"page\" is emitted on the current page's nav link but only gets a color change today — too subtle. What's a stronger active-state signal?"
winner: null
tags: [header, navigation, active-state, accessibility]
---

# Sketch 015: Active Nav-Link Treatment

## Design Question

Both header call sites (`CatalogLive.Index`, `AboutLive`) already emit `aria-current="page"` on
the current page's link. The CSS consuming it today is color-only plus a thin 2px border-bottom —
developer feedback says it's too subtle to register at a glance.

## How to View
```
open .planning/sketches/015-active-nav-treatment/index.html
```

## Variants
- **A: Underline/Rule (refined)** — same family as today's shipped treatment, turned up: 3px rule
  with vertical offset instead of a thin line hugging the text.
- **B: Pill/Chip Background** — solid primary-color pill behind the active link. Strongest signal;
  reuses the same pill shape as the CTA and filter chips elsewhere in the app.
- **C: Weight + Dot** — heavier font-weight plus a small primary-color dot, no border or fill.
  Quietest option, purely typographic.

## What to Look For
- Click between "Inicio" and "Quiénes Somos" in each variant — which one signals state clearly
  without a stare?
- Does B's pill start to compete visually with the "Sumate" CTA (sketch 013) since both are solid
  primary-color shapes?
