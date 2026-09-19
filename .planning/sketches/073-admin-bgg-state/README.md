---
sketch: 073
name: admin-bgg-state
question: "R1 — when BGG has given nothing, what does the editor offer, and where does the `ID de BGG` field live? R2 — what is the editor's action bar, and what does the wait look like?"
winner: "D (r1) + r2 pending"
tags: [admin, juegos, editor, bgg, enrichment, empty-state, estado, publish-gate, cta, action-bar, loading, phase-01.8.2, mobile-first]
---

# Sketch 073: the BGG state in the editor

Item 1 of sketch 072's handoff, and the one with a real defect behind it. The spine is settled (decision 33);
this round draws the block that hangs off it.

## What the database actually says

Queried against the dev DB on 2026-09-19 rather than carried over from the notes — and it is sharper than the
handoff described:

| `enrichment_status` | n | `bgg_id` | campos BGG poblados | `status` |
|---|---|---|---|---|
| `enriched` | 386 | sí | 11/11 | 385 published + 1 draft |
| `no_bgg_id` | **41** | **NULL** | **0** | published |
| `bgg_missing` | **8** | **sí** | **0** | published |
| `pending` | **0** | — | — | — |
| `failed` | **0** | — | — | — |

Four facts, each of which changes the question:

1. **The 49 broken games hold nothing at all.** Every BGG column is NULL — no cover, no year, no description,
   no players, no duration, no rating. 15 of the 41 have a `weight_band` and that is the whole inventory. This
   is not "some facts are missing"; it is an empty set rendered through a block built for a full one.
2. **`form.ex:332-346` renders eleven rows through `value_or_dash/1`**, so today those 49 show a **wall of
   eleven em-dashes** under the sentence *"Vienen de BoardGameGeek y se actualizan solos. No se editan acá."*
   — which for exactly these games is false twice over: they did not update themselves, and the sentence
   offers nothing to do about it.
3. **The two broken states are structurally different, and `bgg_id` is the difference.** `no_bgg_id` has none,
   so there is nothing to retry. `bgg_missing` has one that does not resolve, so retrying is guaranteed to
   fail again. `Reintentar` — gated on `failed` in **both** `form.ex:220` and `catalog.ex:368` — is the wrong
   remedy for both, and `failed` has **zero rows**. A volunteer opens one of the 49 to fix it and is offered
   nothing whatsoever.
4. **Nothing gates publishing on BGG answering.** `Catalog.publish_game/1` (`catalog.ex:490`) runs
   `status_changeset`, which casts and validates only `:status`. That is how all 49 got live.

A likely fifth, flagged rather than asserted: the 8 `bgg_missing` ids look **mis-mapped, not transient** —
"Castillos del Rey Loco Ludwig" carries 255848 while Castles of Mad King Ludwig is 155426. BGG's API answers
401 from here, so it is a hypothesis. It does not change the design either way: a wrong id and a dead id are
fixed by the same action.

## How to View

```
python3 -m http.server 8765          # from the repo root
```
<http://127.0.0.1:8765/.planning/sketches/073-admin-bgg-state/index.html>

Harness: `node .planning/sketches/073-admin-bgg-state/verify.js` — **103/105**. The two failures are the
round's deciding finding, not breakage. `SHOTS_DIR=` to place shots.

Tools: **Variante · Estado · Tema · Teclado**. `Estado` is a **scenario**, not a variant — the dev DB has zero
`pending` and zero `failed` rows, so it is the only way to see those states at all (decision 24's `ENR`
precedent). **`HOY`** renders what `form.ex` ships today; it exists so every guard can be negative-tested.
Round 1's variants **A, B and C were removed** once D was picked, per 072's rule that what is on screen is the
decision and not a menu of them; their measurements are kept below.

## Settled before building, so the variants do not re-argue it

- **What staff supply: the id, pasted, with a hint carrying a link to BGG.** Chosen by the developer over a
  search-by-name flow (which needs a BGG search endpoint that does not exist) and over retry-only (which fixes
  nothing — 41 of the 49 have no id to retry).
- **The publish rule** — *"the app must avoid publishing uncompleted games."* Every variant obeys it
  identically, so it is a rule the sketch keeps, not an axis it varies.

## Variants

- **A — `ID de BGG` es la séptima fila del club.** The id is the club's *input* to BGG, so it joins 072's spine
  as row 7 and the BGG block stays pure read-only output.
- **B — el campo vive dentro del bloque BGG.** State line + inline input + hint + `Traer datos`, where the
  eleven dashes used to be. Closest to what ships.
