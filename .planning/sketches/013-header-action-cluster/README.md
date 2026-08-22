---
sketch: 013
name: header-action-cluster
question: "Should the 'Sumate' CTA be persistent on every page, contextual to landing/About only, or persistent-but-visually-demoted off-landing?"
winner: null
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
