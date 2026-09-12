---
phase: quick-260912-pny
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/todos/pending/2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md
autonomous: true

must_haves:
  truths:
    - "A pending todo exists that a human can pick up and run as ONE browser session covering WINDOWS.md entries 3, 4, 5, 7, 13, 18 and 24"
    - "Every checklist item names an exact route from router.ex, an exact viewport width, the real control labels/selectors from the current code, and a single observable pass criterion"
    - "Pass criteria describe CURRENT shipped behaviour, not the stale wording frozen in the ledger rows (entry 4 footer, entry 24 Cierre height mechanism)"
    - "The todo says how to record a pass (windows fixed <id>), states the verified CLI limitation for waived rows and the fallback, and routes failures to /gsd-debug"
    - "No file under lib/, assets/, test/, config/ or priv/ changes"
  artifacts:
    - path: ".planning/todos/pending/2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md"
      provides: "Human browser verification checklist todo"
      contains: "### Entry 24"
  key_links:
    - from: "todo checklist"
      to: ".planning/WINDOWS.md entries 3,4,5,7,13,18,24"
      via: "Entry <id> headings + windows fixed <id> recording instruction"
      pattern: "windows fixed"
---

<objective>
Capture a single pending todo, in the established `.planning/todos/pending/` format, that turns the seven waived-but-never-human-verified WINDOWS.md UI entries (3, 4, 5, 7, 13, 18, 24) into one concrete browser verification session: exact route, exact width, real labels/selectors, one pass criterion per item, plus how to record results and where failures go.

Purpose: these rows were waived on 2026-09-12 purely to unblock /gsd-ship with "residual risk accepted". The todo keeps that residual risk visible and cheap to retire in one sitting instead of being forgotten.
Output: one new todo markdown file. Planning-only. No code, CSS, test, config or priv changes.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
@~/.claude/gsd-core/workflows/add-todo.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/WINDOWS.md
@.planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md

Planner findings, all verified against the tree on 2026-09-12. The executor should treat these as the source for the todo body and re-ground them with the verify greps, not re-derive them.

**Todo tooling:** there is no `todo add` CLI verb. `gsd-tools todo` only has `complete` and `match-phase`, so write the file directly in the add-todo.md `create_file` format. `gsd-tools query init.todos` supplies `timestamp`. `.planning/todos/pending/` does not currently exist on disk (git drops empty dirs). The Write tool creates it.

**Windows CLI (load-bearing):** `gsd-tools windows` subcommands are `status, append, waive, fixed`. `markFixed` in `~/.claude/gsd-core/bin/lib/broken-windows.cjs` calls `assertOpen`, so it only accepts `open` rows. The planner ran `windows fixed 3 --project-dir <scratch copy of the ledger>`. It refused with `Error: Window 3 is already waived (resolved_at=2026-09-12T21:18:08.219Z).` and left the ledger unchanged. All 7 target rows are `waived`. The ledger is a JSON entries block whose frontmatter counts the parser cross-checks (`WINDOWS_LEDGER_MALFORMED`), so hand-editing WINDOWS.md is unsafe.

**Routes (lib/pukllay_club_web/router.ex):** `live "/"` (CatalogLive.Index), `live "/club"` + `live "/quienes-somos"` (AboutLive), `live "/juegos/:id"` (CatalogLive.Show).

**Game ids (local dev DB `pukllay_club_dev`):** 179 = 7 Wonders Duel. Designers: Antoine Bauza, Bruno Cathala. Artist: Miguel Coimbra. 137 = Wingspan. Designer: Elizabeth Hargrave. 4 artists, including "Greg May (II)". Production was restored by upserting on `csv_row`, so production ids may differ. On https://pukllay.club, find these games by name from `/`.

