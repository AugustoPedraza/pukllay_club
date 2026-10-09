# Requirements: PukllayClub

**Defined:** 2026-10-09
**Core Value:** A member can describe what they want in plain Spanish and find a game that fits —
even without already knowing board-game vocabulary.

## v1 Requirements

Requirements for milestone v1.2 "Web Tab — Sketch 070 Parity". Each maps to roadmap phases.

**Design contract.** Sketch 070 (`.planning/sketches/070-web-destacados/index.html`) plus
`.claude/skills/sketch-findings-pukllay_club/references/admin-web-destacados.md`. The developer
re-reviewed and approved the artefact on 2026-10-09. **Where the note and the artefact disagree,
the artefact wins** — 070's own README is known-stale on four points (a pencil beside the row name,
a separate `Filas del inicio` page, a `⌄` chevron, and `Quitar de la fila` confirming in a dialog;
all four were removed by later decisions and must not be reintroduced).

**Copy rule.** Every Spanish string is **verbatim** from the findings note's "Spanish copy,
verbatim" section — Argentine voseo. No paraphrasing, no re-translation, no register changes.

### Rail

- [ ] **RAIL-01**: The destacada rail carries a "+" slot in every gap — before the first cover,
      between every two, after the last (N+1) — always visible, with a 44px hit box (20px column
      plus 12px each side) and no `gap` on the rail itself
- [x] **RAIL-02**: Each slot has a Spanish accessible label following the artefact's `where()`
      grammar: `Agregar un juego al principio` / `… entre {X} y {Y}` / `… al final`
- [ ] **RAIL-03**: An empty row's rail is a single 96×100 dashed tile beside the line
      `Tocá + para elegir el primer juego.`
- [x] **RAIL-04**: At the 20-game cap every slot dims and tapping one snacks
      `Ya hay 20 juegos. Quitá uno para agregar otro.` (no action, no Deshacer)
- [x] **RAIL-05**: The inline `Agregar un juego` field and `#web-search-results` are **removed** —
      070 decision 12 / D-19j forbids a second control beside the main one
- [ ] **RAIL-06**: A placed cover lands with a 520ms animation (`cubic-bezier(.2,.8,.3,1)`), with a
      `prefers-reduced-motion: reduce` opt-out. **Not** estantes' 620ms
- [x] **RAIL-07**: The rail's `role="group"` stays labelled by the row name (`aria-labelledby`), so
      the row's identity is announced once rather than on every cover

### Add a game

- [x] **ADD-01**: Tapping a slot opens the full-height `¿Qué juego va acá?` sheet, whose header
      context names the chosen spot: `{fila} · al principio | entre {X} y {Y} | al final`
- [x] **ADD-02**: The sheet's search field `Buscá un juego` is pinned and focused on open
- [x] **ADD-03**: Idle (empty query) lists `Últimas novedades` — the 6 most recently added games
      not already in the row
- [x] **ADD-04**: Typing searches every game, starts-with before contains, 6 results max, excluding
      retired games
- [x] **ADD-05**: A game already in the row shows the sub `Ya está en la fila · pasa a este lugar`
      and is **moved, not duplicated**; picking the game already in that exact spot snacks
      `Ya está en ese lugar` (no action)
- [x] **ADD-06**: Placing closes the sheet and snacks `Juego agregado` + **Deshacer**
- [x] **ADD-07**: No match shows `Ningún juego se llama así.` plus `Crear «{q}»` /
      `Agregarlo al catálogo`
- [ ] **ADD-08**: `Crear «{q}»` is **designed in its own sketch round and then built** — it is the
      one piece sketch 070 never drew (the artefact stubs it to a snackbar). Estantes' equivalent is
      settled in sketch 069 decision 66; borrow from it rather than starting cold

### Move a game

- [ ] **MOVE-01**: A cover's options sheet carries three rows with their hint lines — `Ver ficha`
      (*La página del juego en la web*), `Mover` (*Elegís otro lugar en la fila*), and
      `Quitar de la fila` (*Deja de verse en el inicio*)
- [ ] **MOVE-02**: `Mover` opens the full-height `¿Dónde va?` sheet with the rail drawn **without
      the moving game**, so the gaps are the positions it will actually have; the game keeps its old
      spot until one is chosen. Slot labels: `Mover al principio` / `Mover entre {X} y {Y}` /
      `Mover al final`
