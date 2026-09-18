# Handoff — refine the admin "Juegos" tab (fresh session)

**Rewritten:** 2026-09-18, after decisions 13–21. *(Supersedes the earlier handoff written after decision 11 —
that one describes a page with tinted bands and collapsible groups that no longer exists.)*
**Pattern:** the same one that produced 069, 070 and 071 — `/gsd-sketch --quick`, one question at a time, measure
before building, look at the screenshots, record every decision.

## How to run it
```
/gsd-sketch --quick Refine the admin Juegos tab — read .planning/notes/juegos-refine-handoff.md first
```

## Where things stand
`.planning/sketches/071-admin-juegos/index.html` — standalone, hand-written, uses `../069-estantes-ubicar/games.js`
(434 real games, real R2 covers) and `../themes/default.css`. Serve with `python3 -m http.server 8765` from the repo
root. Tools: **Tema · Teclado** only — every variant toggle has been removed, and nothing else collapses.
Harness: `node .planning/sketches/071-admin-juegos/verify.js` — **80/80**, `SHOTS_DIR=` to place screenshots.
Working tree is clean apart from an unrelated `ideas.txt`. Next free sketch number: **072**.

**The page today (375×740):** title `Juegos` 22/600 + a `+` icon · a 48px search · then **ONE LIST** of three
sections, all with identical ink:

```
Sin datos       49  ›     (closed, 15/600 @16, caret inline after the count)
Borradores       1  ›     (closed)
Juegos del club 385       (no caret — never collapses)
  [cover] On Mars / 2020  ›
  …50 rows, Mostrar más
```

Nothing is tinted at rest; a section header gains `--color-surface` only while **pinned**. Sections butt together;
air is **26px above** a label and **0 below** it. Two text left edges: **16** (title, field, labels, covers, hints)
and **68** (row text).

## Settled — and what was superseded
- **Settled:** decisions **1–9** and **16–21** (full text and every measurement in `.planning/notes/juegos-ui-redesign.md`).
- **Superseded by 17:** decisions **10, 11, 13, 14, 15** — every one existed only because the page had *two kinds*
  of section header. It has one. (15 survives only as "the body section never collapses".)
- **Reverted:** decision 12 (`193d10c` → `b1d6c49`).

The decisions that still govern the page:

1. **The one job is finding one game.** 061's four `estado` chips are gone — the dev DB is 434 published / 1 draft
   / 0 retired, so they would filter 435 into 435.
2. Picking a game **opens its editor**; the search is pure navigation, so a game row keeps a chevron (D-19i).
3. **All games under the search, newest first**, `Mostrar más · 50 de N`.
4. **Adding lives in the `+` header icon AND in the search** — a pasted BGG id/link offers *Agregar desde BGG*, no
   match offers *Crear «texto»*. 41 games have no BGG id, so the by-name path is real.
6–7. **D-19n** — a long list keeps its context in two pinned tiers; on Juegos the pinned tier is **the search**.
8. **One list of sections** partitioning the catalog (49 + 1 + 385 = 435). No Pendientes page, no badge.
9. The search **hides on scroll-down, returns on scroll-up** (measured: collapsing it to an icon gained 0 rows at
   375×667 *and* cost a tap).
16. A section label sits on the **16 container keyline**.
17. **ONE LIST, one anatomy.** Every section header is the same caption — a span or a button, but identical ink:
    fill, rank, colour and keyline. This is the iPhone-Contacts / iOS plain-table model.
18. **The two exception sections close at rest** (the catalog was 3,270px down; it is now 206). The **caret is
    affordance, not a second kind** — only collapsible sections carry one, placed **inline after the count**, with
    the hit box stretched to 44px by a pseudo-element so the caption's rhythm survives the touch floor.
19. **A section's hint returns, inside an opened section only** — zero cost at rest.
20. **The section label carries D-19j's rank, 15/600 at full strength.**
21. **Air above a label, none below** — 27px against 9px, a 3.0:1 ratio.

## What is open
Nothing is broken that has been measured. In rough priority:

1. **The enrichment `pending` / `failed` row + Reintentar — not drawn anywhere.** Real shipped behaviour with no
   design at all, and the handoff plan has sketch 072 (the editor) absorbing it. **This is the biggest gap.**
2. **Chrome is 43% of usable height** (265px of 620 before the first game) — title + search + two closed sections.
   Surfaced by the decision-20 audit, *not* yet addressed. It is a structural trade (exceptions-first costs that),
   not a defect, so it needs a decision rather than a fix.
3. **The hint is `13/400` muted directly under a `13/600`… now `15/600` label** at the same keyline. Flagged in
   decision 19 and taken as built; a caption and its hint may read as one two-line block. One-line fix if so.
4. The catalog row's second line is the **year alone** ("2020"), repeating down a newest-first list. Recency may
   earn the line better — against 065 round 3's reason for keeping año (it tells two editions apart).
5. **No prompt line** ("¿Qué juego buscás?", 17/600). Estantes has one because its page is otherwise empty.
6. **Collapse state does not persist** — every visit opens with the two exception sections closed.
7. Copy not reviewed: the add sheet's hint, "Crear a mano · Para un juego que BGG no tiene", the section hints.

