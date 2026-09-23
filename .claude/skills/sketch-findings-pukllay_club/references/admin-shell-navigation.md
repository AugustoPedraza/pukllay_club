# Admin Shell & Navigation

The staff-side frame and everything that sits inside it: header, drawer, tab bar, session/logout, the
Admin home dashboard, and list-row/sheet/label/rhythm rules. Mobile-first — the phone design is the
design; desktop is a documented deviation from it.

**Read these supersessions before using anything below.**
- **060 supersedes 059** on the tab names and on counts. 059's own file still renders `Panel ·
  Secciones · Cuenta` and a plain (non-pending) count; that was left alone on purpose so 059's round
  record stays honest. The current names are **Admin · Juegos · Web · Estantes · Perfil**.
- **065 R8/R9/R10's Estantes page is DEAD.** Sketch 069 (`estantes-ubicar`, DECIDIDO 2026-09-22)
  restarted that UI from scratch and explicitly *"Reemplaza todo lo que 065 R8 y 066 dibujaron para
  estantes"* — the one Estantes page, the `Recorrido|Contenido` chips, the zone bar, the rail, the
  `Agregar juegos` mode and the per-estante Ordenar are all replaced. What survives from R8 is only
  the premises: search answers *where is it*, the order of the games **is** the order of the shelf,
  neighbours are one tap away, and `/admin/estantes/:id/asignar` stays retired. Everything else in
  this file (shell, rows, sheets, labels, rhythm, save bar) is unaffected and current.
- **061 is superseded by 071** for the Juegos page; its rules are quoted here only as things not to
  re-implement (see What to Avoid).

**Verification status:** every finding below was measured in headless Chrome (375/420px phone frame,
1440px desktop, light + dark). **None of it is confirmed on a real device.** The mobile-keyboard
behaviour in particular is driven against a *simulated* keyboard panel, not iOS/Android.

## Design Decisions

**One header, identical in all six states.** Phone + desktop × signed out / public-signed-in / admin
all render the same markup: hamburger + isologo + "Pukllay Club" wordmark. Removed during 059's final
round: the `PANEL` mode pill, the desktop header avatar, the phone wordmark-hiding, the green
signed-in dot and the purple attention dot. Verified by comparing header markup across all six states
(one unique signature). **The signed-in signal never lives in the header** — it is the green ring on
the Perfil tab's avatar.

**No footer on admin** (decided at 059's intake, closing UAT gap G-01.8.1-1a).

**Phone: a bottom tab bar. Desktop: the same sections as a sticky row under the header.**
Tabs are `Admin · Juegos · Web · Estantes · Perfil`. Header and tab bar persist; only `<main>` swaps
(100ms fade, scroll reset) — this maps to one admin `live_session` layout with `navigate` between
LiveViews. Re-tapping the active tab pops to that tab's root, or smooth-scrolls to top if already
there. Overflow sections (`Revisar niveles`, `Staff`) are **not** tabs; they live in the drawer only,
and on those pages no tab is lit — the drawer row carries the active state.

Two implementation obligations the sketch could not mock: **hide the tab bar while an input has
focus** (soft keyboard), and give `<main>` real bottom padding (~72px + `env(safe-area-inset-bottom)`)
so the last row is never covered.

**The drawer never repeats the tab bar.** Four contexts, four contents:

| context | drawer |
|---|---|
| phone, admin | `ADMIN` = Revisar niveles + Staff only (what the tab bar lacks) → `SITIO` |
| desktop, admin | no `ADMIN` group at all — the tab row already has every section |
| public page, signed in | `ADMIN` = one row, "Ir a Admin" (there is no tab bar there) → `SITIO` |
| signed out | `SITIO` only |

The theme switcher is **pinned to the drawer's bottom edge** in every state (`.drawer-body` scrolls,
`.drawer-bottom` is fixed) — measured 16px from the drawer bottom in all six states. It was found
below the fold at −34px when the signed-in drawer hit 11 rows. A control must not move between states.

**One row anatomy for the drawer and every sheet:** `[28px slot: icon or avatar] [label (+ optional
secondary line)] [count] [chevron]`, 48px minimum, full-bleed hover tint. The **only** permitted
variation is a `danger` tone (text + icon colour). No cards, borders, filled/soft buttons or centred
layouts inside a sheet. Group headers use `.group-label` (11px uppercase muted) and that class is
reserved for drawer/sheet groups — never for a page body.

**Session and logout.** Account lives only in the Perfil tab's sheet.
- Perfil tab = avatar with a **green ring** (`box-shadow: 0 0 0 2px bg, 0 0 0 3.5px --color-success`).
- Sheet: `TU PERFIL` → static identity row (avatar + email + "Sesión iniciada · Dueña") → `Ver el
  sitio público ›` → `Cerrar sesión ›` (danger tone, chevron because it leads to a step).
- **Confirm is a second step inside the same sheet**, not a second sheet: content slides/fades
  horizontally and the sheet height animates. Step content is `CERRAR SESIÓN` → one muted line naming
  the account → rows `Sí, cerrar sesión` (danger, no chevron) and `‹ Cancelar` (no chevron).
- Focus lands on `Cancelar`; `Cancelar`/`Esc` step **back** to the account step (focus returns to the
  Cerrar sesión row); backdrop or swipe-down closes the whole sheet and resets it. Hidden step is
  `inert`; `prefers-reduced-motion` kills the step animation. Reset must run **synchronously on open
  while the sheet is off-screen** — a delayed reset showed a stale confirm step on reopen.
- Loading replaces the row's icon with a spinner + "Cerrando sesión…" and dims the other row; then
  the Ingresar page with a "Cerraste sesión" toast. Login title is "Ingresar a Admin".
- **Accepted consequence:** on a public page while signed in there is no logout in the drawer — you
  go drawer → `Ir a Admin` → Perfil. The standalone drawer confirm sheet was removed as unused.

**Back row only on genuine drill-downs.** `Web → Destacados` shows `‹ Web`; a future `Juegos → editar`
shows `‹ Juegos`. Pages reached from a tab or a drawer row are *siblings* of Admin, not children, so
they get no back row and their titles line up at the same height across tabs. This is `page-shell.md`'s
crumb rule applied to admin. The back control is **its own role** — page chrome, not a Terciaria
action: 4/10px padding, −10px pull, leading chevron, identical on every drill-down.

**Vocabulary (060's renames — apply everywhere):** `Panel` → **Admin** (home tab, page title, drawer
group `ADMIN`, login title), `Cuenta` → **Perfil** (tab; sheet group `TU PERFIL`), `Secciones` →
**Web** with a `globe-alt` icon, described as *"Elegí qué filas se ven en la web"*, back row `‹ Web`.
Routes and modules can keep `secciones`/`SectionLive` internally — this is a label change only.
Known watch-outs recorded at the time: the drawer reads `ADMIN` (group) then `Admin` (row), and "Web"
(edit the public rows) sits next to `SITIO` (visit the public site).

**The Admin home is a dashboard of boxes** — this deliberately overrides 059's "no cards" rule for
this page only, because the tab bar and drawer already list every section and a third list earned
nothing. Grid is `repeat(2, minmax(0, 1fr))` with a 10px gap on phone (measured 167px boxes at 375px)
and 3 columns / 16px on desktop. `1fr` was a real bug: long content widened a track (157 vs 176px), so
`minmax(0, 1fr)` is load-bearing.

Box anatomy: `[icon · name] → number → (meter) → one note`. **No chevron** — so the tap affordance has
to come from the box shape plus hover tint and `active: scale(.985)`; implement both. Outline only
(`--color-bg` fill, 1px border, `--radius-lg`); the first pass used a `--color-surface` fill and read
heavy.

| box | number | note (pending pill) | all clear |
|---|---|---|---|
| Juegos | 412 | **3 borradores** | Todos publicados |
| Web | 5 | filas en el inicio | — |
| Estantes | 80% + meter | **84 sin ubicar** | 100% · Todos ubicados |
| Revisar niveles | 7 | **no coinciden con BGG** | 0 · Todo coincide con BGG |
| Staff (owner only) | 3 | 1 invitación pendiente | Sin invitaciones pendientes |

The note must **add** information, never restate the name — "Juegos · 412 juegos" was the bug that
killed the unit line. Web keeps "filas en el inicio" because "Web · 5" means nothing alone.

**Weight inside a box (065 R2).** The Admin home measured **94% bold** — 15 of its 16 text runs — and
the 22px/600 number was typographically identical to the page's own 22px/600 title, so nothing led.
The rule that fixed it, now general:

> **600 marks a label, an action, or a state that needs noticing. Content is 400.**

So the box **name is the box's label** → 13px/600 (down from 16px, which also stops "Revisar niveles"
wrapping), and the **number is content** → 22px/400 tabular. One bold run per box — its name — plus
the pending pill. Related: `.err-t` ("Error al traer datos de BGG", the row with a Reintentar beside
it) was 400 while `.st-draft` was 600, so an error read quieter than a status. Both 600 now.

**One counter source.** Every dashboard box, drawer count and tab badge must read one derived
`DATA()`/`cnt()` pair — not per-page literals. Composed, four independent counter sets produced real
lies: place a game and the Estantes badge stayed at 84; resolve all seven level mismatches and the
page said "Todo coincide con BGG" while the badge and drawer still said 7. Also: one ludoteca, one
size (408 vs 412 across pages), and the Staff note is derived and pluralised, not hard-coded.

**A count bubble always means pending work** — the same accent pill in the dashboard box, the drawer
count and the tab badge. Nothing shows a neutral count in that shape.

**List rows (062 winner B: "Modo ordenar + hojas").**
- A row carries **at most one trailing affordance**: a chevron `›` (the row opens something) or `⋯`
  (the row has options in a sheet). Tapping anywhere on the row triggers it. **No inline icon or text
  buttons on list rows** — which also keeps every row under the `ux-patterns` D22 action cap.
- **Reorder is a mode, not per-row arrows.** An `Ordenar` control in the list header (`.lhead`)
  switches that list to ↑/↓; `Listo` exits. Rows cannot be opened while ordering and each tap saves
  immediately. A pinned row ("Siempre primera" on the featured Web row) has no arrows. The control is
  **outlined in both states** — Secundaria to enter, Principal to leave — because a mode toggle that
  changes what the whole list below it does is not a Terciaria text link.
- **Secondary and destructive row actions open a bottom sheet** (a centred dialog on desktop) using
  the 059 row anatomy and a group label.
- **Undo instead of confirm** for reversible changes (place a game, remove a member, Corregir/Mantener):
  a snackbar with `Deshacer`. Staff removal keeps a confirm step because it signs someone out.
- Row content: 40px slot (thumb / icon tile / avatar) · 15px name that **wraps** (`overflow-wrap:
  anywhere`, no ellipsis, no clamp) · 12px meta line. Meta separators stay attached to the item after
  them so a wrap never leaves a dangling `·`.

**Status marks the exception (065 R3).** The fixture is 3 borradores / 407 publicados / 2 retirados,
so a "Publicado" label appeared on **98.8% of rows** — the least informative word on the page, 407
times.

| status | row |
|---|---|
| Publicado | no marker at all — just the game and its year |
| Borrador | the same accent pill used for pending work everywhere else (11.3:1 light / 10.5 dark) |
| Retirado | muted outline pill **and** a muted row (name + desaturated thumb); 6.2:1 / 6.9 |

Never colour alone (WCAG 1.4.1) — the amber draft dot this replaced measured **2.78:1**, under the
3:1 non-text floor (1.4.11). And grey means *disabled* on iOS and Android, which a draft — the most
actionable row on the page — is not. The "¿Es otra edición?" banner is the one place every status
shows, Publicado included, because there you compare two named games rather than scan a list.

**One field anatomy (065 R4).** Search and form fields are the same species: 44px, 8px radius, 1px
`--stroke`, page background, 14px text. The search field's identity is carried by its leading
magnifier and its clear button, not by a different shape. A filled pill search (`radius-full`,
`--color-surface`, transparent border) sitting 24px under an outlined 8px field read as two species —
and `--color-surface` is what a soft content **block** is made of in this admin, so a filled input
read as a container. 063's in-place editors (title, description, numbers) are the documented exemption.

**One list label (065 R5).** Every block that holds a list names itself — with a visible section label
or with a disclosure row that names it ("En este estante · 68 juegos ⌄" satisfies the rule on its own;
a label above it would only repeat it). The Juegos list is **"Juegos del club"** — reuse the official
word rather than invent a third name (`card-interaction.md`: don't create two parallel vocabularies);
"del club" earns its keep against the BGG-sourced `Agregar juego` block right above it. A *result*
count belongs below the search and chips that change it, not in the section head.

**Two label tiers, one size step apart (065 #4).** Three answers collapsed into two:
- **section label** — 13px/600, full text colour, sentence case, names a block on the page;
- **field label** — 12px/600, muted, names one input inside a block;
- `.group-label` (11px uppercase) keeps exactly 059's job: the header of a row group in a **drawer or
  sheet**. At 13px/600 both, only colour separated a section from a field and "Ajustes / Nombre /
  Subtítulo" stacked as three near-identical lines.

**One page rhythm (065 #6–#9).** The page head sits **24px** above the first block on every page —
the same distance blocks sit from each other. It had been 16px on list pages, 12px on one, 24px in the
editor, and 0 on the Admin home. A page title aligns to the **top** of its row whether it sits alone,
shares the row with a control, or is an editable field — otherwise it jumped up to 7px between
drill-downs. Every drill-down's back row starts at 4px.

**One save bar (065 R7 #3).** There is exactly one: `.ebar.inline` — a soft `--color-surface` block,
12px radius, 12/16px padding, 12px internal gap, a 13px/600 status line with its dot on the left and
`.eactions` (Principal last) on the right, with a one-word **Guardar**. A page with no lifecycle uses
the status line for the save state itself: "Cambios sin guardar" with the accent dot, "Todo guardado"
with the published one. The loose `.saverow` (a 12px accent note plus a button floating on the page
background) is gone. Two soft blocks in one section keep a 12px seam.

**One settings panel (065 R7 #1).** A group of setting rows in a page body is the editor's soft box
(`.sgroup.apanel`), never hairlines — and the form's own fields join it as field rows, so the section
is one surface on one rhythm (12px between every child, 12px above the first and below the last). It
was one labelled block with two surface treatments and gaps of 8/6/12/6/16px down its middle. Sheets
keep rows, not boxes.

**One sheet rhythm (065 R6 #8, R7b #7).** Every sheet shares one shell, measured: padding
`8px 16px 16px`, grab `4px auto 12px`, an 11px caps group label 4px above its first block, **48px
rows**, full-bleed. **A sheet has no buttons at all** — its actions are rows in `.dlinks`: the
committing row **first** with a `tick` glyph (danger tone when destructive), `Cancelar` **last** with
`chevL`. The committing row *is* the form's `type="submit"`, so Enter still commits and an inline
`.ferr` reports without closing the sheet. Chevron rule: **a row that leads somewhere carries one; a
row that acts in place does not.**

**The mobile keyboard (065, four questions 059/061 had flagged and nobody had tested).**
- **iOS focus-zoom:** fields grow to **16px on coarse pointers only**. Do **not** use
  `maximum-scale=1` — it takes pinch-zoom away from everyone, which is a real accessibility loss on a
  14px UI. The viewport meta stays `width=device-width, initial-scale=1`.
- The **tab bar leaves** while a field has focus and slides back on blur. Desktop: nothing moves.
- A **bottom sheet sits on top of the keyboard**, not under it; its max height shrinks to match and it
  is never pushed off the top of the screen.
- Landing focus goes on the page's heading, and is **skipped when that heading is a field**, so
  arriving on a page never opens the keyboard.

**Font weights: the app self-hosts Inter 400 and 600 only.** A declared 500 renders as 400 and 700 as
600, so any sketch balance built on 500/700 was never real. `b, strong, h1–h4, th` must be pinned to
600 (their browser default is 700). Watch for **state pairs that collapse**: tab labels were 600/700,
both became 600, and the active state vanished — inactive tab labels are now **400** and the active
one 600. Drawer rows, chips and the segmented control keep 400 → 600.

**Motion/animation asymmetry, recorded as a build trap:** opening states driven by
`requestAnimationFrame` never fire in a backgrounded or automated tab. Force a reflow
(`void el.offsetWidth`) before adding `.open`. The shipped drawer bug G-01.8.1-1b is likely this
class of wiring — check the real hook.

## CSS Patterns

```css
/* ---------- drawer: right-slide, theme pinned to the bottom edge ---------- */
.drawer {
  position: absolute; top: 0; bottom: 0; right: 0; width: 84%; max-width: 360px; z-index: 50;
  background: var(--color-bg); display: flex; flex-direction: column;
  padding: 8px 0 max(16px, env(safe-area-inset-bottom)); overflow: hidden; box-shadow: var(--shadow-lg);
  transform: translateX(100%); transition: transform var(--duration-slow) var(--ease-out-soft);
}
.drawer.open { transform: translateX(0); }
.drawer-top    { display: flex; align-items: center; justify-content: space-between; min-height: 48px; margin-bottom: 4px; padding: 0 8px 0 16px; flex-shrink: 0; }
.drawer-body   { flex: 1; min-height: 0; overflow-y: auto; padding: 0 16px 8px; }  /* the list scrolls */
.drawer-bottom { flex-shrink: 0; padding: 0 16px; }                                /* theme never moves */
.backdrop { position: absolute; inset: 0; z-index: 40; background: color-mix(in srgb, var(--color-text) 38%, transparent);
  opacity: 0; pointer-events: none; transition: opacity var(--duration-base) var(--ease-standard); }
