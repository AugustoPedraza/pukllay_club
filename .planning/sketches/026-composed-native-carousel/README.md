---
sketch: 026
name: composed-native-carousel
question: "Do the four independently-validated carousel winners (022-C arrows, 023-B physics, 024-A no indicator, 025-B loading) still hold up once composed together on the same real shelves?"
winner: "single composed view"
tags: [consistency, carousel, motion, touch, netflix, mobile]
---

# Sketch 026: Composed Native Carousel

## Design Question
Consistency check, not a new design question — 022, 023, 024, and 025 each isolated one mechanic
(arrow behavior, scroll physics, position indicator, loading feel) to get a clean read on it. This
composes all four winners onto the same real shelves to confirm they don't conflict once combined
(e.g. does the pointer-fine arrow gate interact oddly with the momentum scroll? does the shimmer
skeleton's card width match the momentum rail's card width exactly?).

## Grounding
Built directly from the winner sections of 022 (C), 023 (B), 024 (A), 025 (B) — same CSS values,
same JS logic, no reinterpretation. Two real shelves from 001's `SHELVES` data; one is filterable
(triggers 025-B's shimmer repopulation) to keep the interaction surface focused rather than adding a
filter trigger to every row.

## How to View
open .planning/sketches/026-composed-native-carousel/index.html

- Hover a rail (desktop/mouse) to see the 022-C arrow appear.
- Two-finger trackpad swipe or a real phone to feel 023-B's free-momentum physics.
- Click "🔀 Filtrar por Estrategia" on the first shelf to trigger 025-B's shimmer.
- Toggle "Simular táctil" to force the no-arrow state a real phone already has natively.

## Composed From
- **022-C** — arrows gated to pointer-fine devices only (`@media (hover: hover) and (pointer:
  fine)`), not just visually hidden.
- **023-B** — free momentum scroll (no `scroll-snap-type`), `overscroll-behavior-x: contain`,
  custom-eased arrow-click scroll (006-D's soft ease-out curve, 200ms).
- **024-A** — no position indicator; edge-fade is the only scrollability cue.
- **025-B** — shimmer skeleton scoped to the filter-triggered repopulation moment only (009's
  flat-skeleton decision for full-page/initial loads is unchanged and separate).

## What to Look For
- Does the shimmer skeleton (025-B) sit at the exact same width/position as the real cards once it
  resolves, or is there a layout jump?
- With "Simular táctil" on, does the rail still feel fully usable and discoverable via swipe alone,
  with no arrow at all?
- Click the arrow rapidly several times — does the custom-eased scroll (023-B) still feel smooth
  when interrupted mid-animation by a second click?
- Any visual or behavioral conflict between these four that wasn't visible when each was tested in
  isolation?
