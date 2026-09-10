---
sketch: 053
name: about-mobile-cta-bar-footer-clearance
question: "Sketch 052 winner B (content-sized floating pill) was rejected on real-device UAT — it overlays the footer's 'Powered by BGG' line at the real scrolled page bottom. What full-width, still-floating alternative, following an industry-standard mobile sticky-CTA pattern, stays clear of the footer?"
winner: "D — Hero-Synced Full-Width Bar (docked-state trigger, footer clearance tightened with a rootMargin-based lead-time hide)"
tags: [about, cta, mobile, sticky-bar, gap-closure, G-01.5-12]
---

# Sketch 053: Mobile CTA Bar / Footer Clearance

## Design Question
UAT test 19 (phase 01.5, round 3) confirmed G-01.5-8 and G-01.5-10 as fixed, but rejected
G-01.5-11's shipped fix: sketch 052 winner B, a content-sized floating solid pill
(`.pk-about-cta-bar` / `.pk-sumate-btn-solid`, plan 01.5-14), sits at a fixed `bottom: 20px` —
at the real scrolled page bottom that covers the footer's `Powered by BGG` attribution line
(`bgg_attribution/1`, the one element this footer may never hide at any width). User wants a
**full-width** bar that still **floats** (not flush/static against the footer) and referenced
**common industry-standard mobile sticky-CTA patterns** by name.

Four directions were sketched, all reusing the real `.pk-sumate-btn` geometry (48px height, 28px
inline padding, pill radius) stretched to fill their bar:

- **Today (shipped, rejected)** — content-sized pill, `bottom: 20px`, always on. Reproduced only
  for direct comparison, with a live flag that lights up once the pill's rect actually intersects
  "Powered by BGG" while scrolling.
- **A: Auto-Hide Full-Width Bar** — edge-to-edge, solid, hides via a footer-proximity
  `IntersectionObserver` (the e-commerce "Add to Cart"/"Reservar" sticky-bar pattern — Shopify,
  Booking.com).
- **B: Inset Floating Bar** — same auto-hide behavior, but inset/rounded/card-like instead of
  edge-to-edge (the native-app "docked bottom bar" pattern — Uber, Google Maps).
- **C: Static Full-Width Bar + Reserved Clearance** — no JS, bar always visible, footer gets
  permanent bottom padding instead (the pre-052 mechanism, restored to full width).
- **D: Hero-Synced Full-Width Bar** — reuses the page's own **docked-state** scroll trigger (the
  same boolean already driving the isologo-into-header morph and the hero eyebrow's hide/reveal,
  D-03) instead of a footer-proximity check. The bar doesn't exist at all while the hero's own
  Sumate button is on screen; it slides in full-width, solid, the instant that button scrolls out
  of view, and slides back out on scroll-up past the hero — symmetric with the header morph it
  mirrors.

## Winner: D — Hero-Synced Full-Width Bar
Picked directly. Refined once after selection: the footer-hide leg initially only reacted once
the footer was already (partially) visible — tightened to fire with lead time instead, using an
`IntersectionObserver` with a negative bottom `rootMargin` equal to the bar's own **live-measured**
height. That makes "near footer" true the instant the footer's top edge reaches the strip the bar
occupies, so the slide-out animation is already running — and finishes — before the footer could
ever actually be covered, not merely "not overlapping right now". Today/A/B/C removed from
`index.html` (D only) but preserved above for the record.

## How to View
```
open .planning/sketches/053-about-mobile-cta-bar-footer-clearance/index.html
```
(File-protocol previews are blocked in some browser setups — if it opens blank, serve the
`.planning/sketches/` directory with any static file server and open it over `http://`.)

Scroll the phone frame (320×620) down past the hero, to the very bottom, then back up — the bar
should appear/disappear symmetrically at the hero threshold and clear out before the footer
("Powered by BGG", flagged green as "FOOTER LIBRE ✓" the instant it's guaranteed uncovered).
Toggle the theme selector in the bottom-right toolbar to check both themes.

## What to Look For
- Bar stays fully absent through the whole hero, then slides in cleanly the moment the hero's own
  "Sumate" scrolls past the top of the frame.
- Scrolling to the bottom: the green "FOOTER LIBRE ✓" badge lights up as soon as the footer starts
  entering view — confirming the bar had already cleared before any part of the footer could be
  covered.
- Scrolling back up reverses both triggers symmetrically, matching the real header-morph's own
  reversible behavior.
