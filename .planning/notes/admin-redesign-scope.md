# Admin UI/UX Redesign — Scope

Scoping analysis produced 2026-09-16 by comparing sketches 059–065 against the shipped
LiveView admin. Written before the redesign phase existed, so it survives as direct input
to that phase's `/gsd-discuss-phase` and `/gsd-plan-phase` rather than being re-derived.

**Headline:** the shipped admin is the phase 01.8.1 daisyUI scaffold (last touched
2026-09-14). Sketches 059–065 ran 09-14 → 09-16 and redesigned that surface end to end.
**None** of the seven R7–R10 outcomes are present in shipped code, and two of them (the one
save bar, the one action system) have no shipped counterpart to even modify. This is a
rebuild of all nine admin LiveViews, not a polish pass.

## The load-bearing finding: SC-3 was never correctly met

`lib/pukllay_club/catalog/game.ex:84` documents *"at most one shelf per game, no in-shelf
position"*, and `lib/pukllay_club/catalog/shelves.ex:170-177` (`games_on_shelf/1`) orders
**by name**.

Sketch 065 R8's premise — *the order of games on an estante IS their physical left-to-right
order* — has no column behind it. Zone, neighbours, the rail's tile order, the zone bar and
↑/↓ all sit on data that does not exist. The shipped Estantes screen renders catalogue order
and says nothing about it: exactly the bug R8 named *"five taps to a wrong answer."*

This is a correctness defect under SC-3, not a styling issue. It is justified even if every
visual decision in 065 were reversed, and it blocks four other slices.

## Per-area gap

