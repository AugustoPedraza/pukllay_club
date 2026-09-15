---
sketch: 060
name: admin-panel-entries
question: "How should the Admin home page's entries read as tappable and surface pending work, using only the 059 shell's one row anatomy?"
winner: "B layout (final, single design) — centered 2-column boxes, icon beside name (A), name → number → one note; no chevron"
tags: [admin, dashboard, boxes, affordance, pending-work, drawer, naming, phase-01.8.1, mobile-first]
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

Top bar: shell state only (final design; variants removed). Tools (bottom-left): theme, phone/desktop, role (owner/staff),
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
`index.html` now contains only the final design. A–E were never committed, so the round descriptions above are their only record.

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

## Round 3: dashboard boxes + drawer without duplicates (2026-09-14)
Developer: "Admin page content should be a list of 'boxes' with a simple minimalistic dashboard. On the
drawer menu, not menu option navigation since is accessible from nav menu."

This supersedes C's row list (and its teaching lines) and overrides 059's "no cards" rule for this page
only. The one-anatomy principle still applies: every box uses the same box anatomy.

- **Box anatomy:** [icon · name · chevron] → big number + unit (Inter 700, tabular) → optional meter
  (Estantes only) → foot line. Outline-only (`--color-bg` fill, 1px border, radius-lg). The whole box is the
  tap target: surface tint + primary-tinted border on hover, scale .985 on press, focus ring. No filled buttons.
  - Juegos: **412** juegos · pill "3 borradores" / "Todos publicados"
  - Web: **5** filas en el inicio · "Destacados y 4 más"
  - Estantes: **80%** ubicados · meter · pill "84 sin ubicar" / "Todos ubicados"
  - Revisar niveles: **7** discrepancias · pill "Por revisar" / "Todo coincide con BGG"
  - Staff (owner): **3** personas · "1 invitación pendiente"
- **Pending work** = the same accent pill as the drawer counts and tab badges; everything else is muted.
- **Variants:** A: list of full-width boxes (number + unit on one line); B: 2-column grid on phone (equal
  columns, unit under the number, names wrap). Desktop: 3 columns for both.
- **Drawer never repeats the nav menu:** phone admin → ADMIN holds only Revisar niveles + Staff (what the tab
  bar lacks); desktop admin → no ADMIN group (the tab row has every section); public page signed in → ADMIN
  holds a single "Ir a Admin" row (no tab bar there, so it's the only way in); signed out → SITIO only.

Bugs found and fixed this round: B's grid columns were unequal (157 vs 176px) because `1fr` lets long
content widen a track → `minmax(0, 1fr)`; "Revisar niveles" was ellipsized in B → names wrap in tiles.
First pass used a lavender `--color-surface` fill on every box, which read heavy → outline-only.

Verified (JS + screenshots, light + dark): drawer contents in all four contexts, box → section with the tab
synced, drawer Revisar niveles active with no tab highlighted, staff role (4 boxes, drawer only Revisar
niveles), no horizontal overflow, zero console errors.

## Winner: B, centered 2-column dashboard (2026-09-14)
Developer: "B and not need of arrow. Show me centered content of its boxes." `index.html` now holds only this
design (A, the full-width list, was never committed; it's described in round 3 above).

- **Grid:** `repeat(2, minmax(0, 1fr))`, 10px gap on phone (measured 167px boxes at 375px); 3 columns, 16px gap
  on desktop. With the owner's 5 boxes, Staff sits alone on the last row. All five fit above the phone tab bar.
- **Box (centered, no chevron):** icon + name (wraps if long) → big number (Inter 700, tabular) → unit on
  its own line → meter stretched full width (Estantes only) → foot line / pending pill. The whole box is the
  tap target: outline-only at rest, surface tint + primary-tinted border on hover, scale .985 on press,
  focus ring. With no chevron, the tap affordance comes from box shape + hover/press, so implement both
  (`active:scale`, hover tint) rather than dropping them.
- Everything else from round 3 stands: pending pill = the same accent bubble as the drawer counts and tab
  badges; the drawer never repeats the tab bar; renames Admin / Perfil / Web.

Verified (JS + screenshot): equal box widths on phone/desktop, no chevrons, no clipped text, no horizontal
overflow, box → Revisar niveles and Admin tab → back to 5 boxes, all-clear foot lines, zero console errors.

## Redundancy trim (2026-09-14)
Developer: "For the boxes, there is redundancy. Like Juegos and then 412 juegos again. Same for the rest. Make it
simple and more meaningful."

The unit line under the number is removed. Each box is now **name → number → one note**, and the note must add
information, never restate the name:

| Box | Number | Note (pending pill when there's work) | All clear |
|---|---|---|---|
| Juegos | 412 | **3 borradores** | Todos publicados |
| Web | 5 | filas en el inicio | — |
| Estantes | 80% + meter | **84 sin ubicar** | 100% · Todos ubicados |
| Revisar niveles | 7 | **no coinciden con BGG** | 0 · Todo coincide con BGG |
| Staff (owner) | 3 | 1 invitación pendiente | — |

Web keeps "filas en el inicio" because "Web · 5" means nothing on its own. The duplicate "Destacados y 4 más"
line was dropped. Verified: no clipped text or overflow in either
data state, zero console errors.

## Name/number balance (2026-09-14)
Developer: "It needs a better balance on the 'what' and its number. The number now is too heavy."

- **Name** (the "what"): 14px muted → **16px / 600, text color**; icon 18 → **20px**, muted.
- **Number:** 32px / 700 → **22px / 600** (tabular). The name and number now read as a pair (16 : 22) instead of a
  small label under a headline figure.
- The note line is unchanged (12px, muted or pending pill).

Verified in light and dark: "Revisar niveles" still fits on one line in a 167px box, no clipped text or overflow, zero
console errors.

## Icon treatment round (2026-09-14)
Developer: "Variants? without icons?" The box layout is settled; this round only varies the icon:

- **A: Ícono al lado:** the current design, a muted 20px icon left of the name (matches tab bar/drawer icons).
  Box height 110–122px.
- **B: Sin ícono:** name → number → note only. The tab bar already carries the icons. Same height as A.
- **C: Ícono arriba:** a muted 24px icon stacked above the name. More symmetric when centered, but +25px per box
  (135–147px), and the five boxes get close to the tab bar on a phone.

Verified all three: no clipped text or overflow, zero console errors.

**Picked: A, icon beside the name.** B and C were removed from `index.html` (never committed; described above).
A keeps a section's icon identical across the Admin box, the drawer row and the tab bar.

## Button system from sketch 064 applied (2026-09-15)
The admin now uses one button system everywhere. It's S3 Contorno, weight-tuned; see `064-admin-button-system/README.md`. The identical CSS block ("064: admin button system") is appended to this sketch's `<style>`, scoped with `#device`, so it overrides the older local `.obtn`/`.tbtn` rules.
- **One anatomy:** 44px · 8px radius · 14px/600 · 16px icon · 8px gap.
- **Principal** (`.obtn`/`.b-pri`) is a 1px primary outline. **Secundaria** (`.b-sec`) is a 1px neutral outline (`--stroke`, ≥ 3:1, shared with text fields). **Terciaria** (`.tbtn`) is secondary-purple text. **Peligro** (`.tbtn.danger`) is danger text.
- **No disabled buttons, and Principal is last in its row.**
- Login "Enviarme el link" moved from a grey filled `.btn` to a full-width Principal.
Checked by `064-admin-button-system/audit-admin.js`.
