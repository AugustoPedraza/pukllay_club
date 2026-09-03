---
sketch: 045
name: about-header-scroll-isologo
question: "Should the About page header be hidden until scroll (landing-page style) or stay always-present like the rest of the site, and how should the isologo entrance feel?"
winner: "A3 — 180px hero mark, true scroll-linked pin"
tags: [about, header, motion, isologo, ludoteca-link]
---

# Sketch 045: About Header Scroll + Isologo

## Design Question
The developer wants a scroll-triggered header on the About page — hidden at rest, with an
animated isologo reveal above "Conectá jugando" — plus a clear link back to the Ludoteca
(catalog). This diverges from the rest of the site's header, which is always-visible/sticky with
a scroll-tint (`.pk-header-sticky`, `.CatalogNav` hook, 40px threshold). This sketch explores how
much that divergence should be.

## How to View
```
open .planning/sketches/045-about-header-scroll-isologo/index.html
```

## Variants (Round 1 — since superseded)
- **A: Landing Reveal** — Header fully hidden at rest, fades+slides in past a fixed 70%-of-hero scroll threshold. **Winner of Round 1**, refined below.
- **B: Quiet Persistent** — header always visible, only the isologo animates. Rejected — most divergent from the rest of the site was actually preferred (A), not this.
- **C: Combined + Shimmer** — A + a one-time shimmer. Superseded by Round 2/3's real mechanic.

## Round 2 — corrected mechanic + size exploration
Developer feedback on Round 1: the isologo entrance must be a delayed **automatic** animation on load, not scroll-triggered — and on scroll, that SAME mark (not two separate ones) should morph/jump into becoming the header's compact mark. Rebuilt as a single reused `#morph-mark` element. Explored three hero sizes: **A1 (96px)**, **A2 (140px)**, **A3 (180px)**.

Round 2's first build had a real bug: three separate mark `<img>`s existed simultaneously outside their hidden tab containers, so inactive tabs' marks computed position from a `display:none` (zero-size) hero, producing a stray fragment at top-left plus three overlapping glow animations (the reported "grey shadow that disappears"). Fixed by using one singleton mark element, reconfigured per active tab, positioned via `getBoundingClientRect()` against the *currently visible* hero/header only.

**A3 (180px) picked** for hero size.

## Round 3 — true scroll-linked pin
Further feedback: a fixed "jump past N% scroll" threshold felt wrong — the mark should ride WITH the page 1:1 (full size, no easing) exactly like normal content, and only animate into the header at the precise moment it would scroll behind it (and reverse at that same crossing point scrolling back up). Reimplemented: every scroll frame compares the mark's natural in-flow position (derived live from the hero section's own `getBoundingClientRect()`, which already tracks scroll 1:1) against the header's dock target. Below the crossing point: live positional tracking, no CSS transition. At the crossing point: the one eased "become the header" / "rejoin the page" snap, both directions.

**Confirmed acceptable for a sketch as-is** (2026-09-02) — exact pixel alignment into the real header's brand-slot is flagged as implementation detail, not a sketch-level concern.

## How to View
```
open .planning/sketches/045-about-header-scroll-isologo/index.html
```
Opens on A3 (180px, the picked size). A1/A2 remain navigable via the tab bar for size comparison — reload the page when switching tabs for a clean scroll-state read.

## What to Look For
- The mark should be invisible on load, then fade+grow in after ~0.5s, unprompted by scroll.
- Scrolling down: the mark should track the page exactly (no lag/easing) until it nears the header, then snap-morph into the compact header mark and reveal the header's wordmark + "Volver a la ludoteca" link.
- Scrolling back up: same behavior in reverse, at the same crossing point, with no repeat of the glow.
