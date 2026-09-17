# Handoff — redesign the admin "Web" tab (fresh session)

**Written:** 2026-09-17, at the end of the estante UI restart (sketch 069, decisions 1–68).
**Developer's ask:** *"Based on all the lessons we have, I want to redesign the web (using same components, patterns,
looks and feel, UI/UX, etc., so it delivers a strong balance and rhythm). I want to do it in a fresh session."*
Clarified: **"web" = the admin "Web" tab** (not the public site, not the whole admin).

## How to run it
It is design work → **`/gsd-sketch`** (standalone HTML mockups in `.planning/sketches/`, MANIFEST row, sketch commits),
not implementation. Start with:
`/gsd-sketch --quick Redesign the admin Web tab — read .planning/notes/admin-web-redesign-handoff.md first`
`--quick` skips the mood/direction intake (the look and feel is settled: sketch 069 + D-19). The workflow's default of
2–3 variants per sketch yields to the working agreement below: ask first, measure, build variants only when the
developer asks for them. Implementation comes later through `/gsd-plan-phase 01.8.2`. When the Web sketches settle,
`/gsd-sketch --wrap-up` can refresh the stale `sketch-findings-pukllay_club` skill (D-17).

## What "Web" is
- The admin tab that curates the **public home page's rows** ("Filas del inicio"): the pinned featured row
  (Destacados) and hand-picked sections, hide-only (no delete), ordered.
- Code today (01.8.1): `lib/pukllay_club_web/live/admin/section_live/index.ex` (`/admin/secciones`: list, create by
  name, ↑/↓ reorder of non-featured rows) and `section_live/edit.ex` (`/admin/secciones/:id`: one sección's settings and
  games). Renamed Secciones → **Web** by the 059 shell (scope note row 2); in 01.8.2 it is still the 065 design.
- Last design: sketch **065** (Web page + "sección" drill-down; Rounds 6–7 notes on it). It predates every rule below,
  so treat 065's Web/sección as the **starting point to question**, not the target.

## Read first (in this order)
1. `.planning/phases/01.8.2-admin-ui-ux-redesign/01.8.2-CONTEXT.md` — D-00a..D-00c, **D-08** (the estante pages as
   settled), **D-19a–j** (app-wide rules), D-10.
2. `.planning/phases/01.8.2-admin-ui-ux-redesign/01.8.2-BENCHMARK.md` — component table vs iOS HIG / M3.
3. `.planning/notes/estante-ui-restart.md` — "Where we are" at the bottom first; then decisions as needed (each has the
   developer's words and the measurements).
4. `.planning/sketches/069-estantes-ubicar/index.html` — the component source: copy CSS/JS from here, don't redraw.
5. `.planning/sketches/065-admin-composition/README.md` Rounds 6–7 (Web / sección) and the two LiveViews above.

## The rules to carry (all recorded in CONTEXT / notes)
- **One main job per page** (D-19j): the page shows only its job; secondary lists go behind an entry, never under the
  main control; switching what's below never moves the main control. Type ranks: title 22/600 › prompt 17/600 › main
  control › context 14–15/600 muted › row names 14–15 › chips/subs 12–13.
- **Pending work behind a header icon + count badge** (D-19g), opening its own page.
- **Sheets** (D-19e): ✕ in the header, no Cancelar row; header = optional cover/tile · small **context** line above ·
  18/600 title (what the sheet is about) · divider; two-line option rows (verb + one grey line saying what happens,
  64px); pinned header when tall; form sheets (one field + one full-width Principal button, pre-filled and selected,
  errors under the hint) — restart 67.
- **Destructive = centred dialog** (D-19f): "¿Verbo {cosa}?", one consequence line, Cancelar (focused) + red verb; undo
  snackbar when possible.
- **Status = dot + text, never a pill** (D-19h). **Chevron only when a row opens another page** (D-19i).
- **Reorder = a mode** from a ⇅ header icon: ≡ drag handles, tap ≡ → ↑/↓, Listo → "Orden guardado" + Deshacer
  (restart 68). *Conflict to raise:* 065 R7 made Ordenar an outlined button (Secundaria → Principal "Listo") at the list
  head for Web/sección — the estante decision replaced that shape for estantes; ask whether Web follows 68.
- **Header actions** are 44px A3 icons, the primary create action ("+") rightmost; a text action only for Listo.
- **Create from where you are**: a search with no match offers "Crear «texto»" (restart 62/66).
- **Rhythm on the 8px scale, grouped by belonging** (title row → main control 16; control → next group 32; label →
  its content 16); top-aligned content for result pages; optical centre (2:3) only for a lone idle control.
- Spanish is **Argentine voseo** (memory); mobile first (memory); no age facet (memory).

## Working agreement (developer, all session)
- **One question at a time.** Offer 2–4 options with a recommendation; when the developer says "build variants", build
  them as standalone sketch toggles (*tools → …*), then **remove the losers** once one is picked.
- **Measure before building variants** and report numbers (positions, gaps, widths at 360/375/800, contrast, 44px hit
  areas, keyboard overlap). Look at screenshots in both themes before reporting.
- **Record every decision** (with the developer's words and the measurements) in a notes file for this redesign, e.g.
  `.planning/notes/web-ui-redesign.md`, numbered from 1; app-wide rules also go to CONTEXT (next id D-19k) and BENCHMARK.
- Sketches show **only the UI being designed** (no walk bar, no other pages). Next free sketch number: **070**
  (planned 070–073 were never used; MANIFEST rows 059–069 are the latest).

## Measuring toolkit that worked
- Serve: `python3 -m http.server 8765` from the repo root.
- Headless checks with `playwright-core` from the npx cache (loader in `.planning/sketches/064-admin-button-system/verify.js`),
  `channel: 'chrome'`, viewports 360×640 / 375×667 / 375×800, `deviceScaleFactor: 2`; write scripts and screenshots to the
  session scratchpad.
- The sketch's `#tools` bar covers the header at 375px: hide it (`display:none`) before real clicks; tools can still be
  clicked via `element.click()` in `evaluate`.
- After scripted edits, extract the inline `<script>` and run `node --check` (a stray brace has blanked a page).
- The simulated keyboard is 292px; dropdowns/sheets must end above it.
- Programmatic `.focus()` after a scripted click paints a focus ring in screenshots — refocus only when `e.detail === 0`.

## Suggested first question for the new session
Start from the job, as the estante restart did: *what does staff actually do on Web, and how often?* (e.g. swap the
featured games before a club night / add a new sección / hide one / reorder rows). Then decide the page's one main job
before drawing anything.
