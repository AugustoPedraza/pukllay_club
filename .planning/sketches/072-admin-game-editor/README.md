---
sketch: 072
name: admin-game-editor
question: "In the game editor: is an editable value a ROW THAT OPENS A SHEET or a FORM WITH INLINE FIELDS (round 1, decision 33) — and once the row has no chevron, what says it is editable (round 2, decisions 34-35)?"
winner: "A (spine) + D+B (affordance)"
tags: [admin, juegos, editor, form, spine, sheets, affordance, palette-todo, phase-01.8.2, mobile-first]
---

# Sketch 072: the game editor — the spine

Round 1 of the editor asks **one** question. Everything else the editor owes — the BGG state, Copias,
Estante, Retirar — sits inside whatever this settles, so none of it is designed here.

## Design Question

Sketch 063 put **a pencil on every value**. **Web decision 17 removed the pencil**: the value itself became
the target, "one target instead of two". The editor is the last screen still on the old idiom, so the spine
has to be settled before anything else is drawn on it.

## How to View

```
python3 -m http.server 8765          # from the repo root
```
<http://127.0.0.1:8765/.planning/sketches/072-admin-game-editor/index.html>

Harness: `node .planning/sketches/072-admin-game-editor/verify.js` — **46/46** (39 while the three variants were live; the losing variants and their comparison checks were removed once A was picked). `SHOTS_DIR=` to place shots.

Tools: **Tema · Teclado**. The `Columna` toggle is gone — every variant toggle is removed once its
question is answered, so what is on screen is the decision, not a menu of them.

## Variants

- **A — filas → hoja ★ chosen (decision 33).** Every value is a row: key on line 1, value on line 2, disclosure `⌄`, opening a sheet.
- ~~**B — formulario.**~~ *removed* Stacked inline fields, what ships today: labels, inputs, selects, a textarea.
- ~~**C — mixto.**~~ *removed* The controls that are already one tap stay inline (a stepper for Copias, a switch for
  expansión); everything needing typing or a list of options is a row.

## What the numbers said

| | A | B | C |
|---|---|---|---|
| club block height | **450.6** | 667.9 | **450.6** |
| whole page | **1145** | 1362 | **1145** |
| fields fully on screen at rest | **6** | 4 | **6** |
| taps to change Nivel | 2 | 1 (+ the platform's select popup) | 2 |
| row anatomies | **1** | n/a | **3** |

B is **217px taller** in the club block and shows **4 of 6** fields; A and C show all six.

## What only the screenshots said

Three things the green harness was blind to, all found by looking:

1. **The key and value ran together on one line** — "NombreBrass: Birmingham". They are spans inside a
   button, so as inline boxes they never stacked. Height, contrast and hit-box checks all pass straight
   through that, because none of them asks where the ink sits *relative to its neighbour*. A guard now
   measures it as ink, via Range rects.
2. **Every select in B rendered with no caret** (`var(--caret-bg)` never existed), so both dropdowns read as
   text inputs. Comparing a variant against a broken one is not a comparison — fixed before judging.
3. **A's rows all wore the page chevron `›`, violating D-19i**, which is explicit: *"a chevron means this row
   opens another page. Rows that act in place (show an answer, open a sheet) have none."* Every row here
   opens a sheet. They now carry the disclosure `⌄` — the glyph Web d17's name button uses and Juegos
   decision 26 separated from the row chevron after finding the two byte-identical.

## The finding that decides it

**C cannot have one anatomy, and this is intrinsic rather than sloppy building.** Measured:

```
A   6 rows · all <button> · 1 trailing shape (chevron) · line 2 is ALWAYS the value
C   6 rows · <button> AND <div> · 3 trailing shapes · line 2 is the VALUE on 4 rows, a HINT on 2
```

An inline control *already is* the value display, so the second line has nothing left to carry but a hint —
which makes it a different kind of row. You cannot have both "one anatomy" and inline controls. This is the
same shape as Juegos decisions 13→16: four passes at one seam that decision 17 deleted by changing the
premise.

**A's cost, stated plainly:** flipping a boolean costs a sheet round-trip — 2 taps and a modal for a yes/no.

## Round 2 — the affordance (decisions 34-35)

Round 1 shipped a chevron-down on every row. From the device: *"the chevron pointing down isn't the correct
affordance since we use that for an open list."* Right, and wrong twice over:

- **D-19i already said it literally**: *"rows that act in place (show an answer, open a sheet) have none."*
- **The ⌄ was reasoned from a note, not from the screen.** Web d17 describes the row name as carrying a ⌄,
  so I treated ⌄ as the established opens-a-sheet glyph. But **070 renders a bare `<h2>`** — no glyph — and
  d17's own note records the ⌄ *"drew an empty SVG"*. Grepped across the corpus, `chevD` renders in exactly
  one place: 071's collapse caret. Reading a decision's prose instead of its artefact is its own failure mode.

With no glyph, what says "editable"? Five answers, measured in both themes:

| | signal | light | dark |
|---|---|---|---|
| A bare | none | — | — |
| B tint | hue | ✓ | **✗ 1.17:1 from body text** |
| C hint | standing line | +27px, pushes BGG off the fold | same |
| D polarity | rank | ✓ | ✓ |
| **D+B ★** | **polarity + tint** | **✓** | **✓ (needs a new token)** |

**Both platforms put the label first and the value second** — iOS's grouped table and M3's list item (the
Android Settings row). This sketch had it inverted. Flipping it also separates the club block from the
read-only BGG facts *structurally* (opposite polarity), which a colour-only signal cannot do.

**Why no standing hint** (asked directly): the page already teaches the rule from the other side — the BGG
block says *"No se editan acá."* A positive hint teaches it twice and, above a block where it is false,
implies those facts are editable too. Precedent is on the record: *"no prompt line — the page is not empty"*.

**A guard that passed what it was written to reject.** Distinguishability first used a contrast ratio at
`>= 1.15`; the rejected variant scores **1.17**. Contrast ratio cannot see hue — accepted light is 1.21,
rejected dark 1.17. As **CIE76 ΔE** the same pairs are **29.6 and 10.1**, and a bar at 20 separates them.

> **TODO(palette) — blocking before 01.8.2 ships.** `--val` is defined in this sketch, not the theme:
> `themes/default.css` mirrors `assets/css/app.css` under `check-theme-drift.sh`. The dark token (`#9F7AEA`)
> must go upstream against the `--pk-ramp-*` envelope, and should **beat 4.83:1** — at that value it is the
> lowest-contrast text on the dark page. See the blocking item in `notes/juegos-ui-redesign.md`.

## What is still open on this page

The spine is settled; nothing else about the editor is. In the handoff's order:

1. **The BGG state** — the next round, and where the real defect is: `Reintentar` is gated on
   `enrichment_status == "failed"` in both the UI (`form.ex:220`) and the action (`catalog.ex:368`), but the
   dev DB has **0 failed** rows while **49** games are broken as `no_bgg_id` (41) and `bgg_missing` (8).
   Those 49 are exactly the ones Juegos groups under **SIN DATOS**, so a user taps one expecting to fix it
   and the editor offers nothing at all.
2. **Copias** — `units = 1` for all 434 games (1 null), so D-02's add/remove-a-copy rules describe a state
   that does not exist yet. How much UI does a field earn when its value is constant?
3. **Estante** — this sketch shows a picker, but D-01/D-00c place a *copy*, in the "¿Dónde va?" sheet.
   Likely resolves to read-only plus a link out, not a picker.
4. **Retirar** — 063's in-sheet confirm must become D-19f's centred dialog.
5. **En la web** — the manual-section switches from 063 are not drawn here at all.
