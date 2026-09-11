---
sketch: 046
name: about-photo-rail-mobile-hero
question: "What should the auto-advancing photo rail feel like, and how should the mobile hero's tagline wrap/read against the headline?"
winner: "A (Autoplay Crossfade+Snap) + tagline: 'Volvé a jugar. Volvé a encontrarte.'"
tags: [about, carousel, hero, mobile, motion]
---

# Sketch 046: Photo Rail Autoplay + Mobile Hero

## Design Question
Two related but separate asks from the developer: (1) the About page's photo rail (currently
manual swipe/click only, via the shipped `.AboutCarousel` hook) should auto-advance subtly, and
(2) on mobile, "Nos juntamos todos los sábados a jugar." should wrap to exactly two centered
lines matching "Conectá jugando"'s width, with alternate tagline copy explored.

**No real club photography exists yet** — this sketch (and the shipped page) uses labeled
placeholder blocks. Sourcing/shooting real photos is a separate to-do the developer owns, not
something a mockup can resolve.

## How to View
```
open .planning/sketches/046-about-photo-rail-mobile-hero/index.html
```

## Variants (carousel autoplay)
- **A: Autoplay Crossfade+Snap** — **Winner.** Extends the shipped scroll-snap carousel with a 4s auto-advance timer, reusing the existing pause-on-hover/touch logic. No zoom, clean snap.
- **B: Continuous Drift** — Rejected without much discussion. Slow 28s ambient horizontal loop, no dots.
- **C: Ken Burns + Interval** — Rejected. Same auto-advance as A plus a zoom, judged unnecessary once A was picked.

B/C removed from `index.html` (A only).

## Mobile Hero Tagline — 3 rounds
- **Round 1:** "Cada sábado, una mesa nueva te espera." / "Sábados de juego, siempre abiertos a todos." — rejected as "too excited," also asked to drop "sábados" (already covered by the FAQ's "¿Cuándo y dónde?" answer).
- **Round 2:** "Nos juntamos a jugar, todas las semanas." / "Un lugar fijo para juntarse a jugar." — asked for something more inspirational instead.
- **Round 3 — winner:** "Volvé a jugar. Volvé a encontrarte." (offered alongside "Un espacio para conectar, jugando." and "Jugar nos junta, semana a semana."), echoing the "Conectá jugando" headline's theme without hype.

The tagline picker UI has been removed from `index.html` — the mobile hero frame now shows the final copy directly.

## What to Look For
- The carousel's 4s auto-advance pace against the page's other motion (sketch 045's scroll-linked header) — should still feel calm, not busy.
- The final tagline "Volvé a jugar. Volvé a encontrarte." reads as 2 lines against "Conectá jugando" at the shared mobile width.
