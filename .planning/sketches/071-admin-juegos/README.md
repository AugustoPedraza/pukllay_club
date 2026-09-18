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

## What it draws (decisions 1–9, `notes/juegos-ui-redesign.md`)
- **One job: find one game.** Title `Juegos` + a 48px search field, no filter chips.
- **Picking a game opens its editor** (sketch 063's screen — stubbed here). The search is pure navigation, so a
  game row carries a **chevron** (D-19i).
- **Under the search, all 435 games newest first**, `Mostrar más · 50 de 435` — the search answers "I know the
  name", the list answers "what did we just add". Justified by D-19l and by measurement (see below).
- **Adding lives in a "+" header icon and in the search**: the sheet has the BGG field and a "Crear a mano" path;
  the search offers **Agregar desde BGG** for a pasted id/link and **Crear «texto»** on no match.
- **One list, three collapsible groups** (decision 8, round 2): `▾ Sin datos 49` · `▾ Borradores 1` ·
  `▴ Juegos del club 385`, collapsed by default, partitioning the catalog (49 + 1 + 385 = 435). The Pendientes
  page and its badge are gone. **This reverses D-19g for Juegos** — reconciled as: D-19g still governs real work
  queues (Estantes' Afuera / Sin ubicar), while a catalog groups its own rows, since "sin datos" is an attribute
  of a game rather than a separate work item. Needs recording in CONTEXT as an amendment, not a contradiction.
- **A group header is a tonal band with a leading caret** (decision 10) — measured, a header and a game row shared
  font size, colour, background and trailing-icon position exactly, leaving only weight (and the app ships Inter in
  400/600 only). The band, the leading disclosure caret and the 44-vs-68 indent now separate them. App-wide: the
  same `.lhead` is used by 069 and 070.
- **One tinted mass, two left edges** (decision 12) — the catalog has **no header**: the page, the tab and the
  pager (`50 de 385`) already name it, and a second tinted band is what kept the page reading as stripes. The
  caret takes a row cover's 40px leading slot so band text lands at 68 with row text (edges were 16 / 44 / 68).
- **Two units, not three stripes** (decision 11) — "Sin datos" + "Borradores" join into one contiguous block
  (hairline seam), then 32px, then "Juegos del club" welded to its rows. Visible gaps **24 / 0 / 32 / 0**, no two
  alike. Three equal bands with equal air had measured 44/16/44/16/44 and read as "rayado".
- **The search hides on scroll-down, returns on scroll-up** (decision 9) — *not* collapsed to an icon, which
  measured as 16px saved (a quarter of a row): 0 extra rows at 375×667 and a tap to undo. Hiding gains a row on
  every viewport for free.

## Pinned context while scrolling (decisions 6-7, D-19n)
A long list keeps its context in two pinned tiers, the pairing both design systems use (iOS pins plain-table
section headers *and* collapses a large title into the nav bar; M3 has sticky list subheaders *and* a collapsing
top app bar). Measured first: on Pendientes at scrollTop 1500 the page title, the back link **and** the section
heading are all off screen at once, leaving 11 rows with no context and the back link 1,500px away. Sin datos is
**3,307px** tall; the fully paged Juegos list is **27,664px** (~45 screens).
- **Pendientes / editor** — a 44px page bar (`‹ Juegos` + title at 17/600) pins once the title row goes behind it.
  It is an absolute overlay, so at rest it costs zero layout. `inert` toggles between the two back controls, so
  exactly one is ever focusable.
- **Juegos** — the pinned tier is the **search itself** (decision 7), because a title bar here would repeat the
  word the pinned heading already says. It is the same input pinning, not a copy, so there is no second search.
- **Both** — the section heading pins under the tier, full-bleed and opaque. The "stacked" push is free: each
  heading is confined to its own section, so an arriving one evicts it.

## Verification (`node .planning/sketches/071-admin-juegos/verify.js`)
**59/59 passed**, no page errors. Highlights:
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

- Pinning: bar 44px and inert at rest, layout byte-identical to the pre-sticky build (phead 69, field 129,
  heading 209, cover 244.5); heading flush under the tier (0px), opaque, full-bleed; exactly one focusable back
  control; the push evicts the previous heading; a new screen always starts at scrollTop 0.

**Caught by looking at the screenshots, which the measurements passed:** every cover rendered as an empty box —
the R2 thumbnails are `loading="lazy"` and the shot fired before they decoded. The harness now forces eager
loading and waits for decode before each screenshot, so the shots show what the developer actually sees.

**Caught by the harness while adding decision 7:** the sticky search's new 8px of bottom padding pushed the
suggestions dropdown 5px *under* the 292px keyboard (453 vs 448) — the same trap 069 decision 61 hit. Fixed by
anchoring the dropdown to the field rather than the padded block. And stuck-detection compared against viewport 0
when a sticky element pins to the *scroller's* top edge (53).

## Why there is a list under the search at all
Measured before building, the same argument that produced D-19l on Web: idle Juegos is title + field ≈ **132px**
of content, leaving ~**403px** blank at 375×667 (60%) and ~**580px** at 390×844 (69%) — worse than the Web page
the developer called "too empty" (its worst was 449px / 62%).

## Open for review (choices made without asking)
1. ~~Every row repeats "● Sin datos"~~ — **resolved by decision 8**: the group heading names the state, so a row
   never repeats it. A row's second line is the year, or nothing.
2. **The catalog's second line is the year alone** ("2020"), which repeats down the page. Given the list is
   newest-first, recency ("hace 2 días") may earn the line better — or the year may be worth keeping because it
   is what tells two editions apart (065 round 3).
3. **No prompt line** ("¿Qué juego buscás?", 17/600). Estantes has one because its page is otherwise empty; here
   the placeholder carries it and a prompt would be a third text block above the list.
4. ~~Collapsed groups sit at a 60px pitch~~ / ~~the catalog band carries the same weight as the work bands~~ —
   **both resolved by decisions 11 and 12**: the pitch was the stripe, and the catalog now has no header at all.
5. **Collapse state does not persist** — every visit opens with the work groups closed and the catalog open.
6. Copy not yet reviewed: "Juegos del club", the add sheet's hint, "Crear a mano · Para un juego que BGG no
   tiene", and both group hint lines.

## Not drawn here
The editor itself (sketch 063 — this sketch only designs how you reach it), Ordenar (Juegos has no manual order),
Retirar/Publicar lifecycle (they live in the editor), and the enrichment `pending`/`failed` row states from 061
(the add flow shows the live fill-in, but a failed row + Reintentar is not drawn yet).
