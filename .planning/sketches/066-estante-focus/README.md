---
sketch: 066
name: estante-focus
question: "Phase 01.8.2 D-08: Estantes as master/detail — does the estante page need a Siguiente estante link? (Round 1 asked how other rows recede when one estante opens in place; superseded.)"
winner: "R2-A + Crear opens the new estante — master/detail (list → one page per estante), no Siguiente link; creating an estante lands on its page"
tags: [admin, estantes, master-detail, drill-down, focus, disclosure, single-open, scroll, contrast, a11y, mobile-first, phase-01.8.2]
---

# Sketch 066: Estantes — from focus to master/detail

## Design Question
D-08 is decided: opening an estante **closes any other**, **scrolls its header to the top**, and the
other estante rows **recede** while it is open. The one open question is the recession's look.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/066-estante-focus/index.html

*tools → Estantes (066)* switches **R2-A** (list → detail, the default), **R2-B** (+ Siguiente estante),
and round 1's **R1-A** / **R1-B** (in place). Walk to **Estantes** and open estantes.

`066/index.html` is generated: `node .planning/sketches/066-estante-focus/build.js` takes 065's built
page verbatim and adds one CSS block (in `build.js`) and one script (`page.js`). Nothing else from 065 changes.

## Round 1 — focus on expand (superseded)

### Measured before building (why there were only two variants)

1. **Opacity is out.** A receded row is still a live control (tapping it moves the focus), so 1.4.3
   applies. Its count line ("65 juegos", muted `#675C7D`, 6.17:1) falls under 4.5:1 at opacity
   **0.88**, so any fade you can actually see fails. At 0.6 it is 2.6:1 (light) and 3.4:1 (dark).
   Recession has to be a colour step inside the palette: the **name** goes text → muted
   (17.2 → 6.2:1 light, 13.6 → 6.9:1 dark), and the icon goes muted. Every receded pixel stays ≥ 4.5:1.
2. **Scroll-to-top needs a runway.** With 065's page, the header of **Estante C** could not reach the
   top (short by 18px) and **Estante D** by 78px. The last estante always falls short, however many
   there are. The sketch adds exactly the padding needed below the list while an estante is open, and
   removes it when none is. `main` has a min-height that absorbs part of any padding, so a
   single "add the shortfall" was measured at 31px off. The runway grows until the scroll lands.
   Result: **every estante, including Sin ubicar, opens flush under the header (0px) in both themes.**
3. **The open estante fits one screen.** Visible height under the header and above the tab bar is
   620px. An open estante (header, zone chips, rail, note, Agregar juegos) is 369px (393 for D), so
   once it's scrolled to the top, all of it is visible without scrolling.

### Variants
- **A · Texto atenuado:** the other rows' names and icons turn muted. The open estante is unchanged.
- **B · Atenuado + panel:** A, plus the open estante on the panel surface (`--color-surface`),
  bleeding full width so no content edge moves.

### Costs found by looking (B)
- **Sin ubicar already uses that surface** in 065. In B, the open estante is painted like Sin ubicar,
  so "this is open" and "this is the unplaced pile" look the same.
- **The rail's 16px edge fades are painted in `--color-bg`**, so on the tint they show as pale strips
  at the rail's ends. Aligning would need a second fade colour for the rail.
- **The estante icon's tile is also `--color-surface`**, so inside the panel it vanishes.

A's cost: a muted name is also what a *retired* game row uses (`.grow.is-retired .gname`). Estantes
are never retired, so on this page there's no clash, but it's the same signal with a different meaning.

## Carried from 01.8.2 D-19 (built, not judged here)
- **19d** drawer opens from the left (measured L0–R307; the hamburger was already on the left).
- **19c** the top toast is gone; `showToast` messages are plain snackbars (4 s, no ✕).
- **19b** a snackbar with an action stays **10 s** (measured: still shown at 6 s, gone at 10.5 s) and
  carries a 44×44 ✕.
- **19a** the save bar pins above the tab bar while dirty and off screen. **Sticky cannot do it** in
  this DOM: the bar's parent section ends at the bar (measured top 1495 of 1742 with sticky applied).
  So the sketch shows a pinned copy 12px above the tab bar that disappears once the in-page bar scrolls
  into view, and its Guardar saves. **Planning note:** the pinned bar is 118px tall on a published
  game with changes (status + Retirar + Guardar), about 19% of the 620px work area.

