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

## Round 4 — the game's options sheet
Developer: *"the bottom sheet displayed for options on a game (after I tapped) is weird. Cancelar? the options
aren't clear. Needs better balance."* Measured before changing anything (420px): Cancelar was a 4th 48px row with
the ‹ back chevron, the same size and weight as the options, right under the red Quitar row, and it did the same
thing as a tap outside, a drag down or Esc. Its title was 16/600 and the rows 16/400, so the header and the options
had the same weight, with 0px between them. The labels don't say what they lead to ("Ver en la ludoteca": public or
admin? "Mover a otro lugar": where?). The subtitle "caja 35 de 47" breaks decision 8. Note: "Cancelar last with ‹" is
065 round 7's rule for every admin sheet, so the answer here changes that rule too.
Question 1 (how it closes) → developer asked to see variants 1 and 3. Sketch 069 *tools → Cierre de la hoja*:
- **1 · ✕ arriba** — a 44px ✕ at the right of the header, across from the cover; tap outside / drag / Esc still work.
  Sheet top at 562; 3 option rows.
- **3 · Cancelar aparte** — iOS action sheet: header + options in one floating rounded group (8px inset), a separate
  56px centred Cancelar (600) 8px below it. Sheet top at 505 (57px taller).
Both close correctly and neither overflows, in both themes. The Ubicar sheet uses the same variant.

29. **A sheet closes with ✕ in its header** (variant 1), across from the cover/title; tap outside, drag down and
    Esc still close it. **No Cancelar row.** Variant 3 is removed from the sketch. Developer: *"Be sure to persist
    this decision for all the bottom sheets"* → **app-wide for every admin bottom sheet**: option sheets,
    choose-a-destination sheets (Ubicar), form sheets (Renombrar: the commit row stays first) and in-sheet
    confirms (D-10, Quitar del staff). Replaces 065 round 7's "Cancelar last with ‹". Recorded as **D-19e** in
    `01.8.2-CONTEXT.md` and in `01.8.2-BENCHMARK.md` (A4 + Bottom sheet rows). Still open in this sheet: what the
    options say, the "caja N de M" subtitle (decision 8) and the spacing.

Question 2 (what the options say) → developer: yes, the options should say where they lead; show variants. Sketch 069
*tools → Opciones*, same three actions and icons, only the words change:
- **Hoy** — Ver en la ludoteca · Mover a otro lugar · Quitar del estante.
- **A · adónde lleva** — Ver la ficha pública · Mover a otro estante · Quitar del estante. One line, 48px rows, sheet top 562.
- **B · con explicación** — Ver ficha / *La página del juego en la web* · Mover / *Va al final del estante que elijas* ·
  Quitar del estante / *Queda sin lugar · podés deshacerlo*. Two-line rows at 48px were cramped → 64px (061's two-line
  height); sheet top 514 (48px taller).
- **C · palabras de todos los días** — Abrir en la web · Cambiar de estante · Sacar del estante. One line, sheet top 562.
Nothing wraps or overflows at 420px. "Mover" = to another estante, going to its right end (D-00c); moving within the same
estante is Ordenar, sketch 070.

30. **Option labels = B · con explicación**: a short verb + one grey line saying what happens — **Ver ficha** / *La
    página del juego en la web* · **Mover** / *Va al final del estante que elijas* · **Quitar del estante** / *Queda
    sin lugar · podés deshacerlo*. Two-line sheet rows are 64px. Developer, same answer: *"but still it looks like
    4 rows. Improve the hierarchy and make the header distinct."*

Question 3 (the header reads as a 4th row). Measured with B: header 58px vs 64px rows; same anatomy (44px thumb ·
16px title · 13px grey line vs 22px icon · 16px label · 13px grey line); title 16/600 vs label 16/400 is the only
difference; 0px between header and first row; header text at x72, row text at x54. Sketch 069 *tools → Cabecera*:
- **Hoy** — as measured. Sheet top 514.
- **H1 · Títulos + línea** — cover 56×60, title 18/600, subtitle 14px, 16px gap, a full-width divider and 8px air
  before the rows. Header 85px; sheet top 479 (35px taller).
- **H2 · Bloque** — same cover and type, the game inside a tonal 12px-radius block (`--color-surface`, the admin's
  soft-box surface) inset 12px; rows on the plain sheet below. Header 84px; sheet top 480.
Both themes checked; nothing overflows or scrolls.

31. **Sheet header = H1 · Títulos + línea**: cover 56×60, title 18/600, subtitle 14px, 16px gap, a full-width 1px
    divider and 8px air before the rows. All label and header variants removed from the sketch (only decisions
    29–31 remain). Developer: *"Be sure that is the common pattern for the rest of bottom sheet"* → **app-wide for
    every admin bottom sheet that has a header** (the Ubicar sheet in 069 already takes it; titles without a cover
    keep the same type, divider and spacing). Recorded with decision 29 as **D-19e** in `01.8.2-CONTEXT.md` and in
    `01.8.2-BENCHMARK.md`. Still open in this sheet: the "caja N de M" subtitle (decision 8).
    Found applying it: the Ubicar sheet (9 estantes) is taller than 85% and scrolled its header and ✕ away → the
    grabber + header are **pinned** while the rows scroll (measured: header stays at 140 after scrolling).

Question 4 (the header subtitle "Estante 7 · caja 35 de 47" breaks decision 8). Developer: *"What if says Estantes and
says games count to left and game count to right?"* Measured: the header text column is **206px at 360, 221px at 375,
266px at 420** (14px Inter). Wordings that wrap and were dropped: "34 juegos a la izquierda · 12 a la derecha" (269px)
and "34 a la izquierda · 12 a la derecha" (221px, which only fits at ≥375). Sketch 069 *tools → Subtítulo*:
- **Hoy** — Estante 7 · caja 35 de 47.
- **P1 · flechas, una línea** — "Estante 7 · ← 34 · 12 →" (153px). Header stays 93px at 375.
- **P2 · Izquierda / Derecha** — "Estante 7" / "Izquierda 34 · Derecha 12" (168px). Header 114px at 375.
- **P3 · flechas + juegos** — "Estante 7" / "← 34 juegos · 12 juegos →" (176px). Header 114px at 375.
All fit on one line each at 360/375/420. The counts are read aloud in full ("34 juegos a la izquierda…"). At 375 the
long title "Catan: El Auge de los incas" already wraps to two lines, which is why the header is taller there.

32. **The sheet names the estante only: "Estante 7".** No box number and no left/right counts (P1–P3 removed);
    decision 8 holds. Developer: *"Let's keep it simple. Just estante 7. But {name} needs a better representation,
    not subtitle since is additional information. Variants?"*

Question 5 (how the estante shows in the header, as extra information rather than a subtitle). Sketch 069
*tools → Estante*:
- **E1 · encima del título** — eyebrow: "Estante 7" 13/600 muted above the game name, 2px gap. Header 91px at 375.
- **E2 · ícono + nombre** — meta line under the title: 16px shelf icon + "Estante 7" 14px muted, 6px gap. Header 96px.
- **E3 · etiqueta** — a small tonal label under the title (4px radius, `--color-surface`, 13/600, shelf icon), 94px wide,
  8px gap; square-ish so it doesn't read as a pill or a button. Header 104px.
At 420 all three are 85px (the title fits on one line). Both themes, no errors. Seen on the way: the shelf icon at
14–16px still reads like a barcode (open item from before).
Developer: *"what if E2 top title? Be sure to use another icon that looks like a shelf"*.
- **New estante icon**, compared at 16/20/32px in both themes before building: (a) open sides + two boards + boxes
  standing on them, (b) a framed cabinet → read as a window, (c) one board with boxes → read as a sofa. **(a)** is the
  new `estante` icon for the sheet (E2/E3/E4); the hero and management rows still use the old drawing.
