---
sketch: 075
name: admin-remedy-dirty
question: "r1-r3 — where does the remedy live while the editor is dirty and the CTA slot is taken? · r4 — the slot is gone: where does it live AT ALL?"
winner: null  # ninguna — la pregunta dejó de existir antes de decidirse
tags: [admin, editor, remedy, bgg, d42, d38, d33, d44, d47, d64, d29, d40, dirty-state, palette, 079, 080, premise-change]
rounds: 4
status: CERRADA 2026-09-22 — el escenario se removió en vez de contestarse: los 49 juegos rotos se despublican (ver el cierre al final y `.planning/notes/staff-admin-decisions.md`). El artefacto queda como registro, 26/26.
---

# Sketch 075: the remedy while dirty

The slice decision 42 deferred on purpose:

> **Deferred, deliberately not varied:** what happens to the remedy **while dirty** (all variants hide it —
> mid-edit the thing to do is finish the edit). Its own round.

> **Read round 4 first.** The page was rebuilt on the chrome 079 and 080 decided, and rounds 1–3's
> premise — one CTA slot, taken by `Guardar` while dirty — no longer exists. The variants V1–V4
> described below are **not on the page any more**; their measurements stand as the record of how the
> question got here, and their numbers are what round 4's two homes had to beat.

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/075-admin-remedy-dirty/index.html
node .planning/sketches/075-admin-remedy-dirty/verify.js     # 26/26
```

On screen: **HOY · 079+080** (the shipping chrome — the baseline every negative test is written
against, and the state where the remedy is reachable from nowhere), **A · el cuerpo**, **B · el pie**.
The `Forma (A)` toggle in the tools panel switches A between `banda` and `botón`. To reach the state
rounds 1–3 were about: pick a broken game, then tap **Es una expansión** and change it.

---

## What was measured before anything was drawn

The premise turned out to be stronger than d42's own wording. The remedy is not **demoted** while dirty.
It is **unreachable** — counted at both scroll extremes, on all three broken states:

| | clean | dirty |
|---|---|---|
| CTA slot | `Vincular` / `Corregir ID` / `Reintentar` | `Guardar` |
| remedy on screen, at rest **or** full scroll | **1** | **0** |
| a `bgg_id` row to fall back on | 0 | 0 |
| the d38 diagnosis | present | **present, word for word** |

There is no second door. **d38** drops the `DATOS DE BGG` block entirely on a broken game, and **d33**'s
spine has no `bgg_id` row — so the CTA is the only way to reach `idSheet()`, and while dirty the slot is
taken. Meanwhile the page keeps saying, unchanged:

> *"Este juego no está vinculado a BoardGameGeek. Por eso no tiene tapa, ni descripción, ni datos.
> **Se está viendo así en la web.**"*

**A permanent accusation with the remedy removed.** That asymmetry is the round, and it is asserted
(checks 1–2) so it cannot quietly rot.

### Two things the measurement settled that d42 could not have known

**1. `Guardar` restores it.** Save and the CTA goes straight back to `Vincular`. V1's cost is therefore
**bounded** — two steps instead of one, plus a save you may not have been ready to make. That is a real
defence of doing nothing, and it is why V1 is on the page as a variant rather than as a straw man.

**2. Linking while dirty destroyed the edit, silently.** Set *"Es una expansión"* to **Sí**, link a BGG
id, and the row came back **No**. No dialog, no snack, no undo. One line: `commitId` called `loadState()`,
which rebuilds **both** `G` and `START` from the fixture. It went unnoticed because on 074's page the
remedy is unreachable while dirty — the only way to reach that function in that state was the console.

Which is exactly what V2 and V3 change. **Not a variant axis:** fixed at the source (save first, then
link — the two edits are independent, `bgg_id` is not in `CLUB_KEYS`, so nothing is owed a dialog) and
**negative-tested** by check 9, which reproduces 074's version and confirms it really does wipe the edit.
`Reintentar` had the identical shape and is fixed with it (check 10).

---

## The three answers

d44 fixed the bar at **one slot**, so no variant touches the CTA. `primary()` and `topSlot()` are
identical in all three (check 4: 24/24 across d42's eight situations, dead in exactly 1 of 8 in each).

| | where the remedy lives while dirty | reachable while dirty |
|---|---|---|
| **V1 Nada** | nowhere — the incumbent, and the negative-test baseline | **0 of 3** |
| **V2 En el diagnóstico** | the CTA's understudy, inside the d38 line that never leaves | **3 of 3** |
| **V3 Fila BGG** | a permanent `bgg_id` row in the spine | **0 of 3 at rest** — see below |

**V2 is not simply "reverse d42".** d42 moved the remedy into the bar *because the bar was empty* — "the
bar is completely empty at exactly the moment there is one obvious thing to do". While dirty the bar is
**not** empty; it holds `Guardar`, so the premise that put the remedy there does not apply in this state.
What V2 *does* reopen, said rather than slid past, is d42's other sentence: **"the state line stays as
pure diagnosis."** V2 puts an action in a block that has only ever informed.

**V3 is a d33 argument before it is a remedy argument.** d33: *"every value is a row that opens a sheet."*
`bgg_id` opens `idSheet()` and is the **only** such value in the editor with no row. V3 closes that gap;
the remedy surviving dirty is the side effect. Its anatomy is the spine's, asserted rather than asserted
about: same `.frow` class, same height, same left keyline as `Nombre`, and **no chevron** (d34, check 7).

---

## What building it found

### V3's row is not "one tap away" — it is entirely behind the tab bar

V3's whole claim is permanence. Measured, at 375×740 while dirty:

```
V2  diagnóstico  y224–268   fold 673   visible ✓  tappable ✓
V3  fila         y697–761   fold 673   visible ✗  tappable ✗   → hit-test lands on the tab bar
```

Not clipped — **invisible**, on every broken state. The remedy costs a scroll before it costs a tap.

**The measurement was nearly wrong in V3's favour.** The first version compared against the scroller's own
rect, which reports **740** — but the 67px tab bar *overlays* the scroller, so the eye stops at **673**.
That made the row look 21px short when it is in fact fully hidden. Every fold assertion now measures
against `.tabs`'s top **and** hit-tests the control's centre with `elementFromPoint`.

**Is this an artefact of the drawing?** Checked, because a cost charged to the wrong thing is how the last
round nearly picked the wrong winner. It is not: the row sits after the six club rows because that is
where `DATOS DE BGG` sits on an enriched game. Putting it *above* the spine would lift it over the fold,
but then the group order would change with state. **Named, not built** — it is a real escape hatch if the
d33 argument appeals but the fold position does not.

### V2 inverts the hierarchy, and both rules are being obeyed

Found in a screenshot, then measured on **d46's own axis** (painted area):

```
primary    "Guardar"   0px²    texto      ← d46: a single-action container takes text paint
understudy "Vincular"  319px²  contorno   ← 064: a content block's Principal is an outline
```

The page's **primary is its faintest control** while the **understudy carries the only container on
screen.** Neither rule is violated — this is d47 and 064 meeting in a situation neither was written for,
the same shape as the 064-vs-d42 disabled-button conflict 074 left open.

The alternative (a *text* remedy, 0px² both) removes the inversion and costs the affordance: a bare word
inside a prose block may not read as a control at all. **Not drawn — named**, because it is a call to make
rather than a number to read.

### V2's other cost: the remedy travels

Measured rather than argued — **221px across and 218px down** when the edit starts (bar `312,28` →
diagnóstico `91,246`). That is the shape of the defect d42 fixed *inside* the bar ("the thing to tap is
moving"), now across containers rather than within one.

### V3's cost: the remedy is reachable twice while clean

Bar **1** + fila **1** = **2** (check 13). The same charge 074 round 1 laid against the duplicated back
control. V2 stays at exactly 1 — the understudy is off until the slot is taken.

### A UA bevel, invisible to every assertion that could have looked for it

`.rmd` is the first control drawn from scratch since `.btn` reset `border: 0`, and without that reset the
UA painted a **`2px outset` bezel** — a dark offset edge along the bottom and right of the stroke. Caught
in the **first screenshot**; no box-shadow or contrast assertion can see it, because the inset stroke was
present and its contrast was correct. Check 11 now reads the computed `border-style`.

That is the **seventh** time in this lineage that a screenshot caught what the harness was green over.

### The page could model `pending` but never the moment it ends

Adding `enrichmentArrived()` was not a test hack — it is a real gap. The only route to `enriched` was the
tool panel's fixture switch, which calls `loadState()`, i.e. *"open a different game"*. So the first
version of check 9 **failed while the fix was correct**: it was measuring the tool panel. A page that
cannot express *"the data came back while I was still editing"* cannot be asked whether the edit survived
it. In the real app that transition is PubSub, and whatever was typed is still the user's.

---

## What to look for

Open **V1** on `Sin ID · 41` and change *Es una expansión*. The diagnosis still says the game is broken and
*"se está viendo así en la web"*, and there is now nothing on the page that acts on it — top or bottom.
That is the incumbent, and it is defensible: tap `Guardar` and `Vincular` comes straight back.

Then **V2**: same edit, and the remedy is sitting under the sentence that named the problem. Look at which
of the two controls your eye goes to first — the measurement says the wrong one.

Then **V3**, and notice you have to scroll to find out whether it answered anything at all.

---

## Open

- **The hierarchy inversion is unresolved and is not V2's fault.** d46 (text in a single-action container)
  and 064 (outline in a content block) are both obeyed, and the result puts 0px² of paint on the primary
  and 319px² on the understudy. A text remedy would even them at 0px² each; whether a bare word in a prose
  block still reads as a control is the open question. Joins 074's still-open `no disabled buttons`
  conflict as a case governed by no rule.
- **V3-above-the-spine is named but not drawn.** It would clear the fold; it would also make the group
  order depend on state.
- **`DATOS DE BGG` is a full group label for one row** in V3, and `ID de BGG` beneath it is close to
  saying the same word twice. Not addressed.
- **d42's "the state line stays as pure diagnosis" needs amending or upholding explicitly** if V2 wins —
  it should not become a fourth silent drift, which is the thing d47 was convened to stop.
- **The 49 already-published broken games remain a data decision, not a UI one.** Unchanged.
- `TODO(palette)` — `--val`'s dark stop is still defined locally, inherited from 073 and still owed
  upstream.

---

## Round 2 — V4, the diagnosis *is* the remedy

From the developer, rejecting the shape of the round rather than choosing inside it:

> *"For error, isn't simpler to show a kind of message (toast) and ask to the user like fix data? I mean
> the main purpose is to let the user know about that and ask for fix it. Nothing else care (maybe delete,
> remove the invalid data)."*

**The toast half was not drawn, and the reason is stated rather than assumed.** A toast is a container for
*events*; this is *state*. `snack()` clears itself after **2200ms**; the condition it would announce has
been true since the 2026-08-10 import and is true for **49 published games**. Once it went, nothing on the
page would say *which* of the three problems this game has — and the fix differs per problem. d2 also
makes the editor reachable by search, so arriving from the *Sin datos* queue already knowing why is not
guaranteed.

**The other half was right, and V4 is it.** If the job is only *know, and fix*, then a diagnosis that names
the problem and a separate control that fixes it are two things doing one job. V4 deletes the control: the
state line itself opens the sheet. It dissolves rather than trades — no second control, so no inversion;
nothing appears or moves on edit, so no travel; it is where the diagnosis already is, so above the fold.

### Drawn pure first, and the pixel diff was brutal

V4 was first drawn with **no paint at all**, on the reasoning that adding none is exactly what dissolves
V2's inversion. Pixel-diffed against V1 over the diagnosis region, decoded to RGBA:

```
diffPx 0 of 270000        maxDelta 0        clean AND dirty
```

**Identical.** Not a weak affordance — *none*. The variant where the diagnosis is the way to fix the game
was indistinguishable from the variant where it does nothing, and the page carries other small-grey-prose
blocks (`.lock`, `.hint`) that really are inert, in the same register. A chevron was unavailable by rule
(**d34** bans it on sheet-openers).

So it gets the minimum signifier that is **not a control container**: **d29's band** — a `::before`
anchored to the content box, which is centred by construction and *moves no text* (the spine sits at the
same 154/214/263 as V1). Check 19 keeps the pure result alive: strip `.band` and the diff returns to **0**.

**On comparing the band's paint to V2's 319px² — don't, and d46 is why.** That round discarded two metrics
for being well-defined on two variants and meaningless on the third. A band is a **surface**; V2's stroke
is a **control container**. Putting them on one axis is the same category error. What is measurable is
that `Guardar` keeps the only control container on screen; whether the page still *reads* it as the
primary is a device question, left as one.

### Three defects found, and only one of them was V4's

1. **`font: inherit` reset the line-height.** The shorthand resets `line-height`, and at (0,2,0) it
   out-specified `.st`'s own `1.45`. With one-sided padding on top, the whole spine sat **8px lower** than
   in every other variant. A pixel diff would have reported my CSS as an affordance. Geometry is now
   asserted *before* the diff is read.
2. **`z-index: -1` escaped the button.** With no stacking context the band painted *behind `.device`*,
   which is opaque white — so it rendered nothing, and V4 still pixel-matched V1. `isolation: isolate`
   fixes it. By eye the band was simply absent, twice.
3. **The invisible dot — inherited, and the worst of the three.** `.st.warn .dot` has been
   `var(--color-accent)` since 073. **That property does not exist**: the theme renamed it to
   `--color-accent-bg`/`--color-accent-text` and says so in its own header (`default.css:22`). An
   undefined custom property makes `background` compute to `rgba(0,0,0,0)` — an **8px transparent hole**,
   verified by loading 073, 074 and 075 and reading `getComputedStyle`.

   `warn` is `no_bgg_id`: **41 of the 49**. `.st.bad` uses `--color-danger`, which *is* defined, so 8 games
   showed a dot and 41 did not. **d40** says status is a dot + text; on the majority it has been text
   alone, through three sketches and four rounds of screenshots that all had it on screen. The palette has
   no warning stop at all, so `--warn` is defined locally as **`TODO(palette)` #2**, the same pattern as
   `--val`, and is owed upstream.

### What V4 costs, and the number that bounds it

V4 keeps **d44 intact**, so while *clean* the remedy is reachable twice — bar **1** + diagnóstico **1** —
the same charge as V3 and the one 074 laid against the duplicated back control.

The obvious fix is to drop the remedy from the CTA and let the diagnosis be its only home. **Measured, not
drawn** (check 22, by overriding `primary()`): that leaves the slot **dead in 4 of 8** — *exactly the count
d42 rejected*, and four times what d44 accepted. So V4 cannot become the sole home without reopening d42's
rejected configuration. The duplication is the price of V4, not an oversight in how it was drawn.

### Where V4 lands against the others

| | reachable while dirty | above the fold | travel on edit | inversion | duplication while clean |
|---|---|---|---|---|---|
| **V1** | 0 / 3 | — | none | none | none |
| **V2** | **3 / 3** | ✓ | **221px / 218px** | **0px² vs 319px²** | none |
| **V3** | 0 / 3 (behind the tab bar) | ✗ | none | none | **2** |
| **V4** | **3 / 3** | ✓ | none | none | **2** |

V4's tap target is **343×72 = 24,535px²**, **4.7×** V2's 117×44 button.

## Open (round 2)

- **The toast is argued against, not drawn.** If the argument is unconvincing it should be built and
  measured rather than conceded — the counts above are what it would have to beat.
- **`Borrar el ID` is still not drawn.** The developer's parenthetical — *"maybe delete, remove the invalid
  data"* — is a real gap: for the **8 `bgg_missing`** games a stored ID that does not resolve is worse than
  none, and the page's own copy says `Reintentar` will never fix it. It belongs in the ID sheet as a
  destructive text action, and it is a **data** decision with a live-site consequence (the notes already
  carry `enrichment_status` being unvalidated on every live write path).
- **`TODO(palette)` #2 — the palette has no warning stop.** `--warn` is local here; `.st.warn` is owed a
  real token in `app.css`, and the same undefined `--color-accent` should be grepped for elsewhere.
- **V4-only (dead in 4 of 8) is named, not drawn** — it reopens d44, which this round may not touch.
- Everything in round 1's Open list still stands.

---

## Round 3 — what the header CTA is *for*

From the developer:

> *"The header CTA is action associated to the fullscreen 'page', and 'vincular' is more a kind of 'link'
> that trigger an action (display a new bottom sheet)."*

**Checked against the artefact before building on it, and it is sharper than a placement preference.**
`remedy()` has been returning **two different kinds of thing under one name**:

```
Vincular      act 'open-link'  ->  idSheet()      a DISCLOSURE — opens a sheet, commits nothing
Corregir ID   act 'open-link'  ->  idSheet()      the same
Reintentar    act 'retry'      ->  fires the job  an ACTION, but about the BGG data, not the page
```

So d44's swapping slot has been holding disclosures and page-commits interchangeably. The editor already
has a taxonomy for disclosures — **d33**'s spine, where every row opens a sheet, and **d34**, where such a
row carries no chevron *because* it is that kind of thing. `Vincular` is one of those. `Guardar` and
`Publicar` are not.

**This is an orthogonal axis, not a fifth variant** — and finding that out is the round's first result.
Rounds 1–2 had conflated *where the remedy lives in the body* with *what the header slot is for*. They are
independent, so the CTA policy is drawn as a **toggle** that crosses with every body-home:

| | the slot holds |
|---|---|
| **Cambia (d44)** | the incumbent — whatever is "the one thing to do now", including sheet-openers |
| **Solo acciones de página** | only what commits the page: `Guardar`, `Publicar` |

### What it buys: V4's only charged cost disappears

Round 2 charged V4 with the remedy being reachable **twice** while clean. Under `page` the bar never holds
it, so:

```
V4 · swap    clean 2   →   the duplication round 2 charged
V4 · page    clean 1, dirty 1   →   ONE home, clean and dirty, never moving
```

That was V4's only cost. With it gone, V4 + `page` has no cost this round could measure: reachable 3/3
while dirty, above the fold, no travel, no inversion, no duplication.

### What it costs, and why the same number reads differently

The slot goes **dead in 4 of 8** — *exactly the count d42 rejected*, and four times what d44 accepted.
That is not smoothed over. What changed is what the number describes:

> d42 rejected 4/8 because a dead `Guardar` there *"demoted the real next step to a ghost"* — which
> assumes the remedy **wanted** that slot and was displaced from it. Under `page` it never wanted it.

And the four are not uniform, which is the strongest evidence they are honest rather than inverted:

```
pub·sin-id·limpio      Guardar  [dis]      nothing to save
pub·con-datos·limpio   Guardar  [dis]      nothing to save
pub·id-malo·limpio     Guardar  [dis]      nothing to save
bor·sin-id·limpio      Publicar [dis]      cannot publish a game with no data
```

Three say *this page has nothing to commit*; one says *this page cannot be published yet*. Both are true
statements about the page, which is what the slot is now for. **d46's W3 Texto gets more important, not
less** — a dead text button is a grey word, and there are now four of them rather than one.

**This is an amendment to d42 and d44 and it is written down as one.** Being an unrecorded departure is
precisely what d47 was convened to stop.

### The combination that must not ship

`page` with **no body home** leaves the remedy reachable from **nowhere**, in 6 of 6 broken states. The
two axes are **not** independent: choosing `page` requires choosing a body home. Asserted (check 27) so
they cannot be set separately by mistake.

## Open (round 3)

- **d42/d44 need amending explicitly if `page` wins.** The 4-of-8 count must be recorded as *accepted
  under a new premise*, not left to look like the rejected configuration returning by drift.
- **`Reintentar` is still the odd one.** It is neither a disclosure nor a page-commit — it fires a job
  about the BGG data. Under `page` it goes to the body with the other two, which is right by elimination
  rather than by argument.
- **064's `no disabled buttons` gets worse, not better** — 1 dead slot becomes 4. That conflict was
  already open after 074 and this widens it.
- Everything in rounds 1 and 2's Open lists still stands, including `Borrar el ID`.

---

## Round 4 — the question dissolved, and what replaced it

Opened by *"continue with 075"*, and the first thing the round did was check whether 075 still had a
question. It does not — not as written.

Rounds 1–3 asked **where the remedy lives while dirty and the one CTA slot is taken by `Guardar`**.
That question needs a swapping slot. Two sketches landed after this one and removed it:

| | 075 r1–r3 assumed (074's chrome) | decided since |
|---|---|---|
| header bar | one CTA slot swapping `Guardar` / `Publicar` / `Vincular` (d44) | `‹ · título · ⋮` — the ⋮ is the **only** control (079) |
| `Guardar` | took the slot while dirty, displacing the remedy | **fixed footer bar**, natural width, right, disabled when clean (080) |
| the remedy | displaced by `Guardar` | **never displaced — it has no home in the chrome at all** |

Asserted rather than asserted about: the top bar carries **2** controls, `tb-back` and `kebab`, and
neither is a remedy (check 1); `Guardar` sits at the foot and is *off* while clean, so it never takes
a slot from anything (check 2).

### The number the round opens with

The remedy is not unreachable *while dirty*. Under the shipping chrome it is unreachable **full
stop** — counted at both scroll extremes, on both broken states, clean and dirty:

```
no_bgg_id/limpio  0+0     bgg_missing/limpio  0+0
no_bgg_id/sucio   0+0     bgg_missing/sucio   0+0      = 0 of 8
```

And the accusation is still there, word for word, in all four (check 4):

> *"Este juego no está vinculado a BoardGameGeek. Por eso no tiene tapa, ni descripción, ni datos.
> **Se está viendo así en la web.**"*

**This is the configuration round 3's own check 27 declared must not ship** — `page` with no body
home, the remedy reachable from nowhere. Round 3 wrote that guard against a hypothetical. It now
fires against the decided chrome. That is the round's first result and it is not a preference.

`failed` is not drawn: it has **0 rows**, so `Reintentar` reaches nobody today. Four situations, not
six.

### So the axis changed: not *while dirty*, but *where at all*

Two homes, drawn on the decided chrome. The form question rounds 1–2 spent themselves on (a separate
control vs the block itself) is a **toggle inside A**, not a third tab — the round's axis is *place*,
and making form a tab would have crossed two axes in one list.

| | **HOY** (shipping) | **A · el cuerpo** | **B · el pie** |
|---|---|---|---|
| reachable, 4 situations | **0 / 4** | 4 / 4 | 4 / 4 |
| …at full scroll | 0 / 4 | — | **4 / 4** (fixed chrome) |
| above the fold at rest | — | ✓ | ✓ (it *is* the fold) |
| travel when the edit starts | — | **18px** — see below | **0** |
| reachable twice while clean | — | **no** | **no** |
| tap target | — | 319×59.5 = **18,990px²** | 5,078px² |

### The charge rounds 2 and 3 fought over is gone, and not by anyone's decision

Round 2 charged V4 with being reachable **twice** while clean; round 3 removed that with the `page`
toggle and paid for it by reopening d42's rejected 4-of-8. Neither is needed: the bar has no CTA to
duplicate into, so the count is **1, everywhere, in both variants, clean and dirty** (check 16). It
is 0 by construction, not by argument — which also means round 3's `page`-vs-`swap` axis has nothing
left to decide.

### A's 18px of travel is the note's, not the remedy's

A moves 18px down when the edit starts, and the round nearly charged it for that. Measured instead of
eyeballed: 080's note grows from **39.5 → 57.1px** when it flips to *"Sin guardar · Tus cambios
todavía no están en la web."* — one line to two. **18px, exactly** (check 6). The whole ficha moves;
A is simply inside it. B does not move because the foot is chrome (check 13b), and that is the one
measurable advantage B has over A.

Charging A for it would have ranked the round on an effect of the drawing rather than on its own
question — the trap this lineage has hit before.

### B's cost is the inversion, back in a new container

080 left the footer's left half free and named its owner (the `.ebar.inline` status line, 065) without
building it. B puts the remedy there, and the picture is blunter than the number:

```
Guardar   261px² of outline   DISABLED     ← the primary
Vincular  287px² of outline   live         ← the understudy
```

Both are 064's A1 outline, side by side, and while clean **the primary is the one you cannot press**
(check 14). This is round 1's 0px²-vs-319px² inversion in a different container — and it collides
head-on with 080's still-open *"dónde vive el pendiente"*, because that half already has an owner.
B does not fill empty space; it takes occupied space.

`Guardar` keeps the 14px keel 080 fixed (check 15).

---

## What building it found

### The two shipped decisions say the same sentence, 16px apart, meaning opposite things

Not A's fault and not B's — it is what the port surfaces. On a broken published game:

```
la nota (080)        « Publicado · Así se ve en la web. »
el diagnóstico (075) « …ni datos. Se está viendo así en la web. »      16px below
```

One is reassurance, the other is the accusation the whole block exists to make, and they are the same
words. Both blocks are decided; neither round could have seen it, because neither had the other on
screen. Check 18 holds it so it cannot be forgotten.

### `Nivel` disappeared, and no check could have noticed

The first port hid the whole `.poster` panel on a broken game, on the reasoning that d38 drops the BGG
block. But `Nivel` lives inside that panel and **is a club field** — one of d33's six, editable on a
game with no data exactly like `Copias`. It was gone from the page, and every check passed: they
counted the BGG block, not the six club rows. **The screenshot is what caught it** — the row simply
was not there. Check 17 now reads it on all three broken states. Eighth time in this lineage.

On the 49 it reads **`Sin nivel`**, which is the real state rather than an invented value.

### The pixel diff was about to report my own CSS as an affordance — the same defect, third time

`.st.tap` carried `padding: 6px 0`, so the block measured **71.5px** against the `<p>`'s **59.5**. The
12px pushed the entire ficha down, and the diff-without-the-band came back at **7,057px** instead of 0
— which reads as *"the variant paints something"* when all it does is sit lower.

This is round 2's `font: inherit` / `line-height` defect exactly, and 079 hit a third version of it.
Round 2 wrote the rule that fixes it and this round finally obeys it: **geometry is asserted before a
single pixel is read** (check 8a — block 59.5 = 59.5, ficha y 247.1 = 247.1). With that in place the
result round 2 found survives the new chrome unchanged:

```
with the band      85,574px different from doing nothing
without the band        0px   — identical
```

The band is still the only thing that makes the diagnosis look like a control.

### `ic('link')` drew the word `undefined`, and 080 had already written the warning

080's icon map has no `link` — its own comment, two lines above, documents this exact trap with
`tick`: a node present, sized, classed, and painting nothing. A check counting `.rmd svg` would have
passed. The browser console caught it, not the harness. Check 11 reads the `<path>` inside.

### The harness fabricated a failure by carrying scroll between cases

A's first clean case measured **not tappable** while its dirty case measured tappable — on the same
variant. Cause: the previous block ended with `scrollTop = scrollHeight`, and `go()` did not reset it,
so the diagnosis was measured off-screen. A cost invented by state dragged between cases. `go()` now
resets the scroll, and the reason is written where it happens.

### Two smaller ones

- **The tools panel grew into the variant nav** and ate the clicks: `#tools` inherits `top: 12px` from
  an earlier rule and the later one only sets `bottom`, so with two new rows it stretched the full
  height of the screen. Same family as the defect 080 found when it added its third button. Fixed with
  `top: auto`, a 42vh ceiling, and `z-index` below the nav.
