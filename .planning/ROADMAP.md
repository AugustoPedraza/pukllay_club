# Roadmap: PukllayClub

## Milestones

- ✅ **v1.0 MVP Catalog** — Phase 0, Phase 1 (+ insertions 01.1–01.6) (shipped 2026-09-11)
- ✅ **v1.1 Sharable Version** — Phase 01.7, 01.8, 01.8.1, 01.8.2, 01.8.3 (shipped 2026-10-09)
- 🚧 **v1.2 Web Tab — Sketch 070 Parity** — Phases 01.8.4, 01.8.5, 01.8.6, 01.8.7, 01.8.8
  (38 v1 requirements, admin Web tab only)
- ⏳ **Later** — Phase 2, Phase 3, Phase 4 (not yet started, numbers and scope unchanged)

## Phases

<details>
<summary>✅ v1.0 MVP Catalog (Phase 0, Phase 1 + insertions 01.1–01.6) — SHIPPED 2026-09-11</summary>

Full phase-by-phase detail archived at `.planning/milestones/v1.0-ROADMAP.md`. Summary:

- [x] Phase 0: Walking Skeleton to Production — deploy pipeline only, no product features (completed 2026-07-27)
- [x] Phase 1: Catalog v1 — public browse/filter/search catalog, no auth, no AI (completed 2026-08-18)
- [x] Phase 01.1: Site Shell & Content Pages
- [x] Phase 01.2: Catalog & Detail Navigation Polish (completed 2026-08-29)
- [x] Phase 01.3: Game Detail Layout & Content Accuracy (completed 2026-09-01)
- [x] Phase 01.3.1: Game Image Quality & Multi-Image Gallery
- [x] Phase 01.4: UI Polish Pass for About Page Sketches
- [x] Phase 01.5: About Page CTA Rhythm & Header Morph Refinement (+ quick task 260910-av6)
- [x] Phase 01.6: Light/Dark Theme Color-Family Consistency (6/6 quick tasks)

</details>

<details>
<summary>✅ v1.1 Sharable Version (Phases 01.7–01.8.3) — SHIPPED 2026-10-09 (override closeout)</summary>

Full phase-by-phase detail archived at `.planning/milestones/v1.1-ROADMAP.md`; the phase
directories themselves are at `.planning/milestones/v1.1-phases/`. 5 phases, 63 plans, 166 tasks.

- [x] Phase 01.7: Production Catalog Data & Security Hardening (5/5 plans) — completed 2026-09-11
- [x] Phase 01.8: SEO, Structured Data & Social Sharing (7/7 plans) — completed 2026-09-12
- [x] Phase 01.8.1: Staff Admin — Ludoteca, Shelves & Curated Destacados (15/15 plans) — completed 2026-09-16
- [x] Phase 01.8.2: Admin UI/UX Redesign (22/22 plans) — completed 2026-10-09
- [x] Phase 01.8.3: Admin Screen-by-Screen Refinement (14/14 plans) — completed 2026-09-28