**Entry 3/4, mobile drawer (lib/pukllay_club_web/components/layouts.ex):**
- The trigger is `button.pk-nav-hamburger`, `aria-label="Abrir menú"`, `aria-controls="pk-nav-drawer"`, with `aria-expanded` toggled by the hook.
- The panel is `aside#pk-nav-drawer.pk-drawer` with `role="dialog"`, `aria-label="Menú"`, `inert` when closed. The backdrop is `.pk-drawer-backdrop`. The close button is `.pk-drawer-close`, `aria-label="Cerrar menú"`.
- Links are in `nav.pk-drawer-links`: "Inicio" (`/`) and "Quiénes Somos" (`/quienes-somos`). Each has a `.pk-drawer-chevron`. The active row is `aria-current="page"` with a left accent.
- `.pk-drawer-bottom` holds the social links plus the theme toggle. Its buttons are "Usar tema del sistema", "Usar tema claro" and "Usar tema oscuro".
- The `.CatalogNav` hook focuses the close button on open. Escape closes. Tab/Shift+Tab wrap inside the panel. The backdrop click and close button close it. On close, focus returns to the hamburger. A link navigation also closes it.
- In CSS, the hamburger, drawer and backdrop are `display:none` at base. They are shown only inside `@media (max-width: 480px)` (assets/css/app.css ~6399).
- **Stale ledger wording in entry 4:** since quick 260902-fdm (sketch 044 winner H), the ≤480px footer shows ONLY the BGG attribution line ("Powered by BGG"). `.pk-footer-copyright` is `display:none` at ≤480px, and `.pk-footer-left`/`.pk-footer-right` are hidden. The entry's "keeps copyright+BGG attribution" is superseded by design. The pass criterion must say attribution-only.