- **A backtick inside an HTML comment inside a template literal** ended the literal and took the page
  down with a `SyntaxError`. 080 left that warning twelve lines below where I hit it; I read it after.

---

## What to look for

- Open **HOY** on `Sin ID · 41`. The page says the game is broken and *"se está viendo así en la web"*,
  and there is nothing anywhere — top, body or foot — that acts on it. That is what ships today.
- Read the top two blocks out loud. They say the same sentence 16px apart, one calmly and one not.
- Switch to **A**. The diagnosis is now the control. Look at whether the sand band reads as *tappable*
  or just as *coloured* — the harness can only tell you it is not identical to doing nothing.
- Flip the **Forma** toggle to `botón` and back. Same place, 3.7× less target.
- Switch to **B**. Look at the footer while clean: two outlined buttons, and the dead one is the
  primary.
- Change **Es una expansión** in A and watch the whole page drop 18px as the note grows.

## Open (round 4)

- **A and B are both one home; nothing in the measurements separates them on reachability.** What
  separates them is B's 0px travel against A's 18px, versus B's inversion and its collision with
  080's pendiente. That is a judgement, not a number.
- **080's *"dónde vive el pendiente"* has to be answered before B can be chosen.** The footer's left
  half cannot hold both the status line the system assigns it and the remedy.
