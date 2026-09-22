---
sketch: 062
name: admin-list-rows
question: "Using 061's row anatomy and type scale, where should secondary row actions (reorder, Quitar, Corregir/Mantener) go on Web, the section editor, Estantes, Asignar, Revisar niveles and Staff?"
winner: "B — Modo ordenar + hojas: clean rows (chevron / ⋯), Ordenar→Listo reorder mode, all other row actions in 059 bottom sheets"
tags: [admin, web, secciones, estantes, asignar, niveles, staff, list-rows, reorder, bottom-sheet, phase-01.8.1, mobile-first]
---

# Sketch 062: Admin List Rows

## Design Question
Phase 01.8.1 UAT rejected the admin UI as a whole (G-01.8.1-admin-ux). 059 (shell), 060 (Admin home) and 061 (Juegos)
already settled the frame, the row anatomy and the type scale. The remaining screens still use the shipped
`rounded-box border` list items, filled primary buttons, `.table`s (Revisar niveles, Staff) and display-type `h2`s:

- `SectionLive.Index` (Web): create, ↑/↓ reorder, Destacada / Oculta badges, kind hint
- `SectionLive.Edit`: name, subtitle, hide checkbox, sort select, member type-ahead with ↑/↓ and Quitar, 20-game cap on the featured row
- `ShelfLive.Index`: create, ↑/↓ reorder, and `?vista=lista` pick list
- `ShelfLive.Assign`: walk the shelf with tap-to-assign, move toast with Deshacer, error toast with Reintentar, rename modal
- `BandAuditLive`: table with Corregir / Mantener
- `StaffLive.Index`: invite form, table, Quitar with a confirm modal

This sketch applies 061's decisions to all of them and tests the one open question they share:
**where a row's secondary actions live.**

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/062-admin-list-rows/index.html

Top bar: variant (A/B) plus "Ir a" jump links to each screen. Tools (bottom-left): theme, phone/desktop, role,
**Datos: Con pendientes / Todo al día** (empty states), **Simular → Error al guardar** (the next assign fails).

Real data comes from the `create_sections` migration (the 8 seeded sections with their names, subtitles, kinds and sorts),
`Vocabulary.implied_weight_band/1` thresholds (<1.9 / ≤3.1 / >3.1) and the shipped copy strings.

## Shared by both variants
- 061 page order: add form (group label = field label, outlined 44px field + outlined submit, disabled while empty),
  then search, then list. Web: Nueva sección. Estantes: Nuevo estante. Staff: Invitar a staff, with a helper line
  "Quedan N de 3 lugares" that becomes the limit message and disables the form when full.
- One row: 40px slot (thumbnail, icon tile or 40px avatar) · 15px name that wraps · 12px meta line. Meta separators stay attached
  to the item after them, so a wrap never leaves a dangling "·".
- **Web:** icon tile per kind (star = featured tile tinted with the accent, list = Elegida a mano, sliders = Por nivel, clock = Recientes).
  Hidden rows show a hollow dot + "Oculta" and a muted name. The featured row reads "Siempre primera" and can't move.
  "Las filas sin juegos publicados no se ven en el inicio." (D-24).
- **Sección editor** (drill-down "‹ Web"): AJUSTES (Nombre, Subtítulo, a positive **"Mostrar en el inicio" switch** replacing
  "Ocultar en la home", Orden, and an outlined "Guardar cambios" enabled only when something changed). JUEGOS · n (de 20):
  search pill → result rows with a ⊕ that add on tap → member list. Por nivel / Recientes sections explain where
  their games come from instead of listing them. A non-manual sort shows "Ordenados por nombre. Para ordenarlos vos, elegí 'A mano'."
- **Estantes:** progress line ("328 de 412 juegos ubicados" + accent "84 sin ubicar" pill + meter). An iOS 2-segment
  **view switch** (Estantes / Juegos por estante) replaces the "Ver lista por estante" text link. A view switch is segmented,
  while filters stay chips as in 061. The lista view groups by shelf in walking order, with Sin ubicar last.