- **C — vincular es una tarea.** The empty block is one action row opening a sheet that holds the field, the
  hint and the link. Nothing stands on the page.
- **D — el estado va arriba.** *Added mid-round, after the screenshots.* The state and its remedy sit directly
  under the head, above `DATOS DEL CLUB`; the `DATOS DE BGG` block is dropped entirely when there is nothing
  in it.

## The finding that reframed the round

**A, B and C were all wrong in the same way, and the harness was 64/65 green while they were.** Every guard
asked what the BGG block *contains*. None asked whether a reader ever reaches it. Measured at rest
(`scrollTop 0`, against the tab bar, which is opaque chrome pinned over the scroller):

| | 375×740 | 390×844 | 360×640 |
|---|---|---|---|
| A | **117px below the fold** | 13px below | **217px below** |
| B | 53px below | visible | 153px below |
| C | 53px below | visible | 153px below |
| **D** | **visible** | **visible** | **visible** |

The club spine is six 64px rows under a ~200px head, so the BGG block *starts* at y=619 on a device whose
usable height ends at 673. Wherever the remedy lives inside that block, a volunteer who opened this game **from
the "Sin datos" group — that is, someone who came here specifically to fix it** — lands on a screen that looks
entirely normal, and has to scroll past six healthy-looking fields to learn anything is wrong.

So the premise was wrong, not the three answers. **The state is not a property of the BGG block; it is the
reason the page was opened**, and it outranks every club field. That is D.

It is also the cheapest page, which was not the goal but is worth recording — total page height for a
`no_bgg_id` game: **HOY 1125 · A 866 · B 937 · C 821 · D 772**.

> These are **round 1's** numbers and include the in-page publish gate round 1 drew at the bottom of the
> page. Round 2 moved that into the action bar, so the same measurements come out ~80px lower there (HOY
> 1102, D-family 623). Both are correct for their round; they are not comparable across rounds.

## What only the screenshots said

Three things the green harness was blind to, all found by looking — the same count as 072, which is starting
to look less like coincidence and more like the rate:

1. **The state was below the fold in all three variants** (above). The harness measured A's BGG block as the
   *shortest* of the three at 156.5px and would have read that as cheapest; the reason it is short is that
   most of it is off the bottom of the phone.
2. **The keyboard buried the whole sheet.** Opening the id sheet raised the 292px number pad over the field,
   the hint, the BGG link *and* the commit button, leaving the title and half a subtitle. The guard passed it,
   because it measured `r.bottom <= 740` — the viewport — when the floor at that moment is the keyboard's top
   edge at 448. Committing an id means typing, and typing raises the keyboard, so the hint is covered at
   exactly the moment it is meant to be read. Fixed by moving the sheet above the keyboard, which is what both
   platforms do with a sheet that owns a text field; the guard now measures against whatever is actually
   covering the bottom of the screen.
3. **The action row's hairlines stopped 32px short of the right edge** — 0–343 against `.frow`'s 0–375. The
   first diagnosis was "a `<button>` is shrink-to-fit, it needs `width: 100%`". It already had `width: 100%`,
   and the new guard rejected the fix — which is the entire reason to write the guard before trusting the
   diagnosis. The real mechanism: `main` is padded 16px, so a percentage resolves against a 343px containing
   block, and `margin: … -16px` then *shifts* that sized box without stretching it. `.frow` escapes only
   because its parent `.frows` is a plain `<div>` doing the bleeding.

## What the numbers said about the other three

| | A | B | C | D |
|---|---|---|---|---|
| state on screen at rest (375×740) | ✗ −117px | ✗ −53px | ✗ −53px | **✓** |
| hint readable when offered | ✓ | ✗ −80px (keyboard) | ✓ | **✓** |
| club spine rows | **7** | 6 | 6 | 6 |
| cast fields needed | **7** | 6 | 6 | 6 |
| cost to the 386 healthy editors | **+64px** | 0 | 0 | **0** |
| page height, `no_bgg_id` | 866 | 937 | 821 | **772** |
| taps to fix | 2 | 2 | 2 | 2 |

**A's real cost is not the seventh row, it is who pays for it.** Making `bgg_id` a club field puts it on
*every* editor, including the 386 where it is a number nobody will ever retype — measured at +64px on a page
that is already fine. And `admin_changeset/2` casts six fields (`game.ex:245`); A makes it seven, which is a
schema decision, not a layout one.

