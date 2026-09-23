# Admin — Juegos (list, search, create)

**Status: not shipped.** 071 is the current design for the `/admin/juegos` page; 076 and 077 are two
consecutive slices of one create scenario on top of it. 076 and 077 are both **DECIDED 2026-09-21 "on
the measurements; not device-confirmed"** — chosen at the developer's request without a device pass, and
in this lineage the device has caught what the harness did not eight times. Treat them as the design to
build, but expect a device finding to outrank them.

## Design Decisions

**The page's shape came from counting what staff actually do, not from a filter-and-table default.**
Measured against `pukllay_club_dev` on 2026-09-17: **434 published · 1 borrador · 0 retirados · 49
published games with no cover *and* no description *and* no year · 27 with no `weight_band` · 50 of 435
incomplete for any reason.** Two conclusions fell out: 061's four `estado` chips would spend their life
filtering 435 into 435, and the 49 broken *published* games — which members see right now — were the
real queue nobody could see. **One job: find one game.**

**No filter chips, and no resting page title.** `Juegos` survives only as `<h1 class="sr">` (d22) — the
tab bar names the page and a 48px search field leads it, sticky at `top: 0`. The `+` sits beside the
field, not below it.

**The search is pure navigation: a game row opens its editor**, so it carries a trailing chevron
(D-19i). The one exception is the pending row — see the flow below.

**ONE LIST — three sections, not a work-queue block beside a catalog (decision 17).** `Sin datos 49` ·
`Borradores 1` · `Juegos del club 385` (= 435). Every header is the same caption anatomy; the harness
asserts it as one string across all three (**`1 anatomy`**). Sections butt together (gaps `0, 0`),
nothing is tinted at rest. The separate Pendientes page and its badge are gone. This is the iOS
plain-table / Contacts rhythm — one header anatomy repeated, no blocks, no gaps — but *not* its
ordering: these sections are semantic and wildly unequal (49 / 1 / 385), so there is no scrubber.

**Decisions 10, 11, 13, 14 and 15 were superseded by decision 17** (and 12 was reverted). Every one of
them existed only because there were two kinds of header. Do not reinstate them as fixes: no tonal band
at rest, no leading caret, no 16/44/68 three-edge ladder, no "band the work groups only", no
"the body group is the one that cannot collapse". Only d16's caption rank survived, generalised.

**The two exception sections collapse and are closed by default (d18).** Exceptions-first with
everything open buried the catalog **3,270px** down; closed, the catalog starts at **206px**. The caret
is affordance, not a second anatomy — carried only by sections that collapse, **inline after the count**
(never leading, which would punch a hole in the x=16 column, and never at x=339, which D-19i reserves
for "opens a page"). Glyph is chevron-**down** rotating 180° to up (d25/26), never `chevR`. A 30.9px
caption is under the touch floor, so a pseudo-element stretches the hit box to **44px** without
loosening the visible rhythm.

**Order is exceptions first** (`Sin datos` → `Borradores` → `Juegos del club`), cost measured and
accepted: the catalog sits **50 rows / 3,270px** down, so the 49 broken games cannot be missed but the
newest-first catalog is not at the top.

**Caption rank: 14/600 uppercase, tracked `.07em`, full-strength colour (d28).** This is the current
state and it supersedes d17's 13/600-muted and d20's 15/600 sentence case — check the CSS, not the
README prose, which lags. Separation from a row rests on weight (600 vs 400), keyline (16 vs 68) and
the absent 40px cover, so the old header-vs-row confusion cannot return.

**Air above a label, none below (d21): 27px against 9px, a 3.0:1 ratio, measured text-to-text.** It had
been 15 above / 17 below — *inverted proximity*, so every label attached to the label above rather than
to its own rows. Welding below alone failed at 1.2:1 because a header's bottom padding feeds the *next*
header's gap too. Proximity is a ratio; both ends have to move in opposite directions. Box gaps lie
here (the headers are transparent) — measure ink.

**The pinned fill is a band drawn *around the ink*, never the caption's own background (d29-31).** A
`::before` anchored to the content box and grown by `--band` is centred by construction in every state;
`--cap: 0.6px` nudges it onto the cap block (for versalita the line box is not the ink); `--bandp` fixes
the pinned bar at **44px** for every section regardless of its resting padding, so `Sin datos`' bar no
longer measures 32.2 against `Juegos del club`'s 44.2.

