---
sketch: 077
name: admin-pending-sheet
question: "You tap the row of the game you just made while the data is still coming, a sheet opens and says it is working — who speaks when the data lands?"
winner: "AV1 sólo la hoja"
tags: [admin, juegos, create, pending, failed, sheet, d24, d39, d51, d53, d55, d19i, d47, copy, scenario-walk]
rounds: 1
status: DECIDED 2026-09-21 (on the measurements; not device-confirmed)
---

# Sketch 077: la hoja mientras llegan los datos

**Slice 2 of four.** Decided on **AV1 sólo la hoja** (decision 56). Picking the walk up exactly where 076 put it down: the game is created, `Borradores` is
open, the row is under your thumb. 076 asked *where the new game becomes visible*; this asks **what happens
when you tap it.**

The developer's scope, given at intake and taken as given rather than offered back as variants:

> *"Since I want to do it simple, until the data is retrieved if I tap that row, can I get a bottom sheet
> with a simple 'working' status?"*

and then, settling the arrival:

> *"When the data arrives this should says 'Game name agregado' and allow me to edit(ver)."*

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/077-admin-pending-sheet/index.html
node .planning/sketches/077-admin-pending-sheet/verify.js     # 39/39
```

Use **El paseo**: `1 · Agregar 342942`, then `2 · tocar la fila`, then `3a · llegan los datos` or `3b · falla`,
and `↺`. **Step 2 is optional on purpose** — the arrival steps stay live whether or not the sheet is open, so
both sides of the round's question are reachable: you were watching, or you went back to browsing.

---

## What was checked before anything was drawn

Both halves of the proposal, against the code — and they had different status.

### The sheet is the cheap route, and this is the fact that decides the whole slice

```
index.ex:41-43     subscribe("admin:games")
index.ex:195-198   handle_info({:game_enriched, game_id}) -> stream_insert
form.ex            no subscribe.  no handle_info.  none.
```

**The list already holds the live signal; the editor does not.** A sheet on the list needs no new plumbing.
The editor route needs a subscription that has never existed.

**And it sidesteps a real defect rather than repairing it.** `admin_changeset` casts `:name`
(`game.ex:243-251`), and the editor never learns that enrichment finished — so saving an open editor at that
moment writes `"Juego #342942"` back over the name BGG just supplied. The D-07 gate that would normally stop
that reads the **persisted** row (`enrichment.ex:141-170`), not your screen, so unsaved typing does not close
it. Under the sheet you never open the form, so there is nothing stale to save.

### The "working" status is already said, by the row you just tapped

```
d24          ● Trayendo datos de BGG…          the row's second line (sub(), index.html)
index.ex:241 Juego #<bgg_id> (cargando…)       what ships today
```

The same shape as **076 round 5**, where *"a syncing status on that specific row"* turned out to be built
already. So the sheet **cannot earn its tap on the wait.** It earns it on the **arrival** — it is the one
container on screen at the exact moment the state changes.

Which is what creates this round's question, because the transformed sheet and **d55's toast are now the same
announcement**: both name the game, both offer `Ver`. The toast's suppression rule was only ever written for
the editor (`S.screen === 'editor'`, 076:1114), so on the list nothing stops them firing together.

---

## The three answers

One axis: **who speaks when the data lands and the sheet is open.** `sheetParts` builds byte-identical
content in all three (check 11), so nothing here is attributable to treatment.

| | |
|---|---|
| **AV1 sólo la hoja** | the sheet transforms; the toast is suppressed for the game whose sheet is open — check 25's rule reaching one more container, not a new rule |
| **AV2 los dos** | both fire. **The do-nothing baseline** — what the code does if nobody writes the suppression, and what makes AV1's guard falsifiable |
| **AV3 se retira** | the sheet closes and the toast is the announcement |

```
                     la hoja        el toast              a los 10s
