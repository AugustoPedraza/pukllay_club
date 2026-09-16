---
sketch: 065
name: admin-composition
question: "Do the five admin pages designed on their own hold together as one app in a continuous walk — Admin → Juegos → editor → ‹ back → Web → sección → Estantes → Asignar → Perfil — or has drift crept in?"
winner: "composition (no variants) — 11 drift bugs found and fixed upstream, plus the mobile keyboard 059/061 never tested"
tags: [admin, consistency, composition, shell, rhythm, labels, counters, keyboard, mobile-first, phase-01.8.1]
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
node .planning/sketches/065-admin-composition/verify.js    # 100 checks
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
`verify.js` — 100 checks in headless Chrome, phone (420px) light and dark, then desktop at 1440px.

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
- **K1–K4** the four keyboard questions above.

063's `verify.js` (63/63) and 064's `audit-admin.js` (94/94) still pass with every upstream fix in.
