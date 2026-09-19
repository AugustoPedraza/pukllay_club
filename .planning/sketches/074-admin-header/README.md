---
sketch: 074
name: admin-header
question: "Where does the primary action live once the editor's chrome collapses into one top app bar?"
winner: "N1"
tags: [admin, editor, header, top-app-bar, action-bar, d42, D-19f, D-19n]
rounds: 2
---

# Sketch 074: the editor's header

## The developer's words

> *"Until now, we have been using a useless header that is replaced at scrolling. So I want to explore what
> if we use with 'current action' (like editar juego, o crear juego, etc), the chevron for go back and save
> at the right. (making the save enable or disabled based on the status. It is save if there is changes to
> save)."*

Three questions were tangled in that. At the developer's request to go in smaller slices they were split,
and both rounds ran one at a time.

| | question | settled |
|---|---|---|
| Q1 | do `.hdr` + `.pbar` + `.back` collapse into one top app bar? | round 1 — premise, not varied |
| Q2 | where does the primary live? | **round 1** |
| Q3 | what does the title hold? | **round 2** |
| — | CTA weight — filled / tonal / text | **open, round 3** |

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/074-admin-header/index.html
node .planning/sketches/074-admin-header/verify.js     # 60/60
```

Variants on screen: **N1** (the answer) and **HOY** (what 073 ships — the baseline every guard is
negative-tested against). Round 1's H1 and H3 are removed along with their comparison checks; their
measurements are below.

---

## Round 1 — where the primary lives

**Variants:** H1 top-right `Guardar` + bottom bar · H2 everything top, no bar · H3 the control (bar
untouched) · HOY.

**The premise paid for itself.** HOY stacks a 53px wordmark header above a 44px in-page back row — **97px
before the game's name** — and the back affordance exists **twice** (`.back` and `.pbar`'s chevron, same
destination, and at no single scroll offset are both hittable, which is exactly why it shipped unnoticed).
One 56px bar replaces both: **41px given back, one back control**.

| | containers lit at once | primary's heights | reach from bottom-right | the bar's right edge |
|---|---|---|---|---|
| **H1** | **split in 3/8** | **2** — 28px and 641px | 118–715px | `Guardar` ∣ **`Descartar`** ∣ `Publicar` ∣ remedy |
| **H2** | 1 | 1 — 28px | **715–718px** | *(no bar)* |
| **H3** | 1 | 1 — 641px | **118–185px** | `Guardar` ∣ `Publicar` ∣ remedy |
| HOY | 1 | 1 — 641px | 118–185px | as H3 |

The right edge held at **R359 in every variant** — d42's fix survives. What the split moves is the
**vertical** position, which that fix never had to consider.

### Two findings the harness was green over, found by looking at the screenshots

1. **H1 hands `Descartar` the slot the thumb was taught.** With `Guardar` upstairs the bar still holds
   `Descartar`, and `.dirty` is `flex: 1`, so `Descartar` is pushed to **R359 — the exact edge `Guardar`
   occupies in the other five situations.** Five screens teaching "the bottom-right button is the safe one",
   then the undo-everything button lands there. Same hazard d42 rejected G2's `Retirar` for.
2. **H2 stops saying anything in words.** No bar means nowhere for *"Cambios sin guardar"*; the only signal
   is that a `Guardar` exists.

Plus: the game's name was on screen **three times** inside 600px — bar, 22px head, `Nombre` row.

### Two real page defects, invisible because the check agreed with them

`.hdr` and `.tbar` both set `display` on a class, which **out-specifies the UA stylesheet's
`[hidden] { display: none }`** — so `el.hidden = true` hid neither. Every H variant was rendering the
wordmark header *above* the new top bar (**109px of chrome, worse than the 97px it replaces**) while check 1
reported "41px given back", because it trusted the attribute instead of `offsetParent`. The page and the
check were wrong in the same direction. Caught only because a *different* check counted back controls by
`offsetParent` and saw three in a baseline that has two.

**Developer's verdict on round 1** (from the device): *"I think that header with the main CTA at the right.
(currently that CTA looks huge). The `<` for back is ok. I think that is a good semantic since I'm into this
page to edit/change something. I have the 'back' chevron for leave this page. So not need of main menu."*
Plus two riders: replace the words *"Cambios sin guardar"* with an **enabled/disabled CTA**, and **confirm
on back** when there is unsaved data.

---

## Round 2 — N1, the answer

**One variant, composed.** No bottom bar. Top bar: `‹` · title · one swapping CTA.

### The CTA slot swaps, and is dead in exactly one situation

The enabled/disabled idea taken literally re-opens what **d42 rejected**: a fixed `Guardar` put a dead
control in the strongest slot in **4 of 8** situations and demoted the real next step to a ghost — and on
the 49 real broken games `Vincular` would have nowhere to go, with no bottom bar to hold it. So the slot
**swaps**, and falls back to a disabled `Guardar` only where `primary()` has nothing to offer:

| situation | slot |
|---|---|
| dirty (any) | `Guardar` **enabled** |
| clean · sin ID / ID malo | `Vincular` / `Corregir ID` **enabled** |
| clean · borrador completo | `Publicar` **enabled** |
| clean · publicado · sano | `Guardar` *disabled* ← **1 of 8**, and nothing is pending |
| pending / retirado | `Guardar` *disabled* |

**1 of 8 dead instead of 4 of 8**, and in that one there is nothing to do — so it never inverts the
hierarchy, which is what d42's rejection was actually about. Guarded so it cannot drift back to 4.

### The title is absent at rest and arrives on scroll

The developer: *"not sure that I need to say where you go back or where you are since you can see it."*
True at rest — hence the triplication. **Not true scrolled**: measured on 514px of real scroll, once the
head goes past, a bar with no title says nothing about which game is being edited. That is D-19n.

So the title is `opacity: 0` at rest and fades in as the head clears the bar — `.pbar`'s trigger applied to
a bar that is **already there**. Nothing appears and nothing moves; one element changes opacity. Measured:
**2 name occurrences at rest** (was 3), **back to 1 in the bar at full scroll**.

`flex: 1` is kept while invisible on purpose. A collapsing title would let the CTA slide left at rest and
jump right on scroll — d42's "the thing to tap is moving" defect, reintroduced through the fade. The CTA's
right edge is **R359 at rest and R359 scrolled**; negative-tested by collapsing the title, which does move
it.

### `Descartar` is deleted, not relocated

Round 1's finding was that `Descartar` inherited the primary's edge. The fix is not to move it. With the
bar gone it has no home, and the developer's back-confirmation **is** `Descartar` — it becomes the
destructive option in **D-19f's centred dialog**, drawn here for the first time in this project: 312px,
16px radius, 18/600 question, one 14px consequence line, two right-aligned **text** actions with
`Cancelar` focused and the verb in Peligro red, scrim/Esc cancel. A clean editor leaves silently.

**A defect found in the screenshot:** the first build invented *"Seguir editando"* for the cancel, reasoning
that "Cancelar" is ambiguous here. At 312px both actions **wrapped to two lines**, turning two text actions
into a two-line block and making the focused one read as an outlined button. D-19f's own word fits on one
line. Departing from a settled rule on a judgment call cost a layout defect; `white-space: nowrap` plus a
one-line assertion now make any future departure fail loudly.

### The CTA is 36px, not 44

*"Currently that CTA looks huge"* — it was 44px in a 56px bar, **79% of the bar's height**. Round 1 held it
byte-identical to the bottom bar's button on purpose so a finding about *position* could not be blamed on
*weight*; that paid off, because the same control reads as proportionate in a dedicated action strip and
oversized in a top bar. 36px brings it to **64%**, with the 44px touch floor kept by a pseudo-element (the
technique already used for the switch track), hit-tested above *and* below the visible box and
negative-tested by removing it.

**Provisional.** Weight — filled vs tonal vs text — is round 3.

## What to look for

Open N1 and scroll to the bottom of a game with BGG data: the title arrives, nothing moves, and the CTA
stays where your thumb left it. Then switch to `Con datos · 386` with no edits — that is the one situation
where the slot is dead.

## Open

- **Round 3: CTA weight.** A *disabled filled* button reads as lavender-and-live rather than clearly dead —
  a text button would disable unambiguously. That is now the sharpest input to the weight question.
- **There is no longer any way to abandon an edit without leaving the page.** `Descartar` used to let you
  stay. The honest cost of deleting it, in the same shape as decision 41's.
- **D-19n must be amended, not dropped.** This settles the **editor** only. `.pbar` stays alive for the
  **catalogue list**, a different screen, not decided here.
- `crear juego` is not drawn — the title question changes shape when there is no name yet.
- The d40 lifecycle dot stays in the page head; whether it moves into the bar is untouched.
- `TODO(palette)` — `--val`'s dark stop is still defined locally, inherited from 073 and still owed upstream.
