---
sketch: 063
name: admin-game-editor
question: "On /admin/juegos/:id/editar, how do the editable club fields sit next to the read-only BGG facts, and where do Publicar / Retirar / Restaurar live per status so the lifecycle action is clear without looking like a CTA?"
winner: "R8 V2 + R9 F2 (En el inicio list section) + U2 (1 | 2 | Más units) + R10 D1 (centered labeled divider instead of the grey band): public page mirror on the normal ground, internal part (En el club + Estado) in a full-bleed muted band captioned Solo para el club · no se muestra en la web; no tabs"
tags: [admin, juegos, editor, form, lifecycle, status, bgg, sections, shelf, bottom-sheet, phase-01.8.1, mobile-first]
---

# Sketch 063: Admin Game Editor

## Design Question
The shipped `GameLive.Form` (`/admin/juegos/:id/editar`) is a stacked daisyUI form: a filled primary "Publicar" beside
"Guardar cambios", Retirar/Restaurar as loose secondary buttons below the form, a `.modal` confirm, and a `bg-base-200`
box of BGG facts. This sketch applies the 059–062 decisions and tests one open question:
**where the lifecycle action lives** for each status (borrador / publicado / retirado).

Real data comes from `form.ex` and `Game.admin_changeset/2`:
- The changeset casts only name, units, weight_band, is_expansion, description and shelf_id.
- `section_ids` (manual sections only) are applied after save, and the featured cap raises `:featured_full`.
- D-04: Publicar saves pending changes, then publishes (`_action=publish`).
- D-08: Retirar is confirmed first, and Restaurar is `:retired → :published` only.
- D-03: the failed-enrichment alert has Reintentar.
- `Vocabulary.implied_weight_band/1` thresholds are used for the Nivel suggestion.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/063-admin-game-editor/index.html

- **Top bar:** variant (A/B/C) and **Estado** (Borrador / Publicado / Retirado, which reseeds the game).
- **Tools (bottom-left):**
  - theme
  - phone/desktop
  - **BGG:** Datos OK / Falló
  - **Destacados:** Con lugar / Lleno (20)

## Shared by all variants
- **Head.** A "‹ Juegos" drill-down back row (059 rule), then a 48px thumb, a 22px/700 title and a 12px meta line (year · BGG id).
  - The title shows the *saved* name. The shipped app only updates `page_title` on save.
  - Failed enrichment shows an inline error banner under the head, with a Reintentar text button.
- **DATOS DEL CLUB** holds exactly the six fields the changeset casts, and nothing else looks editable:
  - **Nombre:** outlined 44px field. Helper line: "Así aparece en la ludoteca. En BGG: “Brass: Birmingham”."
  - **Nivel:** a row that opens a picker sheet. The row's meta line teaches: "BGG sugiere **Nivel experto** · peso 3,86" or a green "Coincide con BGG".
    The sheet explains what a level is, gives each band's plain-Spanish description and marks "Sugerido por BGG". "Sin nivel" says it won't appear in any level row.
  - **Estante:** a row that opens a picker sheet (shelves in walking order + Sin ubicar). A divider, then an "Administrar estantes ›" row links to Estantes.
    Unplaced shows the pending orange dot + bold "Sin ubicar" (061 status convention).
  - **Unidades:** a row with a 72px number field.
  - **Es una expansión:** a switch.
  - **Descripción en español:** a textarea with "La leen los socios en la ficha del juego."
- **EN LA WEB:** yes, the editor shows which Web rows the game belongs to.
  - A status-aware note: a draft says rows apply once published; a retired game says it isn't visible.
  - Published only: a "Ver en la ludoteca" row (`/juegos/:slug`, external icon).
  - Every manual section is a **positive switch** row: "Destacados del club · 18 de 20 juegos", or "Oculta en el inicio · 3 juegos" for a hidden row.
  - The 20-game cap blocks the switch inline: "Destacados del club ya tiene 20 juegos. Quitá uno desde Web para sumar este."
    The shipped app only raised a flash after the rest of the form had saved.
  - Automatic rows are explained, not switchable: "Además aparece solo en **Ingenio estratega** (por su nivel) y **Recientemente añadidos**…"
- **DATOS DE BGG (read-only):** group label + "Ver en BGG ↗" text button, then a lock note: "Vienen de BoardGameGeek y se actualizan solos. No se editan acá."
  - A key/value list: 12px muted key, 13px value that wraps. No borders, inputs or chevrons, so it never reads as tappable.
  - Order follows the shipped `.list`: Jugadores, Duración, Edad mínima, Mecánicas, Temáticas, Diseñadores, Ilustradores, Editorial, Valoración, Ranking, Peso.
  - "Plegados" (tools) folds it behind one disclosure row.
- **Desktop:** club fields + web on the left, BGG facts as a **sticky 360px right column**. That's the literal answer to "sit next to".
- **Save:** outlined "Guardar cambios", disabled until something changes, with an accent "Cambios sin guardar" note beside it.
  - Validation runs on save only: "Poné un nombre." and "Unidades tiene que ser 1 o más." Errors clear as you edit.
  - Saving shows a spinner, then a "Cambios guardados" snackbar.
- **Leaving with unsaved changes** (‹ Juegos or any tab) opens the "CAMBIOS SIN GUARDAR" sheet: Guardar y salir / Descartar cambios (danger) / Seguir editando (focused).
- **Lifecycle, same rules everywhere:**
  - Publicar and Restaurar act immediately.
  - Retirar always goes through the in-sheet confirm, with Cancelar focused. The copy names the game and says it can be restored.
  - Any lifecycle change saves pending valid changes first ("Guardado y publicado") and shows a **Deshacer** snackbar.

