---
sketch: 042
name: editorial-tags-divider
question: "Where do editorial hashtag pills sit relative to the description and the ficha-técnica divider, and does that divider still earn its place?"
winner: null
tags: [detail, editorial-tags, divider, gap-closure]
---

# Sketch 042: Editorial Tags & Divider

## Design Question
Phase 01.3 UAT gap G-01.3-1's original complaint: editorial hashtags (`#DuelosMemorables`-style)
render as a bare, unlabelled pill row today, positioned *after* the divider (between it and
Mecánicas). User's suggestion: give it a real "category section," or move it before the divider.
Also open since sketch 040 dropped "Sobre el juego"'s own heading: does the divider still earn its
place, now that this reading column increasingly relies on small labels + rhythm instead of dividing
lines?

Builds directly on 039/040/041 — the fact grid below uses the settled outline pill tone; Comunidad
BGG is the finalized plain-text treatment.

## How to View
open .planning/sketches/042-editorial-tags-divider/index.html

## Variants
- **A: Move Before Divider, Still Bare** — minimal diff from today: tags move up to sit right after
  the description (matching the user's literal suggestion), divider stays where it is, tags keep no
  label.
- **B: Labelled "Categorías," No Divider** — tags get a small `dt`-style label (same treatment as
  every fact in the grid below), and the divider is dropped — the label itself does the "new zone"
  signalling.
- **C: Folded Into the Fact Grid** — goes one step further than 040's own merge: "Categorías" becomes
  one more fact cell inside the same grid as Diseñadores/Ilustradores/Mecánicas/Temáticas (keeping
  its distinct accent pill tone, since it's still a curated category, not a structured fact) — no
  divider, one section for everything about the game.

## What to Look For
- A vs. B vs. C: does the editorial-tags row need its own visual identity (label, position) at all,
  or does it read fine folded all the way into the fact grid?
- Does removing the divider (B/C) lose a boundary the page actually needs, or does 040's own logic
  ("headings/dividers are redundant once labels + rhythm do the work") hold up here too?
- C in particular: does mixing a curated-tag cell into a grid of otherwise-structured facts
  (Año/Diseñadores/Mecánicas) read as inconsistent, or does the accent-vs-outline tone contrast
  already do enough to keep them distinguishable?
