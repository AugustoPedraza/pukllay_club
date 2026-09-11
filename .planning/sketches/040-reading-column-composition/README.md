---
sketch: 040
name: reading-column-composition
question: "Does 039's 'Sobre el juego' / 'Comunidad BGG' hold up once composed with the real Mecánicas/Temáticas/editorial-tags rhythm above it?"
winner: "Sobre el juego absorbs Mecánicas + Temáticas as fact cells, all one pill tone (outline)"
tags: [detail, consistency, reading-column, pills, structure]
---

# Sketch 040: Reading Column Composition

## Design Question
Composed 039's "Sobre el juego"/"Comunidad BGG" into the real reading column order to check balance
against Mecánicas/Temáticas — "how does all that 'details' play balance together."

## Round 1 finding
Production already carries **three** pill tones on this one page: `.pk-pill-accent` (solid fill,
editorial hashtags), `.pk-pill-neutral` (soft fill, Mecánicas/Temáticas), and 039's
`.pk-pill-outline` (fully transparent, Diseñadores/Ilustradores) — a fourth tier with no other user
on the page. Built a toggle to compare 039's outline tone against reusing the existing neutral tone.

**Feedback: "definitely the balance is wrong."**

## Round 2 — resolved
Went further than a tone fix. **Mecánicas and Temáticas are no longer their own top-level
`.section-heading` sections** — they move *inside* "Sobre el juego" as two more `dt`-labelled fact
cells, alongside Año/Diseñadores/Ilustradores, all sharing the same 2-column `.fact-cols` grid
(generalized from 039's `.creators-cols`) and the same `.pill-outline` tone. One section, one pill
tone, for every structured fact about the game. Editorial hashtags stay separate with the solid
`.pk-pill-accent` fill — a curated category, not a structured fact, so it keeps its own visual
identity.

**This is a real structural change from production**, not just a style tweak: today's markup has
Mecánicas and Temáticas as two independent `<h2>` reading-sections *before* "Ficha técnica"/"Sobre el
juego." This sketch merges all of it into one section.

## How to View
open .planning/sketches/040-reading-column-composition/index.html

## Relationship to other sketches
- Supersedes 039's "Sobre el juego" scope — 039's file still stands for its own narrower design
  question (creators/BGG treatment), but the *section boundaries* it assumed (Mecánicas/Temáticas as
  separate sections) are now revised here.
- Does **not** touch editorial-tag placement relative to the divider — that's still open, the next
  sketch in the queue (was going to be numbered 040, now shifts to 041 since this consistency check
  claimed 040).

## What to Look For
- Does one unified "Sobre el juego" section with 4 fact cells (Año spans full width, then
  Diseñadores/Ilustradores/Mecánicas/Temáticas as 2x2) feel like too much in one box, or does the
  shared pill tone make it read as coherent rather than crowded?
- Mobile: 4 stacked fact cells in a row — does that feel like a long scroll before reaching Comunidad
  BGG, or is the rhythm (8px within, pill wrapping) enough to keep it scannable?
- Editorial hashtags (accent, solid fill) directly above this section — does the tone contrast read
  as intentional ("this row is different, it's curated") or jarring?
