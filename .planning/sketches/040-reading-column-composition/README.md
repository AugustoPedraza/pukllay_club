---
sketch: 040
name: reading-column-composition
question: "Does 039's 'Sobre el juego' / 'Comunidad BGG' hold up once composed with the real Mecánicas/Temáticas/editorial-tags rhythm above it?"
winner: null
tags: [detail, consistency, reading-column, pills]
---

# Sketch 040: Reading Column Composition

## Design Question
Single composed view (consistency check, not a new design question) — "how does all this 'details'
play balance together with Mecánicas and Temáticas." Renders the full reading column in real
production order (title → description → divider → editorial tags → Mecánicas → Temáticas → 039's
"Sobre el juego" → "Comunidad BGG") using each section's *actual* CSS tone, not an approximation.

## Finding
Production already carries **three** pill tones on this one page: `.pk-pill-accent` (solid fill,
editorial hashtags — heaviest), `.pk-pill-neutral` (soft fill, Mecánicas/Temáticas — medium), and now
`.pk-pill-outline` (fully transparent, 039's Diseñadores/Ilustradores — lightest). 039 introduced a
**fourth tier with no other user on the page**. Whether that's the right call (creators genuinely are
the least "primary" fact in the column) or an unintended inconsistency (creators and
Mecánicas/Temáticas are structurally the same kind of thing — filter-linked, informational, plural
lists — and should probably share one tone) wasn't visible until this composed view.

## How to View
open .planning/sketches/040-reading-column-composition/index.html — use the top toggle to swap the
creator pills between 039's outline tone and the neutral tone Mecánicas/Temáticas already use.

## What to Look For
- With everything on screen together, does 039's outline pill for creators read as intentionally
  quieter (a fourth, lightest tier), or does it look like a rendering bug next to Mecánicas/Temáticas?
- Toggle to "Neutral" — does matching Mecánicas/Temáticas exactly make Diseñadores/Ilustradores blend
  in too much with mechanic/theme chips, losing the "these are people" distinction?
- Does the editorial-tag row (bare, no heading, sitting right after the divider) look right in this
  composed context, or does it foreshadow sketch 040(next)'s actual question — pill placement +
  whether the divider should exist at all? (Not answered here — that's the next sketch in the queue.)
