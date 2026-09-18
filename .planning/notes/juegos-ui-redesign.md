# Admin "Juegos" tab — UI redesign

**Started:** 2026-09-17 (handoff: `.planning/notes/admin-juegos-redesign-handoff.md`)
**Scope:** the admin Juegos tab — the catalog itself. Today:
`lib/pukllay_club_web/live/admin/game_live/index.ex` (`/admin/juegos`) + `form.ex` (`/admin/juegos/:id/editar`);
last design sketches 061 (page) and 063 (editor), both starting points to question, not targets.
**Carries:** D-19a–m (`01.8.2-CONTEXT.md`), estante restart decisions 1–68, Web decisions 1–20, sketch 069/070 components.

## Context carried in

Dev data queried 2026-09-17 (`pukllay_club_dev`), and it reshapes 061's design before a line is drawn:

| Fact | Count | Consequence |
|---|---|---|
| Published | 434 | — |
| Borradores | **1** | 061's four filter chips would filter 435 into 435 |
| Retirados | **0** | same |
| No cover **and** no description | **49** | published, live, broken on the public site today |
| No `weight_band` (Sin nivel) | 27 | they appear in no Nivel row on the home |
| `bgg_missing` (BGG lookup failed) | 8 | subset of the 49 |
| `no_bgg_id` (never had one) | 41 | subset of the 49 — a by-name creation path is 11% of the catalog, not hypothetical |
| Incomplete, any reason | **50 of 435** | 11.5% |

All 49 were bulk-imported 2026-08-10, many with rough names (`luxor`, `bot factory`, `abyss leviatan`,
`Catapul Feud (expa 1)`, `Age of Artisans(expa Arquitectos)`). The 069 fixture's 49 thumb-less games are exactly
these 49 — `!g.t` is a faithful stand-in for "sin datos", so the sketch needs no invented data.

Shipped behaviour that stays true: the add field accepts **either a BGG number or a BGG link**
("Pegá un número de BGG o el link del juego."), a known BGG id shows the edition prompt, enrichment is async over
PubSub with pending/failed row states + Reintentar, paging is `Cargar más` over 50.

## Decisions

1. **The main job is finding one game.** Not adding, not browsing, not fixing data. Juegos becomes the same page
   shape as Estantes — a search — with a different answer.
   Developer picked "Find one game (Recommended)" over add-first, browse-first and fix-incomplete-first.
   **Consequence:** 061's four `estado` filter chips (Todos / Borradores / Publicados / Retirados) are gone —
   with 434 published, 1 draft and 0 retired they filter 435 into 435. Lifecycle state stops being a filter axis
   and becomes a row marker (D-19h) plus a Pendientes section (decision 5).

2. **Picking a game opens its editor.** The search is pure navigation: tab → type → editor, two taps. No inline
   answer block on Juegos (unlike Estantes, where "where is it" *is* the information — here the reason to find a
   game is to change it, so an answer block would be a stop on the way).
   Developer picked "Opens the editor (Recommended)" over an inline answer block and over an options sheet.
   **Consequence:** the whole space under the search belongs to the list, and a game row carries a **chevron**
   (D-19i: a chevron means the row opens another page) — unlike Web's rows, which open a sheet.

3. **All games under the search, newest first, paged.** "Juegos del club" + the 435 games ordered by when they
   were added, newest at top, `Mostrar más · 50 de 435`. Chosen over A–Z (which repeats what the search already
   does), over a short recent list + a full list page, and over leaving the page empty.
   **Why a list at all** — measured before building, the same argument that produced D-19l on Web: idle Juegos is
   title + field ≈ 132px of content, leaving ~403px blank at 375×667 (60%) and ~580px at 390×844 (69%) — worse
   than the Web page the developer called "too empty" (its worst was 449px / 62%). D-19l covers it: a one-job page
   may list its siblings under the job when the main control alone leaves the screen half empty.
   **Why newest-first** — the search already answers "I know the name"; the list answers the different question
   "what did we just add / what have I been working on". The game added five minutes ago is the first row.