## Variants (lifecycle placement only)
- **A: Fila de estado arriba → hoja.** An ESTADO group directly under the head holds one row: dot tile · **Borrador** / "Nadie lo ve en la web todavía" · muted hint "Publicar" · ›.
  - The row opens a sheet titled "ESTADO · Borrador": Publicar (the sub line says it also saves your changes) / Cancelar.
  - Published: "Retirar de la web ›" (danger) steps to the confirm in the same sheet. Retired: Restaurar / Cancelar.
  - Guardar cambios sits at the end of the club + web groups.
  - Status is the first thing you read. The action is two taps and never on the page itself.
- **B: Barra fija abajo.** A 60px bar sits on the tab bar.
  - Left: status (dot + label) with "Cambios sin guardar / Todo guardado". Right: one lifecycle **text** button (Publicar · red Retirar · Restaurar) + outlined Guardar.
  - On desktop the bar is sticky at the bottom of the content.
  - Save and lifecycle are always one tap away from any field, at the cost of 60px more bottom chrome (136px with the tab bar). The red "Retirar" also sits next to Guardar.
- **C: Al final del formulario.** Status goes in the head's meta line ("Retirado · 2018 · BGG 224517").
  - An ESTADO group is the very last block, after the BGG data: a static status row + one action row (Publicar with tinted eye tile, Retirar de la web › danger, or Restaurar).
  - This is the iOS "Eliminar contacto" pattern and the closest to the shipped layout. It's calm, but for a draft the main next step is at the bottom of a long page.

## What to Look For
- Draft: is it obvious the game isn't live yet and that Publicar is the next step? Compare A (top row), B (always in the bar) and C (meta line + bottom).
- Published: does Retirar feel safely out of the way (A: sheet, C: bottom) or dangerously close to Guardar (B)?
- Does the BGG block read as clearly read-only next to the club fields, on phone (stacked below) and desktop (right column)?
- Nivel's "BGG sugiere…" line: helpful teaching, or noise when staff chose on purpose?
- EN LA WEB: are switches the right control for section membership? Is the automatic-rows sentence clear to a new staff member?
- B's two bottom bars on a small phone: acceptable or too much chrome?

## Verification (build pass)
A scripted headless Chrome run passed 38 of 39 checks. The only failure was a `/favicon.ico` 404 from the static server root, not the sketch. It covered:
- All 3 variants × 3 statuses: no horizontal overflow at 375px or on desktop.
- A: dirty name → Publicar from the sheet saves then publishes ("Guardado y publicado"), and Deshacer returns to draft.
- A: the Retirar confirm step focuses Cancelar, then retires.
- Validation errors show on save and clear on edit.
- The leave guard opens with Seguir editando focused, and Descartar lands on Juegos.
- Band pick shows "Coincide con BGG", shelf pick works, the featured cap blocks the switch, and section switches mark the form dirty.
- B: the bar sits flush on the tab bar, shows dirty text, runs unit validation and saves. Retirar confirm → Restaurar appears in the bar. The last BGG fact is not covered by the bar.
- C: the publish sub line reflects dirty state.
- Failed → Reintentar recovers, and folded facts expand.

Screenshots were reviewed for phone light, phone dark, desktop and the sheets.

Fixed while building:
- The status row in A spanned both desktop columns. It moved into the left column.
- Dark mode: the unchecked switch looked "on" (lavender track) → muted track. The number spinner was light → `color-scheme: dark`.
- Sketch frame: focus/`scrollIntoView` scrolled the `overflow:hidden` device and uncovered off-screen sheets → the frame's scroll is pinned. The real app scrolls the page, so this is sketch-only.

**Still open:** the light-mode unchecked switch (from 062) is also lavender-tinted. Worth checking against daisyUI's `toggle` when implementing.

