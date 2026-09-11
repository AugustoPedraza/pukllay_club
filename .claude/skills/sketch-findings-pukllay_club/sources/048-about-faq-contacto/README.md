---
sketch: 048
name: about-faq-contacto
question: "Should the FAQ band's purple read as a richer/default brand color, and how should Contacto + a Maps link get rebuilt with real icons/links?"
winner: "A (Current/flat) — confirms the live --color-primary value as official, no color change. Width fix + merged Contacto card + mobile layout all confirmed."
tags: [about, faq, contacto, color, maps, width-bug]
---

# Sketch 048: FAQ Band Color + Contacto Rebuild

## Design Question
Three related asks: (1) the FAQ band's purple should feel like "the default color" rather than
an incidental dark band, scoped to the About page for now; (2) the FAQ band (and, root-cause
found below, every content band on the page) doesn't match the shell's content width; (3)
Contacto is currently broken/plain — needs real icons, real working links, and a Google Maps
thumbnail linking out.

## Root cause found: the width bug isn't FAQ-specific
`assets/css/app.css`'s `.pk-band-inner { max-width: 64rem; }` caps EVERY content band on the About
page (Qué hacemos, FAQ, Juntadas/Contacto, closing CTA) at 1024px — narrower than the shell's own
`max-w-7xl` (1280px) used by the header, footer, and the hero section (which sets its own width
manually and doesn't go through `.pk-band-inner`). The fix is a shared-class change (widen
`.pk-band-inner` to 80rem), which corrects every band at once — not a FAQ-only patch.

## How to View
```
open .planning/sketches/048-about-faq-contacto/index.html
```

## Process

**Round 1** — three tabs: width bug+fix, FAQ color (A current-flat / B deep-gradient / C soft-bleed), Contacto+Maps as a 2-column grid (card beside a separate map box). Feedback: the bleed variant's extra padding and the 2-column grid's mismatched proportions "killed the rhythm," and no mobile version existed yet.

**Round 2** — fixes applied:
- FAQ band padding corrected to 72px (`4.5rem`) on all three tone variants, matching the shipped `.pk-band`'s real value instead of an invented 56px.
- Contacto rebuilt as ONE merged card (links + map thumbnail together), not two separate boxes — same "shared edge, no floating pieces" precedent sketch 037 already established for the buy-box.
- Added a 4th tab: 375px mobile preview of both the FAQ band and the Contacto card, stacked.

**Round 3 (final)** — **A (Current/flat)** picked, confirming the FAQ band's existing `--color-primary` value as the official color with no change — B and C removed from `index.html`.

## Winner details
- **Tab 1 — Width fix:** `.pk-band-inner`'s `max-width` goes from `64rem` to `80rem`, matching the shell's `max-w-7xl`. This is a shared-class fix affecting every content band on the page, not FAQ alone.
- **Tab 2 — FAQ color:** unchanged from production (`var(--color-primary)` background, `var(--color-primary-content)` text), now at the corrected 72px rhythm. Pricing FAQ answer: "Reservá tu lugar por $5.000. ¿Venís de sorpresa? Son $7.000 — pero siempre hay lugar para vos." (developer-supplied: $5.000 reserving ahead, $7.000 at the door).
- **Tab 3 — Contacto + Maps:** one card, real WhatsApp/Instagram icons and link pattern (matching the footer's shipped `social_links/1`), plus a map thumbnail linking out. ⚠ No real static map image exists offline — sourcing one (manual screenshot vs. Google Static Maps API, which needs a key and has usage cost) is implementation detail, not resolved here.
- **Tab 4 — Mobile:** both pieces stacked at 375px, same components, tighter padding.

## What to Look For
The winning state is locked (Tab 2 shows A only). Verify the width-fix comparison, the merged Contacto card's proportions, and the mobile stacking read correctly.
