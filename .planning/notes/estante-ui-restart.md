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

## Where we are (2026-09-17, end of session)
- **Current sketch:** `.planning/sketches/069-estantes-ubicar/index.html` — standalone, hand-written (no
  build step), uses `games.js` (434 real games) and `../themes/default.css`. View with
  `python3 -m http.server 8765` from the repo root →
  http://127.0.0.1:8765/.planning/sketches/069-estantes-ubicar/index.html
  Tools left in the sketch: Tema, Teclado simulado, Estante 10 vacío (to try decision 35's empty case). No variants.
- **Settled in 069 (decisions 1–42):** search → one game → its estante rail with the game lifted; Últimas búsquedas;
  the game options sheet (✕ header, estante above the name, Ver ficha / Mover / Quitar with hints); a game with no
  spot opens the full-height **"¿Dónde va?"** sheet at once (search an estante or a neighbour game, the field keeps
  the estante, "+" spots, empty estante = direct, "Juego ubicado" + landing animation); **Mover** = the same sheet as
  one transaction ("Juego movido"); **Quitar** confirms in a dialog.
- **App-wide rules that came out of it** (already in `01.8.2-CONTEXT.md`): D-19e sheets (✕ header, header anatomy,
  two-line hint rows, pinned header), D-19f destructive actions confirm in a centred dialog, D-00c placing/moving
  (choose the spot; replaces "far right end"). Also mirrored in `01.8.2-BENCHMARK.md`.
- **Open items found on the way:** Catan family ranking in suggestions (`cat` shows 1 of 5 editions); the old
  `shelfDrawing` (barcode look) still used by the idle hero and the management stub rows — the new `estante` icon
  (decision 33) should replace it there; status rule (22, dot + text) still not written into `01.8.2-CONTEXT.md`;
  whether Quitar keeps its Deshacer snackbar now that it also confirms (kept for now, D-19f allows both).
- **Measuring notes:** headless Chrome fires no focus events unless `Emulation.setFocusEmulationEnabled` is on;
  after removing code with scripts, syntax-check the inline script (`node --check`) — a stray brace blanked the page
  twice this session.
- **Working agreement:** the developer asks/answers one question at a time; sketches show ONLY the estante UI
  (no 065 walk); measure before building variants; record every decision here; remove losing variants once picked.
- **Next:** **the management page** (reached from the gear, decision 26): the estante list (estante icon, name,
  "N juegos" — decisions 14/17 moved there), an estante's page (browse its rail), Agregar juegos, ordering, rename,
  delete estante (D-10 → dialog per D-19f), Crear estante. Placing, moving and removing a single game are already
  designed (36–41) and should be reused, not redrawn. Then sketch 074 (staff tab bar on public pages, D-14), then
  `/gsd-plan-phase 01.8.2`.
