# Admin Web — Destacados (the home rows)

**Status: settled, decisions 1–20** (`.planning/notes/web-ui-redesign.md`, 2026-09-17). Measured in
Chrome at 360×640, 375×667, 375×740 and 390×844, both themes. Like sketch 069, no variants are left
in the artefact — losing variants were deleted once picked, so `070/index.html` is the design.

**The Web tab is ONE page with ONE job: swapping the featured games.** Everything else — the other
home rows, ordering them, creating one — is secondary and sits *below* the job, not behind a
separate page.

> ⚠️ **The 070 README is stale on four points; the artefact is right.** Its "What is drawn" section
> still describes (a) a pencil beside the row name, (b) a separate `Filas del inicio` page reached
> with `‹ Web`, (c) a `⌄` chevron on the name, and (d) `Quitar de la fila` confirming in a dialog.
> Decisions 17, 18, 18 and 10 respectively removed all four. Build what this file describes.

## Design Decisions

### The page

- **Web opens on the destacada row itself** (2). Title `Web` (22/600) + two bare 44px icon buttons
  in the header: **⇅ Ordenar filas** and **+ Nueva fila** (18 moved them here; the old "rows" icon
  is gone). Under the title, the row's **name at 17/600**, then a muted context line, then the rail,
  then `Otras filas`.
- **The name is a 44px button that opens the row's options sheet** (17, 18). No pencil, no chevron —
  one target instead of two, and the name is no longer a control that only renames. The button uses
  `padding: 11px 8px` (not `min-height`) so a **one-line name (44.1px) and a wrapped two-line name
  (66.2px)** keep the same 5px of visible air above the context line.
- **Context line** (14, 15, 18): state only, no kind tag — you are already inside the row.
  `{n} de 20 juegos` (destacada) · `{n} juegos` (hand-picked) · `Sin juegos, no se ve en el inicio`
  (empty), prefixed by `● Oculta ·` when hidden.
- **The games are the rail** (3), the same component the public home uses: 96px covers in home
  order. **Order is what you see.** Rejected: cover+name list rows with an ⇅ Ordenar mode (~1300px
  of rows); a 3-column grid (fits one screen, which the home does not).
- **A "+" in every gap, always visible** (5) — before the first cover, between every two, after the
  last. Adding needs no selection first, so **nothing is lifted on arrival** and tapping a cover
  opens its options sheet directly. The accepted cost: ~2.6 covers visible at 375px instead of ~3.5,
  and a 20-game row is 2,852px wide instead of ~2,110.
- **At the cap the "+" dims and a tap explains it**: `Ya hay 20 juegos. Quitá uno para agregar otro.`
- **Empty row:** the rail becomes a single 96×100 dashed tile plus the line
  `Tocá + para elegir el primer juego.`
- **`Otras filas` is a group under the rail** (18), not a page. It closed a real hole: measured with
  7 games and 96px covers, the page's content block was a constant 250px pinned to the top and the
  blank below ran **245px at 360×640 (47%), 272 at 375×667 (50%), 345 at 375×740 (56%), 449 at
  390×844 (62%)**. The page is now 914px tall — 3 rows visible under the rail at 375×667, 6 at
  390×844.
- **Any hand-picked row opens the same page** (12) with a `‹ Web` back link and no list. Web is that
  page opened on the destacada; the 20-game cap applies only to the destacada. A 61-game row's rail
  is **8,592px** — the long swipe was accepted deliberately.

### "Destacada" is a role, not a row (7)

- **Exactly one** hand-picked row holds it at any time; it is always first on the home. Destacar on
  another row takes the role away from the old one, which stays as a normal row and **heads the
  rest**. A hidden row becomes visible when it is destacada.
- **Only hand-picked (`manual`) rows can be destacada** — automatic rows (the Nivel bands,
  Recientemente añadidos) never get `Destacar`, so Web always opens on a rail staff can edit.
