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