- [ ] **MOVE-03**: Moving snacks `Juego movido` + **Deshacer**
- [ ] **MOVE-04**: `Ver ficha` opens the game's public detail page. (070 left this stubbed to a
      snackbar and the findings list it as another sketch's job; navigating to the existing public
      page is the obvious reading. If a different treatment is wanted, that is a separate sketch)
- [ ] **MOVE-05**: `Quitar de la fila` keeps its settled shape — no dialog, never red, immediate
      with `Juego quitado` + Deshacer restoring the exact position (D-19k, already shipped)

### Destacada as a role

- [ ] **ROLE-01**: `Destacar` moves the destacada role to a hand-picked row; the row that held it
      becomes a normal row and **heads the rest**. Exactly one row holds the role at any time
- [ ] **ROLE-02**: Only `:manual` rows can be destacada — automatic rows (Nivel bands,
      Recientemente añadidos) never offer `Destacar`
- [ ] **ROLE-03**: A row with more than 20 games cannot be destacada; its `Destacar` sub-line reads
      `Tiene {n} juegos · la destacada lleva hasta 20` and picking it anyway snacks
      `Tiene {n} juegos. Dejá 20 o menos para destacarla.`
- [ ] **ROLE-04**: A hidden row becomes visible when it becomes destacada, and the destacada can
      never be hidden — the home always shows it
- [ ] **ROLE-05**: `Cambiar la destacada`, on the destacada's own page, scrolls to `Otras filas`
      with the hint `Elegí otra fila de la lista y tocá Destacar`
- [ ] **ROLE-06**: Taking the role snacks `{fila} es la destacada` + **Deshacer**, and the 20-game
      cap follows the role

### Page and row chrome

- [ ] **CHROME-01**: The row name is a 44px button opening the row-options sheet — no pencil, no
      `⌄` chevron. It uses `padding: 11px 8px` (not `min-height`) so a one-line and a wrapped
      two-line name keep the same air above the context line
- [ ] **CHROME-02**: The row-options sheet carries the settled rows in order — `Destacar` /
      `Cambiar la destacada` / `Editar la fila` / `Juegos` / `Ocultar del inicio` ·
      `Mostrar en el inicio` — each shown only in its stated condition. Rows are hide-only; there
      is no delete
- [ ] **CHROME-03**: `⇅ Ordenar filas` and `＋ Nueva fila` are 44px icon buttons in the **page
      header**, the create action rightmost
- [ ] **CHROME-04**: One form sheet (`Editar fila` / `Nueva fila`) replaces the inline `Ajustes`
      panel and the bottom create form: `Nombre` (48px, maxlength 40) and `Subtítulo` (a textarea
      growing from two lines to three, maxlength 160), one shared hint, and the settled errors
- [ ] **CHROME-05**: The context line reads `{n} de 20 juegos` for the destacada, `{n} juegos` for
      a hand-picked row, `Sin juegos, no se ve en el inicio` when empty, prefixed `● Oculta ·` when
      hidden — state only, no kind tag
- [ ] **CHROME-06**: `Otras filas` rows carry a 40×40 kind tile with a count badge on its
      **bottom-right** corner in page fill + stroke — never the Pendientes badge's corner or colour
      (D-19m)
- [ ] **CHROME-07**: `Ordenar filas` is a mode with ≡ drag handles, a non-draggable `Destacada` row
      reading `Siempre primera`, tap-≡-for-↑/↓ with a live region, and `Listo` → `Orden guardado` +
      Deshacer
- [ ] **CHROME-08**: `section_live/edit.ex` becomes the same page shape scoped to one row, with a
      `‹ Web` back link and no list. The 20-game cap applies only to the destacada

### Context API

- [x] **CTX-01**: `Sections` gains insert-at-index, preserving the dense-position invariant (D-25)
      and the transactional 20-game featured cap. Index semantics are pinned explicitly and tested
      at slot 0, slot n, and a middle slot
- [x] **CTX-02**: `Sections` gains move-to-index. Its index arithmetic excludes the moving game, so
      a move to slot `i` cannot land one spot off
- [ ] **CTX-03**: `Sections` gains an atomic featured-role move — today `sections.featured` is set
      only by a migration backfill and no function moves it. Setting the role on one row clears it
      on the other inside one transaction
- [x] **CTX-04**: Every new LiveView event bounds-checks its slot index against the **live** member
      count rather than a stale client view, parses untrusted game-id and index params as integers,
      and keeps the `:manual`-vs-`:automatic` guard

## v2 Requirements