- **E4 · ícono + nombre arriba** — E2 moved above the title: 16px icon + "Estante 7" 13px muted, 4px to the title.
  Header 93px at 375 (E1 91, E2 96); 85px at 420 like the rest.

33. **E4 wins: the estante sits above the game name** as a 16px estante icon + "Estante 7" (13px, muted), 4px above
    the 18/600 title. The new estante icon is drawing (a). E1–E3 removed from the sketch.

### Review — hierarchy of every bottom sheet in 069 (developer: *"review the full hiearchy of all bottom-sheet"*)
Two sheets: the game's options and Ubicar. Measured at 375 (light), then fixed what earlier decisions already settle:
- **Shared and consistent:** grabber 36×4; ✕ 44px target, 22px muted glyph, right edge on the 16px content edge; header
  cover 56×60 at x16, text at x88; title 18/600 (the only 600 in each sheet); divider 1px, 8px to the first row; rows
  64px two-line, label 16/400, hint 13/400 muted, danger row red label + icon with a muted hint.
- **Fixed — two row anatomies:** Ubicar rows led with a 32px tinted shelf drawing (label at x64); options rows lead with
  a 22px line icon (label at x54). Ubicar rows now take the 22px estante icon, label at x54 (all rows measured 16/22/54).
- **Fixed — bottom inset:** the sheet's bottom padding had no `env(safe-area-inset-bottom)`; now 16px + the inset.
- **Open — two header anatomies:** options = [estante icon + name] above the game name; Ubicar = "Ubicar Tokaido Duo"
  (verb + name as the title) with the instruction "Va al final del estante que elijas." as a subtitle.
- **Noticed:** Mover's hint and Ubicar's subtitle are the same sentence (fine if Mover opens the same estante list, 070);
  the Ubicar list is 9×64px = 576px, so the sheet opens at y120 and scrolls.

Question 6 (the Ubicar header). Developer: *"show me variants first"*. Sketch 069 *tools → Ubicar* (open it from a Sin
lugar game → Ubicar):
- **Hoy** — "Ubicar Tokaido Duo" (18/600) + "Va al final del estante que elijas." as a 14px subtitle.
- **U1 · Sin lugar arriba** — the options sheet's shape: "● Sin lugar" (dot + text, decision 22; the 8px dot centred
  in the 16px icon slot so the text lines up with "🗄 Estante 7") above "Tokaido Duo"; the instruction becomes a quiet
  13px list label, "Elegí un estante · va al final".
- **U2 · Ubicar arriba** — estante icon + "Ubicar" above "Tokaido Duo"; list label "Va al final del estante que elijas".
- **U3 · la tarea como título** — "Tokaido Duo" (13px muted) above the title "Elegí un estante"; list label "Va al final
  del estante".
All: header 85px, sheet top 120 at 375; the list label adds 28px (header → first row 8 → 36). Both themes, no errors.

34. **Ubicar header = U3 · the task as the title**: game name (13px muted) above "Elegí un estante" (18/600), a quiet
    list label over the estantes. Hoy/U1/U2 removed from the sketch. Consequence for the sheet rule (D-19e): the small
    line above the title is **context** (where the game is, or which game), the title is **what this sheet is about**.
35. *(open — being clarified)* Developer, same message: *"For 'ubicar' a new game, I want to put at left by default (on
    case if empty) or between two games."* Reverses **D-00c** (a placed box goes to the far right end). The list label
    "Va al final del estante" and Mover's hint "Va al final del estante que elijas" both depend on it.
    Asked: (1) left end by default, optionally pick a gap / (2) always pick the spot, an empty estante skips it.
    Developer picked neither and added: *"But for the first time if the 'estante' is empty put on the left directly."*
    So far settled: **an empty estante → the game is placed directly as its first box** (no spot step). Still to
    confirm: on a non-empty estante, is the spot always chosen (a gap between two games), and do the two ends count?
    Developer: *"yes, ends included. show me variants"*. → **35 settled: choosing an estante in Ubicar — empty → the
    game goes in directly as its first box; with games → you choose the spot: before the first, between any two, or
    after the last.** Reverses D-00c (recorded in `01.8.2-CONTEXT.md`). Wording that followed: the Ubicar list label
    is now "Después elegís entre qué juegos va", an empty estante's row says "Vacío · va directo", Mover's hint is
    "Elegís el estante y el lugar". Snackbar after placing: "Va entre Ten y High Society" / "Va al principio de …" /
    "Va al final de …" / "Tokaido Duo es el primer juego de Estante 10", each with Deshacer.

Question 7 (how you choose the spot). Sketch 069 *tools → Lugar* (+ *Estante 10 vacío: Sí* adds an empty estante to try
the direct case). Real Estante 3 = 48 games → 49 spots. Measured at 375:
- **S1 · fila en la hoja** — the sheet stays open: "Tokaido Duo" / **Elegí el lugar**, a label row "Estante 3 · de
  izquierda a derecha" + "Cambiar estante" (A2), then a small rail of 64×68 covers with a dashed 24px "+" before, between
  and after them. Sheet top 506; **4 spots in view**, rail 4664px = 12.4 screens wide, opens at the left end.
- **S2 · fila en la página** — the sheet closes; the answer area turns into "Tokaido Duo" / **Elegí el lugar en
  Estante 3** + "Cancelar" (A2), and the page's own 96px rail gets the "+" spots. **3 spots in view**, 6200px = 16.5
  screens, opens at the left end; Últimas búsquedas stay below.
- **S3 · lista en la hoja** — the sheet stays open and lists the estante top to bottom: a 44px "⊕ Poner al principio"
  row, then each game (28px cover + name, muted, not tappable) with "⊕ Poner acá" between, and "Poner al final" last.
  Sheet top 120; **all spots are words**, 4249px tall = 6.2 sheet heights.
