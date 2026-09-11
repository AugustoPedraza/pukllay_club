---
sketch: 049
name: about-closing-cta-mobile
question: "Why does the closing band 'kill the rhythm,' and is the mobile CTA/scroll experience actually a problem or already solved?"
winner: "A — single 'Sumate' CTA, no repeated WhatsApp/Instagram icons. Mobile CTA bar and scroll density confirmed already fine as shipped."
tags: [about, cta, mobile, rhythm]
---

# Sketch 049: Closing CTA Rhythm + Mobile Density

## Design Question
The developer flagged the closing "Nos vemos el sábado" band + its CTA as breaking the page's
rhythm, and wants the mobile CTA always visible with content that doesn't require excessive
scrolling.

## Finding: the closing band duplicates Contacto
The live closing band repeats WhatsApp + Instagram buttons that sketch 048's rebuilt Contacto
card (right above it) already owns — by the time a reader reaches the closing band, they've
already seen those same two links once (footer/drawer), possibly twice (Contacto). That
repetition is the likely rhythm-killer, not the band's existence.

## Finding: the mobile CTA bar is already always-visible
`.pk-about-cta-bar` is already `position: fixed; bottom: 0` with no scroll-hide/retract logic —
unlike the per-game reservation bar (`.pk-mobile-cta-bar`, which does retract). It only activates
below 480px today. Nothing here needs fixing on that front unless the breakpoint itself should
widen — flagged as a question, not a bug.

## How to View
```
open .planning/sketches/049-about-closing-cta-mobile/index.html
```

## Winner: A — Single CTA
Replaces the duplicated WhatsApp + Instagram button pair with one "Sumate" CTA (reusing the
hero's own button, same brand element in two places instead of a third social-link repeat).
"Today" (reference) and "B: Fold into Contacto" removed from `index.html` (A only).

**Round 2 fix:** the developer caught that the mobile sticky CTA bar stretches `.closing-cta` to
`width: 100%` but the class never set `justify-content: center` — an `inline-flex` box with no
horizontal justify left-aligns its content by default, so "Sumate" would have sat at the left
edge of the full-width pill instead of centered. Fixed by adding `justify-content: center`, which
also makes zero visual difference on desktop (already centered via the parent's `text-align:
center`, since `inline-flex` is still an inline-level box for outer layout).

## Tab 2 — Mobile CTA + density (both confirmed fine, no changes needed)
A scrollable 375px frame walks every section (hero → photos → Qué hacemos/Historia → FAQ →
Contacto → closing) with the CTA bar pinned at the bottom throughout. Confirmed: the full page's
real scroll length reads fine, and `.pk-about-cta-bar` was already `position: fixed` with no
scroll-hide logic — nothing was actually broken on the mobile-CTA-visibility front.

## What to Look For
The winning state is locked (Tab 1 shows A only). Verify "Sumate" reads centered both in the
desktop closing band and the full-width mobile bar.