**B cannot win the hint.** Its field is inline on the page, so focusing it raises the keyboard over the very
instruction it exists to give. A, C and D all put the field in a sheet, and a sheet can move.

## Rules this round leans on, and one it corrects

- **D-19h** — *a status is a dot + text, never a pill.* The shipped `alert alert-error` is a filled red box;
  decision 24 recorded that violation in the list row, and it is in the editor too (`form.ex:262-267`). Every
  variant here is an 8px dot + a sentence. Negative-tested: the harness asserts HOY **is** a filled box, so
  the guard is known to be able to tell the difference.
- **D-19e** — the id sheet closes with a 44px ✕, no Cancelar row. Copied from 072, not redrawn.
- **The lock line becomes conditional.** *"Vienen de BoardGameGeek y se actualizan solos. No se editan acá."*
  is true only for `enriched` and is now that state's own line rather than the block's standing claim.
  Asserted both ways: present for `enriched`, absent in all four others.

## Open, and deliberately not decided here

1. **`enrichment_status` is unvalidated on every live write path.** `validate_inclusion` exists only in
   `seed_changeset/2`; `enrichment_changeset/2` casts the column with no validation and there is no DB CHECK.
   Not a UI question, but it is why two orphan states can sit in the table with no code able to produce or
   clear them.
2. **No failure reason is ever persisted.** `failed` collapses three distinct causes (no credentials / BGG has
   no such item / transient exhaustion) into one string, and the reason is only `Logger.warning`'d
   (`enrich_game_worker.ex:94`). The editor can therefore only ever say "no se pudieron traer los datos" — a
   `bgg_missing` cause and a timeout look identical to the UI.
3. **The publish gate needs a server-side home.** The sketch draws `Publicar` disabled with a reason, but the
   rule belongs in `publish_game/1`, which today validates only `:status`. And it does not by itself address
   the **49 games already published broken** — that is a data fix, and it needs a decision: unpublish them, or
   leave them live while they are repaired one by one.
4. **`Reintentar`'s gate should move** from `enrichment_status == "failed"` to "has a `bgg_id`", in both
   `form.ex:220` and `catalog.ex:368`. Out of scope for a sketch; recorded so it is not rediscovered.
5. **Whether D's action row is a second anatomy** in the editor, and whether that matters. It reuses `.frow`'s
   bleed and press state but is one line with no value beneath — counted in the harness rather than waved
   away, since "one row anatomy" is exactly what decision 33 chose the spine for.


---

# Round 2 — the action bar and the wait (decision 39)

Developer feedback on round 1: *"D is the way, but I'm not sure about having the CTA at the bottom hidden
(since needs scroll down). Also I need consistent CTA (main is save and secondary would be like fix bgg id,
retry, etc). Also the loading isn't a better UI/UX having almost a full screen that allows me to use the
bottom nav until the loading finishes?"*

Three separate things. Round 1 had scattered actions across **three** places — the remedy row mid-page,
`Publicar` at the very bottom of the page (772px down a 740px screen, so genuinely unreachable without
scrolling), and `Guardar` in the pinned save bar.

## Settled before building

- **One primary slot that swaps by moment** — `Guardar` while there are unsaved changes, `Publicar` when
  there are none. Never two strong buttons competing; the bar never changes size. Asserted three ways,
  including the height, because "never changes size" is the half a later edit would silently break.
- **The secondary is the remedy** — Vincular / Corregir el ID / Reintentar.
- **`pending` gets a dedicated waiting screen**, not a skeleton imitating eleven rows of data that do not
  exist yet.

## What was still open

Round 1's winner won on **adjacency**: the state and its remedy sat together under the game's name, which is
the only reason a reader saw either. Moving the remedy into a bottom bar buys consistency and spends that
adjacency. **D-19a** is also in play — it says the save bar pins *while dirty* and otherwise sits in the page,
so an always-present bar amends a settled rule.

- **D1 — el remedio en la barra.** Bar always present; top carries the diagnosis alone.
- **D2 — el remedio arriba.** Bar always present but carries only Descartar + the primary; the remedy stays
  beside the state, keeping round 1's adjacency.
- **D3 — barra condicional.** Remedy in the bar, but the bar appears only when something is pending (dirty or
  broken) — D-19a's original instinct kept rather than amended.

## The collision, predicted before building and confirmed

**While dirty, the secondary slot is already `Descartar`.** A broken game with unsaved changes wants that one
slot to be both `Descartar` and the remedy. Measured — with unsaved changes on a `no_bgg_id` game, is the
remedy reachable at all?

