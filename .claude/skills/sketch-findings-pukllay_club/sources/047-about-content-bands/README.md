---
sketch: 047
name: about-content-bands
question: "How should Qué hacemos / Nuestra historia / Juntadas read for someone who doesn't know board-game hobby vocabulary, and how do they cross-link?"
winner: "Developer-authored final copy (not AI-drafted) — see index.html"
tags: [about, copy, content, factual-correction]
---

# Sketch 047: Content Band Copy

## Design Question
The developer flagged the live "Qué hacemos", "Nuestra historia", and "Juntadas" copy as wrong,
and wanted "Qué hacemos" to link into "Juntadas".

## How to View
```
open .planning/sketches/047-about-content-bands/index.html
```

## Process
- **Round 1** (2 AI drafts, A/B): rewrites using only facts already established elsewhere on the page (2024 founding, Saturdays 16hs, Club de Emprendedores, Pukllay = play in Quechua). Superseded — the "2024 founding" fact itself turned out to be wrong.
- **Round 2** (2 AI drafts, A2/B2): corrected per feedback — don't assume the reader knows what "ludoteca" means, it's a *curated selection* not the whole collection, and the real origin is April 2021 (5+ years), with players from across Argentina plus travelers from France, Spain and Portugal. Also caught a live bug: the shipped About page currently reads "Empezamos en 2024," which is factually wrong.
- **Final**: the developer wrote the actual copy directly (given a portable prompt distilling all the above constraints, for use in any Claude session) rather than picking between AI drafts. It's stronger than any AI draft — concrete ("De más de 400 juegos elegimos la selección del día"), and adds a fact neither AI round had: the club represents the province at national events, which is *why* it draws players from across Argentina and international travelers. All draft rounds removed from `index.html`; only the final copy remains.

## ⚠ Flagged for implementation
`lib/pukllay_club_web/live/about_live.ex`'s "Nuestra historia" band currently says "Empezamos en 2024" — this is wrong and must be corrected to April 2021 when this sketch's findings are implemented, independent of any other change in scope.

## What to Look For
The final copy is locked — no further exploration needed for this sketch.
