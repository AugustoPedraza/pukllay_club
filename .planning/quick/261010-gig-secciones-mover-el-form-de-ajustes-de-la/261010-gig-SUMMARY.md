---
quick_id: 261010-gig
date: 2026-10-10
status: complete
commit: 49727d02
tasks_completed: 3
tasks_total: 3
---

# Quick 261010-gig — SUMMARY

/ admin/secciones now opens with **neither** of its two forms on the page.

## What changed

**Task 1 — the destacada's settings are a sheet.** The `Ajustes`
`section_panel` is gone. `#web-destacada-name` now sits inside
`#web-destacada-name-button` (`aria-haspopup="dialog"`,
`phx-click="open-edit-sheet"`), which opens `#web-edit-sheet` ("Editar fila",
subtitled with the row's name) holding `#web-ajustes-form` verbatim — Nombre,
Subtítulo, the `#web-ajustes-shown` checkbox and the a1 `Guardar`, on the same
`phx-change="validate"` / `phx-submit="save"` events and the same
`normalize_ajustes_params/1` inversion. A successful save closes the sheet; a
validation error keeps it open. Opening re-reads the destacada, so an abandoned
edit does not return on the next open. The name field opts into the
`AdminSheet` hook's `data-pk-sheet-autofocus`.

**Task 2 — create is a "+" beside the title.** The `Nueva fila`
`section_panel` is gone. `<h1>Web</h1>` now lives in a `.pk-admin-web-head`
row with a trailing a3/terciaria `hero-plus` action
(`aria-label="Nueva fila"`, `phx-click="open-create-sheet"`) that opens
`#web-create-sheet` holding `#create-section-form` — name only, same `create`
event, same `@name_error` surfacing, same `push_navigate` to the new section.
Opening clears the field and any stale error. `Ordenar filas` was left in the
`Otras filas` header, untouched.

**Task 3 — tests.** Two helpers (`open_edit_sheet/1`, `open_create_sheet/1`)
now front the seven existing cases that drove either form, plus a new describe
block, *"neither form is open at rest"*, covering: no form in the DOM on mount;
the name trigger's `aria-haspopup="dialog"` and the `+`'s
`aria-label="Nueva fila"`; the form appearing only after its trigger; save
closing the edit sheet and a blank name keeping it open; closing the create
sheet putting the form away; and a name error not surviving a reopen. The
`id="web-destacada-name"` count-of-one assertion is re-checked both at rest and
with the sheet open.

**CSS** (`assets/css/admin/screens.css`): added `.pk-admin-web-head` (the same
flex anatomy `.pk-admin-web-otras-header` already uses on this screen) and
`.pk-admin-web-destacada__name-button` (button reset, so the 17/600 rank stays
on the `<p>`); added `.pk-admin-web-sheet-form .pk-admin-action` for the
full-width in-sheet commit, following `.pk-editor-sheet-save`'s shipped
pattern; deleted the now-dead `.pk-admin-web-ajustes`, `.pk-admin-web-create`
and `.pk-admin-web-create-form`.

## Verification

- `mix quality` — **2033 tests, 0 failures** (format incl. Styler, credo
  `--strict`, sobelow, hex/deps audits all green).
- The resting-state guard was negative-tested: forcing `:edit_sheet` to `true`
  in `mount/3` turns the new describe block red (2 failures), so the refutes
  are falsifiable rather than vacuous.

## Notes / follow-ups

- Sketch 070's intermediate `rowSheet()` options list (Destacar / Cambiar la
  destacada / Editar la fila) is still not built — tapping the name goes
  straight to the settings form. That remains the sketch's own decided shape
  for later.
- The sketch also puts `Ordenar filas` in the page header next to the `+`;
  this screen still keeps it in the `Otras filas` header. Deliberately out of
  scope here.
- The create sheet has no Subtítulo field (parity with the panel it replaced);
  the sketch's `nameSheet()` offers one on the new-row side.