## Implementation notes
- Undo for Publicar is new backend work (`status_changeset(%{status: :draft})`), since there's no draft transition today. Undo for Retirar/Restaurar reuses existing functions.
- Lifecycle actions saving pending changes first extends the shipped Publicar behavior to Retirar/Restaurar, which currently ignore the form.
- The featured-cap check moves from save-time flash to toggle time. It still needs the server check (D-26) on save.
- The leave guard needs a `phx-hook` or a server-side dirty flag with an intercepted `navigate`. LiveView has no built-in unsaved-changes guard.
- On mobile, hide the tab bar (and B's bar) while a field has focus (059 note).

## Round 2: the editor looks like the game's public page (2026-09-15)
Developer: "Can the form looks closer to how the game is displayed? I think that will give better rythm."

Round 1 was a generic settings form: grouped rows, a key/value table for BGG data, and a 22px Inter title. Now the editor follows
`CatalogLive.Show` (sketches 032–043, `detail-page-layout.md`): the same order and components, with values copied from
`assets/css/app.css` (`.pk-facts-row`, `.pk-pill*`, `.pk-poster-panel`, `.pk-fact-col dt`, `.pk-bgg-*`, `.pk-detail-masthead`).

| Public page | Editor |
|---|---|
| Facts pills (players · time · level) in the poster panel | Same pills. **Nivel is the editable one:** accent tint with difficulty dots, and dashed "+ Nivel" when empty. It opens the Nivel sheet, with "BGG sugiere Nivel experto · peso 3,86" under the row. |
| Poster (1:1.05) | Same panel. The phone crops the poster to 16:10 so the title stays near the fold; desktop keeps 1:1.05. Failed BGG shows a dashed "Sin imagen de BGG". |
| Title, Bebas `text-3xl` | **Name edited in place in the same display type**, with a dashed underline and ✎. It focuses to a solid primary underline. |
| Section tags (`section_names`, `.pk-pill-tag`) | The same tags, exactly as members see them. "Editar filas" / "Elegir filas" opens the **Filas del inicio** sheet: switches, the 20-game cap error, the automatic-rows sentence and Listo. |
| Description (justified) | A textarea in the same 15px/1.5 justified text, under a public-style uppercase label. |
| Reservar (buy-box slot under the poster) | **EN EL CLUB:** Estante ›, Unidades, Es una expansión. These fields are never public. They sit under the poster on desktop and after the description on phone. |
| Fact grid: Año · Diseñadores · Ilustradores · Mecánicas · Temáticas as outline pills | Identical, but **read-only**, under one line: 🔒 "De BoardGameGeek · se actualiza solo" + Ver en BGG. It has no borders, inputs or chevrons. |
| Comunidad BGG: 8,6 Valoración · 3,86 Peso · #1 Ranking | Identical. |

- **"Guardar cambios"** follows the last editable block: after EN EL CLUB on phone, and under the description on desktop.
- **"Ver en la ludoteca ↗"** moved to the back row (published only).
- **Edad mínima and Editorial** aren't shown, same as the public page. Say so if staff need to check them here.
- **Lifecycle variants A/B/C are unchanged** and still open. B's bar now reads as the admin twin of the public mobile Reservar bar.

Fixed while building:
- 062's `.empty` empty-state class clashed with the empty pill/poster: 36px icons and centered padding → renamed `is-empty`.
- The Nivel pill wrapped to a second line (8–11px over) → dropped the ▾. The tint is the cue, and the 44px hit area is vertical-only so it no longer causes overflow.
- On desktop the pill spilled past the 20rem panel → wraps like the public desktop row.
- The sticky poster column slid over the desktop tab row and hid EN EL CLUB mid-scroll → no longer sticky, and tabs sit on `z-index` 19.
- The editable pill in dark mode read like a read-only one → accent border.

Verified in headless Chrome: 38 of 39 checks pass, and the only failure is the static server's `/favicon.ico` 404. Checks cover:
- All variants × statuses, with no overflow on phone or desktop.
- Pills fit on one line on phone for every level, and stay inside the panel on desktop.
- The sections sheet: the cap blocks the switch, and switching a row on shows its tag under the title and marks the form dirty.
- The BGG block has no controls apart from Ver en BGG.
- Publish, retire, restore and undo; the leave guard; validation.

Screenshots were reviewed for phone light, phone dark, desktop and the sheets.

## Round 3: B picked, fewer lines (2026-09-15)
Developer: "B feels better, but still I found the form complex full of lines and dividers."

**Lifecycle placement: B (Barra fija abajo) ★ picked.** It's now the default tab. A and C stay in the file for comparison.

Round 2 had 25 bordered elements in the page body: the poster panel border and shadow, the title's dashed underline, the textarea and number strokes,
EN EL CLUB's group borders and row dividers, the divider above the BGG block, outline pills, and the bar's top border. Round 3 compares two ways to remove them
(top bar → "Ronda 3 · menos líneas"; R2 is still there):

- **B1: Sin líneas.** No strokes or dividers. Whitespace and the public-style uppercase labels (DESCRIPCIÓN, EN EL CLUB, AÑO…) separate the groups.
  - The poster sits bare under the pills (proximity only, the sketch 037 principle).
  - The title shows no underline until hover or focus (✎ stays as the cue).
  - The description and Unidades become filled fields that get a primary stroke only on focus.
  - EN EL CLUB rows are separated by spacing, and the BGG pills are filled instead of outlined.
  - The bottom bar lifts with a shadow instead of a border.
- **B2: Bloques suaves.** Same as B1, but groups become soft tinted blocks with no strokes: the poster panel, EN EL CLUB (rows inside, no dividers) and the BGG block. The pills inside the blocks are white.

Measured: bordered elements in the page body went 25 → 1 in both versions. The one left is the Nivel pill's accent outline, which is kept on purpose as the edit cue.
No overflow on phone or desktop, light or dark, and zero JS errors. The existing test script still passes.

Copy: the read-only line is shortened to "Datos de BGG · no se editan" so it stays on one line on phone.

## Final design: B + B2, other variants removed (2026-09-15)
Developer: "B2 feels better. Remove the another variants and let me check again."

`index.html` now holds only one design. A, C, R2 and B1 were never committed, so the rounds above are their only record. The top bar switches Estado only.
- **Layout:** the Round 2 mirror of the public game page.
- **Lifecycle:** B's bottom bar (status + "Cambios sin guardar / Todo guardado" + Publicar · Retirar with an in-sheet confirm · Restaurar + outlined Guardar).
- **Surfaces:** B2's soft blocks. The poster panel, EN EL CLUB and the BGG data are tinted `surface` blocks with no strokes. Fields are filled and get an outline only on focus.
  - The failed-BGG banner is now fill-only too.
  - The only stroke left in the page body is the Nivel pill's accent outline.

Cleanup while removing variants:
- The unprefixed final CSS lost to earlier Round 2 rules (same specificity, earlier in the file) and brought 4–5 strokes back → moved the block to the end of the stylesheet.
- Dead code for the A status row/sheet, C's Estado group and the inline save row was deleted.

Verified in headless Chrome with a fresh test script, 32 of 32 checks passing (favicon 404 ignored):
- Every status: no overflow on phone or desktop, ≤1 stroke in the body, the right lifecycle button in the bar.
- Publicar saves then publishes → Deshacer. The Retirar confirm focuses Cancelar → Restaurar.
- Validation; the leave guard → Juegos (no bar there).
- The Nivel/Estante pickers; the sections sheet cap and the tag under the title.
- Failed → Reintentar; the bar never covers the BGG block; zero JS errors.

Screenshots were reviewed for phone light, phone dark, desktop and the failed state.

## Round 4: title first, BGG suggestion in the sheet, one pencil rule (2026-09-15)
Developer:
- "The title first, then bellow the image block."
- "What the BGG suggest as weight is inside the bottom sheet, not on the block."
- "I like the pencil icon as affordance… Should that be consistent. Maybe the pencil can be polished to improve its balance."

- **Order:** ‹ Juegos → **title + section tags** → image block (pills + poster) → description → EN EL CLUB → BGG data. On desktop the title and tags span the full width above the two columns.
- **BGG weight suggestion** is removed from the block. It lives only in the Nivel sheet ("El peso en BGG (3,86) sugiere **Nivel experto**" + "Sugerido por BGG" on that option). The Nivel pill is now a plain pill like its neighbours, and the pencil is its only cue.
- **Pencil rule (answer: yes, consistent):** ✎ marks every value shown the way members see it that turns editable on tap.
  - **Título:** the input sizes to its text through an inline-grid mirror, so ✎ follows the name instead of parking at the far edge. ✎ hides while typing.
  - **Nivel pill:** ✎ inside the pill.
  - **Filas:** the whole tag line is the button, with ✎ after the tags ("Sin filas elegidas ✎" when empty). This replaces the "Editar filas" text button.
  - **Descripción:** now reads like the public justified paragraph, with ✎ after the last word. Tap it → filled text box, blur → paragraph again.
  - **Estante:** ✎ replaces the chevron.
  - **Real controls get no pencil** (the Unidades number, the Expansión switch): the control is already the affordance, and a ✎ there would be noise.
- **Pencil polish.** The 24px outline pencil read thin and floated at the field edge. It's now the heroicons 16 *solid* pencil, in accent-text color, sized to the text it follows (title 16px, rows 13px, pill 10px). Two treatments to compare (top bar → "Lápiz"):
  - **P1: Glifo:** the bare solid glyph.
  - **P2: Círculo suave:** the same glyph in a soft accent circle (28px title, 22px rows). The pill keeps the bare glyph, because a circle inside a pill overflowed the row and looked nested.

Fixed while building: with ✎ inside it, the Nivel pill overflowed the phone pill row by 12–14px ("Descubre el hobby" / "Ingenio estratega") → phone panel padding 12px, pill gap 4px, Nivel pill padding 7–8px. Measured: every level fits.

Verified in headless Chrome, 39 of 39 checks (favicon 404 ignored). On top of the Round 3 checks:
- The title block sits above the image block, and the title pencil follows the name.
- No BGG hint on the block.
- Tap description → textarea focused; blur → paragraph with the edit, dirty.
- ✎ present on title, Nivel, filas, descripción and estante, with no chevron on Estante.
- P2 has no overflow and its pills fit.

Screenshots were reviewed for P1/P2 phone, desktop and dark.

## Round 5: EN EL CLUB lighter (2026-09-15)
Developer: "En el club block and its content looks big breaking the balance."

The Round 4 block (180px on phone) used full settings rows: 15px labels, a 72×44px white number box and a 44×26px switch. It was visually heavier than
the description above and the BGG block below. Top bar → "Ronda 5 · En el club":
- **Actual:** Round 4 (180px).
- **C1: Como la ficha:** the BGG block's anatomy, so the two soft blocks read as a pair (159px).
  - Small uppercase labels over plain 15px values.
  - ESTANTE spans the full width: "Estante B — estrategia ✎", tap for the sheet.
  - UNIDADES and EXPANSIÓN sit side by side. Unidades is a compact − 1 + stepper: 26px round buttons with a 44px hit area, "−" disabled at 1, and the number is still typeable.
  - Expansión is a small 36×22 switch with a "Sí/No" label.
- **C2: Filas compactas:** the same three rows at 40px, 14px labels, a 52×30 number field and the small switch (152px).

Verified: 44 of 44 checks (favicon ignored).
- The C1 stepper + → 3 marks the form dirty, and − stops at 1 (disabled).
- The C1 switch shows "Sí".
- No overflow in any of the three options.
- Screenshots for C1 and C2 on phone, C1 in dark.

## Round 6: P2 + C2 picked; one section anatomy, inline Estado, BGG collapsed (2026-09-15)
Developer:
- "P2 and C2. But the field label should improve its balance to be noticed. Same for boxes. Must to enforce consistency to keep rhtym."
- "Since bgg data is 'sync' externally and can't be 'edited' should be collapsed and the beginning?"
- "Also the 'stycky' at bottom 'state' could be below the description, leavning the collapsed bgg data at the very bottom."
- "Remove the rest of variants and show that as a new variant."

**Removed:** P1 (bare glyph), C1 (fact-grid club block) and the Round 4 "Actual" club rows. The top bar has two tabs:
- **R5 (baseline):** the P2 pencil in a soft circle, C2 compact club rows, the sticky bottom bar. Round 4 order.
- **R6 (new, default):**
  - **One section anatomy, enforced:** every section is a **label (13px / 700, full text color) above a soft box** (surface fill, radius-lg, 12/16px padding; row boxes 4px + 16px rows), with **24px between every section**. It applies to Portada, En el club, Descripción, Estado and Datos de BGG. Verified by computed style: the 5 labels are identical, the 5 boxes are identical, and every gap is 24px.
    - Round 5's 12px uppercase muted labels were too quiet.
    - The labels inside the BGG box (Año, Diseñadores…) keep the public small-caps `dt` style, because they label values, not sections.
  - **Order (phone):** título + filas → Portada → **En el club** → Descripción → **Estado** → **Datos de BGG**.
    - En el club moved above the description so every editable field comes before Guardar.
    - Desktop: the Portada column on the left; En el club, Descripción and Estado on the right; Datos de BGG full width below.
  - **Estado inline:** the former sticky bar content (status · Cambios sin guardar / Todo guardado · Publicar / Retirar / Restaurar · Guardar) sits in its own box right below the description. There's no sticky chrome, so only the tab bar sits at the bottom.
  - **Datos de BGG collapsed at the very bottom:** one disclosure row (🔒 "Sincronizados con BoardGameGeek · No se editan acá · año, autores, mecánicas y más" ⌄) expands to the fact grid, Comunidad BGG and "Ver en BoardGameGeek ↗".
    - The developer asked "at the beginning?" and then placed it at the very bottom. Bottom is what's built: it's reference data you rarely check while editing.
  - The description sits in its box as the public paragraph with ✎ (tap → textarea in the same box). The club rows have no dividers.

Trade-off to watch: with Estado no longer sticky, editing the title at the top means scrolling down to Guardar. The unsaved-changes guard on leaving still catches forgotten saves.

Verified in headless Chrome, 26 of 26 checks (favicon 404 ignored):
- Only the R5/R6 switches exist, and R6 has no sticky bar.
- The order holds in all 3 statuses, with no overflow.
- Labels, boxes and gaps are identical (computed), and the club rows have no dividers.
- BGG is collapsed by default and expands to 4 fact columns.
- The inline Estado reflects dirty state, and publish saves, then publishes. The retire confirm focuses Cancelar.
- Description box edit and units validation.
- The BGG suggestion appears only in the Nivel sheet.
- Failed state; dark; desktop with no overflow; R5 baseline intact.

## Winner: R6, grouped by visibility (2026-09-15)
Developer: "R6 is better. Remove the rest. Be sure to have the 'sections' correctly into the form: all what is public and 'private/internal' together."

`index.html` now holds only R6. The R5 baseline and its dead helpers were removed, and no variant switches are left (the top bar switches Estado only). Sections are grouped by who sees them:

- **EN LA WEB** (👁 "Lo ven los socios en la ficha"): título + filas → Portada → Descripción → Datos de BGG (read-only, collapsed, last in the group).
- **SOLO PARA EL CLUB** (eye-slash icon, "No se muestra en la web"): En el club → Estado. Estado, with the lifecycle action and Guardar, is always the last thing on the page.

Changes from Round 6:
- Datos de BGG moved into the public group because members see that data on the game page. Round 6 had it at the very bottom of the page; it's now at the end of its group.
- Estado moved into the internal group, still after every editable field.

Group header: a 28px tinted icon circle, a 15px/700 title and a 12px muted explanation on one line. That's one step above the 13px/700 section labels, with 40px before the internal group and 24px between sections inside a group.
Desktop: public group = full-width title, Portada on the left, Descripción + Datos de BGG on the right. Internal group = En el club on the left, Estado on the right.

Verified in headless Chrome, 29 of 29 checks (favicon 404 ignored):
- Single design; order and group membership hold in all 3 statuses.
- Section labels and boxes are identical (computed); 24px gaps inside groups.
- No sticky bar; BGG collapses and expands.
- Inline Estado dirty state, publish, retire confirm; description box edit; units validation; the BGG suggestion only in the Nivel sheet.
- Failed state; dark; on desktop the internal group sits below the public group; no overflow.

### Carry forward to the gap-closure plan (GameLive.Form)
- **Mirror `CatalogLive.Show`:** reuse its pill / poster / fact-grid components. Don't style a separate form.
- **Visibility groups:** EN LA WEB first, SOLO PARA EL CLUB second. Inside each group, a section = a 13px/700 label over a `surface` box (radius-lg, 12/16px padding). No borders or dividers in the page body.
- **✎ rule:** a soft-circle solid pencil on every value shown the way members see it (title, Nivel pill, filas, descripción, estante). Real controls (Unidades number, Expansión switch) get none.
- **Editing in place:**
  - The title is edited in place in display type; the input sizes to its text.
  - The description is a paragraph that turns into a textarea on tap.
  - Nivel, Estante and filas open 059 bottom sheets. The BGG weight suggestion lives only in the Nivel sheet.
- **Estado box:** status + "Cambios sin guardar / Todo guardado" + the lifecycle text button (Publicar / Retirar → in-sheet confirm / Restaurar) + outlined Guardar. Every lifecycle change saves pending changes first and offers Deshacer.
- **Datos de BGG:** read-only, collapsed disclosure: 🔒 "Sincronizados con BoardGameGeek".
- **Unsaved-changes guard** on leaving: needs a hook, since LiveView has none built in.
- **Still open:**
  - The light-mode unchecked switch tint (from 062).
  - iOS focus-zoom on fields under 16px (061 note).
  - Deshacer for Publicar needs a draft transition.

## Round 7: tabs vs jump control for the two groups (2026-09-15)
Developer:
- "The 'filas' needs to be meanninfu.. And the sections are clear."
- "What if we use 'TABS | TABS' for that? what is standardt for this? My only concern is that WHat we're editing could be lost."

Built on the committed R6. The top bar has "Ronda 7 · dos partes". Shared by both:
- **Filas wording:** "**En el inicio:** Destacados del club ✎". Empty: "No aparece en ninguna fila del inicio ✎". The sheet is "Filas del inicio", using the same words as the Web tab.
- **Title + filas stay above the control** as the page identity (always visible).
- **One segmented control** (👁 En la web | eye-slash Solo para el club), sticky under the header on phone and under the tab row on desktop. It gets a soft shadow once stuck.

Variants:
- **T1: Pestañas.**
  - Both panels are in ONE form, and switching only toggles `hidden`. In LiveView this is `JS.show/hide` (or a client-only assign) inside the same `<.form>`, never separate routes/LiveViews. So nothing typed is lost.
  - A purple dot marks a tab with unsaved changes, and a red dot marks a tab with errors. Saving with an error in the hidden tab switches to it and focuses the field.
  - Estado (lifecycle + Guardar) is shared below both panels. A sub-line explains the current tab.
  - `role="tablist"`, with arrow keys switching tabs. Switching while stuck scrolls so the panel starts right under the control.
- **T2: Salto (todo visible).**
  - Nothing is hidden: the R6 page with the group headers. Tapping a segment smooth-scrolls to the group, and a scroll-spy highlights the group you're in.
  - The last group gets a min-height so a jump can bring it to the top on a short page. Without it, the page ends first and the group lands mid-screen (caught by a test). The cost is empty space at the bottom when you jump there.

Verified in headless Chrome, 26 of 26 checks (favicon 404 ignored):
- **Filas wording:** filled and empty.
- **T1:** no overflow in 3 statuses. Panel visibility and the shared Estado work, and edits survive switching tabs (description + units). Dots behave correctly: unsaved changes in En la web, unsaved changes in Solo para el club, and an error that auto-switches to its tab and focuses the field. Saving clears the dots, and arrow keys work.
- **Both:** the control sticks under the header, and a tab switch while stuck shows the panel start.
- **T2:** nothing hidden; the tap jumps to the group and highlights it; the scroll-spy updates at the top and at the end; tapping back scrolls up.
- **Other:** dark; desktop sticky under the tab row for both variants; no JS errors.

Fixed while building:
- 062's `.seg.two` 24px bottom margin left a blank strip under the control.
- The "En el inicio:" line sat 2px left of the title edge.

## Round 8: no tabs, three ways to separate public vs internal (2026-09-15)
Developer: "neither feels correct. Alternatives without tabs?" → "build all three variants"

R7 (T1 tabs / T2 jump control) is rejected and removed; its description above is the only record. Built on R6 with the "En el inicio:" filas wording.
The top bar has "Ronda 8 · sin pestañas":

- **V1: Contenido + barra lateral** (Shopify / WooCommerce / WordPress "Publicar" box, the standard admin editor pattern).
  - **Desktop:** a wide public column (title, filas, Portada | Descripción + Datos de BGG) and a sticky 320px sidebar on a faint neutral ground. The sidebar has a caption "Solo para el club / no se muestra en la web", then **Estado first** (Publicar/Retirar/Restaurar + Guardar), then En el club.
  - **Phone:** the sidebar stacks after the content under the same caption, with En el club, then Estado, so Guardar ends the page.
- **V2: Zona interna con otro fondo.** One continuous page. Everything public sits on the normal ground. The internal part (En el club + Estado) sits in a **full-bleed muted neutral band** that starts with the same caption and runs to the end of the page.
  - The boxes inside the band turn white, so they contrast with the band.
  - You can tell you've left "the game page" by the background alone.
  - Desktop: En el club | Estado side by side inside the band.
- **V3: Resumen interno arriba.** Under the title and filas, one muted line summarizes everything internal: "● Publicado · Estante B · 2 unidades" + "Solo para el club", with ✎ and a "cambios sin guardar" note when internal fields are dirty.
  - Tapping it opens a sheet: "SOLO PARA EL CLUB · NO SE MUESTRA EN LA WEB" → the status → the lifecycle row (Publicar / Retirar de la web › confirm step / Restaurar) → EN EL CLUB (Estante › picker that returns to this sheet, Unidades, Expansión) → Listo.
  - The page below is the pure public preview, ending with a save box ("Cambios sin guardar · Guarda todo lo del juego, también lo del club" + Guardar).
  - A units error on save reopens the sheet.

Verified in headless Chrome, 30 of 30 checks (favicon 404 ignored):
- **All variants:** no overflow in 3 statuses × 3 variants on phone and desktop; filas wording kept.
- **V1:** phone order is content → the club part; desktop sidebar on the right with Estado first, and it stays sticky on scroll.
- **V2:** the band is full-bleed, tinted, and holds En el club + Estado.
- **V3:**
  - The strip sits between the title and Portada, with no internal sections on the page.
  - Editing in the sheet updates the strip and the save box, and the estante picker returns to the sheet.
  - A units error reopens the sheet; Publicar from the sheet saves then publishes.
  - The retire confirm step focuses Cancelar.
- **Other:** dark; no JS errors.

Polish while building:
- The V1 sidebar caption now uses two lines.
- The V2 band goes full-bleed on desktop (box-shadow + clip-path).
- The V3 sheet's status dot aligns with the 28px row slot.

## Winner: R8 V2, internal zone on a different background (2026-09-15)
Developer: "v2 is better".

`index.html` now holds only V2. V1 (sidebar) and V3 (summary strip + sheet) and their code are removed, as are R7's tabs and jump control. None of them were committed; the rounds above are their record.
The top bar switches Estado only.

**Final page (phone):**
- ‹ Juegos … Ver en la ludoteca ↗
- Name edited in place in Bebas ✎ → "En el inicio: Destacados del club ✎" (or "No aparece en ninguna fila del inicio ✎")
- **Portada:** pills with the Nivel pill ✎ + poster
- **Descripción:** the paragraph with ✎; tap → textarea
- **Datos de BGG:** 🔒 "Sincronizados con BoardGameGeek" collapsed; opens to the fact grid, Comunidad BGG and Ver en BoardGameGeek
- **Full-bleed muted band** (rounded top), captioned "Solo para el club · no se muestra en la web":
  - **En el club:** Estante ✎, Unidades, Es una expansión
  - **Estado:** status · Cambios sin guardar / Todo guardado · Publicar / Retirar (in-sheet confirm) / Restaurar · Guardar

**Desktop:** Portada on the left, Descripción + Datos de BGG on the right. The band runs the full width with En el club | Estado side by side.

Verified in headless Chrome, 30 of 30 checks (favicon 404 ignored):
- Single design with no leftovers.
- In every status: no overflow, zero lines in the page body, the order title → portada → descripción → BGG → band (club → estado), and the band holds only club + estado.
- The band is full-bleed; section labels are identical.
- Flows: dirty state; Publicar saves + publishes → Deshacer; Retirar confirm focuses Cancelar; BGG suggestion in the Nivel sheet; estante pick; description edit; units validation focuses the field; leave guard; BGG expands.
- Failed state; dark; desktop with no overflow and club | estado side by side in the band.

### Carry forward to the gap-closure plan (GameLive.Form), replacing the R6 list above where it differs
- **Two zones by background:** public content on the page ground mirrors `CatalogLive.Show`. Internal content (`shelf_id`, `units`, `is_expansion` + the lifecycle/save box) sits in one full-bleed muted band captioned "Solo para el club · no se muestra en la web". It's the last thing on the page, and Guardar is the last control.
- **No tabs, no jump control, no sticky save bar.** Nothing is hidden, and one `<.form>` wraps both zones.
- **Everything else from R6 stands:**
  - The section anatomy: a 13px/700 label over a soft box, 24px apart, white boxes inside the band, no lines.
  - The ✎ soft-circle rule and in-place title/description editing.
  - The Nivel/Estante/Filas sheets, with the BGG suggestion only in the Nivel sheet.
  - Datos de BGG collapsed; lifecycle saves first + Deshacer; the unsaved-changes guard.
- **Filas wording:** "En el inicio: …" / "No aparece en ninguna fila del inicio". The sheet is "Filas del inicio".
- **Still open:** the light-mode unchecked switch tint (062); iOS focus-zoom on fields under 16px (061); Deshacer for Publicar needs a draft transition.

## Round 9: where the game shows + Unidades control (2026-09-15)
Developer: "better representation of the sections where a game can be found" and "Replace 'copias' for unidades. A pick number isn't too mobile friendly. Also the values could be 1 (99% of the times) and rarely more than 2."

Built on the committed V2; everything under "Winner: R8 V2" still stands. The top bar has two independent switches. "Sections" is read as the **home rows** ("filas", the manual sections + the automatic level and recent rows), not the physical Estante.
"Copias" didn't appear anywhere in the sketch or the app (`form.ex` already labels it "Unidades"). The wording is now "1 unidad / N unidades" everywhere, and a check fails if "copia" ever shows up.

**Filas** (shared data: home order Destacados → the 3 level rows → manual rows → Recientemente añadidos; hidden manual rows never show on the home):
- **F1: Etiquetas.** The same line under the title, now listing every row: manual rows as accent tags, automatic ones as muted ✦ tags, plus a key line "✦ automática, por su nivel o por ser nuevo · y en 1 fila oculta". The lead is status-aware ("Al publicarlo, en el inicio:" / "Retirado. Al restaurarlo, en el inicio:"). This is the least change, but on a phone it wraps to 2–3 lines.
- **F2: Lista.** The line under the title is gone; there's a new **En el inicio** section after Descripción (desktop: right column, under Descripción). The box has one row per home row the game is in, with a slot icon (★ Destacados, list for manual, ✦ automatic), the name, and why it's there ("Elegida a mano · 18 de 20 juegos", "Automática · cambia con el Nivel", "Automática · mientras sea de los 20 más nuevos", "Elegida a mano · fila oculta en el inicio").
  - Manual rows carry ✎ and open the Filas del inicio sheet. Automatic rows are static.
  - The last row, "+ Sumar a otra fila ›", opens the same sheet.
  - A draft or retired game gets a note at the top of the box, and retired rows are dimmed.
- **F3: Mini inicio.** The same section drawn as the home page in miniature: all 7 home rows in order, each with a strip of cover tiles (5 on phone, 9 on desktop), the game's cover marked (taller, ringed) in the rows it's in, plus a short why ("Elegida a mano / Por su nivel / Por ser de los más nuevos").
  - Rows it isn't in stay visible but muted, which teaches that only one level row applies.
  - A hidden-row membership is a sentence under the list. The "+ Elegir filas a mano ›" row opens the sheet.
  - Draft: grey ring. Retired: greyscale cover + note.

**Unidades** (no typed number field anymore; `units` still casts as an integer ≥ 1, so the "Unidades tiene que ser 1 o más" error can't happen from the UI):
- **U1: Stepper.** A "− 1 +" control in the En el club row: 32px soft-fill circles with 44px hit areas, and − disabled at 1. When − disables, focus moves to +.
- **U2: 1 | 2 | Más.** A segmented control in the row (iOS-style, no strokes). "Más" sets 3 and turns the third segment into an inline "− 3 +" stepper. Stepping below 3 folds back to the "2" segment.
- **U3: Hoja.** A "Unidades · 1 unidad ✎" value row (same anatomy as Estante), opening a sheet: "Cuántas cajas de este juego tiene el club." → 1 unidad (Lo más común) / 2 unidades / 3 o más (turns into a stepper row) → Listo.

Verified in headless Chrome, 75 of 75 checks (favicon 404 ignored):
- **Layout, every Filas variant × every Estado:** no overflow and zero lines. The order is título → portada → descripción → (en el inicio) → BGG → band (club → estado). Filas appear in exactly one place, always in the public part, and section labels are identical.
- **Filas:** F1 pills show manual vs ✦ automatic, and the draft lead is correct. F2 rows follow home order, manual rows are editable while automatic ones explain why, changing Nivel moves the level row, and Sumar adds a row. F3 shows 7 rows with 3 marked, the tile columns line up, and the retired note + hidden row appear.
- **Unidades:** no "copia" wording in any variant.
  - U1: − disabled at 1, dirty state, focus handoff, hit-area room.
  - U2: default 1, tap 2, Más → stepper, folding back to 2.
  - U3: value row, sheet, pick 2, 3 o más → stepper.
- **All V2 flows still pass.** The units validation check became a name validation check.
- Dark (F2/F3/U2/U3) and desktop (all three Filas) show no overflow, with club | estado side by side.

**Winner: F2 + U2** (developer: "F2 + U2"). F1, F3, U1 and U3 are removed in Round 10; this section and the Round 9 commit are their record.

Fixed while building:
- The new state modifier `st-draft` collided with the existing bold `.st-draft` status label, so it's renamed `fst-*`.
- F1's ✎ wrapped onto its own line, so it moved inside the tag list.
- The marked tile in F3 was wider and pushed its row's tiles out of line, so it's now taller only (there's a check for this).
- Static rows in a box no longer tint on hover (the U2 segmented track disappeared).
- `verify.js`'s `scrollTo` ignored the current scroll position, so screenshots after the first scroll were framed wrong.

## Round 10: a divider instead of the grey band (2026-09-15)
Developer: "F2 + U2. But now I need the 'full gray' area for internal stuff be improved. That gray is weird and breaks balance. What some kind of divider?"

Round 9 is committed with F2 + U2 marked ★ (`295eba2`). F1, F3, U1 and U3 and their code are now removed from `index.html`.
The top bar has one switch, **Separador**. In D1–D3, En el club and Estado sit on the normal page ground with the **same surface boxes as the public part**; only a divider marks the switch to internal content. This lifts R8's "no lines" rule for this one divider. The line is a 1px background, not a border, and spans the content width (not full-bleed).
- **D1: Línea con rótulo.** A hairline with a centered "eye-slash Solo para el club" label on it, and "No se muestra en la web" centered below. 44px above, 20px below.
- **D2: Línea + encabezado.** A plain hairline, then the R6 group header (28px icon circle, 15px/700 "Solo para el club", 12px "No se muestra en la web"). It reads as a new chapter, with the most weight of the three.
- **D3: Rótulo + punteado.** The label comes first, left-aligned, then a dotted line runs to the right edge, with "No se muestra en la web" under the label. It's the lightest; the dots hint at "off the public page".
- **V2: Banda gris.** The R8 band, kept for comparison.

**Winner: D1** (developer: "D1").

Also fixed: the Unidades segmented track was invisible once its box sat on the page ground (the track and box shared the surface color). Off the band, the track is now surface-2 with a bg thumb; dark mode has its own tones.

Verified in headless Chrome, 84 of 84 checks (favicon 404 ignored):
- **Every divider × Estado:** no overflow, no border lines, the section order, and the internal part holds only club + estado.
- **D1–D3:** no band background and the internal boxes match the public boxes; the divider spans the content width; the caption wording; the segmented track stays visible. D0 is still full-bleed.
- **Kept:** the R9 checks (En el inicio rows, Nivel moves the level row, Sumar, the retired note; Unidades 1 → 2 → Más stepper → back to 2; no "copia") and all V2 flows.
- Dark and desktop for every divider, with club | estado side by side.

## How to verify (headless)
`verify.js` in this folder is the headless-Chrome check for V2 + R9 (F2/U2) + the Round 10 dividers. It runs 84 checks:
- **Layout:** no overflow in every status, zero lines in the page body, section order, the band holds only club + estado, the band is full-bleed, identical labels.
- **Flows:** publish → Deshacer, retire confirm, Nivel/Estante sheets, description edit, units validation, leave guard, BGG expand, failed → Reintentar.
- **Rounds 9–10:** every divider × Estado, divider width and caption, En el inicio rows, the 1 | 2 | Más control, and no "copia" wording.
- **Views:** dark and desktop.

```
python3 -m http.server 8765 &          # from the repo root
node .planning/sketches/063-admin-game-editor/verify.js
```

It uses the system Chrome (`channel: 'chrome'`) and finds `playwright-core` in `node_modules` or the npx cache; set `PLAYWRIGHT_CORE` to override.
Screenshots go to `$SHOTS_DIR` (default `<tmp>/sketch-063-shots`). The exit code is 1 if any check fails.

When refining, update the assertions that encode a rule you change (for example, the order check or the "zero lines" check) instead of deleting them.
