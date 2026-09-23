# Handoff — close Juegos, then sketch 072 (the editor)

**Rewritten:** 2026-09-18, after decisions 22–31. *(Supersedes the handoff written after decision 21 — that one
describes a page with a resting `Juegos` title, a `›` caret, 265px of chrome and an 80/80 harness. None of that
is true any more.)*
**Pattern:** the one that produced 069, 070 and 071 — `/gsd-sketch --quick`, one question at a time, measure
before building, look at the screenshots, record every decision.

## How to run it
```
/gsd-sketch --quick Close Juegos then sketch 072, the game editor — read .planning/notes/juegos-refine-handoff.md first
```

## Where things stand

`.planning/sketches/071-admin-juegos/index.html` — standalone, hand-written, uses
`../069-estantes-ubicar/games.js` (434 real games, real R2 covers) and `../themes/default.css`. Serve with
`python3 -m http.server 8765` from the repo root.
Harness: `node .planning/sketches/071-admin-juegos/verify.js` — **127/127**, `SHOTS_DIR=` to place screenshots.
Tools: **Tema · Teclado · Estado BGG**. The first two are simulation switches; **Estado BGG (`—` / `pendiente` /
`error`) is a SCENARIO switch, not a variant** — the dev DB has zero pending and zero failed rows, so it is the
only way to see those states at all. Every variant toggle has been removed as its question was answered.
Working tree clean apart from an unrelated `ideas.txt`. Next free sketch number: **072**.

**The page today (375×740), chrome 209px:**

```
[ Buscá un juego              🔍 ]  +     ← 48px field, sticky; no resting page title
SIN DATOS        49  ⌄                    ← versalita 14/600, closed
BORRADORES        1  ⌄                    ← closed
JUEGOS DEL CLUB 385                       ← no caret; never collapses
  [cover] On Mars / 2020            ›
  …50 rows, Mostrar más
```

Nothing is tinted at rest. A caption gains a band on **hover** (30.2px) and while **pinned** (44px, uniform in
every section). Two text left edges: **16** and **68**. Air **27px above** a label, **9 below**.

## Settled

**Decisions 1–9 and 16–31.** Full text and every measurement in `.planning/notes/juegos-ui-redesign.md`.
**Superseded by 17:** 10, 11, 13, 14, 15. **Reverted:** 12 (`193d10c` → `b1d6c49`).

What governs the page, in one line each:

1. **The one job is finding one game.** No `estado` chips — the dev DB is 434 published / 1 draft / 0 retired.
2. Picking a game **opens its editor**; the search is pure navigation, so a game row keeps a chevron (D-19i).
3. All games under the search, newest first, `Mostrar más · 50 de N`.
4. Adding lives in the `+` **and** in the search — pasted BGG id/link offers *Agregar desde BGG*, no match offers
   *Crear «texto»*. 41 games have no BGG id, so the by-name path is real.
6–7. **D-19n** — a long list keeps its context; on Juegos the pinned tier is **the search**.
8. **One list of sections** partitioning the catalog (49 + 1 + 385 = 435). No Pendientes page, no badge.
9. The search hides on scroll-down, returns on scroll-up.
16–17. **ONE LIST, one anatomy.** Every section header is the same caption — span or button, identical ink.
18. The two exception sections **close at rest**; the caret is affordance, not a second kind, placed inline after
    the count with the hit box stretched to 44px by a pseudo-element.
19. A section's hint returns, **inside an opened section only**.
20–21. The label carries D-19j's rank at full strength, with **air above and none below** (3.0:1).
22. **A search-first tab root has no resting title.** Chrome 265 → 209. Scope checked: Estantes' search is
    `position: relative` and Web has none, so Juegos is the only search-first tab root; they keep their `ptitle`.
23. The hint/label pairing was checked and **does not reproduce** — closed, not fixed.
24. **Enrichment is a dot + text on the row's second line**, and a **closed section reports its failures** in the
    caption (`BORRADORES 1 ● 1 con error ⌄`). Reintentar moved **to the editor**.
25. The second line keeps the **year**. 0 duplicate names, so año's stated reason has zero instances; 433 of 435
    share one insertion date, so recency is worse; and removing it gains **0 rows** (the 40px cover sets 64px).
26. The caret is **chevron-down**, not the row chevron's glyph.
27 + 29 + 30 + 31. The header's **band** — see "Traps" below; these four are all the same class of mistake.
28. **A section label is versalita, 14/600 uppercase, tracked.**

## What is open

**On this page** — start here, it is one short round:

1. **`:active` / the touch state has never been verified.** It is the only state nobody has measured, and three
   of the five findings the developer reported in the last session came from exactly that: an unmeasured state
   or an unmeasured axis. Check `.lhead.tap:active`, `.row:active`, and what a real tap looks like on the
   caption's 44px pseudo-element hit box. Cheap insurance before leaving the page.

