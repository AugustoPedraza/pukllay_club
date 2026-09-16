---
sketch: 065
name: admin-composition
question: "Do the five admin pages designed on their own hold together as one app in a continuous walk — Admin → Juegos → editor → ‹ back → Web → sección → Estantes → Asignar → Perfil — or has drift crept in?"
winner: "composition (no variants) — 6 rounds: 11 drift bugs, weight balance, what a list row says, one field anatomy, one list label, alignment + sheet rhythm; plus the mobile keyboard 059/061 never tested"
tags: [admin, consistency, composition, shell, rhythm, labels, weight, status, fields, counters, keyboard, mobile-first, phase-01.8.1]
---

# Sketch 065: Admin, composed

## Design Question
059–064 each designed one surface on its own. Put the real shell around the real pages and walk
them in one sitting: does it read as one app? This is a consistency check like 007/011/012 on the
public side, and like those, it found real bugs.

## Not a redesign
`build.js` slices the pages out of the shipped sketches and emits `index.html`. The stylesheet is
063's verbatim; the Admin home is 060's, Juegos is 061's, Web/sección/Estantes/Asignar/Niveles/Staff
are 062's, the editor is 063's. **A fix has to be made in the source sketch and re-generated** — the
composition cannot quietly diverge from what those sketches say, and the build throws if an anchor
moves. The only thing written here is what no single sketch could own: one router, one render, one
event layer, the walk, and the phone keyboard.

```
node .planning/sketches/065-admin-composition/build.js     # regenerate after editing 059–063
python3 -m http.server 8765 &                              # from the repo root
node .planning/sketches/065-admin-composition/verify.js    # 164 checks
```

## How to View
http://127.0.0.1:8765/.planning/sketches/065-admin-composition/index.html

The top bar walks the whole thing (**▶ Siguiente**). *tools* has Tema, Vista, Rol, Datos, the game's
Estado, BGG ok/failed and a **Teclado** switch. Tapping any field opens the simulated keyboard.

## What the walk found

Eleven things. Every fix is in the source sketch, not here.

### 1. Four sets of counters, and the Admin home lied after any edit → 060, 061, 062
060's dashboard read a frozen literal, 061's badge read `jCount('draft')`, 062's pages read live
state, 063 hard-coded `{juegos: 3, estantes: 84, niveles: 7}`. Alone each is self-consistent.
Composed: **ubicá un juego in Asignar and the Estantes badge stays at 84**; resolve all seven level
mismatches and the page says "Todo coincide con BGG" while the badge and the drawer still say 7.
Now one `DATA()`/`cnt()` pair — 062's, the only fully derived one — and every dashboard box, drawer
count and tab badge reads it and nothing else. `syncBadges()` refreshes every badge; it used to
refresh only Juegos.

### 2. One ludoteca, two sizes → 061, 062
The Juegos page counted **408 juegos**, Estantes and the Admin box **412**. `HIDDEN_PUBLISHED`
396 → 400, so 12 seeded + 400 hidden = 412 = `TOTAL`.

### 3. The Staff box invented its own number → 060, 061, 062
060/061 hard-coded "1 invitación pendiente" whatever the staff list held; 062 said "invitación
pendiente" with no count and, unlike every other pending thing in the admin, no pill. Now derived,
pluralised, and a pill when there is one.

