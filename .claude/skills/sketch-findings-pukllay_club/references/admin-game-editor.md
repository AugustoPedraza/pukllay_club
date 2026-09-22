# Admin — Game Editor

`/admin/juegos/:id/editar`. Eight sketches (072, 073, 074, 075, 078, 079, 080) reworked this one
screen in a chain where each round amends the last, so **this file is the resolved current design,
not a list of snapshots** — several decisions below supersede an earlier sketch's prose. The final
chrome lives in `080-admin-guardar-fijo/index.html`; every CSS value here is read from that file
unless a different sketch is named. **None of this was confirmed on a real device** — every sketch in
the chain says so explicitly, and in this lineage the device found eight things the harness did not.

Mobile-first throughout: all measurements are 375×667 or 375×740 with 360×640 cross-checks.

## Design Decisions

**The editor is a full-screen destination: two exits and nothing else.** One 56px top bar
`‹ · título · ⋮`, no bottom tab bar (079 round 2, from the device: *"this is a destination page where
I need the user to leave because saved/published or go back with the ‹"*). 074's premise paid for
itself first: what shipped stacked a 53px wordmark header over a 44px in-page back row — **97px
before the game's name**, with the back affordance existing twice at scroll offsets where neither
pair was both hittable. One 56px bar gives 41px back and leaves one back control.

**The ⋮ is the bar's ONLY control — 074's one-CTA slot is gone (079 r1).** 074 round 2/3 decided a
swapping CTA in the bar (`Guardar`/`Vincular`/`Publicar`, W3 Texto weight, d43/d44); **079 replaced
it with a kebab and moved `Guardar` to the foot**, so that whole slot machinery is superseded. Do not
build 074's `primary()`/`topSlot()` swap. What survives from 074 is the bar's geometry, the
scroll-in title, and the D-19f back-confirm. The ⋮ opens a bottom sheet holding the lifecycle verb.
Measured before any container was drawn: the menu never holds more than two items, and in the only
state that will really exist it holds **one** (`published → Retirar`; `retired → Restaurar`;
`draft` never reaches this page — 078 sends it to the sheet).

**The title is absent at rest and fades in on scroll (074 r2, kept in 080).** At rest the name is
already on screen in the body, so the bar repeating it made three occurrences inside 600px. The
`.tb-t` keeps `flex: 1` while invisible on purpose — a collapsing title would let the right-hand
control slide left at rest and jump right on scroll, which is exactly the "the thing to tap is
moving" defect d42 exists to prevent. Trigger is `scrollTop > 46`.

**One verb, not two: `Retirar` = despublicar (079 r1, developer's call).** The codebase disagreed
with itself — `form.ex:352-356`'s dialog describes `retired` as reversible unpublishing, while
`shelves.ex` uses `status != :retired` in 5 queries meaning "the club doesn't have it". Collapsing
the verb makes the 5 queries correct and the copy complete rather than picking a winner. The stated
cost (d47, written not derived): the case *"I published it by mistake but still have the box"* is
lost — that game also leaves the shelf map. Worth 0 today (0 retired rows).

**The body IS the public game page, mirrored and made editable (E3, 079 r2).** Order measured from
`show.ex:548-623` / sketch 005: pills → cover → título Bebas 30/36 → section chip → description
(3-line clamp, justified) → `AÑO / DISEÑADORES / ILUSTRADORES / MECÁNICAS / TEMÁTICAS` → `Comunidad
BGG` → a single 1px `clubsep` → `COPIAS / ESTANTE / ES UNA EXPANSIÓN`. The club's three fields are
the ones `show.ex` renders nowhere, so E3 forces them into the only label→value rank the web has:
12px uppercase 0.08em — **byte-identical (12px | 400 | uppercase | 0.96px | `rgb(103,92,125)`) to the
five BGG labels that are NOT editable.** That is why the affordance carries the entire load here: in
E3 the typographic rank cannot say what is touchable.

**d33 (the spine): a value is a ROW THAT OPENS A SHEET, and d34: that row carries NO chevron.**
072 round 1 measured a row-spine (A) against an inline form (B) and a mixed layout (C): A was
**217px shorter** in the club block (450.6 vs 667.9) and showed **6 of 6** fields at rest against B's
4. C was rejected on a structural finding, not a preference — *an inline control already is the value
display*, so line 2 has nothing left but a hint, which makes it a different row; you cannot have both
"one anatomy" and inline controls. Chevrons were removed under D-19i (*a chevron means the row opens
another page; rows that act in place have none*), and the `⌄` that replaced them was removed too
(072 r2) after grepping found the glyph rendered in exactly one place in the whole corpus. **d33's
cost, stated plainly: flipping a boolean costs a sheet round-trip — 2 taps and a modal for a yes/no.**

**d33 was re-confirmed for E3's non-row blocks in 079 r3, by measurement, not analogy.** E3's header
has no rows (an `<h1>`, a clamped paragraph, an image, a pill), so d33 did not literally cover it.
Inline editing was drawn with the *same* controls mounted in both places and lost on four numbers:
the block grows up to **10.9×** (`band` 28→305px), everything below it shifts **317px** (the sheet
moves the page **0px**), the description's textarea lands at y=595-713 **under** the keyboard floor
of 448 while the sheet puts it at y=315-434, and inline stops the page looking like the ficha exactly
while you are using it — which is E3's whole premise.

**The affordance is `--val` tint PLUS a subtle 14px pencil (d47, 079 r2).** Neither half works alone
and both gaps were measured: the tint cannot mark the **cover** (an image has no text colour) so the
pencil goes badge-style in the corner where the public page already puts its share control
(`absolute right-3 top-3`, `show.ex:551`); the pencil could not mark the **description** (it lived
inside the 3-line clamp and was cropped) so it anchors outside the paragraph in the 44px column the
clamp already reserves. **Unresolved and named:** `--color-primary` and `--color-accent-text` are the
same hex in light, so the tint is also the colour of the section chip, which is not editable — the
only thing disambiguating them is the 14×14 pencil, the smallest mark on the screen. `--val`'s dark
stop (`#9F7AEA`) is still a local token: **`TODO(palette)`, owed upstream to `themes/default.css` +
`assets/css/app.css` before 01.8.2 ships.**

**"La hoja PREPARA, el pie escribe" (080).** `G` is the draft (what the page shows and what sheets
write); `SAVED` is the last commit — what the web serves. `Guardar` copies one onto the other.
`status` is deliberately outside the draft: the ⋮ changes it and commits on its own, because
unpublishing is a page action, not a staged edit. This closed a real hole 079 shipped with: sheets
committed on close *and* a foot CTA claimed to save, so **two commit points and only one wrote** —
the foot button was vestigial, a label claiming work it did not do.

**`Guardar` is fixed at the foot, and this is not a new pattern.** Measured on 079 before touching
anything at 375×667: `.tbar` 0–56, state band 56–94.5, body 94.5–1529 (**1434px = 2.15 screens**),
and `Guardar` at **y=1453 — 880px of scroll from rest**. Not demoted; unreachable. The public game
page already solves this with `.pk-mobile-cta-bar` (`app.css:5375`, phase 01.2): `position: fixed`,
`padding: .75rem 0`, `border-top`, plus `body.pk-has-cta-bar` reserving the height. E3 says the
editor looks like the ficha, so that form is reused rather than reinvented (the web reserves 148px
for *its* two-row bar; this one has one row).

**The foot bar is a DIVIDER, not a surface (080 r5).** Full width and **opaque** — that is what stops
body text showing through behind the button — but it takes the page background, so the only thing
drawn is its 1px line. Measured with the body scrolled to 700, body ink inside the button's band:
**divisor 0px · tonal band 0px · candle-gradient 255px · no band 1456px**. The divider buys exactly
what the tonal band buys without adding a surface. It extends 069's *"un tono, no un borde"* one step
further: not even a tone.

**The button is 064's A1 at its natural width, right-aligned.** 064's context × role table is
textual: save bar `.eactions` → Principal = **A1, last**; box foot → Principal = **never** full
width. A1 is **outlined**: 44px, 16px side padding, 1px stroke, radius 8, 14/600, ending on the 14px
keel. The full-width filled `.cta` the bar arrived with came from 078 — **and that `.cta` is a
sheet's button, not a page bar's**, so they were never competing precedents for this container.
Measured ink-fill of the button box: the web's real bar runs **47.1%** ("Reservar para el sábado",
23 characters); full-width `Guardar` runs **15.8%**; natural width runs **61.7%**. *Copying the web's
width copied a box sized for 23 characters onto one of 7.*

**Enabled only when dirty — a disabled button by explicit choice.** 064 banned disabled buttons
outright; this is the conflict the lineage has been carrying, now taken on purpose rather than by
omission. Two related traps: the disabled `.cta` fill is `--color-surface`, so inside a tonal bar it
measured **1:1** contrast (invisible but for its 1px ring) — the web's bar never hit this because
*its* button never disables. On the divider, the disabled outline is a weak **1.42:1** in light but
the **label reads at 6.17:1** (11.67:1 dark), so the button reads by its word.

**The body reserves the bar's height, and the height is MEASURED not estimated.** 65px clear at 375,
64.7px at 360. If you estimate it, the last block is covered by a few pixels and no check notices.

**Back with unsaved changes opens D-19f's centred dialog.** This is the price of "la hoja prepara" —
d47 had eliminated confirm-on-exit along with dirty state, and it returns. Copy verbatim:
`¿Salir sin guardar?` / `Los cambios que hiciste se pierden.` / `Salir` (danger) — `Cancelar`
focused. A clean editor leaves silently. 074 built D-19f's dialog first (312px, 16px radius, 18/600
question, one 14px consequence line, two right-aligned **text** actions, verb in Peligro red,
scrim/Esc cancel) and found a real defect there: inventing *"Seguir editando"* for the cancel wrapped
both actions to two lines at 312px. D-19f's own word fits on one line — keep `white-space: nowrap`.

