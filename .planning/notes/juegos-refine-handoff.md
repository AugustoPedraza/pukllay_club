# Handoff — refine the admin "Juegos" tab (fresh session)

**Written:** 2026-09-18, after sketch 071 decisions 1–11 (12 was built and reverted).
**Pattern:** the same one that produced 069, 070 and 071 — `/gsd-sketch --quick`, one question at a time, measure
before building, look at the screenshots, record every decision.

## How to run it
```
/gsd-sketch --quick Refine the admin Juegos tab — read .planning/notes/juegos-refine-handoff.md first
```

## Where things stand
`.planning/sketches/071-admin-juegos/index.html` — standalone, hand-written, uses `../069-estantes-ubicar/games.js`
(434 real games, real R2 covers) and `../themes/default.css`. Serve with `python3 -m http.server 8765` from the repo
root. Tools: **Tema · Teclado · Grupos (Cerrados/Abiertos)**. No variants left in the file.
Harness: `node .planning/sketches/071-admin-juegos/verify.js` — **61/61**, `SHOTS_DIR=` to place screenshots.

**The page today:** title `Juegos` + a `+` icon · a 48px search · a tinted block of two collapsed groups
(`Sin datos 49` / `Borradores 1`) · 32px · a tinted `Juegos del club 385` band · the games, newest first, paged.

**Settled — decisions 1–11** (full text and every measurement in `.planning/notes/juegos-ui-redesign.md`):
1. The one job is **finding one game**. 061's four `estado` chips are gone — the dev DB is 434 published / 1 draft /
   0 retired, so they would filter 435 into 435.
2. Picking a game **opens its editor**; the search is pure navigation, so a game row keeps a chevron (D-19i).
3. **All games under the search, newest first**, `Mostrar más · 50 de N` (the search answers "I know the name", the
   list answers "what did we just add").
4. **Adding lives in the `+` header icon AND in the search** — a pasted BGG id/link offers *Agregar desde BGG*, no
   match offers *Crear «texto»*. 41 games have no BGG id, so the by-name path is real.
