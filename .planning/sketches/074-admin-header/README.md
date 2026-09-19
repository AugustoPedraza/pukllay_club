---
sketch: 074
name: admin-header
question: "Where does the primary action live once the editor's chrome collapses into one top app bar?"
winner: "N1 · weight W2 Contorno recommended, pending review from the device"
tags: [admin, editor, header, top-app-bar, action-bar, cta-weight, d42, d64, D-19f, D-19n]
rounds: 3
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
| — | CTA weight — filled / outline / text | **round 3** |

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/074-admin-header/index.html
node .planning/sketches/074-admin-header/verify.js     # 99/99
```

Variants on screen: **W1 / W2 / W3** (N1's CTA in three weights — W2 is the standing recommendation) and
**HOY** (what 073 ships — the baseline every guard is
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

---

## Round 3 — the CTA's weight

**Variants:** W1 Relleno · W2 Contorno · W3 Texto, paint only. **W2 is the standing recommendation on the
measurements — not yet confirmed from the device.**

### The round opened by finding that the question was posed backwards

Round 2 left this as *"filled vs tonal vs text"*, which assumes filled is the incumbent and the others are
departures. Checked against the artefacts rather than the prose, it is the other way round:

- **Sketch 064 already settled this for the whole admin** — *"S3 Contorno, weight-tuned: 1px strokes
  everywhere … **no disabled buttons**"*, applied to 059–063 and checked by `audit-admin.js` at 89/89.
- **071/072/073/074 have drawn a filled primary ever since** (`.btn { background: var(--color-primary) }`,
  072:216 and 073:265, copied forward verbatim), and round 2 added a *disabled* one.
- **Nothing records the departure.** No decision supersedes 064, and none of 071–074 carries its CSS block
  or mentions it. The incumbent on screen and the system of record have simply disagreed, unnoticed, for
  four sketches.

So W2 is not a new proposal. It is 064, and the round is about whether to keep departing from it.

**Tonal is not drawn.** 064's round 2 removed it with the developer in the room (*"S3 looks better"*), and
redrawing it would re-litigate a settled call. Three answers, not four.

### One axis, and the metric it took three tries to get right

Geometry is pinned — same 36px height, same padding, same radius, same hit box — so a finding about weight
cannot be blamed on size. The stroke is an **inset box-shadow, not a border**, so W2 does not shift the
label by the 1px a border would cost. Round 1 held the CTA byte-identical across positions for the same
reason, inverted.

**Two metrics were thrown away first, and both failed the same way** — well-defined for two weights,
meaningless for the third:

1. *"the label against the bar"* is nonsense for W1: its label is white, the bar is white, and the fill sits
   between them so they never touch. The probe returned **1:1** — a true number about a comparison that does
   not exist on screen.
2. *"three different box readings"* assumed three inks. There are not three. In light `--color-primary` and
   `--color-accent-text` are **the same hex** (`#3C1269`), so a fill and a stroke are the same ink at the
   same 14.16:1.

**The axis is painted area, not contrast.** Same token, three coverages:

| | painted container | dominant ink vs the bar (light / dark) |
|---|---|---|
| **W1 Relleno** | **3903px²** | 14.16:1 / **2.33:1** |
| **W2 Contorno** | **285px²** | 14.16:1 / 11.67:1 |
| **W3 Texto** | **0px²** | 14.16:1 / 11.67:1 |

### What decided it

**1. The disabled read — the question round 2 actually asked.** Its note said a disabled filled button
*"reads as lavender-and-live rather than clearly dead"*. The screenshot is blunter than the number: in the
one dead situation W1 keeps **2977px² of solid lavender pill**, the entire silhouette of a live primary.
W2 drops to a **233px² faint outline** and W3 to **nothing at all**. W1 is the only weight whose dead state
still looks tappable.

**2. W1's weight is not portable across themes.** Dark `--color-primary` (#7B2DCE) on the bar's #2E154E is
**2.33:1**, against 14.16:1 in light — the container all but merges with the bar, and what identifies the
button in dark is the white 15.75:1 label, not the fill. *Stated as measured, not as a verdict:* this is
**not** called a WCAG 1.4.11 failure, because 1.4.11 covers information *required* to identify a control and
the label does that job. What it does establish is that "filled is the loudest" is a light-theme fact, not a
property of the weight. W2's stroke holds a container in both (14.16 / 11.67).

**3. W3 merges with the title at full scroll.** The bar's gap between title and action is 4px in every
weight; W1 and W2 put a container edge in it, W3 puts whitespace. On a truncated real name the result is
`Castillos del Rey Loco Lud… Guardar` — one run-on line in which the primary action does not read as a
control. W3 also has no container to outrank the back chevron, so all that distinguishes the primary from
navigation is that one is a word and the other a glyph.

**4. W3 breaks d42's rule in a way the rule never anticipated.** *"The primary always ends at the same
edge"* was written for a control whose box **is** its ink. With no box the two readings come apart and only
one can sit on the 16px keyline: either the label sits 14px short of every other right edge, or the box —
and the 44px hit target with it — overhangs to **R373, two pixels from the bezel**. W3 is drawn the second
way and the cost is measured, not smoothed over.

**W2 wins on every axis and costs nothing new:** it disables unambiguously, keeps a container in both
themes, stays legible beside a truncated title, holds the keyline with no overhang — and it ends an
unrecorded four-sketch departure instead of creating another decision.

### A guard that passed vacuously, caught by the screenshot again

Check 20's first version measured the title-to-CTA gap on `bgg_missing`, chosen because that fixture carries
the long real name. But a broken game has no BGG facts, so the page is barely one screen tall, `toBottom()`
moved nothing, and **the title never faded in** — `getBoundingClientRect()` measured an element at
`opacity: 0` and reported a tidy 4px for all three weights. Three identical numbers, all about something
invisible. The fixtures force the choice (the long name is on the page that does not scroll; the page that
scrolls has a short name), so the name is now typed in through the real sheet, and **the title's visibility
and truncation are asserted before the gap is read**. That is the sixth time in this sketch's lineage the
screenshot caught what the harness was green over.

## What to look for

Open W2 and switch to `Con datos · 386` with no edits — the one dead situation. Then flip to W1 and back:
the question is whether W1's dead lavender pill still looks tappable to you. Then scroll to the bottom of a
game with BGG data in W3 and read the bar left to right.

## Open

- **W2 is a recommendation on the measurements, not a decision.** It needs confirming from the device — and
  the relevant judgement is one only the developer can make: whether a dead filled CTA reads as live in the
  hand the way it does in the screenshot.
- **064 needs a decision either way.** If W2 is confirmed, 071–074's filled `.btn` is a four-sketch drift to
  be corrected and 064 stands. If W1 is chosen instead, 064 is *overturned* and that has to be written down
  — it governs the whole admin, not just this bar.
- **`no disabled buttons` (064) is still contradicted** whichever weight wins, because round 2's slot is
  dead in 1 of 8. 064 banned disabled controls outright; d42 allowed 0 and rejected 4. The 1/8 case sits
  between two rules and is currently governed by neither.
- **There is no longer any way to abandon an edit without leaving the page.** Unchanged from round 2.
- **D-19n must be amended, not dropped.** This settles the **editor** only; `.pbar` stays alive for the
  **catalogue list**.
- `crear juego` is not drawn — the title question changes shape when there is no name yet.
- The d40 lifecycle dot stays in the page head; whether it moves into the bar is untouched.
- `TODO(palette)` — `--val`'s dark stop is still defined locally, inherited from 073 and still owed upstream.
