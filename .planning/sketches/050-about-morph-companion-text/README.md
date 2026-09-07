---
sketch: 050
name: about-morph-companion-text
question: "How should a 'PUKLLAY CLUB' companion wordmark behave alongside the About page's floating isologo during its scroll-morph into the header, so the mark is never text-less?"
winner: null
tags: [about, header, motion, isologo, brand-name, wordmark]
---

# Sketch 050: About Morph Companion Text

## Design Question
Backlog todo `2026-09-07-surface-pukllay-club-brand-name-in-content.md`: the site never spells
out "Pukllay Club" as plain text near the isologo mark. Investigation found the header/footer
lockup (`brand_logo/1`) already renders the name as real text everywhere — **except** on the
About page, where the whole header (including that text) stays hidden while the isologo scroll-
morphs down from the hero (sketch 045's approved mechanic), and the hero copy right where the
mark sits ("Club de juegos de mesa · Jujuy" / "Conectá jugando") never says the actual name. A
first-time visitor scrolling About sees a large graphic mark with no text anchor until it docks
into the header.

This sketch does **not** re-litigate 045's morph mechanic (hidden-until-scroll header, live 1:1
tracking, snap-dock at the crossing point — all kept verbatim). It only adds a companion
"PUKLLAY CLUB" wordmark alongside the mark through the scroll.

## How to View
```
open .planning/sketches/050-about-morph-companion-text/index.html
```
Scroll down slowly on each tab to watch the mark travel toward the header and see how its
companion text behaves along the way. Reload (or switch tabs) to reset scroll position — each
tab activation scrolls to top automatically.

## Round 1 — three approaches (superseded)
- **A: Static label, fades early** — text sits below the mark at rest as its own element, fades
  out fast (first third of the scroll).
- **B: Baked-in, travels with the mark** — text lives inside the same box as the isologo image,
  scaling/fading in the exact same proportion as the mark shrinks. **Picked** — feels like one
  piece melting into the header's own wordmark as it docks.
- **C: Fixed chip, crossfades at threshold** — constant-size pill beside the mark, crossfades out
  past ~40% of the scroll travel.

A/C removed from `index.html` (B carried forward only).

## Round 2 — refining B's weight/balance
Feedback on B: render it in the real logo font, with more weight for better balance. Two real
findings while grounding that request:

1. **The shared sketch theme never actually loaded Bebas Neue** — `themes/default.css` only did
   `src: local("Bebas Neue")`, so on any machine without that font installed it silently fell back
   to a generic system sans, which is why the companion text looked thin/wrong. Fixed at the theme
   level (not just this sketch) by adding the real self-hosted `.woff2` as a fallback source,
   referenced via the same relative-path pattern the isologo image already uses. This fixes every
   sketch that renders Bebas Neue, not only this one.
2. **A heavier `font-weight` isn't available** — `assets/css/app.css` explicitly documents that
   Bebas Neue is self-hosted at weight 400 ONLY, and calls out that any heavier value is a silent
   browser-faked bold the codebase deliberately avoids elsewhere. So "more weight" is explored here
   through size, tracking, and composition instead of a fake bold.

Two refinements of B, replacing A/B/C in `index.html`:
- **B1: One line, larger + tighter** — same single-line "PUKLLAY CLUB", bumped size (~30% larger
  relative to the mark) and tighter letter-spacing for a denser, more confident read.
- **B2: Two-line lockup (name + tagline)** — reproduces the header's own real lockup shape (name
  atop a smaller muted tagline) instead of a lone line — more visual mass as a block, matching how
  the header itself achieves presence without touching font-weight.

## What to Look For
- With the real font now loading, does the companion text finally read as "official" — same
  weight/character as the header's own wordmark once it docks?
- B1 vs B2: does the single larger line feel appropriately weighted, or does the two-line lockup's
  extra mass read better against the isologo image (and does it still fit comfortably at 375px)?
- Does the companion text ever compete with, or get orphaned from, the hero's own eyebrow/H1
  copy directly below it?
- Once the header docks and reveals its own real "PUKLLAY CLUB" wordmark, does the companion
  text's fade-out feel like a handoff rather than a competing duplicate?
- Check at 375px (mobile) — does either variant crowd the hero content or clip at the viewport
  edge?
