---
sketch: 065
name: admin-composition
question: "Do the five admin pages designed on their own hold together as one app in a continuous walk — Admin → Juegos → editor → ‹ back → Web → sección → Estantes → estante abierto → Perfil — or has drift crept in?"
winner: "composition (no variants) — 10 rounds: 11 drift bugs, weight balance, what a list row says, one field anatomy, one list label, alignment + sheet rhythm, one component per job (save bar · view control · grouped list · sheet actions), ONE Estantes page (the physical order of a shelf, a game's zone and its neighbours, with the Asignar screen and the Recorrido/Contenido control retired into it), the mobile keyboard 059/061 never tested — and, in round 10, ONE ACTION SYSTEM: the context picks the anatomy, the role picks the paint (A1 outlined · A2 text · A3 icon · A4 sheet row), from a census of 113 controls over 25 surfaces that found 7 real bugs no check could see. Round 9 tested the developer's \"what if we use carousel … to represent that physical position\" with three variants and MEASURED THE RAIL AS THE LOSER at 162 boxes (the edge-fade distinguishes 3 positions; 27 arrow presses or 8–15 flings to the middle against 2 taps of search); round 10 is a DEVELOPER OVERRIDE of that verdict — B ships, A and C are deleted, and the cost R9 charged is paid by the ZONE BAR: the same three zone words the census retired as description become the three jump targets, 1 tap to the middle instead of 27 presses, a scoped 024 exception earned by shelf length (nothing under ~30 boxes), with zona · estante kept on a search-result row"
tags: [admin, consistency, composition, shell, rhythm, labels, weight, status, fields, counters, keyboard, components, save-bar, disclosure, chips, sheets, estantes, physical-order, position, zones, neighbours, fixture-honesty, a11y, mobile-first, carousel, rail, developer-override, actions, hierarchy, action-matrix, touch-targets, phase-01.8.1]
---

# Sketch 065: Admin, composed

## Design Question
059–064 each designed one surface on its own. Put the real shell around the real pages and walk
them in one sitting: does it read as one app? This is a consistency check like 007/011/012 on the
public side, and like those, it found real bugs.

## Not a redesign
`build.js` slices the pages out of the shipped sketches and emits `index.html`. The stylesheet is
063's verbatim; the Admin home is 060's, Juegos is 061's, Web/sección/Estantes/Niveles/Staff are
062's, the editor is 063's. **A fix has to be made in the source sketch and re-generated** — the
composition cannot quietly diverge from what those sketches say, and the build throws if an anchor
moves. The only thing written here is what no single sketch could own: one router, one render, one
event layer, the walk, and the phone keyboard.

```
node .planning/sketches/065-admin-composition/build.js     # regenerate after editing 059–063
python3 -m http.server 8765 &                              # from the repo root
node .planning/sketches/065-admin-composition/verify.js    # 468 checks
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
  its max height shrinks to match, and it is not pushed off the top of the screen. Try Estantes →
  open an estante → ⋯ → Renombrar, or Estantes → Nuevo estante. *(Round 8 re-pointed this at both of
  them: it used to be driven through the Asignar screen, which no longer exists.)*
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

## Round 7 — four notes on a sección, and every one was a second implementation (2026-09-16)

Developer, all four about the same page:

> - the form (nombre and subtitle fields) with the "mostrar al inicio" feels so disconnected between them, breaking balance and killing rhythm
> - the form fields and the search looks all same (search? form fields?)
> - cambios sin guardar and its CTA are disconnected (why a pure text?)
> - "Ordenar" looks pure text. Improve its affordance … same pattern everywhere

Plus one from Estantes: *"the field blinks when I type."* Five complaints, and not one of them was a
style opinion — each turned out to be a **second implementation of something this admin already had**.

| # | What | Root cause, measured | Fix |
|---|---|---|---|
| 1 | The Ajustes block had two surfaces | One labelled block held *bare* Nombre and Subtítulo fields on the page background and then a soft `--color-surface` box for the two setting rows, with gaps of **8 / 6 / 12 / 6 / 16px** down its middle. Nothing said the four controls were one group. | The fields join the box as field rows: **one panel, gaps 12 / 12 / 12, padding 12 above the first child and 12 below the last** — `.ppanel`'s internal gap, the editor's box rhythm. A field label keeps the half step (6px) over its own input, because a label and its input are one unit. |
| 2 | "search? form fields?" | Not anatomy. Round 4 deliberately gave the search field the same anatomy as every other field, and that still holds (F1 asserts it). The two read ambiguously because **both sat on the same page background** with nothing saying which block each belonged to. | Item 1 fixed it on its own, and it is now measured rather than argued: on a sección the form fields sit on `--color-surface` and **`mem-q` is the only field left on `--color-bg`**. The next lever, if it ever comes back, is the search's position relative to its list — never its anatomy. |
| 3 | **The admin had two save bars** | 063 built `.ebar.inline`: a soft surface block with a status line (`.bl1` + its dot over `.bl2`) and its actions (`.eactions`, Principal last), carrying round 6 #5's rhythm rule. 062 built `.saverow`: a 12px accent note and an outlined button **floating loose on the page background, 16px under the box**. Same job, two components, one tap apart in the walk. | sección uses the editor's component — same classes, same measured `12px 16px` padding, 12px gap, `--color-surface` fill, 12px radius, 13px/600 status line, 44px action landing exactly on the box's content edge (365.5 vs 365.5). What stays true of a sección is that it has **no draft/published lifecycle**, so the status line's own job is the save state — and the dot carries it, exactly as "Borrador" does in a Juegos row. The button is the editor's one-word **Guardar**, not "Guardar cambios". |
| 4 | "Ordenar" read as pure text | It was 064's **Terciaria** rung — no stroke, purple label — for a control that switches every row in the list below it into a different mode. And it was pulled 12px past the row's content edge (**393.5 vs 381.5**), which is the correct treatment for a borderless label and wrong for a button. | A real outlined button in **both** states, changed at the `lhead()` level so Web, Estantes and sección move together: **Secundaria** to enter (1px `--stroke`, 4.3:1 light / 3.49:1 dark) and **Principal** to leave (1px primary, 14.16:1 / 11.67:1) — because "Listo" is the one action that finishes that block's job. `aria-pressed` flips false → true, the border colour changes with it, both states are 44px, and both end on the content edge at 381.5. The row grows 36 → 44px to hold a real button; every other `lhead` right slot (`.gcount`, `.pend`) still sits dead centre on its label's middle (delta 0.0 on all seven). |
| 5 | The search field blinked while you type | `QMAP[id]` debounced 300ms and then called `patch()`, and `patch()` does `main.innerHTML = adminBody()` — so **every keystroke destroyed the focused input, built a new node and put the caret back**. It hit all three of 062's searches. 061 had already solved it for Juegos: `refreshList()` swaps `#jlist` and `#jfilters` and never touches `#q-in`, which is how LiveView would diff it. | One region id per search — **`#mem-results`, `#est-groups`, `#asg-results`** — replaced on its own by `refreshQ(id)`. Measured: the input node identity survives every keystroke, its box is byte-identical between them (`343/44/…`), the caret walks 1,2,3,4,5 and never jumps. The same move fixed the sección form: typing Nombre or Subtítulo now calls `syncSecBar()` and swaps `#sec-bar` alone, the way 063's `sync()` swaps `#ebar` while you type a game's name. |

**One thing the round direction got wrong, and the measurement said so.** Making sección's bar the
same component was supposed to make the two bars measure identically. They don't, and they
shouldn't: the editor's *clean* bar is `12px 16px 0` with `gap: 0` while a sección's is `12px 16px`
with `gap: 12px`. That is round 6 #5's rule firing correctly — an all-text action row's own 14px of
button padding *is* the rhythm, so the box's gap and bottom padding go to zero; an outlined button (or
no action row at all) has a real border to keep off the edge, so both come back at 12px. The census
assertion therefore compares the component's identity — classes, position, fill, radius, border — and
prints the padding rather than requiring it to match. Both bars still measure 12/12 top-to-bottom.

