---
sketch: 016
name: mobile-nav-scale
question: "Does the current inline-desktop/drawer-mobile header split still hold at today's item count, or is a desktop-scale-ready overflow pattern worth prototyping ahead of future nav growth (Rules Oracle, Club Ops)?"
winner: null
tags: [header, navigation, mobile, responsive, scale]
---

# Sketch 016: Mobile Nav Scale

## Design Question

Sketch 011 already validated a mobile drawer (search + nav links + Filtros trigger) for ≤480px —
this isn't new territory. The open question is narrower: does today's item count (2 nav links +
search + CTA + toggle) still justify the current inline-desktop/drawer-mobile split, or is it
worth prototyping a desktop-scale-ready pattern now, given two more roadmap phases (Rules Oracle,
Club Ops) could add real nav destinations later?

Industry research: hamburger-on-desktop is discouraged when nav is primary and item count is low —
inline stays the default until item count genuinely forces collapse. With 2 links today, expect
this sketch to mostly confirm the current split rather than argue for change.

## How to View
```
open .planning/sketches/016-mobile-nav-scale/index.html
```

## Variants
- **A: Confirm Current Split** — desktop inline, mobile hamburger→drawer (search + nav + CTA),
  reusing sketch 011's already-validated drawer pattern as-is. No redesign, just re-verification.
- **B: Desktop Overflow (scale-ready)** — adds a "⋯" overflow trigger that only appears on desktop
  once nav items exceed what fits inline. A "+2 items" control simulates adding Reglas/Alquileres
  (future Rules Oracle / Club Ops nav destinations) to stress-test the pattern before it's needed.

## What to Look For
- Variant A: switch to 📱 Mobile — does the drawer still feel sufficient at today's item count?
- Variant B: click "+2 items" — does the desktop overflow trigger feel like premature complexity
  for a 4-link nav, or does it hold up cleanly?
- This sketch is lower-stakes than 013–015 — it's a stress-test/confirmation, not expected to
  change what ships now.

## Round 2 (2026-08-22): Refine B's Balance, Keep the Scale Path

Feedback: "B looks better (still need a better balance) and correct distribution, but that
scalability path looks nice." The overflow concept and its growth-simulation are validated; only
its distribution within the row needed work.

- **C: Overflow, Refined Balance** — two changes to B: (1) the "⋯" trigger drops its
  border/background, becoming a bare icon (same no-card direction as sketches 013/014's Round 2
  toggle) so it reads as a peer of the CTA/toggle rather than a separate boxed widget; (2) the
  opened menu is positioned relative to the header row's own content inset
  (`right: var(--space-4)`) instead of relative to the trigger button, so it stays flush with the
  header's true content edge — matching "Sumate" — regardless of which control ends up last in the
  row.

### What to Look For (Round 2)
- Click "+2 items" — does the bare "⋯" trigger now sit in rhythm with the CTA/toggle, or still feel
  bolted on?
- Open the menu — does its right edge line up with the header's own content edge (same line as
  "Sumate")?
