---
sketch: 052
name: about-mobile-cta-alternatives
question: "Does an alternative treatment of the mobile sticky 'Sumate' CTA bar fix the 'weird' feel the developer flagged in UAT, and if so which one?"
winner: "B — Floating compact pill (no bar surface, elevated shadow, button sized to its own content)"
tags: [about, cta, mobile, sticky-bar, gap-closure]
---

# Sketch 052: Mobile Sticky CTA Alternatives

## Design Question
Phase 01.5's end-of-phase UAT (test 18) flagged the mobile sticky "Sumate" bar as "weird" and
asked for alternatives. The shipped bar (`.pk-about-cta-bar`, `assets/css/app.css:2655`) is a
full-width fixed bottom strip containing the shared `.pk-sumate-btn` — an OUTLINE pill — stretched
`width: 100%`. Three directions, all reusing the real button geometry (min-height 48px,
padding-inline 28px, radius 9999px):

- **A: Solid filled** — same full-width bar, button switches from outline to a solid
  primary-filled pill. More visual weight/commitment for a persistent bottom CTA than an outline
  button gives.
- **B: Floating compact pill** — no bar surface at all. Just the button, elevated with a shadow,
  sized to its own content instead of stretched full width. Page content stays visible around it.
- **C: Label + compact button** — bar kept full width, but pairs a short context line
  ("¿Te sumás al club?") with a compact (not stretched) solid button — reads like a native app
  bottom bar (context + action) instead of one button spanning the screen.

A fourth tab, "Today (current)", reproduces the exact shipped bar for direct comparison.

## How to View
```
open .planning/sketches/052-about-mobile-cta-alternatives/index.html
```
(File-protocol previews are blocked in some browser setups — if it opens blank, serve the
`.planning/sketches/` directory with any static file server and open it over `http://`.)

Toggle 🌙/☀ in the bottom-right toolbar to check both themes. Each frame is independently
scrollable — the bar always stays pinned to the frame's own bottom edge, mirroring the real
`position: fixed` bar's relationship to page content.

## Winner: B — Floating Compact Pill
Picked directly, no revision. The bar surface (background + border-top) is dropped entirely; the
"Sumate" button floats near the bottom of the viewport, sized to its own content (not stretched)
with a `box-shadow: var(--shadow-lg)` giving it elevation instead of a hairline border. Today
(reference), A, and C stay in `index.html` for the record but are no longer the selected
direction.

## Variants
- **Today** — shipped reference: full-width outline pill.
- **A: Solid filled** — full-width bar, filled button.
- **B: Floating compact pill ★ Selected** — no bar, elevated floating button.
- **C: Label + compact button** — full-width bar, text + compact button.

## What to Look For
- Does the filled button (A) read as more "committed"/higher-weight than today's outline, or does
  it just look heavier without feeling different?
- Does dropping the bar surface (B) feel more modern, or does it lose the "always-there" toolbar
  affordance the full-width bar gives today?
- Does the label in C add useful context, or is it redundant given the page already established
  "Sumate" as the join CTA at the hero and in Cierre above it?
- Check all three against the Cierre band directly above them (heading + tagline) — this sketch's
  scroll frame reproduces phase 01.5's other open UAT gaps (tagline grouping, band/footer
  contrast) only as static content, not as part of this sketch's own design question.