**Pinned context is two tiers (d6/7, D-19n) — and on Juegos the top tier is the search itself.** A title
bar here would repeat the word the pinned heading already says, so the search input pins; it is the same
input, not a second one. Section headings pin under it, full-bleed and opaque, and an arriving heading
evicts the previous one (each is confined to its own section, so the push is free). Motivation was
measured: `Sin datos` is **3,307px** tall and the fully paged list is **27,664px** (~45 screens).

**The search hides on scroll-down and returns on scroll-up (d9)** — *not* collapsed to an icon, which
measured **16px** saved: 0 extra rows at 375×667, plus a tap to undo.

**Why there is a list under the search at all (d3, D-19l).** Idle Juegos is ≈**132px** of content,
leaving ~**403px** blank at 375×667 (60%) and ~**580px** at 390×844 (69%) — worse than the Web page the
developer had already called "too empty" (worst case 449px / 62%). Newest-first, `Mostrar más · 50 de
435`: the search answers "I know the name", the list answers "what did we just add".

**Row anatomy (one, shared):** `min-height: 64px`, 40px cover (radius 6), 15/400 name with
`overflow-wrap: anywhere`, 13/400 second line, divider inset to 68px, 20px chevron. The second line is
the **year alone**; enrichment state takes that same slot as dot + text (d24, D-19h) and never repeats
the section's own state. A failure inside a **closed** section surfaces on the caption as the same
dot + text a row would use, and only while closed.

### The create → pending flow (076 then 077 — one scenario, four steps)

These are consecutive slices of a single walk: tap `+` → create by BGG id → the game appears → you tap
its row while the data is still loading → the sheet speaks when it lands. Read them in that order.

