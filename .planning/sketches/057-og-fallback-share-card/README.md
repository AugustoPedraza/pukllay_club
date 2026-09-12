---
sketch: 057
name: og-fallback-share-card
question: "How should the isologo + wordmark compose on a solid brand-color 1200x630 canvas, and which ramp step should that background be?"
winner: "B (ramp-800 background, isologo-dark.png + wordmark + tagline)"
tags: [seo, share-card, branding, phase-01.8]
---

# Sketch 057: OG Fallback Share Card

## Design Question
Phase 01.8's D-04 locks the composition rule (isologo + "Pukllay Club" wordmark, one deliberately-
composed image, solid brand-color background — never either transparent isologo PNG alone). Two
things are genuinely open: the layout arrangement of mark + wordmark, and which ramp step the
background should be.

## How to View
```
open .planning/sketches/057-og-fallback-share-card/index.html
```

## Variants
- **A: Side-by-side lockup** — isologo left, "PUKLLAY CLUB" wordmark right, both centered as one
  unit. Mirrors the real header's `brand_logo/1` lockup, scaled up.
- **B: Centered stacked** — isologo above, wordmark below, centered as a vertical stack. More of a
  poster/splash-card feel, more vertical breathing room.

Both variants share a background-color swatch picker (ramp-600/700/800/900) so layout and color
can be compared independently. Real assets used: `priv/static/images/isologo-dark.png` (the white
mark — the only isologo variant with contrast against a purple canvas; `isologo-light.png` is dark-
purple, meant for a light background, and disappears here) and the header's own wordmark treatment
(Bebas Neue, uppercase, wide tracking).

## What to Look For
- Does the mark+wordmark read clearly at both the true 1200×630 size and the realistic small preview
  sizes (WhatsApp bubble, X/Twitter card) shown below the canvas?
- Which background ramp step reads best at this larger, text-bearing canvas — ramp-600 (matches the
  per-game og-cards already shipped in plan 01.8-04, for one consistent purple across every social
  preview image site-wide) or a deeper step?

## Decision
**Winner: Variant B (centered stacked), background ramp-800 (#551670)**, with a third line added
beyond the original two-question scope: a tagline under the wordmark reading
"Tu club de juegos de mesa modernos — Jujuy" — developer-requested during review, so the fallback
card also communicates what the club is and where, not just its name. Rendered via a dedicated
`export.html` in this sketch's own font/layout, then composited pixel-for-pixel with Pillow
(isologo-dark.png + the same self-hosted Bebas Neue/Inter fonts, same 190px mark width / 68px
wordmark / 27px tagline / 20px gaps) and exported as WebP — decoded dimensions verified at exactly
1200×630 through the app's own `image`/vix library before landing at
`priv/static/images/og-fallback.webp`.

## Found while grounding this sketch (not this sketch's decision, flagging for the record)
D-07 (already shipped, plan 01.8-04) names the per-game letterbox background as "the site's existing
primary brand color (`--color-primary` / `--pk-ramp-600`)," treating those as interchangeable. As of
the Sep 10 color-ramp redesign (`260910-l7q`) they aren't: dark theme's `--color-primary` is
`--pk-ramp-600` (#8C2AB7); light theme's is actually `--pk-ramp-900` (#45105C). The shipped
`image_pipeline.ex` comment calls #8C2AB7 "the light theme's `--color-primary`," which is backwards
— it's dark's. Nothing visually broke (D-07 named the literal hex, so the shipped per-game cards
match the decision), but the comment's justification is factually wrong and worth a small follow-up
fix independent of this phase.
