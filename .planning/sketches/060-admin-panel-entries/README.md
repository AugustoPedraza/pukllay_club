---
sketch: 060
name: admin-panel-entries
question: "How should the Admin home page's entries read as tappable and surface pending work, using only the 059 shell's one row anatomy?"
winner: "C (final, single design — renamed: Admin / Perfil / Web)"
tags: [admin, panel, dashboard, affordance, list-rows, pending-work, phase-01.8.1, mobile-first]
---

# Sketch 060: Admin Panel Entries

## Design Question
G-01.8.1-1c: the shipped `/admin` dashboard cards (`rounded-box bg-base-200`, display-type title, warning
badge) don't read as touchable. The Panel sits inside the 059-C2 shell, which already lists every section
in the tab bar and the drawer, so the Panel page has to earn its place and can't just be a third copy of
the same list. Constraints carried from 059: mobile-first, one row anatomy (slot · label + secondary line
· count · chevron), no CTA-looking controls, and variation shown only through tone or content.

Real data (from `dashboard_live.ex`): Juegos → draft count; Estantes → `location_progress` placed/total;
Secciones → no count; Revisar niveles → `BandAudit.count_mismatches`; Staff → owner only.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/060-admin-panel-entries/index.html

Top bar: variant A/B/C plus shell state. Tools (bottom-left): theme, phone/desktop, role (owner/staff),
**Datos: Con pendientes / Todo al día**.

## Variants
- **A: Lista con estado:** CATÁLOGO (Juegos, Secciones, Estantes) and MANTENIMIENTO (Revisar niveles, Staff).
  The second line gives live status ("3 borradores sin publicar", "412 publicados"), and a count bubble
  shows pending work. Least resistance: the drawer's PANEL row plus a status line.
- **B: Primero lo pendiente:** PARA HACER shows only task rows ("Publicar 3 borradores", "Ubicar 84 juegos",
  "Revisar 7 niveles") that deep-link to the section, collapsing to a static "Todo al día" row when there's
  nothing left. Then ATAJOS → "Agregar juego" as a row (the core staff action), then a plain SECCIONES list.
- **C: Qué se hace en cada una:** the same groups as A, but the second line teaches what each section is for
  (for new staff). Pending work shows only as the bubble, and the text doesn't change with the data.

All variants: rows are ≥56px, full-bleed hover/press tint, chevron, focus-visible ring. A count bubble
means pending work everywhere (drawer, tab badge, Panel). Secciones and Staff never get one.

## What to Look For
- Does each entry read as tappable at a glance (1c), with no card or button styling?
- Is the Panel useful given that tabs and the drawer already list the sections (B tries hardest)?
- Status line (A) vs. teaching line (C): which is still useful on the 50th visit?
- B's shape changes with the data. Is that helpful or disorienting?
- The tab bar now badges Estantes too (84), since the "bubble = pending" rule applies everywhere. Is that too loud?

## Round 2: remove the redundancy (2026-09-14)
Developer rejected A–C: "All the panel is too overloaded, having same options that left drawer already
have, been this redundant." Every A–C variant re-lists the sections the tab bar and drawer already carry.
Two new directions (A–C kept in the file for comparison):

- **D: Panel = solo pendientes.** No section rows. One PARA HACER group with task rows that deep-link to
  the section ("Publicar 3 borradores" → Juegos). When nothing is pending, the whole page is a single
  static "Todo al día" row. The tab bar and drawer are unchanged from 059.
- **E: Sin Panel.** The Panel page, tab and drawer row are removed, and admin lands on Juegos (the core
  action). Phone tabs: Juegos · Secciones · Estantes · Cuenta. Pending work shows only as tab badges and
  drawer counts, so Revisar niveles (7) is visible only in the drawer on phone.

Verified by JS: D pending/all-clear content, D row → Revisar niveles, where no tab is highlighted as in
059. E: lands on Juegos after login and on variant switch, 4 phone tabs, desktop row without Panel,
Secciones → Destacados drill-down with back row, no overflow, zero console errors.

## Verification (build pass)
JS-driven check of every variant × pending/all-clear × owner/staff: rows render the expected content,
Staff is hidden for the staff role, and there's no horizontal overflow at 375px. Minimum row height is
59px. B's task rows navigate to the section with tab/drawer active states synced, "Agregar juego" routes
to Juegos, and there are zero console errors. Visual screenshot capture timed out in the automation tab,
so this still needs a visual look.

## Winner: C, "Qué se hace en cada una" (2026-09-14)
The developer picked C ("C looks clean") and asked to remove the other variants and rename three things.
`index.html` now contains only the final design (A–E are recoverable from git history of this sketch).

- **Entries:** CATÁLOGO (Juegos, Web, Estantes) → MANTENIMIENTO (Revisar niveles, Staff; Staff is owner-only).
  Each entry is the one row: icon · name + a line teaching what the section is for · pending-count bubble ·
  chevron, at least 56px (measured 59px), with full-bleed hover/press tint and a focus ring. The text is
  stable and never changes with the data. The bubble is the only pending signal.
- **Renames (apply everywhere in 061–063 and the gap-closure plan):**
  - **"Panel" → "Admin"**: home tab, page title, drawer group label (ADMIN), login title "Ingresar a Admin".
  - **"Cuenta" → "Perfil"**: tab label; the sheet group is TU PERFIL.
  - **"Secciones" → "Web"** with a globe icon (heroicons `globe-alt`), because this is where staff choose
    which rows show on the public web. Its description is "Elegí qué filas se ven en la web"; the drill-down
    back row reads "‹ Web". Routes/modules can keep `secciones`/`SectionLive` internally. This is a label
    change only.
- **Count bubble = pending work** everywhere (Admin page, drawer, tab badges: Juegos 3, Estantes 84).
  Web and Staff never show one.

Browser-verified by JS: phone tabs Admin · Juegos · Web · Estantes · Perfil; drawer ADMIN → SITIO; Perfil
sheet; Web → Destacados drill-down with "‹ Web" and the Web tab active; desktop tab row; staff role hides
Staff; logout → "Ingresar a Admin" → login lands on Admin; no horizontal overflow; zero console errors.

### Open notes for implementation
- The drawer now reads ADMIN (group) → "Admin" (first row), so the word appears twice. Acceptable, but the
  first row could become "Inicio de Admin" if it reads odd on device.
- There is a "Web" tab (curates public rows) next to the drawer's SITIO group (public links) and the Perfil
  sheet's "Ver el sitio público". Watch whether staff confuse "Web" (edit) with "Sitio" (visit).
- Mirror the shipped `dashboard_live.ex` counts: drafts, `location_progress` unplaced, band mismatches.
