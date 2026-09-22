# Admin Estantes — Find a Game, Place a Box

**Status: DECIDIDO 2026-09-22, not confirmed on a real device.** Everything below was measured in
headless Chrome at 360×640, 375×667, 375×740 and 375×800, in both themes. No physical phone, no
real staff, no real shelf has seen it.

**Sketch 069 is a restart, not an iteration.** After 068 the developer said *"Let's start over all
of this UI. Ask the question and I'll let you know. Be sure to focus only on that UI."* Its 68
numbered decisions live in `.planning/notes/estante-ui-restart.md` and **replace everything 065-R8
and 066 drew for estantes** — one Estantes page, master/detail, the zone bar, the "Agregar juegos"
mode, "Ordenar por estante". There are **no variants left in the sketch**: every round ended with
the losers deleted, so `069/index.html` is the design, not a menu.

## Real-world constraints (these drive every number below)

- **9 horizontal estantes, up to 50 boxes each.** The sketch fixture is
  `SIZES = [50, 49, 48, 47, 47, 47, 47, 47, 46]` = **428 shelved** + **6 Sin ubicar** = **434 games**
  (the real published catalog; 385 have an R2 cover thumbnail, 49 fall back to the letter tile).
- **Ranked by frequency:** putting a box back / picking one up is the frequent job; adding, ordering
  and removing are rare. The page is built for the frequent one.
- **No checkout state until Phase 4.** The app knows a game's *spot*, not whether the box is on the
  shelf right now. "Juegos afuera" is Phase 4 data — the sketch fakes 3 to reserve its place.
- **The data does not exist yet, and this UI is what creates it.** `01.8.2-CONTEXT.md` D-01 puts
  shelf + left-to-right position on each *copy* (new copies table, reverses 01.8.1 D-11); D-05
  deletes every shelf and assignment at migration, with **no backfill** — each copy starts Sin
  ubicar and staff walk each shelf left to right. Measured 2026-09-22 against `pukllay_club_dev`:
  **1 estante and 1 placed game of 435**. So the 9×46–50 fixture is a stand-in for the
  post-migration salón, not a claim about today; if the real shape differs, re-measure anything that
  depends on it (49 spots in one estante, the height of the "O elegí un estante" list).

## What survived the restart (verified against `069/index.html`)

The README claims four things carried over from 065-R8. All four hold in the artefact:

1. **Search answers *where it is*.** Picking a shelved game renders its estante as context plus the
   whole estante as a rail, centred on that game. No intermediate screen.
2. **The order of the games IS the shelf order.** The rail renders `w.s.ids.map((id, i) => …)` in
   array order, the group's accessible name is `"{Estante}, de izquierda a derecha"`, and each cover's
   label is `"{nombre}, caja {i+1} de {n}"`. Position is the array index — nothing sorts by name.
3. **Neighbours are one tap away.** They are already drawn either side of the lifted cover; tapping
   one moves the selection (and the two "+" follow it).
4. **"Asignar" is deleted.** Zero occurrences in the artefact — and so are "Agregar juegos" and the
   Izquierda / Medio / Derecha zone bar.

One thing the README does *not* say, worth knowing: **"caja N de M" survives only inside the
accessible name.** Decisions 8 and 32 keep box numbers and left/right counts out of every visible
string.

## Design Decisions

### The Estantes page

- **Header:** `<h1>` "Estantes" (22/600) + an **inbox icon with a count badge** → Pendientes
  (D-19g) + the **gear** → Administrar estantes. Both are bare 44px icon buttons (A3), no text —
  "Administrar" as a word broke the header's balance.
- **Idle is the question and the field, nothing else** (54, 58). `¿Qué juego buscás?` (17/600,
  centred) above the field; the 64px hero icon was removed to buy space. **The search is the most
  important component after the title: nothing below it may look heavier than the field, and
  switching what is below must never move it.** Three earlier attempts at a list under the search
  (segmented control, chips, tabs, "Últimas + filtros") were all built, measured and rejected.
- **Últimas búsquedas live in the search dropdown** (58), not on the page: focusing the empty field
  opens a quiet `Últimas búsquedas` label + **3** rows (cover · name · estante, or `● Sin lugar`).
  Typing replaces them with suggestions; clearing brings them back.
