---
sketch: 038
name: lightbox-shell-width
question: "Resolve 033's open question: cap the lightbox photo to the shell's content width (not a standalone 90vw/60rem cap) — where do the chevrons sit relative to a narrower image?"
winner: "Shell-Width-Anchored Arrows (synthesis of round-1 A, corrected boundary)"
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

## Winner: Shell-Width-Anchored Arrows
A, corrected. Round 1's variant A pinned the arrows to the raw browser viewport edge — even after
the photo was capped to shell width, that still looked "weird" (per user feedback) because the
arrows and the photo were measured against two different boundaries. The fix: arrows anchor to
the *same* shell-content-width box the photo is capped to (the dashed-line reference), not the
viewport. At mobile widths the shell width and the viewport width are effectively the same, so
mobile's behavior is unchanged from round 1.

## Round history
- **Round 1** — three approaches explored: **A Viewport-Edge Arrows** (arrows pinned to the raw
  browser viewport edge); **B Image-Relative Arrows** (arrows anchor to the photo's own bounding
  box, hugging it at any width); **C Arrows Below the Photo** (sidesteps edge-anchoring entirely
  with a below-image prev/count/next row). User picked "A, but not viewport — should use the shell
  width." B/C removed from `index.html` (winner only, refined).

## What to Look For
- Now that the photo fills the shell's content width and the arrows are anchored to that same
  boundary, does the arrow-to-photo relationship read as intentional rather than "weird"?
- Does the scrim still read as clearly obscuring the page (per 033's already-picked treatment,
  unchanged here)?
- On mobile, does the left chevron now clearly sit on top of the image (z-index fix)?
