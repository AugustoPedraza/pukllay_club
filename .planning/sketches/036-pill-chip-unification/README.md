---
sketch: 036
name: pill-chip-unification
question: "What single base pill/chip shape (with tone/size/interactive variants) can represent facts pills, Mecánicas/Temáticas chips, editorial hashtags, active-filter chips, and filter-modal chips consistently?"
winner: null
tags: [detail, catalog, pills, chips, design-system, gap-closure]
---

# Sketch 036: Pill/Chip Unification

## Design Question
UAT gap G-01.2-15 (round 3): "Why there is a kind of pill for diffulty, time and # of players,
but then there are another kind of pills for mecanicas, temáticas? What about the pills used for
'busqueda activa'? and then the used on the filter modal? We need 1 representation and its
variants."

The round-3 diagnosis (`.planning/debug/G-01.2-15-pill-chip-design-inconsistency.md`) confirmed
**five independently hand-tuned implementations exist today with no shared base**:

1. `.pk-fact` (`GamePreview.facts_row`) — fully custom, 9999px radius, `4px 9px` padding, 11px/600.
2. `.pk-chip-row .badge` (`GameChips.chip_row`, Mecánicas/Temáticas) — daisyUI `.badge` + a
   color-only override; its own code comment says it was meant to join `.pk-fact`'s "visual
   family" but the geometry was never actually unified.
3. Bare `.badge.badge-sm.badge-accent` (`GameChips.editorial_tags`) — stock daisyUI, no override.
4. `.pk-active-filter-chip` (catalog "búsqueda activa") — fully custom; its own comment explicitly
   says this must never merge with the modal's chip — but the *component*, not the removable
   affordance, is what this sketch proposes merging.
5. `filter_modal.ex`'s `chip_class/1` — pure daisyUI utility classes, `min-h-11` (44px touch
   target) — the only family already sized for real tapping.

This sketch directly feeds the decision checkpoint in gap-closure plan `01.2-26` (D1 base
geometry, D2 tone variants, D3 size variants) — picking a variant here answers that checkpoint
before `/gsd-execute-phase` reaches it.

## Grounding
Real component/class names throughout: `.pk-fact`, `.pk-chip-row .badge`, `.badge-accent`,
`.pk-active-filter-chip` (+`.pk-active-filter-chip-x`), `filter_modal.ex`'s `chip_class/1`
(`min-h-11`, `badge-primary`/`badge-neutral badge-outline`). All six real sections from production
are shown together in every variant so the comparison is honest, not cherry-picked. Sample content
(mecánicas/temáticas/editorial tags) continued from sketches 005/032/034.

## How to View
open .planning/sketches/036-pill-chip-unification/index.html

Toggle 🌙/☀ in the bottom-right toolbar — chip contrast is exactly the kind of thing that can look
fine in one theme and wash out in the other (sketch 033's real lightbox bug in this codebase).

## Variants
- **A: One Universal Shape** — identical radius/border/padding/font for every role; only
  background/border color changes by tone. Simplest mental model. Risk: the "búsqueda activa" and
  filter-modal chips shrink to info-pill size, below the 44px touch target `chip_class/1` already
  guarantees today — may read as a functional regression on tap-heavy surfaces.
- **B: Two Sizes by Interactivity** — informational pills (facts, Mecánicas/Temáticas, editorial)
  stay compact; interactive pills (removable filters, modal facets) get a real 44px touch target.
  Same shape language (radius, border weight, font family) across both — only padding/min-height
  differ by role.
- **C: Three Tiers by Prominence** — info tier quietest, a distinct "topic" tier for
  Mecánicas/Temáticas (slightly bolder, its own visible identity instead of borrowing the facts
  pill verbatim), and an "action" tier for anything tappable (boldest, hover-lift, 44px target).

## What to Look For
- Do the five real sections still each read correctly for what they *are* (info vs. topic vs.
  interactive), or does unifying them make everything look the same regardless of role?
- Does the "búsqueda activa" removable chip and the filter-modal selectable chip now look like
  members of one family, while staying visually distinguishable from each other (✕ vs. plain
  label) — resolving the "never merge" comment without literally merging the two affordances?
- At the sizes shown, does anything feel too small to comfortably tap, or too heavy for a purely
  informational pill (facts row)?
- Which direction, if any, feeds D1/D2/D3 in plan `01.2-26` most directly — or is a synthesis of
  two variants the real answer?