AV1                  se transforma  suprimido             «Ark Nova agregado» SIGUE en pantalla
AV2                  se transforma  suena — y se entierra  —
AV3                  se cierra      suena                 NADA dice que llegaron
```

---

## What building it found

### AV2's toast fires and is never seen — found in a screenshot, against a green check

Check 16 passed: under AV2 the completion toast carries `.show` and its text is the completion wording. **The
screenshot of that exact moment does not contain it.**

```
.snack     z-index 30   bottom: 79px
.backdrop  z-index 40
.sheet     z-index 41   181px tall, from the bottom
```

The second announcement is emitted, covered by the sheet, dimmed by the scrim, and **burns its 10000ms
unseen**. Dismiss the sheet at second 11 and it was never there. A probe at the snack's own centre returns
`sh-head` (check 19b).

**That is the eleventh time in this lineage a green number described something other than the page.**

**Not overclaimed.** The z-order is inherited from 076, not chosen for this round, and raising the toast above
the sheet is a one-line change. **AV2 loses under either reading** — as built the announcement is swallowed;
raised, it is two announcements about one game stacked on each other, which is precisely what check 25's rule
exists to prevent.

### The page says "Trayendo datos de BGG" twice, at once, 310px apart

```
y~190   the row      ● Trayendo datos de BGG…     (d24)
y~540   the sheet    Trayendo datos de BGG…       (its own title)
```

Verbatim identical, both on screen, in one screenshot (check 9). **Counted, not fixed** — it is the direct
consequence of the sheet's waiting state having nothing to add to the row, which is the finding above rather
than a bug to paper over.

### "agregado" is said twice about one game, at two different moments, meaning two different things

```
create    "Juego agregado como borrador"    the snackbar, 4000ms   — the ADDITION happened
arrival   "Ark Nova agregado"               the sheet's title      — the DATA arrived
```

Check 20 counts it. **Built as the developer worded it, and recorded rather than pre-empted**, because there
is a real argument on the other side: until it has a name it is not a game yet, so this is when it is *really*
added. d54's toast avoided the collision by saying *"ya tiene sus datos"* instead — about the data, not the
addition. **This is a copy decision, and it is the developer's.**

### The pending row loses its chevron, and D-19i is why

D-19i is explicit: *"a chevron means THIS ROW OPENS ANOTHER PAGE. Rows that act in place (show an answer, open
a sheet) have none."* 076's comment on that very line invoked the other half — *"a game row opens its editor
(decision 2), so it has one"* — which stops being true the moment the sheet exists.

**The cost is counted, not waved through:** the pending row is the only game row in the list without a
trailing chevron (check 3, `51 of 52`). Either it honestly signals that this row goes nowhere, or the list's
rhythm wobbles on exactly one row. **Negative-tested** (check 4): restore 076's predicate through
`window.opensSheet` and check 3 goes red.

### Persistence is the real difference between AV1 and AV3, and it is invisible at t=0

Both announce. Only one is still there a moment later (checks 32-33).

```
AV1   t+10.4s   «Ark Nova agregado» still on screen   — a sheet has no timer; it waits to be dismissed
AV3   t+10.4s   nothing on screen says it arrived     — the sheet retired and snack() cleared itself
```

076's own open list already flagged this about the toast — *"a missed toast has no second chance"* — and
under AV3 the row becomes the only durable record, which is **076 round 1's question returning intact**.

### Two fixture and rhythm bugs that were mine, not the design's

- **The standing draft was also Ark Nova.** 342942 really is Ark Nova's BGG id, so the arrival read
  *"Ark Nova agregado"* directly above two identical `Ark Nova · 2021` rows and nothing could say which one
  the sheet was about. A fixture that makes the round's own subject ambiguous is a fixture bug. Now
  `Beyond the Sun`.
- **An orphan gap under the rule.** The arrived body has no prose at all, so the button's own `margin-top`
  left 36px of nothing. 076 round 4 checked exactly this after deleting a block from a stack, *"on the grounds
  that nothing else notices an orphan gap."* Sheet 201px → **181px**.

### Three harness traps, two of them new

- **`#snack` carrying `.show` does not tell you which snack it is.** The create snackbar lives 4000ms and the
  walk reaches the arrival in ~1300ms, so **the first measurement taken while building this reported the toast
  firing under AV1 — which is exactly what AV1 suppresses.** It read the class, not the text. Every toast
  assertion now reads `#snack span` text, and the snackbar is explicitly cleared immediately before each
  arrival so that whatever appears after can only be the arrival's.
- **Playwright's `click()` cannot drive a control inside a panel you have just hidden.** Hiding `#tools` and
  then clicking a walk button is self-contradictory; every step is dispatched with `el.click()` inside
  `evaluate`, and the panel is hidden only around screenshots and geometry.
