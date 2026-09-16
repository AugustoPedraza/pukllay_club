---
sketch: 067
name: estante-read
question: "Phase 01.8.2 D-22 workflow 1: how does an estante page show its boxes in shelf order, and let staff read box N, on the club's real shelves (9 horizontal estantes, up to 50 boxes)?"
winner: "C — 065's rail kept, with real covers (letter tile fallback) and names clamped to two lines with an ellipsis (34 of 434 clipped)"
tags: [admin, estantes, read, list, grid, covers, position, fixture-honesty, mobile-first, phase-01.8.2]
---

# Sketch 067: Read an estante

## Design Question
First of seven estante workflows (CONTEXT D-22). Before anyone places, moves or finds a box, the estante
page has to show **what is on the shelf, in the shelf's left-to-right order, and which box is number N**.
Everything later acts on this view. 065's answer was the rail + Izquierda / Medio / Derecha, which the
developer found unclear; this sketch starts from the job instead.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/067-estante-read/index.html → **Estantes** → any estante.
*tools → Leer (067)* switches **A**, **B** and **C** (065's rail, for comparison only).

Generated: `node .planning/sketches/067-estante-read/build.js` takes 066's built page (065 + master/detail +
D-19 chrome) and replaces only the Estantes list and the estante page (`page.js`, `page.css`, `games.js`).

## The fixture is the club, not an invention
- **Shape (developer, 2026-09-16):** 9 horizontal estantes; the fullest holds up to 50 boxes. Sizes used:
  50, 50, 49, 48, 48, 48, 48, 47, 46 = 434.
- **Games:** the 434 published games from the dev database — real names and real R2 cover thumbnails
  (385 have one; the other 49 show the letter tile the app falls back to).
- **Order:** by BGG weight, then name. The real left-to-right order has never been recorded (D-05 starts
  empty), so this is a stand-in; it changes nothing measured below.

## Measured before building
Real name lengths (434 games): median 13 characters, **36% over 16, 27% over 20, 7% over 30**, max 71.
That decides what a box can be labelled with at phone width:
- a list row's name column takes ~30 characters per line → almost every name on one line, none cut;
- a grid tile at 4 columns takes ~20 characters in two lines → about a quarter cut; 5 columns → a third;
- a 3-column grid is as tall as the list (~4 screens), so it buys nothing.
- 065's rail shows 3 of 50 boxes at a time, and the middle of a 50-box shelf is 25 steps away.

## Variants
- **A · Lista numerada:** one row per box, top of the list = left end of the shelf. A quiet position
  column (1–50), cover, name. Label "De izquierda a derecha"; foot "Derecha: fin del estante".
- **B · Grilla:** 4 columns, reading order left→right then down, each cover numbered, name under it (2 lines).
- **C · Riel (065 hoy):** 065's rail, later given real covers.

Rows and tiles are **static**: reading is not acting. Tapping a box belongs to workflows 070 (move) and 071
(take off), so nothing here pretends to answer them.

## Measured on the build (375px device, all 9 estantes)
| | A · lista | B · grilla | C · riel |
|---|---|---|---|
| page, 50-box estante | 2 935px = **4.0 screens** | 1 986px = **2.7 screens** | 1 screen |
| boxes readable on the first screen | 9 | 12 | 3 |
| names cut or hidden | **0 of 434** (34 wrap to a 2nd line, fully shown) | **85 of 434 cut (20%)** at 2 lines | names under 96px tiles |
| where box N is | the number column | a badge on each cover | not shown |

## What to Look For
- Standing at shelf 4, box 23: which view gets your eye to it faster?
- B shows more covers per screen, and covers are how people recognise a box; A never cuts a name.
- Does "De izquierda a derecha" + a top-to-bottom list read as the shelf, or does the grid's row wrap
  read more like the physical shelf?

## Winner: C, the rail, with covers
Developer: *"The riel is ok (use image since its recognizable. Be sure to use name with '...' in case the
name is long. What I need to be fixed is the rest of the page (Izquierda, medio, derecha) and agregar juego
and that weird 3 dots and the options when a box is selected. I want to be sure we prioritize it based on
real world usage."*

- The rail keeps 065's anatomy (96px tile, 10px gap, 16px fade); its letter tile becomes the game's
  **cover** (R2 thumbnail, `object-fit: cover`), with the letter tile as the fallback (49 of 434 games).
- The caption keeps 065's 2-line clamp, which ends in "…": **34 of 434** real names are clipped, measured
  across all 9 estantes.
- A and B stay on the switch as the record.
- **Still open, and the next sketches:** the zone bar (Izquierda / Medio / Derecha), Agregar juegos, the
  ⋯ options and the selected box's actions, ordered by real-world use (CONTEXT D-22).
