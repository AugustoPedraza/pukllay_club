---
sketch: 071
name: admin-juegos
question: "What is the admin Juegos tab's one job, and what does the page look like once that job — not the filter-and-table habit — sets its shape?"
winner: null
tags: [admin, juegos, search, list, pendientes, add-by-bgg, phase-01.8.2, mobile-first]
---

# Sketch 071: Admin Juegos

## Design Question
Sketches 061 (Juegos page) and 063 (editor) predate the estante restart and the Web redesign, so they are the
starting point to question, not the target. The question asked first, as 069 and 070 did: **what does staff
actually do on Juegos, and how often?** — then let the answer set the page.

It reshaped the page before a line was drawn. Dev data (`pukllay_club_dev`, 2026-09-17):

| Fact | Count |
|---|---|
| Published | 434 |
| Borradores | **1** |
| Retirados | **0** |
| No cover **and** no description **and** no year | **49** (published — members see them broken today) |
| No `weight_band` | 27 |
| Incomplete, any reason | **50 of 435** |

So 061's four `estado` filter chips would spend their life filtering 435 into 435, and the 49 incomplete games
are the real queue nobody can see.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/071-admin-juegos/index.html

Tools (top-right): **Tema** · **Teclado** simulado · **Pendientes** 50 / 1 / 0 (to see the badge at each count).

Try: type `cat` (matches + "Crear «…»") · paste `342942` or a `boardgamegeek.com/boardgame/342942/...` link
(offers to add) · **+** → `hola` (the shipped error), `13` (the edition prompt), `342942` (adds, then enriches
live) · the **50** badge → Pendientes → any row → the editor stand-in.

## What it draws (decisions 1–5, `notes/juegos-ui-redesign.md`)
- **One job: find one game.** Title `Juegos` + a 48px search field, no filter chips.
- **Picking a game opens its editor** (sketch 063's screen — stubbed here). The search is pure navigation, so a
  game row carries a **chevron** (D-19i).
- **Under the search, all 435 games newest first**, `Mostrar más · 50 de 435` — the search answers "I know the
  name", the list answers "what did we just add". Justified by D-19l and by measurement (see below).
- **Adding lives in a "+" header icon and in the search**: the sheet has the BGG field and a "Crear a mano" path;
  the search offers **Agregar desde BGG** for a pasted id/link and **Crear «texto»** on no match.
- **Pendientes badge = 50**: a `‹ Juegos` page with **Sin datos** (49) and **Borradores** (1), per D-19g.

## Verification (`node .planning/sketches/071-admin-juegos/verify.js`)
**46/46 passed**, no page errors. Highlights:
- **Rhythm is pixel-identical to 069 raised** at 375×740: title row → field **16.0** (25.2 from the title's text
  box — 069 measures a field from the row, since its border is the visible edge), field → "Juegos del club"
  **32.0**, heading → first cover **16.5**, row **64px**.
- Type ranks: title 22/600 › heading 15/600 › row name 15/400 › second line 13/400 › field 16px (no iOS zoom).
- Header: both icons 44×44, Pendientes **left of** "+" (D-19g), badge `50` and in the accessible name.
- Keyboard (292px): suggestions end at **445** (3px clear), the add sheet's **Agregar** at **324.5** — both above it.
- Sheet closes with a 44px ✕ and has **no Cancelar row** (D-19e).
- Contrast: row name **17.16:1** light / **13.62:1** dark; second line **6.17** / **6.90**.
- No horizontal overflow at 360×640, 375×667, 375×740, 390×844. Rows visible without scrolling: **5** at
  360×640 and 375×667, **8** at 390×844.
- Shipped behaviour preserved: the BGG error copy, the D-03 edition prompt, add → draft → live enrichment.

**Caught by looking at the screenshots, which the measurements passed:** every cover rendered as an empty box —
the R2 thumbnails are `loading="lazy"` and the shot fired before they decoded. The harness now forces eager
loading and waits for decode before each screenshot, so the shots show what the developer actually sees.

## Why there is a list under the search at all
Measured before building, the same argument that produced D-19l on Web: idle Juegos is title + field ≈ **132px**
of content, leaving ~**403px** blank at 375×667 (60%) and ~**580px** at 390×844 (69%) — worse than the Web page
the developer called "too empty" (its worst was 449px / 62%).

## Open for review (choices made without asking)
1. **Inside Pendientes' "Sin datos" section, every row repeats "● Sin datos"** — the heading already says it.
   Differentiating information, or nothing, would probably serve better.
2. **The main list's second line is the year alone** ("2020"), which repeats down the page. Given the list is
   newest-first, recency ("hace 2 días") may earn the line better — or the year may be worth keeping because it
   is what tells two editions apart (065 round 3).
3. **No prompt line** ("¿Qué juego buscás?", 17/600). Estantes has one because its page is otherwise empty; here
   the placeholder carries it and a prompt would be a third text block above the list.
4. Copy not yet reviewed: "Juegos del club · 435", the add sheet's hint, "Crear a mano · Para un juego que BGG no
   tiene", and both Pendientes hint lines.

## Not drawn here
The editor itself (sketch 063 — this sketch only designs how you reach it), Ordenar (Juegos has no manual order),
Retirar/Publicar lifecycle (they live in the editor), and the enrichment `pending`/`failed` row states from 061
(the add flow shows the live fill-in, but a failed row + Reintentar is not drawn yet).
