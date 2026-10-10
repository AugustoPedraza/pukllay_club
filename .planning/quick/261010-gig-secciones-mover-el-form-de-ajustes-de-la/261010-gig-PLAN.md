---
quick_id: 261010-gig
date: 2026-10-10
mode: quick
status: planned
description: >
  Secciones: move the destacada's inline Ajustes form into a bottom sheet opened by
  tapping the section name, and the inline Nueva fila create form behind a "+" icon
  button to the right of the page title.
files_modified:
  - lib/pukllay_club_web/live/admin/section_live/index.ex
  - assets/css/admin/screens.css
  - test/pukllay_club_web/live/admin/section_live_test.exs
---

# Quick 261010-gig — Secciones: both forms behind a tap

## Why

`/admin/secciones` renders two forms permanently open on the page: the destacada's
`Ajustes` panel (`#web-ajustes-form`) and the `Nueva fila` panel
(`#create-section-form`). The developer tested the shipped screen and asked for
neither to be open at rest: the edit form belongs in a bottom sheet opened by
tapping the section name, and create belongs behind a `+` icon at the right of the
title.

This is the shape sketch **070-web-destacados** already decided and the shipped page
diverged from:

- `.phead` — `<h1 class="ptitle">Web</h1>` plus a trailing `.hacts` icon row, where
  `data-act="newrow"` is a `+` button with `aria-label="Nueva fila"`.
- `.fname` — the row's name is a `button` (`data-act="rowopts"`,
  `aria-haspopup="dialog"`), not static text.
- `nameSheet()` — the row's name/subtitle edited in a sheet titled `Editar fila`
  (`Guardar`) or `Nueva fila` (`Crear fila`).

So this is a presentation move onto an already-decided artefact, not a new design.

## Tasks

### Task 1 — the destacada's Ajustes form moves into an `Editar fila` sheet

**files:** `lib/pukllay_club_web/live/admin/section_live/index.ex`,
`assets/css/admin/screens.css`

**action:**
- Drop the `AdminComponents.section_panel` labelled `Ajustes` (and its
  `.pk-admin-web-ajustes` rule) from the page body.
- Make `#web-destacada-name` a `button` carrying `aria-haspopup="dialog"` +
  `phx-click="open-edit-sheet"`, keeping `id="web-destacada-name"` on the element the
  rail's `aria-labelledby` points at and keeping exactly ONE node with that id.
- Add an `AdminComponents.sheet id="web-edit-sheet" title="Editar fila"` holding the
  same `#web-ajustes-form` verbatim: `field` for `:name`/`:subtitle`, the
  `#web-ajustes-shown` checkbox (`checked={!@form[:hidden].value}`), a1/principal
  `Guardar`. Same `phx-change="validate"` / `phx-submit="save"` events, same
  `normalize_ajustes_params/1` — the "Mostrar en el inicio" inversion must not flip.
- `save` closes the sheet on success and leaves it open with errors on failure.
- Autofocus the name field via `data-pk-sheet-autofocus` (the `AdminSheet` hook's own
  opt-in).

**verify:** `mix test test/pukllay_club_web/live/admin/section_live_test.exs`

**done:** no `#web-ajustes-form` at rest; tapping the name opens it; saving closes it;
`id="web-destacada-name"` still appears exactly once.

### Task 2 — create moves behind a `+` next to the page title

**files:** `lib/pukllay_club_web/live/admin/section_live/index.ex`,
`assets/css/admin/screens.css`

**action:**
- Drop the `Nueva fila` `section_panel` (and the now-dead
  `.pk-admin-web-create` / `.pk-admin-web-create-form` rules).
- Wrap `<h1 class="pk-admin-page-title">Web</h1>` in a title row carrying a trailing
  a3/terciaria `AdminComponents.action` with `aria-label="Nueva fila"` and
  `hero-plus`, `phx-click="open-create-sheet"` — same anatomy
  `.pk-admin-web-otras-header` already uses on this screen.
- Add `AdminComponents.sheet id="web-create-sheet" title="Nueva fila"` holding the
  same `#create-section-form` (name only, `#create-section-name`, `@name_error`
  surfacing, `push_navigate` on success).
- Leave the `Ordenar filas` button in the `Otras filas` header where it ships.

**verify:** `mix test test/pukllay_club_web/live/admin/section_live_test.exs`

**done:** no `#create-section-form` at rest; the `+` opens it; a blank name keeps the
sheet open with the error; a valid name still navigates to the new section.

### Task 3 — tests

**files:** `test/pukllay_club_web/live/admin/section_live_test.exs`

**action:** open the right sheet before driving each form (the six
`#web-ajustes-form` cases and the two `#create-section-form` cases), and add resting-
state coverage: neither form in the DOM on mount, each present after its trigger is
tapped, the `+` carrying `aria-label="Nueva fila"`, the name trigger carrying
`aria-haspopup="dialog"`.

**verify:** `mix quality`

**done:** `mix quality` green.

## Out of scope

The sketch's intermediate `rowSheet()` options list (Destacar / Cambiar la destacada /
Editar la fila), a subtitle field on create, moving `Ordenar filas` into the page
header, any change to `Admin.SectionLive.Edit`.

## Checkpoints

- **api-coverage:** SKIP — no external API/SDK/service in scope.
- **assumption-delta:** SKIP — no singular→plural / required→optional /
  derived→chosen transition; two existing forms change location only.
- **schema-push:** SKIP — no ORM schema files (Elixir/Ecto; no migration).

<threat_model>
ASVS level 1, block on high. Surface touched: two staff-only admin forms moved behind
a tap on the same LiveView.

| threat | assessment |
|---|---|
| Authz bypass | None — the route's `:require_authenticated_staff` on-mount hook is untouched; both forms stay inside the same authenticated LiveView. |
| Mass assignment | None — `save`/`create` keep calling `Sections.update_section/2` and `Sections.create_section/1` through the same changesets; no new params are accepted. |
| Hidden-field tampering | Unchanged — the `shown`→`hidden` inversion stays in the single `normalize_ajustes_params/1` path. |
| XSS | None — names/subtitles render through HEEx escaping, no `raw/1` added. |
| CSRF | Unchanged — LiveView channel events, not new HTTP endpoints. |

No high-severity threats; nothing to block on.
</threat_model>