Two smaller things fell out of this. The `.ebar.inline` rules were scoped `.r6 …`, which only ever
meant "the editor", so they moved to `#device .ebar.inline` — `.inline` was already saying it — and
the whole definition now lives in **one block, byte-identical in 062 and 063**, which `build.js`
throws on if they ever drift (the same guard the level vocabulary got in round 1 #10). And dropping
`.saverow`'s 16px margin left the new bar butting **straight against the settings panel at 0px** — a
seam bug the panel work introduced, caught by measuring the section rather than looking at it. It is
12px now, the panel's own rhythm.

Asserted by `verify.js`, both themes at 420px and again at 1440px: **C1** the Ajustes block is one
panel on one rhythm with even padding and its fields still clear the 3:1 stroke floor over the tint
(3.72:1 light / 3.14:1 dark); **C2** the form is in the panel and the search is the only field on the
page background; **C3** exactly one save-bar implementation is left in the admin (`.saverow` and
`.dirty-note` are gone), sección's and the editor's share every component property, both land their
Principal on the content edge and breathe 12/12, and the bar keeps a 12px seam; **C4** the reorder
toggle carries a 1px stroke over 3:1 in both states on all three pages, is 44px, ends on the content
edge, flips `aria-pressed`, and changes its border — not just its word; **C5** typing in a search
never replaces the input node, never moves its box, never jumps the caret, and refreshes its region
instead.

## Round 7b — three notes on Estantes, and the measurement disagreed with the brief four times (2026-09-16)

Developer, all three about the same page:

> - on estantes, that double list doesn't scale at all since i need to scroll down to found what already is on the estante. Find better default standard on mobile for this kind of problem
> - on estantes rename, the bottom sheet use cancel and save pattern. That CTA looks too heavy. And be sure to define a kind of pattern that must to be used everywhere (full consistency)
> - on estantes, Estantes | Juegos por estantes filled feels weird. Improve it

### 6. "Juegos por estante" did not scale — and the fixture was the lie underneath it

| | before | after |
|---|---|---|
| view height, **4** shelves | **1702px = 2.30 screens** | **740px = 1.00 screen** |
| view height, **12** shelves | ≈3,500px ≈ 4.7 screens (projected from a 294px group) | **1171px = 1.58 screens** |
| cost of one more shelf | a **294px** block | one **60px** row |
| games a group would show | **4**, then `y 64 más` with nothing to tap | 8, then **`Mostrar más · 8 de 84`** |
| games reachable at all | **16 of 412 (3.9%)** | every group opens to real rows; the rest is offered |
| "Estante D — expertos" | **157 juegos over 0 rows** | **162 juegos → 5 real rows**, `5 de 162` |
| finding a named game's shelf | impossible unless it was in that group's first four | type the name — its group opens itself |
| search, 12 shelves, one hit | — | 1467px = 1.98 screens, **13/13** headings kept, `1 de 54 coinciden` |

The component is one this admin already ships: Asignar's `.grow.disclose`, which **round 5 ruled names
its own block**, so a collapsed group satisfies L1 without a label above it. A shelf is one disclosure
row carrying its count; it opens in place; what it cannot show it **offers** rather than captions.
`.lcap` is gone — it was a second, mute answer to "there is more here" next to `.more`'s
`Mostrar más` + `N de M`, and it sat on the only two lists you could not page (the other was
Asignar's own "En este estante", which the brief did not mention and which had the same dead end).

The groups then had to read as **one list** rather than 13 blocks, so the 20px `.grp + .grp` gap goes
and the hairline over a group header runs full-bleed — a content row's hairline starts at 76px, past
the thumb. That is the grouped-table seam, and it is the whole visual difference between "a list of
shelves" and "thirteen little pages".

**The fixture honesty problem.** `place` hard-coded a 5-cycle over shelves 1–3, so shelf 4 held nothing
locally while claiming 157 — harmless while a group only showed its first four games, a lie the moment
you can expand it. The fix is not to materialise 412 games (that would replace a count problem with a
412-row fixture and break the "36 rendered / N hidden" shape every other 062 count is built on) but to
**derive the fixture from the shelf count**: `shelfFixture(pend, n)` holds two invariants at any *n* —
every shelf really holds some of the 36 rendered games, and the hidden bases still sum to placed − 20,
so **Σ`shelfCount` = `placedN()` = 328, +84 sin ubicar = 412** at 4 shelves and at 12. At *n* = 4 it
reproduces the seeded 60 / 54 / 37 / 157 exactly, so nothing else in the walk moved.

### 8. The filled view switch was a WCAG failure, not a taste

| | `.seg.two` (before) | the chip row (after) |
|---|---|---|
| track fill, light | `#F1ECFD` = `--color-surface` — **what a soft content BLOCK is made of** (round 4) | — |
| selected segment, light | `#FFFFFF` = `--color-bg`, the page — a hole punched in a block | — |
| **selected vs track** | **1.16:1 light · 1.17:1 dark** (1.4.11 floor: 3:1) | boundary **4.3:1** light / **3.49:1** dark vs the page, **3.42 / 3.15** vs its own fill |
| what carries the state | fill + weight | **✓ glyph at 11.27:1 / 10.54:1** + fill + weight + label colour |
| radius | **10px** track (8px cells) | **8px**, like every other control in the stack |
| hit area | 36px drawn | 32px drawn / **44px** tocable |
| labels | **"Estantes"** (the page title, verbatim) \| "Juegos por estante" | **"Recorrido" \| "Contenido"** |
| instances | **1** in the whole admin | the same component as 061's four filter chips (identical `8px/1/32/400` and `8px/1/32/600`) |

**How the "a view switch is segmented" rule was resolved: it is retired.** The job is "pick one of N,
and change what the list below shows" — which is exactly the job 061 rendered both ways and decided,
choosing **A1, chips**. Keeping a second component for the same job with a single instance is the thing
this round exists to stop. `.seg` stays in the stylesheet as 061's rejected A2 variant and nothing in
the walk renders it.

**Wording.** Both labels had to name a *view*, be parallel in kind, and not repeat the page title.
**"Recorrido"** reuses the page's own word — its list block is literally "Orden de recorrido" — and
**"Contenido"** is what the shelves hold. What lost: *"Estantes | Juegos por estante"* (the first **is**
the page title, and they are not parallel — one names the page, the other a grouping); *"Estantes |
Juegos"* (both collide with a page and a tab, the two-parallel-vocabularies trap `card-interaction.md`
warns about); *"Por recorrido | Por juego"* (false — the second view groups by shelf, not by game);
*"Recorrido | Qué hay en cada estante"* (accurate, but 24 characters against a one-word chip).

### 7. One sheet-action pattern, written down

> **A sheet's actions are rows in its `.dlinks`, never a button footer** — the committing row first
> with `tick` (danger tone when destructive), "Cancelar" last with `chevL`. 48px, full-bleed, inset 0.

Rename becomes `✓ Guardar → ‹ Cancelar`, and "that CTA looks too heavy" answers itself: the outlined
Principal is now the same quiet row "Sí, quitar" already is. The committing row **is** the form's
`type="submit"`, so the one sheet in the admin with a text field still commits from the keyboard, and
the inline `.ferr` still reports without closing the sheet. Driven end to end rather than inspected:
an empty name gives "Poné un nombre.", a duplicate gives "Ya hay un estante con ese nombre.", both
keep the sheet open with focus back on the field, and Enter and a tap on the row each commit **exactly
once** (`×1`). `row()` gained `type` (default `button`), which also closed a latent bug — any `row()`
dropped inside a form would have submitted it. Variant A's inline `.renform` is a **page** form, not a
sheet, so the rule's wording leaves it alone and 064's matrix is untouched there.

### Four places the round direction was wrong, and the measurement said so

1. **"the selected state is effectively invisible in dark mode."** It measured **1.16:1 in light too**.
   Both themes failed 1.4.11; this was never a dark-mode bug.
2. **"or retire the rule and reuse the chip row that 061 already won with"** — as if the chips were
   already compliant. They were not: a chip's outline measured **1.42:1** light / **1.30:1** dark, and
   `.chip.on` set `border-color: transparent` over a fill only **1.26:1 / 1.11:1** off the page. Both
   candidates needed the same `--stroke` fix, so contrast could not decide between them. What decided
   it was the **tick glyph** (a non-colour state marker the segment has no equivalent of, WCAG 1.4.1),
   the 8px radius, and the instance count. In dark mode the accent fill still does almost nothing
   (1.11:1) — the tick is what carries the state, and that is precisely why the chip was the survivable
   component and the segment was not.
3. **"It is the only sheet in the admin with a button footer."** There were **two**: `v-rename`, and
   063's **Filas del inicio** sheet (`<button class="tbtn" data-act="e-close">Listo</button>` inside a
   `.banner-actions`). The second one was **already in R6's walk and passing**, because R6 measured the
   sheet *shell* and never its actions. Both are rows now.
4. **"fits in a bounded number of screens independent of shelf count."** It cannot be independent —
   you have to list the shelves. What is bounded is the **per-shelf cost: one 60px row**, and the
   honest form of the claim is the one the assertion checks: **12 shelves collapsed (1.58 screens) is
   still shorter than 4 shelves were before (2.30)**.

And a fifth, smaller: R6 was green on a **subset**. Adding `renombrar` to its walk immediately showed
its `.group-label` sat **inside** the form, so its label gap measured **−16.5px** against every other
sheet's **+4px**. The walk is 10 sheets deep now (`renombrar`, `orden`, `staff`, `quitar` joined it),
and `quitar` needed the wait raised to 1000ms because its confirm step *slides* — measured mid-slide it
reported a 7px row inset.

### What was deliberately not done
- **The second view was not deleted** (062's README records `?vista=lista` as a real route), and the
  two views were **not merged** into one shelf row that both expands and navigates: that is two tap
  meanings in one row anatomy, and it would collapse two documented routes into one.
- **"N jug." stays** on the rows inside a group. Round 3 removed it from the *Juegos* list, where it
  cost ~70px of a 375px row; here it costs nothing measured and no one asked.
- **"Sin ubicar" lost its accent count pill.** Its number is in the progress line directly above it, and
  one row anatomy for all 13 groups beats a thirteenth exception.
- **The selected chip's fill was not made louder.** An accent or primary stroke on it would clear 3:1
  too, but 064 reserves the accent outline for **Principal** — a selected filter chip that looks like a
  Principal button is a semantic collision, which is the exact class of bug this round is about.

Asserted by `verify.js`, both themes at 420px: **C6** the grouped view names every group with its own
disclosure row, costs one row per shut shelf, fits inside 2 screens at 4 shelves *and* at 12, adds up
(Σ = placed = 328), opens **every** group to real rows, offers what it does not show instead of
captioning it, keeps every heading while filtering (E5) and opens the groups that match with a count of
how many did — with C5's field still surviving every keystroke; **C7** both view labels carry a real 1px
boundary over 3:1 against the page *and* against their own fill in both themes, sit on 8px with a 44px
hit area, mark the choice with a glyph rather than colour alone, repeat neither the page title nor each
other, flip `aria-pressed`, and measure identically to 061's filter chips — with the whole control stack
on one shape; **C8** no sheet in the walk has a button footer, a Cancelar is always the last row with
`chevL`, the rename sheet's commit row is the form's submit, and that form still validates inline and
still commits from the keyboard.

## Round 8 — ONE Estantes page, and the order of a shelf is the order of the shelf (2026-09-16)

Developer, two messages:

> On estantes, the buttons "recorrido" and "contenido" is too complex. Is better a collapsable list of
> games on a "estante" and then games to add? also from the list I should be able to remove it and sort
> inside a "estante"?
>
> Also on estantes, crear secondary(should we use a bottom sheet for it?). The #1 action is to "look"
> where is the game(estante) and together to which games(in middle of which games). Also the list
> should be like is on the middle, more left or more right)
>
> A think the positional should be first but also could be expandable with the rest of information
> (neigtbors and estante name)