## The rules to carry (CONTEXT `01.8.2-CONTEXT.md`, D-19a–n + D-19g-bis)
- **One main job per page** (D-19j); a one-job page may list its siblings below it (D-19l).
- **D-19g-bis, as it now stands:** work *queues* go behind a badge (Estantes' Afuera / Sin ubicar — unchanged); a
  **catalog** is **one continuous list whose sections hold different content**. Every section header is the same
  caption: 15/600 at full strength on the **16 keyline**, full-bleed, sticky, gaining a fill **only while pinned**,
  sections butting together. **Only exception sections collapse**, marked by an **inline caret after the count** —
  never leading, never in the row-chevron slot (D-19i). The **body section never collapses**. A label gets **air
  above and none below**, at least 2:1. A label is **never smaller than its rows** and **never identical to a
  row's second line**. A row never repeats its section's state.
- **D-19n** — a long list keeps its context: a 44px page bar (absolute overlay, `inert` keeps exactly one focusable
  back control) + a sticky section heading; on a search-first page the search pins and hides on scroll-down.
- **Sheets** (D-19e): 44px ✕, no Cancelar row. **Destructive = centred dialog** (D-19f), but removing from a
  curated list is not destructive (D-19k). **Status = dot + text** (D-19h). **Kind = quiet lowercase tag; count =
  neutral pill bottom-right** (D-19m).
- Type ranks (D-19j): title 22/600 › prompt 17/600 › 48px field › **section 15/600** › row names 14–15 › chips 12–13.
  Note the BENCHMARK's `Label (group) 13/600` is a **form** section label (sketch 065) and does **not** govern a
  list section header — conflating the two caused decision 20.
- Spanish is **Argentine voseo**; mobile first; no age facet.

## Working agreement (it is what made 069, 070 and 071 work)
- **One question at a time**, 2–4 options with a recommendation. **Build the variants** — this developer evaluates
  in the browser, not from prose, and asked for variants explicitly when given ASCII. Build them as tools toggles
  and remove the losers once one is picked.
- **Measure before building and after every change**, and **look at the screenshots**.
- **Record every decision** (the developer's words + the measurements) in `.planning/notes/juegos-ui-redesign.md`,
  continuing the numbering; app-wide rules also go to `01.8.2-CONTEXT.md` and `01.8.2-BENCHMARK.md`.
- Sketches show only the UI being designed.

## Process rules this page earned the hard way
- **When consecutive rounds keep re-touching one seam, the seam is not the problem — the structure that creates it
  is.** Decisions 13→14→15→16 were four passes at the same 20px of screen. Decision 17 deleted all of them by
  changing the premise. Four passes should have prompted a premise check, not a fifth pass.
- **When a decision is superseded, re-check what was justified by the thing it removed.** Twice a rule outlived its
  reason: hints deleted for a premise decision 18 changed, and a rank lowered to separate it from controls decision
  17 deleted. A supersession note should list what becomes **re-openable**, not only what is now true.
- **When a guard fires on a legitimate exception, make the assertion more precise — never weaker.** The `1 anatomy`
  check fired on decision 21's deliberately tighter first section; the fix was to split it into ink-identity plus
  two spacing checks, documenting the exception rather than deleting a field.

## Measuring toolkit + the traps this page has actually hit
- Serve `python3 -m http.server 8765`; `playwright-core` from the npx cache (loader in `verify.js`),
  `channel: 'chrome'`, viewports 360×640 / 375×667 / 375×740 / 390×844, `deviceScaleFactor: 2`.
- Hide `#tools` before real clicks. After scripted edits, extract the inline `<script>` and `node --check` it.
- **A scripted `replace()` that must match should assert**, not be eyeballed — one silently no-op'd and the feature
  simply did not land. Every edit in this session asserts and fails loudly.
- **Measure ink, not boxes, when the element draws nothing.** A transparent header's box edge is invisible, so box
  gaps reported three different spacing variants as identical. Every spacing number for a transparent element is
  text-to-text. (Box-vs-visible has now bitten this project three times.)
- **Park the cursor off-canvas before sampling colour.** A click leaves the mouse on its target and `:hover` swaps
  `--color-surface` for `--color-surface-2`, which split one contiguous tinted mass into two and failed a real
  check. `verify.js` has a `cool()` helper; call it before any colour sampling.
- **Count tinted masses from raw pixel runs down a text-free column**, never from a computed style per element —
  the latter proves nothing about what the eye reads stacked.
- **A screenshot lied twice**: two byte-identical bands looked like different tints (simultaneous contrast).
- **Lazy covers**: R2 thumbnails are `loading="lazy"`; force eager and wait for decode before shots.
- **Re-query after any render**: a check clicked a group open then clicked a *stale* node to close it, mutating the
  page so every later measurement was silently wrong.
- **Sticky pins to the scroller's top edge (y=53), not the viewport's** — compare against the scroller. And a
  "pinned" test must also require the section to still extend past the bar, or headers scrolled out of view count
  as pinned (three at once, caught by the harness).
- The simulated keyboard is 292px; dropdowns and sheets must end above it.
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
