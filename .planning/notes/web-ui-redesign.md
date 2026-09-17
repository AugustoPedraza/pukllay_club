# Admin "Web" tab — UI redesign

**Started:** 2026-09-17 (handoff: `.planning/notes/admin-web-redesign-handoff.md`)
**Scope:** the admin Web tab — the public home page's rows ("Filas del inicio"). Today:
`lib/pukllay_club_web/live/admin/section_live/index.ex` + `edit.ex`; last design sketch 065 (starting point to question).
**Carries:** D-19a–j (`01.8.2-CONTEXT.md`), estante restart decisions 1–68 (`estante-ui-restart.md`), sketch 069 components.

## Context carried in
Dev data (2026-09-17), home order:
| Row | Kind | Games |
|---|---|---|
| Destacados del club | manual, featured (pinned first, cap 20) | 7 |
| Crea conexiones | manual | 61 |
| Equipo ganador | manual | 54 |
| Duelos memorables | manual | 19 |
| Descubre el hobby · Ingenio estratega · Nivel experto | weight_band (automatic) | — |
| Recientemente añadidos | recent (automatic) | — |

Rows are hide-only (no delete). Staff edit name, subtitle, hidden, sort; add/remove/reorder games on manual rows;
reorder non-featured rows with ↑/↓.

## Decisions