4. **Adding lives in a "+" header icon AND in the search.** A 44px "+" rightmost in the header opens the
   "Agregar juego" sheet (the BGG field, the edition prompt, and a manual "Crear a mano" path); the search stays
   create-aware — paste a BGG id or link and the dropdown offers **Agregar desde BGG**, type a name with no match
   and it offers **Crear «texto»** (the Estantes house pattern, restart decision 62).
   Developer picked ""+" in the header, and search creates too (Recommended)" over a smart-field-only page
   (adding would be undiscoverable for new staff) and over "+"-only (it would break create-from-where-you-are,
   making Juegos and Estantes behave differently).
   **Settled by the rules, not by taste:** 061's inline "AGREGAR JUEGO" block (section label + 44px field +
   Agregar button) cannot come back — it is a second control sitting above the main one, which D-19j forbids.
   **Why both paths are real:** 41 games have no BGG id at all, so by-name creation is 11% of the catalog.

5. **Pendientes badge = 50: "Sin datos" (49) + "Borradores" (1).** The same shape as Estantes' Pendientes
   (D-19g): a `‹ Juegos` page, two sections, each a heading with count + one hint line + all rows; a row opens
   that game's editor. The 44px icon sits left of the "+" in the header and carries an 18px count badge
   (primary fill, in the accessible name).
   Developer picked "Sin datos + Borradores, badge 50 (Recommended)" over adding a third "Sin nivel" section,
   over drafts-only, and over no badge.
   **Why it is pending work and not just a state:** the 49 are *published* — members see them right now with no
   cover and no description. This is the most urgent queue in the admin, and D-19g is exactly the pattern for it.

## Sketch 071 (round 1, 2026-09-17) — built from decisions 1–5

`.planning/sketches/071-admin-juegos/index.html` — standalone, hand-written, uses `../069-estantes-ubicar/games.js`
and `../themes/default.css`. Components copied from 069 (search, dropdown, sheets, dialog, snackbar, form sheet)
and 070 (header icons, list rows), not redrawn. Tools: Tema · Teclado · Pendientes 50/1/0.
Harness: `verify.js` — **46/46 passed**, no page errors.

**Measured 375×740 (light + dark unless noted):**
- Rhythm is **pixel-identical to 069 raised**: title row → field **16.0** (25.2 from the title's text box — a field
  is measured from the row, since its border is the visible edge; 069 raised gives the same two numbers),
  field → "Juegos del club" **32.0**, heading text → first cover **16.5**, row **64px**.
- Ranks: title 22/600 › heading 15/600 › row name 15/400 › second line 13/400 › field 16px (no iOS zoom).
- Header: both icons 44×44, Pendientes **left of** "+" (D-19g), badge `50`, count in the accessible name.
- Keyboard 292px: suggestions end **445** (3px clear), the add sheet's Agregar ends **324.5**.
- D-19e: 44px ✕, no Cancelar row. D-19i: the game row has a chevron (it opens the editor).
- Contrast: row name **17.16:1** light / **13.62:1** dark; second line **6.17 / 6.90**.
- No horizontal overflow at 360×640 / 375×667 / 375×740 / 390×844; whole rows visible without scrolling:
  **5** at 360×640 and 375×667, **8** at 390×844 — the blank-space problem decision 3 was answering is gone.
- Shipped behaviour preserved: the BGG error copy, the D-03 edition prompt, add → draft → live enrichment.

**Caught by looking at the screenshots, which the measurements passed:** every cover rendered as an empty box —
the R2 thumbnails are `loading="lazy"` and the shot fired before they decoded. `verify.js` now forces eager
loading and waits for decode before each screenshot. (The measuring toolkit note stands: screenshots keep
catching what passing checks do not.)

**Choices made without asking — flagged for review:**
1. Inside Pendientes' "Sin datos" section every row repeats "● Sin datos", which the heading already says.
2. The main list's second line is the year alone ("2020"), repeating down the page; recency may earn it better,
   against 065 round 3's reason for keeping año (it tells two editions apart).
3. No prompt line ("¿Qué juego buscás?"): the page is not empty, so the placeholder carries it.
4. Copy not reviewed: "Juegos del club · 435", the add sheet's hint, "Crear a mano · Para un juego que BGG no
   tiene", both Pendientes hint lines.

