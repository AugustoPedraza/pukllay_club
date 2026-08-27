---
sketch: 038
name: lightbox-shell-width
question: "Resolve 033's open question: cap the lightbox photo to the shell's content width (not a standalone 90vw/60rem cap) — where do the chevrons sit relative to a narrower image?"
winner: null
tags: [detail, lightbox, desktop, arrows, gap-closure]
---

# Sketch 038: Lightbox Shell Width

## Design Question
UAT gap G-01.2-16 (round 3): "I think for desktop, we should use same width that defined for
shell... the overlay isn't correct, it displays background... when I navigate inside the
lightbox, that must not affect the carousel... on the mobile version, the left arrow looks like
behind the current image."

Sketch 033 already picked the scrim treatment (winner A, Fixed Dark Scrim) but explicitly flagged
one thing as an **unresolved open question, deferred to implementation**: "at desktop widths, with
the image capped to `min(90vw, 42rem)`, the edge-anchored arrows can sit far from the image itself
... not confirmed as correct." That's exactly where the round-3 bug landed — the round-3 diagnosis
(`.planning/debug/G-01.2-16-lightbox-scrim-width-carousel-sync.md`) confirmed the scrim itself
composites correctly (verified pixel-by-pixel across 5 viewports); the actual defect is
`.pk-lightbox-img`'s standalone `min(90vw, 60rem)` cap never reading the shell's own content
width, which is what made the photo look small and "unobscured" in a sea of scrim.

**Not in scope here** (separate code fixes, not visual/design questions): the carousel-sync bug
(lightbox navigation shouldn't move the underlying thumbnail selection) and re-tuning scrim
opacity — the diagnosis proved the scrim is already correct once the photo fills the shell width.

## Grounding
Real values: shell content width (`max-w-7xl` + `--pk-gutter`, same reference box used in sketch
032), `--pk-shadow-color`-based fixed dark scrim (sketch 033 winner), `.pk-lightbox-close`'s
existing z-index pattern extended to both chevrons. Mobile chevron z-index fix (currently painting
behind the image due to DOM order + `z-index:auto`) applied identically in every variant.

## How to View
open .planning/sketches/038-lightbox-shell-width/index.html

Each variant shows both a desktop (~1280px) and mobile (390px) frame stacked, so the arrow
placement can be judged at both extremes at once. Toggle 🌙/☀ to check both themes.

## Variants
- **A: Viewport-Edge Arrows** — today's production behavior, kept as the comparison baseline: the
  photo is now capped to the shell's content width, but arrows stay pinned near the viewport's own
  edges. Shows exactly the gap 033 flagged as unconfirmed.
- **B: Image-Relative Arrows** — arrows anchor to the photo's own bounding box, hugging it at any
  viewport width instead of the viewport edge.
- **C: Arrows Below the Photo** — sidesteps the edge-anchoring question entirely: a compact
  prev / count / next control row sits just under the image, identical treatment at every
  viewport, no left/right edge decision to make.

## What to Look For
- Now that the photo fills the shell's content width, does the scrim read as clearly obscuring the
  page (per 033's already-picked treatment) without any further scrim changes?
- At desktop width, does the arrow-to-photo relationship feel intentional in each variant, or does
  A's gap still read as accidental the way 033 worried it might?
- Does C's below-photo control row feel like a meaningfully different (simpler, more mobile-native)
  interaction, or does it lose the "familiar lightbox chevron" recognizability 033 specifically
  validated?
- On mobile, does the left chevron now clearly sit on top of the image in every variant?