**The status note lives IN the body, not in a fixed band (080 r4).** 079 r4 had put it in a 39px
fixed strip at y=56; the developer cut both the full width and the fixedness. It is now the admin's
soft box (`--color-surface` + `--color-border`, radius 12 — the same box as `.ebar.inline`) scrolling
with everything else, and it says **the consequence, not the name** (D-19h: dot + text, never a
pill). The `--warn` tint the first round used was dropped because **`--warn` does not exist in the
theme** — the palette has no warning stop, which is `TODO(palette)` #2.

| | dot token | clean | dirty |
|---|---|---|---|
| publicado | `--color-success` | `Publicado · Así se ve en la web.` | `Sin guardar · Tus cambios todavía no están en la web.` |
| retirado | `--color-text-muted` | `Retirado · No se ve en la web ni está en el estante.` | `Sin guardar · Tus cambios todavía no están guardados.` |

**Open (080's own, unresolved): the note shows EITHER the publish state OR `Sin guardar`, never
both.** With unsaved changes, `Publicado` disappears from the note. That is a consequence introduced
by unifying the two facts into one line — it may be right (the pending thing is the urgent one) or it
may be a loss. Named, not decided. Also open: `.ebar.inline`'s own status line + dot is, per 065,
*the save state's* home, and that bar no longer exists as a band — so there are two possible homes
for one fact and the system-of-record one is the one that was removed.

**078's publish gate (P2): the draft never publishes from this page.** It publishes from its own
sheet, opened from the list row (a draft row has no chevron, D-19i; a published row has one and opens
the editor). `Publicar` is born **disabled** and revives when the nivel is picked — no error message
ever. That puts the entire explanatory load on the label mark `Nivel · hace falta para publicar`,
which survived from a retired round precisely because of this: delete it and P2 is a dead button with
no visible reason, which is the exact defect 064 banned. The gate has **one** condition, measured
against the live catalogue, not assumed:

- **nivel** — 408/408 base games have it, 0/26 expansions do → required, conditional on `is_expansion`
- **estante** — 1 of 435 → never a gate (433 published games would fail their own gate)
- **copias** — 434 of 434 all `= 1`, no DB default, `admin_changeset` lets a blank through → a
  *missing default*, not a gate; the editor pre-fills 1 and the gate says nothing

**When an edit becomes real (078 r2 → 080).** 078 measured *la hoja guarda* (A) against *la hoja
prepara* (B) and found the tap counts identical (3 vs 3, one write each) because `Publicar` has
always saved first (`form.ex:84-92`, `165-177` — the two buttons were never save-vs-publish, they are
*"guardar y publicar"* vs *"guardar y seguir después"*). They differ only on leaving mid-edit. 078
settled its own surface as **one CTA, nothing written until Publicar**; **080 settled the editor as
`la hoja prepara`** — two different surfaces, two consistent answers to the same principle.

**Inside a sheet, the control depends on the surface — and 079 caught itself using the wrong one.**
078 has two patterns: the **draft sheet** is a classic form (`.seg` three-up with descriptors, `.sw`,
`.fld`, one CTA at the end), and the **editor's field sheet** is `.opt` + tick (one option per row,
the tick marks the current value, picking closes the sheet). Choice fields have no save button
(picking *is* the commit); text fields carry their own wide `Guardar`, because closing a text sheet
with the ✕ discarded silently. A stepper edits in place, so **the sheet must repaint itself and the
page behind it** — an edit made inside a sheet the rest of the screen cannot see is the model failing
in silence.

