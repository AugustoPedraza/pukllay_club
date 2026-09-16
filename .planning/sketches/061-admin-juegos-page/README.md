---
sketch: 061
name: admin-juegos-page
question: "How do the Agregar juego form, the state filters + search, and the game list rows sit together on a phone-width /admin/juegos page — no CTA-looking controls, no horizontal overflow?"
winner: "A1 — stacked layout (add → search → filter chips → rows) with Material filter chips + polished hierarchy scale (rounds 2–3)"
tags: [admin, juegos, form, filters, chips, segmented-control, list-rows, overflow, phase-01.8.1, mobile-first]
---

# Sketch 061: Admin Juegos Page

## Design Question
Phase 01.8.1 UAT gaps on `/admin/juegos`:
- **G-01.8.1-2a:** the `.table` is wider than the phone, so the page scrolls sideways.
- **G-01.8.1-2b:** the "Agregar juego" form looks old-school (a boxed panel with a filled primary button).
- **G-01.8.1-2c:** the state filters look like buttons to act on (the active one is a filled primary block).
- **G-01.8.1-3:** long game names cause horizontal overflow.

The page sits inside the 060 shell (Admin · Juegos · Web · Estantes · Perfil tabs; the drawer doesn't repeat the tabs).

Real data comes from `game_live/index.ex`:
- `bgg_id` input (a number or a BGG link), with the error "Pegá un número de BGG o el link del juego."
- The D-03 known-id prompt "Ya tenés X con este BGG ID. ¿Es otra edición?" with confirm/cancel.
- `estado` filters (Todos / Borradores / Publicados / Retirados) and a `q` search with a 300ms debounce.
- Rows with thumbnail, name and status, plus `enrichment_status` pending / failed + Reintentar.
- "Cargar más" paging. After a successful add, the page patches to `?estado=borrador`.

## How to View
From the repo root: `python3 -m http.server 8765`, then open
http://127.0.0.1:8765/.planning/sketches/061-admin-juegos-page/index.html

Tools (bottom-left): theme, phone/desktop, role, **Datos: Con borradores / Sin borradores**, and **Simular → Carga inicial**.
Try these in the add field: `174430`, a BGG link, `13` (edition prompt), `hola` (error), `999999` (BGG failure → Reintentar).

## Intake
The first proposal was three layouts: A stacked, B one field for search and add, C list first with an add sheet.
The developer picked **A** directly: "#1 should the correct one. Just be sure to use common mobile patterns industry standards".
So there's one layout, and the only variant is the filter control, which is the 2c problem itself.

## Layout A (shared by both variants)
1. **Page title** "Juegos".
2. **AGREGAR JUEGO** (the group label is the `<label>`):
   - An outlined 48px text field with the placeholder "ID o link de BGG", plus an **outlined** "Agregar" button (Material outlined button, never filled).
   - The button is disabled while the field is empty.
   - Validation runs on submit only (ux-patterns B12), and the error clears as soon as the user edits.
   - While adding, the button shows a spinner and "Agregando". On success a bottom snackbar says "Juego agregado como borrador", the filter switches to Borradores, and the new row is highlighted briefly.
3. **Edition prompt:** an inline Material banner under the field. It shows the text, the matching games as compact rows (tap to open the editor), and two text buttons, "Cancelar" and "Sí, agregar edición".
4. **Search:** a filled pill field with a magnifier, a clear (×) button and a live 300ms debounce, placed above the filters. This follows the iOS search bar + scope bar and Material search + chips order.
5. **Filters:** see the variants below.
6. **Summary line** ("412 juegos", "3 borradores", "1 resultado"), then the **list**. The list isn't a table, so G-2a can't happen. Each row uses the one anatomy shared with the drawer:
   - 48px thumb · name (wraps with `overflow-wrap:anywhere`, no ellipsis or clamp, so G-3 is fixed) + a status line (dot + status · year · players) · chevron. Rows are at least 68px; the long Twilight Imperium name grows its row to 99px.
   - **Pending:** a pulsing thumb, "Juego #342942", and "Trayendo datos de BGG…" with a spinner. The row can't be tapped.
   - **Failed:** a dashed warning thumb and a red "No se pudieron traer los datos de BGG" line. The chevron is replaced by one "Reintentar" text button (ux-patterns D22 allows fewer than 3 row actions).
   - Borrador is the only status in bold text with an orange dot, because it's pending work. Publicado has a green dot; Retirado has a hollow dot.
7. **Paging:** a "Mostrar más" text button with a "12 de 412" caption. It keeps the shipped "Cargar más" behavior with quieter styling.
8. **Empty states:**
   - Borradores empty: "No hay borradores" + what drafts are.
   - Search with no results: "Sin resultados para “…”" + a "Borrar búsqueda" text button.
9. **Loading:** skeleton rows with the same anatomy (ux-patterns B13).

## Variants (filter control only)
- **A1: Chips de filtro (Material 3).** 32px drawn with a 44px hit area (`::after`). Unselected chips are outlined; the selected chip is tonal (accent-bg) with a check icon. The row scrolls sideways, and the last chip peeks at the edge. Borradores shows its count (3).
- **A2: Control segmentado (iOS).** A four-segment scope bar, 40px, with the selected segment raised on a surface background. There's no room for a count, but the Juegos tab badge already shows it.

## What to Look For
- Does "Agregar" read as a clear submit without looking like a CTA? Does the disabled-when-empty state help or confuse?
- Chips vs. segmented: which reads more clearly as a *filter*? A1 has room for counts and more states later; A2 shows all four options at once with no scrolling.
- Does the page read in the right order (add, then find, then browse), or should search come before add?
- Do wrapped long names (3 lines) look fine in the list?
- Bottom snackbar vs. the 060 shell's top toast: the snackbar is the mobile standard, and the shell toast could move to the bottom too.

## Verification (build pass)
JS-driven checks on the phone frame:
- No horizontal overflow at start, after all flows, or on desktop.
- The empty-field submit button is disabled.
- `hola` shows the error, and editing clears it.
- `13` shows the edition prompt for both Catan entries, and Cancelar dismisses it.
- The BGG link path adds a pending draft, switches the filter to Borradores, shows the snackbar and bumps the tab badge to 4. About 2.6s later the row fills in as Ark Nova.
- Reintentar on the failed row leads to Frosthaven.
- Search "mansiones" returns 1 result, "zzz" shows the empty state, and Borrar búsqueda restores the list.
- Mostrar más appends rows.
- The segmented control's labels aren't clipped.
- "Sin borradores" shows the empty state.

Phone screenshot reviewed. Dark mode hasn't been checked visually yet: the zoomed capture timed out.

## Round 2: A1 picked, visual hierarchy polish (2026-09-14)
Developer: "A1 feels better. But looks like all the content is big. That breaks the balance. Should the Pukllay Club
at header be like the 'max' or second bigger one weight on the page? Review the full visual hierachy to make it polished"

**Diagnosis.** Before this round, the page title (32px display caps) and the brand (28px logo + 22px display caps) competed for first place,
and every control was at full volume (48px inputs, 68px rows, 48px thumbs, 16px names).
**Answer to the brand question:** the brand is chrome, never the page's loudest element. In iOS large titles, the Material top app bar and Shopify
admin, the page title anchors the screen and the brand sits a tier below it: visible, not competing.

**The scale** (tools → Escala: Pulida / Antes compares it with the round-1 sizes):

| Tier | Element | Before | Pulida |
|---|---|---|---|
| 1 | Page title | 32px Bebas Neue caps | **22px / 700 Inter**, the tool voice, clearly separate from the brand face |
| 2 | Brand (header) | logo 28 + wordmark 22px | **logo 24 + wordmark 17px**; header 56 → 52px |
| 3 | Section label | 11px / 700 caps | unchanged |
| body | Row name | 16px / 500 | **15px / 500** |
| body | Input text | 16px (rendered in Arial, a bug) | 16px Inter (kept at 16 so iOS doesn't zoom on focus) |
| meta | Status line, summary, error | 13px | **12px** |

- **One control height:** field, Agregar button and search are all **44px** (the repo's touch minimum). Chips are 32px drawn with a 44px hit area.
- **Rows:** 68 → **60px**, thumb 48 → **40px** (radius 6), divider inset 68px, chevron 16px. Five rows now fit above the tab bar (four before).
- **Spacing:** 8px grid. Gaps between groups are larger than gaps inside them (title → add 16, add → search 24, search → chips 4, chips → summary 8).
- **Edition banner:** tightened (13px text, 32px thumbs, 48px rows).
- **Failed-row copy:** "Error al traer datos de BGG" (the shipped string) fits on one line, so the row stays 60px.
- **Bug fixed:** `input` didn't inherit the font (Arial) → `button, input { font: inherit }`.

Verified (JS + screenshots, light and dark): computed sizes match the table, no horizontal overflow, input font is Inter.

**Shell impact:** the title and header scale belongs to the shell, so 060's Admin page title and the 059 header should adopt it too
(apply everywhere in 062–063 and the gap-closure plan).

## Round 3: quieter fields and submit (2026-09-14)
Developer: "But the placeholder of the form, search and CTA still looks big"

Round 2 kept the field text at 16px (the iOS no-zoom size), and that 16px is what still read as big next to the 15px names.
- **Add field + search:** text and placeholder 16 → **14px**. Height stays **44px** (touch minimum); the search icon is 16px.
- **"Agregar":** 14 → **13px / 600**, horizontal padding 12px, muted text while disabled.
- Measured: add 14px, placeholder 14px, search 14px, button 13px, row names 15px, fields 44px tall, no overflow.

**Implementation note (must handle):** iOS Safari auto-zooms the page when a field under 16px gets focus. Fix it in
`root.html.heex` with `<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">`. iOS keeps
pinch-zoom despite `maximum-scale`. Check that Android Chrome still allows pinch-zoom with it before shipping, and if not, fall back to
a 16px field only on touch devices.

## Winner: A1, chips + polished scale (2026-09-14)
Developer: "yes, mark A1 as winner and commit". A2 (segmented control) stays in the file for comparison, and the Escala toggle keeps the round-1 sizes.
Carry forward to 062–063 and the gap-closure plan:
- Juegos page order: AGREGAR JUEGO (outlined 44px field + outlined "Agregar"), then search pill, then filter chips, then summary, then rows.
- One list-row anatomy: 40px thumb · 15px name (wraps) + 12px status line · chevron or a single text action.
- Admin type scale: page title 22px/700 Inter > brand (24px logo, 17px wordmark) > 11px caps labels > 15px body > 14px fields > 12px meta. Every control is 44px tall.
- iOS focus-zoom must be handled (see round 3).

## Button system from sketch 064 applied (2026-09-15)
The admin now uses one button system everywhere. It's S3 Contorno, weight-tuned; see `064-admin-button-system/README.md`. The identical CSS block ("064: admin button system") is appended to this sketch's `<style>`, scoped with `#device`, so it overrides the older local `.obtn`/`.tbtn` rules.
- **One anatomy:** 44px · 8px radius · 14px/600 · 16px icon · 8px gap.
- **Principal** (`.obtn`/`.b-pri`) is a 1px primary outline. **Secundaria** (`.b-sec`) is a 1px neutral outline (`--stroke`, ≥ 3:1, shared with text fields). **Terciaria** (`.tbtn`) is secondary-purple text. **Peligro** (`.tbtn.danger`) is danger text.
- **No disabled buttons, and Principal is last in its row.**
- "Agregar" is no longer disabled while the field is empty; an empty or invalid value shows the error on submit.
- "Sí, agregar edición" is Secundaria next to the Cancelar Terciaria.
- The login moved to a Principal button.
- The add field uses the shared stroke.
- This supersedes the round-1 note "outlined submit that stays disabled while the field is empty".
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
- **One counter source** with 060/062 (`DATA()`/`cnt()`/`boxData()` identical in all three).
- **412, not 408.** `HIDDEN_PUBLISHED` 396 → 400, so the Juegos page counts the same ludoteca as
  Estantes and the Admin box. The summary line and the "Mostrar más" caption move with it.
- **The Staff box** derives its note (see 060).
- Section labels ("Agregar juego") use the shared 065 section label — 13px/600 in full colour, not
  11px uppercase muted — and the page head sits 24px above the first block.
- **iOS focus-zoom, finally answered.** This sketch flagged it and deferred it to "the viewport meta".
  065 settles it without `maximum-scale`: fields go to 16px on coarse pointers only. See 065's README.
- **Weight balance (round 2).** `.err-t` was 400 while `.st-draft` was 600, so "Error al traer datos
  de BGG" — the row with a Reintentar next to it — read quieter than a "Borrador" status. Both 600
  now. Dashboard box weights as in 060.
- **Round 3 (what a row says, from sketch 065).** Year and player count were never in production
  (the shipped list is Nombre | Estado). Año stays — it is what tells two editions of one game apart;
  "N jug." is gone. Status now marks the EXCEPTION: Publicado is unmarked (it was 407 of 412 rows),
  Borrador takes the accent pill this admin already uses for pending work, Retirado takes a muted
  outline pill and a muted row. Never colour alone — the amber dot it replaces measured 2.78:1,
  under the 3:1 non-text floor, and grey means "disabled", which a draft never is.
