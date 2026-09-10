---
sketch: 056
name: dark-cta-contrast-fix
question: "The dark-mode outline-primary CTAs (Sumate hero/closing, catalog preview CTA, Reintentar retry) fail WCAG contrast at 2.08-2.34:1 — solid fill everywhere, split by role, or an ink swap like the 17 rules already fixed today?"
winner: null
tags: [dark-mode, contrast, accessibility, wcag, cta, quick-task-260910-gck]
---

# Sketch 056: Dark CTA contrast fix

## Design Question

Quick task 260910-gck found that the site's outline-primary CTA buttons — both "Sumate" placements
(hero, closing band), the catalog card's preview CTA, and the "Reintentar" retry button — all
render `--color-primary` as text+border on a transparent background. In dark mode that measures
2.34:1 against `--color-base-100` and 2.08:1 against `--color-base-200`, both failing the 4.5:1
WCAG AA text floor (and the 3:1 non-text/border floor). The mobile sticky Sumate already solved
this with a solid fill (white on `#8C2BB6`, 6.70:1) — this sketch compares extending that
treatment everywhere, splitting it by role, or reusing the ink-swap mechanism from quick task
260910-efe (shipped hours earlier) on the real affected elements.

## How to View
```
open .planning/sketches/056-dark-cta-contrast-fix/index.html
```

## Variants

- **Overview** — the contrast matrix for the current broken state and all 3 candidate fixes.
- **A: Solid fill everywhere** — all 4 buttons get `background: var(--color-primary)`,
  `color: var(--color-primary-content)` (white), 6.70:1. Same pair already live on the mobile
  sticky Sumate.
- **B: Split by role** — the two Sumate CTAs (the site's actual primary call-to-action) get the
  solid fill; the preview card and Reintentar (genuinely secondary) get an ink-swap to
  `--color-neutral` instead.
- **C1: Ink swap everywhere → neutral** — all 4 stay outline/transparent, text+border swap to
  `--color-neutral` (#B8A6CC, 7.00:1/6.21:1) — the same mechanism/token as the 17 rules fixed in
  quick task 260910-efe.
- **C2: Ink swap everywhere → accent-content** — same mechanism as C1, brighter ink
  (#EBD7F4, 11.63:1/10.32:1).

## What to Look For

- Does the solid fill (A/B) make Sumate feel appropriately prominent as the site's main CTA, or
  does it feel too heavy/loud against the dark ground compared to the lighter outline treatment
  light mode uses?
- Does the ink-swap (C1/C2) make Sumate feel "quiet" in a way that undersells it as the primary
  action — the same muting risk flagged for the 17 secondary rules, but here on the one element
  most meant to stand out?
- Does B's two-treatment split read as intentional hierarchy (primary vs. secondary CTA) or as
  visual inconsistency between the preview card and the Sumate buttons?

## Next Step

Present this sketch to the developer, get a variant pick (or a synthesis), then resume the quick
task 260910-gck executor with the decision to implement Task 3.