### What the page's job actually is, and what it was doing instead

**The page's job is one question: *where is this game?*** Round 7b's page could not answer it. Measured
on the round-7 build, at 420×740:

| asking "where is Catan, and what is next to it?" | round 7 | round 8 |
|---|---|---|
| taps to **which estante** | **3** — Estantes tab, "Contenido" chip, then type | **2** — Estantes tab, then type |
| taps to **what is next to it** | **never** — it was not available at any number of taps | **3** — the row expands to *"Primero del estante, antes de Just One"* |
| scroll to the hit, 4 shelves | **0** (row bottom 587 of a 740px screen) | **0** (row bottom 319) |
| scroll to the hit, 12 shelves | **0**, but the page holding it is **1467px = 1.98 screens** with **13 headings** to scan | **0**, page **740px = 1.00 screen**, **1 row** |
| scroll to the neighbours | — | **0** (expansion bottom 424 of 740) |
| the search field | **not on the landing view at all**; 227px on the other one | **167px**, the page's first control |
| the first estante row on landing | **368px** — the "Nuevo estante" form sat at 227, between the progress line and the list | **275px** |
| what a row said | `1995 · 3–4 jug.` | `Más a la izquierda · Estante D — expertos` |

**The most important number in that table is the one that is not a number.** "What is next to it" was not
slow, it was *unavailable* — and worse, it looked available: expanding a group showed five rows in
`G.filter(place === sid)` order, which is the catalogue's order, not the shelf's, and nothing said so.
Round 7b's own fixture work made the counts honest and left the *order* dishonest. Five taps to a wrong
answer.

**And the scroll was never the problem.** The brief asked for "how much scrolling", and the measured
answer is **zero, before and after**: at phone height the hit was already above the fold in round 7 too.
What changed is one tap fewer to the estante, the neighbours going from unavailable to one tap, and — at
12 shelves — the page that holds the answer going from 1467px to 740px.

### The premise everything rests on

> **The order of the games on an estante IS their physical left-to-right order on the shelf.**

So a game's zone is nothing but its index read back in words, its neighbours are the slots either side
of it, and **Ordenar moves a real cardboard box** — which is why its hint says so. Nothing measured
contradicted the premise; what it did was make the *fixture* the load-bearing part of the round (below).

### 1. The `Recorrido | Contenido` chip control is retired, one round after it was introduced

Round 7b built that control and argued its labels for a paragraph. Round 8 deletes it. **That is a
finding about the two-views premise, not an embarrassment:** neither view could answer the page's first
question. "Recorrido" had no search field; "Contenido" could name the estante and never the position.
The right move was not better labels, it was one page.

Asserted as the opposite claim: **`C7` now measures that Estantes carries no view control of any kind**
(`.seg 0, .chip 0, radios 0, v-vista 0`), one search field, and 5/5 (13/13) estantes reachable on it.
R7b's chip work is not lost — its `--stroke` fix still carries 061's four filter chips at **4.3:1** light
and the tick at **11.27:1**, and C7's contrast/shape/hit-area assertions run there now. The one line of
CSS the retired instance owned (`#device main .chips.vista`) is gone from both stylesheets.

### 2. One collapsible list, and the estante carries the jobs the drill-down used to

Every estante is a `.grow.disclose` row with its count (round 5: *a disclosure row names its own block*,
so L1 holds without a heading above it). It opens **in place** to its games in **the shelf's own order**,
and while open it carries a `.gacts` strip — **Agregar juegos** (Secundaria) and **⋯ Opciones** — both
44px, the strip ending on the row's content edge at **381.5 vs 381.5**.

**`/admin/estantes/:id/asignar` is retired as a screen.** Everything it did is on this page:

| Asignar did | now |
|---|---|
| ubicar an unplaced game | an estante's **Agregar juegos** mode (bulk), and **Ubicar en…** from a Sin ubicar row (single) |
| "Buscar cualquier juego" | the page's one search field, which also answers *where is it* |
| the progress line + meter | unchanged, and it stays on screen while you work |
| "En este estante", collapsed | *is* the estante's own disclosure now — the double list is gone because there is only one list |
| **Renombrar** | a row in the estante's options sheet — it **keeps a sheet**, because that is the surface K3 measures against the soft keyboard |

### 3. A game row leads with its zone and expands to its neighbours

`Al medio · 2018` inside its estante; `Más a la izquierda · Estante D — expertos` in a search result.
The meta line carries the zone and **exactly one** other thing: whatever the context does not already
say. Measured over the 13 placed hits for "a":

| the search row's meta line | rows that wrapped | row heights | total |
|---|---|---|---|
| zona · estante · año | **6 of 13** | 60 / 70 / 73 / **89**px | 872px |
| **zona · estante** | **0** | 60 / 73px | **806px** |
| estante · zona · año | 6 of 13 | 60 / 70 / 73 / 89px | 872px |

So the año stays inside the estante (where the name is the heading) and goes from the search row (where
the name is the answer). The año's job — telling two editions of one game apart, round 3 — is not the
job a *where is it* row is being asked.

Inside a group **no row repeats the estante's name** (0 of 5 measured); in a search result **every hit
names it** (asserted across both shelf counts).

### 4. How the row expands: in place, not in a sheet

Both were built and driven. The sheet is this admin's established idiom for a row's options
(`v-mem-sheet`, `v-staff-sheet`, `v-niv-sheet`), so it had the prior:

| | **inline (won)** | sheet (lost) |
|---|---|---|
| taps to the answer | 1 | 1 |
| taps to read a **second** game | **1** | **2** — the backdrop blocks the page (`sheetBlocksPage: true`) |
| page cost | **78px** (the group 506 → 583px) | 0 page px, **238px of sheet** |
| covers what it is describing | no (`pageVisible: true`) | **yes** — a 38% scrim over the heading that names the estante |
| restated context | **none** | must restate the estante's name the heading says 60px above: *"Al medio de Estante B — estrategia. Antes de Dixit."* |
| `aria-expanded` nesting | one level, one expansion open at a time (measured: `v-game-exp:true` inside `v-toggle-grp:true`, `1 expansión`) | flat |
| legibility at 420px | the expansion starts on the row's own text column — **90.5 vs 90.5** — and carries no hairline, so the group still reads as one list | fine |

**What did *not* decide it, though the brief expected it to:** the nested accordion is perfectly legible
and the `aria-expanded` nesting is perfectly sane. What decided it was the **second** game and the
sheet's duplicated sentence. The loser stays renderable as `V.gx = 'sheet'`, the way `.seg` stayed as
061's rejected A2 — three lines, out of the default walk.

A consequence worth stating: the expansion carries **Ver en la ludoteca** and **Quitar del estante** as
Terciaria text buttons, which brushes against 062's winner-B rule *"secondary and destructive actions
open a bottom sheet"*. It is resolved, not ignored: the removal is **reversible with Deshacer** (062's
own rule for reversible changes), and it is *revealed by a disclosure* rather than sitting on the row —
so the row still carries exactly one affordance and every row stays under the D22 action cap.

### 5. How many zones — three, the same three at every shelf length

The fixture's estantes hold **65 / 59 / 42 / 162** games. So:

| | games a zone points at | vocabulary |
|---|---|---|
| **3 zones (won)** | 22 / 20 / 14 / **54** | Más a la izquierda · Al medio · Más a la derecha |
| 5 zones | 13 / 12 / 9 / **33** | Todo a la izquierda · Más a la izquierda · Al medio · Más a la derecha · Todo a la derecha |
| derived from the count (>100 → 5) | — | **[3, 3, 3, 5]** over the fixture's own shelves |

**Yes: "al medio" over a 162-box estante points at 54 boxes, and that is close to lying.** So the zone is
not sold as the answer. Its job is *which end of the shelf to walk to*; the box is named by the
neighbours, one tap and 78px away. Three zones pick the end. Five would pick the same end.

**The brief's implied test did not settle it.** Rendered in a real row with the longest game name, the
longest estante name and the año, **neither vocabulary wraps** — both the 3-zone and the 5-zone labels
come out on one 16px line. What settled it:

1. **Five zones reuse a phrase for a different stretch.** "Más a la izquierda" means 0–33% at three
   zones and 20–40% at five. One phrase, two meanings.
2. **Making the granularity depend on the shelf's length is strictly worse.** Measured: a >100 threshold
   over the fixture's own shelves gives `[3, 3, 3, 5]`, so the same three words mean *thirds* on three
   estantes and *fifths* on the fourth — **on one screen**. That is the two-parallel-vocabularies trap
   `card-interaction.md` warns about, and the rule rounds 5 and 7b both leaned on.
