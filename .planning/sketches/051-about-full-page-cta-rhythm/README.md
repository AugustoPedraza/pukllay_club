---
sketch: 051
name: about-full-page-cta-rhythm
question: "Do the About page's four CTA touchpoints (hero Sumate, Contacto's WhatsApp/Instagram/Maps, closing-band Sumate, mobile sticky Sumate) read as a well-paced ask across the whole page, or does something feel redundant/crowded — on both desktop and mobile?"
winner: "Round 1 desktop composition confirmed as-is. Round 2: strip Contacto's card chrome below 640px. Round 4 picked B — soft accent-tinted chips (icon + text) for the Contacto links, over A (Sumate-shaped pill) and C (icon avatar + text). Round 5: added Facebook as a third chip alongside WhatsApp/Instagram."
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

## Round 2 — mobile Contacto breaks the rhythm
Feedback after round 1: on mobile, Contacto's CTA breaks the rhythm. Real cause: below 640px
`.two-col` stacks Juntadas and Contacto into one column, removing the side-by-side breathing room
desktop has — Contacto's card (background + padding + boxed icon-link rows + Maps thumbnail)
lands directly above Cierre's Sumate with nothing to separate two heavy asks.

Presented 3 directions; picked **strip the card chrome**: below 640px, `.contact-card` loses its
background/padding/border-radius, and `.contact-links a` loses its boxed background/border in
favor of a plain row with a `border-bottom` divider (last row has none) — same treatment as a
plain link list, not a button. The Maps thumbnail itself is untouched (real functional content,
not decorative box chrome — it wasn't what made the section feel heavy). Verified live: WhatsApp/
Instagram now read as calm supporting rows blending with "Juntadas" text beside them, leaving
"Nos vemos el sábado" as the page's one unambiguous final ask.

**Toolbar fix (found from a user screenshot that showed neither the mobile Contacto fix nor
`.two-col`'s stacking taking effect):** the 📱/📟 buttons used to just set `document.body`'s
`max-width`, which visually narrows the page but does NOT change `window.innerWidth` — so it
can't trigger a real `@media` breakpoint no matter how narrow the body looks. Confirmed via the
reported screenshots (581px/731px images, yet still showing the desktop 2-column grid squeezed
into a narrow column) and by reproducing it live. Fixed properly: the toolbar now loads this
exact same file into a hidden `<iframe>` sized to the literal target pixel width when a device
button is pressed (`#page-root` — everything except the toolbar — swaps out for it). An iframe
has its own independent viewport, so `@media` queries inside it respond to the iframe's real
width regardless of the outer browser window's actual size. Verified live:
`iframe.contentWindow.innerWidth` reads 373px at the 375px button, `.two-col` correctly collapses
to one column, and Contacto's chrome-stripped mobile treatment renders exactly as designed.

## Round 3 — the WhatsApp/Instagram links themselves didn't look right
Feedback after round 2: on both desktop and mobile, the "Grupo de WhatsApp"/"Instagram" rows
still "don't look well" — a separate complaint from round 2's card-chrome/rhythm fix, about the
link treatment itself. Presented 3 directions (icon-only compact chips / solid-tint mini-buttons
/ bare underline links); picked **icon-only compact chips**.

Rather than invent a new component, this borrows the real footer's own `.pk-footer-social a`
treatment verbatim (circle, 1px border, fills solid on hover) — sized 44px instead of the
footer's quiet 28px, since these are primary content-area actions (not secondary footer chrome)
and 44px is this app's own touch-target floor. No visible text label: the intro paragraph above
("Escribinos por el grupo de WhatsApp o por Instagram...") already names both channels in prose,
same reasoning the real footer relies on (`aria-label` only). One unified treatment now covers
both viewports — round 2's separate mobile-only row override is gone; only the card's own
background/padding strip still varies by width. Verified live in both the full window and the
375px iframe preview.

## Round 4 — "pure icons breaks the rhythm", 3 alternatives
Feedback on round 3: the icon-only chips break the page's CTA rhythm — too quiet/footer-like next
to the bold, text-bearing "Sumate" buttons everywhere else. Rather than pick one direction blind,
this round adds a small **local switcher** (A/B/C buttons above the links, scoped only to this
component — not a full-page tab set, since everything else is settled) so all three can be
compared directly:

- **A: Icon + text pill** — same visual grammar as `.btn-sumate` (outline pill, fills solid on
  hover), just sized down. Every CTA on the page now shares one button family.
- **B: Soft tinted chip** — rounded rect, filled with the same accent tint this sketch's own
  `.note` banner already uses. Reads "on brand" without borrowing Sumate's exact join-CTA shape,
  keeping contact and join visually distinct kinds of ask.
- **C: Icon avatar + text beside** — the most literal fix: round 3's circular icon avatar kept
  exactly as-is, with the text label restored beside it, unboxed. Changes nothing about round 3's
  shape/hover mechanic, just adds back what "pure icons" was missing.

All three verified live. **Picked B** (soft chip) — reads as an on-brand, correctly
de-emphasized "different kind of ask" from Sumate without needing to borrow its exact shape. A
and C retired, removed from `index.html`.

## Round 5 — add Facebook
Real `ClubLinks.facebook_url/0` already exists in the codebase (`https://www.facebook.com/pukllayclub/`)
and the real `social_links/1` component already supports a `:facebook` icon — Contacto's real call
site just never included it (`icons={[:whatsapp, :instagram]}`). Added a third `.cl-soft` chip
using the real Facebook glyph path (same SVG the header/footer's own social icons use), and
updated the intro copy to name all three channels. Verified live — three chips wrap cleanly.

## Round 6 — 3 chips must fit one row on mobile
Feedback: make sure the 3 buttons fit on the same row on mobile, not wrap. Measured the real
constraint: below 640px the Contacto card has no side-by-side breathing room (round 2's fix
already strips its own padding), so its available width is just the viewport minus the page's
24px gutters each side — at 375px that's ~327px. Three fully-labeled soft chips
(WhatsApp/Instagram/Facebook, ~123/128/116px each plus gaps) need ~387px — more than fits, so they
would wrap to two lines.

Rather than shrink the label text until it clips, the label drops entirely at this width (inside
the same `@media (max-width: 639px)` block round 2 already added) and the chip becomes icon-only
+ circular — same soft-tint background and hover mechanic as B, just compact. `aria-label` on
each link (added regardless of viewport) keeps the accessible name stable whether the visible
label is showing or not. Verified live at 375px: three circular chips sit comfortably in one row
with room to spare, no wrap.

## What to Look For
- Do the three soft chips (WhatsApp/Instagram/Facebook) read as one coherent row on desktop, or
  does adding a third start to feel crowded?
- On mobile, do the icon-only circular chips still clearly read as WhatsApp/Instagram/Facebook
  (relying on icon recognition alone), or does dropping the label lose too much clarity?
- Do CTA 1 (hero) → CTA 2 (Contacto) → CTA 3 (cierre) → CTA 4 (mobile sticky) feel like a
  deliberate, escalating rhythm down the page, on both desktop and mobile?
- On mobile, does the sticky bar (CTA 4) ever visually compete with CTA 3 sitting right above it
  when the closing band is in view?
- If this ships: the real `Contacto` call site (`about_live.ex`) would need
  `icons={[:whatsapp, :instagram, :facebook]}` added, and the real CSS would need this soft-chip
  treatment (plus its mobile icon-only variant) built as actual classes — no real-app equivalent
  exists yet.
