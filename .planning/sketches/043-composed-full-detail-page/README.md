---
sketch: 043
name: composed-full-detail-page
question: "Does the full game detail page (masthead, buybox, lightbox, reading column) still hold together once all of 027, 028, 032, 033, 037, 038, and 039-042's independently-validated winners are composed into one real page?"
winner: "single composed view — consistency check. Real drift found and fixed (lightbox width/arrow-anchor mismatch, desktop-vs-mobile CTA duplication). One issue found and NOT fixed here — see below."
tags: [detail, consistency, masthead, buybox, lightbox, reading-column, gap-closure]
---

# Sketch 043: Composed Full Detail Page

## Design Question

The full game detail page hasn't been composed-checked since sketch 011 — which predates all of
027-042 (sixteen detail-page-specific sketches, each validated independently against its own
narrow slice: buybox boundary, mobile CTA balance, active-filter chips *(catalog, not detail)*,
connection-lost banner *(shared)*, similar-games fallback, masthead facts placement, lightbox
contrast, chip cleanup, detail-page rhythm, pill/chip unification, masthead grouping, lightbox
shell-width, ficha-técnica creators, reading-column composition, pill-outline spread, editorial
tags & divider). This is the same situation sketches 007 and 026 existed to catch on the catalog
side: independently-good decisions can still collide once actually assembled.

## How to View
open .planning/sketches/043-composed-full-detail-page/index.html — click the poster to test the
lightbox, click "…⌄" to test the description toggle, toggle 🌙/☀ for both themes.

## What Was Composed

- **Masthead:** 032's grid (facts row above the poster panel, CTA detached below it) + 037's
  refinement (proximity-only grouping, no shared container, tightened dot-row tap target via
  negative margin).
- **Buybox boundary:** 027's elevated-shadow panel treatment (confirmed already consistent with
  032's own panel styling — no conflict there).
- **Mobile CTA:** 028's stacked bar (Reservar full-width, Compartir as a secondary outline pill
  below it), fixed to the bottom of the mobile frame.
- **Lightbox:** 033's fixed dark scrim + chevron nav + fade/scale transition, composed with 038's
  shell-width fix.
- **Reading column:** 039-042's final state verbatim — Año/Diseñadores/Ilustradores/Mecánicas/
  Temáticas as one shared fact grid on `.pill-outline`, no divider, no "Sobre el juego" heading,
  editorial hashtags right after the title, justified description with the real inline "…⌄" toggle
  from 042's Variant E.

## Real Drift Found (and Fixed)

1. **Lightbox width vs. its own arrow-anchor fix.** 033's own CSS still capped
   `.pk-lightbox-img-wrap` at a standalone `min(90vw, 42rem)` — the exact thing 038 diagnosed as the
   real cause of "no contrast" (image narrower than the page's content column, so viewport-edge
   arrows sat far from a small image). 038's fix targeted the *arrows*' anchor point, but 033's own
   width rule was never actually updated to match — composing them together surfaced that the two
   sketches' CSS had silently diverged. Fixed here: the wrap is now capped to the shell's real
   content width (`calc(1280px - 4rem)`, matching `.pk-shell-wrap`), not an independent guess.
2. **Lightbox arrows anchored to the viewport, not the image.** 033's shipped markup kept
   `.pk-lightbox-nav` as a sibling of the wrap inside `.pk-lightbox` (positioned relative to the
   full-viewport backdrop), even though 038's own README says arrows should track the image's own
   box. Moved them to be children of `.pk-lightbox-img-wrap` so they move with the width fix
   automatically — this closes the exact gap that let them drift out of sync in the first place.
3. **Desktop CTA vs. mobile CTA bar would have doubled up.** 032 keeps a standalone CTA under the
   sticky poster column (desktop); 028 puts a *different*, fixed-bottom stacked CTA bar on mobile.
   Composed naively, mobile would show both. Scoped 032's standalone CTA to `.frame.desktop` only —
   an explicit choice this consistency check exists to catch, not something either source sketch
   would have flagged on its own since each only ever looked at one breakpoint's CTA in isolation.

## Real Issue Found, NOT Fixed Here (deferred, same reason as 042 round 27)

**The float-trick chevron technique can cut off mid-word**, depending on exact container width and
content length. 042's own demo happened to land on a clean word boundary at its 700px desktop
frame; at this sketch's 760px frame the same text clips mid-word ("...expulsar a l...` — the real
text continues "los invasores", but `max-height: 72px; overflow: hidden` has no native ellipsis
mechanism (unlike `-webkit-line-clamp` + `text-overflow: ellipsis`, which the float trick can't use
— see 042's own round-20 finding on why), so wherever the hard pixel cutoff lands, it lands,
mid-glyph if necessary. Confirmed this reproduces at the mobile frame too ("...combinando pode..."). This is a
**functional truncation-quality risk**, not just the cosmetic ink-alignment nit from 042 rounds
25-27 — real game descriptions and real card widths in production will not reliably land on word
boundaries. Per the user's explicit call after 042 round 27 ("I don't want to expend more cycles on
this, I'll do it on the final implementation"), this was not chased further here — but it strengthens
that same deferred note: **when implementing, verify the float-trick technique against real
descriptions at the real card width before shipping it, or fall back to a technique with a native
ellipsis (Variant C from 042, `-webkit-line-clamp` + `text-overflow: ellipsis` + a below-text
trigger) if mid-word cuts turn out to be common.**

## What to Look For

- Does the masthead/buybox/reading-column rhythm read as one coherent page, or do any of the
  independently-tuned spacing values (032/037's masthead rhythm vs. 034/035's reading-column
  rhythm) fight each other now that they're adjacent?
- Lightbox: does it feel anchored to the poster now, at both viewports?
- Mobile: does the fixed CTA bar ever visually collide with the BGG section above it, at any
  scroll position?