3. **The zone's marginal value over the neighbours is nil.** The neighbours cut 162 to 1.

Wording losers: *"Al principio | Al medio | Al final"* (order words where the developer's own words —
and what you actually see at a shelf — are izquierda/derecha); the 5-zone set above; *"El 27 de 59"* as
the collapsed line (precise and unusable — nobody counts 27 boxes; it survives only as the **fallback**
when neither adjacent slot is named).

`P6` asserts the derivation rather than a case: at shelf lengths **1, 2, 3, 5, 13, 37, 54, 65, 162** the
zone is monotone in the index, cuts within one slot of each third, and never leaves the three-word
vocabulary — bands `1:0/1/0 · 2:1/0/1 · 3:1/1/1 · 5:2/1/2 · 13:4/5/4 · 37:12/13/12 · 54:18/18/18 ·
65:22/21/22 · 162:54/54/54`.

### 6. Where "Agregar juegos" lives — a mode on the estante, not a sheet

The real job is 84 games sin ubicar. Both were measured:

| | **mode on the estante (won)** | a sheet off the header (lost) |
|---|---|---|
| rows visible at once | 5 | **8** — the sheet wins this one |
| row anatomy | the page's own: **73px row, 40px thumbnail** | `.dlink`: **48px, 28px slot, no thumbnail** — a second anatomy for the same list, against D5 |
| the progress line the job is measured by | on screen, meter and all | under a 38% scrim |
| paging 84 | `Mostrar más · 8 de 84 sin ubicar`, in the list | a modal at `max-height: 85%` |
| Deshacer per tap | on the page | `#snack` is `z-index` 70 over the sheet's 60, so it lands on top of the modal it belongs to |

The sheet's one win is bought with a second row anatomy and a dimmed counter. It is a **mode**, which is
also the grammar this admin already uses for Ordenar: `Agregar juegos → Listo`.

Placing has a position now, because a shelf has one: a box you carry over goes to the **far right end**,
which is the only honest default, and the snackbar says it — *"The Crew: La búsqueda del planeta X va al
final de Estante A — familiares"*. Measured: the estante grows by 1, Sin ubicar falls by 1, Σ 329 =
ubicados 329, badge 83 = 83, and the game reads its own new position back as **"Más a la derecha"**.

### 7. What leads the page

| order | search at | progress at | first estante at | page | estantes above the fold |
|---|---|---|---|---|---|
| **progreso · buscar · lista (won)** | 167 | 119 | 275 | 767px | 5/5 |
| buscar · progreso · lista | **119** | 163 | 275 | 740px | 5/5 |
| buscar · lista (no progress) | 119 | — | 227 | 740px | 5/5 |

**Measured, it barely matters** — every order costs the same taps and keeps every estante above the
fold; the difference is 48px. So it was settled on one measurement and one rule. The measurement: in the
search-first layout the meter is **343px wide — exactly the width of the search field — 28px below it**,
which is a 4px full-bleed bar sitting precisely where a text field's loading indicator would. The rule:
the progress line is *status*, not an action; the accent "84 sin ubicar" is what the tab badge sends you
here for.

What round 8 actually changed about what leads the page is not the progress line — it is that **the
search field is the page's first control**, where before it was the third (behind the chip row and the
Nuevo estante form) and absent from the landing view entirely.

### 8. "Nuevo estante" is a secondary action in a sheet

Measured: `tbtn b-sec`, 44px, `aria-haspopup="dialog"`, **0 forms in the page body**, and the control
sits at **619px, past the estantes at 275** — where round 7's form sat at **227px, above them**, pushing
the first estante to 368.

It follows round 7b's sheet-action rule exactly: a `.dlinks` commit row with `type="submit"` first,
"Cancelar" last with `chevL`, no button footer. Driven end to end (`P7`): an empty name gives *"Poné un
nombre."*, a duplicate gives *"Ya hay un estante con ese nombre."*, both keep the sheet open with focus
back on the field and **0 estantes created**; Enter and a tap on the row each commit **exactly once**;
and a brand-new estante starts with a real empty order (`[]`, Σ 328 = ubicados 328).

### 9. The list's label: "Estantes del club"

Measured at 420px against the 89.2px **Ordenar** button in a 343px row, **every candidate fits on one
line with ≥74px to spare** — so fit did not decide this either.

| candidate | width | verdict |
|---|---|---|
| **Estantes del club** | 109.4px | **picked** — round 5's move exactly ("Juegos del club" on the Juegos page): reuse the official word and qualify it |
| Orden de recorrido | 121.3px | the old label. It names the *order*, and the order is what the button beside it now does; the block's job is what is on each estante |
| Estantes | 55.4px | the page title verbatim — the exact thing R7b #8 killed on the chip |
| Recorrido | 62.6px | the retired chip's label: names a view, and there is one |
| Dónde está cada juego | 146.4px | names the job — but the job belongs to the search field 108px above it |
| Estantes y juegos sin ubicar | 179.3px | accurate only if Sin ubicar were inside the block |

That last loser did real work: it is what made **Sin ubicar its own block after the estantes** rather
than a fourteenth group inside a list called "Estantes del club". Sin ubicar is a queue of work, not a
shelf, and its rows ask for a shelf rather than disclosing a position. It is rendered as
`section.jsec.grp` — **one** element that is both the page block and the group, because L1 reads a
block's label off `:scope > .glist > .disclose` and a second wrapper would have hidden the name the row
already carries. (It did, at first. L1 caught it.)

### 10. Search answers in a row, not in thirteen headings

| one hit | round 7b | round 8 |
|---|---|---|
| 4 shelves | 987px = 1.33 screens, 5 headings kept | **740px = 1.00 screen**, 1 row |
| 12 shelves | **1467px = 1.98 screens, 13 headings** | **740px = 1.00 screen**, 1 row |

R7b's rule — *the filter never hides a group's heading (E5)* — existed because **the heading was the
only carrier of "which estante"**. The row carries it now, so the rule keeps its job and changes its
carrier. It is re-pointed, not deleted: C6 asserts that a query answers in a flat `Resultados` list with
**0 headings**, and that **every hit names its estante on the row itself**.

### Fixture honesty — the load-bearing part of this round

A zone and a pair of neighbours are only meaningful if the shelf's full ordered contents exist. So they
do. **A shelf is no longer a count with a bag of games in it: `V.order[shelfId]` is an ordered array of
slots**, each either one of the 36 games this sketch names or a slot that really exists on the shelf and
whose title the sketch does not render.

- **Σ of the array lengths IS `placedN()`**: 328 at 4 shelves and at 12, +84 sin ubicar = 412. And it
  stays true through an edit: remove → **327 = 327**, place → **329 = 329**.
- The named games sit in **one contiguous run per shelf**, at a per-shelf offset cycling start / middle
  / end: `5/65@0-4 · 5/59@27-31 · 5/42@37-41 · 5/162@0-4` at n = 4, and `2/22@0-1 … 1/55@54-54` at
  n = 12. That buys three things at once: every index — and therefore every zone — is real at any shelf
  length; every named game has a named neighbour or an honest end; and the fixture **exercises every
  shape of the answer**, `Antes · Después · Entre · Primero · Último` at 4 shelves and
  `Antes · Después · El · Primero · Último` at 12 (that last is the `El 7 de 13 del estante` fallback —
  a lone named game with two unnamed neighbours).
- **No row claims a neighbour it does not have.** `nbrLine()` says *"Entre X y Y"* only when both
  adjacent slots are named, and otherwise *"Después de X"*, *"Antes de Y"*, *"Primero del estante"*,
  *"Último del estante"* or the index fallback. `P10` checks all 20 lines at each shelf count: **0
  dishonest**.
- **One artefact, stated rather than hidden:** ↑/↓ swaps the *slots*, so a box at the edge of a run can
  be pushed past a slot whose title this sketch does not render. The visible list does not change while
  the row's zone and neighbour line do — so the row flashes. In production every slot is a named game
  and this cannot happen; the arrows are therefore disabled at the **array's** ends, not at the last
  named row, which is what `P4` asserts (`slots 27,28,29,30,31 of 59`, none disabled).

### Two bugs the measurement found and the eye could not

1. **A status dot that was 0px wide.** Putting "Sin ubicar" inside a `.mi` (so the separator logic would
   give it its "·") turned `.dot` from a flex item of `.gsub` into an **inline non-replaced box**, where
   `width` and `height` do not apply. It declared 7×7px and measured **0×15**. `inline-block` restores
   it; `P9` asserts every meta-line dot is drawn at its declared size in both themes (`7×7`) and keeps a
   5px gap off its word.
2. **R7b shipped an 8px misalignment.** `#device main .grp .gnote` was set at **76px**, which is the
   *unpolished* row hairline — every row on this page is `.polish`, whose hairline and name column start
   at **68**. Measured: the note sat at 98.5 against the row name's 90.5. It is 90.5 vs 90.5 now.

### How each of the retired screen's assertions was re-based

**Nothing was weakened to make it pass.** Where a rule lost its *subject* it is said so and re-pointed
at the surface that inherited the job.

