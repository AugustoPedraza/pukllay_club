---
created: 2026-09-12T21:44:45.980Z
title: Browser verification session for waived Windows UI entries
area: ui
severity: minor
files:
  - lib/pukllay_club_web/components/layouts.ex
  - assets/css/app.css
  - lib/pukllay_club_web/live/about_live.ex
  - lib/pukllay_club_web/live/catalog_live/index.ex
  - lib/pukllay_club_web/live/catalog_live/show.ex
  - .planning/WINDOWS.md
---

## Problem

On 2026-09-12 (quick 260912-mxt follow-up), 7 `.planning/WINDOWS.md` entries — 3, 4, 5, 7, 13, 18
and 24 — were each waived with "Accepted by user 2026-09-12 to unblock /gsd-ship... residual risk
accepted" reasons. Ledger `open_count` is 0, so none of this is ship-blocking, but none of the 7
has ever had a real human browser check. This todo is not urgent — its point is to retire that
accepted residual risk in one sitting, whenever it's convenient, rather than let it be forgotten.
Severity is `minor` by planner discretion: every waive reason records accepted residual risk with
no known defect, not a confirmed bug.

## Solution

Run one browser verification session covering all 7 entries below, record each result, then close
this todo.

## Session setup

- Run against either the local dev server (`mix phx.server`) or `https://pukllay.club`.
- Game ids `179` (7 Wonders Duel) and `137` (Wingspan) are local-dev ids only. On production,
  find the same games by name from `/` instead of using the id in the URL.
- Use a real desktop Chrome with DevTools' device toolbar in Responsive mode, typing the exact
  width for each check. A prior browser-automation tool in this project pinned its viewport near
  339-390px regardless of resize (STATE.md, Phase 01.2 decision) — do not use that tool for the
  1440px/768px checks, only a real resizable desktop browser.
- Switch themes with the drawer's or footer's "Usar tema claro" / "Usar tema oscuro" buttons.
- For the reduced-motion sub-check, use DevTools > Rendering > "Emulate CSS media feature
  prefers-reduced-motion: reduce".
- Mobile-first: run every 390px check before its desktop counterpart on the same entry.

## Checklist

### Entry 3 — Mobile drawer open/close behaviour

- [ ] **Route:** `/`, `/quienes-somos`, `/juegos/179` (all three). **Width:** 390px.
  **Steps:** tap "Abrir menú" (`.pk-nav-hamburger`) to open the drawer, then close it four
  separate ways across repeats of this check: Escape, tapping "Cerrar menú", tapping the
  backdrop (`.pk-drawer-backdrop`), and tapping the "Inicio" or "Quiénes Somos" link.
  **Pass criterion:** every one of the four close paths works on all three routes. On open,
  focus lands on "Cerrar menú" and `aria-expanded` on the hamburger reads `true`. Tab and
  Shift+Tab never move focus outside `#pk-nav-drawer` while it's open. After the Escape, close-
  button and backdrop closes, focus returns to the hamburger. A link close navigates to that
  route and leaves the drawer closed.
- [ ] **Route:** same three routes. **Width:** 1440px.
  **Pass criterion:** no hamburger is visible anywhere, and tabbing through the entire page
  never focuses anything inside `#pk-nav-drawer` — it is `display:none` above 480px and `inert`.

### Entry 4 — Drawer layout + footer at 390px

