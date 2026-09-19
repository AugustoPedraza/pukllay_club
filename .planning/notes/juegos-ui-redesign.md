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

13. **Two text left edges, not three.** The first refinement of the fresh session, taken on its own — decision 12
    had bundled this with a colour change and was reverted as one, so this round moved only the indent.
    Measured at 375×740, the page read a **16 / 44 / 68** ladder: page title, search field, band caret and row cover
    at **16**; band text at **44**; row text at **68**. Reading down the page the text aligned with nothing, and the
    44 belonged to no other element on the screen. Root cause was decision 10 — outdenting header text to 44 was one
    of the four separators it introduced.

    A row's text **cannot leave 68** (its 40px cover holds it there), so the band is what moves, and there are
    exactly two ways to two edges. Both were built as a `Sangría` tools toggle and measured rather than argued:

    | | text left edges | caret x across the 3 bands |
    |---|---|---|
    | Actual | 16 / 44 / 68 — three | 16, 16, 16 |
    | **A Ranura** | **16 / 68** | **16, 16, 16** |
    | B Título | 16 / 68 | **126.1, 126.9, 181.9** — ragged |

    Developer picked **"A Ranura — band text at 68 (Recommended)"**. The caret now takes the same **40px leading
    slot a row's cover occupies** (20px caret + 24px margin + the existing 8px flex gap = 32), so band text lands at
    **68** in the row-text column while the caret stays **left-aligned at x=16** with the title, the field and the
    covers. Both edges hold: **16 and 68**, the iOS/Material keyline pair.

    **B was rejected on measurement, not taste:** aligning band text with the page title read well as a page-level
    section, but the caret then follows the count, so its x moves with the label — a **56px spread** across three
    bands, visible in the screenshot, not just in the numbers. It also floated the band **52px left of its own rows**,
    against decision 11's welding, and returned the caret to the trailing side decision 10 had moved it off.

    **What this spends:** decision 10 separated header from row on four attributes and indent was one. Three still
    differ — tonal band, icon slot (16 vs 339), height (44 vs 64) — plus weight (600/400) and full-bleed, so the
    separation holds without it. The CSS comment and the harness check that asserted the *old* rule
    (`headTextLeft !== rowTextLeft`) were rewritten to assert the new one rather than deleted.

    **A screenshot nearly lied a third time:** the open-group shot showed the hint line *"Se ven en la web sin tapa
    ni descripción."* hanging left of the band label, and it read as a third edge returning. Measured, the hint is at
    **16** — one of the two edges — so the open state is also 16 / 68. The at-rest edge check had not sampled it
    (the hint only exists when a group is open), so a second check now covers the open state.

Harness: **64/64** (61 + two-edges, row-text column, no ragged caret, and the open-state edge check).