| rule | had | now |
|---|---|---|
| the walk's 8th stop | `8-asignar` | **`8-estante-abierto`** — every geometry rule the walk carries is still measured where the work happens |
| "the lit tab follows the page into its drill-downs" | editor→Juegos, sección→Web, **Asignar→Estantes** | the first two. The third's subject is now *on* the Estantes page, so the lit tab cannot drift — the walk still asserts Estantes lit at stop 8, and C7/P1 assert the stronger claim that the page has no view control, one search, and every estante reachable on it |
| **D1** back rows at one height | 3 drill-downs | 2. The rule lost a subject, not an assertion |
| **D2 / D3** titles and head gap | 10 stops | 10 stops, with the expanded estante in place of Asignar |
| **L1** every list block names itself | Asignar's "Sin ubicar" label + "En este estante" disclosure | "Estantes del club" (lhead) + "Sin ubicar" (its own disclosure row) |
| **R6** one sheet shell | 10 sheets | **13** — `renombrar` re-pointed at the estante's options sheet, plus `opciones-estante`, `ubicar`, `nuevo-estante` |
| **C5** typing never rebuilds the field | 3 searches | 2 — `asg-q` went with the screen and `lista-q` inherited its job |
| **C6** the grouped view scales | `?vista=lista` | the page itself; its E5 sub-rule re-pointed from "keeps every heading" to "every hit names its estante on the row" |
| **C7** the view control's state ≥3:1 | the `.chips.vista` instance + 061's filters | 061's filters — plus the opposite claim asserted on Estantes: no view control of any kind |
| **C8** a sheet's actions are rows | 10 sheets | all of them, plus `P7` driving the admin's second form-in-a-sheet end to end |
| **D6** counters agree after an edit | driven on Asignar | driven in the estante's "Agregar juegos" mode |
| **K1** no field under 16px on touch | visited `asignar` | visits the expanded estante **and both sheets that own a field** |
| **K3** a sheet sits on the soft keyboard | Asignar → Renombrar | the estante's options → Renombrar **and** Nuevo estante — **two subjects where there was one** |
| 064's `audit-admin.js` screens | `asignar`, `rename-sheet` via asignar | `estante-abierto`, `estante-agregando`, `estante-ordenando`, `rename-sheet` via the options sheet, `nuevo-estante-sheet` |

One more thing the re-basing exposed: the walk's 260ms wait was measuring **mid-swap** — `softSwap`
holds the old body for 230ms, and the stops were reporting the *previous* page's tab and title. It is
420ms now. (The same class of artefact R7b hit when `quitar` needed 1000ms.)

### What was deliberately not done

- **Variant A's Estantes is now variant B's page.** A's grammar — three always-visible icons per row —
  cannot carry a row that also has to disclose its position, and A lost three rounds ago. Said here
  rather than silently dropped; both variants still render with no errors.
- **The sheet variant of the row expansion stays in the code** (`V.gx = 'sheet'`) as the recorded loser.
- **The zone is nearly constant down an expanded estante** — 5 of 5 rows read "Al medio" on Estante B,
  and in production 8 consecutive boxes really would. Measured and left alone: inside a group the zone
  labels the *window* you are looking at, and its real consumer is the search result, where every row
  comes from a different shelf at a different position.
- **Reordering the estantes themselves** (the walking order) kept its `lhead` + Ordenar, so C4 keeps its
  Estantes subject and the room's own order is still editable.
- **"N jug." did not come back**, and `.lcap` / `.saverow` stayed dead.

Asserted by `verify.js`, both themes at 420px and the walk again at 1440px: **P1** the search is the
page's first control, the list names itself, and Nuevo estante is a 44px Secundaria opening a dialog with
no form left in the page body; **P2** an open estante lists its games in the shelf's own order, offers
what it cannot show, and carries the two jobs the retired screen owned on a 44px strip ending on the
content edge; **P3** remove works from that list, the slot closes up, every counter agrees and Deshacer
restores the exact order; **P4** ↑ moves a game one physical slot and nothing else moves, the arrows stop
at the shelf's real ends, and the hint says the box moves too; **P5** every row leads with its zone,
expanding reveals the neighbours on the row's own text column with `aria-expanded` one level deep and one
expansion open at a time, and the estante's name is on a search row and never repeated inside a group;
**P6** the zone derivation holds at nine shelf lengths; **P7** Nuevo estante validates inline without
closing and commits from the keyboard exactly once; **P8** everything Asignar did is reachable here, with
the progress line and the page's own row anatomy intact; **P9** a status dot on a meta line is really
drawn; **P10** Σ of the shelves' order arrays is the placed count at 4 and 12 shelves, every order is
materialised in one contiguous run, and no row claims a neighbour it does not have; **P11** the Asignar
screen is retired rather than hidden, and nothing of it is left behind.

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
`verify.js` — 468 checks in headless Chrome, phone (420px) light and dark, then desktop at 1440px.

- **the walk** (10 stops): no horizontal overflow, every page opens at the top, at most one tab lit,
  and the lit tab follows the page into its drill-downs (editor → Juegos, sección → Web). Round 8's
  stop 8 is an **expanded estante** rather than the retired Asignar screen, which is the point: the
  work happens on the page, so the tab cannot drift;
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
- **C1–C5** one component per job (round 7): the Ajustes panel, the one save bar, the reorder toggle's
  affordance, and the targeted search refresh that stops the field blinking;
- **C6–C8** one component per job, continued (round 7b, re-based by round 8): the collapsed-estante
  list that scales (measured at 4 shelves and at 12) and now answers a query in one row instead of
  thirteen headings; the chip row's state at ≥3:1 in both themes on the admin's 8px — measured on 061's
  filters, since Estantes has no view control at all any more, which is itself asserted; and one
  sheet-action pattern — rows, never a button footer — across all **thirteen** sheets in the walk;
- **P1–P11** one Estantes page (round 8): the search leads, every estante opens in place to its games
  in the shelf's own **physical order**, remove and ↑/↓ sort are driven from that list with the whole
  ledger following, a row states its zone and expands to its neighbours, the zone derivation holds at
  nine shelf lengths, "Nuevo estante" is a sheet that validates inline and commits from the keyboard,
  every job of the retired Asignar screen is reachable here, and the fixture is real enough for a
  position to mean something (Σ of the shelves' order arrays = the placed count, one contiguous run per
  shelf, no row claiming a neighbour it does not have);
- **S1–S4** status marks the exception (round 3).

063's `verify.js` (63/63) and 064's `audit-admin.js` (106/106 — round 8 re-pointed its two Asignar
screens at the expanded estante and added its three new surfaces) still pass with every upstream fix in.

## Round 9 — the estante as a rail: the idea does not survive 162 boxes (2026-09-16)

Developer: *"what if we use carousel(horizontal scrolable) to represent that physical position, maybe
been inspired by Apple iBooks?"*

This answers round 8's own open item. R8 made a row lead with a **zone word** derived from its index in
the shelf's physical order, and the complaint raised against it was that **inside an expanded estante
the word is identical on every row** — five consecutive rows measured reading *"Más a la izquierda"* —
because the list order already carries the position and the word only restates it. The developer's
answer: stop *telling* the position and *show* it.

**Three variants, all three still in the file behind `V.est` (⚙ tools → *Estantes (R9)*):**

- **A — the round-8 list (control).** Vertical rows, neighbours on expand.
- **B — the rail as the shelf.** An open estante's games *are* the app's own horizontal rail;
  left-to-right on screen is left-to-right on the wood. No vertical list, no zone words, no
  *Mostrar más*. A marked tile opens a panel with the row's two jobs.
- **C — rail as map, list as work surface.** The rail shrinks to the list's own 44px slot (one row's
  worth of height) and sits above the vertical list, which keeps remove / sort / add.

**It is the app's own carousel, not a second one.** The CSS block *"065 R9: the estante as a RAIL"* is
appended to 062's `<style>` and 063's, byte-identical, and `065/build.js` throws if they drift — plus a
guard the other shared blocks do not need: the four numbers `carousel_row.ex`'s moduledoc calls a
**co-dependent measurement set** are checked against `assets/css/app.css` itself. Card **96px**, rail
gap **10px**, edge fade **16px** are production's ≤480px values verbatim; if production retunes them the
build fails instead of letting this sketch describe a rail the app no longer has. 022-C (arrows
pointer-fine only, *removed from layout* on touch), 023-B (no snap, `scroll-behavior: auto`, the
eased arrow scroller on --ease-standard's 0.4/0/0.2/1 twin) and 025-B (nothing repopulates here, so
nothing shimmers) all came across with it.

### What it cost and what it bought — Estante D, 162 boxes, 420px

| | A — list | B — rail | C — rail + list |
|---|---|---|---|
| open estante | **493px** | **317px** | **553px** |
| page with it open | 1075px | 899px | 1135px |
| the rail itself | — | 154px | 60px (one row) |
| boxes on screen at once | 5 rows (pages 8 at a time) | 3 whole tiles + 41px of peek | 5 rows + 6 squares |
| **to a box in the middle of 162** | *Mostrar más* ×10 + ~4 900px of vertical scroll | **27 arrow presses** · **8–15 flings** · 8 463px | rail 13 presses (derived); list as A |
| search → that box's position | **2 taps**, 78px | 2 taps, **214px** | 2 taps, 214px |
| what the collapsed search row says | `Al medio · Estante B — estrategia` | `Estante B — estrategia` | `Estante B — estrategia` |
| tab stops inside the open estante | 9 | 6 | 12 |
| 024 position states | n/a — the order *is* the position | **3** over 162 | 3 |

**The number that decided it is 3.** 024-A's edge-fade is two booleans — is there content left of the
left fade, is there content right of the right one — so over a 162-box estante it can tell apart
**three** positions, and **39 of the 41 offsets sampled across the whole 16 819px scroll range are the
same single state**. The rail can *be* the answer; it cannot *find* it. 27 arrow presses of 318.8px
(3.01 boxes each) on a pointer, and 8–15 flings on a phone where 022-C leaves no arrows at all (a fling
is whatever velocity the thumb gave it — 8 of ~1 340px and 15 of ~592px both measured).
Search is 2 taps to any named game in every variant — so the rail is never what gets you there, only a
way of drawing the answer something else already found.