- **The search is an autocomplete that resolves to ONE game** (1, 2). Up to **6** suggestions,
  ranked starts-with then contains, accent- and case-insensitive (`NFD` strip). The dropdown falls
  **over** the page (12). Keyboard: ↑ ↓ Enter Esc. Label and placeholder are both `Buscá un juego`
  (65) — neutral across putting back, picking up, and finding a neighbour to place beside.
- **No match → `Crear «{texto}»`** under `Ningún juego se llama así.` (62), a 56px row with
  `Agregarlo al catálogo` beneath.

### When a game is found

- **The field keeps the name, with ✕ back to idle** (60, *reverses decision 11*). Tapping the field
  selects the name so typing the next box replaces it; long names end in "…" (`text-overflow:
  ellipsis` — **17 of 434 names at 375px, 19 at 360px**, do not fit; the longest is 523px).
- **The estante is context, not a heading** (63): an 18px `estante` icon + "Estante 3" at 14/600
  muted, 16px above the lifted cover. Same treatment as the sheet header (33), so the estante reads
  identically everywhere. It was 17/600 in full text colour and read as a third heading.
- **The whole estante is one swipeable rail of 96px covers** (6), centred on the game, which is
  **lifted** (23) between its neighbours.
- **"+" on each side of the selected cover** (64) opens the reverse sheet, `¿Qué juego va acá?`.
  They follow the selection.
- **Tapping another cover moves the selection; tapping the lifted one opens its sheet** (10).
- **Rhythm (61):** title row → field **16**, field → answer **32**, estante line → lifted cover
  **16**. Content stays top-aligned — the space below is the rail's room to grow, not a centring
  problem.

### The game's options sheet (29–33)

Header is cover 56×60 · `estante` icon + "Estante 7" (13px muted) · game name 18/600 · divider · ✕.
Three 64px two-line rows, each a verb plus a grey line saying what happens:

| label | hint |
|---|---|
| **Ver ficha** | *La página del juego en la web* |
| **Mover** | *Elegís el estante y el lugar* |
| **Quitar del estante** (danger) | *Queda sin lugar · te pedimos confirmar* |

No Cancelar row, no ⋯, no box number, no left/right counts.

### Placing, moving, removing

- **`¿Dónde va?` is a full-height sheet** (37) that opens **the moment a game with no spot is
  picked** (36) — from the search or from Pendientes. There is no "Ubicar" button anywhere.
- **Its search finds an estante *or* a game already on one** (36). Estantes rank first, then
  starts-with, then contains; the game being placed is excluded; 6 results max. Picking a game opens
  **its** estante with that game lifted and a "+" on each side, so the box goes "next to" something
  staff can see. **The field then keeps the chosen estante's name** (38) with ✕ to clear; the
  "Estante 3" heading over the rail is gone because the field says it.
- **You choose the spot** (35, *reverses D-00c*): before the first, between any two, or after the
  last. **An empty estante takes the game directly** as its first box, with no spot step — its row
  reads `Vacío · va directo`.
- **After placing: `Juego ubicado` + Deshacer, and the cover drops into place** (39) — from 56px
  above at 92%, small overshoot, settling lifted at −12px over **620ms**; the caption fades in. No
  motion under `prefers-reduced-motion`.
- **Mover is one transaction** (40): the same full-height sheet, the game **stays in its old spot**
  until the new one is chosen, then leaves and arrives in one step. While moving, the estante is
  drawn **without** the moving game, so moving inside the same estante works. ✕ / tap outside / Esc
  changes nothing. Snackbar `Juego movido` + Deshacer (back to the exact old spot).
