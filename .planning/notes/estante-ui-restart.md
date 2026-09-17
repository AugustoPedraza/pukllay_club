# Estante UI — restart (01.8.2, after sketch 068)

**Started:** 2026-09-16. Developer: *"Let's start over all of this UI. Ask the question and I'll let you
know. Be sure to focus only on that UI."* Sketches 066–068 are the record; the new sketches are
**standalone pages with only the estante UI** — no 065 walk bar, no other admin pages, no tools menu.
Decisions are taken one question at a time and recorded here.

## Context carried in
- Real shape: 9 horizontal estantes, up to 50 boxes each; 434 real games, 385 with covers.
- Real-world priority: locating a box (put back after a club night / pick up) is the frequent job;
  adding a new game, ordering and removing are infrequent.
- No checkout state until Phase 4: the app knows a game's spot, not whether the box is on the shelf now.

## Decisions
1. **Entry = search.** Staff holding a box type its name. *"I know the estante has the A, B, C games. When
   I pick game B this should let me know that goes on that space."*
2. **Search is an autocomplete that resolves to ONE game.** Typing shows a short suggestion list (cover +
   name); picking one shows the answer. Families (Catan ×5, Carcassonne…) are told apart by cover.
3. **The answer is a picture of the estante with the spot marked**, always with its neighbours.
4. **Placed game → drawn in its spot, highlighted, between its neighbours.** A game that is not on the
   estante is drawn as an empty spot (developer: *"shows an empty game when the game isn't on the
   estante"*) — in this phase that can only mean a game with no spot (Sin ubicar); "out on a table" needs
   Phase 4 checkout state.
5. **A picked game with no spot (Sin ubicar)** → says so ("Todavía no tiene lugar") + ONE action to give it
   a spot: choose the estante; it goes at the right end (D-00c).
6. **The picture is the whole estante as a swipeable row of covers**, opened at the spot with the game
   highlighted between its neighbours (developer picked option 3 of: close-up + whole-shelf strip /
   close-up only / whole shelf scrollable). Measured widths at 343px: 3 covers = 109px, 5 = 62px,
   7 = 42px, whole 50-box shelf = 6.9px per box.
7. **The picture appears under the search, on the same screen.** *(revised by 11)* ~~The picked game stays
   in the field.~~
8. **Words: the estante name only** ("Estante 1") above the picture. No box number, no "entre X y Y" —
   the highlighted cover and its neighbours say where.
9. **The answer offers a few actions, in a sheet:** Mover, Quitar del estante, Ver en la ludoteca.
10. **Tap the highlighted cover → its sheet.** No ⋯, no link. **Tap another cover → the selection moves**
    to that game (it becomes the highlighted one; tapping it again opens its sheet).
11. **The search field clears the moment a game is found** (developer: *"The search should be cleared on
    the moment there is a found game"*). The field is immediately ready for the next box; the highlighted
    cover's caption is what names the selected game. Tapping another cover moves the selection; the
    field stays empty.
12. **Typing the next box: the suggestion list drops down over the current picture**; the picture stays
    underneath until a new game is picked, then it is replaced.
13. *(revised by 18)* ~~**Before searching, the screen lists the estantes**~~, each with a *meaningful* icon. The search field has
    a **placeholder with instructions** and an **icon on the right**.
14. *(moves to the management page, 18)* **The estante row icon is a small shelf drawing, filled in proportion to how full the estante is.**
15. **Search placeholder: "Buscá un juego para ubicarlo"** (covers putting back and picking up).
16. **Right icon: magnifier**, turning into ✕ (clear) while there is text.
17. *(management page, 18)* **Estante row: name as title ("Estante 1"), total games as subtitle ("48 juegos").** Note: D-04 counts
    copies; today no game has more than one copy, so the two numbers agree — revisit wording if copies > 1.
18. **The Estantes screen is for picking up and putting back games — search first. Estante management is a
    secondary page reached from it** (developer: *"Could estantes management be a secondary page that needs
    to be navigable from 'estantes'. I want to prioritize the search for pickup/return a game. Not for
    estantes management."*). The estante list (shelf-drawing icon, name + "N juegos") lives there, with
    browsing a shelf, adding games, ordering, renaming and deleting.
19. **Management is reached from a text button in the page header**, beside the title ("Estantes ·
    Administrar").
20. **Below the search, before searching: recent lookups.** The developer also wants **"missing games — what
    must be returned"** there; that needs checkout state, so it is **deferred to Phase 4** and takes the
    same place on this screen when it exists.
21. **Recent lookups are list rows**: cover, name, "Estante 1" as subtitle. **Tapping one behaves exactly
    like picking it from a search** (field clears, picture appears). A game with no spot shows its status
    as **a dot + text** in the row, not a pill.
22. **App-wide rule (developer): status is shown as a dot + text, never a pill** — *"I want that to be the
    default for replace pills status across all the app."* Applies to every status indicator (e.g. Juegos'
    Borrador/Retirado, Sin lugar here). Tag/filter pills are not statuses and are not affected. → CONTEXT.
23. **The found game's cover is "lifted"** in the picture: raised a little with a shadow, as if pulled out
    of the shelf; neighbours unchanged.

## Round 2 feedback on sketch 069
24. **"Últimas búsquedas"**, not "Buscados recientemente" (too technical). The block had too much weight:
    now a plain grey label, **3 rows**, compact 48px rows with 32px covers.
25. **A chevron means "navigates".** Recent rows show their answer in place, so they have no chevron. Rows
    that open another page (management list) keep it.
26. **Management entry = a gear icon button (A3) at the right of the "Estantes" title**, no text
    (aria-label "Administrar estantes"). The "Administrar" text broke the header's balance.

## Round 3 — where the search sits
Developer: *"How can the search be more centred? Below 'Últimas búsquedas' there is too much space. Ideas?"*
→ *"Build them as variants so I can try them."* Sketch 069 *tools → Diseño*, with a simulated 292px keyboard:
- **A · Abajo** — search sticky above the tab bar; recents and the answer stack above it; suggestions open
  upward. Measured: idle field 613–661 (12px above the tab bar); with the keyboard, field 388–436 and
  suggestions 112–384, both clear of the keyboard (448).
- **B · Centrado, sube** — title + search + recents centred while idle (field 262–310); focusing or an answer
  moves it to the top (field 121–169), animated.
- **C · Pregunta** — B plus a shelf drawing and "¿Qué juego tenés en la mano?" above the field (field 318–366);
  the prompt goes away once raised.
- **D · Arriba (hoy)** — unchanged (field 121–169; ~310px empty below recents).

27. **Layout C · Pregunta wins**; A, B and D are removed from the sketch. Idle: a shelf drawing and
    **"¿Qué juego tenés en la mano?"** above the search, with Últimas búsquedas below, centred between the
    title row and the tab bar. Focusing the field or showing an answer removes the prompt and moves the search
    to the top (animated; no motion under reduced-motion).
28. **Spacing balance for C** (developer: *"improve the balance of the elements' spaces"*). Measured before:
    icon→question 0px, question→field 8px, group centre 387 of a 393px area (reads as sinking). Now, on the
    8px scale and grouped by what belongs together: **icon→question 16, question→field 24, field→Últimas
    búsquedas 40**, and the free space splits **2:3 above:below** (optical centre; group centre 372).
    Raised state unchanged: title→field 8, field→estante 20, estante→Últimas búsquedas 24.

## Where we are (2026-09-16, end of session)
- **Current sketch:** `.planning/sketches/069-estantes-ubicar/index.html` — standalone, hand-written (no
  build step), uses `games.js` (434 real games) and `../themes/default.css`. View with
  `python3 -m http.server 8765` from the repo root →
  http://127.0.0.1:8765/.planning/sketches/069-estantes-ubicar/index.html
- **Done in 069:** decisions 1–28 above (search → autocomplete → estante rail with the game lifted;
  Últimas búsquedas; Sin lugar + Ubicar; cover sheet; gear → management stub; layout C with balanced spacing).
- **Not committed yet:** sketches 068 (superseded record) and 069, this notes file, MANIFEST rows. Commit before
  or after the next round: `docs(sketch-069): …`.
- **Open items found on the way:** Catan family ranking in suggestions (`cat` shows 1 of 5 editions); the
  shelf-drawing icon reads like a barcode at 28px; status rule (22) still needs to go into
  `01.8.2-CONTEXT.md`.
- **Working agreement:** the developer asks/answers one question at a time; sketches show ONLY the estante UI
  (no 065 walk, no tools beyond Tema/Teclado); measure before building variants; record every decision here.
- **Next:** the developer had more feedback on 069 queued. After 069 settles: the management page (list,
  estante page, Agregar juegos, Mover, Quitar, rename/delete D-10), then sketch 074 (staff tab bar on public
  pages, D-14), then `/gsd-plan-phase 01.8.2`.