**THE EDITOR NO LONGER DESIGNS FOR A BROKEN PUBLISHED GAME — and 073's d38 accusation copy must NOT
ship on a draft.** Sketch 075 asked where the BGG remedy lives while the editor is dirty, ran four
rounds, and **closed with no winner**: the scenario was removed from the product. The 49 games with
no/bad `bgg_id` (41 `no_bgg_id`, 8 `bgg_missing`) **get unpublished, not deleted** — they are real
boxes the club owns and lends (~26 are expansions and promos), and the 8 `bgg_missing` may never have
been broken at all (BGG's API now answers 401 unauthenticated, and `bgg_missing` is assigned on an
empty list, not an error, `enrichment.ex:99`). Recorded in
`.planning/notes/staff-admin-decisions.md` § *Los 49 sin datos de BGG*. **The single easiest thing
for a future build to get wrong:** d38's diagnosis sentence ends

> *"Este juego no está vinculado a BoardGameGeek. Por eso no tiene tapa, ni descripción, ni datos.
> **Se está viendo así en la web.**"*

and **a draft is not on the web**, so that last sentence is now simply false. It is not softened, it
is deleted. 080's note already says the true thing for a draft — *"No se ve en la web ni está en el
estante."* Do not port `Se está viendo así en la web` onto a draft, and do not port 073's
remedy-in-the-bar action row either: **080's index.html renders no BGG diagnosis block and no
`Vincular` / `Corregir ID` / `Reintentar` control at all** (verified by grep). What genuinely
survives 075 is a smaller, different question — *a draft with no BGG id still needs a way to get
one* — and it belongs to 078's draft sheet, which does **not** currently carry one.