5. *(superseded by 8)* A Pendientes page behind a count badge.
6. **D-19n** — a long list keeps its context in two pinned tiers (44px page bar + sticky section heading).
7. On Juegos the pinned tier is **the search itself**, not a title bar.
8. **One list of collapsible groups** — `Sin datos` / `Borradores` / `Juegos del club`, partitioning the catalog
   (49 + 1 + 385 = 435), work groups collapsed by default. Deletes the Pendientes page and badge.
   **Amends D-19g as D-19g-bis** (recorded in CONTEXT + BENCHMARK): D-19g still governs real work *queues*
   (Estantes' Afuera / Sin ubicar — unchanged); a *catalog* groups its own rows, since "sin datos" is an attribute
   of a game, not a separate work item.
9. The search **hides on scroll-down, returns on scroll-up** — measured, collapsing it to an icon saves 16px (a
   quarter of a row), gaining 0 rows at 375×667 *and* costing a tap.
10. A group header is a **tonal band**, because it and a game row otherwise shared four attributes exactly.
11. **Two units, not three stripes** — the two work groups join into one contiguous block (hairline seam), then 32,
    then the catalog band welded to its rows.

**Tried and reverted — decision 12** (`193d10c`, reverted by `b1d6c49`): dropped the `Juegos del club` band
entirely (one tinted mass) and moved the caret into a row cover's 40px slot so band text landed at 68. The
developer asked to undo it. It is in history if any of it is wanted back.

## What to refine first — the two open findings from the last audit
Both are measured, both are still true in the current build:

1. **A residual stripe.** Down the page: void 20 → **TINT 92** (work block) → void 32 → **TINT 44** (catalog band)
   → rows. Two tinted masses with a void between them still read as banding — this is the "rayado" the developer
   flagged twice. Decision 12 was one answer to it; there are others (band only the work groups and let the catalog
   header be plain text that gains its band when it pins; invert which block is tinted; drop the tint entirely and
   separate by caret slot + alignment + weight).
2. **Three text left edges.** Page title, band caret and row cover start at **16**; band text at **44**; row text at
   **68**. Reading down the page the text aligns with nothing. **This is a defect introduced by decision 10**, it
   has nothing to do with colour, and it is worth fixing on its own whatever happens to the catalog header. The fix
   that was reverted with 12: give the caret the same 40px leading slot a row's cover occupies (16..56) plus 12px,
   so band text lands at 68 exactly with row text — two edges, 16 and 68, which is also the iOS/Material convention.

## Also still open (smaller, from round 1)
- The catalog row's second line is the **year alone** ("2020"), repeating down a newest-first list. Recency may earn
  the line better — against 065 round 3's reason for keeping año (it tells two editions apart).
- **No prompt line** ("¿Qué juego buscás?", 17/600). Estantes has one because its page is otherwise empty.
- **Collapse state does not persist** — every visit opens with the work groups closed.
- Copy not reviewed: the add sheet's hint, "Crear a mano · Para un juego que BGG no tiene", the group hint lines.
- **Not drawn at all:** the enrichment `pending` / `failed` row + **Reintentar** (real shipped behaviour, no design).

## The rules to carry (CONTEXT `01.8.2-CONTEXT.md`, D-19a–n + D-19g-bis)
- **One main job per page** (D-19j); a one-job page may list its siblings below it (D-19l).
- **D-19g-bis** — work queues go behind a badge; a catalog groups its own rows. Group headers: partition the list,
  collapsed by default for work groups, a real 44px control on a **tonal band**, caret never a trailing "›"
  (D-19i reserves that for navigation), the tapped heading stays put when opened, and **a row never repeats its
  group's state** (the group names the state, the row names the thing).
  **Bands must not repeat into a stripe:** same-kind groups join contiguously (gap 0), a different kind is
  separated, and a band is always welded to its own rows. Gaps are back-solved from **visible edges**.
- **D-19n** — a long list keeps its context: a 44px page bar (absolute overlay, zero layout cost at rest; `inert`
  keeps exactly one focusable back control) + a sticky section heading; on a search-first page the search pins
  instead and hides on scroll-down.
- **Sheets** (D-19e): 44px ✕, no Cancelar row. **Destructive = centred dialog** (D-19f), but removing from a
  curated list is not destructive (D-19k). **Status = dot + text** (D-19h). **Kind = quiet lowercase tag; count =
  neutral pill bottom-right** (D-19m).
- Type ranks (D-19j): title 22/600 › prompt 17/600 › 48px field › section 15/600 › row names 14–15 › chips 12–13.
- Spanish is **Argentine voseo**; mobile first; no age facet.

## Working agreement (it is what made 069, 070 and 071 work)
- **One question at a time**, 2–4 options with a recommendation. Build variants only when asked, as tools toggles,
  and remove the losers once one is picked.
- **Measure before building and after every change**, and **look at the screenshots**.
- **Record every decision** (the developer's words + the measurements) in `.planning/notes/juegos-ui-redesign.md`,
  continuing the numbering; app-wide rules also go to `01.8.2-CONTEXT.md` and `01.8.2-BENCHMARK.md`.
- Sketches show only the UI being designed. Next free sketch number: **072**.

## Measuring toolkit + the traps this session actually hit
- Serve `python3 -m http.server 8765`; `playwright-core` from the npx cache (loader in `verify.js`),
  `channel: 'chrome'`, viewports 360×640 / 375×667 / 375×740 / 390×844, `deviceScaleFactor: 2`.
- Hide `#tools` before real clicks. After scripted edits, extract the inline `<script>` and `node --check` it.
- The simulated keyboard is 292px; dropdowns and sheets must end above it.
- **A screenshot lied twice**: two byte-identical bands looked like different tints (simultaneous contrast). Sample
  raw pixels before believing a colour difference — and park the cursor off-canvas, since a stray hover really did
  darken a band in an earlier shot.
- **Lazy covers**: R2 thumbnails are `loading="lazy"`, so shots fired before decode showed empty boxes. `verify.js`
  forces eager loading and waits.
- **Re-query after any render**: a check clicked a group open then clicked a *stale* node to close it, leaving the
  page mutated so every later measurement was silently wrong (a "seam" read 3162px).
- **A scripted `replace()` that must match should assert**, not be eyeballed — one silently no-op'd and the feature
  simply did not land.
- **Sticky pins to the scroller's top edge (y=53), not the viewport's** — compare against the scroller.
- A **field** is measured from the title *row*; a **band** from its own visible edge. Box gaps lie in both directions.
- Dev DB is real and worth querying:
  `PGPASSWORD=postgres psql -h localhost -U postgres -d pukllay_club_dev`.
  Juegos: 434 published · 1 draft · 0 retired · **49 with no cover, no description and no year** (published, live) ·
  27 with no `weight_band` · 41 `no_bgg_id` · 8 `bgg_missing`. The fixture's 49 thumb-less games *are* those 49.

## After Juegos settles
1. **Sketch 072 — the game editor.** Every path on Juegos ends there and it is still sketch 063's design, which
   predates everything settled since. Four verified contradictions: "Unidades" vs **Copias** (scope note #18); an
   **in-sheet** Retirar confirm vs **D-19f**'s centred dialog; a shelf picker with no per-copy position vs
   **D-01/D-00c**; and "a pencil on every value" vs **Web decision 17**, which removed the pencil. It should also
   absorb the enrichment pending/failed row + Reintentar.
2. **Sketch 074** — staff tab bar on public pages (D-14); the last item in CONTEXT's pre-planning sequence.
3. `/gsd-sketch --wrap-up` to refresh the stale `sketch-findings-pukllay_club` skill (D-17), then
   `/gsd-plan-phase 01.8.2`.

## Prompt to paste in the fresh session
```
/gsd-sketch --quick Refine the admin Juegos tab — read .planning/notes/juegos-refine-handoff.md first
```
