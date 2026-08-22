---
sketch: 013
name: header-action-cluster
question: "Should the 'Sumate' CTA be persistent on every page, contextual to landing/About only, or persistent-but-visually-demoted off-landing?"
winner: "E"
tags: [header, cta, navigation, information-architecture]
---

# Sketch 013: Header Action Cluster (Sumate CTA)

## Design Question

The header's "Sumate" (join) CTA was added during Phase 01.1's real build and was never part of
the validated 003/011 shell sketches — it's genuinely new territory. Developer feedback: it reads
as visually disconnected from the rest of the header cluster. This sketch asks a scope question
first (does it belong everywhere, or only where "join us" is contextually relevant) before a pure
styling question.

## How to View
```
open .planning/sketches/013-header-action-cluster/index.html
```

## Variants
- **A: Persistent Everywhere (current)** — Sumate renders solid/full-weight on Catálogo, Detalle,
  and Acerca de identically. Matches what's shipped today.
- **B: Landing-Only (contextual)** — Sumate only appears on Acerca de; Catálogo and Detalle drop
  it entirely. **Carries an implementation cost**: 01.1-PATTERNS.md's D-05 deliberately hardcodes
  the CTA as non-slot/always-rendered specifically to prevent a page silently omitting it — this
  variant reopens that decision, not just a CSS change.
- **C: Persistent, Demoted Off-Landing** — Sumate always renders (keeps D-05's guarantee intact)
  but is outline/secondary everywhere except Acerca de, where it goes solid/primary.

## What to Look For
- Use each variant's page switcher (Catálogo / Detalle / Acerca de) — does the CTA's presence (or
  visual weight) make sense for what someone's doing on that page?
- On Detalle specifically: does "join the club" compete with someone who's mid-way through reading
  one game's rules?
- Variant B's risk note appears when you switch to Acerca de — read it before picking B.

## Round 2 (2026-08-22): Visual Weight, Not Just Scope

Feedback on A/B/C: "013 still needs better balance and improve the semantics: do we need system
color big and on the top? I think about the same for the navigation and main CTA." Read as: the
scope question (persistent/contextual/demoted) wasn't the whole problem — the cluster still had
*multiple* heavy elements competing at once (solid CTA + colored/underlined active link + boxed
3-way toggle). CTA scope stays **persistent** here (matches the D-05 constraint documented above;
this round doesn't reopen that axis) — the axis shifts to how much visual weight each element
carries.

Two new variants, both keeping CTA scope persistent:

- **D: CTA Sole Accent Weight** — exactly one element in the cluster carries real color/fill:
  "Sumate" stays solid/primary. Nav links drop to plain text (color + weight only, no
  border-bottom). The theme toggle loses its card/border, becoming three bare icon buttons with a
  small underline for the active state — same markup/CSS as sketch 014's Round 2 variant D, so the
  two compose identically into the real header. Brand stays dominant by size, not color.
- **E: Uniform Light Weight** — goes further: the CTA itself drops its solid fill at rest too
  (outline, same weight as the nav links), filling only on hover. Nothing in the cluster outweighs
  anything else at rest; hierarchy comes from position (right-aligned, consistent spacing) rather
  than fill/color/boldness.

### What to Look For (Round 2)
- D: does "Sumate" now read as clearly the one actionable thing, with links/toggle receding around
  it?
- E: does the CTA still read as clickable/important without a permanent solid background, or does
  it need to look more clickable at rest?
- Compare D's toggle directly against sketch 014's Round 2 D — confirm they read as the same
  component in both contexts (they share identical CSS/markup by design).

## Winner: E (2026-08-22)

Picked **E — Uniform Light Weight** after direct comparison against D. A/B/C (Round 1) and D
(Round 2) were removed from the live HTML per explicit request — their full descriptions stay
above for the record, and the complete versions remain recoverable via git history
(`git log -- .planning/sketches/013-header-action-cluster/index.html`).

CTA scope stays **persistent** (matches 01.1-PATTERNS.md's D-05 — this sketch never reopened that
axis, only visual weight). E's flattened-until-hover CTA composes with sketch 014's finalized bare
icon toggle (winner D, further refined to monochromatic in Round 3) and sketch 015's finalized
underline-only active-link treatment (winner A) — see sketch 017 for how all three compose into
one real header.