**Not drawn:** the editor itself (063), the enrichment `pending`/`failed` row + Reintentar, lifecycle actions.

6. **A long list keeps its context in two pinned tiers** — app-wide, recorded as **D-19n**. Developer: *"for scroll
   the «pendientes», that should be a kind of «stacked» header at scrolling to keep the context when I scroll down,
   shouldn't? is that a common pattern for mobile?"* — yes, and both design systems pair two separate mechanisms:
   iOS pins `UITableView` plain-style section headers (the next one pushes the previous out — Contacts) *and*
   collapses a large title into the compact nav bar; Material 3 has sticky list subheaders *and* a top app bar whose
   large variant collapses to small on scroll. Developer picked "Page bar + section heading, stacked (Recommended)"
   over section-heading-only, page-bar-only and nothing.
   **Measured first — all three pieces of context are lost at once.** On Pendientes at scrollTop 1500 (375×667):
   page title **not visible**, `‹ Juegos` **not visible**, section heading **not visible**, 11 rows on screen with
   nothing to orient them — and the back link 1500px away. The Sin datos section alone is **3,307px** tall; the main
   Juegos list fully paged is **27,664px** (~45 screens).
   **What it draws:**
   - A 44px **page bar** pinned at the top of the scroller once the title row has gone behind it: `‹ Juegos` +
     the page title at 17/600. It is an **absolute overlay on `.device`, not a sticky child** — at rest it must cost
     zero layout, and it does: phead 69, title text 77.8, field 129, heading 209, first cover 244.5, row 64 are
     byte-identical to the pre-sticky build. A tab-level page (Juegos) has no back link, just the title.
   - The **section heading** pins under it at `top: 44px`, full-bleed and opaque so the full-bleed rows cannot slide
     visibly past its edges. The "stacked" push is free: each heading is confined to its own `.lgroup`, so an
     arriving section evicts the previous heading (measured: "Sin datos 49" 97 → pushed out by "Borradores").
   - **Exactly one focusable back control at all times** — `inert` toggles between the in-page link and the bar's,
     so the accessibility tree never carries a duplicate "Juegos".
   - A new screen always starts at scrollTop 0, so the bar never appears on a page you never scrolled.
   Harness: **58/58**. Rhythm at rest unchanged (title row → field 16, field → heading 32, heading → cover 16.5).

7. **On Juegos the pinned tier is the search itself, not a title bar.** Decision 6 exposed the problem: the bar said
   "Juegos" and the heading pinned under it said "Juegos del club 435" — **71.5px of pinned chrome spending itself
   on the same word twice**, while the search, the page's one job (decision 1), sat 1,200px up. Now scrolling pins
   the 48px field with "Juegos del club 435" under it. Pendientes, which has no search, keeps back + title.
   Developer picked "The search field (Recommended)" over dropping the pinned heading too, a magnifier that jumps
   back up, and leaving the repetition.
   **Built as the SAME input pinning, not a copy inside the bar** — so unlike the back link (which needed `inert`
   to avoid a duplicate), there is never a second search to keep in sync. Verified: exactly one `#q` in the DOM.
   **Padding compensated in the margins so the resting rhythm is untouched**: `.search` gains `12px -16px 0` margin
   and `4px 16px 8px` padding, `.search + .lgroup` drops 24 → 16, and the measured numbers are unchanged —
   title row → field **16.0**, field → heading **32.0**, heading → cover 16.5. Pinned tier is 60px, so the section
   heading's sticky `top` is a `--bar` var (60 on Juegos, 44 elsewhere).
   **A real bug the harness caught, the same trap as 069 decision 61:** the new 8px of bottom padding pushed the
   suggestions dropdown to **453**, five pixels *under* the 292px keyboard (448). Fixed by anchoring `.sugg` to the
   field (`top: calc(100% - 4px)`, inset 16px) rather than to the padded sticky block — back to **445**, 3px clear.
   **A second bug, caught by an assertion:** stuck-detection compared `getBoundingClientRect().top` against 0, but a
   sticky element pins to the *scroller's* top edge (y=53), not the viewport's. Now compared against the scroller.
   Harness: **59/59**.
