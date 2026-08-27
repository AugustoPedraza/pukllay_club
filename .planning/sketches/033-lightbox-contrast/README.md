---
sketch: 033
name: lightbox-contrast
question: "What backdrop/frame treatment gives the game-detail lightbox real contrast against the page, in both light and dark theme?"
winner: "A"
tags: [detail, lightbox, contrast, overlay, dark-theme, motion, gap-closure]
---

# Sketch 033: Lightbox Contrast

## Design Question
UAT gap G-01.2-11: "the lightbox doesn't contranst with background page." Found while grounding
this sketch in the real code (`assets/css/app.css` `.pk-lightbox` rule, ~line 2895): the backdrop
is `color-mix(in srgb, var(--color-base-content) 55%, transparent)` — it mixes the **text** color
into the scrim, not a background/page color. In light theme `--color-base-content` is `#241238`
(near-black), so the scrim reads as a normal dark dimming overlay. In dark theme
`--color-base-content` is `#F3ECFA` (near-white) — so the "dimming" scrim is actually a pale veil
laid over an already-dark page, the opposite of what a lightbox backdrop is for. This is very
likely the actual root cause of the reported contrast complaint, not just a visual-weight question.

## Grounding
Real markup/classes from `CatalogLive.Show` (`lib/pukllay_club_web/live/catalog_live/show.ex`
~line 575) and `app.css`'s `.pk-lightbox`/`.pk-lightbox-img`/`.pk-lightbox-close` rules (WR-04's
`--pk-shadow-color: rgb(20 8 34)` token — already used by every other floating surface in this app
specifically so shadows/scrims don't invert in dark mode — is the established pattern this sketch
reuses). Sample content reused from sketch 005/032 for continuity.

## How to View
open .planning/sketches/033-lightbox-contrast/index.html

Click "🔍 Ampliar imagen" or a thumbnail to open the lightbox; click outside the image or the ✕ to
close. **Toggle 🌙/☀ in the bottom-right toolbar and reopen the lightbox in both themes** — the
production bug only shows up in dark theme, so a variant that only looks fine in light theme hasn't
actually fixed anything.

## Winner: A — Fixed Dark Scrim
Replaces the buggy token with a fixed dark value (`color-mix(in srgb, #150826 72%, transparent)`,
matching `--pk-shadow-color`'s intent) — same scrim darkness in both themes, closest to what every
other overlay in this app already does.

## Round history
- **Round 1** — three treatments explored: **A Fixed Dark Scrim** (flat fixed-dark fill, matches
  the rest of the app's overlays); **B Frosted Scrim** (lighter dark tint + `backdrop-filter: blur`
  on the page behind); **C Framed Card, Light Scrim** (near-invisible scrim, contrast comes from a
  bordered/shadowed card frame around the image instead). A picked directly.
- **Round 2** — two gaps flagged on the picked winner: (1) the sketch only had a close button, no
  prev/next — production's real lightbox has left/right chevron navigation
  (`btn-circle` buttons in `CatalogLive.Show`) that Round 1's mockup omitted; added `‹`/`›` nav
  buttons (industry-standard placement: absolutely positioned, vertically centered, left/right
  edges) plus `ArrowLeft`/`ArrowRight` keyboard support alongside the existing `Escape`-to-close.
  (2) open/close was an instant `display:none`/`flex` toggle with no transition — switched to
  opacity+visibility+`pointer-events` (the same technique this app's other animated floating
  surfaces already use, since `display` can't transition) with a soft fade + subtle scale-in
  (0.96→1) on the image card, using the app's own `--duration-base`/`--ease-out-soft` tokens
  (sketch 006's validated "Subtle/Soft" motion winner — no overshoot, small amplitude) rather than
  a hand-picked timing value. B/C removed from `index.html` (A only, refined).

## What to Look For
- In dark theme specifically: does the image clearly separate from the page behind it?
- Does the open/close transition feel soft and quick, not sluggish or bouncy — consistent with the
  rest of the app's restrained motion language?
- Do the prev/next controls read as familiar, standard lightbox navigation (placement, hover
  state, keyboard arrows)?