**Closed as `override_closeout`, not a verified closeout.** 12 open artifacts acknowledged
(1 carried forward from v1.0), no milestone audit was run, and phases 01.7/01.8/01.8.1 reported
`verification=stale` at close — a fingerprint mismatch against later commits, not a finding.
Two developer-attributed waivers live inside 01.8.2 (D-37's unpersisted enrichment failure
reason; open item 1's unfilled device pass). Full disclosure in `.planning/MILESTONES.md` and
STATE.md `## Deferred Items`.

</details>

**🚧 v1.2 Web Tab — Sketch 070 Parity** — Phases 01.8.4 through 01.8.8, decimal insertions ahead
of Phase 2 (continuing this project's convention: 01.7, 01.8, 01.8.1, 01.8.2, 01.8.3 all precede
it). Scope is the **admin Web tab only** — `lib/pukllay_club_web/live/admin/section_live/index.ex`
and `edit.ex`, the `Catalog.Sections` context, and `AdminComponents`. Design contract: sketch 070
plus `.claude/skills/sketch-findings-pukllay_club/references/admin-web-destacados.md`; where the
two disagree, **the artefact wins** (070's README is known-stale on four points). Every
user-facing Spanish string is **verbatim** from the findings note's "Spanish copy, verbatim"
section (Argentine voseo) — no paraphrasing. Mobile-first: every new control meets the project's
touch-target minimum and the rail scrolls horizontally.

- [ ] **Phase 01.8.4: The Rail Becomes the Add Surface** - Positions API + a "+" in every gap + the `¿Qué juego va acá?` sheet; the inline `Agregar un juego` field is deleted
- [ ] **Phase 01.8.5: Moving a Game** - The cover sheet grows `Ver ficha` / `Mover`, and `Mover` opens `¿Dónde va?` drawn without the moving game
- [ ] **Phase 01.8.6: Page & Row Chrome** - Row name as the one 44px control, one `Editar fila` / `Nueva fila` sheet, header ⇅/＋, `Otras filas` tiles, `Ordenar filas` drag, `edit.ex` parity
- [ ] **Phase 01.8.7: Destacada Becomes a Role** - `Destacar` / `Cambiar la destacada` move the role atomically between hand-picked rows, with the cap following it
- [ ] **Phase 01.8.8: `Crear «{q}»` — Designed, Then Built** - The one piece 070 never drew gets its own sketch round first; then the end-of-milestone UAT device pass

> ⚠️ **Tooling hazard — these are decimal phases, so GSD's resume guard is blind here.**
> `execute-phase`'s `safe_resume_gate` computes `PHASE_N=$((10#{phase_number}))`, which aborts
> outright on `01.8.4`, and its commit-scope regex `^[a-z]+\((0*PHASE_N)-(0*PLAN_N)\):` never
> matches this repo's real `feat(01.8.4-7):` scopes. **Consequence: a half-executed plan in these
> phases is NOT detected, and a bare `/gsd-execute-phase` will restart it at Task 1.** Do not
> "fix" it by writing the SUMMARY first either — `has_summary` then skips the plan's remaining
> tasks silently. Read `.claude/CLAUDE.md` → "GSD Decimal-Phase Resume Bug" before resuming any
> partially-executed plan in this milestone, and use its manual recovery path (inspect what
> landed, run the remaining steps by hand, write the SUMMARY last). Same applies to the
> `branching_strategy: "none"` vs protected-`main` mismatch documented just above it in CLAUDE.md:
> confirm `git status` says "up to date with origin/main" **before** starting any of these phases.

### Phase 01.8.4: The Rail Becomes the Add Surface

**Goal**: Staff can place any game at an exact spot in the destacada rail by tapping the "+" in that gap — and the rail's slots are the page's only add control.
**Depends on**: Phase 01.8.3 (shipped — the sheet/snackbar/button vocabulary and the current page)
**Requirements**: CTX-01, CTX-02, CTX-04, RAIL-01, RAIL-02, RAIL-03, RAIL-04, RAIL-05, RAIL-06, RAIL-07, ADD-01, ADD-02, ADD-03, ADD-04, ADD-05, ADD-06, ADD-07

> **Why this phase is the largest, and why it cannot be split.** RAIL-05 deletes the inline
> `Agregar un juego` field, which is today the *only* way to add a game — so it can only ship in
> the same phase as the sheet that replaces it (ADD-01), and that sheet is only useful with its
> search (ADD-04): a sheet offering just `Últimas novedades` would leave staff unable to add
> anything outside the 6 newest games. ADD-05 (a game already in the row *moves*) needs
> move-to-index, so CTX-02 lands here too, not with the move sheet. Sequence the context API
> (CTX-01, CTX-02) as this phase's **first plans** — `Sections.add_game/2` only appends today, so
> nothing above it can place at a chosen slot. CTX-04's parse/bounds-check guard is established
> here, on the first untrusted slot-index and game-id params, and every later phase's new events
> follow that same pattern.

**Success Criteria** (what must be TRUE):

  1. Tapping the "+" before the first cover, between two covers, or after the last opens the full-height `¿Qué juego va acá?` sheet whose header context names that spot (`{fila} · al principio` / `entre {X} y {Y}` / `al final`), and the picked game lands at exactly that index — insert-at-index is tested at slot 0, a middle slot and slot n, leaving positions dense `0..n-1` (D-25) and the 20-game featured cap enforced inside the transaction
  2. With an empty query the sheet lists `Últimas novedades` (the 6 most recently added games not already in the row); typing searches every non-retired game starts-with before contains, 6 max; a game already in the row shows the sub `Ya está en la fila · pasa a este lugar` and is **moved, not duplicated** (the row's member count is unchanged), while picking the game already in that exact spot snacks `Ya está en ese lugar` with no action and no state change
  3. Placing closes the sheet and snacks `Juego agregado` + **Deshacer**, and the cover lands with a 520ms `cubic-bezier(.2,.8,.3,1)` animation — not estantes' 620ms — with no animation under `prefers-reduced-motion: reduce`
  4. The inline `Agregar un juego` field and `#web-search-results` are absent from the rendered page (asserted, not just visually gone), so the slots are the only add control; an empty row's rail is the single 96×100 dashed tile beside `Tocá + para elegir el primer juego.`
  5. At 20 members every slot renders dimmed and tapping one snacks `Ya hay 20 juegos. Quitá uno para agregar otro.` with no action; each slot carries its `where()` label (`Agregar un juego al principio` / `… entre {X} y {Y}` / `… al final`) in a 44px hit box (20px column + 12px each side, no `gap` on the rail), the rail's `role="group"` is `aria-labelledby` the row name, and every slot index and game id arrives parsed as an integer and bounds-checked against the **live** member count with the `:manual`-vs-`:automatic` guard intact

**Plans:** 4 plans in 3 waves

Plans:
**Wave 1**

- [ ] 01.8.4-01-PLAN.md — Tracer: a game lands at the chosen slot end to end, plus the positional `Sections` API (`insert_game_at/3`, `move_game_to/3`, `rest_index/2`, `featured_cap/0`) and the shared `Admin.Params` guard
- [ ] 01.8.4-02-PLAN.md — `Catalog` ranked search (accent-folded, starts-with-first) and `Últimas novedades` recents

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 01.8.4-03-PLAN.md — The sheet becomes the only add control: real search, the member move, the no-match stub, the 20-game cap, and the inline field's deletion

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 01.8.4-04-PLAN.md — The rail reads like 070: empty-row tile, the 520ms landing, the CSS-source geometry gate and the 44px hit-box probe

**UI hint**: yes

### Phase 01.8.5: Moving a Game

**Goal**: A cover already in the row can be sent to another exact spot from the page itself, without removing and re-adding it.
**Depends on**: Phase 01.8.4 (CTX-02 move-to-index, and the slot markup/geometry the `¿Dónde va?` rail reuses)
**Requirements**: MOVE-01, MOVE-02, MOVE-03, MOVE-04, MOVE-05

> `¿Dónde va?` is the same N+1 slot pattern as 01.8.4's rail with a different label set, so this
> phase has two callers for it — decide explicitly, in planning, whether the slot becomes a shared
> `AdminComponents` function component or stays local to `section_live`.

**Success Criteria** (what must be TRUE):

  1. Tapping a cover opens its options sheet carrying three 64px two-line rows in order with their hint lines — `Ver ficha` (*La página del juego en la web*), `Mover` (*Elegís otro lugar en la fila*), `Quitar de la fila` (*Deja de verse en el inicio*)
  2. `Mover` opens the full-height `¿Dónde va?` sheet with the rail drawn **without the moving game**, so the visible gaps are the positions it will actually have, slots labelled `Mover al principio` / `Mover entre {X} y {Y}` / `Mover al final`; the game keeps its old spot until a slot is chosen (dismissing the sheet changes nothing)
  3. Choosing a slot lands the game at that exact visible gap for both a forward and a backward move — move-to-index arithmetic excludes the moving game, so a move to slot `i` never lands one spot off — and snacks `Juego movido` + **Deshacer**
  4. `Ver ficha` navigates to that game's existing public detail page
  5. `Quitar de la fila` still has no dialog, is never red, and removes immediately with `Juego quitado` + **Deshacer** restoring the exact original position (D-19k, already shipped — asserted here as a regression check now that two more rows share its sheet)

**Plans**: TBD
**UI hint**: yes

### Phase 01.8.6: Page & Row Chrome

**Goal**: The page's chrome matches 070 — the row name is the single control that opens a row, one form sheet both creates and edits, and `Otras filas` reads as the designed group.
**Depends on**: Phase 01.8.5
**Requirements**: CHROME-01, CHROME-02, CHROME-03, CHROME-04, CHROME-05, CHROME-06, CHROME-07, CHROME-08

> CHROME-01 and CHROME-02 ship together — the name button is the row-options sheet's only entry
> point, so either alone leaves a dead control or an unreachable sheet. CHROME-04 ships in the
> same phase as the removal of the inline `Ajustes` panel and the bottom create form, because
> those are today's only way to rename a row or set a subtitle.

**Success Criteria** (what must be TRUE):

  1. The row name is one 44px button using `padding: 11px 8px` (no pencil, no `⌄` chevron) that opens the row-options sheet, and a one-line name (44.1px) and a wrapped two-line name (66.2px) keep the same visible air above the context line
  2. The row-options sheet shows the settled rows in order and only in their stated condition — `Editar la fila` always, `Juegos` only from the list, `Ocultar del inicio` · `Mostrar en el inicio` per visibility (the `Destacar` / `Cambiar la destacada` rows arrive in 01.8.7) — and there is no delete action for a row anywhere on the page
  3. `⇅ Ordenar filas` and `＋ Nueva fila` are 44px icon buttons in the **page header** with the create action rightmost, and the inline `Ajustes` panel and bottom create form are gone — replaced by one sheet titled `Editar fila` / `Nueva fila` with `Nombre` (48px, maxlength 40, pre-filled and selected), `Subtítulo` (a textarea growing 72px→96px, maxlength 160), the single hint `El título y esta línea son lo que se ve en el inicio.`, and the errors `Escribí un nombre.` / `Ya hay una fila con ese nombre.`
  4. The context line reads `{n} de 20 juegos` for the destacada, `{n} juegos` for a hand-picked row, `Sin juegos, no se ve en el inicio` when empty, prefixed `● Oculta ·` when hidden, with no kind tag; `Otras filas` rows carry a 40×40 kind tile whose count badge hangs off its **bottom-right** corner in page fill + 1px stroke — never the Pendientes badge's top-right corner or filled-primary colour (D-19m) — with the count in the tile's accessible name
  5. `Ordenar filas` is a mode with 44px ≡ drag handles, a non-draggable `Destacada` row reading `Siempre primera`, tap-≡-for-↑/↓ announced in a live region, and `Listo` → `Orden guardado` + **Deshacer**; `section_live/edit.ex` renders the same page shape scoped to one row with a `‹ Web` back link, no list, and no 20-game cap

**Plans**: TBD
**UI hint**: yes

### Phase 01.8.7: Destacada Becomes a Role

**Goal**: The destacada is a role that moves between hand-picked rows rather than a fixed row — this milestone's only net-new product behaviour and its only data-model work.
**Depends on**: Phase 01.8.6 (`Destacar` and `Cambiar la destacada` live in the row-options sheet, so ROLE-05 is unreachable before CHROME-02)
**Requirements**: CTX-03, ROLE-01, ROLE-02, ROLE-03, ROLE-04, ROLE-05, ROLE-06

> Kept in its own phase with its own test surface, deliberately not blended into the UI-chrome
> phase: `sections.featured` is today set **only** by a migration backfill and no function moves
> it, so CTX-03's atomic role move lands here first and the ROLE-* behaviours sit on top of it.

**Success Criteria** (what must be TRUE):

  1. `Destacar` on a hand-picked row moves the role inside one transaction — exactly one row has `featured: true` afterwards, the row that held it becomes a normal row that **heads the rest**, and a failed move leaves both rows exactly as they were (tested, including the rollback path)
  2. Automatic rows (the Nivel bands, Recientemente añadidos) never offer `Destacar` at all, and a hand-picked row with more than 20 games shows the sub-line `Tiene {n} juegos · la destacada lleva hasta 20` and, picked anyway, snacks `Tiene {n} juegos. Dejá 20 o menos para destacarla.` while changing no row
  3. A hidden row becomes visible the moment it takes the role, and the destacada's own options sheet offers no `Ocultar del inicio` — the home always shows it
  4. `Cambiar la destacada`, shown only on the destacada's own page, scrolls to `Otras filas` with the hint `Elegí otra fila de la lista y tocá Destacar`
  5. Taking the role snacks `{fila} es la destacada` + **Deshacer**, and the 20-game cap follows the role: the new destacada's slots dim at 20 and the former destacada's slots stop dimming, with its context line switching from `{n} de 20 juegos` to `{n} juegos`

**Plans**: TBD
**UI hint**: yes

### Phase 01.8.8: `Crear «{q}»` — Designed, Then Built

**Goal**: The add sheet's no-match branch creates a game for real instead of snacking a stub, and the finished Web tab is walked end-to-end once on a real device.
**Depends on**: Phase 01.8.7 (and Phase 01.8.4's ADD-07, which ships the no-match line stubbed to a snackbar exactly as the artefact does)
**Requirements**: ADD-08

> **This phase's first step is `/gsd-sketch`, not implementation.** `Crear «{q}»` is the one piece
> sketch 070 never drew — everything else in this milestone implements an already-approved design
> and needs no sketch round. Borrow from sketch 069 decision 66 (Estantes' settled equivalent,
> into sketch 063's editor) rather than starting cold. The end-of-milestone UAT pass lives here
> too, per the developer's recorded preference: screen-by-screen to completion, then one full
> walk at the end — not a verification walk between every change.

**Success Criteria** (what must be TRUE):

  1. A sketch round settles `Crear «{q}»` and its decisions are recorded in `admin-web-destacados.md` **before** any implementation plan for it is written
  2. In the `¿Qué juego va acá?` sheet, no match shows `Ningún juego se llama así.` plus `Crear «{q}»` / `Agregarlo al catálogo`, and `Crear «{q}»` now completes the designed flow and ends with the new game placed in the slot the staff member originally tapped — no stub snackbar path remains in the code
  3. One end-of-milestone UAT walk on a real device covers the whole curation path in sequence — place at a chosen slot, move a cover, `Quitar de la fila` + Deshacer, move the destacada role, rename a row, reorder rows — with every Spanish string checked verbatim against the findings note's "Spanish copy, verbatim" section and every event introduced this milestone re-checked against CTX-04's parse/bounds guard

**Plans**: TBD
**UI hint**: yes

**After this milestone:** the stated reassessment is AUDIT-01/AUDIT-02 (v2 requirements, **not**
phases here) — diff every *other* admin page against its winning sketch to measure the same class
of sealed-phase-vs-sketch gap this milestone found on the Web tab, and record what it finds as
real deferred items.

**⏳ Later milestones** — Phases 2, 3 and 4 below keep their original numbers and scope. Phase 2
is the project's stated core value.

### Phase 2: Natural-Language Spanish Search + Auth

**Goal**: Members can describe what they want in plain Spanish and get matched games — the core value of the product — then save favorites behind lightweight auth.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: SEARCH-01, SEARCH-02, SEARCH-03, SEARCH-04, AUTH-01, AUTH-02, AUTH-03
**Success Criteria** (what must be TRUE):

  1. Member can type a natural-language Spanish query (e.g. "algo de negociación estilo Catan") and get relevant matched games back, ranked by hybrid vector+keyword scoring
  2. The NL query parser maps free text onto the same plain-Spanish tag vocabulary established in Phase 1, and every embedding/LLM call runs asynchronously (local CPU embeddings + Oban-queued LLM parsing) — never on the request hot path
  3. If the LLM/embedding pipeline is unavailable or rate-limited, the member still gets usable keyword-only results instead of an error
  4. Member can sign in via a passwordless magic-link (`phx.gen.auth`) and mark/unmark games as favorites
  5. A member's favorites persist across sessions

**Plans**: TBD
**UI hint**: yes

### Phase 3: RAG Rules Oracle

**Goal**: Members can ask a specific game's rules question in Spanish and get a trustworthy answer grounded in that game's official rulebook.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: RULES-01, RULES-02, RULES-03
**Success Criteria** (what must be TRUE):

  1. Member can select a specific game and ask a rules question in Spanish
  2. The answer is grounded in that game's official rulebook and cites the specific passage/section it draws from
  3. Rules Q&A stays scoped to the selected game — there is no open-ended cross-game question path

**Plans**: TBD
**UI hint**: yes

### Phase 4: Club Operations

**Goal**: Club admins can manage the catalog and physical copies and track in-person rentals, using an admin role distinct from member magic-link auth.

> **Scope note (2026-09-13):** staff auth, catalog add/edit/remove, and the curated first carousel
> moved forward into Phase 01.8.1 (Staff Admin). Phase 4 keeps physical copies, rental tracking,
> and promotions — revisit these criteria (and seed `saturday-sessions-and-managed-carousels`)
> when Phase 4 is planned.
>
> **Scope note (2026-09-16):** copies as rows, the copy count, and per-copy shelf position moved
> forward into Phase 01.8.2 (see `01.8.2-CONTEXT.md` D-01..D-04, D-20). Phase 4 keeps checkout/return
> state, who has a copy, the rentals dashboard, and promotions, building on 01.8.2's copies table.
> Criterion 3 ("add, edit, and remove … physical copies") is partially satisfied by 01.8.2.
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: CLUBOPS-01, CLUBOPS-02, CLUBOPS-03, CLUBOPS-04
**Success Criteria** (what must be TRUE):

  1. Admin can mark a physical copy as checked-out or returned
  2. Admin can view which copies are currently checked out and to whom, from a dashboard distinct from the member catalog view
  3. Admin can add, edit, and remove catalog entries and physical copies
  4. Admin can manage promotions

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 0 → 1 → 01.7 → 01.8 → 01.8.1 → 01.8.2 → 01.8.3 → 01.8.4 → 01.8.5 → 01.8.6 → 01.8.7 → 01.8.8 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Walking Skeleton to Production | 6/6 | Complete — shipped v1.0 | 2026-07-27 |
| 1. Catalog v1 (+ 01.1–01.6) | 87/87 | Complete — shipped v1.0 | 2026-09-11 |
| 01.7. Production Catalog Data & Security Hardening | 5/5 | Complete — shipped v1.1 | 2026-09-11 |
| 01.8. SEO, Structured Data & Social Sharing | 7/7 | Complete — shipped v1.1 | 2026-09-12 |
| 01.8.1. Staff Admin — Ludoteca, Shelves & Curated Destacados | 15/15 | Complete — shipped v1.1 | 2026-09-16 |
| 01.8.2. Admin UI/UX Redesign | 22/22 | Complete — shipped v1.1 | 2026-10-09 |
| 01.8.3. Admin Screen-by-Screen Refinement | 14/14 | Complete — shipped v1.1 | 2026-09-28 |
| 01.8.4. The Rail Becomes the Add Surface | 0/4 | Not started | - |
| 01.8.5. Moving a Game | 0/TBD | Not started | - |
| 01.8.6. Page & Row Chrome | 0/TBD | Not started | - |
| 01.8.7. Destacada Becomes a Role | 0/TBD | Not started | - |
| 01.8.8. `Crear «{q}»` — Designed, Then Built | 0/TBD | Not started | - |
| 2. Natural-Language Spanish Search + Auth | 0/TBD | Not started | - |
| 3. RAG Rules Oracle | 0/TBD | Not started | - |
| 4. Club Operations | 0/TBD | Not started | - |
