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

## Where we are (2026-09-18)
- **Sketch:** `.planning/sketches/071-admin-juegos/index.html`, harness `verify.js` — **91/91**.
  Tools: **Tema · Teclado** only — every variant toggle is removed once its question is answered.
- **Settled:** decisions 1–9 and **16–22**. **Superseded by 17:** 10, 11, 13, 14, 15 (all were consequences of
  having two kinds of section header). **Reverted:** 12 (`193d10c` → `b1d6c49`).
- **The page today (375×740):** a 48px search with a `+` beside it · then ONE LIST of three sections —
  `Sin datos 49 ›` and `Borradores 1 ›` closed, `Juegos del club 385` open. No resting page title. Chrome 213px.
  Two text left edges: **16** and **68**. Air **27px above** a section label, **9 below**.
- **App-wide rules recorded** in `01.8.2-CONTEXT.md` + `01.8.2-BENCHMARK.md`: **D-19n** scrolled context,
  **D-19g-bis** catalog sections.
- **Still open** (handoff's list, minus the one decision 22 closed):
  1. the enrichment `pending`/`failed` row + Reintentar — not drawn anywhere (slated for sketch 072)
  2. the hint is `13/400` muted directly under a `15/600` label at the same keyline — may read as one block
  3. the catalog row's second line is the year alone, repeating down a newest-first list
  4. no prompt line
  5. collapse state does not persist
  6. copy not reviewed
- **Next:** finish Juegos → sketch 072 (the editor), sketch 074, `--wrap-up`, then `/gsd-plan-phase 01.8.2`.