All: every spot is a real button named for screen readers ("Poner entre Ten y High Society", "Poner al principio de
Estante 3"); rail spots have a 48px-wide hit box running under the covers, which can't be tapped while choosing; no
errors. Choosing a spot places the game, closes the picker and shows it lifted in its new spot.

Developer: *"What if we reuse the mechanism defined for the 'estantes', with same search for estante and/or game so I can
place a game based on another?"* → two more variants in *tools → Lugar*. Both reuse decisions 1–2 and 6: one search that
finds **an estante or a game already on one** (estantes first, then games: starts-with, then contains; the game being
placed is excluded); picking a game opens **its estante with that game lifted** and a "+" on each side, so the box goes
"next to" a game staff can see; picking an estante opens it at the left end; an empty estante still takes the game
directly (decision 35). Without typing, the estantes are listed under "O elegí un estante".
- **R1 · buscar en la página** — Ubicar doesn't open a sheet: the page itself switches to placing. Above the search,
  "Tokaido Duo" / **¿Dónde va?** + Cancelar (A2); the field gets the placeholder "Buscá un estante o un juego" (the longer "…o un juego de al lado" was cut off at 375)
  and focus; Últimas búsquedas are hidden; suggestions drop down as usual (decision 12); the answer area shows the page's
  96px rail with the "+" spots, the reference game centred (0px off). Finishing or Cancelar restores the normal screen.
- **R2 · buscar en la hoja** — the Ubicar sheet: "Tokaido Duo" / **¿Dónde va?**, a search field in the sheet, results in
  place of the estante list, then the small 64px rail with "Cambiar" (A2) back to the search. Sheet top 450 with the
  rail; reference game 15px off centre.
Tested at 375, both variants: "high" → 1 result, High Society · Estante 3; picking it shows 4 spots in view (principio,
Ten|High Society, High Society|Lost Cities, Lost Cities|Survive the island); tapping High Society|Lost Cities → snackbar
"Va entre High Society y Lost Cities", game lifted on the page. "10" → Estante 10 (Vacío · va directo) + Stone Age 10
aniversario; picking Estante 10 → "Tokaido Duo es el primer juego de Estante 10". No errors. The regular search still
works (suggestion covers 40px). Not checked by eye in dark mode yet (scratchpad for screenshots went away mid-round).

36. **R1 wins, and placing starts the moment a game with no spot is found** (developer: *"R1. But the workflow should be
    trigger at the moment I tap the game without a place, shouldn't?"*). Picking a Sin lugar game — from the search or
    from Últimas búsquedas — goes straight to **"¿Dónde va?"** on the Estantes page: game name above, Cancelar (A2) on the
    right, the field focused with "Buscá un estante o un juego", Últimas búsquedas hidden, "O elegí un estante" listed
    below. The same search finds an estante or a game already on one (picking a game opens its estante with that game
    lifted and a "+" on each side); an empty estante takes the game directly (35). Placing clears the field, drops the
    keyboard and shows the game lifted in its spot, with a Deshacer snackbar. Cancelar returns to the plain screen.
    **Removed:** S1–S3 and R2; the "Sin lugar · Todavía no tiene lugar · Ubicar" answer; the Ubicar sheet (so
    **decision 34 no longer has a screen**; its rule stays for any sheet: small line = context, title = what the sheet
    is about). After **Quitar del estante** the screen goes back to idle (the game shows as Sin lugar in Últimas
    búsquedas; Deshacer puts it back and shows it). Tested at 375 in dark: search "Tokaid" → Tokaido Duo · Sin lugar →
    placing; Cancelar; recent row → placing; "high" + Enter → Estante 3 with High Society lifted; + after it → "Va entre
    High Society y Lost Cities"; Quitar → idle, Deshacer → back; "10" → Estante 10 (Vacío) → "Los odiosos 7 es el primer
    juego de Estante 10". No errors. Found and fixed on the way: a stray brace from the cleanup broke the page; recents
    did not refresh after Cancelar; the field kept focus after placing into an empty estante.
    Open: whether Mover (sketch 070) reuses this same "¿Dónde va?" flow — its hint already says "Elegís el estante y el lugar".

Question 8. Developer: *"Since that is an 'ubicar' action, shouldn't be inside a bottom sheet?"* Answer given: yes as a
modal task, but not a content-height sheet (R2 lost on room: sheet top 450, 64px covers); proposed a **full-height
sheet** (iOS large detent / M3 full-screen for tasks with typing + many choices). Developer: *"yes, build it as a
variant"*. Sketch 069 *tools → ¿Dónde va? en*:
- **R1 · la página** — decision 36 as built.
- **F · hoja completa** — the same flow in a sheet from y24 to the bottom (24px of page shows above): D-19e header
  (cover · "Tokaido Duo" · **¿Dónde va?** · ✕), then a pinned search field (141–189), then the body — "O elegí un
  estante" rows, results while typing, or the estante's 96px rail with the "+" spots (same component as the page).
  ✕, tap outside or Esc = cancel (back to the plain screen, the game stays Sin lugar in Últimas búsquedas). Placing
  closes the sheet and the page shows the game lifted + the Deshacer snackbar.
Measured at 375 (device 800 tall): with the keyboard (292) the sheet sits above it at 24–508, leaving **311px** for
results under the field (the page search has 272); keyboard down, the rail box is 223–384 with **4 spots in view** and
the reference game centred (0px), like R1. Tested both themes: search "Tokaido D" → sheet opens with the field focused;
"high" + Enter → Estante 3 with High Society lifted; + after it → "Va entre High Society y Lost Cities"; ✕ → cancel;
Estante 10 (empty) → placed directly; switching back to R1 still works. No errors. Fixed on the way: the field kept
focus after the sheet closed. Measuring note: headless Chrome fires no focus events unless
`Emulation.setFocusEmulationEnabled` is on — without it the keyboard simulation silently never appeared.

Developer: *"f looks better. When I look for a game and I selected it, the search on this case should keep what is the
selected 'estante'. Also the 'success' message should say 'juego ubicado' and make a little animation of the
'highlighted' game."*
37. **"¿Dónde va?" is a full-height sheet (F).** R1 (placing on the page) removed from the sketch. Decision 36's trigger
    stands: the sheet opens the moment a game with no spot is picked. Mover (070) can open the same sheet.
38. **The sheet's search field keeps the chosen estante.** Picking a result — an estante, or a game on one — puts the
    estante's name in the field ("Estante 3"), with ✕ to clear (decision 16), and the estante's rail below with the
    game lifted when one was picked. The "Estante 3" heading above the rail is gone (the field says it). Focusing the
    field selects its text, so typing replaces it and shows results again; clearing it shows "O elegí un estante".
39. **After placing: snackbar "Juego ubicado"** (with Deshacer; the same for an empty estante), **and the placed cover
    drops into its spot**: from 56px above at 92% size, a small overshoot, settling lifted at −12px in 620ms; its
    caption fades in; no animation under reduced-motion.
Tested at 375: "high" + Enter → field "Estante 3", rail with High Society lifted and centred (0px); refocus selects
0–9; typing "est" → results; ✕ → empty field + estante list; Estante 5 → field "Estante 5", rail at the left end; a +
→ sheet closes, "Juego ubicado", `.landed` running `land` then removed; empty Estante 10 → "Juego ubicado" + landing.
No errors. Frames checked at 150 / 400 / 900ms.

Developer: *"Then for mover, this should be like a transactional action where I need to open a new 'ubicar' and once I
selected the new place, the 'remove' is success (so that means) that the mover is a 'remove' from a place and 'add' it to
another. For delete, I want a dialog for confirmation."*
40. **Mover = one transaction.** Mover in the game's options sheet closes that sheet and opens the same full-height
    "¿Dónde va?" sheet (37–38). The game **stays in its spot until the new spot is chosen**; choosing it removes the game
    from the old spot and adds it to the new one in one step. ✕ / tap outside / Esc = nothing changes. While moving, the
    estante is drawn **without the moving game** (its rail and spots are the positions it will have), so moving within
    the same estante works too. Snackbar **"Juego movido"** with Deshacer (back to the exact old spot) + the landing
    animation (39).
41. **Quitar del estante asks first, in a centred dialog** (M3 basic dialog, 312px, 16px radius): title "¿Quitar
    {juego} del estante?", text "Queda sin lugar hasta que lo vuelvas a ubicar.", two text actions right-aligned —
    **Cancelar** (focused, the safe default) and **Quitar** (Peligro red). Scrim tap or Esc = Cancelar. Confirmed →
    snackbar "Juego quitado del estante" with Deshacer. The option's hint is now "Queda sin lugar · te pedimos confirmar".
    **Conflicts with** D-19e ("in-sheet confirms") and 064's "Peligro … always confirms in a sheet" — scope asked.
Tested at 375: Mover → search "high" → Enter → game still Estante 7 #35 → ✕ → unchanged; Mover → Estante 7 → the rail
has no Catan, 47 spots → first spot → Estante 7 #1, total 428 unchanged, "Juego movido" → Deshacer → #35; Mover next to
High Society → Estante 3 #3 of 49. Quitar → dialog (focus on Cancelar) → Esc → unchanged; Quitar → Quitar → none, total
427, "Juego quitado del estante". Dialog checked in dark. No errors.

Developer: *"every destructive action uses the dialog. and for mover, I typed catan, I selected catan, the search value
is correct, but the 'estante' should show the game selected position since I typed and selected that. Does it make sense?"*
42. **Every destructive action in the admin confirms in the dialog of decision 41** — never in a sheet. Recorded as
    **D-19f** in `01.8.2-CONTEXT.md` (D-19e no longer lists in-sheet confirms; D-10 now says dialog) and as a
    "Confirmation (destructive)" row in `01.8.2-BENCHMARK.md`; replaces 064's "Peligro always confirms in a sheet".
- **Bug fixed (Mover):** yes, it should — and it did for Ubicar. While moving, the page behind the sheet still shows
  the game's estante rail with `id="rail"`, and the sheet's rail had the same id, so centring scrolled the page's rail
  and the sheet's stayed at the left end. The sheet's rail is now `#prail`. Re-tested at 375: moving Catan: El Auge de
  los incas, "catan" → Catan viajeros de las estrellas → field "Estante 7", that game lifted and centred (0px); moving
  Wingspan, "high" → High Society centred (0px); moving Lapsus, "catan" → Catan: El Auge de los incas centred (0px).
  One #rail and one #prail in the DOM. No errors.

## Management page (started 2026-09-17)
Reached from the gear (decision 26). D-08's list inventory (progress, search, rows, Sin ubicar, Nuevo estante, Ordenar)
predates the restart; search already lives on the Estantes page (18). Question 1: what else belongs on the list.
Developer picked Sin ubicar and Nuevo estante, and added: *"For new, I like the same pattern that 'Estantes' has: an icon
at right of 'title'. The options should be edit and remove (both on bottom sheet, don't?). Not view since I view on real
world. BTW: not right chevron since not details for games."*

43. **The list page = estante rows + a Sin ubicar row.** No progress line and no Ordenar estantes (not picked).
44. **Nuevo estante = an icon button at the right of the "Administrar estantes" title**, the same pattern as the gear
    on Estantes (26); no text.
45. **An estante has no page of its own.** Staff see the boxes on the real shelf, and finding, placing, moving and
    removing a game already happen on the Estantes page (1–42). So the estante rows have **no chevron** (25).
    **Revises D-08** ("one page per estante", `/admin/estantes/:id`, Agregar juegos mode, per-estante Ordenar) —
    to record in `01.8.2-CONTEXT.md` once the management page is settled.
46. **Tapping an estante row opens its options sheet** (D-19e header) with two options: **Editar** and **Eliminar**.
    Eliminar confirms in the dialog (D-19f; D-10's text "Sus N copias vuelven a Sin ubicar").
    **Editar changes the name**: an estante has only `name` and `position` (`lib/pukllay_club/catalog/shelf.ex`), and
    ordering was not picked (43).

Question 2 (what the Sin ubicar row does, now that there is no estante page). Developer: *"It's like #1 [a list page].
Go back and show the 'ubicar' search page but instead of 'últimas búsquedas' shows all the games sin ubicar."*
47. **Tapping Sin ubicar goes back to the Estantes page with the Sin ubicar games in place of Últimas búsquedas.**
    Same rows as recents (21: cover, name, "● Sin lugar"); tapping one opens the full-height "¿Dónde va?" sheet (36–38)
    as usual. The Sin ubicar row navigates, so it **keeps its chevron** (25), unlike the estante rows.
    Measured against decision 28's numbers: the idle centred layout (C) has a 393px area; hero 40 + 16 + question 24 +
    24 + field 48 + 40 + label 20 = 212px, so it holds **3 compact rows (356px)**. The sketch has 6 Sin ubicar games;
    after the D-05 migration all 434 are Sin ubicar (20,832px of rows). This list cannot sit in the centred layout.

Question 3 (how the Sin ubicar list looks and how you leave it). Developer: *"Build both as variants"*. Sketch 069: the
management page is now real (decisions 43–46: back "‹ Estantes", title + "+" icon, 9 estante rows with the new `estante`
icon in the 40px tile and no chevron, then a divider and the Sin ubicar row with a chevron; tapping an estante opens its
sheet, D-19e header = estante tile · "48 juegos" above "Estante 3" · ✕, rows **Editar** / *Cambiar el nombre* and
**Eliminar** / *Quedan sin lugar · te pedimos confirmar* — the first hint "48 juegos quedan sin lugar · te pedimos
confirmar" wrapped to 2 lines at 375 (305px), and the header already names the count; Eliminar → dialog "¿Eliminar
Estante 3?" / "Sus 48 juegos quedan sin lugar hasta que los vuelvas a ubicar." / Cancelar (focused) · Eliminar →
snackbar "Estante eliminado" + Deshacer). Editar and Nuevo estante are stubs. *Tools → Sin ubicar* (V1/V2) and *Juegos sin
lugar* (6 / 434, the post-migration case):
- **V1 · Etiqueta + ✕** — the Estantes page raised (title + gear, field 121–169), then "Sin ubicar · 6" as the quiet label
  with a 44px ✕ at the right (193–237), the rows below. ✕ → Últimas búsquedas, idle centred layout again. Placing the last
  one also goes back.
- **V2 · Título propio** — "‹ Administrar" (69–113) + title "Sin ubicar" instead of Estantes + gear; field 165–213 (44px
  lower than V1); a quiet "6 juegos" label (237–265). Back → Administrar estantes. At 0: "Todos los juegos tienen lugar."
Both at 375×800, light and dark: picking a row opens "¿Dónde va?"; Esc → the list is unchanged; placing into Estante 5 →
"Juego ubicado", the rail with the game lifted above the list, which now counts 5. 434: 434 rows, page 21,444px tall.
Delete Estante 2 → Sin ubicar 54, Deshacer → 5. No overflow, no errors.
Found while measuring: **(a)** on the management page the Sin ubicar row sits at 722–782, **under the tab bar (733)**, so
at 375×800 it is off screen until you scroll (the page is 808px in a 747px scroller); **(b)** with 434 games the search
scrolls away with the list (field at −2879 after scrolling 3000px), so picking a game far down means scrolling back up to
search.

Developer: *"V2. But the 'juegos sin acomodar' shouldn't be inside estantes [management]. Should be at the 'estantes'
initial page (where the search lives). Also there could be a kind of 'how many games aren't on the estantes' (were picked
up and need to be restored)."*
48. **V2 wins: the Sin ubicar list is its own view of the Estantes page**: back link + title "Sin ubicar" in place of
    Estantes + gear, the search below, "N juegos" as a quiet label, then the rows; empty → "Todos los juegos tienen
    lugar." V1 removed from the sketch.
49. **The way into Sin ubicar is on the Estantes page itself, not in Administrar estantes.** The management list is
    estante rows only (43 revised), which also fixes finding (a). V2's back link reads "‹ Estantes".
50. **The Estantes page also counts the games that are off their estante** (picked up, waiting to go back). This is
    decision 20's "missing games — what must be returned": it needs Phase 4 checkout state, so it **takes the same place
    as the Sin ubicar entry when Phase 4 lands**. The entry is designed now with room for that second line.
    Wording to settle: the developer says "sin acomodar"; the sketch says "Sin ubicar" / "Sin lugar".
    Measured, idle layout at 375 wide: the centred group (hero → Últimas búsquedas) is 391px; the free space around it
    is **84px at 667 tall**, 157 at 740 and 217 at 800. A 48px entry + a 24px gap (72px) fits even at 667 (12px left);
    two lines (Phase 4) do not fit at 667 without taking a row from Últimas búsquedas.

Question 4 (where the entry goes). Developer: *"Build variants, but I think below the search, with 3 list options (it shows
only one): 'últimas búsquedas', 'juegos afuera', 'juegos sin ubicar'."*
51. **Below the search, one list at a time, chosen from three: Últimas búsquedas · Juegos afuera · Juegos sin ubicar.**
    It replaces the "Últimas búsquedas" label. Juegos afuera is Phase 4 data; the sketch fakes 3 games to preview it.
    How V2 (48) fits in (my reading, to confirm by eye): the idle page shows **up to 3 rows** of the chosen list, and a
    longer list ends in "Ver los N ›", which opens the V2 view ("‹ Estantes" + title). Tapping a game behaves as before:
    shelved/afuera → its spot, lifted (so an afuera game shows where it goes back); sin ubicar → "¿Dónde va?".
    Measured label widths (Inter 600): at 13px, full labels are 120 + 90 + 111 = 321px, plus 24px padding each = 393px,
    wider than the 343px row at 375 (328 at 360) → a switch with all three side by side needs **short labels**
    ("Últimas" 47 · "Afuera · 3" 62 · "Sin ubicar · 434" 99 = 208 + 72 = 280px).

Sketch 069 *tools → Lista* (V1 and the management Sin ubicar row removed; V2 is the "Ver los N" view, back "‹ Estantes",
title "Juegos afuera" / "Juegos sin ubicar"; *tools → Afuera (Fase 4)* 3 / 0 fakes the checkout data):
- **L1 · Segmentos** — a 44px 3-segment control, "Últimas · Afuera 3 · Sin ubicar 6" (count in 400 weight), selected
  segment tinted like the tab bar's active tab.
- **L2 · Pestañas** — text tabs with a 2px underline, left-aligned, 20px apart (47 / 55 / 75px wide).
- **L3 · Menú** — the label names the list in full ("Juegos sin ubicar · 6 ▾") and opens a 260px menu with the three lists,
  counts at the right and a ✓ on the current one. Counts for the lists not shown are hidden until opened.
Rows: Últimas as before; Afuera "● Afuera · va en Estante 3" (a blue dot, decision 22); Sin ubicar "● Sin lugar". Up to 3
rows; Afuera/Sin ubicar with more than 3 end in "Ver los N ›" (A2, on the content edge); Últimas stays capped at 3 with
no link (24). Empty: "Todos los juegos están en su estante." / "Todos los juegos tienen lugar."
Measured idle (field → end of list), all fit with no scroll at 375×667 and 375×800; at **360×640 L1 and L2 with "Ver los
N" overflow by 3–7px** (the page scrolls a little), L3 fits (its label is 44px like the others, but it has no border
row). Flows: Afuera → Océanos de papel → Estante 3 rail with it lifted; Sin ubicar → Ver los 6 → the V2 view → a game →
"¿Dónde va?" → Esc → back returns with Sin ubicar still chosen; 434 mode → "Sin ubicar 434"; Afuera 0 → empty line.
Management list = 9 estante rows only. Light + dark, no errors.

Developer: *"What is more mobile?"* → answered L1: the segmented control is the native in-place view switch on iOS
(HIG segmented control, 2–5 segments) and Android (M3 segmented buttons); M3 tabs belong at the top of a page and would
be a second tab bar over the bottom one; L3 hides the counts, which are the point. Developer: *"What I don't like about
segmentos is that looks too heavy. Improve its balance and hierarchy to a great rhythm on the full page."*
52. *(proposed, awaiting the developer's look)* **Segmentos, lighter.** Measured before: the control had the **search
    field's height (44), full width and the same 1px stroke colour**, plus 2 dividers and an accent-tinted selection, so
    it read as a second field of the same rank right under the search. Now (*tools → Lista → Segmentos · ligero*): a
    **36px tonal track** (`--color-surface`, radius 10, 3px inset, no stroke, no dividers); the selected segment is a
    **raised neutral chip** (page background + a 1–2px shadow in light, `--color-surface-2` in dark), 13/600
    `--color-text`; the others 13/400 muted; counts 400 muted. The 44px hit area is kept (verified 6px above and below
    the track still hit the segment). Page rhythm on the 8px scale, grouped: icon→question 16 · question→field 24 ·
    **field→switch 32** (was 40 to a 44px box) · switch→rows 8 · rows → "Ver los N" 0.
    Contrast: unselected 5.33 light / 6.2 dark, selected 17.2 / 10.5; track vs page 1.16 / 1.11 (a tone, not an edge).
    Fits without scrolling at 360×640 (the old one overflowed 3–7px), 375×667 and 375×800. No errors.
    "Segmentos · antes" stays in the tools for comparison; L2 and L3 are still there until this is confirmed.
    Developer: *"Ligero is better but still having it with shadow makes it more relevant."* → the shadow goes. Two ways
    without it, same size, spacing and type (*tools → Lista*):
    - **A · carril, sin sombra** — the tonal track stays; the selected segment is a flat page-colour chip. Chip vs track
      1.16 light / 1.11 dark, so the selection is carried mostly by weight + colour (17.2 vs 5.3).
    - **B · sin carril** — no track; only the selected segment is tinted (`--color-surface`), the others are plain text.
      One tinted shape instead of two (lightest); unselected 6.2 light / 6.9 dark, selected 14.8 / 12.3.
    Both: 44px hit area verified, fit at 360×640 / 375×667 / 375×800, light + dark, no errors.
    Developer: *"That doesn't look good. Alternatives for mobile based on industry standard?"* → four offered: filter chips
    (M3; Maps, Play, Gmail), smart-list rows (iOS Mail/Reminders), count tiles (Reminders grid), full-width tabs (M3
    primary tabs). Developer: *"1 and 4"*.
53. **The segmented control is dropped** (52 and its A/B, L2, L3 removed from the sketch). Two standard switches are built,
    same place and rhythm (field → switch 32, switch → rows 8), *tools → Lista*:
    - **1 · Chips** (M3 filter chips) — 32px chips, 8px radius, 8px apart, starting on the content edge; unselected = 1px
      `--color-border` outline, 14/400 + muted count; selected = tonal `--color-accent-bg` fill, no outline, a leading
      ✓, 14/600 accent text. Each button is the 44px target with the 32px chip inside (a `::before` extension was clipped
      by the sideways-scrolling row: measured, it missed 5px below). The row scrolls sideways if it ever overflows (M3);
      at 360 wide with "Sin ubicar 434" it still fits (right edge 339 of 344).
    - **4 · Pestañas a lo ancho** (M3 primary tabs) — full-bleed, 3 equal 48px columns (125px at 375, 120 at 360), 14px
      labels, selected 600 accent with a 3px indicator as wide as its label (rounded top), others 400 muted, 1px divider
      across the page. No separators between tabs (not part of M3). At 360 with "Sin ubicar 434" the label fits its
      120px column without clipping but sits ~10px from the screen edge.
    Contrast: chips unselected 17.2 light / 13.6 dark, selected 14.2 / 6.5; tabs unselected 6.2 / 6.9, selected 14.2 /
    11.7. Both fit without scrolling at 360×640 and 375×667 idle, work raised under an estante rail, light + dark, no
    errors.

Developer: *"Is a better pattern to have the list (últimas by default, not as chip) and make afuera and sin ubicar filters of
that list?"* → answered: yes as a pattern (default list + optional single-select chips: Gmail search, Photos, Maps), but
they **swap** the list rather than filter it — Afuera/Sin ubicar are catalog sets, not subsets of the search history
(filtering history by "Sin ubicar" would show 1 game, not 6 or 434). Developer: *"yes, build it. And for the list is ok
to remove the big icon below the title to gain space. But always the search is the most important component of the page
after the title, isn't?"* → yes: the page's job is "I'm holding a box"; everything below the field is secondary.
54. **The search is the most important component after the title**: nothing below it may look heavier than the field
    (48px, 1px stroke), and switching what's below must never move it. **The big 64px icon above the question is
    removed**; the question stays ("¿Qué juego tenés en la mano?", 24px above the field). Decision 28's icon→question 16
    no longer applies.
55. *(built, awaiting choice)* **Últimas + filtros** (*tools → Lista*, now the default; Chips and Pestañas still there):
    below the search (32px) two filter chips **Afuera 3 · Sin ubicar 6** (same chip as option 1, `aria-pressed`; ✓ +
    tonal fill when on; tap again → off); below them (10px) the quiet label of the list showing — **Últimas búsquedas**
    by default, "Juegos afuera" / "Juegos sin ubicar" when a chip is on; then up to 3 rows and "Ver los N ›".
    Measured at 375×667: title 69–113, question 164–186, field 210–258, chips 296–328, label 338–366, rows to 511; fits at
    360×640, 375×667, 740, 800 with 3 rows (the 28px label that seemed to need a row less fits, because the icon is gone).
    **Found and fixed:** tapping a chip re-centred the page and the search jumped 17px ("Ver los N" adds 44px). The list
    body now keeps one height (3 rows + that line, 191px), so the field stays put across Últimas / Afuera / Sin ubicar /
    an empty list — verified to the pixel at 360×640, 375×667, 375×800. Light + dark, raised under a rail, no errors.

Developer: *"Últimas + filtros is better, but the balance looks weird. Why the chip is bigger than the rows? Can the text
below be more relevant? Is it recognizable that I need to tap the chip again to 'remove' that filter? Is it recognizable
that I can activate only one chip?"*
56. **Últimas + filtros wins** (55). Chips (option 1) and Pestañas (option 4) removed from the sketch.
57. *(built, awaiting look)* **Balance + affordances.** Measured before at 375×667: chip 85×32 outlined, **14px text = the
    row names (14)**, the only outlined shape under the field; the list label **13/400 muted = the faintest text** there;
    rows 48px with 32px covers, subs 12px. So the control outranked the list it controls. Now (*tools → Lista → Filtros ·
    ajustado*; "antes" kept to compare):
    - **Chips 28px, 13px text** (below row names), 10px side padding; still a 44px target (verified 7px above/below).
    - **The list's name is a heading: 15/600 in text colour** ("Últimas búsquedas" / "Juegos afuera" / "Juegos sin
      ubicar"). Ranks: title 22/600 › question 17/600 › field 16 in a 48px box › heading 15/600 › row names 14 › chips 13
      › subs 12.
    - **The active chip ends in ✕** instead of starting with ✓ — the Gmail / Maps / Airbnb "applied filter" form, which
      says "tap to remove". Screen readers: "Sin ubicar 6, activo. Tocá para quitar el filtro".
    - Rhythm: field → chip 32 · chip → heading 16 · heading → rows 4. The field stays at the same y across all lists
      (184 / 195 / 248 at 360×640 / 375×667 / 375×800); no scroll; 360 wide with "Sin ubicar 434" fits (229 of 344).
    - Contrast: chips 17.2 light / 13.6 dark, active 11.3 / 6.5.
    **Only one active:** not shown upfront, and on purpose not signalled: a wrong guess costs nothing — tapping the other
    chip switches at once, the first one loses its ✕ and fill, and the heading changes, so it is learnt on the first tap.
    Radio-style controls that announce exclusivity are the segmented control/tabs already rejected (52–53).
    Found on the way: tapping the active chip did not turn it off in the new version (the toggle checked the old
    variant's name); fixed and re-verified — tapping again returns to Últimas búsquedas.

Developer: *"Doesn't feel correct. Let's explore other options. Since the main focus is to search and 'acomodar', is the
list part of the 'main' page a good idea? Where can I put it?"* → 57 not accepted. Question 5 reopens *where* the three
lists live (decisions 20, 47–51, 55 all assumed "under the search"). Answer given: the three lists are two different
kinds of thing — **Últimas búsquedas is a search aid** (industry standard: shown when the field is focused, before typing —
iOS, Google, Spotify, Amazon), while **Afuera / Sin ubicar are work queues** (a checklist after a club night; 434 to place
after the migration) that deserve a page, with only a count on the main page.
Offered: focus + header badge / focus + summary line / below the fold. Developer: *"Build variants"* (the first two).

58. *(built, awaiting choice)* **The Estantes page is the title, the question and the search — nothing else idle.** The
    switch, chips and list heading (55–57) are removed from the page. In both variants:
    - **Últimas búsquedas live in the search dropdown**: focusing the empty field opens it with a quiet "Últimas
      búsquedas" label and 3 rows (cover · name · estante or ● Sin lugar); typing replaces them with suggestions; clearing
      brings them back; tapping one behaves as before (field clears, rail shows). Replaces 20–21's "below the search".
    - **Afuera + Sin ubicar live on a "Pendientes" page** ("‹ Estantes"): a section per queue — heading "Afuera 3" /
      "Sin ubicar 6" (15/600 + count), one hint line ("Volvieron de una mesa: tocá uno para ver dónde va." / "Todavía no
      tienen lugar: tocá uno para ubicarlo."), all rows. Afuera row → Estantes with the game lifted in its spot; Sin
      ubicar row → "¿Dónde va?" over Pendientes (✕ stays there); placing → Estantes, landing + "Juego ubicado".
      Replaces 47–48's V2 view.
    Variants (*tools → Pendientes*):
    - **P1 · Foco + insignia** — a 44px inbox icon with a count badge (18px, primary fill, "9", "99+" over 99) left of the
      gear in the header (inbox 283–327, gear 327–371 at 375). Idle: question 265–287, field 311–359 at 375×667.
    - **P2 · Foco + línea** — no header icon; 24px under the idle search one quiet centred line "● 3 afuera · ● 6 sin
      ubicar ›" (14px muted words, 600 counts, 44px tall, 231px wide) → Pendientes; hidden once the page is raised.
      Field 278–326 at 375×667.
    Measured: both fit with no scroll at 360×640, 375×667, 375×800; light + dark; no errors. Focus at 375×667 with the
    simulated 292px keyboard: field 121–169, dropdown 173–383, keyboard from 375 → **the 3rd recent row is 8px under the
    keyboard** (the sketch's keyboard is sized for a 740–800 phone; a real ~260px SE keyboard leaves 234px ≥ the 210 needed).
59. **P1 wins: Pendientes = a header inbox icon with a count badge.** P2 removed from the sketch. Developer: *"That must be a
    default admin approach to be implemented somewhere when we need something similar."* → recorded app-wide as **D-19g**
    in `01.8.2-CONTEXT.md` and a "Pending work (queues)" row in `01.8.2-BENCHMARK.md`.

Question 6. Developer: *"The search needs better polish: I input and select a name, the estante is shown, but I don't have
a way to go back to the initial state."* Today, once a game is picked the page is raised (field at the top, empty per
decision 11, magnifier icon; rail below) and nothing returns to idle — only picking another game replaces the answer.
Measured for keeping the name in the field: text room is 279px at 375 / 264 at 360 (16px); **17 of 434 names (19 at 360)
don't fit** (longest 523px, "El Señor de los Anillos: Viajes por la Tierra Media - Vientos de Guerra"), so a kept name
would be cut with an ellipsis for those.
Offered: name stays + ✕ / ‹ in the field / ✕ on the answer. Developer: *"Build variants"*. Sketch 069 *tools → Volver*:
- **B1 · Nombre + ✕** — the found game's name stays in the field with ✕ (the "¿Dónde va?" field's behaviour, 38; Google
  Maps). ✕ → idle. Tapping the field selects the name (0–6 for "Lapsus"), so typing replaces it and suggestions return;
  tapping another cover puts that game's name in the field; placing from Pendientes shows the placed name; Quitar → idle,
  field empty. Long names end in "…" (checked with "El Señor de los Anillos: Viajes por la Tierra Media - Vientos de
  Guerra"). Reverses decision 11.
- **B2 · Flecha en el campo** — the field stays empty (11 holds); while an answer shows, a 44px ‹ appears inside it at
  the left (18–62) and the placeholder shifts right; ‹ → idle.
- **B3 · ✕ en la respuesta** — the field stays empty; a 44px ✕ at the right of the "Estante 1" heading (327–371); → idle.
  The ✕ overlaps the heading's air so the rail keeps its place (fixed a 2px shift found measuring).
All: field 121–169, rail 215–376 at 375×667 in every variant; back → idle (field 311–359, no answer); light + dark; no
errors.

Developer: *"B1. Remove the others. Then review the full hierarchy on the page when the estante is displayed (looks too close
to the top). Also, the estante name isn't meaningful, and wondering if always. Additionally, I'd like to trigger creating a
new game from there (if I type something that isn't found, show the action on the result to say 'create game')."*
60. **B1 wins: the field keeps the found game's name, with ✕ back to idle.** **Reverses decision 11** (clear the moment a
    game is found). Tapping the field selects the name so typing the next box replaces it; tapping another cover puts its
    name in the field; long names end in "…". B2/B3 removed.
61. **Raised-page rhythm** (review). Measured before at 375×667: title row → field **8**, field → "Estante 1" 20, heading →
    lifted cover **8** (others 20), all content in the top 376px (224px empty above the tab bar; 357 at 800). Now: title row
    → field **16**, field → answer **32** (a new group), heading → lifted cover **16** (others 28): field 129–177, heading
    209–231, rail 235–404. Content stays top-aligned (search results convention; the empty space below is the rail's room
    to grow, not a centring problem). Knock-on: the suggestions dropdown ran 5px under the simulated keyboard → max-height
    272 → **264** (ends at 445, keyboard at 448).
62. **A search with no match offers "Crear «texto»"** in the dropdown, under "Ningún juego se llama así.": a 56px row, 40px
    tonal tile with +, accent 600 label, "Agregarlo al catálogo" sub. Stub for now (snackbar); where it leads (the Juegos
    editor? then "¿Dónde va?") is open.
Question 7 ("the estante name isn't meaningful, and wondering if always"). Asked which meaning (heading looks wrong / say it
as the answer / numbers say nothing / not needed). Developer: *"Need better balance."* → it's the label's weight, not its
words. Measured: "Estante 3" 17/600 full text colour, between the page title (22/600) and the 48px field — a third
heading-weight line, reading as a section title. Sketch 069 *tools → Estante* (same page rhythm, High Society at 375×667):
- **Hoy** — 17/600 text colour, 209–231; lifted cover 16 below.
- **E1 · Contexto** — 18px estante icon + "Estante 3" 14/600 muted (the sheet's E4, decision 33), 209–227; contrast 6.2
  light / 6.9 dark.
- **E2 · Título + cantidad** — "Estante 3" 15/600 + "48 juegos" 14/400 muted, 209–229.
- **E3 · En el estante** — no label above: the rail sits 32px under the field (lifted cover at 213) and the label goes
  under the covers on a 3px shelf-board line, like a shelf tag: icon + "Estante 3 · 48 juegos" 13/600 muted, 370–403.
All: light + dark, no errors; field stays 129–177.
63. **E1 wins: the estante above the rail is context** — 18px estante icon + "Estante 3", 14/600 muted, 16px above the
    lifted cover (209–227, cover at 243 at 375×667; contrast 6.2 light / 6.9 dark). Same treatment as the game sheet's
    header (33), so the estante reads the same everywhere. Hoy, E2, E3 removed from the sketch.
Still open: where "Crear «texto»" (62) leads; the Catan-family suggestion ranking; `shelfDrawing` is now unused on the
Estantes page (the idle hero lost its icon, 54) — only its definition remains.

## Round 5 — the prompt copy and adding a game from the rail
Developer: *"The copy '¿Qué juego tenés en la mano?' isn't correct since I can look for another game (Catan) to put a new
game at its left or right. Be sure that the carousel after a search shows the option to add a game."*
64. **The found game's rail offers "+" on each side of the selected cover** (the "¿Dónde va?" spot, decision 35, on the
    page rail): 24px dashed "+", centred on the covers (293–317 vs covers 255–355 at 375×667), 12px from each cover, a 44px
    hit box that reaches the covers' edges without covering them (measured: the lifted cover's last pixel still opens its
    sheet). The "+" follow the selection (tapping another cover moves them, 10). Screen readers: "Poner un juego entre Ten
    y High Society" / "…al principio de…" / "…al final de…".
    Tapping "+" opens the full-height sheet **"¿Qué juego va acá?"** — the reverse of "¿Dónde va?": header context
    "Estante 3 · entre High Society y Lost Cities" (wraps to 2 lines with long names), title "¿Qué juego va acá?", ✕; a
    focused field "Buscá el juego que va acá"; empty → **Sin ubicar · N** rows (the likely ones); typing → every game
    (a shelved one is **moved** here, one transaction like 40); no match → "Crear «texto»" (62). Picking places it: sheet
    closes, the field shows its name (60), it lands lifted (39), snackbar "Juego ubicado" / "Juego movido" + Deshacer.
    Picking the game that is already in that spot → "Ya está en ese lugar", nothing changes.
    Tested at 375×667: High Society → "+" right → Tokaido Duo → Ten, High Society, Tokaido Duo, Lost Cities; "+" left of
    Tokaido Duo → High Society → "Ya está en ese lugar"; "+" right → Catan: El Auge de los incas (Estante 7) → "Juego
    movido", placed after Tokaido Duo; Deshacer → back in Estante 7; "zorblax" → Crear row; Esc closes. No errors.
Question 8 (the prompt). Measured at 17/600 (room 343px): "¿Qué juego tenés en la mano?" 246, "¿Qué juego buscás?" 166,
"¿Qué juego estás buscando?" 237, "Encontrá un juego en los estantes" 277, "¿Dónde está o dónde va un juego?" 282.
The placeholder "Buscá un juego para ubicarlo" (221 of 279) has the same problem.
65. **Prompt "¿Qué juego buscás?", placeholder and label "Buscá un juego"** — neutral across putting back, picking up
    and finding a neighbour to place another game next to. **Replaces decisions 15 and 27's copy.** Applied: question
    265–287, field 311–359 at 375×667 (unchanged positions); no errors.

Developer: *"Crear should open the new game editor, then ¿Dónde va?"*
66. **Crear «texto» opens the new-game editor with the name filled in; saving continues to placing.**
    - From the **search** (no spot yet): "Crear juego" → back on Estantes with **"¿Dónde va?"** open (36–38); placing →
      field shows the name (60), lifted, "Juego ubicado".
    - From a **rail "+"** ("¿Qué juego va acá?", 64): the spot is already chosen, so saving **places it there directly** —
      no second "¿Dónde va?". The editor says where it will go ("Después va en Estante 5, entre Zorblax Quest y Kingdomino
      Age of Giants (Expansión).") vs "Después elegís dónde va." from the search. Confirmed by the developer ("Place it
      there" over "still ask ¿Dónde va?").
    - "‹ Estantes" in the editor = cancel, nothing is created. Closing the "+" sheet forgets its spot, so a later Crear
      from the search asks "¿Dónde va?" again.
    The editor in 069 is a **stand-in** (back link, "Nuevo juego", Nombre, the "después" line, a note pointing to the real
    Juegos editor of sketch 063, "Crear juego"); the real screen is 063's, with this entry (name prefilled) and exit
    (→ placing). Tested at 375×667: "Zorblax Quest" → editor → Crear juego → "¿Dónde va?" → Estante 5 → first spot →
    "Juego ubicado"; "+" right of it → "Zyx Nova" → Crear → editor hint names the spot → Crear juego → rail Zorblax
    Quest, Zyx Nova, Kingdomino…; ✕ on a "+" sheet then search Crear → "Después elegís dónde va."; back → Estantes. No errors.

## Round 6 — Nuevo estante and Editar
Asked: Nuevo estante → ask for a name first, or create "Estante 10" and rename later? Developer: *"ask for a name first.
What is the UI? a simple bottom sheet? what about edit?"* → answered: yes, a form sheet (D-19e already lists form
sheets), and Editar is the same sheet filled in.
67. **One name sheet creates and edits an estante.** D-19e header: estante tile · context line ("9 estantes" when
    creating, "48 juegos" when editing) · title **Nuevo estante** / **Editar estante** · ✕. Body: label "Nombre", a 48px
    field (max 40), hint "Un nombre que se reconozca en el salón.", one A1 Principal full-width button **Crear
    estante** / **Guardar**. Enter saves too.
    - Creating pre-fills the next number ("Estante 10") **selected**, so one tap creates it and typing replaces it;
      editing pre-fills the current name, also selected. The field is focused on open and the sheet sits on the keyboard.
    - Errors under the hint, in Peligro red, field outlined red: "Escribí un nombre." (empty or spaces) / "Ya hay un
      estante con ese nombre." (case- and accent-insensitive). Typing clears the error.
    - Saving closes the sheet and returns to Administrar estantes: a new estante is the last row, snackbar "Estante
      creado"; a rename updates the row, "Nombre guardado" (no snackbar if the name did not change). No estante page to
      open (45).
    - Editar in the estante's options sheet closes it and opens the name sheet after it has gone down (280ms).
    Measured with the simulated keyboard: 375×667 sheet 79–375, field 226–274, button 315–359, keyboard from 375; 360×640
    sheet 52–348, button 288–332, keyboard 348; 375×800 sheet 212–508. Button always fully above the keyboard. Light +
    dark; no errors. Tested: create default → "Estante 10" last + snackbar; next default "Estante 11"; spaces → error;
    "estante 3" → duplicate error; Editar Estante 3 → "Pared de la ventana" → row renamed + "Nombre guardado".

Asked: should Administrar estantes let you reorder? Developer: *"Yes, it needs reorder. drag and drop? what do you suggest?
the best place to trigger the order is on the list, isn't?"* → suggested an Ordenar mode with drag handles (iOS edit list /
M3), entered from the list header; not long-press on the row (undiscoverable, fights tap-to-open and scroll), not handles
always visible (clutter for a rare action); plus a non-drag way (WCAG 2.5.7). Developer picked **"Icon + handles only"**.
68. **Ordenar estantes = a mode.**
    - **Entry:** a 44px ⇅ icon (aria "Ordenar estantes") left of "+" in the Administrar estantes header (283–327, "+"
      327–371 at 375).
    - **In the mode:** the header becomes **"Ordenar estantes"** + **Listo** (A2) — no back link, the title moves up
      to the back link's row (78–104); a hint "Arrastrá ≡ al orden en que recorrés el salón."; rows are not tappable and
      end in a 44px **≡ handle**.
    - **Drag:** the row lifts (page background + large shadow) and follows the finger; it swaps with a neighbour when it
      passes that neighbour's middle. Tested: 140px down moves Estante 1 two places.
    - **Without dragging:** tapping ≡ marks it (tonal) and shows **↑ / ↓** (44px) on that row only; the top ↑ and
      bottom ↓ are disabled; focus stays on the arrow; a live region says "Estante 5, posición 3 de 9".
    - **Listo:** back to the list; if the order changed, snackbar "Orden guardado" + **Deshacer** (restores the order from
      before the mode).
    - The order is the estantes' order everywhere: this list and "O elegí un estante" in "¿Dónde va?" (checked: Estante 9
      moved first shows first there).
    375×667, light; no errors.