**Step 0 — the `+` sheet says only what the app actually does.** Four rounds took it from **435px to
271px**. `Crear a mano` is **deleted** (d51), in *both* places that offered it — the sheet and the
search's `Crear «…»` suggestion — because it is unbuilt, not unfinished: `catalog.ex:325` is the only
game insert in the application, it goes through `Game.draft_changeset`, and that does
`validate_required([:bgg_id])`. (The 41 `no_bgg_id` rows are legacy CSV-seed values, not evidence of a
by-name path.) The hint line is then **deleted outright** (d53) after being corrected once — it had
promised *"y el nivel"*, which enrichment never writes: `Enrichment.attrs_from_bgg_item/1` returns no
`weight_band`, and only `admin_changeset` and the band-audit tool ever set it. What remains is a label,
a field and a button. **`Agregar` is disabled while the field is empty (d52)** — the first disabled
`.obtn` in the project and an open conflict with 064's outright ban, argued rather than assumed
(the button is *waiting*, with the input one tap above it) and measured on d35's ΔE axis rather than
contrast: label 43,6 light / **28,3 dark**, border 80,0 / 81,6, against a bar of 20. In dark the border
does nearly all the work. A non-empty value that does not parse still raises *"Pegá un número de BGG o
el link del juego."* — disabling the empty case must not swallow the invalid one. **Cost recorded:** the
`+` path no longer states the consequence before you commit; only the search suggestion (*"BGG 342942 ·
se agrega como borrador"*) still does.

**Step 1 — creating has to put the game on screen (d55, variant V2 "Se abre").** Walked on 071 as it
stood at 375×740: after `Agregar` the snackbar said *"Juego agregado como borrador"* for 4000ms,
`BORRADORES` went 1 → 2, and **the new game's name was nowhere in the rendered page** — not below the
fold, not behind a caret, not in the DOM. The cause is a seam, not a sketch bug: the shipped app
`push_patch(to: filter_path(:draft, ""))` (`index.ex:105`) onto the drafts filter, d1 deleted that
filter, d8 replaced it with collapsed sections, and nothing took over the job at the create moment.
**V2 opens the section that holds the new row and scrolls to it** — 0 extra taps, row at y166–230, 79px
of page travel, still 3 section labels. V3 (a `Recién agregado` block above every section) was rejected:
it invents a concept with no lifetime rule (a `failed` game never resolves, so the block is permanent),
costs a 4th caption, and announces the same failure twice.

Two amendments ride on this and must be written down, not drifted: **d1 stands for browsing** (the chips
really did filter 435 into 435; no chips return), but the job they did at the create moment is now d8's
`Borradores` section opening. And **d18's "closed at rest" means *on arrival*, not invariantly** — the
section opens on create and *stays* open, through the sync finishing and a round trip to the editor and
back. One tap on the caption still closes it; the state is per-session and never persisted.

**Step 2 — the end of the sync speaks (d54), and it is a second axis, not a fourth variant.** A toast
when enrichment finishes, naming the game, with a 44px `Ver` that opens that game's editor; 10000ms.
Naming it is load-bearing because staff add in batches. **A failure counts as finishing** and gets the
same toast with a different verb. No toast for a game whose editor you are already reading. This does
not contradict d49's refusal of a toast for the *broken* state: that is state and has held since August
across 49 games; enrichment finishing is an **event**, so d49's own reasoning endorses it. Neither axis
covers the other — V2 covers the **interval** between create and completion, the toast covers the
**moment** of completion, and a missed toast has no second chance.

**Step 3 — tapping the pending row opens a sheet, and the sheet is what speaks (077, AV1 "sólo la
hoja", d56).** The decision rests on plumbing that already exists: the **list** holds the live signal
(`index.ex:41-43` subscribes to `"admin:games"`, `:195-198` handles `{:game_enriched, game_id}` and
`stream_insert`s), while **`form.ex` has no subscribe and no `handle_info` at all**. A sheet on the list
needs no new plumbing; the editor route needs a subscription that has never existed. It also sidesteps a
real defect instead of repairing it: `admin_changeset` casts `:name`, so saving an open editor at the
arrival moment writes `"Juego #342942"` back over the name BGG just supplied, and the D-07 gate reads
the **persisted** row, not your screen. Under the sheet you never open the form.

The sheet **cannot earn its tap on the wait** — the row already says `● Trayendo datos de BGG…` (d24),
and the page ends up saying it twice, verbatim, 310px apart. It earns the tap on the **arrival**, being
the one container on screen at the moment the state changes. Under AV1 the sheet transforms in place and
**the toast is suppressed for the game whose sheet is open** — that is check 25's existing rule reaching
one more container, not a second rule: the suppression is conditioned on `S.sheetFor`, which
`closeSheet()` clears, so closing the sheet before the data lands puts the toast back. Persistence is
the real difference: at t+10.4s AV1 still says *"Ark Nova agregado"* on screen; AV3 (sheet retires,
toast announces) says nothing at all. AV2 (both fire) loses either way — as built the toast is emitted
at `z-index: 30` under `.backdrop` 40 and `.sheet` 41 and burns its 10000ms unseen; raised above the
sheet it is two announcements about one game stacked on each other.

**A pending row loses its chevron.** D-19i: a chevron means *this row opens another page*; rows that act
in place have none. The cost is counted, not waved through — it is the only game row in the list without
one (**51 of 52**).

**Copy, verbatim** (Rioplatense; keep it):

```
+ sheet          Agregar juego · Número o link de BGG · placeholder 342942 · Agregar
create snackbar  Juego agregado como borrador                            4000ms
row, pending     ● Trayendo datos de BGG…
row, failed      ● Error al traer datos de BGG
sheet, pending   Trayendo datos de BGG…
                 Podés cerrar esto. El juego ya quedó agregado como borrador y te
                 avisamos cuando lleguen los datos.
sheet, arrived   «Ark Nova» agregado                                     [ Ver ]
sheet, failed    No pudimos traer los datos
                 «Ark Nova» quedó agregado igual, como borrador.         [ Ver ]
toast, ok        Ark Nova ya tiene sus datos                    [ Ver ]  10000ms
toast, failed    No pudimos traer los datos de Juego #342942    [ Ver ]  10000ms
section hints    Sin datos   — Se ven en la web sin tapa ni descripción.
                 Borradores  — Todavía no se ven en la web.
```

**One open copy question, and it is the developer's:** *"agregado"* is now said twice about one game at
two moments meaning two different things — the snackbar's *"Juego agregado como borrador"* (the addition
happened) and the sheet's *"Ark Nova agregado"* (the data arrived). d54's toast dodges it with *"ya
tiene sus datos"*. What is built is the developer's wording. Also unresolved: *"hasta que lo publiques"*
was tuteo-shaped in the deleted hint while the rest of the admin uses voseo (`Pegá`, `Buscá`).

## CSS Patterns

```css
/* section caption — one anatomy, sticky, fill only while pinned */
.lhw   { position: sticky; top: var(--bar); z-index: 5; margin: 0 -16px; background: var(--color-bg); }
.lhead { width: 100%; display: flex; align-items: center; gap: 8px; padding: 10px 16px 4px;
         border: 0; background: transparent; text-align: left; font-size: 14px; font-weight: 600;
         line-height: 1.3; color: var(--color-text);
         position: relative; --band: 6px; --bandp: 12.9px; --cap: .6px; --pt: 26px;
         padding-top: var(--pt); padding-bottom: 0; }
.lgroup:first-of-type .lhead { --pt: 14px; }        /* the 48px search already separates section 1 */
.lhead .ln  { letter-spacing: .07em; text-transform: uppercase; }
.lhead .cnt { font-weight: 400; margin-left: 4px; color: var(--color-text-muted); }
.lhead::before { content: ""; position: absolute; z-index: -1; left: 0; right: 0;
  top: calc(var(--pt) - var(--band) - var(--cap)); bottom: calc(var(--cap) - var(--band));
  background: transparent; transition: background 120ms var(--ease-out-soft); }
.lhw.pinned .lhead::before { top: calc(var(--pt) - var(--bandp) - var(--cap));
  bottom: calc(var(--cap) - var(--bandp)); background: var(--color-surface); }   /* == 44px bar */

/* collapsible section: caret inline, hit box stretched to the touch floor without loosening rhythm */
.lhead.tap::after { content: ""; position: absolute; left: 0; right: 0; top: 50%;
                    height: 44px; transform: translateY(-50%); }
.lhead .caret { width: 14px; height: 14px; margin-left: 4px; transition: transform 160ms var(--ease-out-soft); }
.lhead[aria-expanded="true"] .caret { transform: rotate(180deg); }

/* list row */
.row { display: flex; align-items: center; gap: 12px; min-height: 64px; padding: 8px 16px;
       border: 0; background: none; position: relative; }
.row + .row::before { content: ""; position: absolute; top: 0; left: 68px; right: 0; height: 1px;
                      background: var(--color-border); }
.row .name { font-size: 15px; line-height: 1.3; overflow-wrap: anywhere; }
.sub  { font-size: 13px; line-height: 1.35; color: var(--color-text-muted); display: flex; gap: 6px; }
.cov  { width: 40px; height: 40px; border-radius: 6px; flex-shrink: 0; object-fit: cover; }
.row.fresh { background: var(--color-accent-bg); }        /* the just-created row */
.row.fresh .name { font-weight: 600; }

/* the search is the page's own pinned tier (d7) */
.search { position: sticky; top: 0; z-index: 12; margin: 4px -16px 0; padding: 4px 16px 8px;
          background: var(--color-bg); }
.sfield input { width: 100%; height: 48px; padding: 0 48px 0 14px; border: 1px solid var(--stroke);
                border-radius: 8px; background: var(--color-bg); font-size: 16px; }
/* anchor the suggestions to the FIELD, not the padded sticky block — the padded version pushed the
   dropdown 5px under the 292px keyboard (453 vs 448) */
.sugg { position: absolute; left: 0; right: 0; top: calc(100% + 4px); max-height: 264px; }

.obtn[disabled] { border-color: var(--color-border); color: var(--color-text-muted); cursor: default; }
```

## HTML Structures

```html
<!-- one section. The caption is a <span> unless the section collapses, and only then a <button>. -->
<section class="lgroup shut">
  <h2 class="lhw">
    <button class="lhead tap" phx-click="toggle-section" phx-value-section="draft" aria-expanded="false">
      <span class="ln">Borradores</span><span class="cnt">1</span>
      <span class="warn"><span class="dot err"></span>2 con error</span>   <!-- only while closed -->
      <span class="caret" aria-hidden="true"><.icon name="chev-down" /></span>
    </button>
  </h2>
  <p class="hint">Todavía no se ven en la web.</p>            <!-- only while OPEN (d19) -->
  <div class="rows">…</div>
</section>

<!-- a row. The chevron is dropped exactly when the row opens a sheet instead of a page (D-19i). -->
<button class="row" phx-click={pending? && "open-pending" || "open-game"} phx-value-game={g.id}>
  <img class="cov" … />
  <span class="txt"><span class="name">{row_name(g)}</span><span class="sub">{sub(g)}</span></span>
  <span :if={not pending?} class="chev" aria-hidden="true"><.icon name="chev-right" /></span>
</button>

<!-- the + sheet body, final form (271px total sheet) -->
<div class="fbody">
  <label class="flab" for="bg">Número o link de BGG</label>
  <input class="tfield" id="bg" placeholder="342942" inputmode="text" autocomplete="off" />
  <p class="ferr" hidden></p>
  <button class="obtn pri wide" disabled>Agregar</button>
</div>
```

Notes for the Phoenix side:
- `enrich_game_worker.ex:104-106` already broadcasts `{:game_enriched, game_id}` on **both** success and
  failure, and `index.ex:195-198` already consumes it to re-render the row. Everything above is a small
  change on a signal that exists — do not build a new one.
- Use a distinct value key (`phx-value-section`, `phx-value-game`), never `phx-value-value`
  ([[feedback_no_phx_value_value]]).
- Cover images in the list are R2 thumbnails; anything that screenshots or measures the list must force
  eager loading and await decode, or every cover reads as an empty box.

## What to Avoid

- **061's page shape, in whole or in part.** 061 stacked an `AGREGAR JUEGO` block (section label + 44px
  field + `Agregar` button) on top of a search pill on top of a scrolling row of four `estado` filter
  chips (Todos / Borradores / Publicados / Retirados), then a summary line, then the rows. 071 says
  outright that 061 "predates the estante restart and the Web redesign, so it is the starting point to
  question, not the target." Three things are specifically wrong with it: the four chips filter 435 into
  435 on the real data; the inline add block is a second control sitting above the page's main one,
  which D-19j forbids (adding moved into the `+` and the search); and it labelled the page's real work —
  the 49 broken published games — as nothing at all. 061's *row anatomy* and admin type scale survive in
  069/070/071; its page composition does not.