**And on its best flow it is still beaten.** The brief singled out the flow that answers both halves of
the question at once, and it was built and driven: search *"dixit"* → tap the row → the estante's rail
opens **already scrolled to Dixit and marked**, with **Brass: Birmingham and Twilight Imperium to its
left and Root and Splendor to its right**, centred, no words. It works, it reads well, and it costs
**214px against A's 78px for the same answer at the same 2 taps** — where A's answer, *"Entre Brass:
Birmingham y Root"*, is the more precise of the two. Worse, B's **collapsed** row had to give up the
zone to make the rail the position channel, so before you tap you know *less* than in A.

**One extra estante costs 60px in every variant** — a shut estante is its disclosure row and nothing
else, so the rail changes nothing about what the page costs per estante, only what an *open* one costs.
At twelve estantes the page is the same eleven 60px rows plus whichever open estante you are looking at.

**C loses harder than B.** It has the rail's cost (+60px over A, 553px vs 493) and none of its one
saving, its 44px squares name nothing (see `r9-C-shelfD.png`: five colour chips and a hatched band),
and reaching the middle through the map is still 13 presses (arithmetic, not a driven run: a 52px pitch × 81 boxes = 4 212px at 318.8px a press). A map that neither labels nor navigates is
a strip of decoration above a list that was already doing the work.

### The 024 verdict: HELD, unchanged, and no exception is needed

024 ruled a rail carries **no** position or pagination indicator — edge-fade only, matching Netflix.
Nothing was added here: **0 indicator elements and 0 per-tile ordinals on either rail variant**,
asserted in both themes at 420px and 1440px, because quietly adding one is exactly the drift this
sketch series exists to catch.

No exception is argued, for a simple reason: **no rail ships.** But the condition is worth writing down,
because the measurement that would have forced an exception is the same one that killed the rail. 024's
own README states its premise — *"this app's shelves are shorter (8-10 cards, per `SHELVES` in 001),
where 'how far through this row am I' is a more answerable question"* — a rail you can reach either end
of in one or two flings. At 162 boxes that premise is simply false, and the fade degenerates from
*where am I* to *can I scroll*. **So if a rail is ever wanted in this admin, 024 holds unchanged up to
roughly the length you can fling end-to-end (~30 boxes at this card width), and past that it needs a
scoped admin exception — not a progress bar, which would be 1px of fill per 2 boxes, but a scrubber
with a grab handle, which is what Apple itself reaches for once a library stops fitting a shelf.** That
is a different sketch, and it should be asked for by a job, not by this one.

### Does the rail make the zone words redundant? No — but the census does

The developer's actual question, answered by counting rather than by the rail. **Inside an open estante,
every rendered row of every estante derived the identical zone word: 4 estantes, 20 rows, 20 words, one
distinct word per estante.** That is partly the fixture's doing (R8 put each shelf's named games in one
contiguous run so every index would be real), so the arithmetic was computed too: a page is 8
consecutive boxes and a zone is a third of the shelf, so the word can only change across a page when
the page straddles a boundary — **14 of 58 start positions on the 65-box estante, 14 of 155 on the
162-box one. One word covers every row of 60% of pages on the club's smallest estante (42 boxes) and
91% on its biggest**, i.e. more so the longer the shelf, which is the opposite of what a label wants to do.

So **the zone is dropped inside an expanded estante and kept in a search result**, where thirteen
results come from thirteen estantes in relevance order, there is no order to read, and it is the only
thing that says which end to walk to — keeping the first slot the developer asked for. The row inside a
group now carries exactly its año, which is the slot R8 had already reserved for it. **This is the
round's substantive change and it lands in A, the winner — the rail did not earn it, the census did.**
`P5`'s *"every row leads with its physical zone"* is re-pointed rather than deleted: inside a group it
now asserts that **no** row restates the order, and the zone is asserted where it still has a job.

**The words do not go away for a screen reader, either — they become the only channel left.** A rail's
whole claim is that the eye reads position off the geometry, and AT has no geometry to read, so every
tile's accessible name has to say it: *"Dixit, caja 29 de 59"*. Measured and asserted. A rail does not
remove the words; it removes them from the people who can see.

### WCAG, keyboard and gesture — measured on all three

| Check | Result |
|---|---|
| **1.4.10 reflow** | The page never gains a second axis: `overflowX 0` on A, B and C, both themes, 420px and 1440px. A rail is a *scoped* horizontal scroller inside the page's vertical one — the exception 1.4.10 allows, and what the catalogue already ships. |
| **1.4.11 non-text contrast** | The marked cover's ring is 064's `--stroke`: **4.3:1 light / 3.49:1 dark**. The obvious `--color-primary` ring measures **14.16:1 light / 2.33:1 dark** — **under 3:1**, the exact shape of the failure round 7 caught in a control that looked fine. So the mark is R7b's chip answer instead: four channels — stroke, a ✓ badge at 11.27:1 / 10.54:1, the accent fill behind the label, and 400→600 weight. |
| **2.1.1 / 2.4.3 keyboard** | A vertical list is keyboard-trivial; a rail is not. Without help, one focusable card per game is **up to 162 tab stops** between an estante and whatever follows it. A roving tabindex fixes that — **1 tab stop per rail**, with ← → Inicio Fin moving inside it and the rail scrolling to follow focus — and it is ~20 lines the list got for free. It fixes the *stops* and not the *traversal*: reaching the middle of 162 by keyboard is still **81 ArrowRight presses** from the first box, against 10 taps of *Mostrar más*. |
| **touch targets** | A tile is **96×138** and the ordering ← / → are **44×44** (*"Mover Catan a la izquierda"*, correctly disabled at slot 0), all over the admin's 44px floor. 022-C's other half holds: on a touch pointer the arrows measure **0px with `display: none` and are out of the tab order** — no dead tap target over the swipe area. |
| **gesture conflict** | **None, in either direction.** Driven through CDP's real input pipeline (`touchStart` / `touchMove`× / `touchEnd`), starting on a tile: horizontal → rail **Δ319px**, page **Δ0**; vertical → page **Δ284px**, rail **Δ0**; a sloppy mostly-vertical thumb → page Δ284, rail Δ0; mostly-horizontal → rail Δ323, page Δ0. With a bottom sheet open the rail underneath is inert (Δ0 / Δ0) like every other surface. This is what production's `touch-action: manipulation` buys over a single-axis `pan-x`, and it is the rail's cleanest result. |

### Fixture honesty at rail density

A shelf is an ordered array of slots (R8) and only 36 of the 412 games are named here, so most slots
are real boxes this sketch cannot title. A list showed 8 at a time and the gap never surfaced; a rail
shows many at once, so this is the round where it would have. **No cover may imply a game that does not
exist**, so a run of unnamed slots is not drawn as covers at all: it collapses into **one hatched band
whose width is the run's real length × the tile pitch**, carrying a sticky caption that says exactly
what it is (*"157 cajas sin título en este boceto"*) and stays on screen while you scroll the stretch it
describes.

Every slot is accounted for and the geometry stays the shelf's own, so every distance measured above is
true: **5 tiles + 60 = 65 · 5 + 54 = 59 (two bands of 27, the named run being mid-shelf) · 5 + 37 = 42 ·
5 + 157 = 162**, with `scrollWidth` equal to the shelf's real width on all four (6 912 / 6 276 / 4 474 /
**17 194**px), **0 invented covers** and **0 tiles off their true x**. One artefact stated rather than
hidden: keyboard **Fin** lands on the last *tile*, not the last *slot*, because a band is not focusable
— in production every slot is a tile and Fin is slot 162.

### The co-dependent set, and the one number that changed

Card 96 · gap 10 · fade 16 came across verbatim. The **gutter** is the one that differs: the
catalogue's `--pk-gutter` is 14px at ≤480px and this page's is 16px. Consequence, measured rather than
waved through: at the 375px device the 4th tile shows **41px**, of which 16 sit under the fade, leaving
**25px of clear peek** where production would leave 27. The set survives the swap with 2px less peek,
and it is asserted, because a fade wider than the peek swallows the cue it exists to create.

### Winner: **A**, and the rail is recorded rather than shipped

**A — the round-8 list**, with the zone word dropped inside an expanded estante and kept in search
results. B and C stay in `062/index.html` behind `V.est` so the idea is walkable and its numbers
re-measurable; neither is deleted, because "the rail loses at 162" is a finding about *length*, not
about rails.

**What the rail won outright, and did not win enough with:**
- **← / → is physically honest where ↑ / ↓ is not.** R8's arrows point a way no shelf has, and it said
  so ("Movés la caja de verdad"). The rail's arrows point the way the box actually moves. This is real,
  it is the rail's one clean victory, and it is not worth 27 presses to the middle — but a vertical list
  could borrow half of it by making the *labels* physical ("Mover Catan a la izquierda en el estante")
  while the glyph keeps naming the list move. Left as an open item rather than half-changed now: a
  glyph and a label that point different ways is its own problem for AT.