14. **The tint marks the work block, not every group header.** The residual "rayado" — the finding decision 11
    could not reach and decision 12 was reverted for attempting. Measured as raw runs down **x=300**, clear of all
    text, the page ran:

    ```
    35 white (field) / 16 void / TINT 88 (work block) / void 32 / TINT 44 (catalog band) / 195 void (rows)
    ```

    **Two tinted masses floating above a plain page.** Decision 11 had already killed the equal pitch (24/0/32/0);
    what remained was that a void between two tints still reads as banding. Three answers were built as a
    `Franjas` tools toggle and measured at rest and scrolled:

    | | tinted masses at rest | catalog heading at rest | pinned |
    |---|---|---|---|
    | Actual | **2** — 88 + 44 | banded | banded |
    | **A Solo trabajo** | **1** — 88 | plain, welded to its rows | **gains its band** |
    | B Sin tinte | 0 | plain | opaque but **edgeless** |
    | C Invertido | 1 — 44 | banded | banded |

    Developer picked **"A Solo trabajo (Recommended)"**. The tint now marks only the work block, so the page
    carries **one** tinted mass. The catalog is the page's **body**, so its header leads as plain text welded to
    its rows and gains its band **only when it pins** — which is where the band earns its keep, terminating the
    pinned heading over the rows sliding under it. This is also the option decision 11 had already named as the
    next move ("band only the work groups, and let the catalog's header be plain text that gains its band when it
    pins"), so it closes that thread rather than opening a new one.

    **B and C were rejected on measurement, not taste.** B looked calmest at rest (zero tinted masses) but the
    scrolled screenshot showed the failure plainly: the pinned heading is opaque yet **has no edge**, so a half-cut
    cover and a stray "2025" sat directly beneath it with nothing dividing them — and `Sin datos` + `Borradores`
    were left holding together on a hairline alone, undoing decision 11's contiguous block. C put one lavender bar
    mid-page with white above and below, which reads as **more** of a stripe, not less.

    **What this costs, named:** the catalog header now has two appearances over time. That is *not* decision 11's
    finding 2 (a collapsed band and an expanded band contradicting each other **simultaneously on screen**) — it is
    one element changing as it detaches, the standard sticky-subheader convention. At rest that header leans on
    caret-vs-cover, 44-vs-64 and 600-vs-400 to not read as a row; the work-group headers keep their band, so
    decision 10's protection is untouched where a header actually sits adjacent to its own rows.

    **A trap avoided:** the tinted masses are counted from **raw runs sampled down x=300**, not from a computed
    style per element. A per-element check would have said "three headers, one background" and proved nothing about
    what the eye reads stacked down the page — the same class of mistake as trusting a screenshot's colour.

Harness: **68/68** — one tinted mass at rest, the catalog header plain at rest, and pinned it gains `--color-surface`
(compared against the resolved token, not merely "not transparent").

15. **The body group is not collapsible.** Found by the developer the moment they tested decision 14 in a real
    browser: *"This is so weird — which alternative do we have for those rows?"*, with a screenshot of all three
    groups collapsed.

    **A defect in decision 14, not a taste complaint.** Decision 14 justified the catalog's plain header as
    "welded to its rows" — but collapse it and there are no rows, so the justification evaporates. Reproduced by a
    real tap (not the dev toggle) and measured: a plain, **bandless** header stranded above **308px of void**
    (42% of a 740px viewport) with **0 rows on the page**, while the two work headers above it kept their bands.
    Three groups in an identical state, one of them looking different for no reason a user can see.

    | | tinted masses at rest | collapse the catalog → |
    |---|---|---|
    | Decision 14 as built | 1 | plain orphan header, **0 rows, 308px void** |
    | **A Fija** | **1** | **unreachable** |
    | B Sin filas (band it when it has no rows under it) | 1 | banded, but **2 masses** + 0 rows, 308px void |
    | C Siempre (revert 14) | **2** | banded, 2 masses + 0 rows, 308px void |

    Developer picked **"A Fija — the catalog can't collapse (Recommended)"**. The decisive measurement: **B and C
    only restyle the orphan — all three of them still let you reach a Juegos tab with zero games and 42% of the
    viewport blank.** A removes the state instead of painting it, and the control costs nothing to lose:
    collapsing 385 games shows you nothing, and the work groups already sit above it, so there is no scrolling to
    save. The body group renders as a `<span>` caption — no caret, no `data-act`, no `aria-expanded` — so it reads
    as a caption for its list rather than a peer of the two controls above it, and it still gains its band when it
    pins (verified `pinned=true`, `top=53`).

    **Cost, named:** it breaks decision 8's symmetry — two groups collapse, one does not. That is the honest shape:
    the work groups collapse *because* they are collapsed by default and you expand them to work; the catalog is
    the page's resting content. Its caret had been implying "one of three peers" when it never was.

    **A bug caught only by measuring the variant before judging it:** removing the caret dropped the header text
    back to **16**, because the caret is what holds it at 68 under decision 13. That would have aligned the body
    header with the page title while both work headers stayed at 68 — three treatments, and the exact pairing
    decision 13 rejected, reinstated by accident. `.lhead.fixed` keeps `padding-left: 68px`, so the leading slot
    survives the caret.

    **A trap this session re-introduced and the harness caught:** adding clicks before the tinted-mass check left
    the cursor parked on "Sin datos", and `.lhead:hover` swapped `--color-surface` for `--color-surface-2` —
    splitting one contiguous mass into two and failing a real check for a reason that had nothing to do with the
    design. Verified directly: 241,236,253 parked vs **222,212,243** hovered. The handoff warned about exactly this
    ("a stray hover really did darken a band in an earlier shot") and it still happened, so the cursor is now parked
    off-canvas *inside* a `cool()` helper called before colour sampling, rather than remembered at each call site.

Harness: **73/73** — the caption is a span with no caret and no `data-act`, the catalog can never be empty, the
caption keeps the 68 slot, and the caret-rotation check now *produces* the expanded state (since after decision 15
only the two collapsed work groups have carets) and closes the group again, leaving the page as it found it.

16. **The caption gets its own rank, on the 16 keyline.** Developer, pointing at the seam between the tinted work
    block and the catalog caption: *"this is the part that breaks the rythm"*.

    Measured, **two** causes were stacked there, and separating them by variant was what made the answer obvious:

    1. **The caption was typographically identical to the two controls above it** — both `15/600 rgb(35,19,57)`,
       byte for byte. Decision 15 had made it *behave* like a caption while it still *looked* like a peer, so it
       read as a group header that had lost its band and caret: incomplete, rather than a different kind of thing.
    2. **The leading column had a hole.** Down x=16 the page ran `caret · caret · EMPTY · cover · cover` — the
       caption was the only element on the page with an empty leading slot, an indent held open for a caret that
       decision 15 had removed.

    | | type | vs. the controls above | hole at x=16 |
    |---|---|---|---|
    | Decision 15 as built | `15/600` @68 | **byte-identical** | **yes** |
    | **A** | **`13/600` muted @16** | **differs** | **no** |
    | B | `13/600` muted @68 | differs | **yes** |
    | C | `15/600` @16 | **byte-identical** | no |

    Developer picked **"A — 13/600 muted at 16 (Recommended)"**, the only one that answers both. `13/600` muted is
    not a new rank: it is the system's existing **Label (group)** rank, already in the BENCHMARK and matching both
    platforms (iOS 13pt section header, M3 list subheader). Contrast **6.17** on the page background, above 4.5.
    B fixed the read but kept the hole; C closed the hole but left the type identical, so it still read as a header
    missing its decoration.

    **Cost, named:** the caption no longer aligns with the rows it heads — it sits on the **container keyline**
    while its rows sit on the content keyline. That is exactly what a Material list subheader does, and it is the
    right trade here precisely *because* it is no longer a peer of the banded controls: a label belongs to the
    page's left edge, a control belongs to its list. Decision 13 is untouched — the page still measures **16 / 68**.

    **Note the sequence:** decisions 13 → 14 → 15 → 16 are four passes at the same seam, each one exposing the
    next. 13 moved the band text to 68; 14 took the tint off the catalog; 15 removed its caret; and only then did
    the caption's inherited 15/600-at-68 anatomy — correct for a banded control, wrong for a label — become
    visible. Each step was right and each created the next defect, which is an argument for the small-slice
    pattern rather than against it: bundled, none of these would have been separable.

Harness: **75/75** — the caption sits on the 16 keyline with no hole, and carries its own rank *and* its own colour
(`13/600 rgb(103,92,125)` vs the controls' `15/600 rgb(35,19,57)`). The decision-15 check that asserted the old
68 slot was rewritten to assert the new rule, not deleted.

17. **ONE LIST.** The developer, after rejecting every variant built for the two work bands:
    *"none of them makes sense. So as I interpretate it, this is the same «list» but with different content (but
    same rythm). So the «sections» should be integrated it. is iPhone contacts list a good example?"*

    **This is the reframe the previous seven decisions were missing.** Every variant I built — one line, chips, a
    line above the search, off the page entirely — treated the work groups as a **block** to be placed beside the
    catalog. The developer's frame is that there is no block: it is **one list** whose sections happen to hold
    different content, with one rhythm throughout.

    **Is iPhone Contacts a good example? Yes for the rhythm, no for the ordering.**
    - *It fits:* one continuous list where sections are labels *inside* it; **one** header anatomy, repeated, so
      the repetition **is** the rhythm rather than a defect; headers are **not controls**, so they need no caret,
      no 44px target and no tonal band to stop them reading as rows; and sections butt together with no gaps.
      The BENCHMARK already recorded this as the iOS plain-table pattern, so it is not a new deviation.
    - *It does not fit:* Contacts' sections are **alphabetical** — mechanical, evenly distributed, ~26 of them,
      none more "yours" than another — and it solves reaching them with the alphabet scrubber. Ours are
      **semantic and wildly unequal** (49 / 1 / 385), so there is no rhythm of repetition to see and a scrubber
      would be pointless with three sections.

    **What was built and measured:** every section header is now the same component. The harness asserts it as a
    single string across all three — `SPAN|false|false|false|13px/600|rgb(103,92,125)|rgba(0,0,0,0)|30.9|16` —
    `1 anatomy`. Nothing is tinted at rest; a header gains its fill **only when it pins**, which is the one moment
    it must terminate itself over rows sliding under it. Sections butt together (`gaps 0, 0`).

    **The cost, measured and accepted.** Developer chose **"Exceptions first, as built"**: `Sin datos` (49) →
    `Borradores` (1) → `Juegos del club` (385). So the page opens on the 49 cover-less games and the catalog is
    **50 rows / 3,270px (~5 screens)** down. The 49 are impossible to miss, which is what decision 8 wanted; the
    newest-first catalog decision 3 wanted at the top is not there. Rejected: catalog first (the 49 end up 385
    rows down, close to hiding them) and a jump control (a scrubber for three sections).

    **What this supersedes — the real result of the day.** Decisions **10, 11, 13, 14 and 15 existed only because
    there were TWO kinds of header.** With one kind they all dissolve:
    - 10 (a header must not read as a row → tonal band + leading caret) — a caption is not a control, so it cannot
      be mistaken for a row in the first place.
    - 11 (two units not three stripes; gaps 24 / 0 / 32 / 0) — there are no units to space.
    - 13 (the caret takes the cover's 40px slot so band text lands at 68) — there is no caret.
    - 14 (the tint marks the work block) — nothing is tinted at rest.
    - 15 (the body group does not collapse) — **no** section collapses, so the defect it fixed cannot exist.
    - **16 survives and generalises:** the Label (group) rank, 13/600 muted on the 16 keyline, is now what *every*
      section header wears. Two text left edges, 16 / 68, still hold.

    Dead code removed with them: `.wblock` and its gap system, the caret and its rotation, `aria-expanded`,
    `S.open`, the group-toggle handler, and both tools toggles (`Grupos`, `Trabajo`) — nothing collapses, so
    there is nothing to toggle.

    **The lesson worth keeping.** Seven decisions were spent negotiating the relationship between two kinds of
    header, and the answer was to stop having two kinds. Small slices found each local defect correctly and each
    fix was right on its own terms; none of them could question the premise, because the premise was set in
    decision 8 and never revisited. **When consecutive rounds keep re-touching one seam, the seam is not the
    problem — the structure that creates it is.** Four passes at the same 20px of screen (13 → 14 → 15 → 16) was
    the signal, and I read it as progress instead of as a smell.

Harness rewritten for the one-list model: **62/62**. The checks that encoded the superseded rules were replaced
by the rule that replaced them, not deleted — the load-bearing one asserts `new Set(anatomies).size === 1`.

18. **The two exception sections close at rest.** Developer: *"That is better. But «sin datos» and «borradores»
    should be closed at begginng."* — which pays off decision 17's one accepted cost without giving up the one
    list. Measured: the catalog was **3,270px** from the top (50 rows, ~5 screens); it is now **206px**.

    **The design problem this had to avoid:** a collapsible header is a *control*, and a control at a caption's
    rank is exactly what started the decision-10 cascade. Solved by separating two things that had been conflated:
    - **Anatomy stays one.** Fill, rank, colour, height and keyline are byte-identical across all three headers —
      the harness still asserts `1 anatomy` (`rgba(0,0,0,0)|13px/600|rgb(103,92,125)|30.9|16`).
    - **The caret is affordance, not a second kind.** Only the two collapsible sections carry one, which is
      precisely the thing that *tells* you they collapse. A caption with a disclosure caret and a caption without
      are one component with an optional affordance — not the decision-10 problem, which was a 44px control
      wearing a row's exact anatomy.
    - **Where the caret goes.** **Inline, after the count.** Not *leading* — that reopens decision 16's hole in
      the x=16 column. Not at **x=339** — D-19i reserves the trailing slot for "opens a page". Measured: carets at
      x=113/136 against the row chevron at 339. Text edges still **16 / 68**.
    - **Touch floor without losing the rhythm.** A 30.9px caption is under the 44px floor, and padding it to 44
      would visibly loosen the list. The hit box is stretched by a `::after` pseudo-element instead: measured
      **44 / 44** while the visual row stays 30.9.
    - **The body section still never collapses** (decision 15 holds): it is a `<span>` with no caret and no
      `aria-expanded`, so the empty-page state remains unreachable. Decision 8's "the tapped heading stays exactly
      where the finger left it" is restored and asserted.

    **A bug this surfaced, in code I had written an hour earlier:** the pinned-header detection compared only
    against the bar, so a header that had scrolled entirely *out of view* still counted as pinned — with two
    collapsed sections stacked at the top the harness caught **three** headers pinned at once. Fixed by also
    requiring the header's own section to still extend past the bar. It was invisible on screen (an off-screen
    element's background does not matter), which is exactly why the assertion was worth having.

Harness: **68/68**.

19. **The hint line returns, inside an opened section only.** Decision 17 had deleted the per-section hints
    because a paragraph under every header was a second anatomy in a list whose whole point is one. **Decision 18
    changed that premise**: a hint can now only appear where the reader has already opened the section, so it was
    worth re-testing rather than leaving deleted on a reason that no longer applied.

    Two shapes built and measured:

    | | at rest | opened | edges |
    |---|---|---|---|
    | none (as it was) | caption 30.9, catalog at 206 | first row at 175 | 16 / 68 |
    | **A own line** | **byte-identical to none** | first row at 201 (+26) | 16 / 68 |
    | B folded into the caption | caption **47.8**, catalog at **223** | first row at 192 | 16 / 68 |

    Developer picked **A**. It costs the resting list **nothing** — same 30.9px captions, same 206px to the
    catalog, `1 anatomy` untouched, and the harness asserts no `.hint` exists at rest — and spends 26px only in
    the moment the hint is relevant. The hint sits at **16**, so it adds no third text edge.

    **B failed on its own premise, measured:** folding the hint into the caption wrapped the header to **2.78
    lines even while collapsed** and pushed the catalog 206 → 223 — paying at rest, on every visit, for text that
    only matters once the section is open. That is precisely what decision 18 had just bought back.

    **Flagged, not resolved:** the hint is `13/400` muted directly under a `13/600` muted caption at the same
    keyline, so a caption and its hint read as one two-line block rather than a label plus a note. Offered as a
    variant (drop the hint to 12px); the developer took A as built. Worth a look if the pairing ever reads muddy.

Harness: **72/72**.

20. **The section label returns to D-19j's rank.** Developer: *"evaluate all the page to fix hiearchy since the
    balance is broken. The group identifier looks to small and isn't easily identifibled."* Audited the whole type
    ladder, and the complaint was exactly right — **the hierarchy was inverted**:

    | rank | size/weight | contrast | left |
    |---|---|---|---|
    | page title | 22/600 | 17.16 | 16 |
    | search | 16/400 | 17.16 | 16 |
    | **section label** | **13/600** | **6.17** | 16 |
    | row name | 15/400 | **17.16** | 68 |
    | row year | 13/400 | 6.17 | 68 |

    Three findings:
    1. The label organising 385 rows was **2px smaller and 2.8x lower contrast than a single row inside it**.
    2. It **violated D-19j**, this project's own ladder, which puts a list section at **15/600, above** row names.
    3. It was **byte-identical to a row's second line** — `Sin datos` and `2020` both 13 / `rgb(103,92,125)` at
       6.17:1, separated only by weight, and decision 10 established 600-vs-400 is this app's entire weight range.
       A section name carried the weight of row metadata.

    **Cause, and it was mine.** Decision 16 demoted the caption to 13/600 muted *specifically to separate it from
    the banded 15/600 **controls***. Decision 17 deleted those controls. The reason went away; the demotion
    stayed. I also mis-cited the BENCHMARK's `Label (group) 13/600` — that row was measured from a **form**
    section label in sketch 065, not a list section header. D-19j governs the latter, at 15/600.

    | | section | vs row name | vs row year | catalog top |
    |---|---|---|---|---|
    | as built | 13/600 @6.17 | 2px smaller, 2.8x fainter | **identical** | 206 |
    | **A D-19j** | **15/600 @17.16** | same size, heavier | distinct | 211 |
    | B mid | 15/600 @6.17 | 2.8x fainter | distinct | 211 |
    | C versalita | 12/600 caps @17.16 | 3px smaller | distinct | 203 |

    Developer picked **A**. Costs 5px. **Decision 10's confusion cannot return** even though a section and a row
    now share size and colour: they differ by weight (600/400), keyline (16/68) and the 40px cover a row has and a
    section does not — and decision 10's actual problem was a 44px **control** with a trailing icon in the
    row-chevron slot, which has not existed since decision 17. All four differentiators are now asserted, plus two
    guards against the inversion itself: a section is never smaller than its rows, and never identical to a row's
    second line.
    Rejected: 15/600 muted (fixes size, keeps it 2.8x fainter — the inversion partly survives) and 12/600 all-caps
    tracked (earns presence from case rather than size and costs *less* height, but it is a harder, more systemy
    voice than the sentence-case Spanish this admin uses everywhere, and iOS moved away from caps section headers).

    **Pattern worth naming:** this is the second time a rule outlived its reason. Decision 19 restored the hints
    that 17 had deleted for a premise 18 changed; decision 20 restores a rank that 16 lowered for controls 17
    removed. **When a decision is superseded, re-check what was justified by the thing it removed** — the
    supersession note should list what becomes re-openable, not just what is now true.

Harness: **76/76** (ladder holds, all four differentiators, both inversion guards).

21. **Air above a section label, none below it.** The balance half of the same request. With the labels back at
    15/600 the top of the list measured, **text to text**:

    | gap | px |
    |---|---|
    | "Sin datos" → "Borradores" | **15** |
    | "Borradores" → "Juegos del club" | 14 |
    | "Juegos del club" → its first row | **17** |

    **Inverted proximity.** The gap *above* a label was smaller than the gap *below* it, so every label was
    visually attached to the label above rather than to the rows it heads — which is why three strong 15/600
    labels read as one block of headings instead of three sections.

    | | above | below | ratio | chrome |
    |---|---|---|---|---|
    | as built | 15 | 17 | **0.9:1** inverted | 40% |
    | A air above | 29 | 17 | 1.7:1 | 44% |
    | B hairline | 20 | 17 | 1.2:1 | 41% |
    | C weld below | 11 | 9 | 1.2:1 | 37% |
    | **D air above + weld below** | **27** | **9** | **3.0:1** | 43% |

    Developer picked **D**, which is also 8px cheaper than A because the air added above is partly paid for by the
    slack removed below.
    **C failed for the instructive reason:** welding a label to its rows also tightens the gap to the *next*
    header, because a header's bottom padding feeds both — so both ends moved together and the ratio barely
    changed. **Proximity is a ratio; the two ends have to move in opposite directions.**
    B was rejected because the 1px rule would be doing the work instead of proximity, in a list that draws no
    other line above its rows.

    **Two measurement failures worth recording, both mine, both caught:**
    - **Box gaps lied again, and this time there was no box at all.** My first pass measured element edges and
      reported variant A as `0/0/0` — identical to the current build — because the padding lives *inside* the
      header box. The headers are transparent, so a reader can only see where the **ink** is. Every number above
      is text-to-text. This is the third time this project has been bitten by box-vs-visible measurement; here the
      rule is sharper: *if the element draws nothing, its box is not a measurement at all.*
    - **The `1 anatomy` guard fired on a legitimate exception**, and the right response was to make the assertion
      more precise rather than weaker. D gives the FIRST section less leading air (14 vs 26) because the 48px
      search field above it already separates it, while the others follow a label or rows. Height is *spacing*,
      not identity — so the anatomy check now asserts **ink** (fill, rank, colour, keyline) across all three, and
      **two further checks** assert that leading air is uniform after the first and that the first is deliberately
      tighter. The exception is documented in the harness instead of hidden by deleting a field from the guard.

Harness: **80/80** — including a standing guard that a label must sit closer to its own rows than to the label
above it, by a ratio of at least 2:1.

22. **A search-first tab root has no resting title.** The handoff's open question 2 — *"chrome is 43% of usable
    height"* — surfaced by the decision-20 audit and never addressed, deliberately left as a decision rather than
    a fix.

    **The first finding was that 43% was the wrong number.** Chrome is a **fixed 265px**, so the ratio is worst on
    the smallest phone and 43% was measured on the roomiest one:

    | viewport | chrome | % de alto útil | juegos visibles |
    |---|---|---|---|
    | **360×640** | 265px | **51%** | **3** |
    | 375×667 | 265px | 48% | 4 |
    | 375×740 | 265px | 43% | 5 |
    | 390×844 | 265px | 37% | 7 |

    Four variants were built as a `Cabecera` toggle and measured across all four viewports:

    | | chrome | 360×640 | 375×740 | excepciones visibles al reposo |
    |---|---|---|---|---|
    | como está | 265px | 51% · 3 filas | 43% · 5 filas | 2/2 |
    | **A sin título** | **213px** | **41% · 4 filas** | **34% · 6 filas** | **2/2** |
    | B excep. abajo | 174px | 33% · 5 filas | 28% · 6 filas | **0/2** |
    | C ambos | 122px | 23% · 6 filas | 20% · 7 filas | **0/2** |

    Developer picked **A**. The `<h1>Juegos</h1>` is dropped and the `+` moves beside the field (343 → 301px, and
    the `+` keeps `.hacts`' own right edge at 371 so the icon column is unchanged).

    **Why it is not a new idea:** this is **decision 7's own argument applied to the resting page.** Decision 7
    already deleted the *scrolled* title bar because it "repeats the word the pinned heading already says" — and
    the bottom tab bar says **Juegos** and highlights it, persistently, at rest too. The `h1` survives as `.sr`,
    so dropping it costs the eye and not the accessibility tree (asserted: text `Juegos`, ≤1px wide).

    **Scope, checked rather than assumed.** Estantes and Web also carry a `.ptitle`, so this looked app-wide. It
    is not: **Estantes' search is `position: relative` and Web has none**, so Juegos is the only search-first tab
    root and the only page with a `.pbar`. The rule is *a page whose pinned tier is its search has no resting
    title* — Estantes and Web keep theirs, untouched.

    **B and C were rejected on a measurement, not a preference.** Moving the exceptions below the catalog (D-19l,
    a one-job page may list its siblings below it) is the cheapest chrome of the four — and it puts **"Sin datos"
    at 3,467px, 5.0 screens down, behind 50 rows and a *Mostrar más***. That is the *same number decision 18 spent
    itself removing* (3,270 → 206), aimed at the work queue instead of the catalog. Neither exception count is on
    screen at rest (0/2). It buys 91px by burying 49 live games that need data.

    **A seam cleaned up on the way.** The `+` shortens the field, so the suggestions dropdown no longer spans the
    block. Rather than offset it by a magic number (my first pass wrote `right: 68px`, and the correct value was
    58 — it was already wrong), it moved **inside `.sfield`** at `left:0/right:0`, and the harness asserts it
    against the *field's own edges* plus clearance from the `+`. A constant there would have drifted the moment
    the `+` changed size.

    Dead code removed with the title row: `.phead`, `.ptitle`, `.hacts`, and `updateBar`'s `.phead, .ehead`
    fallback — the same hygiene decision 17 applied to `.wblock`.

Harness: **91/91**, including a standing guard that chrome must stay **≤45% of usable height at every viewport**,
measured on the smallest — the check that would have caught 51% being reported as 43%.

23. **The decision-19 flag, checked and closed: it does not reproduce.** Decision 19 took hint variant A as
    built but flagged that a `13/400` muted hint sitting directly under a (then `13/600`, now `15/600`) label on
    the same 16 keyline "may read as one two-line block rather than a label plus a note". Measured with a section
    open, and looked at:

    | | rango | keyline |
    |---|---|---|
    | etiqueta `Sin datos 49` | 15/600 `rgb(35,19,57)` | 16 |
    | hint | 13/400 `rgb(103,92,125)` | 16 |
    | nombre de fila | 15/400 `rgb(35,19,57)` | 68 |

    Gaps, text to text: **label → hint 3.5**, **hint → first row 25.4** (7.26:1).

    **The rank separation already does the work** — 15/600 at full strength against 13/400 muted reads as a
    caption plus a note, not as a wrapped paragraph. The 3.5px binds the hint to its own label, which is the
    *correct* grouping: decision 21 established that proximity is a ratio, and here it points the right way.
    Closed as **verified, not reproduced**. No variants built for a defect that is not on screen.

    One fact recorded rather than fixed: the hint is **byte-identical to a row's second line** (13/400
    `rgb(103,92,125)`, the same as the year) — the exact identity decision 20 added a standing guard against,
    though that guard is about the *label*. It is benign here: the hint sits on the 16 keyline and the year on
    68, and the two never share a line. Deliberate tertiary rank, not a defect.

24. **BGG enrichment: `pending` and `failed`, and the handoff was wrong about them.** The handoff called this
    "the biggest gap — real shipped behaviour with no design at all". Audited against `lib/`, and it **is**
    drawn, in the admin 071 replaces:

    | estado | dónde | qué dibuja |
    |---|---|---|
    | pending | `admin/game_live/index.ex:363` | skeleton en la tapa |
    | pending | `index.ex:242` | `"Juego #<bgg_id> (cargando…)"` |
    | failed | `index.ex:372-380` | `<div class="alert alert-error">` + botón `Reintentar`, **dentro de la fila** |
    | failed | `game_live/form.ex:262-267` | el mismo alert en el editor |

    So the gap is not "no design" — it is **a shipped design that contradicts three rules settled since**:
    1. `alert alert-error` is a red **box inside a list row**. D-19h: a status is a **dot + text, never a pill** —
       and an alert box outweighs a pill.
    2. A `Reintentar` **button inside the row** is a second action per row, when D-19i reserves the trailing slot
       for "opens a page" and decision 2 sends picking a game to its editor.
    3. **`enrichment_status` is filtered by no query anywhere** (`catalog.ex` filters only on `status`). A
       `failed` game is public the moment `status` is `:published`; nothing gates publishing on BGG answering.
       Not a UI defect — but it is why the 49 "Sin datos" games are live and broken on the public site.

    **The column, for the record:** `enrichment_status`, a plain string (`game.ex:48`), declared values
    `pending | enriched | no_bgg_id | bgg_missing | failed` (`game.ex:19`). Live code writes only **pending,
    enriched, failed**; `no_bgg_id` (41) and `bgg_missing` (8) are seed-era values still sitting in the dev DB.
    `enrichment_changeset/2` does **not** `validate_inclusion`, and there is no DB check constraint — so the
    column is unvalidated on every live write path. Oban: `max_attempts: 3`, linear backoff `attempt * 30`.

    **Determined by the rules, not asked:** the row carries it on its **second line** — the slot the year already
    occupies — as a dot + text. No new anatomy, no third text edge (measured 68/68), the row keeps **only** its
    chevron, and Reintentar moves to the editor. It does not repeat the section's state either: a draft is a
    draft whether or not BGG answered, which is what decision 1 actually objected to. `pending` additionally
    takes a skeleton cover and the placeholder name `Juego #<bgg_id>` — the one part of the shipped design that
    was right.

    **What was actually open, and a structural finding that framed it.** A `failed` game is a **draft**
    (`draft_changeset` forces `status: :draft`), and drafts live in **Borradores, which decision 18 closes at
    rest**. Measured: at rest the failed row **is not even in the DOM**. A failure is invisible until you open
    the section. Three ways out were built and measured:

    | | al reposo | costo de chrome |
    |---|---|---|
    | A fila, nada más | **invisible** (la fila no está en el DOM) | 0 |
    | B la sección se abre sola | error completo a la vista | catálogo 213 → **299px (+86)** |
    | **C la cuenta lo dice** | `Borradores 1 ● 1 con error ›` | **0** |

    Developer picked **C**. One line at 360/375/390 (ink ends at x=245, 115px of slack on the narrowest), zero
    cost to the resting page, and it shows **only while the section is closed** — an open section's rows say it
    themselves. **It is decision 18's move again:** an optional affordance on ONE anatomy, not a second kind of
    header, and the harness asserts the ink identity survives it.
    **B was rejected on the measurement:** it hands back 86px of what decision 18 bought, every visit, and
    decides for the reader that they want the section open — a failure you already know about keeps pushing the
    catalogue down forever.

    `ENR` stays in the tools as a **scenario** toggle, not a variant: the dev DB has zero `pending` and zero
    `failed` rows, so it is the only way to see the state at all, and the resting page stays the real 49+1+385.

Harness: **108/108** — 17 new checks, including that a failed row is absent from the DOM at rest (the reason the
caption must carry it), that no `[class*=alert]` exists anywhere, and that `1 anatomy` survives the report.

25. **The row's second line keeps the year — and the reason it was questioned turned out not to exist.** The
    handoff asked whether "recency may earn the line better", against 065 round 3's reason for keeping año ("it
    tells two editions apart"). Both sides were checked against the real database and **both collapsed**:

    - **0 duplicate names** in the 435-game catalogue. The stated justification for año has **zero instances**.
    - **433 of 435 games share one insertion date** (2026-08-10, the CSV import; 3 distinct dates in total). A
      recency line would read "hace 1 mes" on 433 identical rows — strictly worse than the year.

    Then the density argument collapsed too. Measured with the year on and off:

    | | 360×640 | 375×740 | 390×844 | alto de fila |
    |---|---|---|---|---|
    | **A año** | 4 filas | 6 filas | 7 filas | 64px |
    | B sin 2ª línea | 4 filas | 6 filas | 7 filas | 64px |

    **Removing it gains nothing.** `.row` is `min-height: 64px` because of the 40px cover plus padding, so the
    second line fits *inside* the existing height for free (total scroll 3,585 → 3,564px, and those 21px come
    only from the 2 rows whose names wrap). Developer looked at all three in the browser and took **A**.
    A third variant — year only on names sharing a first word (Catan ×4, Wingspan ×4, Dixit ×3; 3 of the first
    50 rows) — was built and rejected: a conditional rule to explain, and a list that looks uneven for no
    visible reason.

    **Recorded, not acted on:** decision 3's "newest first" is a real sort for **2 of 435 games**. For the other
    433 the order is decided by the tiebreaker (id, i.e. CSV row), so the catalogue's stated order is effectively
    import order. It is correct *going forward* — games added one at a time will surface on top, which is what an
    admin wants right after adding — and degenerate only on the imported backlog, so it is a property to know
    rather than a defect to fix. Alphabetical was costed and dropped: reaching Z needs **8 taps of "Mostrar más"**
    at 50 per page, and decision 2 already makes the search the way you find a named game.
    (The sketch's fixture fakes a distinct `added` per game — `added: x.t ? 2000 + i : 0` — so its order is more
    meaningful than the real query's. Worth knowing when 072 or the real build reads from the database.)

26. **The caret is a different GLYPH, not just a different x.** Developer asked to focus on the section headers;
    auditing the three, ink by ink, turned up four things, and this was the one taken first.

    ```
    "Sin datos"        nombre 15/600 x=16..83    cuenta 15/400 x=95..114   caret x=126..140
    "Borradores"       nombre 15/600 x=16..97    cuenta 15/400 x=109..115  caret x=127..141
    "Juegos del club"  nombre 15/600 x=16..130   cuenta 15/400 x=142..170  sin caret
    chevron de fila                                                        x=339..359
    ```

    **The caret was byte-identical to the row chevron** — both `chevR`, both `M9 5l7 7-7 7`. So a closed section
    read `Sin datos 49 ›`, using the exact glyph D-19i reserves for "opens a page", and the page showed **four
    "›" meaning two different things**. Decision 18 had separated them by **position** (x=126 vs x=339) and
    called it solved; decision 10 had already written the rule the right way round — *"a disclosure triangle,
    never a trailing ›, which under D-19i means opens a page"* — and decision 18 kept the position fix while
    losing the glyph rule. **Third time in this sketch that a rule outlived its reason**, and the first where the
    superseding decision contradicted an explicit prohibition rather than merely forgetting a justification.

    | | glifo cerrado | vs chevron de fila | abierta |
    |---|---|---|---|
    | A `›` (como está) | `chevR` | **idéntico byte por byte** | gira 90° |
    | **B `⌄` rota** | `chevD` | distinto | gira 180° → `⌃` |
    | C `▶` maciza | triángulo relleno | distinto de familia | gira 90° |

    Developer picked **B**. Down means expand, up means collapse; neither ever points the way a row chevron does,
    so the collision is resolved **by glyph** and the position fix becomes belt-and-braces rather than the whole
    argument. All three measure the same 14px at x=126, so it costs nothing.
    **C** was rejected because it still points right — it separates by weight rather than direction — and at 14px
    reads small and more systemy than the sentence-case voice this admin uses.
    **`+`/`−` was dropped without building it**, on a real collision: `+` already means *agregar un juego* on this
    very page, beside the search.

    The standing guard is the one that states the rule directly: **every right-pointing chevron on the page is a
    row's "opens a page"** — 99 of 99.

    **Still open from the same audit, not yet taken:** the three counts land at x=95 / 109 / 142 so they form no
    column; the full 375px of a collapsible caption is tappable while its ink stops at x=140 (235px of invisible
    target); and the count is 15/400 — the size of a row *name*, and larger than a row's second line at 13/400.

27. **The pinned header band was 26px of empty tint above its text.** Reported from the device: *"when I
    scroll, the background color isn't aligned, making the text be more aligned to the bottom of what it shows."*
    Measured, exactly right — **26.0px above the text, 0.5 below**, with the text jammed against the band's
    bottom edge.

    **Cause, and it is decision 21's.** That decision set `padding-top: 26 / padding-bottom: 0` on `.lhead` to
    make the *resting* rhythm (air above a label, none below). At rest the caption is transparent, so the padding
    is invisible — it is just air. The instant it **pins** it gains `--color-surface`, and the same padding
    becomes visible empty colour.

    **This is the box-vs-ink trap inverted, and it earns a new line in the rule.** What was on file was *"if the
    element draws nothing, its box is not a measurement at all."* The corollary it lacked: **an element that
    draws nothing at rest but something in another state has TWO geometries, and the spacing tuned for the
    invisible one becomes visible in the other.** Decision 21 optimised the transparent case and never re-checked
    the pinned one — and every pinned assertion in the harness tested *which* header was pinned, never what it
    looked like, so a transparent-state measurement shipped as a tinted-state defect.

    Fix: halve `--pt` onto both sides when pinned. Centres the ink (**13 / 13.5**) and keeps the box height
    byte-identical at 45.5, so the sticky element's flow slot never changes and nothing jumps at the moment it
    pins. Three new guards cover the band's geometry, including the height-unchanged one.

28. **A section label is versalita: 14/600 uppercase, tracked.** Same report: *"I need the look and feel of those
    header looks more different of the rest of the content."* Until now a caption differed from a row name by
    **weight alone** (600 vs 400), plus keyline, cover and chevron — decision 20 put them at the same size and
    colour deliberately. Four differentiators that are all position and weight still read as "a row without a
    picture", because the **text is the same kind**. Case changes the kind.

    Three directions were built and measured; then, on *"something closer to B+C"*, a size scale inside the
    winner. The decisive measurement is **cap height**, not font-size — the only comparison that means anything
    for uppercase:

    | | mayúscula | vs may. de fila | vs minúscula de fila | chrome |
    |---|---|---|---|---|
    | hoy (15 caja baja) | — | — | minúscula 8px | 213px |
    | versalita 12 | 9px | 82% | 113% | 201px |
    | versalita 13 | **9px** | 82% | 113% | 205px |
    | **versalita 14** | **11px** | **100%** | **138%** | **209px** |
    | versalita 15 | **11px** | 100% | 138% | 213px |

    **The scale collapses to two real steps** — the font renders 12 and 13 at the same 9px cap, and 14 and 15 at
    the same 11px — so within each pair the cheaper size wins and the choice is 9px or 11px of capital.
    Developer picked **14**: its capitals match a row name's capitals exactly while reading **138% of the
    lowercase body the eye actually scans**, so it changes category without losing a gram of presence. It is also
    **cheaper than what it replaces** — chrome 213 → 209.

    **Rejected, both on measurement.** A permanent tinted band is the most different at a glance, and it does
    stay **3 separate masses** rather than decision 14's stripe (146..190, 200..244, 258..289 — the air has to
    move out of the caption first, or they merge) — but it costs **24px and a whole row**, and reopens decision
    17's *"nothing is tinted at rest"*, which is what ended seven rounds of band negotiation. 17/600 lower-case
    restores a ladder step but is the **same kind of text, only bigger** — the least answer to what was asked.

    **Four guards fired, and all four were made MORE PRECISE rather than weaker** — the project's own rule for
    exactly this:
    - `every section carries D-19j's 15/600` → every section carries the **same** rank, now 14/600, **plus** a
      new assertion that every label is uppercase.
    - `a section is never smaller than the rows it heads (14 vs 15)` → decision 20 wrote this in **font-size**,
      which is the wrong measurement for caps: a 14px capital is taller than a 15px lowercase. Restated in **cap
      height** (11 ≥ 11) with a second check that it clears the row's x-height by ≥1.25× (138%).
    - `type ranks hold` → the ladder's heading rank updated.
    - `it costs the resting page NOTHING (still 213px)` → decision 24 had **hardcoded** the number, so decision
      28's legitimate 4px saving read as a failure. "Costs nothing" is a *relative* claim; it now measures the
      page with the failure against the same page without it (209 vs 209).

Harness: **118/118**.

29. **The fill is a band drawn around the ink, never the caption's own background.** From the device, one round
    after decision 27: *"When I put the mouse over a header, the text isn't vertically centered to its colored
    row."* Measured on hover: **14px of colour above the text, 1.2 below** — byte-for-byte the defect decision 27
    had just fixed, in the state nobody had looked at.

    **This is the more useful failure of the two.** Decision 27 wrote the general rule — *an element that draws
    nothing at rest but something in another state has TWO geometries* — and then applied it to the **single
    state that had been reported**. `.lhw.pinned .lhead` was patched; `.lhead.tap:hover`, which paints the same
    asymmetric box, was not, and neither was `:focus-visible`, whose ring framed the same empty half. Naming a
    rule is not applying it: **the fix has to be as general as the rule, or the next state carries the defect.**

    The structural fix, rather than a third patch: the fill moves off `.lhead` onto a `::before` anchored to the
    **content box** — which is where the ink is — and grown by `--band` each way. That is centred **by
    construction, in every state, present and future**. Two properties it buys that padding-halving could not:
    - **It moves no text.** The caption's own padding, and with it decision 21's 3:1 resting ratio, is untouched.
      Halving the padding on hover would have centred the band by making the label **jump 13px under the cursor**
      — a worse defect than the one being fixed.
    - **It cannot be forgotten.** A future state that draws gets a centred band for free.

    Pinned keeps a full-height bar (it is a bar under the search, not a highlight), with decision 27's halving
    centring the ink inside it. Two band shapes, one invariant: **the ink is centred in whatever is drawn.**

    Measured after: hover **7 / 8.2** (band 32.2), pinned **13 / 14.2** (band 44.2), and the label's ink top is
    identical hovered and at rest (160 / 160).

    **The guard now enumerates STATES, not the reported one.** It walks rest, pinned and hover, measures anything
    that draws a fill or a ring, and asserts centring for each — plus two traps this round found: that hovering
    does not move the label, and that **`.lhead` itself never carries a background**, since a direct fill is
    precisely how a fourth state would reintroduce the bug. One existing check had to be re-pointed at the band
    (it read `.lhead`'s own background, now transparent by design).

    **The pattern, now at four:** decisions 26, 27, 28 and 29 were all a rule or an assertion outliving its
    reason. 29 adds the sharpest form of it — **a fix can outlive its own rationale at the moment it is
    written**, if it is applied more narrowly than the rule it cites.

Harness: **123/123**.

30. **A Range's rect is still a box: centre the CAP BLOCK.** From the device, with a screenshot: *"still doesn't
    look centered. Be sure to have the correct breath to don't kill rythm."* Decision 29's guard reported hover
    centred at 7 / 8.2 and the band still looked wrong — because that measurement was the text's **range rect**,
    and a range rect is a box like any other:

    ```
    caja de línea   alto 17   (ascendente 14 / descendente 3)
    TINTA real      alto 11   (mayúscula, sin descendente)

    medido por CAJA :  arriba 7     abajo 8.2    <- lo que verificaba el guard
    medido por TINTA:  arriba 10    abajo 11.2   <- lo que ve el ojo
    ```

    **Versalita uses no descenders**, so the line box carries 3px of space the ink never occupies. The project's
    rule was *"measure ink, not boxes"* — applied to element boxes, never to the **text's** box. Third form of
    the same trap in this sketch, and the one that made a visibly-wrong band pass green.

    **Two traps inside the fix, both caught by measuring:**
    - **Glyph-dependent ink.** Measuring the actual text made the states disagree by 2px: the **J of "JUEGOS"
      descends below the baseline**, so `actualBoundingBoxDescent` was 2 for the catalogue and 0 for "SIN DATOS".
      The eye does not centre on the tail of a J. The probe is now an **"H"** — cap height, glyph-independent.
    - **Inverted sign.** The hover band moves the **band**; the pinned bar moves the **ink** (via padding).
      Raising a band is the same as lowering the ink inside it, so the same `--cap` reads as opposite-looking
      expressions, and the first attempt fixed one state while pushing the other from −1.2 to −3.4. Measuring
      `--cap` at 0 showed both states off by the *same* −1.2, which is what identified the single correction.

    Result: **0.0 delta in both** — hover 9.6 / 9.6 (band 30.2), pinned 16.6 / 16.6 (band 44.2). `--cap` is
    0.6px, half the leading, and it changes neither band height nor the caption's padding, so decision 21's
    resting rhythm is untouched.

    **The breath, measured rather than eyeballed** (the second half of the request). At `--band` 5 / 6 / 7 the
    band is 28.2 / 30.2 / 32.2 and its edge lands **24.6 / 23.6 / 22.6 from the next label's capitals**, against
    **33.2 of ink-to-ink between labels** — so none of the three crowds the rhythm and the choice is 2px of heft.
    Took **6**: 9.6px around an 11px cap, a band 2.7× the cap and comfortably lighter than a row's own 64px
    hover. Deliberately not spent as another full round on a 2px seam.

    **The guard now measures the cap block**, with the tolerance tightened from 1.5 to 0.8 — a loose tolerance on
    the wrong metric is how this passed twice.

Harness: **123/123**.

31. **Every pinned bar is the same height.** From the device, scrolling one section and then another: *"when I
    navigate with SIN DATOS, the header doesn't have same height that Juegos del Club."* Measured:

    | sección | `--pt` en reposo | barra pinneada |
    |---|---|---|
    | Sin datos | **14px** | **32,2px** |
    | Borradores | 26px | 44,2px |
    | Juegos del club | 26px | 44,2px |

    **Cause:** the bar *was* the caption's own box, so it inherited decision 21's deliberate first-section
    exception — the first section gets less leading air because the 48px search already separates it. That
    exception is right **at rest** and meaningless **in a bar**: once the label is pinned under that same search,
    it is chrome, and chrome does not inherit a rhythm exception.

    **And I had predicted this and dismissed it.** While building decision 27 I noted the two heights would
    differ and reasoned "only one pins at a time, nobody compares them". The developer scrolled to one, then the
    other, and compared them. *A state the user can reach twice in a row is a state they will compare.*

    Fix: the band is a pseudo-element, so its thickness is **independent of the box**. `--bandp` fixes the bar at
    **44px** (matching `.pbar` and the touch floor) for every section, with no flow change. This also **retires
    decision 27's padding halving entirely** — one mechanism now serves hover and pinned, differing only in
    thickness, and the caption's padding never changes between states at all.

    **The guard that could never have caught it.** Decision 27's check asserted a bar against **its own** resting
    height; decision 29's walked the **states**. The missing axis was **across sections** — three bars measured
    against each other. It now asserts all three are identical, that the height is 44, and, deliberately, that
    the *resting* air still differs by section, so a future "simplification" cannot quietly delete decision 21's
    exception in the name of uniformity.
    The anti-jump guard was also restated: comparing two different sections' boxes proves nothing when one is
    meant to be shorter, so it now asserts that **pinning changes no padding at all**, which is the property that
    actually keeps the flow slot fixed.

Harness: **127/127**.

32. **A tap has a state, and it is one token.** The last unmeasured state on the page. Measured before
    proposing anything: the page had **8 `:hover` rules, 6 `:focus-visible` and ZERO `:active`**, so a press
    painted byte-identical to a hover (both `rgb(241,236,253)`). On a pointer that is harmless — the hover had
    already painted. On **touch there is no hover at all**, so the only feedback a tap ever got was the
    platform's own highlight — and `-webkit-tap-highlight-color` was authored **nowhere**, leaving every
    tappable surface at the platform default: **`rgba(51,181,229,0.4)`, Android's Holo cyan**, a colour that
    appears nowhere in this palette.

    **Taken: one press token, `--color-surface-2` (#DED4F3), on every pressable surface**, with the platform
    flash suppressed at `:root` (the property inherits, so a surface added later cannot reintroduce it).

    | opción | `.row` | `.lhead.tap` | `.tap` pinneada | colores nuevos |
    |---|---|---|---|---|
    | B = hover | #F1ECFD | #F1ECFD | #DED4F3 | 0 |
    | C más hondo | #DED4F3 | #DED4F3 | **rgb(188,177,210)** | **1** |
    | **D (tomada)** | **#DED4F3** | **#DED4F3** | **#DED4F3** | **0** |

    **Why D over B:** a press is a *momentary* state where hover is a *sustained* one, and a momentary state
    needs more contrast to register in the ~100ms it exists. B's #F1ECFD on white is the lightest of the three
    and is the one a phone in daylight would miss. **Why D over C:** C buys a third rank that only a *pointer*
    pressing a *pinned* caption can perceive, and pays a fabricated `rgb(188,177,210)` for it — a value in no
    other part of the system. **The accepted cost of D**, asserted in the harness so it stays deliberate: that
    same pointer-on-pinned-caption case reads press == hover, because that caption's hover is already
    surface-2. Touch, which is what the state exists for, has no hover to collide with.

    `transition-duration: 0s` on the way **in**: the caption's band fades over 120ms, longer than a quick tap,
    so a transitioned press fill would show only partly faded — or, on a fast tap, not at all.

    **Two measurement traps, both caught by controlling first.**
    - **CDP touch does not set `:active`.** An injected control rule painted under `mouse.down()` and *not*
      under `Input.dispatchTouchEvent`. A touch-driven assertion would have passed vacuously. The guards
      therefore press with a **mouse** and say so; real-tap behaviour is confirmed on the device, not here.
    - **Under CSS nesting every style rule carries an empty `.cssRules`**, so a `if (r.cssRules) recurse` walk
      descends into nothing and reports **zero rules on a fully-styled page**. The first two runs of the rule
      audit reported "0 `:hover` rules" and were believed for one step. The walk now tests `selectorText`
      first, and a guard asserts the walk sees >100 rules — *a zero means the walk broke, not that the page is
      clean.*

    **The guard is written against the SHAPE, not the surface** (the decision 27/29 lesson): it enumerates the
    **rules** and asserts **every selector with a `:hover` also has an `:active`**, so a new hover-only control
    fails the day it is written — which is exactly how this defect got in. Negative-tested: injecting
    `.negtest-ctl:hover` turned it red and named the selector.

Harness: **135/135**.

33. **The editor's spine: every value is a row that opens a sheet.** Sketch **072**, round 1. Sketch 063 had
    put *a pencil on every value*; **Web decision 17 removed the pencil** ("one target instead of two"), and
    the editor was the last screen still on the old idiom. Three spines were built and measured at 375×740:

    | | A filas → hoja | B formulario | C mixto |
    |---|---|---|---|
    | bloque del club | **450,6** | 667,9 | **450,6** |
    | página entera | **1145** | 1362 | **1145** |
    | campos en pantalla | **6 de 6** | 4 de 6 | **6 de 6** |
    | toques para cambiar Nivel | 2 | 1 | 2 |
    | **anatomías de fila** | **1** | — | **3** |

    **What decided it was not the height — it was the anatomy count**, and the finding is *intrinsic, not
    sloppy building*. Measured: A is 6 rows, all `<button>`, one trailing shape, and **line 2 is always the
    value**. C is two element kinds, three trailing shapes, and **line 2 is the value on 4 rows and a hint on
    2** — because an inline control *already is* the value display, so its second line has nothing left to
    carry. **You cannot have both "one anatomy" and inline controls.** Same shape as decisions 13→16: several
    passes at one seam that decision 17 deleted by changing the premise.

    A's cost, stated rather than hidden: **one edit is 2 taps** (open the sheet, pick), and flipping a boolean
    costs a modal. Asserted in the harness so a third tap cannot creep in unnoticed.

    **Three defects the green harness was blind to, all found by looking at the screenshots** — the run was
    32/32 while the page was visibly wrong:
    - **The key and the value ran together on one line** ("NombreBrass: Birmingham"). `.fr-k`/`.fr-v` are
      spans inside a button, so as inline boxes they never stacked. Height, contrast and hit-box checks pass
      straight through that: **none of them asks where ink sits relative to its neighbour.** New guard
      measures it as ink, through Range rects.
    - **Every `<select>` in B drew no caret** — `var(--caret-bg)` never existed — so both dropdowns read as
      text inputs. *Comparing a variant against a broken one is not a comparison*; fixed before judging.
    - **Every row in A wore the page chevron `›`, violating D-19i**, which is explicit: *"a chevron means this
      row opens another page. Rows that act in place (show an answer, open a sheet) have none."* Every row
      here opens a sheet. They now carry the disclosure **`⌄`** — Web d17's name button uses it and decision
      26 separated the two glyphs after measuring them byte-identical. The guard asserts the **path data**,
      not the icon's name, for exactly that reason.

    **A fourth trap, in the harness itself.** The 44px touch-floor check was written three ways before it
    could fail honestly: it read `getBoundingClientRect` (blind to a pseudo-element hit box, so the 32px
    switch passed); then hit-tested only the viewport (blind to everything below the fold); then accepted
    `hit.contains(e)`, so the switch's **parent row** swallowed every probe and the check was
    *unfalsifiable*. Negative-testing is what exposed all three — removing `.sw::before` left it green
    three times. It now scrolls the page, skips points covered by a known overlay (the save bar had been
    reported as a small target), and asserts it reached every control in `#main`.

Harness: **31/31** after the losing variants were removed.

34. **A row that opens a sheet carries no chevron — and the ⌄ was not free to borrow.** From the device:
    *"the chevron pointing down isn't the correct affordance since we use that for an open list."* Correct,
    and the round-1 build was wrong twice over:
    - **D-19i already said it literally** — *"a chevron means this row opens another page. Rows that act in
      place (show an answer, open a sheet) have none."* Every row in the editor opens a sheet.
    - **The ⌄ I substituted was reasoned from a note, not from the screen.** Web decision 17 describes the
      row name as "a 44px-tall button with a ⌄ chevron", so I took ⌄ to be the established
      opens-a-sheet glyph. Checked against what is actually built: **070 renders a bare `<h2>` inside that
      button, no glyph at all** — and d17's own note even records the ⌄ *"drew an empty SVG"*. Grepped
      across the corpus, `chevD` is **rendered in exactly one place**: 071's collapse caret. So ⌄ has one
      live meaning, the developer's, and borrowing it would have spent the catalogue's one disclosure glyph
      on a second thing.
    *Reading a decision's prose instead of its artefact is its own failure mode — the note described an
    intent that the sketch never implemented, and nothing flagged the gap.*

35. **The value is the label's subordinate, and it carries the tint.** Removing the glyph opened the real
    question — what says "editable"? Five answers built and measured at 375×740, in both themes:

    | | señal | claro | oscuro |
    |---|---|---|---|
    | A pelado | ninguna | — | — |
    | B acento | tono | ✓ | **✗ 1,17:1 del texto** |
    | C pista | línea fija | +27px, empuja BGG fuera | igual |
    | D anatomía | polaridad | ✓ | ✓ |
    | **D+B (tomada)** | **polaridad + tono** | **✓** | **✓ (con token nuevo)** |

    **What decided it: both platforms put the LABEL first and the VALUE second** in a settings row — iOS's
    grouped table (label ink left, value grey right) and M3's list item (headline = label, supporting text =
    value, which is literally the Android Settings row). This sketch had it **inverted**: key muted 13 /
    value ink 15. Flipping the polarity also separates the club block from the read-only BGG facts
    **structurally** — club reads ink-label/quiet-value, BGG reads quiet-key/ink-value, opposite polarity in
    both themes. **A colour-only signal cannot do that**, which is why B alone failed: dark
    `--color-accent-text` is `#E3D9F9`, 1.17:1 from body text, so tint *and* polarity die on the switch.

    **Rejected, and why a standing hint is not the answer** (the developer asked): the page already teaches
    the rule **from the other side** — the BGG block says *"Vienen de BoardGameGeek… No se editan acá."* A
    positive hint would teach the same lesson twice and, sitting above a block where it is false, imply the
    BGG facts are editable too. It also costs **27px forever for a lesson learned once**, pushes DATOS DE
    BGG off the fold, and contradicts decision 19, which made a section's hint **contextual, not standing**.
    The project's own precedent is already on the record: *"no prompt line — the page is not empty"*;
    Estantes has one *"because its page is otherwise empty"*. The editor is not empty. And D-19o now gives
    every row a real press response, which on touch outteaches any line of text.

    **TODO(palette), raised by the developer and real:** the dark half of this needs a colour the palette
    does not have. `themes/default.css` is a **mirror of `assets/css/app.css`**, gated hex-for-hex by
    `check-theme-drift.sh`, so `--val` is defined **in the sketch**, not the theme. The dark token must clear
    **three** bars at once — ≥4.5:1 on the ground (it is body text), perceptibly distinct from body text, and
    clear of `--color-text-muted` (or it collides with the empty state). Measured over nine candidates,
    **`#9F7AEA` (4.83 / ΔE 65.5 / 1.43)** is the only strong pass. Before shipping: add the stop upstream
    reconciled against app.css's `--pk-ramp-*` envelope, mirror it, re-run the drift check. **It should try
    to beat 4.83:1, not match it** — that makes the value the lowest-contrast text on the dark page, where
    everything else sits at 6.9+.

    **A guard that passed the thing it was written to reject.** The distinguishability check first used a
    contrast ratio with a `>= 1.15` bar — and the rejected variant scores **1.17**, four hundredths above
    it, so the negative test came back green. Contrast ratio measures luminance and **cannot see hue**: the
    accepted light pair is 1.21 and the rejected dark pair 1.17, while the eye reads one as obviously purple
    and the other as identical. Re-measured as **CIE76 ΔE** the same pairs are **29.6 and 10.1**, and a bar
    at 20 sits clear of both. *Decision 30's lesson, in a new place: a loose tolerance on the wrong metric.*

Harness: **46/46**.

36. **The label and its value are one typographic unit.** From the device: *"does the label and its editable
    text below have the correct space?"* Measured as **ink**, cap blocks probed with an **"H"** (decision 30 —
    a real string's descender moves the box and not the eye):

    | | medido | referencia |
    |---|---|---|
    | tinta etiqueta → valor | 9,5 | 10,5 (fila nombre+año de 071) |
    | aire sobre la etiqueta | 17,8 | |
    | aire bajo el valor | 14,7 | → el par quedaba **1,55px bajo** |

    **The gap was fine; the imbalance was leading.** `.fr-k` had no explicit `line-height`, so it inherited
    **1.5** — a 22.5px line box around an 11px cap — while its own value sat on 1.32/18.5px. **Two lines of
    one pair on different leading.** `line-height: 1.3` takes the offset to **0,26px**; `margin-top: 2px`
    puts the ink gap at **10,0** against 071's 10,5. The row stays 64px, so nothing around it moves.
    The guard asserts the **mechanism** (the label carries its own line-height) as well as the result, so a
    future edit cannot reintroduce mixed leading and merely look right at one size. Negative-tested.

37. **CANDIDATE RULE — scoped to editors, not yet app-wide.** Asked from the device: *"do we need to follow
    the same pattern for any editable field across the app (like search)?"* Split in two, because the halves
    have different reach:

    - **The anatomy** — label prominent, value subordinate, the row opens a sheet — belongs wherever the
      *same situation* exists: **a stored value shown at rest and changed somewhere else**. Other editors
      (an estante's settings, a Web row's properties, Perfil) are candidates.
    - **The tint** needs a narrower meaning or it dilutes on contact. **It marks the datum you are about to
      change — never that a row is tappable.** Verified rather than assumed: 071's game rows are tappable
      and **plain ink** (`rgb(35,19,57)`, 435 of them, none tinted). A tint meaning "interactive" would be
      contradicted by the catalogue on day one.

    **Search is NOT this pattern, and should not adopt it.** A search field fails all three tests: no stored
    value at rest (it is empty), editing is **continuous typing** rather than a discrete pick, and the edit
    happens **in** the control rather than elsewhere. It *is* the control. The same holds for filters,
    switches, steppers, and **the fields inside a sheet** — once the sheet is open you are already editing,
    so nothing needs to advertise editability, which is why a picker's chosen option carries a **tick, not a
    tint**. Both platforms keep these as separate components too.

    **Deliberately NOT promoted to a D-19 rule yet.** It has been tested on exactly one page; 069 (Estantes)
    and 070 (Web) have value-ish rows nobody has checked it against. *A rule outrunning its evidence is this
    project's recurring failure — decisions 26 and 28 were both an assertion that had outlived its reason.*
    **Promote when:** it survives a check against 069 and 070, at which point it becomes a D-19 rule with
    three pages of evidence instead of one.

Harness: **49/49** at the time; **53/53** after sketch 073 round 4 sent two fixes back into it (below).

38. **The BGG state is the reason the page was opened, not a property of the BGG block.** Sketch 073 round 1.
    Grounded on the dev DB rather than the handoff, and it is sharper than the handoff said: the 49 broken
    games hold **zero** populated BGG columns — no cover, no year, no description, nothing; 15 of the 41 have
    a `weight_band` and that is the entire inventory. `form.ex:332-346` renders that through
    `value_or_dash/1` as a **wall of eleven em-dashes**, under *"Vienen de BoardGameGeek y se actualizan
    solos. No se editan acá."* — false twice for exactly these games.

    | `enrichment_status` | n | `bgg_id` | campos | `status` |
    |---|---|---|---|---|
    | enriched | 386 | sí | 11/11 | 385 pub + 1 draft |
    | no_bgg_id | **41** | **NULL** | **0** | published |
    | bgg_missing | **8** | **sí** | **0** | published |
    | pending / failed | **0** | — | — | — |

    **The two broken states are structurally different and `bgg_id` is the difference.** `no_bgg_id` has none
    (nothing to retry); `bgg_missing` has one that does not resolve (retrying fetches the same dead id).
    `Reintentar` is gated on `failed` in **both** `form.ex:220` and `catalog.ex:368` — and `failed` has
    **zero rows**, so the 49 that are actually broken are offered nothing at all.

    **What decided the round was not the question asked.** Three variants argued about where the remedy sits
    *inside* the BGG block; the harness was **64/65 green** across all three while every one of them was
    wrong the same way. The club spine is six 64px rows under a ~200px head, so the block *starts* at y=619
    on a device whose usable height ends at 673:

    | | 375×740 | 390×844 | 360×640 |
    |---|---|---|---|
    | A / B / C | −117 / −53 / −53 | −13 / ✓ / ✓ | −217 / −153 / −153 |
    | **D** | **✓** | **✓** | **✓** |

    Every guard asked what the block *contains*; none asked whether a reader reaches it. A's block measured
    *shortest* — it is short because most of it is off the phone. **The state moved above the club block**,
    and the `DATOS DE BGG` heading is dropped entirely when there is nothing under it.

    **Settled by the developer before building:** staff **paste the id** with a hint carrying a real BGG link
    and a worked `…/boardgame/155426/…` → `155426` example (a search-by-name flow needs an endpoint that does
    not exist; retry-only fixes nothing for the 41). And **"the app must avoid publishing uncompleted
    games"** — a rule `Catalog.publish_game/1` does not implement: `catalog.ex:490` runs `status_changeset`,
    which casts and validates **only `:status`**. That is how all 49 got live.

39. **The action bar, and a wait that lets you leave.** Round 2. Round 1 scattered actions across three
    places, with the publish gate at **772px on a 740px screen**. One bar now, pinned: **one primary slot
    that swaps** — `Guardar` while dirty, `Publicar` when clean — never two strong buttons, never resizing.

    **The collision that decided it, predicted before building:** while dirty the secondary slot is already
    `Descartar`, so a broken game with unsaved changes wants one slot to be both. Putting the remedy there
    **lost it entirely** — reachable only by discarding your edit first. *(Superseded by decision 42, which
    resolves it from the other side: the remedy is not a secondary at all.)*

    **`pending` gets a dedicated waiting screen, not a skeleton.** The justification is the job: enrichment
    is an Oban job on a queue with **concurrency 1** (`config.exs:41`) and `attempt * 30` backoff, so with 49
    games to repair the wait is real **and it continues whether or not the page is open**. The screen says
    so, carries no bar, makes nothing editable mid-fetch, and all five tab destinations are verified
    *hittable* via `elementFromPoint`, not merely present. Page height **1044 → 407px**.

40. **The lifecycle status is a dot + text in the head — a third D-19h violation, never flagged.**
    `form.ex:212-214, 253` renders `badge badge-warning` / `badge-success` / `badge-neutral` — daisyUI
    **pills**, in the editor header. D-19h is literal: *"a status is a dot + text, never a pill. Every status
    indicator in the admin."* Same family as the list-row pill (restart decision 22) and the `alert
    alert-error` (decision 24). Now **● Publicado · 2018 · BGG 224517**.

    **"Sin guardar" does not join it.** A lifecycle status is durable, server-side and shared; unsaved
    changes are transient, local, and already stated by the bar next to the buttons that act on them. One
    slot, one kind of thing.

    **What adding it found, which was not the question:** `Publicar` was being drawn for games that are
    **already published** — and the real 49 *are* live; that is their whole problem. Corrected: `Publicar`
    belongs to a draft and nothing else.

41. **One `Guardar` in the editor, and it is the bar's.** Round 3. From the device: *"should I have bottom
    sheet AND save for fields? isn't that contradictory with the save at the bottom?"* It is, and it was
    measurable — probed on the built page:

    ```
    sheet button said:       "Guardar"
    bar immediately after:   "Cambios sin guardar · Descartar · Guardar"
    ```

    You press `Guardar` and the app answers *"Cambios sin guardar"*. The sheet's button never saved
    anything. And the six sheets had **three commit anatomies** — a button (Nombre, Descripción), commit on
    tap (Nivel, Estante, Expansión), a live stepper (Copias) — *decision 33's row-level defect one level
    down*. The button is not a commit affordance: only the free-text sheets have one, **because only they
    raise a keyboard**. It is a dismiss button wearing the wrong word.

    **The button is deleted.** Text commits live like everything else; D-19e's four closes (✕, tap outside,
    drag down, Esc) never needed it. 0 of 6 sheets carry a commit, the Nombre sheet drops **215.6 → 159.6px**.
    Rejected: renaming it "Listo" — that keeps a **full-width filled primary**, the heaviest control in the
    system, spent on closing a sheet at **7.8×** the area of the ✕ already two inches above it.
    **Its honest cost:** no per-field abandon — a typo is undone by `Descartar`, which discards *every*
    change. "Listo" did not fix that either, so the difference is candour, not capability.

42. **The bar holds the one thing to do now — and the remedy is not a secondary.** Round 4, one question, at
    the developer's request to go in smaller slices. From the device: *"isn't better a centralized way to
    have CTA? Having retry at top looks weird. Also, where is the publish button?"*

    Mapped rather than argued — the bar across all eight situations:

    ```
    published | no_bgg_id | sin cambios | -- SIN BARRA -- | Vincular (arriba)
    ```

    **That row is the 49 real games**, and it is the whole thing in one line: the bar is *completely empty*
    at exactly the moment there is one obvious thing to do, and that thing was stranded at the top of the
    page. Decision 39's collision assumed the remedy had to be a **secondary**; a broken clean game has **no
    primary at all**, so it competes with nothing. It *is* the thing to do.

    > broken+clean → the remedy · dirty → `Guardar` (+`Descartar`) · draft+complete → `Publicar` ·
    > published+clean+fine → nothing.

    The remedy leaves the top; the state line stays as pure diagnosis. Rejected: a bar that never empties but
    offers **`Retirar`** when idle (a destructive action, alone, on a healthy game, in the strip that
    otherwise holds the safe one), and a fixed `Guardar` always in the same place (**4 of 8** situations put
    a *dead* control in the strongest slot and demote the real next step to a ghost — it inverts the
    hierarchy exactly when there is something to do).

    **Two defects found by measuring, both sent back into 072:**
    - **The primary moved between three horizontal positions** — right edge at R296 / R359 / R112. The empty
      "cambios sin guardar" span collapses to `display:none`, so a lone button started at the left. In a
      design premised on the bar being *the one place you look*, the thing to tap was moving. Pinned to one
      edge; the verb and width still change, the edge does not.
    - **The pinned bar covered the last row by 53px** at full scroll. `main` reserves **79px**, which clears
      the 67px *tab bar* and nothing else; an absolute bar overlays rather than pushes, and at rest floats
      over blank space — which is why every earlier check was green over it. Reserve applied only while the
      bar is present.
    - **Also fixed in 072: a sheet's change never reached the row behind it.** Step `Copias`, close the
      sheet, and the row still read "Copias 1" beside a *"Cambios sin guardar"* bar. All three close paths
      (✕, backdrop, Esc). 072's own 49/49 suite was blind to it; guard added and **negative-tested** —
      reverting the fix gives 49/52, exactly the count it had while blind.

    **Deferred, deliberately not varied:** what happens to the remedy **while dirty** (all variants hide it —
    mid-edit the thing to do is finish the edit). Its own round.

43. **The editor's chrome is one top app bar, and the title arrives on scroll.** Sketch 074, rounds 1-2,
    from the developer's own proposal: *"we have been using a useless header that is replaced at scrolling."*
    Measured, the complaint was understated — the editor spent **97px before the game's name** on a 53px
    wordmark header plus a 44px in-page back row, and the back affordance existed **twice** (`.back` and
    `.pbar`'s chevron, the same destination reached two ways; at no single scroll offset are both hittable,
    which is exactly why it shipped unnoticed). One 56px bar replaces both: **41px back, one back control,
    no hamburger** — you reached this screen by drilling down, so the chevron is the way out.

    **The title is absent at rest and fades in on scroll.** From the device: *"not sure that I need to say
    where you go back or where you are since you can see it."* True at rest — round 1 put the game's name on
    screen **three times** inside 600px (bar, 22px head, `Nombre` row). Not true scrolled: on 514px of real
    scroll a bar with no title says nothing about which game is being edited, which is **D-19n**. So it is
    `opacity: 0` at rest and arrives as the head clears the bar — `.pbar`'s trigger applied to a bar that is
    **already there**. Nothing appears, nothing moves, one element changes opacity. Name occurrences: **3 -> 2
    at rest, 1 in the bar at full scroll.** `flex: 1` is kept while invisible, or the CTA would slide left at
    rest and jump right on scroll — d42's "the thing to tap is moving", reintroduced through the fade.

    **D-19n is amended, not dropped: this settles the EDITOR only.** `.pbar` stays alive for the catalogue
    list, which is a different screen and is not decided here.

44. **The action area moves to the top bar entirely, and the slot swaps.** Round 1 measured three answers to
    "where does the primary live". The split (`Guardar` up, the rest below) lit **two containers in 3 of 8**
    situations — and, found in a screenshot rather than by a number, pushed **`Descartar` to R359, the exact
    right edge `Guardar` holds in the other five**. The editor would spend five situations teaching "the
    bottom-right button is the safe one" and then put the undo-everything button there: the hazard d42
    rejected G2's `Retirar` for. The bottom bar is deleted from the editor.

    **The developer's enabled/disabled CTA, reconciled with d42 rather than against it.** From the device:
    *"isn't better to have enable the CTA? If I open the form and don't change nothing, the button is
    disable."* Taken literally that re-opens what d42 rejected — a fixed `Guardar` put a dead control in the
    strongest slot in **4 of 8** and demoted the real next step to a ghost, and with no bottom bar `Vincular`
    would have nowhere to go on the 49 real games. So the slot **swaps** (`Guardar` / `Vincular` /
    `Corregir ID` / `Publicar`) and falls back to a disabled `Guardar` only where `primary()` has nothing to
    offer: **1 of 8, and in that one nothing is pending**, so it never inverts the hierarchy. Guarded so it
    cannot drift back to 4.

    **The CTA is 36px, not 44.** *"Currently that CTA looks huge"* — 44px in a 56px bar is **79%** of its
    height. Round 1 held it byte-identical to the bottom bar's button so a finding about POSITION could not
    be blamed on WEIGHT; that paid off, because the same control reads as proportionate in a dedicated action
    strip and oversized in a top bar. 36px is 64%, with the 44px floor kept by a pseudo-element (the switch
    track's technique), hit-tested above and below the visible box. **Weight — filled vs tonal vs text — is
    still open**, and the sharpest input to it is that a *disabled filled* button reads as lavender-and-live
    rather than clearly dead.

45. **`Descartar` is deleted, and D-19f is drawn for the first time.** Not relocated — deleted. With the bar
    gone it has no home, and the developer's second rider supplies the replacement: *"On going back, this
    could ask confirmation about you're going to lose unsaved data."* That dialog **is** `Descartar`. It
    stops being a permanent control on every screen and becomes the destructive option on the way out.
    D-19f qualifies it — the rule covers actions that lose state staff would have to rebuild (D-19k's own
    test), and unsaved edits are exactly that. A clean editor leaves silently, or it is noise on 385 healthy
    games.

    **Anatomy is the rule's, asserted against its numbers:** 312px, 16px radius, 18/600 question, one 14px
    consequence line, two right-aligned TEXT actions — `Cancelar` focused by default, the verb in Peligro
    red — scrim tap and Esc cancel.

    **What building it found:** the first version invented *"Seguir editando"* for the cancel, reasoning that
    "Cancelar" is ambiguous here (cancel the edit, or cancel the leaving?). At 312px minus 40px of padding
    there are 272px for both actions, and **both wrapped to two lines** — two text actions became a two-line
    block and the focused one read as an outlined button. The rule's own word fits on one line, and the
    ambiguity is already answered by the question directly above it. Departing from a settled rule on a
    judgment call cost a layout defect; `nowrap` plus a one-line assertion now make any future departure fail
    loudly instead of wrapping quietly.

    **Its honest cost:** there is no longer any way to abandon an edit *without leaving the page*.
    `Descartar` used to let you stay. Same shape as decision 41's candour about the missing per-field abandon.

## Where we are (2026-09-19)

- **Sketches:** `071-admin-juegos` **135/135** · `072-admin-game-editor` **53/53** ·
  `073-admin-bgg-state` **132/132**. Serve with `python3 -m http.server 8765` from the repo root.
- **Settled:** decisions 1–9, 16–36, **38–42**. **37 is still a CANDIDATE**, scoped to editors until checked
  against 069 and 070. **Superseded by 17:** 10, 11, 13, 14, 15. **Reverted:** 12. **Superseded by 42:**
  39's "the remedy cannot go in the bar".
- **073 round 4 is PENDING REVIEW** — G1 (the bar disappears when nothing is pending) is the standing
  recommendation on the measurements, not yet confirmed from the device. G2 and G3 are still in the page.
- **Two fixes landed back in 072** from 073's findings, both guarded and negative-tested: the sheet-close
  stale row (all three close paths) and the save bar covering the last row at full scroll.

### The editor as it stands after 073

```
‹ Juegos
[tapa] Nombre del juego
       ● Publicado · 2018 · BGG 224517        <- d40, dot+text, never a pill
● Este juego no está vinculado a BGG.          <- d38, the diagnosis, above the spine
  Por eso no tiene tapa… Se está viendo así en la web.
DATOS DEL CLUB                                 <- d33's spine, 6 rows, one anatomy, no glyph
  Nombre / Nivel / Copias / Estante / Expansión / Descripción
DATOS DE BGG                                   <- dropped entirely when empty (d38)
[ barra: la acción del momento, borde derecho fijo ]   <- d42
```

### Open, in slice order

1. **NEXT, and the developer's own proposal (fresh session):** *the header.* See the handoff below.
2. **The remedy while dirty** — deferred out of decision 42 on purpose.
3. **`Retirar` / `Restaurar`** — untouched since 063; must become D-19f's centred dialog.
4. **`Estante`** — 072 shows a picker, but D-01/D-00c place a *copy*, in the "¿Dónde va?" sheet. Likely
   resolves to read-only plus a link out.
5. **`Copias`** — `units = 1` for all 434 games. How much UI does a field whose value is constant earn?
6. **`En la web`** — 063's manual-section switches are not drawn anywhere.

### Owed to the codebase, not to a sketch

- **The 49 already published broken.** A data decision, not a UI one: unpublish them, or leave them live
  while they are repaired one at a time. Nothing in the sketches addresses it.
- **`publish_game/1` must implement the publish rule.** `catalog.ex:490` validates only `:status`.
- **`Reintentar`'s gate should move** from `enrichment_status == "failed"` to *"has a `bgg_id`"*, in both
  `form.ex:220` and `catalog.ex:368`.
- **`enrichment_status` is unvalidated on every live write path** — `validate_inclusion` exists only in
  `seed_changeset/2`; `enrichment_changeset/2` casts it with none, and there is no DB CHECK.
- **No failure reason is ever persisted** — `failed` collapses three causes into one string, logged only
  (`enrich_game_worker.ex:94`), so the UI can never say which happened.
- **`TODO(palette)` from decision 35 still blocks 01.8.2** — see below, unchanged.

---

## HANDOFF — sketch 074, the header (opened 2026-09-19, for a fresh session)

**The developer's words:** *"Until now, we have been using a useless header that is replaced at scrolling. So
I want to explore what if we use with 'current action' (like editar juego, o crear juego, etc), the chevron
for go back and save at the right. (making the save enable or disabled based on the status. It is save if
there is changes to save)."*

**What exists today, and why the complaint is fair.** The admin currently spends vertical space on *three*
overlapping things at the top of an editor:

| | what it is | where |
|---|---|---|
| `.hdr` | a 53px `PUKLLAY CLUB` wordmark + hamburger, identical on every screen | 071/072/073 chrome |
| `.pbar` | D-19n's scroll-triggered page bar — an absolute overlay that fades in once the head scrolls past, carrying ‹ back + the game name | 071 onward |
| `.back` | an in-page `‹ Juegos` row above the game's head | 072/073 |

So the back affordance exists **twice** and the wordmark carries no information on a screen the user reached
by drilling down. The proposal collapses all three into one M3-style top app bar: **‹ back · "Editar juego" ·
Guardar**.

**What this round has to decide, and what it must not quietly break:**

- **D-19n** (*"a long list keeps its context while scrolled"*) is what `.pbar` implements. A permanent app
  bar may make D-19n redundant *on an editor* while still being needed on the **catalogue list** — the two
  screens must be checked separately, and D-19n amended rather than silently dropped.
- **Decision 42 put the primary in the BOTTOM bar**, with a fixed right edge, because it holds *the one thing
  to do now* — which on a broken game is `Vincular`, not `Guardar`. Moving `Guardar` to the top splits the
  action area in two again, which is exactly what round 2 was convened to fix. **This is the central
  tension of the round** and it needs measuring, not asserting: is the top-right `Guardar` the *only*
  primary, with the situational action staying below? Or does the bottom bar disappear entirely, and
  `Vincular` move to the top too?
- **D-19a** (the save bar pins while dirty) is already amended by 42; a top-bar `Guardar` amends it further.
- **Reachability.** A top-right `Guardar` on a 375-wide phone is a one-handed thumb stretch to the far
  corner; the bottom bar is not. Worth measuring rather than assuming, since the admin is mobile-first.
- **The title is a real question of its own:** *"Editar juego"* (the action) vs the game's name (the object).
  The bar cannot hold both at 375px without truncation — 072's `.pbar` already chose the name. Whichever
  wins, `crear` and `editar` must both work, and the D-19h lifecycle dot (d40) needs somewhere to live.

**Start from:** `.planning/sketches/073-admin-bgg-state/index.html` (chrome, spine, sheets, bar, harness
idioms all current). Read `073/README.md` first — it carries all four rounds — then this file's decisions
33–42.

**House rules that keep catching real defects, and cost little:**
- Keep a `HOY` variant rendering what ships, so every guard can be **negative-tested**; twice this sketch it
  caught a baseline that had quietly stopped being the baseline.
- **Screenshot every variant and look at it.** Across 073's four rounds the harness was fully green while the
  page was wrong **five** times — the state below the fold, the keyboard burying a sheet, a row 32px short, a
  stale value behind a closed sheet, a bar covering the last row. That is the rate, not bad luck.
- **Measure at the scroll extremes and with the keyboard up**, not only at rest.

## Where we are (2026-09-18, superseded — kept for the 01.8.2 blocker below)
- **Sketch:** `.planning/sketches/071-admin-juegos/index.html`, harness `verify.js` — **135/135**.
  Tools: **Tema · Teclado** only — every variant toggle is removed once its question is answered.
- **Settled:** decisions 1–9 and **16–36**; **37 is a CANDIDATE rule**, scoped to editors until checked against 069 and 070. **Superseded by 17:** 10, 11, 13, 14, 15 (all were consequences of
  having two kinds of section header). **Reverted:** 12 (`193d10c` → `b1d6c49`).
- **The page today (375×740):** a 48px search with a `+` beside it · then ONE LIST of three sections, labelled
  in **versalita 14/600** — `SIN DATOS 49 ⌄` and `BORRADORES 1 ⌄` closed, `JUEGOS DEL CLUB 385` open. No resting
  page title. Chrome **209px**.
  Two text left edges: **16** and **68**. Air **27px above** a section label, **9 below**.
- **App-wide rules recorded** in `01.8.2-CONTEXT.md` + `01.8.2-BENCHMARK.md`: **D-19n** scrolled context,
  **D-19g-bis** catalog sections.
- **Still open** (handoff's list, minus the one decision 22 closed):
  1. **the section-header audit's other three findings** (decision 26): the counts form no column (x=95/109/142);
     235px of invisible tap target to the right of a caption's ink; the count is 15/400, a row *name*'s rank
  2. **the editor still owes Reintentar** — decision 24 moved it there from the row (sketch 072)
  3. no prompt line
  4. collapse state does not persist
  5. copy not reviewed
  *(the hint/label pairing is closed by decision 23 — verified, not reproduced; the `:active`/touch state is
  closed by decision 32)*
- **BLOCKING BEFORE 01.8.2 SHIPS — `TODO(palette)`, from decision 35.** The editor's editable-value colour
  needs a **dark token the palette does not have**. `sketches/themes/default.css` is a **mirror** of
  `assets/css/app.css` gated hex-for-hex by `check-theme-drift.sh`, so sketch 072 defines `--val` **locally**
  and the real fix is upstream. The token must clear **three** bars at once: **≥4.5:1** on the dark ground
  (it is body text), **perceptibly distinct** from body text (ΔE, *not* a contrast ratio — see decision 35),
  and **clear of `--color-text-muted`** or it collides with the empty state. `#9F7AEA` (4.83 / ΔE 65.5 /
  1.43) is the measured candidate and **the reconciliation should try to beat 4.83:1**, since it would
  otherwise be the lowest-contrast text on the dark page (everything else is 6.9+).
  Steps: add the stop in `app.css` against its `--pk-ramp-*` envelope → mirror into `default.css` → re-run
  `check-theme-drift.sh` → drop the local `--val` override from sketch 072.
  *While reconciling, audit the rest of the dark palette for the same class of gap: `--color-accent-text`
  resolving to `#E3D9F9` (1.17:1 from body text) is why a tint-based affordance had no dark answer at all.*
- **Next:** sketch 072 rounds 2+ (the BGG state), sketch 074, `--wrap-up`, then `/gsd-plan-phase 01.8.2`.