### 4. Three answers to "this is a labelled block" → 059–063
| Before | Where |
|---|---|
| 11px uppercase muted | Agregar juego · Filas del inicio · Equipo · Sin ubicar (061/062) |
| 12px sentence muted | Nombre · Subtítulo (062's section editor) |
| 13px sentence, full colour | Portada · En el club · Estado (063's R6) |

Two labels and one size now: a **section** label is 13px/600 in full colour, a **field** label is the
same 13px/600 muted. `.group-label` keeps exactly the job 059 gave it — the header of a row group
inside the drawer or a sheet — so "RENOMBRAR ESTANTE" in a sheet still reads as sheet furniture.
063's R6 label won because it was the most recently argued and, at 11px, a page section was nearly
invisible next to its own content.

### 5. Two treatments for a group of setting rows → 059–063
The section editor's "Mostrar en el inicio / Orden" sat between hairlines; the game editor's "En el
club" is a soft rounded box (063's R3: *strokes and dividers are replaced by soft tinted blocks*).
Same component, two looks, one tap apart in the walk. Page bodies now use the box; sheets keep rows.

### 6. The page head sat at three distances above the first block → 059–063
16px on list pages, **12px on Asignar** (its spacer follows `.trow`, so it missed the polish rule that
bumped the others to 16), 24px in the editor — while blocks are 24px apart on every page
(`.jsec + .jsec`, `.sec + .sec`). The editor was right: 24px everywhere.

### 7. The Admin home had no head gap at all → 060, 061, 062
`pageHead()` special-cased `panel` to emit no spacer, and `.dash` added its own 12px top margin. The
home page's title sat 12px above its boxes where every other page sat at 16 (now 24).

### 8. Page titles landed at three heights under a back row → 059–063
48 / 50 / 55px for sección / editor / Asignar. A bare title starts at its row's top, but Asignar's
44px "Renombrar" centred the 26px title inside its row, and the editor's title is an input in a 48px
row. The title now aligns to the top of its row in all three, so it does not jump between drill-downs.

### 9. The editor's back row sat 4px below every other drill-down's → 063
`.eback-row` wrapped `.back` in a flex row and reset its margins. It now carries `.back`'s own
offsets, so ‹ Juegos, ‹ Web and ‹ Estantes all start at 4px.

### 10. The level vocabulary was defined twice, in two shapes → 062
062 held the three level names; 063 held names **and** what they mean. So "Ingenio estratega" was
explained in the game editor's Nivel sheet and simply assumed in Revisar niveles — the same word
taught on one screen and taken for granted on the next. Composing them collided on one `const BANDS`.
One definition now, and Revisar niveles' "Pasar a …" row carries the level's meaning instead of
"Usa el nivel que indica BGG", which told a staffer nothing the row above it didn't. `build.js`
throws if the two sketches ever disagree again.

### 11. 059 and 060 were two rounds behind on type → 059, 060
Neither carried 061's R2 polish pass — no `.polish` block, never applied the class — so the Admin
home and the shell rendered their titles at 32px Bebas and their fields at the pre-polish scale,
while every page reached from them used 22px Inter. Both now carry the block and apply it.

## Round 2 — font-weight balance

The app ships Inter **400 and 600 only**, so 064 could only ask "is every weight 400 or 600?" (it is).
Balance is about *where* 600 lands. Counting every visible text run in the page body:

| | Admin | Juegos | editor | Web | sección | Estantes | Asignar | Niveles | Staff |
|---|---|---|---|---|---|---|---|---|---|
| before | **94%** | 11% | 44% | 15% | 10% | 37% | 11% | 18% | 29% |
| after | 63% | 12% | 44% | 15% | 10% | 37% | 11% | 18% | 29% |

**The Admin home was 94% bold — 15 of its 16 text runs.** Every line of every box was 600: the name
(16px/600) *and* the number (22px/600), stacked, with nothing between them, so neither led. Worse,
the number was **typographically identical to the page's own title** — both 22px/600 — so "412"
shouted as loudly as "Admin", four times over. "Revisar niveles" wrapped to two bold lines and became
the heaviest thing on the page.

The rule the rest of the admin already followed, now written down and enforced:

> **600 marks a label, an action, or a state that needs noticing. Content is 400.**

So in a dashboard box the **name is the box's label** → 13px/600, the same as the section label a box
effectively is (down from 16px, which also stops "Revisar niveles" wrapping); the **number is
content** → 22px/**400**, still the headline figure, just no longer shouting. Each box now has
exactly one bold run — its name — plus the accent pill when work is pending. The page title leads
again.

Second finding, same rule: **`.err-t` was 400 while `.st-draft` was 600**, so in a Juegos row "Error
al traer datos de BGG" — the one line with a Reintentar button next to it — read *quieter* than the
"Borrador" status it replaces. An enrichment failure is exactly "a state that needs noticing": 600.

**The editor's 44% is not drift.** It is the read-only BGG box, whose pills are the shipped public
component (`.pk-pill { font-weight: 600 }` in `assets/css/app.css`) — 063 mirrors the public game
page on purpose, and changing the weight there would break the mirror and diverge from production.

Locked in by `verify.js`:
- **W1** nothing in a page body is both as large as and as heavy as that page's own title (display
  type — the editor's Bebas name and poster — is judged by size, since Bebas has one weight);
- **W2** every Admin box has exactly one 600 run, its name, the pending pill aside;
- **W3** an error reads at least as loud as the status it stands in for;
- **W4** the bold share of every page is printed on each run, so a future round can see it move.

## The mobile keyboard — 059 and 061 flagged it, nobody had tested it

All four questions are answered in the sketch and asserted in `verify.js`.

- **iOS focus-zoom.** Every admin field was 14–15px, and iOS zooms the page in when a focused field's
  text is under 16px. 061's note said "handle it with the viewport meta" — but `maximum-scale=1` also
  takes pinch-zoom away from everyone, which is a real accessibility loss for a 14px UI. Instead
  fields grow to **16px on coarse pointers only**; the viewport meta stays `width=device-width,
  initial-scale=1` and the page stays zoomable.
- **The tab bar while a field has focus:** it leaves. A bottom bar with the keyboard up is either
  hidden behind it (iOS does not resize the layout viewport) or pressed against its top row
  (Android), which is where Estantes gets tapped instead of the space bar. It slides back on blur.
  On desktop nothing moves — there is no soft keyboard there.
- **A bottom sheet with the keyboard open:** the sheet sits **on top of** the keyboard, not under it,
  its max height shrinks to match, and it is not pushed off the top of the screen. Try Asignar →
  Renombrar.
- **Editing the 063 title and description in place:** both stay above the keyboard while you type.
  The snackbar rides up too.

Arriving on a page also must not open the keyboard: landing focus goes on the page's heading, and is
skipped when that heading is a field — which the editor's title is.

## Round 3 — what a list row says (2026-09-15)

Developer: *"on the admin/juegos, what is the point of show game date and players? instead of
represent game status label what if we use colors to show them draft, published and archived?"*

**Year and players were never in production.** The shipped `/admin/juegos` is two columns, Nombre |
Estado (`admin/game_live/index.ex:361–387`) — no year, no players, no dates. 061 added them.

- **Año stays.** It is the only thing that tells two editions of one game apart: the catalogue holds
  `Catan · 1995` and `Catan: Edición Aniversario 25 Años · 2020` under the same BGG id, which is the
  exact case the "¿Es otra edición?" flow exists for.
- **"N jug." goes.** Member-facing *choosing* data. A staffer here is finding a named game or working
  the drafts; player count helps with neither, and it cost ~70px of a 375px row.

**Colour alone: no.** Three measured reasons, not a preference:
1. **WCAG 1.4.1** — colour must never be the only visual means of conveying information.
2. **The colours are already too weak to carry it.** Measured against the row: the amber draft dot
   was **2.78:1**, under the 3:1 floor for non-text contrast (1.4.11). Published 3.92, retired 4.04.
   The dot was failing as a *supporting* cue; as the sole carrier it is worse.
3. **Grey and shadow already mean other things.** Grey/dim reads as *disabled / unavailable* on both
   iOS and Android — but a **Borrador is the most actionable row on the page**, the one you must go
   finish, so greying it inverts the meaning. Shadow is a surface channel (what floats above what),
   is nearly invisible in dark mode, and 063 R3 deliberately stripped shadows out of this admin.
   Grey *is* right for **Retirado** — that one really is inactive.

**The real problem was that the label was on all 412 rows.** The fixture is 3 borradores / 407
publicados / 2 retirados, so **98.8% of rows said "Publicado"** — the least informative word on the
page, 407 times. Mobile practice: *mark the exception, not the rule.*

| status | row |
|---|---|
| **Publicado** | no marker at all. Just the game and its year. |
| **Borrador** | the same accent pill this admin already uses for pending work everywhere else — the drawer counts, the tab badges, the Admin box's "3 borradores" — so the row and the badge that counts it speak with one voice. |
| **Retirado** | a muted outline pill **and** a muted row (name + desaturated thumb). |

The **"¿Es otra edición?" banner** is the one place every status shows, Publicado included: it
compares one or two named games rather than scanning a list, so each one's status is the point.

Measured after: Borrador **11.3:1** light / 10.5 dark, Retirado 6.2 / 6.9, Publicado (banner) 12.1 /
10.5, and a muted retired name still **6.2:1** — muted, never illegible.

**Two repo rules this follows.** `app.css:1165–1200` governs pills: *"every visual property a pill can
have is declared here, once; a call site picks the base and a tone… a call site that needs a property
this block does not offer adds a VARIANT here, never a rule of its own."* The shipped admin's
`badge badge-warning` is a sixth pill family sitting outside that system, and this is the shape of
the variant it should become. And `card-interaction.md` already tested bright row badges and rejected
them — *"it reads as louder than a metadata detail warrants"* — so these pills are quiet, not filled
warning colours.

Asserted by `verify.js` in both themes: **S1** published is unmarked, every exception is marked and
marked with its *word*; **S2** every status label ≥ 4.5:1 against what is really behind it; **S3**
only retired rows are muted, a retired name stays readable, and a draft never reads as disabled;
**S4** the meta line is the year and no player count.

## Round 4 — Buscar and Agregar are one control (2026-09-15)

Developer: *"buscar por nombre and the 'agregar' fields must to play better balance"*.

Measured, the two sit **24px apart, both 44px tall, both starting at the same left edge, both 14/400
text** — and then differ on three of four surface properties:

| | Agregar | Buscar (before) |
|---|---|---|
| radius | 8px | **9999px** (pill) |
| border | 1px `--stroke` | **transparent** |
| background | `--color-bg` | **`--color-surface`** (filled) |

Two problems, not one. The obvious one is that at that distance three differing properties read as
inconsistency rather than as "search is a different species". The subtler one is what the fill
*means*: **`--color-surface` is what a soft content BLOCK is made of in this admin** — `.sbox`,
`.ppanel`, the settings-row group, the edition banner (063 R3: *strokes and dividers are replaced by
soft tinted blocks*). Filling an input with it made the search field read as a container rather than
as something you type into.

The search field now takes the same anatomy as every other field — 8px radius, 1px `--stroke`, page
background — **through the 064 block itself**, not a parallel rule: `.sfield input` was added to that
block's `:is()` list, the same move that put the admin's status chip inside the pill system. The
leading magnifier and the clear button carry "this is search" on their own, and 8px now matches
everything else in the stack: the Agregar field, the Agregar button and all four filter chips.

Measured after: both fields 44px / 8px / 1px, stroke **4.3:1** light and **3.49:1** dark (floor 3:1).

The pill was also the only element in that whole control stack not on 8px — so this removes an
outlier shape rather than flattening a meaningful difference.

**It also closed an audit hole.** 064 checks that every text field carries a 1px stroke at ≥3:1, but
its selector was `.tin, .field input` — the search field was never audited, which is part of why it
could drift. The selector now includes `.sfield input`.

Asserted by `verify.js`: **F1** every text field on a page shares one anatomy (height, radius, border
width, background), with 063's in-place editors (title, description, units) exempt exactly as 064
exempts them.

## Round 5 — the Juegos list gets a name (2026-09-15)

Juegos was the only page in the admin with an unlabelled block: "Agregar juego" named the add form,
then the search, the filters and 412 rows sat under no heading at all — while Web labels **Filas del
inicio**, Estantes **Orden de recorrido**, Staff **Equipo**, Asignar **Sin ubicar**, and a sección
**Ajustes** / **Juegos · 18 de 20**. Every one of those pages is [action-label form] then
[content-label list]; Juegos had only the first half.

**Wording.** Four were rendered in place and compared:

| | verdict |
|---|---|
| **Juegos del club** | **picked** |
| Catálogo | cleanest to look at — one word, no repetition — but it invents a *third* name for a set the app already calls "Juegos" (tab, page title, drawer) |
| Todos los juegos | correct only while the Todos chip is selected; tap Borradores and the label is wrong |
| Fichas de juego | precise but jargon |

"Catálogo" lost to a rule this project already wrote down, in `card-interaction.md`: *"inventing a
second, different vocabulary just for this indicator when the app already has an official 3-tier band
name elsewhere creates two parallel vocabularies for the same concept. Reuse the existing one."* The
same reasoning applies to the name of the collection. So the label reuses the official word and
qualifies it — and **"del club" earns its keep on this page specifically**, because the block right
above it adds games *from BGG*. "Juegos del club" is the ones you already have, as opposed to the one
you are about to pull in.

The count line stays where it is. It is a *result* count — it follows the search and the chips that
change it, so it belongs after them, not in the section head where 062's `lhead` puts a static count.

**The new rule found a second one.** Asserting it across the walk flagged Asignar's "En este estante"
block as unlabelled too — but that one is a **collapsible header that is also the control**
("En este estante · 68 juegos ⌄"), so it names itself and a label above it would only repeat it. The
rule is *every block that holds a list names itself*, and a disclosure row satisfies that; the
assertion accepts it explicitly rather than being loosened.

Asserted by `verify.js`: **L1** every block holding a list carries a visible label or a disclosure
row that names it, on every page of the walk.

## Round 6 — alignment and rhythm, eight things caught by eye (2026-09-16)

| # | What | Root cause | Fix |
|---|---|---|---|
| 1 | The Nivel pencil broke the right alignment line | `justify-content: space-between` pinned the pill to the box's content edge, so its pencil — 7px inside the pill — landed at **357.8** where every other end-of-row pencil sits at **365.5**. Close enough to read as a miss. | The facts row groups left (`flex-start`, wrap), as it already did on desktop and on the public page. Nothing in that row claims the line now. |
| 2 | "Datos de BGG 🔒 Solo lectura" not aligned | `.sec-note` was an `inline-flex` whose first item is an `<svg>`. An SVG has no baseline, so the note aligned by its box edge and rode ~4px above the label's. | Plain `inline`, with the icon on `vertical-align: -2px`. Off by 1.3px now. |
| 3 | "Ver más" wasn't split off as the collapse control | `.bgg-body` ended exactly where `.bgg-more` began — zero seam between the content and the thing that collapses it. | It takes the footer treatment `.cta2` already gives "Agregar a una fila": a soft full-width button on `--color-bg` inside the surface box, 12px clear of the last fact. |
| 4 | **Unidades → Copias**, and 1 \| 2 \| Más lopsided | `min-width: 44px` made the cells 44 / 44 / **47.9** — "Más" is wider than a digit. | One `width: 48px` for all three. And the label is **Copias**: a club says it has two *copias* of a game; *unidades* reads like retail stock. The schema field stays `units` — this is copy, not code. |
| 5 | Estado broke the rhythm | A borderless text button hides 14px of padding above and below its label, so the declared 8px gap read as **~22px** of dead space and the box bottom as ~26px — and the label stopped 12px short of the content edge. | With an all-text action row the button's own padding *is* the rhythm (gap and bottom padding go to 0 → an even 14/14); the moment the row carries an outlined button, which has a real border to keep off the edge, both come back at 12px — `.ppanel`'s internal gap. A trailing text button is pulled out 12px so its label lands on the content edge, the same rule already applied to a leading one. |
| 6 | Web's "filas sin juegos" note buried | It sat *after* eight rows, as a footnote to a rule you needed *before* scanning. | Moved directly under "Filas del inicio" as the section's hint, and reworded: *"Una fila sin juegos publicados no se ve en el inicio, aunque esté acá."* It steps aside while Ordenar mode shows its own hint. |
| 7 | sección unbalanced, content overlapping | **A regression from round 1.** Unifying `.sgroup` into the editor's soft box also set `margin: 0`, dropping its `16px` top margin — so the box butted straight into the Subtítulo field above it. And "Ajustes" (section) and "Nombre" (field) were both 13px/600, separated only by colour, so three near-identical lines stacked. | Top margin restored. Field labels step down to **12px/600 muted** — one size under the 13px section label, so the rank is legible. |
| 8 | Sheet rhythm inconsistent | The filas sheet's switch rows were `.srow` at 56px while every other sheet's rows are `.dlink` at 48px; and "Ver en la ludoteca" had no chevron while "Ver el sitio público" — which does the same thing, navigate away — had one. | `48px` for sheet rows everywhere; the chevron rule is *a row that leads somewhere carries one, a row that acts in place does not*. |

Every sheet now shares one shell, measured: padding `8px 16px 16px`, grab `4px auto 12px`, an 11px caps label 4px above its first block, 48px rows, full-bleed.

Asserted by `verify.js`: **R1** a pencil is either on the row's content edge or clearly away from it
(no near-misses); **R2** a label's inline note sits on its baseline; **R3** a box's collapse control is
separated from what it collapses; **R4** the Copias cells are one width and the label is Copias;
**R5** Estado's action lands on the content edge and the box breathes evenly; **R6** every sheet
shares one padding, grab, label style, first gap, row minimum and inset, and a navigating row carries
a chevron. **D4** now asserts *two ranked tiers* of label rather than one style.

## Left as settled
- **The editor's title is 30px Bebas** while every page title is 22px Inter. That is 063's deliberate
  mirror of the public game page, and the walk did not argue against it — it now at least starts at
  the same height as every other title.
- **059 still says Panel / Secciones / Cuenta** and shows a plain count where 060's rule says a count
  pill always means pending work. 060 supersedes it on both; rewriting 059 would falsify the record
  of its own round.
- **"How many are in this list" is told four ways** — a pending pill, a neutral count, a summary line,
  or inline in the label. Under 060's rule each means something different, so it is a vocabulary
  rather than drift.

## Verification
`verify.js` — 164 checks in headless Chrome, phone (420px) light and dark, then desktop at 1440px.

- **the walk** (10 stops): no horizontal overflow, every page opens at the top, at most one tab lit,
  and the lit tab follows the page into its drill-downs (editor → Juegos, sección → Web, Asignar →
  Estantes);
- **D1** every drill-down's back row starts at the same height;
- **D2** every page title is the same type;
- **D3** the head ends 24px above the body on every page, and titles start at the same height with
  and without a back row;
- **D4** one section-label style across the admin;
- **D5** every list row declares the same minimum height and slot (rendered height still grows when a
  name wraps — 061's rule, on purpose);
- **D6** badge, drawer count, dashboard box and page agree, and keep agreeing after an assignment,
  after resolving every level mismatch, and about the size of the ludoteca;
- **K1–K4** the four keyboard questions above;
- **W1–W4** the weight balance (round 2);
- **F1** one field anatomy (round 4);
- **L1** every list block names itself (round 5);
- **R1–R6** alignment and sheet rhythm (round 6);
- **S1–S4** status marks the exception (round 3).

063's `verify.js` (63/63) and 064's `audit-admin.js` (94/94) still pass with every upstream fix in.