- **A console 404 that `page.on('response')` cannot see.** `/favicon.ico` is fetched by the *browser*, not the
  document, so it logs an error no response listener observes. The first fix filtered `"Failed to load
  resource"` out of the error check — **which made that check unable to fail**, the shape 075 named *"a guard
  that passed the thing it was written to reject."* Reverted; the page now declares `<link rel="icon"
  href="data:,">` so the request is never made and the guard stays strict.

---

## What to look for

Walk `1 · Agregar 342942`, then `2 · tocar la fila`. Read the sheet, then look at the row behind it — and ask
what the sheet is telling you that the row is not.

Then `3a · llegan los datos` on each variant. On **AV2**, watch closely: the toast is firing and you cannot
see it. On **AV3**, wait ten seconds and ask what on the page still says anything happened. On **AV1**, the
sheet is still there whenever you come back to it.

Then `↺`, walk to step 2, and take `3b · falla` instead.

---

## Decided — AV1 sólo la hoja (2026-09-21, decision 56)

AV2 and AV3 stay on the page and navigable; the winner is marked, not the only option.

| | la hoja | el toast | a los 10s | «llegó» dicho |
|---|---|---|---|---|
| **AV1 ★** | se transforma | **suprimido** | **sigue en pantalla** | **1** |
| AV2 | se transforma | suena — y **se entierra** | — | 2, una invisible |
| AV3 | se cierra sola | suena | **nada** | 1 |

**AV2 loses under both readings of its own defect** — as built the toast is emitted behind the sheet and
burns its 10000ms unseen; with the z-order raised it becomes two announcements about one game stacked on each
other, which is exactly what check 25's rule exists to prevent.

**AV1 dominates AV3 rather than merely beating it, and the reason is structural.** `render()` runs before the
sheet repaints, so the row behind the sheet is *already* the finished row. AV1 therefore gives you AV3's
result **plus** an announcement that persists — at t+10.4s AV1 still says *"Ark Nova agregado"* while AV3's
page says nothing at all (checks 32-33), which is 076 round 1's question returning intact. AV3's only
advantage is that the scrim is gone and the list is bright again.

**AV1 degrades correctly, and that is what keeps it from being a new rule.** The suppression is conditioned
on `S.sheetFor`, which `closeSheet` clears — so closing the sheet before the data lands puts the toast back.
The toast is silenced only while you are actually looking at the thing it would announce. **That is check
25's rule reaching one more container, not a second rule beside it.**

### The amendment this decision carries

**d39 is amended, not deleted, and it is written down here rather than left to drift (d47).** 073 gave
`pending` a dedicated 407px screen inside the editor. Every route to it went through a game row — and a
pending row now opens a sheet instead, so that screen has no caller left.

- **What d39 got right stands:** a game whose data is still coming has nothing to edit and should not be
  shown a form. The sheet says the same thing in less space and without leaving the list.
- **What it could not deliver was its own promise.** Its copy said *"te avisamos cuando lleguen"* while
  `form.ex` had no subscribe and no `handle_info` anywhere behind it. **AV1 is the first thing in this
  lineage that actually keeps that promise.**
- **Not claimed:** d39's other premise — *"nothing editable, an incoming write would overwrite it"* — is
  **false for three of the six club rows** (`enrichment_changeset` never casts `weight_band`, `units` or
  `shelf_id`, `game.ex:182-210`). This decision does not rest on that being fixed; it moves the question to
  a different container rather than answering it. See Open.

### Not device-confirmed

Chosen on the measurements at the developer's request. In this lineage the device has caught what the harness
did not **eight** times. If AV1 feels wrong in the hand, that finding outranks all of the above.

## Open

- **`agregado` vs `ya tiene sus datos`** — the round's one live copy question, named above. The developer's
  wording is what is built.
- **`Ver` vs `Editar`.** d55 already chose `Ver` for this exact destination and there is no read-only admin
  view, so both words land on `/admin/juegos/:id/editar`; consistency decided it. The honesty argument for
  `Editar` is untested.
- **d39 is owed an explicit amendment (d47), and this sketch does not write it.** 073 gave `pending` a
  dedicated 407px screen in the editor. Every route to it went through a row that now opens a sheet, so that
  screen has no one left to serve — and its own copy promised *"te avisamos cuando lleguen"* with no mechanism
  anywhere in the app behind it. Here the promise is kept. **Deleting the screen without recording why would
  be the fourth silent drift d47 exists to stop.**
- **The waiting sheet repeats the row verbatim.** If the duplication grates, the cheapest repair is to make
  the sheet's waiting state say what the row *cannot* — how long, or what is queued ahead of it — rather than
  to delete the sheet, which would take the arrival with it.
- **The failure branch is drawn minimally and is out of scope.** The developer scoped this *"until the data is
  retrieved"*, but a sheet open when the job dies has to say something, so it says the load-bearing thing (the
  game still exists) and sends you where `Reintentar` lives. **Designing the failure is slice 079.**
- **Nivel is still unreachable while you wait**, and it is the one datum BGG never supplies (d51). Measured
  against the code this round: `enrichment_changeset` never casts `weight_band`, `units` or `shelf_id`
  (`game.ex:182-210`), so d39's premise for a non-editable waiting state — *"an incoming write would overwrite
  it"* — is **false for exactly the three rows the club owns**. Not opened here; the sheet moved the question
  rather than answering it.
- **There is still no publish gate.** `publish_game/1` → `status_changeset/2` casts and validates only
  `:status` (`catalog.ex:490-494`, `game.ex:218-222`), so the game this walk creates can be published with a
  placeholder name, no nivel and no data at all. That is slice 3 (`draft`).
- **The real app broadcasts on both success and failure already** (`enrich_game_worker.ex:104-106`), and the
  list consumes it to re-render the row (`index.ex:195-198`). Whatever wins here is a small change on a signal
  that already exists.
- Everything in 076's Open list still stands.