### Why round 1 was superseded
Developer, looking at A and B: *"This feel so overloaded. Should we follow the master/details mobile
pattern?"* The overload was structural, not a paint problem: with one estante open, one screen held
controls for **the list** (progress, search, "Estantes del club · Ordenar", the other rows, Sin ubicar,
Nuevo estante) and for **one estante** (Izquierda / Medio / Derecha, the rail and its arrows, the hint,
Agregar juegos, ⋯) — five outlined controls, and Ordenar meaning two different things one scroll apart.
Recession cannot remove any of it, and round 1 had already measured that it cannot fade it far either.
Decision: **master/detail** (CONTEXT D-08, revised).

## Round 2 — master/detail (2026-09-16)

**Estantes** is a list: progress, search, a drill row per estante (name · count, chevron right), Sin
ubicar as a drill row too, Nuevo estante. **One page per estante** (`‹ Estantes`, `/admin/estantes/:id`):
title + count, zone bar, rail, Agregar juegos, ⋯. **Sin ubicar** gets the same kind of page. The tab bar
keeps **Estantes** active on both (the page's parent). Search is unchanged from 065 R8: a hit expands in
place to the rail at that copy, which already answers "where is it and what is next to it" on one screen.

### Measured (390×844, light)
| | list | estante page (R2-A) | estante page (R2-B) | round 1, one open |
|---|---|---|---|---|
| outlined controls visible | 1 (Ordenar) | **1** (Agregar juegos) | 1 | 5 (Ordenar, 3 zone chips, Agregar juegos) |
| page content ends at | 683px | **513px** | 629px | scrolls (1 064px page) |
| fits above the tab bar (673px) without scrolling | yes | **yes** | yes (Siguiente row 505–597) | no |

Driven end to end: list → C → ‹ back → D → ‹ back → Sin ubicar → ‹ back; R2-B A → Siguiente → B (lands
at scroll 0); on B, Agregar juegos → tap a game (snackbar *"… va al final de Estante B — estrategia ·
Deshacer"*) → Listo (count 59 → 60, badge 84 → 83); switching to R1-A still opens in place. Back
restores the list's scroll position (clamped to what the page can scroll).

### The question this round: does the estante page need "Siguiente estante ›"?
It exists to shorten the **walk**: go shelf by shelf, placing each copy. Counted taps for that walk,
12 estantes and ~412 copies (the fixture's numbers):

| step | R2-A (no link) | R2-B (Siguiente) |
|---|---|---|
| move between estantes | ‹ back + tap next row = **2** × 11 = 22 | Siguiente = **1** × 11 = 11 |
| placing (Agregar juegos, one tap per copy, Listo) | ~412 + 24 | ~412 + 24 |
| total | ~459 | ~448 — **−2.4%** |

**And the walk that matters most does not pass through it.** On the first run (D-05, D-09) the estantes
do not exist yet: staff create the next one with **Nuevo estante**, which lives on the list. So in the
start-empty walk the next estante is never a "Siguiente" away; it is back → Nuevo estante → name →
Crear. Siguiente helps only later walks over estantes that already exist.

Cost of R2-B: a second labelled block ("Siguiente estante") on every estante page, +116px, and one more
tap target competing with Agregar juegos on the page whose job is placing.

## Winner (round 2): R2-A, and Crear opens the new estante
Developer picked the measured recommendation: **no "Siguiente estante" link**, and **creating an
estante lands on its new page** (snackbar "Estante creado"). The start-empty walk is then:
Nuevo estante → name → Crear → *on the new estante* → Agregar juegos → place left to right → Listo →
‹ Estantes → Nuevo estante. R2-B stays renderable on the switch.

Built with it:
- **An empty estante says so:** "Todavía no tiene juegos. Agregalos en el orden del estante, de
  izquierda a derecha." replaces 065's "Tocá una caja…" over an empty rail (065 never had an empty
  estante to show).
- **Content edge on the estante page is 16px for everything:** title, zone chips, note, Agregar juegos
  (measured). With no header row, 065's list-row indents do not apply.
- A bug caught by drawing, not by the property check: the snackbar ✕ was drawn on plain snackbars
  because `display: inline-flex` overrode `[hidden]`. The D-19 check now reads the drawn box.

## What to Look For (round 2)
- R2-A vs R2-B on Estante A: does the Siguiente block read as part of the estante, or as noise?
- Walk: list → estante → Agregar juegos → place two → Listo → ‹ → next. Does the back step feel slow?