Deferred to a future milestone. Tracked but not in this roadmap.

### Admin parity

- **AUDIT-01**: Diff every other admin page against its winning sketch (065, 069, the juegos and
  estantes sketches) to measure the same class of sealed-phase-vs-sketch gap this milestone found
  on the Web tab — the explicit reassessment at this milestone's end
- **AUDIT-02**: Record whatever that audit finds as real deferred items, so a gap can never again
  go unlisted at a milestone close

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Every admin page other than the Web tab | Scoped deliberately to one screen — screen-by-screen to completion, then verify. The rest is unmeasured; measuring it is AUDIT-01 |
| The public home page itself | 070 designed the admin that curates the home, not the home. Listed as "not drawn, still open" in the findings |
| A device pass on a 61-cover / 8,592px rail | 070 accepted the long swipe deliberately without testing it on real hardware; no new decision needed here |
| Deleting rows or games | Rows are hide-only (D-17/E6) and removal from a row is undoable list editing, not destruction (D-19k) |
| Reopening 070's settled decisions | The developer approved the artefact. Decisions 5 and 12 (slots replace the inline field) and 7 (destacada is a role) are inputs, not questions |

## Traceability

Which phases cover which requirements. Populated during roadmap creation (2026-10-09).

| Requirement | Phase | Status |
|-------------|-------|--------|
| RAIL-01 | Phase 01.8.4 | Pending |
| RAIL-02 | Phase 01.8.4 | Complete |
| RAIL-03 | Phase 01.8.4 | Pending |
| RAIL-04 | Phase 01.8.4 | Complete |
| RAIL-05 | Phase 01.8.4 | Complete |
| RAIL-06 | Phase 01.8.4 | Pending |
| RAIL-07 | Phase 01.8.4 | Complete |
| ADD-01 | Phase 01.8.4 | Complete |
| ADD-02 | Phase 01.8.4 | Complete |
| ADD-03 | Phase 01.8.4 | Complete |
| ADD-04 | Phase 01.8.4 | Complete |
| ADD-05 | Phase 01.8.4 | Complete |
| ADD-06 | Phase 01.8.4 | Complete |
| ADD-07 | Phase 01.8.4 | Complete |
| ADD-08 | Phase 01.8.8 | Pending |
| MOVE-01 | Phase 01.8.5 | Pending |
| MOVE-02 | Phase 01.8.5 | Pending |
| MOVE-03 | Phase 01.8.5 | Pending |
| MOVE-04 | Phase 01.8.5 | Pending |
| MOVE-05 | Phase 01.8.5 | Pending |
| ROLE-01 | Phase 01.8.7 | Pending |
| ROLE-02 | Phase 01.8.7 | Pending |
| ROLE-03 | Phase 01.8.7 | Pending |
| ROLE-04 | Phase 01.8.7 | Pending |
| ROLE-05 | Phase 01.8.7 | Pending |
| ROLE-06 | Phase 01.8.7 | Pending |
| CHROME-01 | Phase 01.8.6 | Pending |
| CHROME-02 | Phase 01.8.6 | Pending |
| CHROME-03 | Phase 01.8.6 | Pending |
| CHROME-04 | Phase 01.8.6 | Pending |
| CHROME-05 | Phase 01.8.6 | Pending |
| CHROME-06 | Phase 01.8.6 | Pending |
| CHROME-07 | Phase 01.8.6 | Pending |
| CHROME-08 | Phase 01.8.6 | Pending |
| CTX-01 | Phase 01.8.4 | Complete |
| CTX-02 | Phase 01.8.4 | Complete |
| CTX-03 | Phase 01.8.7 | Pending |
| CTX-04 | Phase 01.8.4 | Complete |

**Per-phase totals:** 01.8.4 → 17 (RAIL-01..07, ADD-01..07, CTX-01, CTX-02, CTX-04) ·
01.8.5 → 5 (MOVE-01..05) · 01.8.6 → 8 (CHROME-01..08) ·
01.8.7 → 7 (ROLE-01..06, CTX-03) · 01.8.8 → 1 (ADD-08). Sum = 38.

**Coverage:**

- v1 requirements: 38 total
- Mapped to phases: 38 ✓
- Unmapped: 0 ✓
- Duplicates (a requirement in more than one phase): 0 ✓

---
*Requirements defined: 2026-10-09*
*Last updated: 2026-10-09 — traceability populated from the v1.2 roadmap (Phases 01.8.4–01.8.8)*