- **The physics are safe.** No gesture conflict was measurable in either direction, so a rail over a
  *short* admin list (a sección's 20-game cap, say) would not fight the page.
- **It is cheaper than the list it replaces** — 317px against 493 — which is the honest shape of the
  finding: the rail is a good *display* of a shelf and a bad *navigator* of one, and Estantes is a page
  whose entire job is navigation.

Checked by `065/verify.js` **X1–X10** (both themes at 420px, then again at 1440px, plus a real-touch
context for 022-C and the gesture pass), with **P5 re-pointed** rather than deleted, and still green in
`063/verify.js` and `064/audit-admin.js`.

## Round 10 — the developer overrides the rail's verdict, and the admin gets one action system (2026-09-16)

Two jobs, and the first one is a **developer override of a measured verdict**. Recorded here the way
round 6's reversal was (*"verify.js used to ban the word 'copia' — reversed by the developer"*):
**round 9's numbers below are the ones round 9 measured, unedited.** Nothing in that section has been
softened to make the rail look like it won, and the numbers it charged against the rail are now
written down as problems this page owns.

Developer: *"For estantes, I want option B(riel). remove the another variants."*

### Job 1 — B ships, A and C are deleted, and the rail's navigation problem is solved

**What round 9 measured, unchanged:** over Estante D's 162 boxes at 420px, an open estante cost
**A 493px · B 317px · C 553px**; reaching the middle was **27 arrow presses** on a pointer and **8–15
flings** on a phone, where 022-C leaves no arrows at all; 024-A's edge-fade distinguishes **3
positions** and **39 of 41** sampled offsets are the same single state; search is **2 taps** to any
named game in every variant; and B's own weak point was its collapsed row, which had dropped the zone
word so that *before you tapped you knew less than in A*. Round 9's winner was **A**.

A and C are gone from `062/index.html` — no `V.est`, no `.map` recipe, no `data-est` switch — and
`build.js` now **throws** on a trace of any of the three, so "deleted" is a build condition and not a
claim. Deleting the losers is this series' own practice (022–025 each record "A/C removed from
index.html").

#### The zone bar: the three zone words, promoted from description to navigation

R9 deferred this as *"a different sketch … it should be asked for by a job, not by this one"*. The
override is that job. The candidate the brief named turned out to be the right one, and the reason is
the measurement that killed the rail: **024's fade can tell three positions apart and reach none of
them.** So the three words become the three destinations.

| | measured |
|---|---|
| arrows alone, to the middle of 162 | **27 presses** · 8 357px at 318.8px (3.01 cajas) each |
| **the zone bar, to the middle** | **1 tap** — *Medio* lands on **caja 81 de 162**, 0 of error |
| the worst box on the shelf | **1 tap + 14 presses = 15**, at caja 41 (three anchors leave 41-box gaps) |
| an open Estante D | **369px** (rail 154 + bar 52), against R9's A 493 · B 317 · C 553 |
| the page with it open | **1 064px**, against R9's A 1 075 |
| boxes on screen at once | 3 whole tiles + 25px of clear peek |
| tab stops inside an open estante | **9** (rail 1 + bar 3 + foot 2 + 022-C's two arrows) — R9: A 9, C 12 |

It is **the admin's own "pick one of N" control, not a fourth component**: R7b ruled that job belongs
to the chip row (a segmented track failed 1.4.11 at 1.16:1), and this is that markup with the chip's
own state channels — the accent fill, the accent label, 600 weight and R7b's `--stroke` boundary at
**4.3:1** — plus `aria-current`. **No tick glyph**, and that is measured rather than aesthetic: the
current zone changes on every frame of a fling, and a glyph appearing and disappearing would shift the
labels under your thumb. One thing it does not inherit: 061's filter chip is a 32px pill whose
`::after` bleeds its target to 44px; a zone jump is a target you hit one-handed standing at a real
shelf, so it is a **real 44px box** and the `::after` is pulled back so it cannot bleed into the rail.

The labels are the short navigational form (**Izquierda · Medio · Derecha**) and each one's accessible
name is the developer's own phrase in full: *"Ir a más a la izquierda de Estante D — expertos"*. That
is what "no new vocabulary" means literally.

#### The 024 exception, argued and scoped

024 ruled a rail carries **no** position or pagination indicator — edge-fade only, matching Netflix.
Here is the exception, in the shape R9 said it would have to take.

- **024's premise is false at this length.** Its own README states it: *"this app's shelves are shorter
  (8-10 cards, per `SHELVES` in 001), where 'how far through this row am I' is a more answerable
  question"* — a rail you can reach either end of in one or two flings. At 162 boxes the fade
  degenerates from *where am I* to *can I scroll*: **3 states, 39 of 41 offsets identical**.
- **The exception is scoped to LENGTH, not granted to the admin by fiat.** `ZONE_NAV_MIN = 30`, derived
  from R9's own fling measurement (~592–1340px over a 343px rail ⇒ 5–12 boxes a fling, 10–25 in two).
  Under it the bar does not render at all and 024 is untouched — which is **every rail the catalogue
  ships**. Asserted on the 12-shelf fixture, where the 20/22/14-box estantes get no bar and the 54-box
  ones do.
- **The rail itself is untouched.** 0 indicator elements inside it, 0 per-tile ordinals, both themes,
  420px and 1440px. The bar is a **sibling above** it with three states, not 162.
- **What would generalise it back:** a rail short enough to fling end to end needs none of this. If the
  catalogue ever grows a shelf past ~30 cards, this is the control to reach for — and still three words
  rather than a progress bar, which at this length is 1px of fill per 2 boxes.

#### The scrubber: built, driven, and the round's own hypothesis was wrong

R9 wrote that past the fling length a rail *"needs a scrubber with a grab handle, which is what Apple
itself reaches for once a library stops fitting a shelf"*, and the brief asked for the zone words to be
measured against one. It was built against the real geometry and driven. **The guess going in was that
three jump targets would beat it outright. They do not.**

| | zone bar | scrubber |
|---|---|---|
| to the middle of 162 | **1 tap** | 1 drag |
| to an arbitrary box, worst case | 1 tap + 14 presses = **15** | 1 drag landing within ±14 + 5 presses = **6** |
| resolution of one gesture | 3 anchors, 41-box gaps | 1.66px per box · a 44px fingertip covers 27 boxes |
| what it draws | 3 × 44px targets | a handle **inflated 5.9×** — 44px drawn for the 7.5px it stands for |
| for a screen reader | 3 named destinations | `role="slider"`, 162 values |
| gesture | a tap | a **drag** inside a horizontal scroller inside a vertical page |
| vocabulary | none new — the census had just retired these three words from describing | a new component and a new idiom |

**The scrubber is finer, and it is still not what ships.** Both reach the middle in one gesture, which
was the named problem; on an arbitrary *unnamed* box the scrubber wins by 9 gestures, and that is the
job search already does in **2 taps**. Against that it costs a position indicator that lies about the
viewport it represents, the one gesture conflict X7 measures as absent, 162 AT values instead of 3, and
a component the admin does not have. Asserted in the direction that is true (`X4`), so a later round
has to move a number rather than re-argue a taste.

#### Keeping the zone on a search-result row — the combination, measured

R9's finding was that B's collapsed row told you *less*. The shipped page keeps both halves and the
zone word now has exactly **two jobs and no third**:

- **a search-result row: `zona · estante`** — *"Al medio · Estante B — estrategia"*. Thirteen results
  from thirteen estantes in relevance order; there is no order to read, and the zone is the only thing
  that says which end to walk to. It keeps the first slot the developer asked for.
- **inside an expanded estante: the three jump targets** — and **0 words**, on all four estantes, over
  every rendered tile. R9's census is why: a page of 8 consecutive boxes straddles a third-boundary in
  only 14 of 58 start positions on a 65-box shelf and 14 of 155 on a 162-box one, so **one word covered
  every row of 60% of pages on the club's smallest estante and 91% on its biggest**.

The flow: search *"dixit"* → tap the row → the estante's rail opens **already scrolled to Dixit and
marked**, Brass: Birmingham and a 27-box band to its left, Root and Splendor to its right, centred, in
**214px**. The words are the coarse answer and the picture is the precise one, at the same 2 taps.
**No zone bar inside a search expansion**, and that is the rule rather than an omission: the bar
belongs to *browsing* a shelf, and this rail is already on the answer.

#### Accessibility, now load-bearing rather than hypothetical

R9's sharpest finding was that a rail does not remove the position words, it removes them *from the
people who can see* — so with the rail shipped, every part of it is asserted:

| | measured |
|---|---|
| every tile's accessible name | *"Brass: Birmingham, caja 28 de 59"* — the real box number, on every tile |
| the rail's own group name | *"Estante B — estrategia, de izquierda a derecha"* |
| roving tabindex | **1 tab stop** for the rail (of 5 tiles; one per game would be up to 162) |
| the zone bar | **3 real 44px stops**, the full phrase as each accessible name, exactly 1 `aria-current` |
| the marked cover's ring | 064's `--stroke`, **4.3:1 light / 3.49:1 dark**; `--color-primary` measures **2.33:1 in dark** and is not used |
| the mark's channels | ring + ✓ badge at 11.27:1 + accent fill + 400→600, like R7b's chip |
| 022-C on touch | arrows `display: none`, **0px**, out of the tab order |
| gesture conflict | none either way (`touchStart`/`touchMove`×/`touchEnd`): horizontal → rail Δ319 / page Δ0; vertical → page Δ284 / rail Δ0 |
| 1.4.10 reflow | `overflowX 0` shut, open and with a box marked, both themes, 420px and 1440px |

#### Fixture honesty, unchanged

**5 tiles + 60 = 65 · 5 + 54 = 59 · 5 + 37 = 42 · 5 + 157 = 162**, `scrollWidth` 6 912 / 6 276 /
4 474 / 17 194px, **0 invented covers, 0 tiles off their true x**. An unnamed run is still one hatched
band of its real length with its sticky caption.

#### What promoting the rail broke, and the eye would not have caught

**W1 failed the first round the rail actually shipped.** A tile's cover is a placeholder letter at
**28px/600**, and the page title *"Estantes"* is **22px/600** — so five placeholders at once outweighed
the title on a page whose title is supposed to lead. W1 has been the rule since round 2 and it outranks
a stand-in: the letter is capped at **21px**. In production every tile is an `<img>` and carries no
type at all. No exemption was added.

#### Every round-9 and round-8 assertion that was re-pointed

Nothing was deleted. Where a rule lost its carrier it changed carrier; where it lost its subject it was
re-aimed at the stronger claim the rail is making.

| assertion | was | now |
|---|---|---|
| `P1` (cont.) | Nuevo estante is **Secundaria** in a sheet | it is **Terciaria text** — Job 2's rule 2 |
| `P2` ×2 | an open estante **lists rows** in shelf order; its caption is honest | the **tiles** are in shelf order; a rail shows the whole shelf, so there is nothing left to page |
| `P5` ×8 | the row's zone, its expansion on the row's 68px text column, its actions | 0 words inside, the tile's `caja N de M`, the panel's two jobs, one mark at a time, the search expansion centred and marked, and the **inversion**: a rail is full-bleed, so the expansion reaches *out* to the page edge (22.5 = 22.5 against the text column at 90.5) |
| `P3` | remove from a row's expansion | remove from a **marked tile's panel** — same ledger, same undo |
| `P4` ×5 | ↑ / ↓ on a row; arrows disabled at the array's ends | ← / → in the panel, **the glyph and the label finally point the same way** (R9's one clean victory, closed), the mark follows the box, and the ends are walked on three shelves (run at start / middle / end) |
| `C6` ×2 (+1 new) | every estante opens to real **rows**; what is not shown is offered | opens to real **slots**; a rail has nothing to page — plus a new one: **the bar is earned by length** |
| `C7` | Estantes has no view control | still 0 on the page — the bar lives inside an *open* estante and changes nothing the page shows |
| `X1` ×2 | three variants render | one page ships, and A/C are gone (build-enforced) |
| `X2` ×2 (+1 new) | 024 holds, **and that is why the rail loses** | 024 holds **on the rail**, and the fade's three states are the exception's justification; the bar is a sibling with three states |
| `X3` ×2 | A vs B vs C heights | the shipped 369px against R9's recorded 493 |
| `X4` ×2 (+2 new) | 27 presses = the case against the rail | 27 presses = the **baseline the bar is measured against**; the bar is 1 tap; the worst box is 15; the scrubber is finer and still not chosen |
| `X6` ×2 (+2 new) | tab stops A vs B vs C | the shipped page's 9, plus the bar's three stops and its state channels |
| `X9` ×2 (+1 new) | the zone is dropped inside, kept in search | the same census, plus **the word's second job** |
| `X10` ×3 | the flow works **and still loses** | the flow works and **keeps the half B had dropped** |
| `X2` (cont.) reflow | three variants at 420px | shut / open / marked, which is the tallest the surface gets |
| `X5`, `X7`, `X8` | — | untouched |
| `W1` | — | **not** re-pointed: it caught a real failure and the page was fixed |

### Job 2 — one action system for the whole admin

Developer: *"Then I want to work on ACtions, like (ordernar, Agregar juegos, etc). Those too big and
kill balance. and also, there are 'text actions' like 'Ver en la ludoteca' and 'Quitar del estante'. We
need a consistent way to represent actions everywhere with its corresponding hierachy and correct
balance to fix the currently broken rythm."*

064 wrote down the **paint** of a role and nothing about the **shape** a role takes in which place, so
each place invented one. The census: **113 visible action controls across 25 admin surfaces, 25
context × role pairs**. The rule this round lands is one sentence:

> **THE CONTEXT PICKS THE ANATOMY; THE ROLE PICKS THE PAINT.**

The matrix lives in **064's README** (it belongs with the role matrix it extends) and in the
`065 R10` CSS block. What is recorded here is what the census found and what it cost.

#### Seven things the census found, and not one of them was visible to an existing check

1. **`.pacts` applied the borderless −12px pull to an OUTLINED Secundaria**, so "Nuevo estante" hung
   its 1px stroke **12px past the page's left content edge**. 064's audit measured only the right edge.
2. **The estante's options `.ibtn` sat at inset 0** while every row arrow directly above it sat at −12
   — two identical 18px glyphs **12px out of line down one column**.
3. **"The space between two text actions" had four answers**: **4px** in `.gxacts`, **8px** in
   `.eactions` and `.banner-actions`, **0** inside a save bar with no outline. Round 6 #5 had settled
   this once ("a borderless text button's own padding IS the rhythm") and it had only ever been applied
   where round 6 happened to look. This is the "broken rhythm" the complaint names.
4. **`.banner.err .banner-actions { margin: 0 }` cancelled the strip's pull**, so 063's lone
   "Reintentar" had its label 12px inside the banner's content edge while 061's "Cancelar", in the same
   class, sat on it. Found by the new check, not by eye.
5. **Two settings panels declared 40px for rows that open a sheet** — R7's `.sgroup.apanel` ("Orden ·
   A mano") and the editor's `.r6 .sbox.rows` ("Estante · Sin ubicar"). **6 tap targets under the 44px
   floor** in the walk, and nothing had ever looked: 064's audit only measured buttons.
6. **`.ebar .obtn { margin-left: 4px }`** gave the outlined last action of a save bar two different
   left margins depending on whether it was `.obtn` or `.b-pri` — one role, two anatomies, in one bar.
7. **The editor's back row held two anatomies for one context × role**: `‹ Juegos` (4/10px padding,
   −10px pull, leading chevron) beside "Ver en la ludoteca" (12/12, −12px). Resolved by **naming the
   back control its own role**: it is page chrome, it is identical on every drill-down, and D1 has been
   asserting that since round 1. Naming it is what lets both be right.