- **The duplicated sentence needs one of the two blocks to change.** Not this round's axis, and it is
  a copy decision that belongs to whoever owns 080's note.
- **`Nivel` now renders as a full white panel holding one pill** on a broken game — 130px of surface
  for one chip, because the ficha's poster panel survives without its poster. Identical in all three
  variants so it does not bias the comparison, but it is not right.
- **Three stacked surfaces before the title in A** (note, band, Nivel panel). B has two.
- **`Reintentar` is still undrawn** because `failed` has 0 rows. Unchanged from round 3.
- **`Borrar el ID` is still not drawn.** Unchanged from round 2, and still a data decision.
- **`TODO(palette)` #1 and #2 still stand.** `--val` and `--warn` are local tokens, inherited through
  073/075/079/080 and owed upstream.
- **064's `no disabled buttons` gets its most concrete case yet**: B puts a dead primary next to a live
  secondary in one bar, 261px² against 287px². Still governed by no rule.
- Not confirmed on a real device.

---

## Closed 2026-09-22 — the scenario was removed, not answered

From the developer, after round 4:

> *"For keep it simple, let's remove that scenario for now. If there is some data without id or with
> id malo, or with a failed sync, remove it."*

**Checked against the data before acting on it, and the second sentence did not survive the check.**
The 49 rows are not junk: ~26 of the 41 `no_bgg_id` are expansions and promos the club physically
owns and lends (`Wingspan Europa (expa)`, `Root Expansion Los Rivereños`, both `ESDLA: Viajes por la
Tierra Media`…), the rest are base games with unmatched hand-typed names (`ganges`, `obscurio`,
`luxor`), and the 8 `bgg_missing` all carry plausible ids for their release years — which could not
be verified because BGG's API now answers **401** unauthenticated, while `bgg_missing` is assigned on
an **empty list**, not an error (`enrichment.ex:99`). Deleting would have removed 11% of the live
catalog, possibly over an enrichment bug.

