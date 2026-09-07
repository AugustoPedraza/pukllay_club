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
"PUKLLAY CLUB" wordmark and explores three ways that text can accompany the mark through the
scroll.

## How to View
```
open .planning/sketches/050-about-morph-companion-text/index.html
```
Scroll down slowly on each tab to watch the mark travel toward the header and see how its
companion text behaves along the way. Reload (or switch tabs) to reset scroll position — each
tab activation scrolls to top automatically.

## Variants
- **A: Static label, fades early** — "PUKLLAY CLUB" sits directly below the mark at rest as its
  own separate element, then fades out fast (roughly the first third of the scroll) — gone well
  before the mark starts noticeably shrinking.
- **B: Baked-in, travels with the mark** — the text lives inside the same box as the isologo
  image, so it scales and fades in the exact same proportion as the mark shrinks — one piece that
  visually melts into the header's own wordmark as it docks.
- **C: Fixed chip, crossfades at threshold** — a constant-size pill sits beside the mark, staying
  fully legible no matter how small the mark gets, then disappears in one crossfade once the mark
  has covered ~40% of its trip to the header (not a continuous fade).

## What to Look For
- Does the companion text ever compete with, or get orphaned from, the hero's own eyebrow/H1
  copy directly below it?
- Once the header docks and reveals its own real "PUKLLAY CLUB" wordmark, does any variant's
  companion text feel like it's fighting or duplicating that reveal, rather than handing off to
  it?
- At small mark sizes (B), is the shrinking text still legible for long, or does it read as noise
  before it fades — would a different curve or an earlier fade-out serve better?
- Is a *fixed*-size chip (C) that survives the mark's shrink actually more reassuring/legible than
  the other two, or does its independence from the mark's own scale feel disconnected from it?
- Check at 375px (mobile) — does any companion element crowd the hero content or clip at the
  viewport edge?
