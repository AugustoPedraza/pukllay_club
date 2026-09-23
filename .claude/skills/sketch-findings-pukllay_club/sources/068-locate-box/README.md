---
sketch: 068
name: locate-box
question: "Phase 01.8.2 D-22, the most frequent real-world job: from a search, how does staff learn where a box goes back (or where to pick a game up) — estante, position, neighbours — and where do the rare actions on a box live?"
winner: null
tags: [admin, estantes, search, locate, position, neighbours, covers, actions, sheet, phase-01.8.2]
---

# Sketch 068: Locate a box

## Design Question
Developer, ranking by real use: *"putting boxes back is the most frequent. Maybe see where is a game too to
be picked up. Then add a new one / order / remove aren't frequent."* Both frequent jobs ask the same thing:
**which estante, which position, next to what.** This sketch draws that answer and demotes the rare actions.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/068-locate-box/index.html → **Estantes** → type in *Buscar un juego*
(try `cat`, `lapsus`). *tools → Ubicar (068)* switches **A** and **B**.

Generated: `node .planning/sketches/068-locate-box/build.js` takes 067's built page (9 real estantes, real
covers, the rail) and adds `page.js` / `page.css`.

## Measured before building (434 real names)
- **Typing is cheap:** 3 characters bring a game to ≤ 3 results for half the catalogue, 5 characters for 90%.
  Only 5 names never get under 4 results by name alone (Carcassonne, El señor de los anillos, Planet, Ra,
  Wingspan — families). So the answer must be readable **in the results**, not one screen later.
- **The neighbours are the physical cue:** a box goes back into the gap between two boxes you can see.
- **Three covers fit the content width exactly** (3 × 96 + gaps = 308 of 343px) — box + both neighbours.

## Variants
- **A · La fila responde:** every result row carries the whole answer with **no tap**: cover, name,
  **"Estante 1 · caja 25 de 50"**, "entre *Virus* y *HDP*", and a **position bar** (Izq. ——●—— Der.). Tapping
  the row opens the estante with that box selected and scrolled into view.
- **B · Fila + vecinos:** a compact row (cover, name, "Estante 1 · caja 25 de 50"); tapping expands it in
  place to the neighbours **as covers** (left · this box · right, "Principio/Final del estante" at an end),
  the position bar, and **Ver en el estante**.

**Both** replace 065's selected-box panel on the estante page: the repeated bold name and the two text
actions are gone; it now says **"Caja 1 de 50 · al principio, antes de Lapsus"**, shows the position bar, and
carries ONE text action, **Opciones de la caja**, which opens a sheet: Ver en la ludoteca · Mover a otro
lugar (sketch 070) · Quitar del estante (danger) · Cancelar. The ⋯, Izquierda/Medio/Derecha and Agregar
juegos are untouched here — they are 069, 070 and 072.

The position bar is the proposed replacement for the zone WORDS as the "where along the shelf" cue: the
number says exactly which box, the bar says where to walk to, and its ends are named.

## Measured on the build (375px device)
| | A | B |
|---|---|---|
| taps from results to estante + position | **0** | **0** |
| taps to the neighbours | **0** (names) | **1** (covers) |
| result row height | 107px (124 when neighbours wrap) | 68px; +230px expanded |
| results fully visible on the first screen (query `cat`, 16 hits) | 4 | 6 |
| back from the estante | query kept, 16 results — the next box is one tap away | same |

## What to Look For
- Hold a real box (say *Catapul Feud*). With A, can you walk to it without tapping? With B, is the one tap
  worth seeing the neighbours' covers?
- Is the position bar clearer than Izquierda / Medio / Derecha?
- On the estante page: is "Opciones de la caja" + a sheet the right weight for actions you rarely use?
