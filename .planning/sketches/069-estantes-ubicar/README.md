---
sketch: 069
name: estantes-ubicar
question: "Estante UI restart (01.8.2): the Estantes screen as the place to pick up and put back a game — search that resolves to one game, the estante picture with it lifted between its neighbours, recent lookups, and a secondary management page."
winner: null
tags: [admin, estantes, search, autocomplete, locate, rail, covers, status-dot, sheet, restart, phase-01.8.2]
---

# Sketch 069: Estantes — ubicar un juego

## Design Question
The developer restarted the estante UI after 068 (*"Let's start over all of this UI. Ask the question and
I'll let you know. Be sure to focus only on that UI."*). Every choice on this page was made by the developer
one question at a time; they are numbered in `.planning/notes/estante-ui-restart.md` (1–23). This sketch
draws them — no variants, because nothing here was left open.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/069-estantes-ubicar/index.html

A standalone page: only the Estantes screen and its management stub. The header and tab bar are context and
do nothing. The one tool is Tema (Claro / Oscuro). Data: the 434 real games and covers, 428 of them on 9
estantes of 46–50 boxes, 6 with no spot.

## What it does (decision numbers from the notes)
- **Estantes** title with a **gear icon** on the right (19, 26) → a secondary page listing the estantes with a
  shelf-drawing icon, name and "N juegos" (14, 17, 18). Rows there are stubs.
- **Layout (27, 28):** idle, a shelf drawing and "¿Qué juego tenés en la mano?" sit above the search, with
  Últimas búsquedas below, the whole group at the optical centre (free space 2:3 above:below; gaps 16 / 24 /
  40). Focusing the field or showing an answer removes the prompt and moves the search to the top. A
  simulated 292px keyboard shows while the field is focused (*tools → Teclado simulado*).
- **Search** with the placeholder "Buscá un juego para ubicarlo" and a magnifier on the right that becomes ✕
  while typing (15, 16). It is an **autocomplete**: up to 6 suggestions (cover, name with the typed part in
  600, estante or "● Sin lugar") drop **over** the page (2, 12). Keyboard: ↑ ↓ Enter Esc.
- **Picking a game** clears the field (11) and shows **"Estante 4"** (8) above the **whole estante as a
  swipeable row of covers** (6), centred on the game, which is **lifted** (23) between its neighbours (3, 4).
- **Tap another cover** → the lift moves to it; **tap the lifted cover** → its sheet (10): Ver en la ludoteca ·
  Mover a otro lugar · Quitar del estante · Cancelar (9). Ver and Mover are stubs for later sketches.
- **Quitar** → the answer turns into **"● Sin lugar"** with **Ubicar** (5) and a 10 s Deshacer snackbar.
  **Ubicar** → a sheet of estantes → the game lands lifted at the right end, with Deshacer.
- **Últimas búsquedas** below (20, 21, 24, 25): 3 compact rows, cover, name, estante — or **dot + "Sin
  lugar"** (22) — no chevron; tapping one is the same as picking it from the search.

## Measured (375×740 device, both themes)
- Field bottom at 169px; a 292px phone keyboard leaves **275px** → the suggestion list is capped at **272px**
  (4 whole rows + half a fifth, so a longer list reads as scrollable).
- Picking centres the lifted cover in the rail (offset **0px**); at the estante's end it sits at the edge.
- Contrast: Administrar 6.0:1 light / 6.9:1 dark; subtitles and placeholder 6.2 / 6.9; field stroke 4.3 / 3.5.
- The sheet renders **no buttons**, only rows; focus lands on the sheet, so no row looks pre-selected.

## Found on the way
- `cat` suggests only one of the five Catan editions in its first 6 (prefix matches rank first, in catalogue
  order). Families need a ranking rule — open.
- The shelf-drawing icon (10 spines filled by fullness) reads a bit like a barcode at 28px — open.
- Decision 11 (clear on pick) means the estante title and the lifted cover's caption are the only places
  naming the picked game.

## What to Look For
- Put back three boxes in a row: type → pick → look → type the next. Does anything slow you down?
- Is the lifted cover obvious enough at a glance?
- Is "Administrar" findable when you need it, and quiet when you don't?