- **A row with more than 20 games cannot be destacada**; its `Destacar` sub-line says why
  (`Tiene {n} juegos · la destacada lleva hasta 20`), and picking it anyway snacks
  `Tiene {n} juegos. Dejá 20 o menos para destacarla.`
- Today's model is `sections.featured`, a boolean — making the role movable means setting it on one
  row clears it on the other, and the cap follows the role.

### Row sheet (D-19e header: tile · context · title · ✕)

Context reads `Fila destacada` / `Fila personalizada` / `Fila automática`. Rows, in order, all 64px
two-line:

| row | hint | when |
|---|---|---|
| **Destacar** | *Pasa a ser la primera fila del inicio* | hand-picked, not currently destacada |
| **Cambiar la destacada** | *Elegí otra fila de la lista y tocá Destacar* | on the destacada's own page (scrolls to `Otras filas`) |
| **Editar la fila** | *Su nombre y su subtítulo en el inicio* | always |
| **Juegos** | *Agregar, quitar y ordenar* (hand-picked) / *Se editan en Web* (destacada) | only from the list, never on the row's own page |
| **Ocultar del inicio** | *Guarda sus juegos para más adelante* | never for the destacada — the home always shows it |
| **Mostrar en el inicio** | *Vuelve a verse en su lugar* | when hidden |

Rows are hide-only. There is no delete.

### The game's options sheet

Header is cover · row name (context) · game name (title) · ✕. Three rows:

| label | hint |
|---|---|
| **Ver ficha** | *La página del juego en la web* |
| **Mover** | *Elegís otro lugar en la fila* |
| **Quitar de la fila** | *Deja de verse en el inicio* |

**`Quitar de la fila` has no dialog and is not red** (10 → **D-19k**): the game leaves at once with
`Juego quitado` + Deshacer (10s). Removing from a curated list is not destructive — the game and its
shelf spot are untouched, and Deshacer restores the exact position. A 5-game swap is **10 taps, not
15**. D-19f's dialog stays for state staff would have to rebuild.

### Adding a game — `¿Qué juego va acá?`

Full-height sheet opened from a "+". Header context is `{fila} · al principio | entre {X} y {Y} | al
final`; title `¿Qué juego va acá?`; a pinned, focused field `Buscá un juego`.

- **Idle shows `Últimas novedades`** (11) — the 6 most recently added games not already in the row.
  Featuring new arrivals is the likely reason to swap, so it is often one tap and no typing.
- Typing searches every game (starts-with, then contains, 6 max). A game already in the row shows
  the sub `Ya está en la fila · pasa a este lugar` and is **moved** rather than duplicated; picking
  the one already in that spot → `Ya está en ese lugar`.
- No match → `Ningún juego se llama así.` + `Crear «{q}»` / `Agregarlo al catálogo` — **stubbed to a
  snackbar in 070**, still to be designed.
- Placing closes the sheet, `Juego agregado` / `Juego movido` + Deshacer, and the cover lands.

### Moving — `¿Dónde va?`

Full-height sheet; context is the game's name, title `¿Dónde va?`. **The row is drawn without the
moving game**, so the "+" gaps are the positions it will actually have; it keeps its old spot until
one is chosen. Slot names: `Mover al principio` / `Mover entre {X} y {Y}` / `Mover al final`.

### `Otras filas` rows (14, 15, 16)

- **Tile** 40×40 with the kind's icon (star / hand / level / clock) and a **count badge hanging off
  its bottom-right corner** — 18px, page fill + 1px stroke, 11/600 muted. Deliberately a *different
  corner and colour* from Pendientes' badge (top-right, filled primary, white) so it never reads as
  a notification. The count is in the tile's accessible name (`61 juegos`).
- **Second line** = `[● Oculta ·] {kind tag} [tail]`, where the tag is a quiet outlined chip and the
  tail is `hasta 20` for the destacada or `Vacía` for an empty row.