- **Reinstating any of decisions 10, 11, 13, 14, 15** (tonal band at rest, leading caret, the 16/44/68
  ladder, band-the-work-groups-only, a non-collapsible body group). d17 dissolved all five at once.
- **A trailing `›` on a section caption, or a leading caret.** Trailing at x=339 means "opens a page"
  (D-19i); leading punches a hole in the x=16 column. Inline after the count, chevron-down.
- **Padding the caption to reach 44px.** That loosens d21's 3:1 rhythm. Stretch the hit box with a
  pseudo-element.
- **Giving the caption its own `background`.** The fill must be a `::before` band around the ink, or the
  pinned state gets 26px of empty tint above the text and hover shows the same defect.
- **A page title row on Juegos**, or a second search when it pins. The tab bar names the page (d22) and
  the pinned tier *is* the field (d7).
- **Repeating the section's state on its rows** ("● Sin datos" under a heading that already says it).
- **Creating a game without opening the section that now holds it** — the shipped `push_patch(:draft)`
  and this redesign otherwise disagree, and the page falls silent for the whole wait.
- **Firing the completion toast while the sheet or editor for that same game is open.** One
  announcement, one subject. Suppression keys off `S.sheetFor` / the open editor, and must be released
  when the sheet closes.
- **Putting the pending state in the editor.** `form.ex` has no subscription, and an open editor saved
  at the arrival moment overwrites the name BGG just supplied.
- **Assuming publish is gated.** `publish_game/1` → `status_changeset/2` casts and validates only
  `:status` (`catalog.ex:490-494`, `game.ex:218-222`), so a game created by this walk can be published
  with a placeholder name, no nivel and no data. That gate is a later slice — do not assume it exists.

## Origin
Synthesized from sketches: 071, 076, 077
Source files available in: `sources/071-admin-juegos/`
Also drawn on: `.planning/notes/juegos-ui-redesign.md` (the authoritative decision list, 1-56 — 071's own
README stops at decision 21 and its verification snapshot is stale; the `index.html` and the notes are
current). 061 is recorded above as **superseded**, for "What to Avoid" only.