## CSS Patterns

```css
/* the top app bar — ‹ · título · ⋮ */
.tbar { height: 56px; flex-shrink: 0; display: flex; align-items: center; gap: 16px;
  padding: 0 16px 0 2px; border-bottom: 1px solid var(--color-border); background: var(--color-bg); }
.tbar[hidden] { display: none; }            /* see "What to Avoid" — load-bearing */
.tbar .tb-back { width: 44px; height: 44px; display: grid; place-items: center; border: 0; background: none; }
.tbar .tb-t { flex: 1; min-width: 0; font-size: 17px; font-weight: 600; white-space: nowrap;
  overflow: hidden; text-overflow: ellipsis; opacity: 0; transition: opacity 140ms var(--ease-out-soft); }
.tbar.titled .tb-t { opacity: 1; }          /* toggled at scrollTop > 46 */
@media (prefers-reduced-motion: reduce) { .tbar .tb-t { transition: none; } }

.kebab { width: 36px; height: 36px; display: grid; place-items: center; border: 0; background: none;
  color: var(--color-accent-text); border-radius: 9px; position: relative; }
.kebab svg { width: 20px; height: 20px; }
.kebab::before { content: ""; position: absolute; inset: -4px; }   /* 44px tap floor, invisible */
.kebab:active, .kebab[aria-expanded="true"] { background: var(--color-surface-2); }

/* the fixed foot: a DIVIDER the colour of the page, button at natural width, right.
   The sketch declares `position: absolute` because it lives inside a phone-frame `.device`;
   the real page uses `position: fixed`, which is what `.pk-mobile-cta-bar` (app.css:5375) does. */
.ctabar { position: fixed; left: 0; right: 0; bottom: 0; z-index: 18; display: flex; justify-content: flex-end;
  padding: 12px var(--gut, 14px) calc(12px + env(safe-area-inset-bottom, 0px));
  background: var(--color-bg); border-top: 1px solid var(--color-border); }
.ctabar[hidden] { display: none; }
.ctabar .cta { width: auto; padding: 0 16px; min-height: 44px; font-size: 14px; font-weight: 600;
  background: var(--color-bg); border: 1px solid var(--color-primary);
  color: var(--color-accent-text); border-radius: 8px; box-shadow: none; }   /* 064 A1 */
:root[data-theme="dark"] .ctabar .cta { border-color: var(--color-accent-text); color: var(--color-accent-text); }
.ctabar .cta[disabled] { border-color: var(--color-border); color: var(--color-text-muted); background: var(--color-bg); }
/* the reserve: --barh is SET FROM getBoundingClientRect().height + 24, never hard-coded */
.pg.hasbar { padding-bottom: var(--barh, 88px); }

/* the status note — in the body, D-19h dot + text */
.note { display: flex; align-items: baseline; gap: 8px; margin: 0 var(--gut, 14px) 16px;
  padding: 10px 12px; background: var(--color-surface); border: 1px solid var(--color-border);
  border-radius: 12px; font-size: 13px; line-height: 1.35; color: var(--color-text); }
.note .dot { flex-shrink: 0; align-self: center; width: 8px; height: 8px; border-radius: 50%; display: block; }
.note .dot.ok { background: var(--color-success); }        /* publicado  */
.note .dot.off { background: var(--color-text-muted); }    /* retirado   */
.note .dot.pend { background: var(--color-accent-text); }  /* sin guardar */
.note .n { font-weight: 600; }
.note .w { color: var(--color-text-muted); }

/* the editable block: a real <button>, reset FIRST, then type rules */
.pg .ed { border: 0; background: none; text-align: inherit; font: inherit; color: inherit; padding: 0;
  cursor: pointer; position: relative; }
.pg .ed:focus-visible { outline: 2px solid var(--color-primary); outline-offset: 3px; border-radius: 4px; }
.pg .ed::after { content: ""; position: absolute; left: 0; right: 0; top: 50%; height: 44px;
  transform: translateY(-50%); }                           /* 44px tap floor on a text-sized target */
.pg .ed.desc::after, .pg .ed.cardposter::after { content: none; }
.pg .ed[hidden] { display: none; }

/* d47 — tint + subtle pencil. NOTE the compound selectors: .ed IS the .h1, it does not contain it */
:root { --val: var(--color-accent-text); }
:root[data-theme="dark"] { --val: #9F7AEA; }               /* TODO(palette) — still a local token */
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --val: #9F7AEA; } }
.pg .ed.h1, .pg .ed.desc { color: var(--val); }
.pg dd .ed { color: var(--val); }
.pg .ed.pill { color: var(--val); border-color: var(--val); }
.pg .ed .pen { display: inline-grid; place-items: center; width: 16px; height: 16px; vertical-align: -2px;
  margin-left: 6px; color: var(--color-text-muted); }
.pg .ed .pen svg { width: 14px; height: 14px; }
.pg .cardposter .pen { position: absolute; right: 8px; top: 8px; margin: 0; width: 28px; height: 28px;
  border-radius: 50%; background: var(--color-bg); box-shadow: var(--shadow-sm); }
.pg .descshell .pen { position: absolute; right: 0; top: 0; margin: 0; width: 44px; height: 28px; }

/* the gutter: the WEB's 14px, not the admin's 16 — and it must not stack on an inherited 16 */
:root, .device { --gut: 14px; }
.pg { --gut: 14px; padding-left: 0; padding-right: 0; padding-bottom: 0; }
.pg .wrap { padding-left: var(--gut); padding-right: var(--gut); }
.pg .h1 { font-family: var(--font-display); font-size: 30px; line-height: 36px; font-weight: 400; }
.pg .clubsep { height: 1px; background: var(--color-border); margin: 0; }   /* one divider, like the web */
```