1. **The main job is swapping the featured games** (Destacados). Three kinds of home row, by how often they change:
   - **Destacados** — the pinned featured row; changed often (before a club night, new arrivals). Its **name is
     editable** (e.g. "Selección de Sábado").
   - **Temporary lists** — come and go ("Favoritos de Lacerda"; Netflix's "Emmy nominated").
   - **Static rows** — set up once: Crea conexiones, Equipo ganador, Duelos memorables, the Nivel rows, Recientes
     (Netflix's "Thrillers").
   Developer: *"I think that Swap Destados. Even that name should be editable (Could be like "Selección de Sábado").
   Eventually, we could have a new session like "Favoritos de Lacerda" or another lists. But the "Crea Conexiones",
   "Equipo Ganador" and etc are more like "estatic" lists. If we do an analogy with Netflix, we have always like the
   "thriler" movies, but eventually we can have "temporally" list (Emmy nominated for example)."*
   Fits today's model: featured name already editable; a temporary list is a manual row, hidden when its time is over
   (hide-only keeps its games).

2. **Web opens on Destacados.** The page's one job (D-19j) is the featured row itself: its editable name and its games,
   with add / remove / reorder in place — swapping takes no extra tap. Temporary lists and static rows move behind a
   header icon (as the gear → Administrar estantes). Rejected: Destacados + temporary lists as a list of entries (one
   tap to the games); 065's all-rows list with Destacados pinned first (no single job).
   Developer picked "Opens on Destacados (Recommended)".

3. **The featured games are the estante rail** (069), which is also how the public home shows the row: covers in home
   order; tap a cover → lifted (−12px + shadow) with a "+" on each side (add a game in that spot); tap the lifted cover →
   options sheet (Ver ficha · Mover · Quitar, Deshacer snackbar). Order is what you see. Rejected: cover·name list rows
   with ⇅ Ordenar mode (faster multi-remove, ~1300px of rows); 3-column cover grid (fits one screen, unlike the home).
   Developer picked "Rail, like the home (Recommended)".

4. **The row name sits under the title.** Page title stays "Web" (22/600); directly under it the row name at prompt rank
   (17/600) with a pencil → the name sheet (restart 67 shape: field pre-filled and selected, Guardar); then the rail.
   Rejected: the name as the page title (long names wrap, "Web" only in the tab bar); the name as muted context with
   renaming in a ⋯ sheet (one step away from the thing staff edit).
   Developer picked "Name under the title (Recommended)" (after asking what "22/600" meant — use plain words for type
   sizes in questions: "22px, semi-bold").

5. **A "+" in every gap of the rail, always visible** — before the first cover, between every two, after the last — the
   same spots "¿Dónde va?" offers on an estante. Adding needs no selection first. Consequence: nothing is lifted on
   arrival, and tapping a cover opens its options sheet directly (the lift existed only to reveal the "+").
   Cost (to measure in the sketch): each gap grows 10px → a 44px hit target; ~2.8 covers visible at 375px instead of
   ~3.5; a 20-game row ≈ 2,840px wide instead of ≈ 2,110px.
   Developer: *"what if we add + on middle of the "sections"? Same affordance that the "estantes" has."* → picked
   "A "+" in every gap" over "middle cover lifted on arrival". Rejected before that: a "+ Agregar" tile at the end,
   first cover lifted, "+" in the header.

6. **Other rows behind one header icon** (rows icon, 44px A3) → a **"Filas del inicio"** page (`‹ Web`): every row in home
   order, the featured row first and locked; header ⇅ Ordenar + "+" Nueva fila; row → sheet (Editar · Ocultar/Mostrar).
   Same shape as gear → Administrar estantes. Rejected: two pages (temporary / static — they share one home order);
   a "Otras filas del inicio ›" link under the rail (a secondary entry under the main control, against D-19j).
   Developer picked "One header icon (Recommended)".

## Sketch 070 (round 1, 2026-09-17) — built from decisions 1–6
Measured 375×667: title → name 16.8; name → context 5; context → covers 16; cover to cover 44; ~2.6 covers visible
(2 whole); rail 1,032px at 7 games / 2,852px at 20; sheets end at the keyboard. Choices made without asking (flag for
review): context line "Primera fila del inicio · 7 de 20 juegos"; idle "¿Qué juego va acá?" lists "Llegaron hace poco";
Quitar confirms in a dialog (D-19f) + Deshacer; at 20 the "+" dims and explains the cap; subtitle not on the name sheet.

7. **"Destacada" is a role, not a row.** Any row can be the highlighted one (the pinned first row that Web opens on);
   "Destacados del club" is just the name the current one happens to have. There is always at least one highlighted
   row. On Filas del inicio the highlighted row sits in its own group, separated from the rest (not a locked first row
   in the same list).
   Developer: *"On the list of "sections" the "bloqued" at top should be dynamic. I mean, any one can be the
   "highlighted" (not just "destacados"). "Destacados" is just a random name. Always I should have a least one on
   "highligthed". On the list of sections, the "highlighed" should be separated of the rest."*
   Today's model: `sections.featured` is a boolean with one featured row created by the migration; making it movable
   means "set featured" on another row clears it on the old one (and the 20-game cap follows the role).
   **Exactly one** highlighted row at a time: highlighting another takes the role from the old one, which stays as a
   normal row. Web keeps one job (it opens on that row). Rejected: one or more (Web would need several rails or a
   chooser). Developer picked "Exactly one (Recommended)".
   **Only hand-picked rows can be highlighted**; automatic rows (Nivel, Recientes) never get "Destacar", so Web always
   opens on a rail staff can edit. Rejected: any row (Web would lose its job while an automatic row held the role).
   Developer: *"I think #1 is the correct one, since the "automatic" sections aren't "editable" (since are automatic).
   So only custom sections are able to be highlighted."*

## Sketch 070 round 2 (2026-09-17) — decision 7 drawn
Filas del inicio: "Destacada" group (1 row) and "Las demás filas · 8", group gap 32 (last row → next heading), same
heading anatomy as 069 Pendientes. Destacar sits first in a hand-picked row's sheet ("Pasa a ser la primera fila del
inicio"); the new destacada moves to the top, the old one heads the rest, a hidden row becomes visible, snackbar
"{fila} es la destacada" + Deshacer. The destacada's sheet has no Ocultar (the home always shows it). Choices made
without asking: a row with more than 20 games cannot be destacada (sub-line says why); where the old destacada lands.

8. **Grouping kept; no hint lines under the group headings.** A row with more than 20 games cannot be destacada, and
   the old destacada heads the rest — both accepted. "Las demás filas" needs better copy.
   Developer: *"Grouping feels right. I think that is ok. What I want a better balance and copy is for the blocks.
   Destacada is ok, but the "las demas filas" sounds weird. not subtitle needed"*

9. **The second group is "Otras filas"** (Destacada / Otras filas); neither heading carries a count, so the two read as a
   pair. Rhythm measured at 375×667: title row → "Destacada" 16; heading → first row name 16.5; last row → "Otras filas"
   32. Rejected: "Debajo"; "Primera / Las siguientes". Developer picked "Otras filas (Recommended)".
   Balance fix, measured on what is visible (tile edges and heading text, not boxes): a row's tile ends 12px inside its
   box, so the 32px box gap read as 44 against 16 above. Group margin now makes it title → "Destacada" 16 · heading →
   tile 16 · tile → "Otras filas" 32 · heading → tile 16, both themes.
   Developer: *"yes, balanced now."*

10. **Quitar de la fila has no dialog**: the game leaves the row at once with "Juego quitado" + Deshacer (10 s); the sheet
    row loses its red and its "· te pedimos confirmar". Removing from a home row keeps the game and its shelf spot, and
    Deshacer restores the exact spot — a 5-game swap is 10 taps, not 15. App-wide as **D-19k** (CONTEXT + BENCHMARK):
    removing from a curated list is not destructive; D-19f's dialog stays for losing state staff must rebuild.
    Rejected: keep the D-19f dialog. Developer picked "No dialog, just Deshacer (Recommended)".

11. **"¿Qué juego va acá?" opens on "Últimas novedades"**: the 6 most recently added games not already in the row, under
    the search field — featuring new arrivals is a likely reason to swap, so often one tap, no typing. Label renamed
    from "Llegaron hace poco". Rejected: "Quitados hace poco" first; the search alone.
    Developer kept the recommended behaviour with a note: *"Named Ultimas novedades"*.

12. **Every hand-picked row is edited on the same page as Web.** Filas del inicio → row sheet → **Juegos** opens that row
    on Web's page: `‹ Filas del inicio`, name + pencil, context "Elegida a mano · N juegos", the rail with "+" in every
    gap, the same add / options / Mover sheets and Deshacer. Web is that page opened on the destacada; Destacar only
    changes which row Web opens on. The 20-game cap and "Primera fila del inicio" apply only to the destacada.
    Measured 375×667: back link → name 8 (≈20 between visible text, as ‹ Web → title on Filas); context → covers 16;
    Crea conexiones' rail is 8,592px (61 covers) — the long swipe was accepted with this option. Adding a game there
    updates its Filas count (61 → 62).
    Rejected: a list page for long rows (two editors); a "Buscá en la fila" field over the rail (a second control above
    the main one). Developer picked "Same page as Web (Recommended)".

13. **Nueva fila opens the new row's page** (after Crear fila): `‹ Filas del inicio`, its name, "Sin juegos, no se ve en el
    inicio" and the empty rail's "+" — ready for the first game. Developer: *"yes"*.

(Round 5 asks, 2026-09-17, developer's words:)
- *"Subitle could me a little more meaningful without breaking balance (is automatic? how many games has?)"*
- *"yes (I need to access its options to from the bottom-sheet)"* — a row's options sheet reachable from its page.
- *"PLus I want to improve what the "web" initial page shows since is too empty right now and it breaks rythm"*
Facts found: a non-destacada row shows at most **30** games on the home page (`@carousel_infinite_scroll_max`);
the destacada at most 20. Published games per Nivel (dev): Descubre el hobby 179 · Ingenio estratega 183 · Nivel
experto 46 (26 without a band). Recientes shows the newest 30.

14. **A row's second line = [● status ·] a kind tag + its count.** Copy: **Personalizada / Automática** (replaces "Elegida
    a mano", "Por nivel", "Los últimos que llegaron"); counts: destacada "7 de 20", hand-picked "61 juegos" (or
    "Vacía"), Nivel rows their published games ("179 juegos"), Recientes "los últimos 30".
    Developer: *"But needs better copy. A mano isn't meaningufl at all."* → then *"but could looks more like a "tag" or
    something like that instead of like pure text?"* → *"show me variants 1 and 2"*.
    Tags are not statuses (D-19h allows them). Variants on tools → Etiqueta, measured 360/375 × both themes:
    - **T1 Tonal** — 20px, 12/600, tile tint fill + accent text: text 12.25:1 light / 10.49:1 dark; fill vs page only
      1.16 / 1.11 (the tag's edge is carried by its text colour, like the icon tile).
    - **T2 Contorno** — 20px, 1px --stroke, muted text: text 6.17 / 6.90; border vs page 4.31 / 3.48 (≥3:1).
    Both: second line stays one line (20px) at 360 even with ● Oculta (276/276px), rows stay 64px.

15. **Tag = Contorno; count = Esquina badge on the tile.** Developer: *"I like contorno and esquina variants. Remove the
    another and then review the full balance to have it correct since now it breaks rythm"* — note this reverses the
    previous turn's "Tonal is better" for the tag (flagged; kept the later word). Losing variants and their toggles
    removed from the sketch.
    Count badge: 18px pill hanging 5px off the tile's bottom-right, page fill + 1px --stroke + 11/600 muted (the
    Pendientes badge is top-right, filled primary, white — different corner, different colour). It clears the row
    divider (badge right 61, divider starts at 68). The count is in the tile's accessible name ("61 juegos").
    **Balance pass after removing them** (375×740, both themes, measured, not eyeballed):
    - the status gap went back to 069's 6px (it had become 8);
    - a 20px tag sits 4px lower than a 13px text line, so the second line's box gap goes to 0 (`.sub:has(.tag)`) and the
      row keeps its rhythm: content top 12.3 vs tile top 12, row still 64;
    - one vocabulary everywhere: "Elegida a mano"/"Por nivel"/"Los últimos que llegaron" → **Personalizada / Automática**
      (list rows, sheets, the name sheet's context);
    - the row PAGE drops the kind tag and keeps only state ("7 de 20 juegos", "61 juegos", "● Oculta · …"): on the page
      you are already inside that row, and the long "Personalizada 7 de 20 juegos · primera del inicio" broke the line.
    Rhythm on Web unchanged: title → name 16.8 · name → context 5 · context → covers 16.

16. **The kind tag steps back** (developer: *"Still the label for "personalizada" takes too much weight. Alternatives?"*):
    11px regular (was 12/600), 18px tall, hairline `--color-border` instead of `--stroke`, muted text, and the word in
    **lowercase** — "personalizada" / "automática". Measured 375×740 both themes: tag text 6.17:1 light / 6.90 dark
    against the row name's 17.16 / 13.62, so the name clearly leads; the border is decorative (1.42 / 1.30) and carries
    no meaning; row height 64 and content top 12.8 vs tile 12 unchanged. Sheet contexts read "Fila personalizada" /
    "Fila automática" / "Fila destacada".
    Rejected: tagging only automatic rows (two row heights in one list); dropping the tag for the row's public subtitle.

17. **The row name opens the row's options sheet** (Web and any row page): the pencil is gone; the name is a 44px-tall
    button with a ⌄ chevron, opening the same sheet Filas uses, with **Editar nombre** inside it — one target instead of
    two, and the name is no longer a button that only renames.
    On a row page the sheet drops **Juegos** (you are on it). The destacada's page sheet would have held one row, so it
    gains **Cambiar la destacada** → Filas del inicio ("Elegir otra fila para el inicio"). A non-destacada row page keeps
    Destacar · Editar nombre · Ocultar del inicio.
    Measured: hit box 44.1px; a **wrapped two-line name** was overlapping the context line by 6px because a 44px
    min-height only has slack while the name is one line — the button now uses 11px padding, so one line (44.1) and two
    lines (66.2) keep the same 5px of visible air above "7 de 20 juegos"; no horizontal scroll at 375.
    Caught while measuring: the ⌄ drew an empty SVG (this sketch's icon set had no `chevD`).
    Rejected: a ⋯ header icon beside the pencil; an "Opciones de la fila ›" row under the rail (D-19j).
    Developer picked "The name opens the sheet (Recommended)".

18. **Web is ONE page: the destacada edited inline, the other rows listed under it.** Filas del inicio disappears as a
    page; its ⇅ Ordenar and + Nueva fila move into Web's header (the rows icon is gone), and "Otras filas" is a group
    under the rail. A row opened from that list gets the same page with `‹ Web` and no list. The destacada's own sheet
    row is now "Cambiar la destacada · Elegí otra fila de la lista y tocá Destacar", which scrolls to the list.
    Developer: *"what if we combine there as "inline" highlighted row edition and below the rest of sections?"* → picked
    "All rows, no separate page (Recommended)".
    **Why it was needed** (measured before, 96px covers, 7 games): the content block was a constant 250px pinned to the
    top and the blank below ran 245px at 360×640 (47%), 272 at 375×667 (50%), 345 at 375×740 (56%), 449 at 390×844
    (62%). Now the page is 914px tall: 3 rows visible under the rail at 375×667, 6 at 390×844, the rest scrolls.
    Rhythm: last caption → "Otras filas" 32 · heading → first tile 16 (rail 8 + 16 + the heading's own 8).
    Also **the ⌄ chevron beside the name is gone** (developer: *"the chevron at the "destacados" is weird. remove it"*) —
    the name still opens the options sheet.