- **Asignar** (drill-down "‹ Estantes"; the shipped back link wrongly went to /admin/juegos): title + Renombrar text button, progress,
  "Buscar cualquier juego", **SIN UBICAR first** (tap the row or its ⊕; the row slides out and the meter and tab badge update),
  and "En este estante · n" as a collapsed disclosure row at the bottom. Search results show "En Estante B" (a tap
  moves it, with "Movido desde…") or "Ya está en este estante" (green check, can't be tapped). A failed save reverts the row and shows
  "No se pudo guardar · Reintentar".
- **Revisar niveles:** no table. Meta line: `Ingenio estratega → **Nivel experto** · BGG 3,86`. Empty state: "Todo coincide con BGG".
- **Staff:** avatar · email that wraps · green "Activo · entró el 13 sep" or orange "**Invitación pendiente** · enviada ayer".
  The owner row ("Dueña · vos") has no action.
- Every non-confirmed change (assign, remove member, Corregir/Mantener) gets a **snackbar with Deshacer**. Staff removal
  keeps a confirm step because it signs someone out.

## Variants
- **A: En la fila.** Actions are always visible. ↑/↓ icon buttons (44px targets, 18px chevrons, disabled at the ends) on
  Web, Estantes and members. Members also get a ⊖ Quitar icon, so that row carries **three** icons (over the ux-patterns
  D22 action cap, and names get about 150px). Revisar niveles puts "Mantener" / "Corregir" text buttons under the evidence line (rows
  about 96px tall). Staff has a red "Quitar" text button that opens a confirm sheet. The Orden setting is a native select, and Renombrar
  swaps the title for an inline field.
- **B: Modo ordenar + hojas.** Rows show only a chevron (opens) or ⋯ (has options). An "Ordenar" text button in the list
  header switches that list to ↑/↓ mode, and "Listo" exits (iOS Edit pattern). Rows can't be opened while ordering. All other actions use
  059's bottom sheet and row anatomy: member ⋯ opens Ver en la ludoteca / Quitar de la sección. A niveles row opens a sheet that
  spells out the evidence ("Brass: Birmingham está en Ingenio estratega, pero su peso en BGG (3,86) corresponde a Nivel
  experto."), then "Pasar a Nivel experto" / "Mantener en Ingenio estratega · No vuelve a aparecer, salvo que cambie su peso
  en BGG" / Cancelar. Staff ⋯ opens identity + "Quitar del staff ›", which steps to the confirm in the same sheet. Orden and Renombrar open sheets.

## What to Look For
- Reordering: does A's always-visible ↑/↓ feel like clutter on Web/Estantes, where the order rarely changes? Is B's
  extra "Ordenar" tap worth the clean rows?
- Members in A carry three icons. Is it too dense, or is it fine because this list is only edited by staff?
- Revisar niveles: A needs one tap per game but is a wall of text buttons. B needs two taps but explains the decision,
  which matters for "Mantener", since that decision is sticky (drift detection).
- Asignar: does putting Sin ubicar first with "En este estante" collapsed match walking the shelf with a phone?
- Consistency with 061 of add form → list on every page. On Web, creating a section is rare. Should "Nueva sección" move below the list?

## Verification (build pass)
A scripted run through both variants passed on the 375px phone frame with zero JS errors and no horizontal overflow on any screen:
- Web reorder swaps rows, and focus stays on the arrow (or falls back to the other arrow once the first is disabled).
- Destacados: adding past 20 shows the cap error, and removing a member shows the snackbar.
- Editor: Guardar enables only once something changes, and saving renames the section.
- Estantes: the lista view shows 5 groups.
- Asignar: the badge goes 84 → 83, a simulated failure keeps the count and shows Reintentar, searching for Catan moves it with
  "Movido desde Estante B", and rename works both inline (A) and in a sheet (B).
- Niveles: 7 → 6 → Deshacer → 7.
- Staff: an invalid email shows the error, the 3rd invite locks the form, the confirm step opens with Cancelar focused, and removal works.
Screenshots were reviewed for A's Web list, A's editor and members, A's niveles, and B's niveles sheet. **Dark mode and desktop have not been checked visually yet.**

Fixes made while building: separators dangling at the ends of wrapped meta lines, and "Pasar a hobby" (a truncated band name) → "Corregir".

## Winner: B, Modo ordenar + hojas (2026-09-15)
Developer: "B feels better, mark it as winner". A stays in `index.html` for comparison. B is now the default tab and marked ★.

Carry forward to 063 and the gap-closure plan:
- **Rows:** a row carries at most one trailing affordance. A chevron (›) means the row opens something. A ⋯ means the row has options in a sheet.
  Tapping anywhere on the row triggers it. No inline icon or text buttons on list rows, which also keeps every row under the ux-patterns D22 action cap.
- **Reorder is a mode:** an "Ordenar" text button in the list header (lists that can be reordered: Web, Estantes, a manual section's
  members) switches to ↑/↓ mode, and "Listo" exits it. Rows can't be opened while ordering, and each tap saves right away (D-19 `move_*`).
  The featured section row reads "Siempre primera" and has no arrows.
- **Secondary and destructive actions open a bottom sheet** (a centered dialog on desktop) with 059's row anatomy and a group label: member ⋯ → Ver
  en la ludoteca / Quitar de la sección. Niveles row → evidence sentence + "Pasar a {banda}" / "Mantener en {banda}" (with
  the drift-detection explanation) / Cancelar. Staff ⋯ → identity + "Quitar del staff ›", which steps to the confirm in the same sheet with Cancelar
  focused. The Orden picker and Renombrar estante are sheets too.
- **Undo instead of confirm** for reversible changes (place a game, remove a member, Corregir/Mantener): a snackbar with Deshacer.
  Removing staff keeps a confirm step because it signs someone out. Undo for Corregir/Mantener and for a first placement is new backend
  work (the shipped app only offers undo on a move).
- Everything under "Shared by both variants" above also applies: the Estantes view switch, "Mostrar en el inicio" as a switch, Sin ubicar first on
  Asignar with "En este estante" collapsed, the Asignar back link going to Estantes, and Staff slot counts.
- Still open: whether "Nueva sección" should move below the Web list. Dark mode and desktop haven't been checked visually yet.

## Button system from sketch 064 applied (2026-09-15)
The admin now uses one button system everywhere. It's S3 Contorno, weight-tuned; see `064-admin-button-system/README.md`. The identical CSS block ("064: admin button system") is appended to this sketch's `<style>`, scoped with `#device`, so it overrides the older local `.obtn`/`.tbtn` rules.
- **One anatomy:** 44px · 8px radius · 14px/600 · 16px icon · 8px gap.
- **Principal** (`.obtn`/`.b-pri`) is a 1px primary outline. **Secundaria** (`.b-sec`) is a 1px neutral outline (`--stroke`, ≥ 3:1, shared with text fields). **Terciaria** (`.tbtn`) is secondary-purple text. **Peligro** (`.tbtn.danger`) is danger text.
- **No disabled buttons, and Principal is last in its row.**
- The add forms (Crear, Invitar, Agregar) are never disabled. An empty "Crear" now says "Poné un nombre." Invitar is not rendered when the staff is full (the help line explains why).
- "Guardar cambios" only appears with changes, next to a "Cambios sin guardar" note.
- The rename sheet's "Guardar" moved from a text button to Principal.
- "Sí, agregar edición" is Secundaria.
- The login moved to a Principal button.
Checked by `064-admin-button-system/audit-admin.js`.

## Font weights normalized to what the app ships (2026-09-15)
The app self-hosts Inter **400 and 600 only** (`assets/css/app.css`), so a declared 500 rendered as 400 and 700 as 600. The sketch's balance was never what ships. This is the same fix 063 got in its R11.
- Every `font-weight: 700` is now 600 and every `500` is now 400. `b, strong, h1–h4, th` are pinned to 600, because their browser default is 700.
- **One state pair collapsed and was re-separated:** tab labels were 600 with the active one at 700, so both became 600. Inactive tab labels are now 400 and the active one stays 600. The other state pairs still differ: drawer rows, chips and the segmented control are all 400 → 600.
- Row names (`.gname`) went from 500 to 400, matching 063's rows.

Checked by `064-admin-button-system/audit-admin.js`: real Inter 400/600 loads, every visible element is 400 or 600, text is Inter or Bebas only, and the active tab label outweighs the inactive ones.

## Applied from sketch 065 (admin composition, 2026-09-15)
Walking the whole admin in one app turned up drift that was invisible one sketch at a time. The
identical shared block "065: one label per job" is appended to 059–063; the changes here are:
- **One counter source.** This sketch's `DATA()` — the only fully derived one — became THE pair for
  060, 061 and the composition.
- **412, not 408** (`HIDDEN_PUBLISHED` 396 → 400), matching `TOTAL`.
- **One level vocabulary.** `BANDS` held the three level names; 063 held names *and* meanings, so
  "Ingenio estratega" was explained in the game editor and assumed here. `BANDS` now carries 063's
  shape verbatim, and the Nivel sheet's "Pasar a …" row says what the level means instead of "Usa el
  nivel que indica BGG".
- **The settings group is a soft box,** not hairlines — the same component the game editor renders
  (063 R3/R6). Sheets keep their rows.
- **Asignar's head gap** was 12px where every other page had 16 (its spacer follows `.trow`, so it
  missed the polish rule). All page heads now sit 24px above the first block, the distance blocks sit
  from each other.
- **Asignar's title** no longer sits 7px lower than sección's because "Renombrar" centres it in a
  44px row.
- Section and field labels follow the shared 065 block.
- **Weight balance (round 2).** `.err-t` was 400 while `.st-draft` was 600, so "Error al traer datos
  de BGG" — the row with a Reintentar next to it — read quieter than a "Borrador" status. Both 600
  now. Dashboard box weights as in 060.
- **Round 3 (what a row says, from sketch 065).** Year and player count were never in production
  (the shipped list is Nombre | Estado). Año stays — it is what tells two editions of one game apart;
  "N jug." is gone. Status now marks the EXCEPTION: Publicado is unmarked (it was 407 of 412 rows),
  Borrador takes the accent pill this admin already uses for pending work, Retirado takes a muted
  outline pill and a muted row. Never colour alone — the amber dot it replaces measured 2.78:1,
  under the 3:1 non-text floor, and grey means "disabled", which a draft never is.
- **Round 4 (fields, from sketch 065).** "Buscar por nombre" was a filled pill (`radius-full`,
  `--color-surface`, transparent border) sitting 24px under the outlined 8px "Agregar" field — two
  inputs of the same size and type reading as different species, and `--color-surface` is what a soft
  content block is made of here, so it read as a container. The search field now joins the 064 field
  system (8px, 1px `--stroke`, page background) via that block's own `:is()` list; the magnifier and
  clear button carry "search". 064's field audit selector now includes `.sfield input`, which it
  never covered.
- **Round 5 (list label, from sketch 065).** Juegos was the only admin page with an unlabelled block:
  "Agregar juego" named the form, the search + filters + 412 rows named nothing. The list is now
  **"Juegos del club"** — reusing the official word rather than inventing a third name for the same
  set (`card-interaction.md`: don't create two parallel vocabularies), with "del club" earning its
  keep against the BGG-sourced Agregar block right above. The result count stays below the chips that
  change it.
- **Round 6 (alignment + rhythm, from sketch 065).** See 065's README for the full table. Here:
  Web's "filas sin juegos" rule moved above the list as its hint; "Ver en la ludoteca" gained the
  chevron every other navigating sheet row has; field labels step down to 12px/600 muted; `.sgroup`'s
  16px top margin restored (a round-1 regression that made the sección box butt into the field above).

## Round 7 — one component per job (from sketch 065, 2026-09-16)
Four developer notes on the sección editor plus one on Estantes, and every one of them was **a second
implementation of something this admin already had**. The shared block "065 R7: one save bar, one
settings panel" is appended to this sketch's `<style>` and to 063's, byte-identical;
`065/build.js` throws if the two ever drift apart.

| # | Note | Root cause, measured | Fix |
|---|---|---|---|
| 1 | *"the form … with the 'mostrar al inicio' feels so disconnected, breaking balance and killing rhythm"* | The **Ajustes** block held Nombre and Subtítulo bare on the page background and then a soft `--color-surface` box for the two setting rows — one labelled block, two surface treatments — with gaps of **8 / 6 / 12 / 6 / 16px** down its middle. | The fields become field rows inside the same box (`.sgroup.apanel`): one surface, gaps **12 / 12 / 12**, padding 12 above the first child and 12 below the last — `.ppanel`'s internal gap, the game editor's box rhythm. A field label keeps its 6px half step over its own input. Fields on the tint still carry a 1px stroke at **3.72:1** light / **3.14:1** dark, over 064's 3:1 floor. |
| 2 | *"the form fields and the search looks all same (search? form fields?)"* | Not anatomy — round 4 gave the search the same field anatomy on purpose and that stands. They read alike because **both sat on the page background**. | Item 1 resolved it, and it is measured: the form is on `--color-surface` and `mem-q` is the only field left on `--color-bg`. `.sfield input` was not touched. |
| 3 | *"cambios sin guardar and its CTA are disconnected (why a pure text?)"* | **Two save bars for one job.** `.saverow` was a 12px accent note and an outlined button loose on the page background, 16px under the box; 063 already had `.ebar.inline` — a soft surface block with a status line and its actions. | sección renders the editor's component: `12px 16px` padding, 12px gap, `--color-surface`, 12px radius, a 13px/600 status line with its dot, and a 44px **Guardar** (the editor's one-word label) landing on the box's content edge. A sección has no draft/published lifecycle, so the status line's own job is the save state: "Cambios sin guardar" with the accent dot, "Todo guardado" with the published one. `.saverow` and `.dirty-note` are gone. |
| 4 | *"'Ordenar' looks pure text … same pattern everywhere"* | 064's **Terciaria** rung (no stroke, purple label) for a control that switches every row below it into another mode — and pulled 12px past the row's content edge (**393.5 vs 381.5**), which is right for a borderless label and wrong for a button. | Changed in `lhead()`, so Web, Estantes and sección move together: **Secundaria** to enter the mode (1px `--stroke`, 4.3:1 / 3.49:1) and **Principal** to leave it (1px primary, 14.16:1 / 11.67:1) — "Listo" is the action that finishes the block's job. `aria-pressed` flips, the border changes with the word, both states are 44px and end on the content edge at 381.5. The header row grows 36 → 44px; the `.gcount` / `.pend` right slots still sit dead centre on their label's middle. |
| 5 | *"on estantes, the field blinks when I type"* | `QMAP[id]` debounced 300ms into `patch()`, and `patch()` rebuilds `main.innerHTML` — so every keystroke **destroyed the focused input**, built a new node and restored the caret. All three searches did it (`mem-q`, `lista-q`, `asg-q`). | `refreshQ(id)` replaces one region and never the field: **`#mem-results`**, **`#est-groups`**, **`#asg-results`** — the same targeted refresh 061 already used for Juegos, and how LiveView would diff it. Typing Nombre/Subtítulo likewise calls `syncSecBar()` and swaps `#sec-bar` alone, the way 063's `sync()` swaps `#ebar`. |

Also found by measuring rather than looking: dropping `.saverow`'s 16px margin left the new bar
butting **straight against the settings panel at 0px**. It keeps a 12px seam now — the panel's own
rhythm.

Checked by `065/verify.js` C1–C5 (both themes at 420px, then 1440px) and still green in
`064/audit-admin.js`.

### Round 7b — three notes on Estantes (from sketch 065, 2026-09-16)
Same round, three more notes, and again each one was a measurement rather than a taste. The shared
block **"065 R7b: one control for pick one of N, one grouped list"** is appended to this sketch's
`<style>` and to 063's, byte-identical, and `065/build.js` now throws if those two — or the two copies
of `row()` — ever drift apart.

| # | Note | Root cause, measured | Fix |
|---|---|---|---|
| 6 | *"on estantes, that double list doesn't scale at all since i need to scroll down to found what already is on the estante"* | **1702px = 2.30 screens for FOUR shelves**, showing **16 of 412 games (3.9%)**: every group rendered `games.slice(0, 4)` and then a caption, `y 64 más`, with nothing to tap. One populated group was **294px**, so twelve shelves would have been ≈3,500px ≈ 4.7 screens — still four games each. And "Estante D — expertos" claimed **157 juegos over 0 rows**, because its games all lived in the `base` this sketch never materialised. | Collapsed groups that expand in place — the mobile standard, and a component this admin already ships: Asignar's `.grow.disclose` (round 5: a disclosure row names its own block, so L1 holds without a label above it). A shut group costs **one 60px row**; the whole view is **740px = 1.00 screen** at four shelves and **1171px = 1.58 screens at twelve** — still shorter than four shelves used to be. A group opens to its games eight at a time and then offers **"Mostrar más · 8 de 84"**, the unplaced list's own control, instead of a caption. **`.lcap` is gone**: it was the mute answer to "there is more here" and it sat on the only two lists you could not page (the other was Asignar's own "En este estante"). |
| 6b | the fixture was the lie | `place` hard-coded a 5-cycle over shelves 1–3, so shelf 4 held nothing locally while claiming 157. Harmless while a group only ever showed its first four games; a lie the moment you can expand it. | `seed062(pend, nShelves = 4)` derives the shelves from a count via `shelfFixture()`, with two invariants at any *n*: every shelf really holds some of the 36 games rendered here (round-robin), and the hidden bases still sum to placed − 20, so **Σ`shelfCount` = `placedN()` = 328, +84 sin ubicar = 412** at 4 shelves and at 12. At *n* = 4 it reproduces the seeded 60 / 54 / 37 / 157 exactly. "Estante D" now says **162 juegos** and opens to **5 real rows** with "5 de 162". |
| 7 | *"on estantes rename, the bottom sheet use cancel and save pattern. That CTA looks too heavy. And be sure to define a kind of pattern that must to be used everywhere"* | **Two sheets had a button footer, not one.** `v-rename` had a Terciaria "Cancelar" beside a Principal "Guardar" in a `.banner-actions`; 063's **Filas del inicio** sheet had a lone Terciaria "Listo" in one. Every other sheet — `confirmRemove`, the Nivel sheet, Orden, the member sheet, Staff — builds its actions as 48px full-bleed `.dlinks` rows. The rename sheet also put its `.group-label` **inside** the form, so its label gap measured **−16.5px** where every other sheet measures **+4px** — it had never been in R6's walk. | **A sheet's actions are rows in its `.dlinks`, never a button footer** — the committing row first with `tick` (or danger tone when destructive), "Cancelar" last with `chevL`. Rename is `Guardar → Cancelar`; Filas is `Listo`. The committing row **is** the form's `type="submit"`, so Enter still commits, and the inline `.ferr` still reports without closing the sheet ("Poné un nombre." / "Ya hay un estante con ese nombre.", focus back on the field). `row()` gained `type` (default `button`) — which also closed a latent bug: any `row()` dropped inside a form would have submitted it. Variant A's inline `.renform` is a **page** form, not a sheet, so the rule leaves it alone. |
| 8 | *"Estantes \| Juegos por estantes filled feels weird"* | A WCAG failure, not a preference. The `.seg.two` track was filled with `--color-surface` — what a soft content **block** is made of in this admin (round 4) — and the selected segment with `--color-bg`, the page background, so the chosen option read as a hole punched in a block. Selected vs track: **1.16:1 light, 1.17:1 dark**, both under **1.4.11**'s 3:1 floor for a component's state. 10px where chips, the Agregar field and the search field are all 8px. And its first label was **"Estantes" — the page title, verbatim**. Nothing had ever audited it (064 has no chip/seg check), the same audit-hole shape as round 4's search pill. | The job is "pick one of N and change the list below", which is the job 061 compared A2 (segmented) against A1 (chips) for and **chose chips**. The view switch **is** the chip row, markup included; `.seg` survives only as 061's rejected A2 variant. A chip carries its state on four channels — a **✓ glyph at 11.27:1 light / 10.54:1 dark**, 600 weight, the accent fill and the accent label — where the segment had only a 1.16:1 fill. Labels: **"Recorrido" \| "Contenido"** — parallel, both naming a view, neither repeating the title. |
| 8b | the chips owed the same debt | **Neither candidate passed 1.4.11 as shipped.** A chip's own outline measured **1.42:1** light / **1.30:1** dark against the page, and `.chip.on` set `border-color: transparent` with a fill only **1.26:1 / 1.11:1** off the page — so the control's boundary was under 3:1 too. | Every chip carries 064's field/Secundaria `--stroke`: **4.3:1** light, **3.49:1** dark against the page, **3.42 / 3.15** against the selected chip's own fill. One token for one job, so the state stays on the tick, the fill and the weight rather than on a louder border (an accent stroke would borrow Principal's language, which 064 reserves). This also visibly improves 061's four filter chips on Juegos. |

**Search, with groups that collapse.** The rule in code — *the filter never hides a group's heading
(E5)* — now means the heading **is** the group, so it always stays: at 12 shelves a one-hit search
keeps **13/13** headings (1467px = 1.98 screens). A group that matches **opens itself** and says
`1 de 54 coinciden`; one that does not stays shut and says `Ninguno coincide`. `V.grpOpen` is cleared
on every keystroke, so each query re-derives its own defaults instead of inheriting the last one's —
and a tap still overrides either way. R7's no-blink rule holds through all of it: the `lista-q` node
survives every keystroke, `#est-groups` is the only thing replaced.

Checked by `065/verify.js` C6–C8 (both themes at 420px, the sheet walk now 10 sheets deep) and still
green in `063/verify.js` and `064/audit-admin.js`.

## Round 8 — Estantes is ONE page, and the order of a shelf is the order of the shelf (from sketch 065, 2026-09-16)

Developer: *"the buttons 'recorrido' and 'contenido' is too complex. Is better a collapsable list of
games on a 'estante' and then games to add? also from the list I should be able to remove it and sort
inside a 'estante'?"* · *"crear secondary(should we use a bottom sheet for it?). The #1 action is to
'look' where is the game(estante) and together to which games(in middle of which games)"* · *"the
positional should be first but also could be expandable with the rest of information (neigtbors and
estante name)"*

**The page's job is one question — *where is this game?* — and round 7b's page could not answer it.**
Measured on the round-7 build at 420×740: the estante took **3 taps** (tab, "Contenido" chip, type) and
the neighbours took **no number of taps at all**, because a group opened to `G.filter(place === sid)` —
catalogue order, not shelf order — and nothing said so. Five taps to a wrong answer. It takes **2 taps**
to the estante and **3** to the neighbours now, and the answer needs **no scrolling** in either round —
the scroll was never the problem, the answer was.

**The premise the page now rests on:** the order of the games on an estante **is** their physical
left-to-right order on the shelf. A zone is an index read back in words, the neighbours are the slots
either side, and Ordenar moves a real box — which is why its hint says *"Movés la caja de verdad, así
que hacelo también en el estante."*

The shared block **"065 R8: ONE Estantes page"** is appended to this sketch's `<style>` and to 063's,
byte-identical, and `065/build.js` now throws if those two — or the two copies of `QREG` — drift apart.

| # | Note | Root cause, measured | Fix |
|---|---|---|---|
| 9 | *"the buttons recorrido and contenido is too complex"* | Round 7b's own control, **one round old**. Neither view could answer the page's first question: "Recorrido" had no search field at all and put the Nuevo estante form at **227px**, between the progress line and the first estante, which it pushed to **368px**; "Contenido" could name the estante (3 taps) and never the position. A control that lasts one round is a finding about its premise, not an embarrassment — **two views was the wrong premise, not the wrong labels.** | **One page.** `head` → progress → **search at 167px, the page's first control** → `lhead('Estantes del club', 'estantes')` with Ordenar → the estantes as `.grow.disclose` groups → **Sin ubicar as its own block** → "Nuevo estante". `.seg` and `.chips.vista` render nowhere; the chip fixes R7b made survive on 061's four filter chips, which is where the component still has a job. |
| 10 | *"a collapsable list of games on a estante … from the list I should be able to remove it and sort inside a estante"* | The double list was two lists because Asignar was a separate screen. | An estante opens **in place** to its games **in the shelf's own order**, 8 at a time then `Mostrar más · 5 de 59`. A row expands to its neighbours and carries **Quitar del estante** (reversible with Deshacer, so 062's "destructive actions open a sheet" rule is satisfied by the undo rather than bypassed) and **Ver en la ludoteca**. Sorting is the admin's own Ordenar mode, scoped per estante (`sh<id>`), reached from the estante's **⋯ Opciones** sheet along with **Renombrar estante**. |
| 11 | **`/admin/estantes/:id/asignar` is retired as a screen** (developer's choice when asked: *"Expanded shelf replaces it"*) | Everything it did either belonged on the page or had no reason to be a drill-down. | ubicar in bulk → an estante's **Agregar juegos** mode (`Agregar juegos → Listo`, the same grammar as Ordenar); ubicar one → **Ubicar en…** from a Sin ubicar row; "Buscar cualquier juego" → the page's one search field, which also answers *where is it*; the progress line → unchanged and **on screen while you work**; **Renombrar** → a row in the estante's options sheet, and it keeps a sheet because that is the surface K3 measures against the soft keyboard. `SCREENS.asignar`, `asgBody`, `asgListHtml`, `V.asgQ`, `V.onShelfOpen` and `V.vista` are all gone. |
| 12 | *"the positional should be first but also could be expandable"* | Nothing on the page had ever said where on a shelf a game was. | A row leads with its **zone** — `Más a la izquierda` · `Al medio` · `Más a la derecha`, the developer's own words — and the meta line then carries **exactly one** more thing, whatever the context does not already say: the **estante** in a search result, the **año** inside that estante's group. Measured: `zona · estante · año` wrapped **6 of 13** result rows into **four** row heights (60/70/73/89px, 872px total) where `zona · estante` wraps **none** (60/73px, 806px). Tapping the row expands it **in place** to the precise half of the answer — *"Entre Brass: Birmingham y Root"* — on the row's own text column (**90.5 vs 90.5**). |
| 13 | *"crear secondary(should we use a bottom sheet for it?)"* | The `addForm` sat in the page body above the list, which is 061's page order and the wrong order for a page whose job is finding. | **Yes, a sheet.** `tbtn b-sec` + `aria-haspopup="dialog"`, 44px, at **619px** past the estantes instead of 227px above them, and **0 forms left in the page body**. It follows round 7b's sheet-action rule exactly — commit row with `type="submit"` first, "Cancelar" last with `chevL`, inline `.ferr` that keeps the sheet open — and is driven end to end: empty → "Poné un nombre.", duplicate → "Ya hay un estante con ese nombre.", **0 estantes created**, and Enter or a tap each commit exactly once. `shelf-new` left `V_FIELDS` for a `SHEET_FIELDS` map, because a field in a sheet is not in `#main` and patching the page per keystroke was work for nothing. |
| 13b | **the fixture had to get real** | R7b made the *counts* honest and left the *order* dishonest. A zone and a pair of neighbours mean nothing out of a bag of games. | **A shelf is an ordered array of slots.** `V.order[shelfId]` holds, in physical order, either one of the 36 games this sketch names or a slot that really exists on the shelf and whose title it does not render. Σ of the array lengths **is** `placedN()` — **328** at 4 shelves *and* at 12, +84 sin ubicar = 412 — and it stays true through an edit (remove → 327 = 327, place → 329 = 329). The named games sit in **one contiguous run per shelf** at a cycling start/middle/end offset (`5/65@0-4 · 5/59@27-31 · 5/42@37-41 · 5/162@0-4`), so every index and therefore every zone is real at any shelf length, every named game has a named neighbour or an honest end, and the fixture exercises **every shape of the answer**: `Antes · Después · Entre · Primero · Último` at 4 shelves and `Antes · Después · El · Primero · Último` at 12. `nbrLine()` never claims a neighbour it does not have — 20 lines checked at each shelf count, **0 dishonest**. |

**Three zones, not five, and not derived from the count.** The fixture's estantes hold 65 / 59 / 42 /
162, so a third of the biggest one is **54 boxes** — which is close to lying, and the reason the zone is
never sold as the answer: its job is *which end to walk to*, and the neighbours name the box one tap
away. Five zones (13/12/9/33) lost for two measured reasons, neither of them layout — **both
vocabularies fit on one line**, so wrap settled nothing. They lost because "Más a la izquierda" would
mean 0–33% at three zones and 20–40% at five (one phrase, two meanings), and because deriving the
granularity from the count is worse still: a >100 threshold over these very shelves gives **[3, 3, 3,
5]**, the same three words meaning thirds on three estantes and fifths on the fourth *on one screen* —
the two-parallel-vocabularies trap `card-interaction.md` warns about and rounds 5 and 7b both ruled on.

**Two bugs measurement found and the eye could not.** Moving "Sin ubicar" inside a `.mi` turned `.dot`
from a flex item of `.gsub` into an inline non-replaced box, where `width` and `height` do not apply: it
declared 7×7px and measured **0×15**, i.e. invisible (`inline-block` now, asserted in both themes). And
R7b's `.grp .gnote` was set at **76px** — the *unpolished* row hairline — where every row on this page
is `.polish`, whose name column starts at **68**: the note sat 8px right of it (98.5 vs 90.5), and is
flush now.

**One artefact, stated rather than hidden:** ↑/↓ swaps *slots*, so a box at the edge of a run can be
pushed past a slot whose title this sketch does not render — the visible list does not change while the
row's zone and neighbour line do, so the row flashes. In production every slot is a named game and this
cannot happen, which is why the arrows are disabled at the **array's** ends and not at the last named
row. **And variant A's Estantes is now variant B's page**: A's grammar (three always-visible icons per
row) cannot carry a row that also has to disclose its position, and A lost three rounds ago.

Checked by `065/verify.js` **P1–P11** (both themes at 420px, then the walk again at 1440px, with the
walk's 8th stop re-pointed from `asignar` to an expanded estante, and C6/C7/C8/D1/D6/K1/K3/L1 re-based
rather than deleted), and still green in `063/verify.js` and `064/audit-admin.js` — whose two Asignar
screens were re-pointed at the expanded estante and joined by three new surfaces.

## Round 9 — the estante as a rail, and the zone word's census (from sketch 065, 2026-09-16)

Developer: *"what if we use carousel(horizontal scrolable) to represent that physical position, maybe
been inspired by Apple iBooks?"* — the answer to round 8's own open item, which was that **inside an
expanded estante the zone word is identical on every row** (five consecutive rows measured reading
*"Más a la izquierda"*), because the list order already carries the position. Stop *telling* it, show it.

Three variants, all three kept in this file behind **`V.est`** (⚙ tools → *Estantes (R9)*): **A** the
round-8 list, **B** the estante's games as the app's own horizontal rail, **C** the rail shrunk to a
44px map above the list. The rail is **transplanted, not invented** — the shared block *"065 R9: the
estante as a RAIL"* is byte-identical in this sketch's `<style>` and in 063's, `065/build.js` throws if
they drift, **and it additionally checks the four numbers `carousel_row.ex` calls a co-dependent set
against `assets/css/app.css` itself** (card 96 · gap 10 · fade 16 are production's ≤480px values
verbatim; the gutter is this page's 16px against the catalogue's 14px, and the 25px of clear peek that
leaves is asserted).

| # | Note | Measured | Outcome |
|---|---|---|---|
| 14 | *"what if we use carousel … to represent that physical position"* | **The rail is a display, not a navigator, and 3 is the number.** 024-A's edge-fade is two booleans, so over a 162-box estante it distinguishes **3** positions and **39 of 41 offsets sampled across the whole 16 819px range are the same single state**. Reaching the middle is **27 arrow presses** of 318.8px (3.01 boxes each) on a pointer and **8–15 flings** (a fling is whatever velocity the thumb gave it; 8 of ~1340px and 15 of ~592px both measured) on a phone, where 022-C leaves no arrows at all (`display: none`, 0px, out of the tab order). Search is **2 taps** to any named game in all three variants. | **B loses.** It renders, it reads as a shelf, and it is even **cheaper** than the list it replaces (an open Estante D is **317px** against A's **493px**) — but Estantes is a page whose whole job is finding, and the rail cannot do the finding. |
| 14b | the flow the round was built to test | Search *"dixit"* → tap the row → the estante's rail opens **already scrolled to Dixit and marked**, Brass: Birmingham and Twilight Imperium left, Root and Splendor right, centred, no words. It works. It costs **214px against A's 78px for the same answer at the same 2 taps**, A's answer (*"Entre Brass: Birmingham y Root"*) is the more precise of the two, and B's **collapsed** row had to give up the zone to make the rail the position channel — so before you tap you know *less* than in A. | the picture is not worth 2.7× the height of the sentence |
| 14c | *"rail as map, list as work surface"* | **C costs +60px** over A (553 vs 493) for a strip of 44px squares that names nothing, and the map still needs **13 presses** to the middle (arithmetic, not a driven run: a 52px pitch × 81 boxes = 4 212px at 318.8px a press — X4 drives the 27 on B). | **C loses harder.** It has the rail's cost and none of its saving. |
| 15 | **the zone word inside an expanded estante — round 8's open item, closed** | **4 estantes, 20 rendered rows, 20 zone words, one distinct word per estante.** Partly the fixture's doing (R8 put each shelf's named games in one contiguous run so every index would be real), so the arithmetic was computed too: a page is 8 consecutive boxes, a zone is a third of the shelf, so the word can only change across a page that straddles a boundary — **14 of 58 start positions at 65 boxes, 14 of 155 at 162. One word covers every row of 60% of pages on the 42-box estante, 76% on the 65-box one and 91% on the 162-box one** — more so the longer the shelf. | **Dropped inside a group, kept in a search result.** `zoneSub()` now returns the zone only when `withShelf` — thirteen results from thirteen estantes in relevance order have no order to read, so there the zone is the only thing saying which end to walk to, and it keeps the first slot. A row inside a group carries exactly its año, the slot R8 had already reserved for it. |
| 15b | and it does **not** go away for a screen reader | A rail's claim is that the eye reads position off the geometry; AT has no geometry. So every tile's accessible name must say it — *"Dixit, caja 29 de 59"*. | a rail does not remove the words, it removes them from the people who can see |
| 16 | **fixture honesty at rail density** | A list showed 8 rows at a time and the 376 unnamed games never surfaced; a rail shows many covers at once. **No cover may imply a game that does not exist**, so a run of unnamed slots is not drawn as covers: it is **one hatched band of the run's real length × the tile pitch**, with a sticky caption (*"157 cajas sin título en este boceto"*) that stays on screen while you scroll the stretch it describes. Every slot accounted for — **5+60=65 · 5+54=59** (two bands of 27, the run being mid-shelf) **· 5+37=42 · 5+157=162** — `scrollWidth` equal to the shelf's real width on all four (6 912 / 6 276 / 4 474 / **17 194**px), **0 invented covers, 0 tiles off their true x**. | the geometry is the shelf's, so every distance above is true |
| 17 | the marked tile, which would have failed in dark | A 2px `--color-primary` ring measures **14.16:1 light / 2.33:1 dark** — **under 1.4.11's 3:1 floor**, the exact shape of the failure round 7 caught in a control that looked fine. | R7b's chip answer instead: 064's **`--stroke`** as the boundary (**4.3:1 / 3.49:1**) on four channels — stroke, a ✓ badge at 11.27:1 / 10.54:1, the accent fill behind the label, 400→600 weight. |
| 18 | the rail's own keyboard bill | One focusable card per game is **up to 162 tab stops** between an estante and what follows it. A roving tabindex makes the whole rail **1 tab stop** with ← → Inicio Fin inside it — ~20 lines the vertical list got for free — and it fixes the stops, not the traversal: the middle of 162 is still **81 ArrowRight presses** from the first box, against 10 taps of *Mostrar más*. Tab stops inside an open estante: **A 9 · B 6 · C 12**. | recorded as a cost, not hidden |
| 19 | the gesture conflict that did not happen | Driven through CDP's real input pipeline, starting on a tile: horizontal → rail **Δ319**, page **Δ0**; vertical → page **Δ284**, rail **Δ0**; sloppy mostly-vertical → page Δ284, rail Δ0; mostly-horizontal → rail Δ323, page Δ0. With a bottom sheet open the rail underneath is inert (Δ0/Δ0). `overflowX 0` on all three variants, both themes, 420px and 1440px (1.4.10 — a rail is a *scoped* horizontal scroller inside the page's vertical one, which is what the catalogue already ships). | **no conflict in either direction** — this is what production's `touch-action: manipulation` buys over `pan-x`, and it is the rail's cleanest result |

**One extra estante costs 60px in every variant** — a shut estante is its disclosure row and nothing
else — so the rail changes nothing about the page's cost per estante, only what an *open* one costs.

**Winner: A**, with note 15's drop applied. B and C are **not deleted** — they stay behind `V.est` so
the idea is walkable and its numbers re-measurable, because "the rail loses at 162" is a finding about
*length*, not about rails. **The 024 verdict is HELD, unchanged, with no exception argued**: nothing was
added to either rail (0 indicator elements, 0 per-tile ordinals, asserted in both themes at both
widths), and no exception is needed because no rail ships. The condition is on the record though — 024's
own premise is a rail of 8–10 cards you can fling end-to-end, and past roughly 30 boxes at this card
width the fade degenerates from *where am I* to *can I scroll*, at which point an admin rail would need
a scrubber with a grab handle (not a progress bar, which would be 1px of fill per 2 boxes). That is a
different sketch and it should be asked for by a job.

**The rail's one outright win, kept as an open item:** **← / → is physically honest where ↑ / ↓ is not**
(44×44, *"Mover Catan a la izquierda"*, correctly disabled at the array's real end). A vertical list
could borrow half of it by making the *labels* physical while the glyph keeps naming the list move —
left alone this round rather than half-changed, because a glyph and a label pointing different ways is
its own problem for AT.

Checked by `065/verify.js` **X1–X10** (both themes at 420px, again at 1440px, plus a real-touch context
for 022-C and the gesture pass), with **P5 re-pointed** — its *"every row leads with its physical zone"*
now asserts that no row inside a group restates the order, and the zone is asserted where it still has
a job. Still green in `063/verify.js` and `064/audit-admin.js`.

## Round 10 — the estante IS the rail, and one action system (from sketch 065, 2026-09-16)

### A developer override of a measured verdict

Round 9 built three Estantes variants and **measured the rail as the loser**: over Estante D's 162
boxes an open estante cost A 493px · B 317px · C 553px, reaching the middle took **27 arrow presses**
or 8–15 flings against **2 taps** of search, 024-A's edge-fade distinguishes **3 positions** with 39 of
41 sampled offsets identical, and B's collapsed row told you *less* than A's before you tapped. Winner:
**A**.

Developer: *"For estantes, I want option B(riel). remove the another variants."*

So the rail ships and **A and C are deleted** — no `V.est`, no `.map` recipe, no `data-est` switch, and
`065/build.js` throws on a trace of any of them. Round 9's numbers stand as measured in 065's README;
none of them has been softened. What changed is that the cost round 9 charged against the rail is now
this page's problem to pay.

### What the page is now

- **An open estante is the rail**, and nothing else: no vertical list of its games, no *Mostrar más*,
  no paging. `.grow.gdisc` rows measure 0 inside an estante. Left to right on screen is left to right
  on the wood, asserted on the tiles' `data-slot` order.
- **Above the rail, the zone bar** (`.chips.ezones`): three jump targets, **Izquierda · Medio ·
  Derecha**, each one's accessible name the developer's own full phrase (*"Ir a más a la izquierda de
  Estante D — expertos"*). **1 tap to the middle of 162 boxes** — it lands on caja 81 of 162, exactly —
  against 27 arrow presses. The worst box on the shelf is 1 tap + 14 presses = 15. It is also the
  position readout: the third holding the rail's centre carries `.on` + `aria-current`, updated by the
  rail's own scroll handler so a fling moves it without a re-render.
- **The bar is earned by length, not granted to every rail.** `ZONE_NAV_MIN = 30`, derived from round
  9's fling measurement. Under that, nothing is added and 024 is untouched — which is every rail the
  catalogue ships. The exception is argued in 065's round-10 section.
- **A marked tile opens `.epanel`**: the game's name and the two jobs a row used to carry (*Ver en la
  ludoteca* · *Quitar del estante*), or, in Ordenar mode, **← / →**. That is round 9's one clean
  victory for the rail, now shipped: the glyph and the label finally point the way the box really
  moves, where round 8's ↑ / ↓ pointed a way no shelf has. The mark follows the box when it moves, and
  is cleared when the box leaves the shelf.
- **A search-result row keeps `zona · estante`** — *"Al medio · Estante B — estrategia"* — and expands
  into the rail, already scrolled to the game and marked, with its real neighbours on both sides in
  214px. The words are the coarse answer, the picture the precise one, at the same 2 taps. Round 9
  measured B throwing that first half away; it is back. **No zone bar inside a search expansion**: the
  bar is for browsing a shelf, and this rail is already on the answer.
- **Inside an estante the zone words are gone entirely** (0 over every rendered tile, all four
  estantes) — round 9's census is why, and the same census is why they are exactly right as
  navigation.
- **A tile's accessible name still says its real box number** (*"Brass: Birmingham, caja 28 de 59"*),
  the rail's group name says *"… de izquierda a derecha"*, the rail is **one tab stop** and the bar is
  **three real 44px stops**. A rail's claim is that the eye reads position off geometry; AT has none.
- **The cover placeholder letter is capped at 21px.** At 28px/600 it outweighed the page title
  *"Estantes"* at 22px/600 — five at once — and 065's `W1` caught it the first round the rail actually
  shipped. In production a tile is an `<img>` and carries no type at all.
- **Fixture honesty unchanged**: 5 tiles + 60 / 54 / 37 / 157 in hatched bands = 65 / 59 / 42 / 162
  slots, `scrollWidth` 6 912 / 6 276 / 4 474 / 17 194px, 0 invented covers.

### One action system (065 R10)

The matrix is in **064's README**. What lands in this file:

- **"Nuevo estante" is Terciaria text, not outlined Secundaria.** A page-level action is never
  Principal and never outlined — it sits under content it does not belong to. This also fixes a real
  bug: `.pacts .tbtn { margin-left: -12px }` is the *borderless* pull, and applying it to an outlined
  button hung its stroke **12px past the page's left content edge**. `.pacts`'s top margin drops 20 →
  8px, because a borderless button hides 14px of padding above its label (8 + 14 = 22, the same optical
  distance the outline's box edge used to hold).
- **`.gxacts` / `.epanel .gxacts` gap: 4px → 0.** Two borderless text actions already hold 12px of
  their own padding on each side, and round 6 #5's rule is that that padding *is* the rhythm. The
  census found four different answers to that one rule across the admin.
- **The estante's options `.ibtn` is pulled −12px**, so its 18px glyph lands on the content edge like
  every row arrow above it. It sat at inset 0 — two identical glyphs 12px out of line down one column.
- **A tappable row clears 44px**: `.sgroup.apanel .srow` (a sección's "Orden · A mano") declared 40px,
  and nothing audited it.
- **An outlined action never pulls**, in any context — round 7 wrote that rule for `.lhead` alone.
- **`v-grp-more` only serves "Sin ubicar"** now: a rail shows the whole shelf, so no estante has a
  *Mostrar más* to reach it.
- `resetGrps()` clears `V.ordering` too. A box is reordered on the rail, so "which estante is open" and
  "which estante is being reordered" are the same question — and a search that left `V.ordering` set
  used to render result rows offering a move in an order the search was not showing.

All three suites green with these in: `065/verify.js` **610/610**, `063/verify.js` **63/63**,
`064/audit-admin.js` **154/154**.
