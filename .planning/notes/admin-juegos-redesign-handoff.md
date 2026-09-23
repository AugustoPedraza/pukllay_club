# Handoff — redesign the admin "Juegos" tab (fresh session)

**Written:** 2026-09-17, at the end of the Web tab redesign (sketch 070, decisions 1–20).
**Pattern:** the same one that produced the estante screens (sketch 069) and Web (sketch 070) — `/gsd-sketch --quick`,
one question at a time, measure before building, record every decision.

## How to run it
`/gsd-sketch --quick Redesign the admin Juegos tab — read .planning/notes/admin-juegos-redesign-handoff.md first`

`--quick` skips the mood/direction intake: the look and feel is settled. Implementation comes later through
`/gsd-plan-phase 01.8.2`. When Juegos settles, `/gsd-sketch --wrap-up` can refresh the stale
`sketch-findings-pukllay_club` skill (D-17).

## What "Juegos" is
The admin tab that manages the catalog itself — ~434 published games plus drafts and retired ones.
- Today (01.8.1): `lib/pukllay_club_web/live/admin/game_live/index.ex` (`/admin/juegos`: a daisyUI `<.table>` of
  Nombre | Estado with a search, add-by-BGG, `Mostrar más · N de M`) and `game_live/form.ex` (`/admin/juegos/:id/editar`:
  the editor — name, cover, players, duration, Copias, BGG block, Estado, save bar).
- Last design: sketches **061** (Juegos page, type scale) and **063** (game editor, save bar, Copias control), with
  **064** (button system) and **065** (composition R3–R7) on top. They predate the estante restart and the Web
  redesign, so treat them as the starting point to question, not the target — exactly as 065's Web was for sketch 070.
- Scope note rows to read: `.planning/notes/admin-redesign-scope.md` rows 12 (list rows) and the `table/1` and
  Visual-Hierarchy rows of the stale-UI-SPEC table.

## Read first (in this order)
1. `.planning/phases/01.8.2-admin-ui-ux-redesign/01.8.2-CONTEXT.md` — D-08 (the estante pages), **D-19a–m** (app-wide
   rules; k, l and m came out of the Web redesign), D-10, D-16..D-18.
2. `.planning/notes/web-ui-redesign.md` — decisions 1–20 with the developer's words and every measurement.
3. `.planning/notes/estante-ui-restart.md` — "Where we are" at the bottom, then decisions as needed.
4. `.planning/sketches/070-web-destacados/index.html` and `.planning/sketches/069-estantes-ubicar/index.html` — the
   component source. **Copy CSS/JS from these, do not redraw**: header icons (A3), rail + "+" slots, sheets (D-19e),
   the form sheet with its fields, the confirmation dialog (D-19f), the snackbar, Ordenar mode with drag + ↑/↓,
   list rows with kind tag and count badge, the simulated keyboard, the tools bar.
5. `.planning/sketches/061-admin-juegos-page/README.md` and `063-admin-game-editor/README.md` — what they settled and why.

## The rules to carry (all in CONTEXT / the notes)
- **One main job per page** (D-19j) — but a one-job page **may list its siblings below** the job when the main control
  alone leaves the screen half empty (**D-19l**, Web). Queues of pending work still go behind a header badge (D-19g).
- **Type ranks:** title 22/600 › prompt or row name 17/600 › main control (48px field) › context 14–15/600 muted ›
  row names 14–15 › chips/subs 12–13. Rhythm on the 8px scale, grouped by belonging (title → main control 16,
  control → next group 32, label → its content 16) and **measured on what you can see** (a tile ends 12px inside its
  row box, a 20px tag sits 4px lower than a 13px line — box gaps lie).
- **Sheets** (D-19e): ✕ in the header, no Cancelar row; optional cover/tile · small context line · 18/600 title ·
  divider; two-line option rows (verb + one grey line, 64px); form sheets sit above the 292px keyboard.
- **Destructive = centred dialog** (D-19f) — but **removing an item from a list staff curate is not destructive**
  (**D-19k**): it happens at once with a Deshacer snackbar (10 s), and its sheet row is not red.
- **Status = dot + text** (D-19h). **Kind = a quiet lowercase tag; a count = a neutral pill on the tile's bottom-right**
  (**D-19m**) — never the top-right filled badge, which means pending work.
- **Chevron only when a row opens another page** (D-19i).
- **A row's name opens its options sheet** (Web decision 17) — no pencil; Editar lives in the sheet.
- **Reorder = a mode** from a ⇅ header icon: ≡ drag handles, tap ≡ → ↑/↓, Listo → "Orden guardado" + Deshacer.
- **Header actions** are 44px A3 icons, the primary create action ("+") rightmost; a text action only for Listo.
- **Create from where you are**: a search with no match offers "Crear «texto»".
- Spanish is **Argentine voseo** (memory); mobile first (memory); no age facet (memory).

## Working agreement (unchanged, it is what made 069 and 070 work)
- **One question at a time**, 2–4 options with a recommendation; build variants only when the developer asks, as tools
  toggles, and **remove the losers** once one is picked.
- **Measure before building variants and after every change**: positions, gaps, widths at 360/375/390, contrast in both
  themes, 44px hit areas, keyboard overlap — and **look at the screenshots**, which caught an empty SVG, a dark-theme
  textarea, a wrapped name overlapping its context line and a 44px gap that measured 32.
- **Record every decision** (developer's words + the measurements) in a notes file for this redesign, e.g.
  `.planning/notes/juegos-ui-redesign.md`, numbered from 1; app-wide rules also go to CONTEXT (next id **D-19n**) and
  BENCHMARK.
- Sketches show **only the UI being designed**. Next free sketch number: **071**.

## Measuring toolkit
- Serve: `python3 -m http.server 8765` from the repo root.
- Headless: `playwright-core` from the npx cache (loader in `.planning/sketches/064-admin-button-system/verify.js`),
  `channel: 'chrome'`, viewports 360×640 / 375×667 / 375×740 / 390×844, `deviceScaleFactor: 2`; scripts and screenshots
  go in the session scratchpad.
- Hide `#tools` (`display:none`) before real clicks; tools can still be clicked with `element.click()`.
- After scripted edits, extract the inline `<script>` and run `node --check` (a stray brace blanks the page).
- The simulated keyboard is 292px; sheets and dropdowns must end above it.
- Dev data is real and worth querying: `PGPASSWORD=postgres psql -h localhost -U postgres -d pukllay_club_dev`.
  For Juegos: 434 published games, drafts/retired via `games.status`, `weight_band` counts 179 / 183 / 46 (+26 with
  no band), and `.planning/sketches/069-estantes-ubicar/games.js` is a 434-game fixture with real R2 cover thumbnails.

## Suggested first question for the new session
Start from the job, as 069 and 070 did: *what does staff actually do on Juegos, and how often?* (add a game that just
arrived / fix or complete a game's data / find one game to check it / publish a draft / retire a game). Then decide the
page's one main job before drawing anything — and expect the answer to reshape 061's search-plus-filtered-table.

## Prompt to paste in the fresh session
```
/gsd-sketch --quick Redesign the admin Juegos tab — read .planning/notes/admin-juegos-redesign-handoff.md first
```
