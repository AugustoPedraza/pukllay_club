---
sketch: 075
name: admin-remedy-dirty
question: "Where does the remedy live while the editor is dirty and the CTA slot is taken?"
winner: null
tags: [admin, editor, remedy, bgg, d42, d38, d33, d44, d47, d64, d29, d40, dirty-state, palette]
rounds: 3
status: PENDING REVIEW
---

# Sketch 075: the remedy while dirty

The slice decision 42 deferred on purpose:

> **Deferred, deliberately not varied:** what happens to the remedy **while dirty** (all variants hide it —
> mid-edit the thing to do is finish the edit). Its own round.

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/075-admin-remedy-dirty/index.html
node .planning/sketches/075-admin-remedy-dirty/verify.js     # 48/48
```

Variants on screen: **V1 Nada** (opens — the incumbent), **V2 En el diagnóstico**, **V3 Fila BGG**,
**V4 El diagnóstico ES el remedio** (round 2), and **HOY** (073's three-piece chrome, the baseline every negative test is written against). To reach the
state the round is about: pick a broken state, then tap **Es una expansión** and change it.

074's `W1`/`W2` weight tabs are gone — d46 settled the weight and what is on screen is the decision, not a
menu of them.

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
