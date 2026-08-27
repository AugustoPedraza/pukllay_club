---
sketch: 036
name: pill-chip-unification
question: "What single base pill/chip shape (with tone/size/interactive variants) can represent facts pills, Mecánicas/Temáticas chips, editorial hashtags, active-filter chips, and filter-modal chips consistently?"
winner: "A+B Synthesis (flat info pills + always-bordered action chips with tap-press feedback)"
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

## Winner: A+B Synthesis
Purely informational pills (facts, Mecánicas/Temáticas, editorial) render flat — no background, no
border, middot-separated — since nothing happens when you tap them. Interactive chips (removable
active filters, selectable filter-modal facets) keep an **always-visible** 1px border at rest (not
just on hover), a real 44px touch height, and a genuine `:active` tap-press feedback (scale-down +
background flash). This is the industry pattern for signaling tappability with no hover state to
lean on (Material Design's "filter chip", Airbnb's own filter pills) — border-only-at-rest is what
makes something *read* as interactive on a touch device, not chrome for chrome's sake.

## Round history
- **Round 1** — three structural directions explored: **A One Universal Shape** (identical
  geometry for every role, tone-only variation — risked shrinking interactive chips below the
  44px touch target); **B Two Sizes by Interactivity** (compact info pills, 44px interactive
  chips, same shape language); **C Three Tiers by Prominence** (info/topic/action as three visibly
  distinct weights). User picked B, flagged "needs a better balance."
- **Round 2** — closed the size gap (info padding/font bumped up, action's font brought down —
  44px touch height kept, that's an a11y floor not a style choice), gave action chips a resting
  background+border instead of bare transparent, gave info pills more padding, unified radius/
  border-width across both sizes. "Looks better."
- **Round 3** — two polish notes: pill text switched from `--color-text-muted` (read as "default
  gray") to the theme's full `--color-text` (a genuine contrast improvement, not just a look); all
  emoji icons and the editorial `#` hashtag prefix removed — plain label text only.
- **Round 4** — "why does the rounded shape feel like too much padding? what else can be
  minimalistic?" Three fresh directions against a kept Reference (round 3): **A Tight Pill** (same
  capsule, padding roughly halved); **B Flat, No Chrome** (info pills drop all chrome, action keeps
  a minimal outline); **C Low-Radius Chip** (small rounded-rect instead of a full capsule).
- **Round 5** — "how do A and B combine, with real tap affordance, especially mobile — what do
  Netflix/Airbnb do?" Answered with the industry pattern (border-only-at-rest signals tappability
  when there's no hover state; a press/tap feedback state substitutes for the missing hover cue)
  and built **D, the A+B synthesis**: flat info pills (B) + tightly-sized, always-bordered action
  chips (A) + a new `:active` press-feedback. Picked directly as the winner. Reference/A/B/C
  removed from `index.html` (winner only).

## What to Look For
- Do the informational pills (facts/mecánicas/temáticas/editorial) read as clearly non-interactive
  now that they have no chrome at all?
- Do the "búsqueda activa" and filter-modal chips read as clearly tappable at rest (not just on
  hover), and does the tap-press feedback feel responsive rather than laggy?
- Does the whole set still read as one family — same radius, same border weight, same font — with
  size/chrome differing only by whether something is interactive?