## Where we are (2026-09-17, management + Estantes page polish)
- **Current sketch:** `.planning/sketches/069-estantes-ubicar/index.html` — standalone, hand-written (no
  build step), uses `games.js` (434 real games) and `../themes/default.css`. View with
  `python3 -m http.server 8765` from the repo root →
  http://127.0.0.1:8765/.planning/sketches/069-estantes-ubicar/index.html
  Tools left in the sketch: Tema, Teclado simulado, Juegos sin lugar 6/434, Afuera (Fase 4) 3/0, Estante 10 vacío. No variants.
- **Settled in 069 (decisions 1–63):**
  - Estantes page: title + inbox badge (Pendientes, 59 / D-19g) + gear; idle = "¿Qué juego tenés en la mano?" + search
    only (54, 58). Focus on the empty field → Últimas búsquedas in the dropdown (58). No match → "Crear «texto»" (62).
  - Found game: the field keeps its name with ✕ back to idle (60, reverses 11); estante as context (icon + name, 63); rail
    with the game lifted; rhythm title→field 16, field→answer 32, label→lifted cover 16 (61).
  - Game sheet (29–33), "¿Dónde va?" full-height sheet (35–39), Mover (40), Quitar dialog (41–42) — unchanged.
  - Pendientes page: Afuera (Phase 4 data) + Sin ubicar sections (58).
  - Administrar estantes (gear): estante rows only, no chevron, "+" Nuevo estante in the header, row → sheet Editar /
    Eliminar (dialog) (43–46, 49).