**Entry 5, About sticky CTA bar (about_live.ex ~897, app.css ~3242/~3279/~6757/~6911):**
- `div#pk-about-cta-bar.pk-about-cta-bar` contains the shared "Sumate" CTA (`Layouts.sumate_cta/1`). It is `display:none` at base and `display:block` only at ≤480px.
- The bar starts hidden (translateY + visibility hidden). It slides in once `#about-hero` has `.is-docked` (the hero isologo has morphed into the header). No auto-hide in either scroll direction, by design (sketch 053).
- `body:has(.pk-about-cta-bar)` reserves document-end clearance from `--pk-about-cta-bar-h`, so the footer is never under the bar.
- At ≤480px, `#cierre .pk-about-cierre-cta` (the Cierre band's own Sumate button) is hidden because the bar replaces it.
- The detail page has its OWN, different `.pk-mobile-cta-bar` (reserve/share). Seeing that on `/juegos/:id` is NOT a failure of entry 5.

**Entry 7, About photo rail (about_live.ex ~434-620, `.AboutCarousel` hook):**
- Markup: `section#fotos` > `#about-carousel`, with five `figure.pk-about-slide` elements inside `[data-rail]`.
- Dots are in `[data-dots]`: five `button.pk-about-dot` with `aria-label` "Foto 1" through "Foto 5" and `data-goto` 0-4. The active dot gets `.is-active` + `aria-current="true"`.
- Scrolling the rail updates the active dot. The last dot activates when scrolled to the end.
- Auto-advance runs every 4500ms. It skips while paused, while `!document.hasFocus()`, or while `prefers-reduced-motion: reduce` matches.
- `mouseenter` pauses and `mouseleave` resumes immediately. `pointerdown` (touch/swipe/dot tap) pauses and resumes after 6s idle.

**Entry 13, active filter chips vs heading (catalog_live/index.ex ~1075-1110):**
- The heading is `h2.font-display.text-2xl` reading "Resultados" when filters are active, else "Toda la ludoteca". Below it is a `text-neutral text-sm` count line.
- Beside it is a chip row of `button.pk-active-filter-chip.pk-pill.pk-pill-accent.pk-pill-comfortable.pk-pill-interactive.min-h-11`, with a trailing `.pk-active-filter-chip-x` "×". A `button.pk-clear-filters-link` reads "Limpiar filtros".
- `/?players=4&max_playtime=60` yields the chips "Jugadores: 4" and "Duración máx.: 60 min". The params parse via `CatalogFilters.parse_int/1`, and about 229 dev games match.
- Sketch 029's intent is that the chip row is "clearly secondary" (soft accent tint, no shadow).

**Entry 18, creator pills (catalog_live/show.ex ~654-680, `creator_pills/1` ~1248):**
- Rendering: `dl.pk-spec-list` > `.pk-fact-cols` > `dt` "Diseñadores" / "Ilustradores" > `a.pk-pill.pk-pill-outline.pk-pill-interactive`, inside `.pk-chip-row`.
- Navigation: designer pills go to `~p"/?designers=#{name}"` and artist pills to `~p"/?artists=#{name}"` (percent-encoded).
- Landing state: the index shows a chip "Diseñador: <name>" or "Ilustrador: <name>".
- Hover on desktop: border and ink go to `--pk-ink-brand`.
- `creator_pills/1` carries NO `min-h-11`, unlike the index chips, so the tap-target height must be measured, not assumed. The project touch minimum is 44px (ux-responsive skill).
- 01.3-UAT test 1 already confirmed the other 4 sub-items of this row. Only "tappable creator pills" is unverified.

**Entry 24, Cierre band (about_live.ex ~828-845, app.css ~3409/~3416-3510):**
- Markup: `section#cierre.pk-band.pk-band-tint`, containing h2 "Nos vemos el sábado", the Sumate CTA (wrapper `.pk-about-cierre-cta`), and `p.pk-about-closing-meta` "Pukllay Club · San Salvador de Jujuy, Argentina".
- **Stale ledger wording:** the "70vh proportion" floor was retired. 01.5-07 reduced it and 01.5-09 replaced the viewport-height floor with a fixed `padding-block: 5rem` (80px) at `min-width: 640px`. The h2 uses `font-size: clamp(2rem, 4vw, 3rem)`.
- The inner is a flex column with `align-items:center` and `gap:1.5rem`.
- Top and bottom band whitespace should be identical by construction.
- The footer gets a page-scoped fill (`body:has(#cierre) .pk-footer`, 01.5-11), so it has a legible top edge against the tinted band.
- 375px/1280px were already human-checked (01.5-UAT test 20). 768px was never checked.
- 768px is above 480px, so no sticky CTA bar and the Cierre Sumate button IS visible.

**Environment caveat (STATE.md, Phase 01.2 decision):** a browser automation tool once pinned its viewport near 339-390px regardless of resize. The 1440px/768px checks need a real desktop browser (Chrome DevTools device toolbar, Responsive, exact width typed in), not that tool.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write the browser verification checklist todo</name>
  <files>.planning/todos/pending/2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md</files>
  <read_first>
    - .planning/WINDOWS.md (rows 3, 4, 5, 7, 13, 18, 24: description + reason columns)
    - ~/.claude/gsd-core/workflows/add-todo.md (create_file step: frontmatter keys and Problem/Solution sections)
    - .planning/todos/completed/2026-09-07-surface-pukllay-club-brand-name-in-content.md (house style for a todo with a dated Resolution section)
    - lib/pukllay_club_web/router.ex (confirm the three live routes)
  </read_first>
  <action>
Run `node ~/.claude/gsd-core/bin/gsd-tools.cjs query init.todos --pick timestamp` to get the `created` value. There is no `todo add` verb, so write the file directly with the Write tool at exactly `.planning/todos/pending/2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md`. The slug came from `gsd-tools query generate-slug "Browser verification session for waived Windows UI entries"`.

**Frontmatter** (add-todo.md create_file format):
- `created`: the timestamp from above.
- `title`: "Browser verification session for waived Windows UI entries".
- `area`: `ui`. This matches every existing todo.
- `severity`: `minor`. It is a planner discretion call: the waive reasons record accepted residual risk with no known defect. add-todo.md's interactive severity confirmation cannot run inside a batch executor, so state that choice in one sentence at the end of the Problem section.
- `files`: a YAML list of `lib/pukllay_club_web/components/layouts.ex`, `assets/css/app.css`, `lib/pukllay_club_web/live/about_live.ex`, `lib/pukllay_club_web/live/catalog_live/index.ex`, `lib/pukllay_club_web/live/catalog_live/show.ex`, `.planning/WINDOWS.md`.

**Body, in this order:**

1. `## Problem`: the 7 entries were waived on 2026-09-12 (quick 260912-mxt follow-up) only to unblock /gsd-ship, each with "residual risk accepted", and none of them has had a human browser check. Ledger `open_count` is 0, so this session is not ship-blocking. The point is to retire the residual risk in one sitting. Include the severity sentence.

2. `## Session setup`:
   - Where to run it: either the local dev server (`mix phx.server`) or https://pukllay.club.
   - Game ids 179 (7 Wonders Duel) and 137 (Wingspan) are local-dev ids. On production, open those games by searching the name from `/`.
   - Use a real desktop Chrome with the DevTools device toolbar in Responsive mode and the width typed exactly. Include the STATE.md caveat about an automation tool that could not resize past about 390px.
   - Switch themes with the drawer's or footer's "Usar tema claro" / "Usar tema oscuro" buttons.
   - For reduced motion, use DevTools > Rendering > "Emulate CSS media feature prefers-reduced-motion: reduce".
   - Mobile-first: run every 390px check before its desktop counterpart.

3. `## Checklist`: one `### Entry <id> — <short name>` heading per entry, in the order 3, 4, 5, 7, 13, 18, 24. Under each heading, write `- [ ]` checkbox lines, each giving **Route:**, **Width:**, **Theme:** (only where relevant), **Steps:** naming the real labels/selectors from the planner findings, and exactly one **Pass criterion:** line (bold label, verbatim). Content per entry:
   - **Entry 3, drawer behaviour.**
     - Width 390px on each of `/`, `/quienes-somos` and `/juegos/179`.
     - Steps: tap "Abrir menú" (`.pk-nav-hamburger`), then close it four separate ways: Escape, "Cerrar menú", tapping `.pk-drawer-backdrop`, and tapping the "Inicio" or "Quiénes Somos" link.
     - Pass criterion: every close path works on all three routes. On open, focus lands on "Cerrar menú" and `aria-expanded` is "true". Tab and Shift+Tab never leave `#pk-nav-drawer`. After the Escape, button and backdrop closes, focus is back on the hamburger. A link close navigates and leaves the drawer closed.
     - Second line, at 1440px on the same routes. Pass criterion: no hamburger is visible, and tabbing through the whole page never focuses anything inside `#pk-nav-drawer`, because it is display:none above 480px and inert.
   - **Entry 4, drawer + footer layout.**
     - Route `/quienes-somos` (or `/`), width 390px, both themes.
     - Pass criterion for the drawer: Inicio and Quiénes Somos rows read as full-width tappable rows, each with a right chevron. The current page's row shows the left-accent active state. The social links and the three theme buttons sit pinned against the panel's bottom edge.
     - Separate pass line for the footer at 390px: the footer shows only the "Powered by BGG" attribution line, with no copyright, social links, theme toggle or FAQ/Contacto/Juntadas links.
     - Add an explicit note that the ledger row's "keeps copyright+BGG attribution" wording is superseded by quick 260902-fdm (sketch 044 winner H), so a hidden copyright is expected, not a failure.
   - **Entry 5, About sticky CTA bar + footer.**
     - Route `/quienes-somos`, width 390px.
     - Steps: load at top, scroll down past the hero, then scroll to the very bottom.
     - Pass criterion: `#pk-about-cta-bar` ("Sumate") is not visible at page top. It slides in once the hero isologo docks into the header and stays pinned through the rest of the scroll in both directions. At the very bottom, the "Powered by BGG" footer line sits fully visible above the bar with nothing clipped behind it. The Cierre band's own Sumate button is not shown at this width.
     - Second line: at 1440px on `/quienes-somos`, and at 390px on `/` and `/juegos/179`, no `#pk-about-cta-bar` appears at any scroll position.
     - Note that the detail page's own reserve/share bar (`.pk-mobile-cta-bar`) is a different component and is expected there.
   - **Entry 7, About photo rail interaction.**
     - Route `/quienes-somos` `#fotos`, width 1440px with a mouse, plus 390px for the touch lines. The browser tab must be focused.
     - Write one `- [ ]` line each for these sub-checks: dot sync on manual rail scroll (including the last dot when scrolled to the end); click "Foto 3" jumps and highlights dot 3 with `aria-current`; auto-advance about every 4.5s when idle; hover pauses and mouse-out resumes; at 390px a swipe or dot tap pauses and auto-advance resumes about 6s after the last touch; switching to another tab or window stops advancing; with reduced-motion emulation on, no auto-advance happens.
     - Each sub-check gets its own pass criterion phrased as the observable result.
   - **Entry 13, filter chip row weight.**
     - Route `/?players=4&max_playtime=60`, widths 390px and 1440px, light and dark themes. That is 4 combos.
     - Steps: confirm the heading reads "Resultados" and the chips "Jugadores: 4", "Duración máx.: 60 min" and "Limpiar filtros" render.
     - Pass criterion: in all 4 combos the eye lands on the "Resultados" heading first. The chip row reads as clearly secondary (soft accent tint, no shadow, lighter than the heading) while staying legible, and nothing in it competes with the heading.
     - This one is subjective. Note that a "no" is a design finding for /gsd-debug or /gsd-sketch, not a regression.
   - **Entry 18, tappable creator pills.**
     - Route `/juegos/179`, width 390px. Second line at 1440px. Also `/juegos/137` for the four-artist wrap case.
     - Steps: under "Diseñadores", tap "Antoine Bauza". Go back. Under "Ilustradores", tap "Miguel Coimbra". At 390px, measure a pill's rendered height in DevTools.
     - Pass criterion: pills read as tappable (outline pill; at 1440px hover shifts border and text to brand ink). Tapping "Antoine Bauza" lands on `/?designers=Antoine%20Bauza` with a "Resultados" heading, a "Diseñador: Antoine Bauza" chip, and 7 Wonders Duel in the results. Tapping the artist gives the "Ilustrador: Miguel Coimbra" equivalent. On `/juegos/137` the four artist pills, including "Greg May (II)", wrap cleanly without overflow. The measured height is at least 44px, the project touch minimum.
     - Note that `creator_pills/1` has no `min-h-11`, so a height under 44px is a real finding to send to /gsd-debug.
   - **Entry 24, Cierre band at 768px.**
     - Route `/quienes-somos`, scrolled to `#cierre`, width 768px, both themes.
     - Pass criterion: "Nos vemos el sábado", the Sumate button and "Pukllay Club · San Salvador de Jujuy, Argentina" are centred as one group. The whitespace above the heading and below the signature inside the band is visibly equal (in DevTools, `#cierre` computed padding-top and padding-bottom are both 80px). The band reads as a distinct closing moment, neither cramped nor mostly empty. The footer below has a legible top edge against the tinted band. No sticky CTA bar is shown.
     - Add a note that the ledger row's "70vh proportion" wording is stale: 01.5-09 replaced the viewport-height floor with a fixed `padding-block: 5rem` at ≥640px. 375px and 1280px were already human-checked in 01.5-UAT test 20.

4. `## Recording results`:
   - For each entry whose lines all pass, run `node ~/.claude/gsd-core/bin/gsd-tools.cjs windows fixed <id>`. This is the ledger's documented verb, per the WINDOWS.md header.
   - Immediately state the verified limitation. As of 2026-09-12, `markFixed` only accepts `open` rows, so on these 7 waived rows it refuses with "Window <id> is already waived (resolved_at=...)" and changes nothing.
   - Until GSD supports waived-to-fixed, record each pass in a `## Resolution` section appended to this todo: date, entry id, route(s), width(s), theme(s), PASS. Leave the ledger row `waived`.
   - Never hand-edit WINDOWS.md. Its JSON entries block and frontmatter counts are cross-checked by the parser, and a mismatch raises WINDOWS_LEDGER_MALFORMED and breaks /gsd-ship.
   - For any failed line, do not fix it inline. Open `/gsd-debug` with the entry id, route, width, theme, expected (the pass criterion) versus observed, and a screenshot. Note the debug session slug under that entry in this todo.
   - When all 7 entries are recorded, close the todo with `node ~/.claude/gsd-core/bin/gsd-tools.cjs todo complete 2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md`.

Do not touch STATE.md. The quick-batch coordinator owns STATE.md updates for this run. Do not modify WINDOWS.md, and do not run `windows fixed` or `windows waive` against the real ledger. Make no change under lib/, assets/, test/, config/ or priv/. Do not use fenced code blocks in the todo body. Use inline code spans for commands, selectors and routes so the checklist stays scannable on mobile.
  </action>
  <verify>
    <automated>cd /home/apedraza/projects/pukllay_club && F=.planning/todos/pending/2026-09-12-browser-verification-session-for-waived-windows-ui-entries.md && test -f "$F" && head -1 "$F" | grep -qx -- '---' && grep -q '^title: Browser verification session for waived Windows UI entries$' "$F" && grep -q '^area: ui$' "$F" && grep -q '^severity: minor$' "$F" && for id in 3 4 5 7 13 18 24; do grep -qE "^### Entry $id " "$F" || { echo "MISSING ENTRY: $id"; exit 1; }; done && [ "$(grep -o 'Pass criterion:' "$F" | wc -l)" -ge 7 ] && for s in '/quienes-somos' '/juegos/179' '/juegos/137' '/?players=4&max_playtime=60' '390px' '1440px' '768px' 'Abrir menú' 'Cerrar menú' 'pk-about-cta-bar' 'Foto 3' 'Resultados' 'Antoine Bauza' 'Nos vemos el sábado' 'windows fixed' 'already waived' '/gsd-debug' 'todo complete' '## Resolution'; do grep -qF -- "$s" "$F" || { echo "MISSING: $s"; exit 1; }; done && grep -q 'aria-label="Abrir menú"' lib/pukllay_club_web/components/layouts.ex && grep -q 'id="pk-about-cta-bar"' lib/pukllay_club_web/live/about_live.ex && grep -q 'aria-label="Foto 3"' lib/pukllay_club_web/live/about_live.ex && grep -q 'id="cierre"' lib/pukllay_club_web/live/about_live.ex && grep -q '~p"/?designers=#{name}"' lib/pukllay_club_web/live/catalog_live/show.ex && grep -q 'live "/juegos/:id"' lib/pukllay_club_web/router.ex && LT="$(node ~/.claude/gsd-core/bin/gsd-tools.cjs list-todos)" && case "$LT" in *'Browser verification session for waived Windows UI entries'*) : ;; *) echo "list-todos missing todo"; exit 1;; esac && GS="$(git status --porcelain -- lib assets test config priv .planning/WINDOWS.md)" && [ -z "$GS" ] && ! grep -q '^```' "$F" && echo OK</automated>
  </verify>
  <done>