- **Quitar asks first, in a centred dialog** (41, 42 — D-19f, app-wide for every destructive admin
  action; replaces 064's "Peligro always confirms in a sheet"). Title `¿Quitar {juego} del
  estante?`, body `Queda sin lugar hasta que lo vuelvas a ubicar.`, two right-aligned text actions:
  **Cancelar** (focused, safe default) and **Quitar** (danger red). Scrim tap or Esc = Cancelar.

### `¿Qué juego va acá?` (64)

The reverse of `¿Dónde va?` — the spot is known, staff pick the game. Header context is
`{Estante} · al principio | entre {X} y {Y} | al final`, title `¿Qué juego va acá?`, a focused field
`Buscá el juego que va acá`. Empty → `Sin ubicar · {N}` rows (the likely ones), or `Todos los juegos
tienen lugar. Buscá uno para moverlo acá.`. Typing searches every game; a shelved one is **moved**
here in one transaction. Picking the game already in that spot → `Ya está en ese lugar`, nothing
changes.

### Pendientes (58, 59)

Its own page behind the header inbox badge. One section per queue, each with a 15/600 heading +
count, one hint line, and **all** rows (no cap, no "Ver los N"):

- **Afuera** *(Phase 4 data)* — `Volvieron de una mesa: tocá uno para ver dónde va.` Row sub is a
  blue dot + `Afuera · va en {Estante}`. Tapping goes to Estantes with the game lifted in its spot.
- **Sin ubicar** — `Todavía no tienen lugar: tocá uno para ubicarlo.` Row sub is `● Sin lugar`.
  Tapping opens `¿Dónde va?` over Pendientes.

Empty states: `Todos los juegos están en su estante.` / `Todos los juegos tienen lugar.`

### Administrar estantes (43–49, 67, 68)

- **Estante rows only, no chevron** (45, 49) — an estante has **no page of its own**; staff read the
  boxes off the real shelf, and finding / placing / moving / removing all happen on Estantes.
  *Revises D-08.* Row = 40px `estante` tile · name · `{N} juegos` or `Vacío`.
- Header: **⇅ Ordenar** and **+ Nuevo estante**, both bare icons (44, 68).
- **Tapping a row opens its sheet**: **Editar** / *Cambiar el nombre* and **Eliminar** / *Quedan sin
  lugar · te pedimos confirmar* (or *Está vacío · te pedimos confirmar*). Eliminar confirms in the
  dialog: `¿Eliminar {Estante}?` / `Sus {N} juegos quedan sin lugar hasta que los vuelvas a ubicar.`
  (`Está vacío.` when empty) → `Estante eliminado` + Deshacer.
- **One name sheet creates and edits** (67). Header context is `{N} estantes` when creating,
  `{N} juegos` when editing; title `Nuevo estante` / `Editar estante`. Body: label `Nombre`, a 48px
  field (`maxlength=40`), hint `Un nombre que se reconozca en el salón.`, one full-width primary
  button `Crear estante` / `Guardar`. Enter saves. Creating pre-fills the next number ("Estante 10")
  **selected**, so one tap is enough. Errors under the hint in danger red with the field outlined
  red: `Escribí un nombre.` / `Ya hay un estante con ese nombre.` (case- and accent-insensitive).
  Snackbars `Estante creado` / `Nombre guardado` (silent if the name did not change).
- **Ordenar is a mode** (68). The header becomes `Ordenar estantes` + `Listo` (no back link), hint
  `Arrastrá ≡ al orden en que recorrés el salón.`, rows stop being tappable and end in a 44px ≡
  handle. Drag swaps with a neighbour once the pointer passes that neighbour's midpoint. **Tapping ≡
  without dragging** marks it and shows ↑/↓ on that row only, ends disabled, with a live region
  saying `{Estante}, posición {i} de {n}` (WCAG 2.5.7). `Listo` → `Orden guardado` + Deshacer. The
  order is the estantes' order everywhere, including `O elegí un estante`.

### Creating a game from here (62, 66)

`Crear «texto»` opens the new-game editor with the name filled in. **From the search** (no spot
yet) the editor says `Después elegís dónde va.` and saving continues into `¿Dónde va?`. **From a
rail "+"** the spot is already chosen, so the editor says `Después va en {Estante}, entre {X} y
{Y}.` and saving places it there directly. `‹ Estantes` cancels and creates nothing; closing the "+"
sheet forgets the spot. **069's editor is a stand-in — the real one is sketch 063's Juegos editor**,
which needs this entry (name prefilled) and this exit (→ placing).

## App-wide rules born here

Recorded in `01.8.2-CONTEXT.md` and `01.8.2-BENCHMARK.md`:

| rule | what it says |
|---|---|
| **D-19e** | Every sheet closes with **✕ in its header** (29). Header anatomy = cover · context line · title 18/600 · divider (31, 33). The small line above the title is **context** (where the game is / which game); the title is **what the sheet is about** (34). Replaces 065-R7's "Cancelar last with ‹". |
| **D-19f** | Every destructive admin action confirms in a **centred dialog**, never in a sheet (41, 42). Replaces 064's "Peligro always confirms in a sheet". |
| **D-19g** | Pending work lives behind a **header icon with a count badge**, not on the page (59). |
| **D-19h** | Status is a **dot + text**, never a pill (22). Tag/filter pills are not statuses and are unaffected. |
| **D-19i** | A **chevron means "navigates"** (25). Rows that answer in place have none. |
| **D-19j** | One main job per page, and the type scale backs it up. |
| **D-00c** *(revised)* | Placing/moving: choose the estante, then the spot; an empty estante goes direct (35). |

## CSS Patterns

Tokens the sketch adds on top of `themes/default.css`:

```css
:root { --stroke: color-mix(in srgb, var(--color-text) 58%, var(--color-bg)); --ter: var(--color-secondary); }
:root[data-theme="dark"] { --stroke: color-mix(in srgb, var(--color-text) 42%, var(--color-bg)); --ter: var(--color-text-muted); }
```

**Button system (carried from 064, unchanged):**

```css
/* A1 outlined */ .obtn { height:44px; padding:0 16px; border:1px solid var(--stroke); border-radius:8px; font:600 14px/1 inherit; }
                  .obtn.pri { border-color: var(--color-primary); color: var(--color-accent-text); }
/* A2 text    */ .tbtn { height:44px; padding:0 12px; border-radius:8px; font-size:14px; font-weight:600; color: var(--ter); }
                  .tbtn.pull-r { margin-right:-12px; }   /* label lands on the 16px content edge */
/* A3 icon    */ .ibtn { width:44px; height:44px; border-radius:50%; color: var(--color-text-muted); }
                  .ibtn svg { width:20px; height:20px; } .ibtn.pull-r { margin-right:-12px; }
```

**Search field and dropdown:**

```css
.sfield input { width:100%; height:48px; padding:0 48px 0 14px; border:1px solid var(--stroke);
                border-radius:8px; font-size:16px; text-overflow: ellipsis; }
.sfield .sico { position:absolute; right:2px; top:2px; width:44px; height:44px; }  /* magnifier ↔ ✕ */
.sugg { position:absolute; left:0; right:0; top:calc(100% + 4px); border:1px solid var(--color-border);
        border-radius:12px; box-shadow: var(--shadow-lg); padding:4px 0; max-height:264px; overflow-y:auto; }
.srow { min-height:56px; padding:6px 12px; gap:12px; }
```

`max-height: 264px` is load-bearing: the room between the dropdown's top (181px) and a 292px phone
keyboard (448px) is 267px. It was 272 and ran 5px under the keyboard after decision 61 moved the
field down 8px.

**The rail** (this is 067's rail kept verbatim, with real covers):

```css
.shelf { position: relative; margin: 0 -16px; }                      /* full-bleed */
.shelf::before, .shelf::after { width:16px; }                        /* edge fades in --color-bg */
.shelf .board { position:absolute; left:16px; right:16px; bottom:50px; height:4px; border-radius:2px;
                background: var(--color-surface-2); }
.rail { display:flex; gap:10px; overflow-x:auto; scroll-snap-type: x proximity; padding:16px 16px 8px;
        scrollbar-width:none; }
.box  { flex:0 0 96px; width:96px; scroll-snap-align:center; }
.box .bc  { width:96px; height:100px; border-radius:6px; object-fit:cover; }
.box .cap { font-size:12px; line-height:1.3; color:var(--color-text-muted);
            -webkit-line-clamp:2; display:-webkit-box; -webkit-box-orient:vertical; overflow:hidden; min-height:31px; }
/* lifted (23) */
.box.on .bc  { transform: translateY(-12px); box-shadow: 0 14px 22px -6px rgba(36,18,56,.45); }
.box.on .cap { color: var(--color-text); font-weight: 600; }
:root[data-theme="dark"] .box.on .bc { box-shadow: 0 14px 22px -6px rgba(0,0,0,.8); }
```

Cover fallback is the letter tile (**49 of 434** games): `hsl(var(--h) 45% 84%)` / text
`hsl(var(--h) 40% 28%)`, inverted in dark, hue hashed off the name. The 2-line clamp clips
**34 of 434** real names (measured across all 9 estantes in 067) — they end in "…".

**The insertion slot ("+"):** a visible 24px dashed circle with a 44px hit box that runs *under*
the (inert) covers without covering them.

```css
.slot { position:relative; flex:0 0 20px; align-self:stretch; display:grid; place-items:start center; z-index:2; }
.slot::before { content:""; position:absolute; inset:0 -12px; }      /* 20 + 12 + 12 = 44px target */
.slot .pl { width:24px; height:24px; border-radius:50%; border:1px dashed var(--stroke); background: var(--color-bg); }
.rail .slot .pl { margin-top: 38px; }                                /* optically centred on the covers */
#rail .slot { margin: 0 2px; }                                       /* 12px to each cover */
.rail.placing { gap: 4px; }
.placing .box { pointer-events: none; }                              /* covers are inert while choosing */
```

**The landing animation (39):**

```css
@keyframes land { 0%{transform:translateY(-56px) scale(.92);opacity:0} 55%{transform:translateY(-6px) scale(1.02);opacity:1}
                  78%{transform:translateY(-15px) scale(1)} 100%{transform:translateY(-12px)} }
.box.on.landed .bc  { animation: land 620ms cubic-bezier(.2,.8,.3,1) both; }
.box.on.landed .cap { animation: landcap 620ms ease-out both; }
@media (prefers-reduced-motion: reduce) { .box.on.landed .bc, .box.on.landed .cap { animation: none; } }
```

**Sheets (D-19e):**

```css
.sheet { position:absolute; inset:auto 0 0; border-radius:18px 18px 0 0; max-height:85%; overflow-y:auto;
         transform: translateY(105%); transition: transform 260ms var(--ease-out-soft); box-shadow: var(--shadow-lg);
         padding-top:0; padding-bottom: calc(16px + env(safe-area-inset-bottom, 0px)); }
.sheet.open { transform: none; }
.sheet.full { top: 24px; max-height: none; }          /* large detent: 24px of page still shows */
.sh-top  { position: sticky; top: 0; z-index: 2; background: var(--color-bg); padding-top: 8px; }  /* ✕ never scrolls away */
.grab    { width:36px; height:4px; border-radius:2px; margin:0 auto 8px; }
.sh-head { display:flex; gap:16px; align-items:center; padding:8px 16px 16px;
           border-bottom:1px solid var(--color-border); margin-bottom:8px; }
.sh-head .cov { width:56px; height:60px; border-radius:6px; }
.sh-title { font-size:18px; font-weight:600; }        /* the only 600 in the sheet */
.est-meta { display:flex; align-items:center; gap:6px; margin:0 0 4px; font-size:13px; color:var(--color-text-muted); }
.est-meta svg { width:16px; height:16px; }
.sh-x    { width:44px; height:44px; margin:-6px -10px 0 0; align-self:flex-start; border-radius:50%; }
.sh-x svg { width:22px; height:22px; }
/* one row anatomy for every sheet: 22px line icon, label at x54 */
.dlink { display:flex; align-items:center; gap:16px; min-height:48px; padding:0 16px; font-size:16px; }
.dlink svg { width:22px; height:22px; color: var(--color-text-muted); }
.dlink .dsub { display:block; font-size:13px; color: var(--color-text-muted); }
.dlink:has(.dsub) { min-height:64px; padding-block:8px; }
.dlink.danger, .dlink.danger svg { color: var(--color-danger); }
/* with the keyboard up, the sheet sits on top of it */
.device.kbd2 .sheet.full, .device.kbd2 .sheet.form { bottom: 292px; padding-bottom: 0; }
```

**The confirmation dialog (D-19f)** — M3 basic dialog:

```css
.dscrim { position:absolute; inset:0; z-index:60; display:grid; place-items:center; padding:24px;
          background: color-mix(in srgb, #231339 38%, transparent); }
.dialog { width:100%; max-width:312px; border-radius:16px; padding:24px 24px 12px; box-shadow: var(--shadow-lg);
          transform: scale(.96); }
.dscrim.open .dialog { transform: none; }
.dialog h2 { font-size:18px; font-weight:600; margin:0 0 8px; }
.dialog p  { font-size:14px; line-height:1.45; color:var(--color-text-muted); margin:0 0 16px; }
.dacts     { display:flex; justify-content:flex-end; gap:8px; margin-right:-12px; }
.tbtn.dan  { color: var(--color-danger); }
```

Focus lands on **Cancelar** 60ms after open. Scrim tap and Esc both = Cancelar.

**List rows:**

```css
.rows { margin: 0 -16px; }                                           /* full-bleed, content edge stays 16px */
.row  { min-height:60px; padding:8px 16px; gap:12px; }
.row + .row::before { content:""; position:absolute; top:0; left:68px; right:0; height:1px; background:var(--color-border); }
.row.compact { min-height:48px; padding:6px 16px; }                  /* dropdown recents, queue rows */
.row.compact .cov { width:32px; height:32px; border-radius:5px; }
.row.compact .name { font-size:14px; } .row.compact .sub { font-size:12px; }
.row.compact + .row.compact::before { left:60px; }
.shelfico { width:40px; height:40px; border-radius:8px; background:var(--color-surface); color:var(--color-accent-text); }
```

**Status (D-19h) and the pending badge (D-19g):**

```css
.dot      { width:8px; height:8px; border-radius:50%; background:#D9892B; }   /* Sin lugar */
.dot.out  { background:#3D7DD8; }                                             /* Afuera (Phase 4) */
.badge    { position:absolute; top:5px; right:3px; min-width:18px; height:18px; padding:0 5px; border-radius:9px;
            background: var(--color-primary); color:#fff; font:600 11px/18px inherit;
            box-shadow: 0 0 0 2px var(--color-bg); }                          /* "99+" over 99 */
:root[data-theme="dark"] .badge { background: var(--color-accent-text); color: var(--color-bg); }
```

**Snackbar (D-19b/c):** pinned `bottom: 79px` above the tab bar, `left/right: 12px`, min-height 48,
radius 8, `--color-text` fill on `--color-bg` text, 44px ✕. 10s with an action, 4s without.

**Idle-vs-raised layout (27, 28, 54, 61):** the whole page toggles one class.

```css
.hero { display: none; }
.device:not(.raised) .hero { display:flex; flex-direction:column; align-items:center; gap:16px;
                             text-align:center; margin-bottom:24px; }
.device:not(.raised) .search { margin-top: 0; }
.hero p { font-size:17px; font-weight:600; }                 /* "¿Qué juego buscás?" */
.device:not(.raised) .sp-top { flex: 2 1 0; }                /* free space splits 2:3 above:below */
.device:not(.raised) .sp-bot { flex: 3 1 0; }                /* an exact 1:1 centre reads as sinking */
.search { margin-top: 16px; }                                /* raised: title row → field 16 */
.answer { margin-top: 32px; }                                /* field → answer 32 (a new group) */
#answer .rail { padding-top: 24px; }                         /* estante line → lifted cover 16 */
```

`raised` is set when the field is focused **or** a game is picked. The transition is FLIP-animated.

**The `estante` icon** — a shelf that still reads as one at 16px. Two rejected drawings: a framed
cabinet (read as a window) and a single board with boxes (read as a sofa). The vertical-stroke
`shelf` glyph reads as a barcode.

```
M3.5 3.5v17M20.5 3.5v17M3.5 12h17M3.5 20.5h17   + three rects for boxes standing on the boards
```

## HTML Structures

**The rail with its two "+" slots** (only the selected cover gets them):

```html
<h2 class="aname e1"><svg …>estante</svg>Estante 3</h2>
<div class="shelf">
  <div class="rail" id="rail" role="group" aria-label="Estante 3, de izquierda a derecha">
    …
    <button class="slot" data-act="addat" data-sid="3" data-pos="2"
            aria-label="Poner un juego entre Ten y High Society"><span class="pl">+</span></button>
    <button class="box on" data-act="box" data-id="88" aria-pressed="true"
            aria-label="High Society, caja 3 de 48. Tocá para ver opciones">
      <img class="bc" src="…" alt=""><span class="cap">High Society</span></button>
    <button class="slot" data-act="addat" data-sid="3" data-pos="3"
            aria-label="Poner un juego entre High Society y Lost Cities"><span class="pl">+</span></button>
    …
  </div>
</div>
```

Covers use `<img class="bc" alt="">` — the name is already in the button's `aria-label` and its
visible caption, so the image is decorative.

**Sheet shell:**

```html
<div class="sheet full" role="dialog" aria-modal="true">
  <div class="sh-top">
    <div class="grab"></div>
    <div class="sh-head">
      <img class="cov" …>
      <div class="sh-txt">
        <div class="est-meta">Tokaido Duo</div>       <!-- context -->
        <div class="sh-title">¿Dónde va?</div>        <!-- what the sheet is about -->
      </div>
      <button class="sh-x" data-act="close" aria-label="Cerrar">✕</button>
    </div>
    <div class="psearch">…pinned field…</div>
  </div>
  <div class="pbody" id="pbody">…</div>
</div>
```

Focus goes to the **sheet itself** (or a named field), never to the first row — a focused first row
painted as if it were already chosen.

**Spot buttons are real buttons with real names.** Every "+" announces the gap:
`Poner al principio de {Estante}` · `Poner entre {X} y {Y}` · `Poner al final de {Estante}`
(page rail: `Poner un juego …`).

## Spanish copy, verbatim

Snackbars (all with **Deshacer** except the two marked): `Juego ubicado` · `Juego movido` ·
`Juego quitado del estante` · `Estante eliminado` · `Orden guardado` · `Estante creado` *(no
Deshacer)* · `Nombre guardado` *(no Deshacer)* · `Ya está en ese lugar` *(no action)*.

Empty / error lines: `Ningún juego se llama así.` · `Ningún estante ni juego se llama así.` ·
`Todos los juegos tienen lugar.` · `Todos los juegos están en su estante.` ·
`Todavía no buscaste ningún juego.` · `Escribí un nombre.` · `Ya hay un estante con ese nombre.`

Labels: `O elegí un estante` · `Vacío · va directo` · `Sin ubicar · {N}` · `Sin lugar` ·
`Afuera · va en {Estante}` · `Buscá un estante o un juego` · `Buscá el juego que va acá`.

## What to Avoid

**Sketch 066 — superseded in full.** Do not build:
- **Master/detail with one page per estante** (`/admin/estantes/:id`), its title + count, zone bar,
  rail, ⋯ and "Agregar juegos" mode. Decision 45 **revises D-08**: an estante has no page, because
  staff read the boxes off the real shelf and every action already happens on Estantes.
- **Single-open / focus recession** (round 1). It was structurally overloaded — one screen carried
  five outlined controls and "Ordenar" meaning two different things one scroll apart. Round 1 also
  proved the paint fix is impossible: opacity fails WCAG 1.4.3 at **0.88** for a still-live row, so
  recession had to be a colour step, which then collides with the retired-game row's own signal.
- **"Siguiente estante ›"** — measured at only **−2.4%** taps (448 vs 459 over 12 estantes and ~412
  copies), and the walk that matters most (the start-empty first run, D-05) never passes through it.
- The **Nuevo estante → lands on the new estante's page** flow. There is no page to land on; the
  name sheet returns to the list (67).

**Sketch 067 — the page it drew is gone, but two findings survive into 069 and still hold:**
- ✅ **Keep:** the rail with real R2 covers and the **letter-tile fallback** (49 of 434 games), and
  the caption's **2-line clamp ending in "…"** (34 of 434 names clipped). Both are live in 069.
- ❌ **Do not build** its variants A (lista numerada, 4.0 screens for a 50-box estante) or B (4-col
  grilla, which cut **85 of 434** names, 20%). Both were static read-only views of a page that no
  longer exists.

**Sketch 068 — winner null, nothing from it ships:**
- The **position bar** (Izq ——●—— Der) as the "where along the shelf" cue.
- `Estante 1 · caja 25 de 50` and `entre {X} y {Y}` as **visible** result-row text — decisions 8 and
  32 keep box numbers and left/right counts out of every visible string; the neighbours' covers are
  the cue. The box number survives only in an `aria-label`.
- `Opciones de la caja` as a text action opening a sheet, and 065's selected-box panel it replaced.
- Its "answer inside the result row" shape (A) / "expand in place" shape (B). 069's answer is the
  page itself: one picked game, its estante, its rail.

**Decisions 069 itself reversed — do not resurrect from the notes:**
- **Decision 11** (clear the field the moment a game is found) — reversed by **60**; the field keeps
  the name with ✕.
- **D-00c** (a placed box goes to the far right end) — reversed by **35**; you choose the spot, ends
  included, empty estante goes direct.
- **065-R7's "Cancelar last with ‹"** in sheets — replaced by **D-19e** (✕ in the header).
- **064's "Peligro always confirms in a sheet"** — replaced by **D-19f** (centred dialog).
- Every rejected list-under-the-search: segmented control (52, and its A/B), M3 tabs, the ⌄ menu,
  chips, and "Últimas + filtros" (55–57). Decision **58** removed all of it from the page.

**Other traps:**
- Do not sort a shelf's games by name. `shelves.ex:170-177` does today and `game.ex:84` documents
  *"at most one shelf per game, no in-shelf position"* — D-01/D-05 replace both. This UI is what
  records the real order.
- Do not put a "+" hit box on top of a cover. The 44px target runs *under* the covers
  (`.slot::before { inset: 0 -12px }`) and the covers are `pointer-events: none` while placing —
  measured so the lifted cover's last pixel still opens its sheet.
- Do not give two rails the same `id`. A real bug found in round 4: the page's `#rail` sits behind
  the "¿Dónde va?" sheet, so centring scrolled the wrong one. The sheet's rail is `#prail`.
- Do not measure focus behaviour in headless Chrome without `Emulation.setFocusEmulationEnabled` —
  no focus events fire and the keyboard simulation silently never appears.

## Open items (069 flags three, all verified against the artefact)

1. **Catan-family ranking in the suggestions.** `suggestions()` ranks starts-with first, then
   contains, in catalog order, capped at 6 — so typing `cat` surfaces only one of the five Catan
   editions. The 6-result cap plus prefix-first ordering is the mechanism; families are exactly what
   decision 2 said covers would disambiguate.
2. **`shelfDrawing` is dead code on the Estantes page.** Verified: defined once at
   `069/index.html:648`, **zero call sites**. Decision 54 removed the idle hero's icon and 33 gave
   sheets and management rows the new `estante` glyph. Either delete it or find it a home before
   porting.
3. **Whether Quitar keeps Deshacer after confirming.** Today it does both: the D-19f dialog confirms
   *and* `doQuitar` fires `snack('Juego quitado del estante', { label: 'Deshacer' })`. Decide
   whether a confirmed destructive action should still be undoable before writing the LiveView.

Plus, not on that list but flagged in the notes: **where `Crear «texto»` leads** is settled in 069
(decision 66) but the editor it opens is a **stand-in** — sketch 063's real Juegos editor must grow
this entry (name prefilled, a "después" line) and this exit (→ placing, or straight into the chosen
spot).

## Origin
Synthesized from sketches: 069 (current), 066 / 067 / 068 (superseded)
Source files available in: `sources/069-estantes-ubicar/`, `sources/066-estante-focus/`,
`sources/067-estante-read/`, `sources/068-locate-box/`
The 68 numbered decisions: `.planning/notes/estante-ui-restart.md`
App-wide rules: `01.8.2-CONTEXT.md` (D-19e–j, D-00c, D-01, D-05), `01.8.2-BENCHMARK.md`