## HTML Structures

```heex
<%!-- the bar: ‹ · título · ⋮ — the kebab is the ONLY control --%>
<div class="tbar" id="tbar">
  <button class="tb-back" aria-label="Volver a Juegos"><.icon name="chevL" /></button>
  <span class="tb-t">{@game.name}</span>
  <button class="kebab" aria-label="Más acciones" aria-haspopup="dialog"><.icon name="kebab" /></button>
</div>

<%!-- the note: state + consequence, dot + text, inside the body --%>
<div class="note">
  <span class={["dot", @dot]}></span>
  <span class="t"><span class="n">{@state_name}</span> <span class="w">{@consequence}</span></span>
</div>

<%!-- an editable block: a real button carrying the tint class and the pencil --%>
<button class="h1 ed" phx-click="edit" phx-value-field="name">
  {@game.name}<span class="pen"><.icon name="pen" /></span>
</button>

<%!-- the club's three fields, in the web's own label→value rank --%>
<dl class="specs">
  <div class="spec"><dt>Copias</dt><dd><button class="ed inline" …>{@game.units}<span class="pen">…</span></button></dd></div>
  <div class="spec"><dt>Estante</dt><dd><button class="ed inline" …>{@game.shelf || "Sin estante"}…</button></dd></div>
  <div class="spec"><dt>Es una expansión</dt><dd><button class="ed inline" …>{if @game.is_expansion, do: "Sí", else: "No"}…</button></dd></div>
</dl>

<%!-- the foot: divider + one natural-width outlined button, enabled only when dirty --%>
<div class="ctabar" id="ctabar">
  <button class="cta" phx-click="save" disabled={not @dirty}>Guardar</button>
</div>
```

