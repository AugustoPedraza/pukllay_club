---
sketch: 053
name: about-mobile-cta-bar-footer-clearance
question: "Sketch 052 winner B (content-sized floating pill) was rejected on real-device UAT — it overlays the footer's 'Powered by BGG' line at the real scrolled page bottom. What full-width, still-floating alternative, following an industry-standard mobile sticky-CTA pattern, stays clear of the footer AND stays visible the whole time (no disappearing near the footer)?"
winner: "D (refined) — Hero-Synced Full-Width Bar, always visible once shown, with reserved footer clearance instead of an auto-hide"
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

Four directions were first sketched, all reusing the real `.pk-sumate-btn` geometry (48px height,
28px inline padding, pill radius) stretched to fill their bar:

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
  D-03) instead of a footer-proximity check. Originally paired with an auto-hide-near-footer leg
  like A/B.

## Winner: D (refined) — Hero-Synced, Always Visible + Reserved Footer Clearance
Picked directly, then refined twice after selection:

1. **First pass:** tightened the footer-hide trigger to fire with lead time (a `rootMargin`-based
   `IntersectionObserver` sized to the bar's live height) instead of reacting only once the footer
   was already visible.
2. **Second pass (this version):** dropped the footer-hide behavior entirely — user wants the bar
   **always visible** once it's appeared, never disappearing near the footer. Synthesizes D's
   entry trigger (hidden until the hero's own Sumate scrolls out of view) with **C's** mechanism
   for the footer (a reserved, live-measured clearance below the footer, sized to the bar's own
   height — the same shape as the real production `body:has(.pk-about-cta-bar)` document-end
   padding) instead of C's "always on from page load" — the bar still only appears after the hero,
   it just never goes away again once shown.

Also fixed: an earlier draft of this sketch included a generic "empty canvas below a short
footer" filler div, mimicking unrelated site-wide behavior (G-01.5-9 Cause A) that doesn't apply
to `/quienes-somos` — that page is proven always taller than the viewport (G-01.5-9's own
diagnosis), so its footer sits at the true scroll end with nothing below it. Removed as a
misleading artifact; the sketch's only reserved space now is the bar's own real clearance.

Today/A/B/C removed from `index.html` (D only) but preserved above for the record.

## How to View
```
open .planning/sketches/053-about-mobile-cta-bar-footer-clearance/index.html
```
(File-protocol previews are blocked in some browser setups — if it opens blank, serve the
`.planning/sketches/` directory with any static file server and open it over `http://`.)

Scroll the phone frame (320×620) down past the hero — the bar slides in and **stays** visible for
the rest of the scroll, including at the true bottom, where "Powered by BGG" keeps clearance above
it (flagged green as "FOOTER LIBRE ✓"). Scroll back up past the hero and the bar slides back out.
Toggle the theme selector in the bottom-right toolbar to check both themes.

## What to Look For
- Bar stays fully absent through the whole hero, then slides in cleanly the moment the hero's own
  "Sumate" scrolls past the top of the frame — and never disappears again below that point.
- Scrolling to the very bottom: the bar is still there, full width, and the footer's "Powered by
  BGG" line has real breathing room above it — no overlap, no vanishing bar, no leftover empty gap.
- Scrolling back up: the bar only ever disappears at the hero threshold, nowhere else.
