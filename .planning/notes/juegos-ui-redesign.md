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

## Round 2 (2026-09-18) — one list, collapsible groups, and the search that gets out of the way

Developer: *"But I want juegos, pendientes and borradores all at a single list. and the scroll show «transform» the
search into an icon that is «transformed» again into a search when the scroll goes to top. with that we can get more
space for show the «current scrollable list». Also I been thinking what if we use a collapsable list(borradores,
«pendientes» and juegos?)"*

8. **One list, three collapsible groups, collapsed by default.** `▾ Sin datos 49` · `▾ Borradores 1` ·
   `▴ Juegos del club 385`, the two work groups on top. The Pendientes page and its count badge are **deleted**.
   Developer picked "Collapsible groups, collapsed by default (Recommended)" over putting the work groups below the
   catalog, over non-collapsible sections, and over keeping the Pendientes page.
   **This reverses D-19g for Juegos, and the reversal was flagged before building, not after** — D-19g (069 restart
   decision 59) says pending work lives behind a header badge, *never as lists on a task page*, and Estantes'
   Pendientes page is built on it. The reconciliation recorded with the decision: **D-19g keeps governing real work
   queues** (Estantes' Afuera / Sin ubicar, where "no shelf" is a genuinely different state), **while a catalog
   groups its own rows**, because "sin datos" is an *attribute of a game*, not a separate work item. Estantes is
   unaffected. This needs to land in CONTEXT as an amendment to D-19g, not a silent contradiction.
   - The groups **partition** the catalog — 49 + 1 + 385 = 435 — so a game is never in two of them. Precedence:
     draft → Borradores, else no data → Sin datos, else → Juegos del club.
   - The heading is now a real control, so it is **44px** (it was 27.5px of plain text). `.search + .lgroup` drops
     24 → 8 to pay for the 8px its text gained inside that box: field → heading text is back to **32**.
   - The caret is a **trailing chevron-DOWN that rotates 180°**, never a "›" — under D-19i a chevron-right means
     "this row opens another page", which a group header must not claim. Trailing also keeps the heading text at
     16px, aligned with the title and the hint (a leading caret would have pushed it to 40).
     `chevD` had to be added to the icon set — **the exact key 070 shipped as an empty SVG**.
   - **A row never repeats its group's state.** This is flag 1 from round 1, resolved by the structure: under a
     heading reading "Sin datos 49", all 49 rows saying "● Sin datos" was pure noise. A row's second line is now
     the year, or nothing (the 49 have no year either). The group names the state; the row names the game.
   - Opening a group **keeps the tapped heading exactly where the finger left it** (measured: 197.0 → 197).

9. **The search hides going down and returns going up — it does not become an icon.** Developer proposed the icon;
   measured before building, it does not pay:

   | 375×667, usable 547px, row 64px | Rows visible |
   |---|---|
   | Search pinned (decision 7) | 7 |
   | Search → 44px icon bar | **7** — no gain |
   | Search hidden | 8 |

   An icon saves only **16px**, a quarter of a row, so across 360/375/390 it gained +1, **0**, +1 rows *and* cost a
   tap. Hiding it outright gains +1 on every viewport for free and needs no new affordance to learn (Material's
   `enterAlways` top-app-bar behaviour; iOS Safari's toolbar). Developer picked "Hide on scroll down, return on
   scroll up (Recommended)".
   Measured after building, rows visible at rest → with the search away: **360×640 3→7 · 375×667 3→8 · 390×844 6→10**.
   It never hides while the field has focus (its dropdown is open there) or within 140px of the top; the group
   heading pins to the very top while the search is away (`--bar` → 0).

**Process failure worth recording:** the decision-9 scroll logic silently did not land — a scripted `replace()` did
not match (a comment word differed) and no-op'd, and the count I checked to "confirm" it (`hidesearch` × 3) was
counting only the CSS. The harness caught it three checks later. A string-replace that must match is worth asserting
on, not eyeballing a count; the later edits in this round assert and fail loudly instead.

Harness rewritten for the new structure: **53/53**.

10. **A group header must not read as a row: a tonal band and a leading caret.** Developer: *"Visually the row for
    «sections» are almost the same that row of a game"* — and measured, they shared **four attributes exactly**:

    | | Group header | Game row |
    |---|---|---|
    | Font size | 15px | 15px |
    | Text colour | rgb(35,19,57) | rgb(35,19,57) |
    | Background | transparent | transparent |
    | Trailing icon | 20px at **x=339** | 20px at **x=339** |
    | Height | 44 | 64 |
    | Weight | 600 | 400 |
    | Text left | 16 | 68 |

    Only weight and indent separated them — and the app self-hosts Inter in **400 and 600 only**, so 600-vs-400 was
    the entire weight range available. **Root cause was decision 8:** while the heading was plain static text,
    D-19j's adjacent ranks (section 15/600 › row name 14–15) were fine; turning it into a 44px control with a
    trailing icon gave it a row's exact anatomy.
    Developer picked "Tonal band + caret moves left (Recommended)" over band-only, a quieter label rank, and moving
    the caret alone. **Three of the four now differ:** a full-bleed `--color-surface` band (the classic sticky
    section-header treatment, and it makes the pinned-opacity requirement natural rather than a patch); the caret
    moves to the **leading** edge, where a right-pointing caret is a disclosure triangle rather than a navigation
    chevron (a D-19i "›" is always *trailing*); and header text sits at 44 against the row's 68.
    Measured both themes: heading on the band **14.84:1** light / **12.25:1** dark, count 5.33 / 6.2 — all above 4.5.
    Caret at x=16 vs the row chevron at x=339; band full-bleed at 375.
    **App-wide:** `.lhead` is the same component in 069 (Pendientes) and 070 (Otras filas), so the band and leading
    caret belong to D-19g-bis, not to Juegos alone.

Harness: **57/57**.

11. **Full-page balance pass: two units, not three stripes.** Developer: *"Now review the full page add improve the
    balance and hierarchy. And the color you added didn't fix it since now looks «rayado»"* — correct, and "rayado"
    is exact. Audited at 375×740, the page measured **44 / 16 / 44 / 16 / 44**: three equal bands with equal air, a
    repeating 60px pitch with nothing dominant.

    **Five findings from the audit:**
    1. The stripe was literal — a repeating band/background pitch below the search.
    2. **One component, two behaviours, both on screen:** a *collapsed* band floated with 16px under it; an
       *expanded* band was welded to its rows at 0. Same element, contradictory attachment.
    3. **Unequal things, equal weight:** "Borradores 1" was styled identically to "Juegos del club 385".
    4. **The rhythm tuned in decision 8 had gone stale and was not re-measured.** `field → heading text = 32` was
       set while the heading was bare text; decision 10 gave it a visible band edge, so the real visible gap had
       silently become **20**. This project's own rule — *box gaps lie, measure what you can see* — cutting the
       other way, against a number I had tuned myself.
    5. Nothing anchored the page under the search; the eye dropped onto three identical bars.

    Developer picked "Work groups join; catalog leads (Recommended)" over one grouped list of all three, over
    banding only the work groups, and over dropping the band entirely.
    **Now:** "Sin datos" and "Borradores" are **one contiguous block** (touching, split by a `--color-border`
    hairline — they are the same kind of thing), then **32px**, then "Juegos del club" **welded to its rows** as the
    page's body. Measured visible gaps: **24 / 0 / 32 / 0** — no two alike, so there is no pitch to read as a stripe.
    Margins are **back-solved from the visible edges**: the field's border bottom is 177 but `.search` carries 8px of
    its own padding and `.lhw` another 4, so 12px of margin yields a visible 24 and 28 yields a visible 32.
    `.wblock .lgroup + .lgroup` (0,3,0) has to outrank the generic `.lgroup + .lgroup` (0,2,0) or contiguity loses.

    **Still open from finding 3:** the catalog band carries the same fill and weight as the two work bands. Grouping
    fixed the stripe and the reading order, but if the catalog should visibly *lead* rather than merely sit apart,
    the next move is the option not taken — band only the work groups, and let the catalog's header be plain text
    that gains its band when it pins.

Harness: **61/61**, and it now asserts the gaps against the band edges (24 / 0 / 32 / 0) plus "no repeating pitch",
so this cannot silently come back.

12. **Tried and reverted: dropping the catalog header.** Built as `193d10c` and reverted at the developer's request
    ("undo that last change") before it settled. What it did: removed the `Juegos del club 385` band entirely so the
    page carried **one** tinted mass, and moved the group caret into the 40px slot a row's cover occupies so band
    text landed at **68** with row text (two left edges instead of three).
    **Reverted state is decision 11's:** the catalog band is back, and the page measures two tinted masses
    (92px work block, void 32, 44px catalog band) with text left edges at **16 / 44 / 68**.
    **The two findings that prompted it still stand and are still unfixed**, so they stay on the open list:
    - a void between two tinted masses still reads as banding (the residual "rayado");
    - the page has **three text left edges** — title/caret/cover at 16, band text at 44, row text at 68 — which
      breaks rhythm independently of any colour. This one was a defect introduced by decision 10, and the revert
      restored it, so it is worth fixing on its own whatever happens to the catalog header.
    Harness back to **61/61**.