The ⋮ sheet's body, verbatim copy (one option, `.opt` + subtitle, danger styling on `Retirar`):

- published → `Retirar` / *"Deja de verse en la web y sale del estante."* → D-19f dialog:
  `¿Retirar Scythe?` / *"El club ya no lo tiene. No va a aparecer más en la ludoteca pública ni en
  los estantes. Vas a poder restaurarlo después."* / `Retirar` (danger) → snack `Juego retirado`
- retired → `Restaurar` / *"Vuelve a la ludoteca y a la web."* → no dialog → snack `Juego restaurado`

The sheet header says the state (`Ciclo del juego` + the state as subtitle) and **the body never
repeats it** — the state is said once on the page and once in the sheet header, not three times.

## What to Avoid

- **Don't ship 073's `Se está viendo así en la web` on a draft.** A draft is not on the web. The
  broken-published-game scenario was removed from the product (075 closed with no winner); the 49
  affected games become drafts. Porting that sentence forward re-creates an accusation that is now
  literally false, and there is no remedy control on the page to act on it.
- **Don't build 074's swapping CTA slot.** 079 replaced it with the ⋮ and moved `Guardar` to the
  foot. 074's `primary()` table (`Vincular` / `Corregir ID` / `Publicar` / disabled `Guardar`,
  1-of-8 dead) describes a bar that no longer exists.
- **Don't use sketch 063 as a reference for anything.** It predates the 01.8.2 restart: a pencil on
  every value (removed by web d17 — the value itself is the target, "one target instead of two"), a
  filled primary beside `Guardar cambios`, `Retirar`/`Restaurar` as loose buttons below the form, a
  `.modal` confirm, in-sheet confirmation, and a `bg-base-200` BGG box. Every one of those was
  overturned. Keep it only as the description of what ships today.
