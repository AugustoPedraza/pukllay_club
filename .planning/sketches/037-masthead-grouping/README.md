---
sketch: 037
name: masthead-grouping
question: "Now that pills sit above the poster (032's winner A), how do pills + photo + compact dot row read as one grouped buy-box unit instead of 3 floating pieces?"
winner: "C"
tags: [detail, mobile, masthead, buybox, grouping, gap-closure]
---

# Sketch 037: Masthead Grouping

## Design Question
UAT gap G-01.2-13 (round 3), against 032's already-shipped "Pills Above, CTA Detached" layout:
"the pills are ok on the position but there are too many like 'floating' stuff: the pills, the
image, the CTA. Also... the margin left and right of the shell isn't the same for all the
components." Plus a separate dot-spacing complaint: "the dots... have too much space between
then. This should a default 3 dots."

The round-3 diagnosis (`.planning/debug/G-01.2-13-mobile-masthead-spacing.md`) found **three
independent causes**, all applied identically across every variant below so this sketch isolates
just the one real open question — the grouping container:

1. Dot touch-target math (44px hit box, 8px mark) makes the row read 5x wider than its declared
   gap — fixed here via a 22×32px hit box + tighter negative-margin compression, mark stays
   comfortably tappable.
2. The facts row, poster panel, and CTA share no visual container today.
3. `.pk-poster-panel`'s own 1rem padding puts the photo 16px further from the shell edge than its
   siblings — fixed here (all pills/photo/dots sit inside one `gutter-ref` reference column).

**CTA placement is deliberately NOT re-opened** — 032 already settled "Reservar detached, below
the group" against UAT test 7 (passed) and is preserved identically in all three variants here.

## Grounding
Mobile-only (390px frame) since this is exclusively a mobile bug. Real classes referenced:
`.pk-facts-row`/`.pk-fact`, `.pk-poster-panel`, `.pk-gallery-dots`/`.pk-gallery-dot`, share control
corner anchor (`.pk-poster-frame`, sketch 032). Sample content continued from sketch 032/033/034.

## How to View
open .planning/sketches/037-masthead-grouping/index.html

The red dashed lines mark the shell gutter (14px, the app's own `--pk-gutter` value at ≤480px) —
every real edge (pills, photo, dots, CTA) should land flush against it in all three variants; that
part isn't a variant question, it's a shared fix. Toggle 🌙/☀ to check both themes.

## Winner: C — Proximity Only, No Shared Container
No shared background/border at all; grouping comes purely from tightened vertical rhythm +
aligned edges (minimal diff from production — the poster photo keeps its own light border+shadow,
same as sketch 027's panel treatment, but pills and dots stay bare). Picked directly, no revision
requested.

## Round history
- **Round 1** — three grouping treatments explored: **A Extended Panel** (`.pk-poster-panel`'s
  existing bordered/shadowed treatment wraps the facts row too); **B Shared Background Band, No
  Border** (a soft tinted band behind pills+photo+dots, no hard border/shadow); **C Proximity
  Only, No Shared Container** (no shared container at all — grouping from rhythm + alignment
  alone). C picked directly. A/B removed from `index.html` (C only).

## What to Look For
- Do pills + photo + dots now read as one deliberate unit, or still as separate pieces?
- Does the CTA read clearly as *outside* that unit (per 032)?
- Is the compact dot row (3 marks, tight spacing) actually easier to read as "3 photos" than the
  current spread-out version?
- Do all edges (pills, photo corners, dot row, CTA) land flush against the dashed gutter lines?
