---
sketch: 075
name: admin-remedy-dirty
question: "Where does the remedy live while the editor is dirty and the CTA slot is taken?"
winner: null
tags: [admin, editor, remedy, bgg, d42, d38, d33, d44, d47, d64, dirty-state]
rounds: 1
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
node .planning/sketches/075-admin-remedy-dirty/verify.js     # 31/31
```

Variants on screen: **V1 Nada** (opens — the incumbent), **V2 En el diagnóstico**, **V3 Fila BGG**, and
**HOY** (073's three-piece chrome, the baseline every negative test is written against). To reach the
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
