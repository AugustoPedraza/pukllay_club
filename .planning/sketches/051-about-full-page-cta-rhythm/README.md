---
sketch: 051
name: about-full-page-cta-rhythm
question: "Do the About page's four CTA touchpoints (hero Sumate, Contacto's WhatsApp/Instagram/Maps, closing-band Sumate, mobile sticky Sumate) read as a well-paced ask across the whole page, or does something feel redundant/crowded — on both desktop and mobile?"
winner: null
tags: [about, cta, consistency, layout, desktop, mobile]
---

# Sketch 051: About Full-Page CTA Rhythm

## Design Question
Prior sketches validated each CTA touchpoint independently: the Contacto card (048), the closing
band + mobile sticky bar (049, "no changes needed" at the time). This sketch composes the
**entire** About page at real spacing (72px/section, 1280px content width — matching
`app.css`'s `.pk-band`/`.pk-band-inner` exactly) so all four touchpoints can be judged together,
in sequence, on both desktop and mobile — not each in isolation.

The four touchpoints, flagged with small "CTA N" pills in the sketch so they're easy to spot
while scrolling:
1. **Hero** — the "Sumate" button, right below the isologo (sketch 050's current hero, carried
   over verbatim — companion wordmark, in-flow anchor grouping, eyebrow dock-sync).
2. **Contacto** — WhatsApp + Instagram icon links, plus a Maps thumbnail with a "Cómo llegar"
   overlay link (sketch 048's real card).
3. **Cierre** — "Nos vemos el sábado" heading + a second "Sumate" button + an Instagram text
   link (sketch 049's real closing band).
4. **Sticky mobile bar** — a third "Sumate" button, fixed to the bottom of the viewport, only
   ≤480px (same real media-query threshold as production's `.pk-about-cta-bar`).

Photo rail and the live Google Maps embed are simplified placeholders (their own motion/behavior
was already validated in sketches 046/048) — not the point of this sketch.

## How to View
```
open .planning/sketches/051-about-full-page-cta-rhythm/index.html
```
Scroll the whole page top to bottom. Toggle 📱 in the toolbar to check the mobile sticky bar
(it only appears ≤480px, matching the real media query) and to see how tight the rhythm feels on
a small screen where every section is taller relative to the viewport.

## Bugs found while verifying (fixed, not design changes)
Live-verified in a real browser after the initial build surfaced two real defects — both in this
sketch's own scaffolding, not in the four CTAs' actual design:

1. **The debug "CTA N" flag pills were hiding the real buttons.** Positioned `top:8px; left:8px`
   *inside* each marker box, they fully covered the hero/cierre Sumate buttons — those are only
   48px tall, barely bigger than the flag itself, so the flag's opaque fill painted directly over
   the "Sumate" label. Fixed by moving the flags to `bottom:100%` (entirely above the marker,
   never overlapping its content).
2. **The docked isologo mark overlapped the header's own wordmark text** ("PUKLLAY CLUB" showed
   as "…LLAY CLUB", the "PUK" covered). The fake header's `.brand-slot` never reserved a box for
   the mark icon before the text — production's real markup always renders an `<img>` there, but
   this sketch's header only had the text span. Fixed by adding an empty `.mark-slot` (32×32,
   matching `DOCK_SIZE`) as the flex item before `.brand-text`, so the docking mark lands in
   reserved space instead of on top of the letters. **Same fix applied back to sketch 050**
   (`about-morph-companion-text`), which has the identical header markup and the identical latent
   bug — not previously caught because round 5's confirmation didn't zoom into the docked state
   closely enough to notice.

## Live Verification (desktop)
Scrolled through the whole page at desktop width after the fixes above: hero → photo rail →
Qué hacemos/Nuestra historia → dark FAQ → Juntadas/Contacto → Cierre all read as one clean,
well-paced sequence — no visual collision between any two CTA touchpoints, header dock/undock is
clean in both directions. Mobile's sticky bar reuses the exact `max-width:480px` media query
already shipped and validated (sketch 049) — not independently re-toggled in this verification
pass, but the mechanism is unchanged from what's already confirmed working in production.

## What to Look For
- Do CTA 1 (hero) → CTA 2 (Contacto) → CTA 3 (cierre) → CTA 4 (mobile sticky) feel like a
  deliberate, escalating rhythm down the page, or does any pair feel redundant back-to-back?
- On mobile, does the sticky bar (CTA 4) ever visually compete with CTA 3 sitting right above it
  when the closing band is in view?
- Does Contacto's icon-link style (CTA 2) read as a different *kind* of ask than the "Sumate"
  button (CTA 1/3/4), and does that difference make sense (contact vs. join) or feel inconsistent?
- Does the whole page's real length (with the photo rail and FAQ band at full size) make the gap
  between CTA 1 and CTA 2 feel too long, too short, or fine?
- Anything that felt fine in isolation (048, 049) that reads differently now that it's composed
  with everything else?