**Decided instead: the 49 are unpublished, not deleted.** Full rationale and counts in
`.planning/notes/staff-admin-decisions.md` § *Los 49 sin datos de BGG*.

### Why that closes this sketch rather than just narrowing it

A draft is not on the web. So the sentence this entire sketch was built on —

> *"…ni datos. **Se está viendo así en la web.**"*

— becomes **false** and goes. That sentence was the whole moral engine: round 1's finding was not
"the remedy is inconvenient" but *"a permanent accusation with the remedy removed."* With the
accusation gone, so is the asymmetry that made the question urgent.

Two of round 4's own measurements go with it:

- **The 16px duplicated sentence dissolves.** 080's note for a draft already reads *"No se ve en la
  web ni está en el estante."* — it no longer collides with the diagnosis, because they no longer
  claim the same thing.
- **The 0-of-8 unreachability stops being a contradiction.** A draft that cannot yet be fixed is
  merely incomplete; a *published* game that cannot be fixed while telling you it is broken in public
  was the defect.

### What genuinely survives, and where it goes

**A draft with no BGG id still needs a way to get one.** That question is real, but it is smaller and
it is not this sketch's: it belongs to the draft flow, where **078** already decided
`P2 · la hoja del borrador, un solo CTA`, and 078's sheet does **not** currently carry a way to link
an id — checked, not assumed.

Round 4's two homes stay on the page as the measured record for whoever picks that up:

| | A · el cuerpo | B · el pie |
|---|---|---|
| reachable, 4 situations | 4 / 4 | 4 / 4 |
| travel on edit | 18px (the note's, not the remedy's) | 0 |
| tap target | 18,990px² | 5,078px² |
| cost | three stacked surfaces before the title | dead primary beside a live secondary (261 vs 287px²) |

Both were measured on a **published** broken game. Neither number transfers to a draft unchecked —
the chrome differs and the diagnosis copy changes — so re-measure rather than cite.

### Still owed, and not closed by this

- **The 8 `bgg_missing` need a second look**, because they may never have been broken. If the 401 is
  the cause they re-enrich clean, and unpublishing them was unnecessary.
- **The unpublish itself is not done.** It is 49 rows on a live site and wants a reversible
  migration, not an ad-hoc `UPDATE` — see the note.
- **`TODO(palette)` #1 and #2 still stand** — `--val` and `--warn` are local tokens inherited through
  073/075/079/080 and owed upstream, independent of this sketch's fate.
- **064's `no disabled buttons` conflict is still open.** It was never 075's to close.