.backdrop.open { opacity: 1; pointer-events: auto; }

/* ---------- ONE row anatomy: drawer + every sheet ---------- */
.group-label { font-size: 11px; font-weight: 600; letter-spacing: .08em; text-transform: uppercase;
  color: var(--color-text-muted); margin: 16px 0 4px; }         /* drawer/sheet groups ONLY */
.dlinks { display: flex; flex-direction: column; margin: 0 -16px; }  /* full-bleed */
.dlink {
  display: flex; align-items: center; gap: 12px; min-height: 48px; padding: 0 16px; width: 100%;
  border: 0; background: none; text-align: left; font-size: var(--text-base); font-weight: 400;
  cursor: pointer; border-left: 3px solid transparent; color: var(--color-text);
  transition: background var(--duration-fast) var(--ease-standard);
}
.dlink:hover  { background: var(--color-surface); }
.dlink:active { background: var(--color-surface-2); }
.dlink .slot  { width: 28px; height: 28px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; }
.dlink .ico   { width: 22px; height: 22px; color: var(--color-text-muted); }
.dlink .lbl   { flex: 1; min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.dlink .lbl .sub { display: block; font-size: 12px; font-weight: 400; color: var(--color-text-muted); margin-top: 1px; }
.dlink .chev  { width: 16px; height: 16px; color: var(--color-text-muted); flex-shrink: 0; }
.dlink .count { font-size: 12px; font-weight: 600; color: var(--color-accent-text);
  background: var(--color-accent-bg); border-radius: var(--radius-full); padding: 2px 8px; }
.dlink.on { background: var(--color-surface); border-left-color: var(--color-primary); font-weight: 600; }
.dlink.static { cursor: default; }  /* the identity row */
.dlink.static:hover, .dlink.static:active { background: none; }
.dlink.danger, .dlink.danger .ico { color: var(--color-danger); }
:root[data-theme="dark"] .dlink.danger,
:root[data-theme="dark"] .dlink.danger .ico { color: #F2A3B8; }   /* danger lightened for the dark ground */

/* ---------- bottom sheet: one shell, two-step in place ---------- */
.sheet {
  position: absolute; left: 0; right: 0; bottom: 0; z-index: 60; background: var(--color-bg);
  border-radius: 18px 18px 0 0;
  padding: 8px 16px max(16px, calc(env(safe-area-inset-bottom) + 8px));
  box-shadow: var(--shadow-lg); transform: translateY(105%);
  transition: transform var(--duration-slow) var(--ease-out-soft);
  max-height: 85%; overflow-y: auto; overflow-x: hidden;  /* overflow-x kills the step's h-scrollbar */
}
.sheet.open { transform: translateY(0); }
.sheet.dragging { transition: none; }                      /* swipe-to-dismiss */
.sheet .group-label { margin-top: 4px; }
.grab { width: 36px; height: 4px; border-radius: 4px; background: var(--color-border); margin: 4px auto 12px; }
/* desktop: the same sheet becomes an anchored panel / centred dialog */
.desk .sheet { left: auto; right: 32px; bottom: auto; top: 112px; width: 340px; border-radius: var(--radius-lg);
  opacity: 0; pointer-events: none; transform: translateY(-8px);
  transition: opacity var(--duration-base), transform var(--duration-base); }
.desk .sheet.open   { opacity: 1; pointer-events: auto; transform: none; }
.desk .sheet.center { left: 50%; right: auto; top: 30%; transform: translate(-50%, -8px); }
.desk .grab { display: none; }
/* two steps, one sheet: height animates, content slides */
.steps { position: relative; transition: height var(--duration-slow) var(--ease-out-soft); }
.steps.animating { overflow: hidden; }
.step { transition: opacity var(--duration-base) var(--ease-standard), transform var(--duration-slow) var(--ease-out-soft); }
.step[aria-hidden="true"] { position: absolute; top: 0; left: 0; right: 0; opacity: 0; pointer-events: none; }
.step-account[aria-hidden="true"] { transform: translateX(-24px); }
.step-confirm[aria-hidden="true"] { transform: translateX(24px); }
@media (prefers-reduced-motion: reduce) { .step, .steps, .sheet, .drawer, #main { transition: none; } }
/* one sheet rhythm: a sheet's switch rows match its .dlink rows */
.sheet .srow { min-height: 48px; padding-block: 4px; }

/* ---------- tab bar (admin only) ---------- */
.tabs { position: absolute; left: 0; right: 0; bottom: 0; z-index: 30; background: var(--color-bg);
  border-top: 1px solid var(--color-border); display: flex;
  padding: 4px 4px max(10px, env(safe-area-inset-bottom)); }
.tabs button { flex: 1; min-width: 0; min-height: 52px; border: 0; background: none; cursor: pointer;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px;
  font-size: 11px; font-weight: 400; color: var(--color-text-muted); border-radius: var(--radius-md);
  -webkit-tap-highlight-color: transparent; }
.tabs button svg { width: 24px; height: 24px; }
.tabs .tab-ico { position: relative; width: 56px; height: 30px; display: flex; align-items: center;
  justify-content: center; border-radius: 15px; transition: background var(--duration-base) var(--ease-out-soft); }
.tabs button.on { color: var(--color-primary); }
.tabs button.on .tab-ico { background: var(--color-accent-bg); }
.tabs button.on .tab-lbl { font-weight: 600; }            /* inactive stays 400 — the pair must not collapse */
/* the light accent-bg pill is near-invisible on the dark ground */
:root[data-theme="dark"] .tabs button.on { color: var(--color-accent-text); }
:root[data-theme="dark"] .tabs button.on .tab-ico { background: color-mix(in srgb, var(--color-accent-text) 22%, transparent); }
.tabs .badge { position: absolute; top: 0; left: 30px; min-width: 16px; height: 16px; border-radius: 8px;
  background: var(--color-secondary); color: #fff; font-size: 10px; display: flex; align-items: center;
  justify-content: center; padding: 0 4px; }
/* desktop: same sections, sticky row under the header */
.desk .tabs { position: sticky; top: 57px; bottom: auto; border-top: 0;
  border-bottom: 1px solid var(--color-border); justify-content: safe center; gap: 8px;
  padding: 0 16px; overflow-x: auto; }
.desk .tabs button { flex: 0 0 auto; flex-direction: row; min-height: 44px; padding: 0 14px;
  font-size: 13px; gap: 8px; border-radius: var(--radius-full); }
.desk .tabs button.on { background: var(--color-accent-bg); }
.desk .tabs .badge { position: static; margin-left: 6px; }

/* ---------- page chrome: back control + title ---------- */
.back { display: inline-flex; align-items: center; gap: 2px; min-height: 44px;
  margin: -8px 0 -4px -10px; padding: 0 10px 0 4px;     /* its own pull — NOT the A2 −12px */
  color: var(--color-text-muted); font-size: var(--text-sm); font-weight: 600;
  border: 0; background: none; cursor: pointer; border-radius: var(--radius-md); }
.back svg { width: 18px; height: 18px; }
.ptitle { font-family: var(--font-sans); font-size: 1.375rem; font-weight: 600;
  letter-spacing: -.01em; line-height: 1.2; margin: 4px 0 0; }        /* 22px Inter, not Bebas */
main > .ptitle + div[style*="height"] { height: 24px !important; }     /* head → first block: 24px */
main .trow > .ptitle { align-self: flex-start; }                       /* one title height everywhere */

/* ---------- two label tiers ---------- */
main :is(.sec-label, .group-label) {           /* SECTION label — names a block on the page */
  font-size: 13px; font-weight: 600; letter-spacing: .01em; line-height: 1.3;
  text-transform: none; color: var(--color-text); margin: 0 0 8px; }
main :is(.flabel, .field label) {              /* FIELD label — one step down, muted */
  font-size: 12px; font-weight: 600; letter-spacing: .01em; line-height: 1.3;
  color: var(--color-text-muted); }
main .lhead :is(.sec-label, .group-label) { margin: 0; }

/* ---------- Admin home: dashboard boxes ---------- */
.dash { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; }
.desk .dash { grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; }
/* minmax(0, 1fr) is load-bearing: plain 1fr let long content widen a track (157 vs 176px) */
.box { display: flex; flex-direction: column; align-items: center; gap: 6px; width: 100%;
  text-align: center; cursor: pointer; color: var(--color-text);
  padding: 12px 14px 14px; border: 1px solid var(--color-border);
  border-radius: var(--radius-lg); background: var(--color-bg);   /* outline only — a fill read heavy */
  -webkit-tap-highlight-color: transparent;
  transition: border-color var(--duration-fast) var(--ease-standard),
              background var(--duration-fast) var(--ease-standard), transform var(--duration-fast); }
.box:hover  { background: var(--color-surface); border-color: color-mix(in srgb, var(--color-primary) 30%, var(--color-border)); }
.box:active { transform: scale(.985); background: var(--color-surface-2); }   /* no chevron → these carry the affordance */
.box-head { display: flex; align-items: center; justify-content: center; gap: 6px; max-width: 100%;
  min-height: 24px; font-size: 13px; font-weight: 600; letter-spacing: .01em; color: var(--color-text); }
.box-head .ico  { width: 16px; height: 16px; flex-shrink: 0; color: var(--color-text-muted); }
.box-head .name { min-width: 0; line-height: 1.3; }
.box-num  { font-size: 1.375rem; font-weight: 400; line-height: 1.2;   /* content → 400, not 600 */
  font-variant-numeric: tabular-nums; color: var(--color-text); }
.meter    { align-self: stretch; height: 4px; border-radius: 2px; background: var(--color-surface-2); overflow: hidden; }
.meter i  { display: block; height: 100%; background: var(--color-primary); border-radius: 2px; }
:root[data-theme="dark"] .meter i { background: var(--color-accent-text); }
.box-foot { font-size: 12px; color: var(--color-text-muted); min-height: 20px;
  display: flex; align-items: center; justify-content: center; }
.pend { font-size: 12px; font-weight: 600; color: var(--color-accent-text);
  background: var(--color-accent-bg); border-radius: var(--radius-full); padding: 2px 8px; white-space: nowrap; }

/* ---------- list rows ---------- */
.glist { display: flex; flex-direction: column; margin: 0 -16px; }
.grow { position: relative; display: flex; align-items: center; gap: 12px; width: 100%;
  min-height: 60px; padding: 8px 8px 8px 16px; border: 0; background: none; text-align: left;
  color: var(--color-text); cursor: pointer; -webkit-tap-highlight-color: transparent;
  transition: background var(--duration-fast) var(--ease-standard); }
.grow::before { content: ''; position: absolute; top: 0; left: 68px; right: 0; height: 1px;
  background: var(--color-border); }                    /* hairline inset past the 40px thumb */
.grow:first-child::before { display: none; }
button.grow:hover  { background: var(--color-surface); }
button.grow:active { background: var(--color-surface-2); }
.thumb { width: 40px; height: 40px; flex-shrink: 0; border-radius: 6px; }
.gname { display: block; font-size: 15px; line-height: 1.3; font-weight: 400;
  overflow-wrap: anywhere; }                            /* long names WRAP — never ellipsis/clamp */
.gsub  { display: flex; align-items: center; flex-wrap: wrap; gap: 0 5px; margin-top: 2px;
  font-size: 12px; color: var(--color-text-muted); line-height: 1.35; }
.grow .chev { width: 18px; height: 18px; color: var(--color-text-muted); flex-shrink: 0; }
/* status marks the EXCEPTION — Publicado renders nothing */
.st-pill { display: inline-flex; align-items: center; border-radius: var(--radius-full);
  border: 1px solid transparent; font-size: 11px; font-weight: 600; line-height: 1.45;
  padding: 1px 8px; white-space: nowrap; }
.st-pill.draft     { background: var(--color-accent-bg); color: var(--color-accent-text); }
.st-pill.published { background: var(--color-surface-2); color: var(--color-text); }  /* banner only */
.st-pill.retired   { border-color: var(--color-surface-2); color: var(--color-text-muted); }
.grow.is-retired .gname { color: var(--color-text-muted); }
.grow.is-retired .thumb { filter: saturate(.3); }
.err-t { color: var(--color-danger); font-weight: 600; }  /* an error is "a state that needs noticing" */

/* ---------- block head with a mode control ---------- */
.lhead { display: flex; align-items: center; justify-content: space-between; gap: 8px;
  min-height: 44px; margin-bottom: 4px; }
.lhead > :is(.obtn, .b-pri, .b-sec) { margin: 0; }   /* an outlined control NEVER pulls */
.lhead .gcount { font-size: 12px; color: var(--color-text-muted); font-variant-numeric: tabular-nums; }

/* ---------- the one save bar ---------- */
.ebar.inline { position: static; display: flex; flex-direction: column; align-items: stretch;
  min-height: 0; gap: 12px; padding: 12px 16px; border: 0; box-shadow: none;
  background: var(--color-surface); border-radius: var(--radius-lg); }
/* an all-text action row: the buttons' own 14px padding IS the rhythm */
.ebar.inline:has(.eactions):not(:has(.eactions > :is(.obtn, .b-pri, .b-sec))) { gap: 0; padding-bottom: 0; }
.ebar .bl1 { display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; }
.ebar .bl2 { font-size: 12px; color: var(--color-text-muted); }
.ebar .bl2.dirty { color: var(--color-accent-text); font-weight: 600; }
.ebar .eactions { display: flex; justify-content: flex-end; align-items: center; gap: 8px; }
.ebar .eactions .push { margin-right: auto; margin-left: -12px; }        /* Peligro, far left */
.ebar.inline .obtn { background: var(--color-bg); }                      /* readable on the tint */
main .sgroup.apanel + .ebar.inline { margin-top: 12px; }                 /* two soft blocks need a seam */

/* ---------- settings panel in a page body (never hairlines) ---------- */
main .sgroup.apanel { margin: 0; padding: 12px 0; display: flex; flex-direction: column; gap: 12px;
  border: 0; overflow: hidden; background: var(--color-surface); border-radius: var(--radius-lg); }
main .sgroup.apanel > *      { padding: 0 16px; }
main .sgroup.apanel .flabel  { margin: 0 0 6px; }
/* 44px floor on anything you tap, a row that opens a sheet included */
main :is(.sgroup, .sbox.rows) :is(button, label, a).srow { min-height: 44px; }

/* ---------- iOS focus-zoom without taking pinch-zoom away ---------- */
@media (pointer: coarse) { :is(.tin, .field input, .sfield input) { font-size: 16px; } }
```

## HTML Structures

```html
<!-- Tab bar: sections + the Perfil/account tab (the ONLY signed-in signal) -->
<nav class="tabs" aria-label="Secciones de Admin">
  <button data-nav="panel" data-tab="panel" class="on" aria-current="page">
    <span class="tab-ico"><svg …/></span><span class="tab-lbl">Admin</span></button>
  <button data-nav="juegos" data-tab="juegos">
    <span class="tab-ico"><svg …/><span class="badge">3</span></span><span class="tab-lbl">Juegos</span></button>
  <button data-nav="secciones" data-tab="secciones">…<span class="tab-lbl">Web</span></button>
  <button data-nav="estantes" data-tab="estantes">…<span class="tab-lbl">Estantes</span></button>
  <button data-act="open-account" data-tab="account" aria-haspopup="dialog"
          aria-label="Tu perfil (sesión iniciada)">
    <span class="tab-ico"><span class="avatar ring">AP</span></span><span class="tab-lbl">Perfil</span></button>
</nav>

<!-- Drawer: only what the tab bar lacks; theme pinned to the bottom edge -->
<aside class="drawer" aria-label="Menú">
  <div class="drawer-top">…logo… <button class="icon-btn" aria-label="Cerrar">✕</button></div>
  <div class="drawer-body">
    <p class="group-label">ADMIN</p>
    <div class="dlinks">
      <button class="dlink" data-nav="niveles"><span class="slot">…</span>
        <span class="lbl">Revisar niveles</span><span class="count">7</span><svg class="chev"/></button>
      <button class="dlink" data-nav="staff">…</button>
    </div>
    <p class="group-label">SITIO</p>
    <div class="dlinks">…</div>
  </div>
  <div class="drawer-bottom"><div class="divider"></div>…theme icons…</div>
</aside>

<!-- Account sheet: two steps, ONE sheet, rows only -->
<div class="sheet" id="sheet-account" role="dialog" aria-modal="true" aria-label="Tu perfil">
  <div class="grab"></div>
  <div class="steps">
    <div class="step step-account">
      <p class="group-label">TU PERFIL</p>
      <div class="dlinks">
        <div class="dlink static"><span class="slot"><span class="avatar">AP</span></span>
          <span class="lbl">vos@ejemplo.com<span class="sub">Sesión iniciada · Dueña</span></span></div>
        <button class="dlink"><span class="slot">…</span><span class="lbl">Ver el sitio público</span><svg class="chev"/></button>
        <button class="dlink danger"><span class="slot">…</span><span class="lbl">Cerrar sesión</span><svg class="chev"/></button>
      </div>
    </div>
    <div class="step step-confirm" aria-hidden="true" inert>
      <p class="group-label">CERRAR SESIÓN</p>
      <p class="sheet-text">Vas a salir de <b>vos@ejemplo.com</b>.</p>
      <div class="dlinks">
        <button class="dlink danger"><span class="slot">…</span><span class="lbl">Sí, cerrar sesión</span></button>
        <button class="dlink"><span class="slot">‹</span><span class="lbl">Cancelar</span></button>
      </div>
    </div>
  </div>
</div>

<!-- Admin home box: name → number → (meter) → one note. No chevron. -->
<button class="box" data-nav="estantes">
  <span class="box-head"><svg class="ico"/><span class="name">Estantes</span></span>
  <span class="box-num">80%</span>
  <span class="meter" aria-hidden="true"><i style="width:80%"></i></span>
  <span class="box-foot"><span class="pend">84 sin ubicar</span></span>
</button>

<!-- Block head with the Ordenar mode control (outlined in BOTH states) -->
<div class="lhead">
  <p class="sec-label">Filas del inicio</p>
  <button class="b-sec" aria-pressed="false">Ordenar</button>   <!-- Listo → .b-pri when on -->
</div>

<!-- List row: ONE trailing affordance. Status marks the exception. -->
<button class="grow">
  <span class="thumb">…</span>
  <span class="gtxt">
    <span class="gname">Las Mansiones de la Locura: Segunda Edición</span>
    <span class="gsub"><span class="st-pill draft">Borrador</span><span>·</span><span>2016</span></span>
  </span>
  <svg class="chev"/>            <!-- › opens · ⋯ (.ibtn) means options in a sheet · never both -->
</button>

<!-- The one save bar -->
<div class="ebar inline">
  <div class="bst">
    <span class="bl1"><span class="dot draft"></span>Cambios sin guardar</span>
    <span class="bl2 dirty">Nombre, Subtítulo</span>
  </div>
  <div class="eactions"><button class="obtn">Guardar</button></div>
</div>

<!-- Sheet actions are ROWS, never a button footer: commit first (tick), Cancelar last (chevL) -->
<form class="dlinks">
  <button type="submit" class="dlink"><span class="slot">✓</span><span class="lbl">Guardar</span></button>
  <button type="button" class="dlink"><span class="slot">‹</span><span class="lbl">Cancelar</span></button>
</form>
```

## What to Avoid

- **Don't take the Estantes UI from 065 (R8/R9/R10) or 066.** Sketch 069 replaced all of it — the one
  Estantes page, the `Recorrido | Contenido` chips, the zone bar, the rail, `Agregar juegos` mode and
  per-estante `Ordenar`. Only R8's premises survive (search answers *where is it*; shelf order is
  physical order; neighbours one tap away; `asignar` retired).
- **Don't re-implement 061 (superseded by 071).** Specifically dead: the `Agregar` button **disabled
  while the field is empty** (064 killed disabled buttons; validate on tap instead — empty → *"Pegá un
  ID o link de BGG."* + focus), the **filled pill search field** (065 R4 gave it the shared field
  anatomy), **11px uppercase page-body labels** (065 #4 → 13px/600 sentence case), **year + player
  count in a row meta line** ("N jug." is gone — año stays because it tells two editions apart), the
  **iOS segmented control** for filters (chips won, and a filled segment track measured **1.16:1**,
  under the 3:1 floor of WCAG 1.4.11), and the **`maximum-scale=1` viewport meta** (use a 16px field on
  coarse pointers only).
- **Don't put the signed-in signal in the header** — no mode pill, no avatar, no green/purple dots.
  The header markup is byte-identical in all six states; the signal is the Perfil tab's ringed avatar.
- **Don't give the drawer what the tab bar already has.** Redundancy was the explicit rejection that
  killed 060's first three variants and its own winner's row list.
- **Don't let the theme switcher (or any persistent control) change place with state.** It is the
  drawer's pinned bottom block in admin, public-signed-in and signed-out alike.
- **Don't open a second sheet for a confirm step.** Two sheets animating at once (one down, one up) was
  the exact complaint. Step in place, animate the height.
- **Don't build buttons inside a sheet.** A sheet's actions are 48px full-bleed rows; the commit row is
  the form's submit. A button footer in a sheet is drift (it happened twice before it was caught).
- **Don't give a sibling page a back row.** Only genuine drill-downs get one — otherwise titles jump
  between tabs and the row duplicates the tab itself.
- **Don't ship per-page counters.** One derived source for badges, drawer counts, dashboard boxes and
  pages, or the admin will lie after the first edit — measured, not hypothetical.
- **Don't put a neutral count in the pending-pill shape.** A count bubble means pending work,
  everywhere.
- **Don't stack 600 on 600.** Content is 400; 600 is reserved for a label, an action or a state that
  needs noticing. The Admin home was 94% bold and nothing led.
- **Don't declare 500 or 700** — the app self-hosts Inter 400/600 only, so they silently round and any
  state pair built on them collapses.
- **Don't put inline icon or text buttons on a list row.** One trailing affordance; the rest goes in a
  sheet. Three icons on a row also breaks the `ux-patterns` D22 action cap.
- **Don't carry status by colour alone, and don't grey a draft.** The amber dot measured 2.78:1, and
  grey reads as *disabled* on both platforms — a draft is the most actionable row on the page.
- **Don't fill an input with `--color-surface`.** That token is what a soft content *block* is made of
  here, so a filled field reads as a container.
- **Don't rebuild a component that already exists** — the recurring failure mode across 065's ten
  rounds. Before adding a save bar, a settings group, a grouped list, a "pick one of N" control or a
  disclosure, check whether the admin already ships one.
- **Don't drive open/close state from `requestAnimationFrame`** — it never fires in a backgrounded or
  automated tab. Force a reflow before adding `.open`.
- **Don't rebuild `main.innerHTML` on every keystroke.** It destroys the focused input (the "the field
  blinks when I type" bug); refresh only the results region, the way LiveView would diff it.

## Origin
Synthesized from sketches: 059, 060, 062, 065 (with 061 quoted only as superseded).
- **059** admin-shell — winner C2, then the consistency / one-header / drawer-trim / back-row-scope rounds.
- **060** admin-panel-entries — winner B, the centered 2-column dashboard, plus the renames and the
  drawer-must-not-repeat-the-tab-bar rule.
- **062** admin-list-rows — winner B "Modo ordenar + hojas"; rounds 7–10 here are 065's, applied upstream.
- **065** admin-composition — 10 rounds, 11 drift bugs; the consistency rules (one row anatomy, one
  field anatomy, one list label, one component per job, one save bar, one disclosure, one sheet
  rhythm, the weight rule, the page rhythm, the keyboard answers). Its **Estantes work is superseded
  by 069**.
- Cross-cutting action anatomy lives in `admin-button-system.md`.

Source files available in: `sources/059-admin-shell/`, `sources/060-admin-panel-entries/`,
`sources/062-admin-list-rows/`, `sources/065-admin-composition/`