- [ ] **Route:** `/quienes-somos` (or `/`). **Width:** 390px. **Theme:** light, then dark.
  **Pass criterion (drawer):** "Inicio" and "Quiénes Somos" render as full-width tappable rows,
  each with a right chevron (`.pk-drawer-chevron`). The current page's row shows the left-accent
  active state (`aria-current="page"`). The social links and the three theme buttons ("Usar tema
  del sistema" / claro / oscuro) sit pinned against the drawer panel's bottom edge
  (`.pk-drawer-bottom`).
  **Pass criterion (footer):** the footer shows only the "Powered by BGG" attribution line, with
  no copyright text, social links, theme toggle, or FAQ/Contacto/Juntadas links visible.
  Note: the ledger row's "keeps copyright+BGG attribution" wording is stale — since quick
  260902-fdm (sketch 044 winner H), `.pk-footer-copyright` is `display:none` at ≤480px by
  design. A hidden copyright at this width is expected, not a failure.

### Entry 5 — About sticky CTA bar + footer clearance

- [ ] **Route:** `/quienes-somos`. **Width:** 390px.
  **Steps:** load at the top of the page, scroll down past the hero, then scroll to the very
  bottom.
  **Pass criterion:** `#pk-about-cta-bar` (the "Sumate" bar) is not visible at page top. It
  slides in once the hero isologo docks into the header, and stays pinned through the rest of
  the scroll in both directions (no auto-hide by design). At the very bottom, the "Powered by
  BGG" footer line is fully visible above the bar with nothing clipped behind it. The Cierre
  band's own Sumate button is NOT shown at this width (the bar replaces it).
- [ ] **Route:** `/quienes-somos` at 1440px, plus `/` and `/juegos/179` at 390px.
  **Pass criterion:** no `#pk-about-cta-bar` appears at any scroll position on any of these.
  Note: `/juegos/:id` has its own, different `.pk-mobile-cta-bar` (reserve/share) — seeing that
  there is expected and is not a failure of this entry.

### Entry 7 — About photo rail interaction

- [ ] **Route:** `/quienes-somos` `#fotos`. **Width:** 1440px with a mouse (browser tab must be
  focused), plus 390px for the touch-specific lines below.
  **Steps + pass criteria, one line each:**
  - Manually scroll the rail — the active dot (`[data-dots] button.pk-about-dot`, `.is-active` +
    `aria-current="true"`) tracks the visible slide, including the last dot when scrolled to the
    end.
  - Click "Foto 3" (`aria-label="Foto 3"`, `data-goto="2"`) — the rail jumps to that slide and
    dot 3 becomes active.
  - Leave the rail idle — it auto-advances roughly every 4.5s.
  - Hover the rail with a mouse — auto-advance pauses; moving the mouse away resumes it
    immediately.
  - At 390px, swipe the rail or tap a dot — auto-advance pauses, then resumes about 6s after the
    last touch.
  - Switch to another browser tab or window while the rail is idle — auto-advance stops while
    unfocused.
  - With DevTools' `prefers-reduced-motion: reduce` emulation on — no auto-advance happens at
    all.

### Entry 13 — Active filter chip row visual weight

- [ ] **Route:** `/?players=4&max_playtime=60`. **Widths:** 390px and 1440px. **Theme:** light
  and dark (4 combos total).
  **Steps:** confirm the heading reads "Resultados" (not "Toda la ludoteca"), with the chips
  "Jugadores: 4" and "Duración máx.: 60 min" plus a "Limpiar filtros" link below it.
  **Pass criterion:** in all 4 combos, the eye lands on the "Resultados" heading first. The chip
  row reads as clearly secondary (soft accent tint, no shadow, visually lighter than the
  heading) while staying legible, and nothing in the row competes with the heading for
  attention.
  Note: this is a subjective visual-weight judgment. A "no" here is a design finding to route to
  `/gsd-debug` or `/gsd-sketch`, not a regression — structural intent is already pinned by
  existing tests.

### Entry 18 — Tappable creator pills

- [ ] **Route:** `/juegos/179`. **Width:** 390px, then 1440px.
  **Steps:** under "Diseñadores", tap "Antoine Bauza"; go back; under "Ilustradores", tap
  "Miguel Coimbra". At 390px, use DevTools to measure a pill's rendered height.
  **Pass criterion:** pills read as tappable (outline pill style; at 1440px, hovering shifts
  border and text color to brand ink). Tapping "Antoine Bauza" lands on
  `/?designers=Antoine%20Bauza` showing a "Resultados" heading, a "Diseñador: Antoine Bauza"
  chip, and 7 Wonders Duel in the results. Tapping "Miguel Coimbra" gives the equivalent
  "Ilustrador: Miguel Coimbra" result. The measured pill height is at least 44px (this project's
  touch-target minimum).
  Note: `creator_pills/1` carries no `min-h-11`, unlike the index chips, so a measured height
  under 44px is a real finding — route it to `/gsd-debug`, don't wave it through.
- [ ] **Route:** `/juegos/137` (Wingspan, 4 artists including "Greg May (II)"). **Width:** 390px.
  **Pass criterion:** all four artist pills wrap cleanly under "Ilustradores" with no overflow
  or clipping.

### Entry 24 — Cierre band whitespace at 768px

- [ ] **Route:** `/quienes-somos`, scrolled to `#cierre`. **Width:** 768px. **Theme:** light and
  dark.
  **Pass criterion:** "Nos vemos el sábado", the Sumate button, and "Pukllay Club · San Salvador
  de Jujuy, Argentina" read as one centred group. Whitespace above the heading and below the
  signature inside the band is visibly equal — in DevTools, `#cierre`'s computed
  `padding-top`/`padding-bottom` are both 80px (5rem). The band reads as a distinct closing
  moment, neither cramped nor mostly empty. The footer below has a legible top edge against the
  tinted band. No sticky CTA bar is shown at 768px (that only appears at ≤480px).
  Note: the ledger row's "70vh proportion" wording is stale — 01.5-09 replaced the
  viewport-height floor with a fixed `padding-block: 5rem` at `min-width: 640px`. 375px and
  1280px were already human-checked in 01.5-UAT test 20; only 768px is new here.

### Follow-up — G-01-7 double focus ring (not a WINDOWS.md ledger entry)

- [ ] **Route:** any page with the catalog filter modal (`/`). **Width:** 390px and 1440px.
  **Theme:** light and dark (4 combos).
  **Steps:** open the filter modal, open a checklist facet (e.g. Mecánicas or Temáticas), then
  Tab into and click into its search input.
  **Pass criterion:** exactly ONE focus indicator shows (the input's border darkens to
  `base-content`) — no double outline ring around it.
  This was fixed in quick 260912-pnx (commit `ea1df22`), but only automated class assertions
  have run so far — it has not been visually checked in a real browser. If a double ring is
  still visible in any combo, reopen it via `/gsd-debug`, don't re-fix ad hoc.

## Recording results

- For each entry whose checklist lines all pass, first try the documented ledger verb:
  `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed <id>`. As of 2026-09-12, `markFixed`
  only accepts `open` rows (verified) — on these 7 waived rows it refuses with `Error: Window
  <id> is already waived (resolved_at=...)` and changes nothing.
- **Approved fallback for this exact case (user-approved 2026-09-12):** since `windows fixed`
  cannot flip a `waived` row, hand-edit `.planning/WINDOWS.md` directly for each PASSING entry
  only — nowhere else in the ledger. Edit BOTH places consistently:
  1. The markdown table row's Status column.
  2. The matching JSON entry: set `"status": "fixed"`, `"reason": ""` (or a short verification
     note naming the route/width/theme checked), and `"resolved_at"` to a fresh ISO timestamp.
  Then update the ledger frontmatter counts to stay consistent: `waived_count` -1,
  `fixed_count` +1, and bump `last_updated`. The markdown table and JSON block are cross-checked
  by the parser — a mismatch raises `WINDOWS_LEDGER_MALFORMED` and breaks `/gsd-ship`, so edit
  both halves in the same pass and double-check the counts before saving.
- For any entry with a FAILING line, do not touch its WINDOWS.md row at all — leave it `waived`.
  Instead open `/gsd-debug` with: the entry id, route, width, theme, the expected pass criterion
  versus what was actually observed, and a screenshot. Note the resulting debug-session slug
  under that entry in this todo.
- Regardless of outcome, log every entry in a `## Resolution` section appended to the bottom of
  this todo: date, entry id, route(s), width(s), theme(s), and PASS (ledger row flipped to
  `fixed`, per above) or FAIL (debug-session slug opened, row left `waived`).
- The G-01-7 follow-up item is not a ledger row — just record its PASS/FAIL in the same
  `## Resolution` section, with a debug-session slug on FAIL.
- Once all 7 entries and the G-01-7 follow-up are recorded, close this todo:
  `node ~/.claude/gsd-core/bin/gsd-tools.cjs todo complete 2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md`