Then, in rough priority — all taste or small, none blocking:

2. Three findings from the decision-26 header audit, **built and measured but never taken**: the counts land at
   three different x so they form no column; the full 375px of a collapsible caption is tappable while its ink
   stops far short (a large invisible target, and the same empty strip does nothing on the non-collapsing
   section); and the count's rank is now 14/400 after decision 28.
3. No prompt line ("¿Qué juego buscás?"). Estantes has one because its page is otherwise empty.
4. Collapse state does not persist — every visit opens with the two exception sections closed.
5. Copy not reviewed: the add sheet's hint, "Crear a mano · Para un juego que BGG no tiene", the section hints.

## Then: sketch 072 — the game editor

**This is where the real risk is.** Every path on Juegos ends in the editor, and it is still sketch 063's design,
which predates everything settled since. Five things it owes, four of them verified contradictions:

1. **"Unidades" vs Copias** (scope note #18).
2. An **in-sheet Retirar confirm** vs **D-19f**'s centred dialog.
3. A **shelf picker with no per-copy position** vs **D-01 / D-00c**.
4. **"A pencil on every value"** vs **Web decision 17**, which removed the pencil.
5. **Reintentar**, which decision 24 moved out of the list row and into the editor — with the shipped
   `alert alert-error` box replaced by D-19h's dot + text. Shipped today at
   `lib/pukllay_club_web/live/admin/game_live/form.ex:262-267`.

Real enrichment facts, audited against `lib/` (do not re-derive):
- Column `enrichment_status`, plain string, `game.ex:48`; declared values `pending | enriched | no_bgg_id |
  bgg_missing | failed` (`game.ex:19`). **Live code writes only `pending`, `enriched`, `failed`**; the other two
  are seed-era values still sitting in the dev DB (41 and 8 rows).
- `enrichment_changeset/2` does **not** `validate_inclusion`, and there is no DB check constraint — the column
  is unvalidated on every live write path.
- Oban `max_attempts: 3`, linear backoff `attempt * 30`.
- **`enrichment_status` is filtered by no query anywhere.** A `failed` game is public the moment `status` is
  `:published`; nothing gates publishing on BGG answering. This is why the 49 "Sin datos" games are live and
  broken on the public site. Not a UI defect — but the editor is where it becomes visible.
- Retry exists end to end: `Catalog.retry_enrichment/1` (`catalog.ex:368-381`), which only matches
  `enrichment_status: "failed"` and returns `{:error, :not_failed}` otherwise.

## After 072

1. **Sketch 074** — staff tab bar on public pages (D-14); the last item in CONTEXT's pre-planning sequence.
2. `/gsd-sketch --wrap-up` to refresh the stale `sketch-findings-pukllay_club` skill (D-17).
3. `/gsd-plan-phase 01.8.2`.

## The rules to carry (CONTEXT `01.8.2-CONTEXT.md`, D-19a–n + D-19g-bis)

- **One main job per page** (D-19j); a one-job page may list its siblings below it (D-19l).
- **D-19g-bis:** work *queues* go behind a badge (Estantes' Afuera / Sin ubicar); a **catalog** is **one
  continuous list whose sections hold different content**. Every section header is the same caption — now
  **versalita 14/600** on the **16 keyline**, full-bleed, sticky, gaining a band only on hover or while pinned,
  sections butting together. **Only exception sections collapse**, marked by an **inline chevron-down after the
  count** — never leading, never in the row-chevron slot (D-19i). The body section never collapses. A label gets
  **air above and none below**, at least 2:1, and is never identical to a row's second line.
- **D-19n** — a long list keeps its context: a 44px page bar (absolute overlay, `inert` keeps exactly one
  focusable back control) + a sticky section heading; on a search-first page the search pins and hides on
  scroll-down, and **there is no resting page title** (decision 22).
- **Sheets** (D-19e): 44px ✕, no Cancelar row. **Destructive = centred dialog** (D-19f), but removing from a
  curated list is not destructive (D-19k). **Status = dot + text** (D-19h) — never a pill, never an alert box
  (decision 24). **Kind = quiet lowercase tag; count = neutral pill bottom-right** (D-19m).
- Type ranks (D-19j): title 22/600 › prompt 17/600 › 48px field › **section versalita 14/600** › row names 14–15
  › chips 12–13. The BENCHMARK's `Label (group) 13/600` is a **form** section label (sketch 065) and does **not**
  govern a list section header — conflating the two caused decision 20.
- Spanish is **Argentine voseo**; mobile first; no age facet.

## Working agreement (it is what made 069, 070 and 071 work)

- **One question at a time**, 2–4 options with a recommendation. **Build the variants** — this developer
  evaluates in the browser, not from prose, and asks for variants explicitly when given ASCII. Build them as
  tools toggles and remove the losers once one is picked.
- **Measure before building and after every change**, and **look at the screenshots**.
- **Record every decision** (the developer's words + the measurements) in `.planning/notes/juegos-ui-redesign.md`,
  continuing the numbering; app-wide rules also go to `01.8.2-CONTEXT.md` and `01.8.2-BENCHMARK.md`.
- Sketches show only the UI being designed.

## Process rules this page earned the hard way

- **When consecutive rounds keep re-touching one seam, the seam is not the problem — the structure that creates
  it is.** Decisions 13→14→15→16 were four passes at the same 20px. Decision 17 deleted all of them by changing
  the premise.
- **When a decision is superseded, re-check what was justified by the thing it removed — and what it
  *prohibited*.** Decision 26 found decision 18 had kept decision 10's position fix while dropping the explicit
  glyph prohibition that came with it. A supersession note should list what becomes **re-openable**.
- **An assertion can outlive its reason too.** Four guards fired on decision 28, all correct when written and
  wrong by then — decision 20 had encoded a rank rule in `font-size`, which is the wrong measurement for
  versalita, and decision 24 had hardcoded a chrome constant into a claim that is inherently relative.
- **A fix must be as general as the rule it cites.** Decision 27 named the two-geometries rule and then applied
  it to the single reported state; `:hover` carried the identical defect into decision 29.
- **When a guard fires on a legitimate exception, make the assertion more precise — never weaker.**
- **A state the user can reach twice in a row is a state they will compare.** Decision 31's uneven pinned bars
  were predicted while building 27 and dismissed as "only one pins at a time".

## Measuring toolkit + the traps this page has actually hit

- Serve `python3 -m http.server 8765`; `playwright-core` from the npx cache (loader in `verify.js`),
  `channel: 'chrome'`, viewports 360×640 / 375×667 / 375×740 / 390×844, `deviceScaleFactor: 2`.
- Hide `#tools` before real clicks. After scripted edits, extract the inline `<script>` and `node --check` it.
- **A scripted `replace()` that must match should assert**, not be eyeballed. Every edit asserts and fails loudly.
  Two overlapping edit scripts in one session were caught this way before either landed.
- **Measure ink, not boxes — and a Range's rect is still a box.** Three escalating forms, all hit here:
  1. A transparent element's box edge is invisible, so box gaps reported three spacing variants as identical.
  2. An element that draws **nothing at rest but something in another state has TWO geometries**; padding tuned
     for the invisible one becomes visible colour in the other (decisions 27 and 29).
  3. For **versalita the line box is not the ink**: at 14/600 the line box is 17px inside an 18.2px content box
     while the capitals are 11px with no descender, so centring the range rect leaves the ink visibly high
     (decision 30). Probe cap height with an **"H"**, never the real text — the J of "JUEGOS" descends and made
     the two states disagree by 2px.
- **Check every axis, not just the reported one.** A band was asserted against its own resting height (27) and
  across states (29) before anyone compared it **across sections** (31).
- **Park the cursor off-canvas before sampling colour** — `cool()` in `verify.js`. A click leaves the mouse on
  its target and hover swaps the fill.
- **Count tinted masses from raw pixel runs down a text-free column**, never from a computed style per element.
- **A screenshot lied twice**: two byte-identical bands looked like different tints (simultaneous contrast).
- **Lazy covers**: R2 thumbnails are `loading="lazy"`; force eager and wait for decode before shots.
- **Re-query after any render** — a check once clicked a group open then clicked a *stale* node to close it.
- **Sticky pins to the scroller's top edge (y=53), not the viewport's.** A "pinned" test must also require the
  section to still extend past the bar, or headers scrolled out of view count as pinned.
- The simulated keyboard is 292px; dropdowns and sheets must end above it.
- Dev DB is real and worth querying:
  `PGPASSWORD=postgres psql -h localhost -U postgres -d pukllay_club_dev`.
  Juegos: 434 published · 1 draft · 0 retired · **49 with no cover, no description and no year** (published,
  live) · 27 with no `weight_band` · 41 `no_bgg_id` · 8 `bgg_missing` · **0 duplicate names** · **433 of 435
  inserted on 2026-08-10** (the CSV import — so decision 3's "newest first" is a real sort for 2 games; correct
  going forward, degenerate on the backlog). The fixture's 49 thumb-less games *are* those 49, but it fakes a
  distinct `added` per game, so the sketch's order is more meaningful than the real query's.

## Prompt to paste in the fresh session
```
/gsd-sketch --quick Close Juegos then sketch 072, the game editor — read .planning/notes/juegos-refine-handoff.md first
```