- The todo file exists at the exact path, with add-todo.md frontmatter (created/title/area/severity/files).
- It has 7 `### Entry <id>` sections (3, 4, 5, 7, 13, 18, 24), each with a route, width and at least one `Pass criterion:` line using real labels/selectors.
- The stale ledger wording for entries 4 and 24 is called out, and the pass criteria match current code.
- The recording section names `windows fixed <id>`, documents the verified already-waived refusal and the Resolution-section fallback, forbids hand-editing WINDOWS.md, routes failures to /gsd-debug, and gives the `todo complete` close-out.
- `gsd-tools list-todos` lists it.
- There are zero changes under lib/, assets/, test/, config/, priv/ and in WINDOWS.md.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| planning doc -> future human/agent | The todo is read later as instructions. Wrong recording guidance could corrupt the ledger. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-260912-pny-01 | Tampering | .planning/WINDOWS.md | medium | mitigate | The todo explicitly forbids hand-editing WINDOWS.md, because the JSON block and counts are cross-checked and a mismatch gives WINDOWS_LEDGER_MALFORMED, which blocks /gsd-ship. It records passes in the todo's own Resolution section instead. The verify gate asserts WINDOWS.md is unchanged by this plan. |
| T-260912-pny-02 | Repudiation | waived ledger rows | low | mitigate | Each pass is recorded with date, route, width and theme in the todo's Resolution section, so the verification trail exists even though the CLI cannot flip waived rows to fixed. |
| T-260912-pny-03 | Information disclosure | todo body | low | accept | The body contains only public routes, public game names and CSS selectors from a public repo. No secrets, credentials or production host details beyond the already-public domain. |
</threat_model>

<verification>
- Task 1's automated verify prints OK.
- `git diff --stat` for the executor's commit touches only the one todo file.
</verification>

<success_criteria>
A human can open one todo, run a single browser session, and for each of WINDOWS.md entries 3, 4, 5, 7, 13, 18 and 24 know the exact URL, the exact viewport width, what to tap, what "pass" looks like in today's shipped UI, how to record the pass, and where a failure goes. No source code changed.
</success_criteria>

<output>
Create `.planning/quick/260912-pny-capture-a-pending-todo-in-planning-todos-pending-for-a-singl/260912-pny-SUMMARY.md` when done
</output>