#### Two things that looked like findings and were not

- **061's 32px filter chip is a legal 44px target.** Its `::after` bleeds ±6px, so the drawn box is 32
  and the tap target is 44 — the first census read the drawn box and would have recorded a false floor
  violation. The same harness-trap shape as round 1's srgb contrast parser, and it is why the new floor
  check measures the **hit box**. (The 065 probe hit it too: `getComputedStyle` takes the
  pseudo-element as its **second** argument, and the local one-argument `cs()` helper silently reported
  a legal 44px target as 32.)
- **`.gacts` is left-aligned where 064 says "right-aligned, Principal last".** That is a deliberate
  context rule, not drift: a block's foot strip sits on the list's own left text edge so it reads as
  belonging to the list above it, and the block's options icon goes to the far right.

#### Before and after, measured with the rail held constant

The R10 declarations were injected back out so only the action system moves:

| surface | bold share | action-pixel share | outlined actions | 1px stroke ink | page height |
|---|---|---|---|---|---|
| Estantes, shut | 24.5% → **24.5%** | 3.72% → **3.62%** | 2 → **1** | 662 → **266px** | 767 → **755px** |
| Estantes, one estante open | 26.7% → **26.7%** | 4.63% → **4.57%** | 3 → **2** | 1 026 → **630px** | 1 076 → **1 064px** |
| sección, con cambios | 13.3% → 13.3% | 1.11% → 1.11% | 2 → 2 | 532 → 532px | 1 880 → 1 888px |
| editor, borrador con cambios | 44.2% → 44.2% | 6.07% → **6.04%** | 3 → 3 | 1 259 → 1 259px | 1 578 → 1 586px |
| editor, publicado con cambios | 32.6% → 32.6% | 6.49% → **6.46%** | 2 → 2 | 991 → 991px | 1 740 → 1 748px |

**The bold share did not move, and it could not.** Round 2 already settled weight, and a role's label
is 600 in every anatomy — so "kill balance" was never about weight. The number that moved is the
**stroke ink**: −60% on the Estantes page shut, −39% with an estante open, because the page's own
action stopped being an outline. The pages that grew 6–8px are the ones where a 40px tappable row
became 44.

**Does the content lead more?** On the page the developer named, yes and specifically: the first screen
now carries **one** outlined action instead of two, and the one it carries (*Ordenar*) belongs to the
block it acts on. Three equal Secundarias and no Principal — which is what R8 shipped — is the exact
shape of "too big and kill balance": the page shouts three times and asks for nothing.

### Verification

```
node .planning/sketches/065-admin-composition/build.js        # checksum-stable across two runs
node .planning/sketches/065-admin-composition/verify.js       # 610/610  (was 564)
node .planning/sketches/063-admin-game-editor/verify.js       #  63/63
node .planning/sketches/064-admin-button-system/audit-admin.js #  154/154  (was 106)
```

New in 065: `M1`–`M6`, the census **as an assertion** — every context × role across a 14-surface walk
plus four sheets (**22 pairs, 100 controls**) must have exactly **one** anatomy; four anatomies and no
fifth; no block piles up outlined actions of one rank; every page-level action is text; every tap
target clears 44px; every sheet's actions are 48px rows. The editor was **missing from that walk** at
first, which is where five of the pairs only ever appear — a cross-page rule that never visits a page
asserts nothing about it.

The per-screen half lives in **`064/audit-admin.js` (`A1`–`A9`)**, on purpose: round 4 and round 9 both
found a control that nothing audited, and a rule that lives only in the composition drifts the moment a
sketch is edited on its own.
