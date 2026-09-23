---
sketch: 070
name: web-destacados
question: "Does the admin Web tab work as ONE job — swapping the featured games — with every other home row behind a header icon?"
winner: "one page — destacada inline + Otras filas (decisions 1–20)"
tags: [admin, web, destacados, rail, home-rows, 01.8.2]
---

# Sketch 070: Web — Destacados

## Design Question
Web restarted from the job (notes/web-ui-redesign.md, decisions 1–6): the page opens on the featured row itself — its
editable name and its games as a rail with a "+" in every gap — and the other home rows move to "Filas del inicio".

## How to View
`python3 -m http.server 8765` from the repo root →
http://127.0.0.1:8765/.planning/sketches/070-web-destacados/index.html

Tools: Tema · Teclado simulado · Juegos en Destacados 0 / 7 (dev data) / 20 (cap).

## Settled (notes/web-ui-redesign.md, decisions 1–20)
Web is ONE page: the **destacada** row edited inline (name → its options sheet, rail with a "+" in every gap, add /
Mover / Quitar with Deshacer) and **Otras filas** listed under it (kind tag + count badge on the tile); ⇅ Ordenar and
+ Nueva fila in the header. Any hand-picked row opens the same page (`‹ Web`). "Destacada" is a role exactly one
hand-picked row holds. App-wide rules that came out of it: **D-19k** (removing from a curated list is not destructive),
**D-19l** (a one-job page may list its siblings below), **D-19m** (kind tag / count badge anatomy).

## What is drawn
- **Web**: title + rows icon; row name (17/600) + pencil → name sheet; context line (position · N de 20); rail of 96px
  covers with a "+" before, between and after every cover. "+" → "¿Qué juego va acá?" (full-height; idle shows "Últimas novedades"; a game already in the row moves). Cover → sheet Ver ficha · Mover · Quitar de la fila (dialog +
  Deshacer). Mover → "¿Dónde va?" with the row drawn without the game. At 20 the "+" dims and a tap explains the cap.
- **Filas del inicio** (`‹ Web`), round 2: two groups — **Destacada** (one row) and **Otras filas** (home order below it; no counts, no hint lines — round 3), 32px apart; ⇅ Ordenar keeps the destacada locked
  in its own group; "+" Nueva fila. A hand-picked row's sheet starts with **Destacar** (the role moves; the old one
  heads the rest; Deshacer); automatic rows never get it; the destacada's sheet has no Ocultar. A row over 20 games
  shows why it can't be destacada.

- **Any hand-picked row** (round 4): Filas → row sheet → Juegos opens it on the same page (`‹ Filas del inicio`),
  no cap, context "Elegida a mano · N juegos". Quitar has no dialog (D-19k); the add sheet opens on "Últimas novedades".

## Measured (375×667, both themes)
Title row → name text 16.8 · name → context 5 · context → covers 16 · cover to cover 44 (= the "+" hit box) · ~2.6
covers visible (2 whole) · rail 1,032px wide at 7 games, 2,852px at 20 · header glyph on the content edge (359) · add and
name sheets end exactly at the 292px keyboard · no horizontal page scroll at 360.