- **App-wide rules** in `01.8.2-CONTEXT.md` / `01.8.2-BENCHMARK.md`: D-19e sheets, D-19f destructive dialog, D-19g pending
  work behind a header badge, D-00c placing/moving. **Recorded 2026-09-17:** D-08 rewritten (three pages, 1–68), D-09/D-10/D-11/D-21 aligned, D-19h status = dot + text,
  D-19i chevron = navigates, D-19j one main job per page + type ranks; BENCHMARK rows for status, chevron, reorder.
- **Also settled after this summary was written:** + beside the found game → "¿Qué juego va acá?" (64); prompt "¿Qué juego
  buscás?" / "Buscá un juego" (65); Crear → new-game editor → "¿Dónde va?", or straight into the "+" spot (66).
- **Also settled:** Nuevo estante / Editar name sheet (67); Ordenar mode (68).
- **Open items:** Catan family ranking in
  suggestions; `shelfDrawing` unused on Estantes; whether Quitar keeps Deshacer after confirming.
- **Measuring notes:** headless Chrome fires no focus events unless focus emulation is on (Playwright handles it);
  the sketch's `#tools` bar covers the header at 375px — hide it before real clicks; syntax-check the inline script
  (`node --check`) after scripted edits; the simulated keyboard is 292px (sized for 740–800 phones).
- **Working agreement:** one question at a time; sketches show ONLY the estante UI; measure before building variants;
  record every decision here; remove losing variants once picked.
- **Next:** the open items above (Editar / Nuevo estante), then sketch 074 (staff tab bar on
  public pages, D-14), then `/gsd-plan-phase 01.8.2`.