- **Don't give an editable row a chevron** (D-19i / d34) — a chevron means the row opens another
  page. And don't substitute a `⌄` either; 072 r2 removed that too after finding the "established"
  glyph rendered in exactly one place in the corpus.
- **Don't reason from a decision's prose when the artefact is right there.** This lineage's most
  repeated failure: 072 adopted `⌄` from a note whose own text records that it *"drew an empty SVG"*;
  079 hand-wrote sheet chrome (`<h2>`, a `.sh-hr` that does not exist) when `sheetChrome()` /
  `.sh-top` / `.grab` / `.sh-head` / `.sh-title` / `.sh-x` were all already defined. Grep what
  renders before citing precedent.
- **Don't set `display` on a class without an `[hidden]` companion.** A class rule out-specifies the
  UA's `[hidden] { display: none }`, so `el.hidden = true` hides nothing. 074 lost a round to it;
  078 hit it **five times in one file**. Corollary: a check asking "is this on screen" must use
  `offsetParent`, never `.hidden`.
- **Don't put a CSS reset after the type rules it resets.** `.pg .ed { font: inherit }` and
  `.pg .h1` have the same specificity (0,2,0), so the reset placed second silently rendered the
  title as Inter 16 instead of Bebas 30/36 — and the page still looked plausible. Third occurrence in
  this lineage.
- **`.ed .h1` is not `.ed.h1`.** The editable block *is* the title; it does not contain it. With the
  descendant selector the tint variant was byte-identical to the "nothing" variant and every
  node-counting check passed.
- **Don't estimate the fixed bar's reserved height** — measure the real rendered height. An estimate
  covers the last block by a few pixels and no check notices.
- **Don't make the foot button full width.** 064: a Principal in a save bar is A1, last, outlined,
  natural width — never full width, never filled. The full-width filled `.cta` belongs to a *sheet*
  (078), not to a page bar.
- **Don't give the foot bar a tonal surface.** Measured, a divider the colour of the page blocks
  exactly as much body ink (0px) as a `--color-surface` band, without introducing a surface. A
  gradient "candle" leaves 255px of readable text bleeding through near its top edge.
- **Don't use `--warn` or any local token.** `--warn` does not exist in the theme (the palette has no
  warning stop) and `--val`'s dark stop `#9F7AEA` is still defined per-sketch. Both are owed upstream
  to `themes/default.css` + `assets/css/app.css` under `check-theme-drift.sh`; `--val`'s dark value
  should beat 4.83:1 or it becomes the lowest-contrast text on the dark page.
- **Don't use a status *pill*** — D-19h: a status is a dot + text. And a `.dot` needs explicit
  `display` and `flex-shrink: 0`: a status dot vanished three times in this lineage through three
  different mechanisms (transparent token, a modifier orphaned under a removed ancestor, and an empty
  `<span>` staying `inline` at 0 width) with node-counting checks green every time.
- **Don't draw the cover as genuinely editable.** Choosing another image reverts 01.3.1/D-07, which
  emptied `gallery_urls` on purpose. The control is drawn (the pencil badge needs a target) but it
  does nothing — that is a reversion decision, not a screen.
- **Don't let the admin's 16px gutter stack on the web's 14px.** `main`'s inherited `padding: 16px`
  plus `--gut: 14px` put the text at 30px and *read like the expected finding* ("it's faithful to the
  web, the web has two edges"). Adopting the web gutter also moves the body's right edge to R361
  while the bar stays at R359 — two right edges, accepted and measured, not fixed.
- **Don't let a snackbar and the fixed bar share a boundary by accident.** The snack sits at 540–588
  and the bar starts at 598 — 10px, and only because r2 shrank the bar by 8px. The snack's `bottom:
  79` was chosen for a tab bar that no longer exists. One extra line on the bar and they collide
  again.
- **Don't assume the status band/note and the ficha can read different values.** One writer
  (`setField`) for every control; sheet edits must repaint both the sheet and the page behind it.

## Origin
Synthesized from sketches: 072, 073, 074, 078, 079, 080 (075 closed)
Source files available in: sources/080-admin-guardar-fijo/