| | remedio con cambios sin guardar |
|---|---|
| D1 | ✗ **perdido** — Descartar se queda con la única ranura |
| **D2** | ✓ arriba, junto al estado, y en pantalla |
| D3 | ✗ **perdido** — misma razón |

D1 and D3 can only get it back by adding a third control to a bar the developer asked to keep consistent, or
by making the reader discard their edit first to see the remedy again. **D2 never has the problem**, because
its remedy was never in the bar — the "consistent CTA" is the *primary slot*, which is what was actually
asked for, and the remedy stays where round 1 proved it had to be.

## The numbers

| | D1 | D2 | D3 |
|---|---|---|---|
| CTA principal en pantalla sin scrollear | ✓ (663 vs tab bar 673) | ✓ | ✓ |
| remedio con cambios sin guardar | ✗ | **✓** | ✗ |
| alto de página, `no_bgg_id` | **623** | 691 | **623** |
| barra al reposo, juego sano | 21px | 21px | **0 — no hay** |
| la ranura principal alterna Guardar/Publicar | ✓ | ✓ | ✓ (sin barra al reposo) |
| taps para arreglar | 2 | 2 | 2 |

D2 costs **68px** of page height for its remedy row. D3's bar appears and disappears (21 → 65px), which moves
the page under the reader — the cost of keeping D-19a literal.

Baseline for scale: today's editor is **1102px** for the same game. All three are ~40% shorter.

## The wait

A dedicated screen, centred in the space between the head and the tab bar: a spinner, *"Trayendo datos de
BoardGameGeek…"*, and the line that does the actual work — *"Puede tardar un rato si hay varios juegos en la
cola. Sigue funcionando aunque salgas de esta pantalla — te avisamos cuando lleguen."*

The justification is the job, not the look. Enrichment is an Oban job on a queue with **concurrency 1**
(`config.exs:41`, bounding libvips memory on the 1GB host) and `attempt * 30` backoff, so with 49 games to
repair the wait is real **and it keeps running whether or not the page is open**. A skeleton asks the reader
to wait; this tells them they do not have to. Page height drops to **407px**, against 1102 today.

Four things the screen owes, all asserted: it says the work continues if you leave · it carries **no action
bar** (nothing to save, nothing to discard) · **nothing is editable** mid-fetch, since the incoming write
would overwrite it · and all five tab-bar destinations are **actually hittable**, checked with
`elementFromPoint` rather than by existence, because "the way out is present" and "the way out works" are
different claims.

It was first drawn top-anchored over ~600px of void, which read as a page that had failed to load — the
opposite of the message. Centred after measuring.

## Two more bugs found by looking, not by measuring

1. **A sheet's change never reached the row behind it.** After stepping `Copias` up and closing the sheet,
   the row still read **"Copias 1"** while the bar already said *"Cambios sin guardar"*. The stepper commits
   into state and refreshes only the bar — re-rendering under an open sheet would tear it out from under the
   finger — and closing never re-rendered. **Inherited verbatim from 072**
   (`072-admin-game-editor/index.html:469`, `return closeSheet()`), whose own 49/49 harness never asserted
   that a row reflects a stepper change either. Fixed here and guarded; **072 needs the same fix, or 01.8.2
   ships it.**
2. **A guard asserting about source formatting.** The "says the work continues if you leave" check matched
   `/salgas de esta pantalla/` against `textContent`, but the phrase wraps across two source lines, so the
   rendered text holds `"salgas de\n      esta pantalla"` and the guard failed a screen that was correct.
   A guard that reads rendered text has to normalise whitespace first.

Plus one real regression the negative tests caught the moment it happened: restructuring `render()` to drop
the BGG block for broken states dropped it for **`HOY`** too, erasing the eleven-em-dash baseline. Three
negative tests went red at once — which is the entire reason they exist, since every positive check stayed
green while the thing they were compared against had quietly vanished.

## Still open after round 2

- **Which of D1/D2/D3.** The collision points hard at D2, but D2 is the only one that spends 68px and keeps a
  second action location — worth the developer's eye rather than the harness's verdict.
- Everything in round 1's open list stands, in particular the **49 already published broken** and moving
  `Reintentar`'s gate from `enrichment_status == "failed"` to "has a `bgg_id`".
- **D-19a needs a decision either way.** D1/D2 amend it to an always-present bar; D3 keeps it literal and pays
  by moving the page. Whichever wins should be written back as an amendment rather than left as sketch-local
  behaviour.