- **The kind tag is deliberately weak** (16): 11px regular, 18px tall, hairline `--color-border`,
  muted text, and the word **lowercase** — `personalizada` / `automática`. Contrast is 6.17:1 light
  / 6.90 dark against the row name's 17.16 / 13.62, so the name clearly leads; the border is
  decorative (1.42 / 1.30) and carries no meaning. It replaces "Elegida a mano" / "Por nivel" /
  "Los últimos que llegaron" everywhere, including sheet contexts.
- **Tags are not statuses**, so D-19h (dot + text) does not apply to them. `● Oculta` *is* a status
  and uses the dot.

### Ordenar filas (a mode, same shape as 069's decision 68)

Header becomes `Ordenar filas` + `Listo`; hint
`Arrastrá ≡ al orden en que se ven en el inicio, debajo de la destacada.` Two groups: **Destacada**
— one non-draggable row with a lock icon and the sub `Siempre primera` — and **Otras filas**, each
with a 44px ≡ handle. Drag swaps at the neighbour's midpoint; tapping ≡ without dragging shows ↑/↓
on that row with a live region. `Listo` → `Orden guardado` + Deshacer.

### The name + subtitle form sheet (19, 20)

One sheet creates and edits. Header context `Fila destacada` / `Fila personalizada` / `Fila
automática`; title `Editar fila` / `Nueva fila`.

- **Nombre** — 48px field, `maxlength=40` (the real column limit), pre-filled and selected.
- **Subtítulo** — a **two-line box that grows to three** (`min-height: 72px; max-height: 96px`,
  15px/1.4, `resize: none`), `maxlength=160`. A single-line field showed only ~35 of 160 characters.
  Enter still saves — a subtitle is one line.