| # | Area | What must change | Size |
|---|------|------------------|------|
| 1 | **In-shelf position (data)** | New `shelf_position` + migration + backfill; `games_on_shelf/1` reorders; move-within-shelf / append-at-far-right / reindex-on-remove in `shelves.ex`. Pure backend, no UI. | LARGE |
| 2 | **Admin shell (059/060)** | No bottom tab bar exists — `layouts.ex` has only `.pk-nav-admin` (:737) and a drawer Admin row (:879). Needs the 5-tab bar, drawer PANEL/SITIO/TU CUENTA, renames **Panel→Admin · Secciones→Web · Cuenta→Perfil**, no admin footer. | LARGE |
| 3 | **Estantes as ONE page** | `shelf_live/index.ex` still has the two-view switch (`parse_vista/1` :44-45, `?vista=lista`, the Ver lista/Ver estantes links :107-116) that R8 **retired**. Rebuild: progress → search-first → estante disclosure rows → `Sin ubicar`. Inline create form (:125-137) becomes a sheet. | LARGE |
| 4 | **Delete the Asignar screen** | `shelf_live/assign.ex` (329 L) + route `router.ex:113`. Rename modal → estante options sheet; progress line, search, place/move, undo toast re-home onto Estantes. | MEDIUM |
| 5 | **Estante expands into `.pk-rail`** | Reuse `components/carousel_row.ex` (388 L) — R9 pinned card 96 / gap 10 / fade 16 to `app.css`. Roving tabindex (1 tab stop), per-tile `"X, caja N de M"`, marked-cover ring on `--stroke`. **Depends on #1.** | LARGE |
| 6 | **Three-target zone bar** | `Izquierda · Medio · Derecha`, chip-row markup + `aria-current`, real 44px boxes, no tick glyph, full phrase as accessible name. **Depends on #1, #5.** | MEDIUM |
| 7 | **Zone word placement** | Dropped inside an expanded estante (0 words), kept as `zona · estante` on search rows. Nothing shipped emits a zone word at all. | SMALL |
| 8 | **Position indicator / `ZONE_NAV_MIN = 30`** | Bar does not render under ~30 boxes; rail carries 0 indicators, 0 ordinals. A rule + a guard. | SMALL |
| 9 | **One save bar** | There is **no** save bar. `section_live/edit.ex:200` has a bare `Guardar cambios` inside the form; `game_live/form.ex:303-320` has a `flex flex-wrap gap-2` Publicar/Guardar row plus two loose Retirar/Restaurar divs. Needs the shared `.ebar.inline` (status line + dot, Principal last, one-word **Guardar**). | MEDIUM |
| 10 | **One action system (064 R10)** | Shipped uses `btn btn-primary` (filled), `btn-outline`, `btn-ghost btn-square`, `btn-error`. Zero of A1/A2/A3/A4. Every `modal-action` button footer — `assign.ex:286`, `staff_live/index.ex:190`, `game_live/form.ex:358` — is what R7b outlawed. Touches all 9 files + `core_components.ex`. | LARGE |
| 11 | **Sheets** | The admin has no bottom sheets — three daisyUI `modal`s instead. 062-B routes every secondary/destructive action into one; 065 R6 fixes one shell (48px rows, full-bleed, `tick` first / `chevL` Cancelar last). | MEDIUM |
| 12 | **Juegos list rows (R3/R4/R5)** | `game_live/index.ex:357-390` is a `<.table>` with Nombre\|Estado and a badge on **all** rows. Needs: no table, one row anatomy, Publicado unmarked, Borrador accent pill, Retirado muted pill + muted row, **año** in the meta, `.pk-pill` instead of `badge badge-warning`, "Juegos del club" label, R4 search anatomy. | MEDIUM |
| 13 | **Ordenar mode** | Always-visible `↑/↓ btn-ghost btn-square` on every row in `shelf_live/index.ex:153-170`, `section_live/index.ex:99-119`, `section_live/edit.ex:244-263`. 062-B wants an **Ordenar→Listo mode**; R7 #4 puts the toggle at `.lhead` level so all three pages move together. | MEDIUM |
| 14 | **Sección Ajustes panel (R7 #1)** | `section_live/edit.ex:178-201` is a flat `space-y-2` form. Needs one `.ppanel` at 12/12/12. Copy flips: shipped **"Ocultar en la home"** vs sketches' **"Mostrar en el inicio"**. | SMALL |
| 15 | **Dashboard boxes (060-B / R2 W2)** | `dashboard_live.ex:26-77`: name in `font-display text-xl` + a `badge-warning`, **no number at all**, loose "Salir" link on the page. Needs 2-col boxes, muted icon, name 13px/600, number 22px/400, Estantes meter, accent pending pill, Salir into the drawer/account sheet. | MEDIUM |
| 16 | **Type + weight pass (R2, R11)** | Everything uses `font-display text-xl/2xl` for page titles; sketches say **22px/600 Inter** (Bebas only for the editor's game name). Plus W1–W4. | MEDIUM |
| 17 | **Keyboard / touch (K1–K4)** | 16px fields on coarse pointers only, tab bar leaves on focus, sheet sits on the keyboard. Downstream of #2 and #11. | SMALL |
| 18 | **Copias, niveles vocabulary** | `game_live/form.ex:272` `label="Unidades"` → **Copias** (schema field stays `units`); `band_audit_live.ex:106-108` has two bare `Corregir`/`Mantener` buttons where R1 #10 wants the level's *meaning* on a "Pasar a …" row. | SMALL |

## Files touched — all nine admin LiveViews

| File | L | Fate |
|------|---|------|
| `live/admin/dashboard_live.ex` | 88 | rewritten (#15) |
| `live/admin/band_audit_live.ex` | 118 | rewritten (#10, #18) |
| `live/admin/section_live/index.ex` | 123 | rewritten (#10, #13) |
| `live/admin/shelf_live/index.ex` | 199 | **rebuilt from scratch** (#3, #5, #6) |
| `live/admin/staff_live/index.ex` | 206 | rewritten (#10, #11) |
| `live/admin/section_live/edit.ex` | 274 | rewritten (#9, #13, #14) |
| `live/admin/shelf_live/assign.ex` | 329 | **DELETED** |
| `live/admin/game_live/form.ex` | 367 | rewritten (#9, #10, #18) |
| `live/admin/game_live/index.ex` | 398 | rewritten (#12) |

**One whole screen is deleted:** `/admin/estantes/:id/asignar` — `shelf_live/assign.ex` plus
its route `router.ex:113`. The `?vista=lista` route variant also goes
(`shelf_live/index.ex:44-45`, :82) — a second retired route.

Outside `live/admin/`:
- `components/layouts.ex` (1368 L) — `app/1` :194, `bottom_collapse` :123, `.pk-nav-admin`
  :737, drawer Admin row :879. Gains the admin shell.
- `components/core_components.ex` (534 L) — `button/1`, `input/1`, `table/1`, `header/1`,
  `list/1`; the action system lands partly here.
- `components/carousel_row.ex` (388 L) — reused as the estante rail.
- `assets/css/app.css` — the pill block at :1165-1200 (the `badge badge-warning`
  "sixth pill family" problem), plus new admin blocks.
- `catalog/game.ex`, `catalog/shelf.ex`, `catalog/shelves.ex` — slice #1.

No dedicated admin component module exists today; the sketches imply creating one.

## Slicing — ~18–22, and it wants more rather than fewer

The 18 rows above are already near-atomic. Ordering constraints: **#1 blocks #5, #6, #7, #8**;
**#2 blocks #17**. Several rows split further:

- **#1** → (a) migration + backfill, (b) context read path (`games_on_shelf` order),
  (c) context write path (place at far right / move / reindex on remove) — 3 slices.
- **#3** → (a) retire the view switch, search becomes the first control, (b) estantes as
  disclosure rows + `Sin ubicar`, (c) Nuevo estante → sheet — 3 slices.
- **#10** → split by anatomy (A1 outlined, A2 text, A3 icon, A4 sheet row), which is also how
  `audit-admin.js`'s A1–A9 are written, so each lands with its own check — 2–4 slices.
- **#5** → (a) rail renders the shelf, (b) roving tabindex + AT names, (c) the marked tile's
  panel (remove / ← →) — 3 slices.

**Two slices carry no UI and can go first, independently:** #1a/#1b/#1c, and #18's
"Unidades→Copias" label change.

## `01.8.1-UI-SPEC.md` is stale — do not plan against it as-is

`status: approved`, dated 2026-09-13 — **one day before sketch 059 started.** Superseded or
directly contradicted:

| UI-SPEC location | Says | Superseded by |
|---|---|---|
| Component Inventory → `button/1` (L57) | `variant="primary"` = **filled**, the ONE action per screen | 064 **S3 Contorno**: 1px strokes, no filled button in the admin; 4 roles; R10 adds 4 anatomies. R10 rule 1 is "at most one **outlined** action per block"; rule 2 "a page-level action is never Principal and never outlined". **CONTRADICTS** |
| → `table/1` (L59) | "Use for Juegos list, Staff list, Band-audit list" | 061: *no table — one row anatomy (40px thumb · wrapping 15px name · 12px status line · chevron)*. **CONTRADICTS** for Juegos |
| → Status badge (L62) | `badge-warning` draft / **`badge-success` published** / `badge-neutral` retired | 065 R3: **Publicado is unmarked**; Borrador = accent pill; Retirado = muted outline pill + muted row. Cites `app.css:1165-1200` as a sixth pill family outside the system. **CONTRADICTS twice** |
| → `header/1` (L61) | standard header every screen, `<h1>` in `font-display text-2xl` | 065 D1/D2/D3: back row at one height, page head 24px above body, titles **22px/600 Inter**. 064 R10 #7 makes the back control **its own role**. **SUPERSEDED** |
| → Undo toast (L63) | "a single `variant="secondary"` Deshacer button" | A2 text anatomy; toast itself survives. **PARTIALLY STALE** |
| Typography (L94-102) | "Admin caps at 3 sizes"; Heading = **24px `font-display`**; Display "not used" | 061 scale is 22/17/11caps/15/14/12, titles are Inter; 063 keeps **30px Bebas** for the editor's game name deliberately. **CONTRADICTS both** |
| Color → Accent (L118) | "**Exactly one filled `variant="primary"` button per admin screen**" | 064: outline-only. **CONTRADICTS** |
| Copywriting → "Guardar cambios" (L144) | Primary CTA on edit forms | 065 R7 #3: the editor's one-word **Guardar**. **CONTRADICTS** |
| → "Crear estante" (L145) | Primary CTA (Estantes) | R8 #8: **"Nuevo estante"**, a sheet; R10 demotes it to **Terciaria text**. **CONTRADICTS** |
| → "{N}/400 ubicados" (L164) | Walk-the-shelf progress | That *screen* is retired (R8); the line moves to Estantes. **SUBJECT RETIRED** |
| → "Quitar" (D-25) (L165) | per-item, non-destructive, on the row | 062-B: secondary/destructive open a sheet; R10 rule 3: a row-level action is never outlined (shipped `section_live/edit.ex:264` is `variant="secondary"` on every row). **CONTRADICTS** |
| → "Unidades" | — | 065 R6 #4: **Copias** (field stays `units`). **SUPERSEDED** |
| Visual Hierarchy → dashboard (L176-180) | single column; order Juegos→Estantes→**Secciones**→Revisar niveles→Staff; `badge-warning` count | 060-B: **2-column** (3 desktop) with icon + number + meter + one note; **Secciones→Web**; Revisar niveles and Staff move into the **drawer** on phone; accent pill. **CONTRADICTS** |
| UI Considerations → E4 (L219-222, all 4 rows) | the Walk-the-shelf assign surface | **Surface retired.** Every E4 truth needs re-pointing at the expanded estante. **WHOLLY STALE** |
| → E5 zero-one-many (L224) | "grouped by shelf in walking order plus Sin ubicar; **an empty group still shows its shelf name**" | R8 #10: a query answers in a **flat `Resultados` list with 0 headings**; every hit names its estante **on the row**. Same job, different carrier. **CONTRADICTS as written** |
| → E1 populated (L212) | "~400 rows via **`Cargar más`**" | R7b: **`Mostrar más · N de M`**; `.lcap` deleted. Shipped `game_live/index.ex:391` still says "Cargar más". **CONTRADICTS** |

**Not stale:** the voseo copywriting rule, BGG-failure and edition-prompt copy, destructive-
confirmation copy, the undo-toast *shape* `"Movido desde {shelf} · Deshacer"`, 40-char name
caps, and E7 (public home sections) — the sketches never touched the public surface. The 44px
floor (L83-85) is reinforced by R10 rule 6, with one refinement: measure the **hit box**, not
the drawn box (a 32px chip with a bleeding `::after` is legal).

## Other known inputs

- **`sketch-findings-pukllay_club` skill is stale.** Last updated 2026-09-13; **zero**
  mentions of sketches 059–065 across its 14 reference files. CLAUDE.md says it is
  *"Auto-loaded during UI implementation"* — left as-is it will feed the replaced design back
  into the redesign. Refresh it alongside the UI-SPEC as a first slice.
- **5 open UI gaps from UAT** — `G-01.8.1-1a` (footer), `1b` (**drawer does not open**, major),
  `1c`/`1d` (affordance, session state), `2a` (horizontal scroll), `2b`/`2c` (form, filters),
  `3` (long-name overflow), `5` (featured hero not distinct), all subsumed under
  `G-01.8.1-admin-ux`. See `01.8.1-UAT.md`.
- **`625f566`** (`docs(260916-kvq)`, CLAUDE.md) is queued to land in this phase's PR rather
  than its own sync PR.
- **`G-01.8.1-14-enrichment-stuck`** — production add-by-BGG is broken. By the user's decision
  `/gsd-debug` runs **after** this phase deploys, so production takes one deploy not two.
  Note its bug (2) (worker does not rescue raised exceptions) is independent of every UI
  decision here and can be lifted out if this phase runs long.

## Deliberately still open

- **Focus mode for an expanded estante** (centre it, recede the rest). A modal was advised
  against — it is a drill-down with extra steps, and a near-full-height modal with its own
  scrollers and sub-sheets is the sheet-on-sheet anti-pattern. Alternatives: single-open
  accordion with a quiet page, or a real pushed screen. Better judged in live LiveView than
  in a sketch.
- **A `--page=` / `--only=` subset mode for the sketch verify harness.** Worth it only if
  sketching continues; a wrong-way investment heading into implementation.