- **One hint under both:** `El título y esta línea son lo que se ve en el inicio.` (the Nombre hint
  was dropped to pay for the textarea's height.)
- Errors: `Escribí un nombre.` / `Ya hay una fila con ese nombre.` Button `Guardar` / `Crear fila`.
  Snackbar `Fila guardada` (silent when nothing changed) / `Fila creada`.
- Every row in the dev DB has a subtitle (8/8, longest 76 characters) — title + subtitle are the two
  lines the home prints.
- Measured at 375×740 with the 292px keyboard: sheet top **33.8** (was 45.6 with a one-line
  subtitle), `Guardar`'s bottom **16px clear** of the keyboard, nothing scrolls inside the sheet.
- **A new row opens on its own page** (13) after `Crear fila`: `‹ Web`, its name,
  `Sin juegos, no se ve en el inicio` and the empty rail's "+".

## App-wide rules born here

Recorded in `01.8.2-CONTEXT.md` + `01.8.2-BENCHMARK.md`:

| rule | what it says |
|---|---|
| **D-19k** | Removing from a curated list is **not destructive** — no dialog, just an immediate change + Deshacer. D-19f's dialog stays for losing state staff must rebuild. |
| **D-19l** | A one-job page **may list its siblings below the job** (Web lists `Otras filas` under the destacada's rail). |
| **D-19m** | Kind tag + count badge anatomy — and the count badge is **never** the pending-work badge (different corner, different colour). |

## Measured (375×667 unless noted, both themes)

| | value |
|---|---|
| title row → name text | 16.8 |
| name → context line | 5 |
| context → covers | 16 |
| cover to cover | 44 (= the "+" hit box) |
| covers visible | ~2.6 (2 whole) |
| rail width, 7 games / 20 games / 61 games | 1,032px / 2,852px / 8,592px |
| last caption → `Otras filas` heading | 32 (rail 8 + 16 + the heading's own 8) |
| heading → first tile | 16 |
| header glyph | on the content edge (x359) |
| add + name sheets with the keyboard | end exactly at the 292px keyboard |
| horizontal page scroll at 360 | none |
| name button, one line / two lines | 44.1px / 66.2px |

Dev data the sketch runs on (2026-09-17), in home order: **Destacados del club** (manual, featured,
7 games) · Crea conexiones (61) · Equipo ganador (54) · Duelos memorables (19) · *Favoritos de
Lacerda* (a hidden temporary list, 9) · Descubre el hobby (level, 179 published) · Ingenio estratega
(183) · Nivel experto (46) · Recientemente añadidos (recent, newest 30). A non-destacada row shows
at most **30** games on the home (`@carousel_infinite_scroll_max`); the destacada at most **20**.

## CSS Patterns

The sheet, dialog, snackbar, row, `.tbtn` / `.ibtn` / `.obtn` and `--stroke` / `--ter` systems are
**identical to 069's** — see `admin-estantes.md`. What is specific to Web:

**The row name as one button:**

```css
.fname { display:flex; align-items:center; min-height:44px; margin-top:-3px; }
.fname .fnbtn { display:flex; align-items:center; gap:4px; max-width:100%;
                margin-left:-8px; padding:11px 8px; border-radius:8px; text-align:left; }
.fname h2 { margin:0; font-size:17px; font-weight:600; line-height:1.3; overflow-wrap:anywhere; }
.fctx { margin:-6px 0 0; display:flex; align-items:center; gap:6px;
        font-size:14px; line-height:1.35; color:var(--color-text-muted); }
```

`padding: 11px 8px` rather than `min-height: 44px` — a min-height only has slack while the name is
one line, and a wrapped name overlapped the context line by 6px.

**The rail with a "+" in every gap** (the slot carries the spacing, so `.rail` has no `gap`):

```css
.rail { display:flex; overflow-x:auto; scroll-snap-type:x proximity; padding:16px 16px 8px; }
.box  { flex:0 0 96px; width:96px; }
.box .bc  { width:96px; height:100px; border-radius:6px; object-fit:cover; }
.box .cap { font-size:12px; line-height:1.3; -webkit-line-clamp:2; display:-webkit-box;
            -webkit-box-orient:vertical; overflow:hidden; min-height:31px; color:var(--color-text-muted); }
.slot { position:relative; flex:0 0 20px; margin:0 12px; align-self:stretch; }   /* 20 + 12 + 12 = 44 */
.slot::before { content:""; position:absolute; inset:0 -12px; }
.slot:first-child { margin-left:0; } .slot:last-child { margin-right:0; }
.slot:first-child::before { left:-16px; } .slot:last-child::before { right:-16px; }
.slot .pl { width:24px; height:24px; margin-top:38px; border-radius:50%;
            border:1px dashed var(--stroke); background:var(--color-bg); }
.slot.full .pl { opacity:.45; }                                    /* at the 20-game cap */
/* empty row: the slot becomes the tile */
.rail.empty { align-items:center; gap:12px; padding-bottom:16px; }
.rail.empty .slot { flex:0 0 96px; height:100px; margin:0; border:1px dashed var(--stroke); border-radius:6px; }
.rail.empty .slot .pl { margin:0; border:0; }
```

**Landing** is **520ms** here (069's estante landing is 620ms — do not unify them by accident):

```css
.box.landed .bc { animation: land 520ms cubic-bezier(.2,.8,.3,1) both; }
@media (prefers-reduced-motion: reduce) { .box.landed .bc { animation: none; } }
```

**Kind tag and count badge (D-19m):**

```css
.tag { display:inline-flex; align-items:center; height:18px; padding:0 6px; border-radius:4px;
       font-size:11px; font-weight:400; line-height:1; white-space:nowrap;
       border:1px solid var(--color-border); color:var(--color-text-muted); }
.sub:has(.tag) { margin-top:-1px; }    /* an 18px tag sits lower than a 13px line; keeps the row at 64px */
.tile { position:relative; width:40px; height:40px; border-radius:8px;
        background:var(--color-surface); color:var(--color-accent-text); }
.tile svg { width:22px; height:22px; }
.cnum { position:absolute; right:-5px; bottom:-5px; height:18px; min-width:18px; padding:0 5px;
        border-radius:9px; background:var(--color-bg); border:1px solid var(--stroke);
        color:var(--color-text-muted); font:600 11px/1 inherit; display:grid; place-items:center; }
```

The badge clears the row divider (badge right edge 61, divider starts at 68).

**Group rhythm:**

```css
.row   { min-height:64px; padding:8px 16px; gap:12px; }
.row + .row::before { content:""; position:absolute; top:0; left:68px; right:0; height:1px; background:var(--color-border); }
.row.hid .name { color: var(--color-text-muted); }
.lhead { margin:8px 0 4px; font-size:15px; font-weight:600; line-height:1.3; }
.shelf + .fgroup { margin-top:16px; }   /* last caption → heading reads as 32 */
.fgroup + .fgroup { margin-top:12px; }
.lock { width:44px; height:44px; margin-right:-12px; opacity:.6; }   /* the destacada in Ordenar mode */
```

Group spacing is set on **visible edges, not boxes**: a row's tile ends 12px inside its box, so a
32px box gap read as 44 against 16 above.

**Subtitle textarea:**

```css
.tfield.ta { height:auto; min-height:72px; max-height:96px; padding:12px 14px;
             line-height:1.4; font-size:15px; resize:none; overflow-y:auto; font-family:inherit; }
.flab.sp { margin-top:16px; }
button, input, textarea { font: inherit; color: inherit; }   /* textarea MUST be in this list */
```

That last line is a real bug fixed in round 5: `button, input { color: inherit }` did not cover
`textarea`, so the subtitle rendered near-black in dark theme.

## HTML Structures

**The page:**

```html
<div class="phead">
  <h1 class="ptitle">Web</h1>
  <div class="hacts">
    <button class="ibtn" data-act="ordon" aria-label="Ordenar filas">⇅</button>
    <button class="ibtn" data-act="newrow" aria-label="Nueva fila">+</button>
  </div>
</div>

<div class="fname">
  <button class="fnbtn" data-act="rowopts" aria-haspopup="dialog"
          aria-label="Destacados del club · opciones de la fila">
    <h2 id="fname">Destacados del club</h2>
  </button>
</div>
<p class="fctx">7 de 20 juegos</p>

<div class="shelf">
  <div class="rail" id="rail" role="group" aria-labelledby="fname">
    <button class="slot" data-act="add" data-pos="0" aria-label="Agregar un juego al principio">
      <span class="pl">+</span></button>
    <button class="box" data-act="box" data-id="12"
            aria-label="Everdell, 3 de 7. Tocá para ver opciones">
      <img class="bc" src="…" alt=""><span class="cap">Everdell</span></button>
    <button class="slot" data-act="add" data-pos="1"
            aria-label="Agregar un juego entre Everdell y Pictures"><span class="pl">+</span></button>
    …
  </div>
</div>

<section class="fgroup" id="others">
  <h2 class="lhead">Otras filas</h2>
  <div class="rows">
    <button class="row" data-act="rowsheet" data-rid="2">
      <span class="tile" role="img" aria-label="61 juegos">…icon…<span class="cnum" aria-hidden="true">61</span></span>
      <span class="txt">
        <span class="name">Crea conexiones</span>
        <span class="sub"><span class="tag">personalizada</span></span>
      </span>
    </button>
    …
  </div>
</section>
```

The rail's `role="group"` is labelled **by the row name** (`aria-labelledby="fname"`), so the row's
identity is announced once rather than repeated on every cover.

A hidden row prefixes its sub with `<span class="dot"></span>Oculta<span aria-hidden="true">·</span>`
— dot + text, never a pill (D-19h).

## Spanish copy, verbatim

Headings / labels: `Web` · `Otras filas` · `Destacada` · `Ordenar filas` · `Listo` ·
`Últimas novedades` · `Nombre` · `Subtítulo`.

Context lines: `{n} de 20 juegos` · `{n} juegos` · `Vacía` · `hasta 20` · `Sin juegos, no se ve en
el inicio` · `Siempre primera` · `Fila destacada` / `Fila personalizada` / `Fila automática` ·
`Oculta` · `personalizada` / `automática` (lowercase, in the tag).

Sheet titles: `¿Qué juego va acá?` · `¿Dónde va?` · `Editar fila` · `Nueva fila`.

Snackbars (all with **Deshacer** unless noted): `Juego agregado` · `Juego movido` · `Juego quitado` ·
`{fila} es la destacada` · `Fila oculta` / `Fila visible` · `Orden guardado` · `Fila guardada`
*(no Deshacer)* · `Fila creada` *(no Deshacer)* · `Ya está en ese lugar` *(no action)* ·
`Ya hay 20 juegos. Quitá uno para agregar otro.` *(no action)* ·
`Tiene {n} juegos. Dejá 20 o menos para destacarla.` *(no action)*.

Hints and errors: `Tocá + para elegir el primer juego.` ·
`Arrastrá ≡ al orden en que se ven en el inicio, debajo de la destacada.` ·
`El título y esta línea son lo que se ve en el inicio.` · `Ya está en la fila · pasa a este lugar` ·
`Ningún juego se llama así.` · `Crear «{q}»` / `Agregarlo al catálogo` · `Escribí un nombre.` ·
`Ya hay una fila con ese nombre.`

## What to Avoid

- **Do not build a separate `Filas del inicio` page.** Decision 18 folded it into Web; the 070
  README's round-2 description of it (`‹ Web`, two groups, its own ⇅/+ header) is superseded. The
  ⇅ and + live in **Web's** header; `Otras filas` is a section under the rail.
- **Do not add a pencil beside the row name, or a `⌄` chevron.** Both existed and both were removed
  (17, 18). The name itself opens the sheet.
- **Do not confirm `Quitar de la fila` with a dialog** (D-19k). It is undoable list editing, not
  destruction. Do not paint that sheet row red or give it `· te pedimos confirmar`.
- **Do not let an automatic row hold the destacada role**, and do not allow more than one destacada
  — Web would lose its single job (7).
- **Do not use the Pendientes badge for the row count.** Different corner (bottom-right vs top-right)
  and different colour (page fill + stroke vs filled primary/white) on purpose (D-19m).
- **Do not make the kind tag tonal or bold.** A 12/600 tonal chip was tried (T1) and a 12/600
  outlined one shipped briefly; both outranked the row name they label. It is 11px regular,
  lowercase, hairline border (16).
- **Do not put a "Buscá en la fila" field over the rail** or split long rows onto a list page (12) —
  both add a second control above the main one, against D-19j.
- **Do not lift a cover on arrival.** The lift existed only to reveal the "+"; with a "+" in every
  gap it has no job (5).
- **Do not reuse 069's 620ms landing here** — Web's is 520ms.
- **Do not forget `textarea` in `button, input { color: inherit }`** (see CSS above).

**Not drawn, still open:**
- The **public home page** itself.
- **Ver ficha** (stubbed to a snackbar; another sketch).
- **`Crear «{q}»` from the add sheet** (stubbed to a snackbar) — Estantes' equivalent is settled
  (069 decision 66, into sketch 063's editor); Web's is not.
- What a hand-picked row's **61-cover, 8,592px rail** feels like to walk was accepted as a long
  swipe without being tested on a real device.

## Origin
Synthesized from sketches: 070
Source files available in: `sources/070-web-destacados/`
The 20 numbered decisions: `.planning/notes/web-ui-redesign.md`
Shared sheet / dialog / snackbar / button system: `references/admin-estantes.md`
App-wide rules: `01.8.2-CONTEXT.md` (D-19e–m), `01.8.2-BENCHMARK.md`
Real code today: `lib/pukllay_club_web/live/admin/section_live/index.ex` + `edit.ex`
