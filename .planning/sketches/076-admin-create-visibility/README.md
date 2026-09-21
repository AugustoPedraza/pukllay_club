---
sketch: 076
name: admin-create-visibility
question: "R1 — after you tap `Agregar` with a BGG id, where does the just-created game become visible? R2/R3 — what do you get when you tap `+`?"
winner: null
tags: [admin, juegos, create, draft, pending, failed, d1, d3, d4, d8, d17, d24, d51, d52, d53, d54, d49, d39, d38, d35, d36, d46, d64, copy, disabled-state, scenario-walk]
rounds: 5
status: PENDING REVIEW
---

# Sketch 076: crear con ID de BGG — ¿dónde queda el juego?

**Slice 1 of four.** The first sketch in this lineage that measures a **transition** rather than a state,
and the first to walk the seam between two screens. Opened under the 2026-09-20 handoff's new way of
working: *one scenario end to end, in baby steps.*

The developer's scope for the scenario, given at intake:

> *"Not 'crear a mano' yet. Let's focus for now on 'create with Bgg ID' and its possible status, but on
> tiny slices (baby steps) so we can move on the right direction."*

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/076-admin-create-visibility/index.html
node .planning/sketches/076-admin-create-visibility/verify.js     # 38/38
```

Use the **El paseo** strip in the tool panel: `1 · Agregar 342942`, then `2a · llegan los datos` or
`2b · falla`, and `↺` to start over. State is carried between steps — the row that changes is the row the
walk made, never a fixture reload. Switch **Variante** at any point; all three are renderings of the same
walk, so you can create once and compare where the game went.

---

## What was measured before anything was drawn

Walked on **071 as it stands**, at 375×740, tapping `+` → typing a real BGG id → `Agregar`:

```
snackbar                              "Juego agregado como borrador"   clears after 4000ms
BORRADORES                            1 -> 2                           collapsed by default (d8)
the new game's name anywhere in the rendered page      FALSE
```

**The game you just created is not on screen at all.** Not below the fold, not behind a caret — not in the
DOM. Four seconds later the snackbar goes and the page is identical to before you tapped `+`, except a
hidden counter reads 2 instead of 1.

### The cause is a collision between the redesign and what ships, not a sketch bug

- **The shipped app handles this.** `index.ex:105` — on a successful create it calls
  `push_patch(to: filter_path(:draft, ""))`, jumping the list to the `Borradores` **filter**, so the new
  game is the thing you are looking at.
- **Decision 1 deleted that filter.** Its own consequence line: *"061's four `estado` filter chips (Todos /
  Borradores / Publicados / Retirados) are gone."* They were deleted on a good measurement — with 434
  published, 1 draft and 0 retired they filter 435 into 435.
- **d8 replaced them with collapsed sections**, and nothing took over the job the filter was doing at the
  create moment.
- So **d3's promise is false exactly when it matters most**: *"the game added five minutes ago is the first
  row."* It is not a row at all.

No property-at-a-time round could have found this. It does not exist on any screen — it exists in the seam
between two of them, which is the whole argument for walking a scenario.

---

## Grounded in the shipped create path, which turned out to contradict the handoff

Verified against the codebase on 2026-09-20 before the fixtures were written. **`catalog.ex:325` is the
only game insert in the entire application**, and it goes through `Game.draft_changeset`:

```elixir
cast [:bgg_id] · validate_required([:bgg_id]) · validate_number greater_than: 0
put_change :status,            :draft
put_change :enrichment_status, "pending"
put_change :name,              "Juego #<bgg_id>"        # game.ex:159-166
```

Consequences the handoff had wrong, all corrected here:

| the handoff said | what the code says |
|---|---|
| `Crear a mano` "has never been drawn" | **it is drawn**, in 071 (`addSheet`, `index.html:798`), both paths working |
| by-name creation is "11% of the catalogue, not an edge case" | **by-name creation has never once happened.** The 41 `no_bgg_id` rows are legacy CSV-seed values (`seed/report.ex`); no live path writes them |
| two of the four steps are "blocked on codebase gaps" | sharper than that — **one whole branch is unbuilt.** `validate_required([:bgg_id])` means there is no by-name path and no route for one |
| `failed` collapses three causes "into one logged string" | the **log preserves** each reason via `inspect/1` (`enrich_game_worker.ex:94`). The collapse is into one **column value** (`"failed"`, `:97`) and one **UI string** (`"Error al traer datos de BGG."`, `index.ex:373` / `form.ex:263`) |

And one that makes the developer's scenario *more* real, not less: **`failed` is reachable on attempt 1.**
Missing credentials (`:65-68`) and BGG-has-no-such-item (`:78-80`) both write `"failed"` immediately; only
the third branch waits for `attempt >= max_attempts`.

In round 1 `Crear a mano` was therefore left **on screen and disabled**, in both places that offer it, on the
reasoning that deleting it would silently reverse d4 — the unrecorded-drift failure d47 was convened to
stop — while drawing it as working would make the sketch assert a feature that cannot ship.

> **Superseded by round 2:** the developer's call is to delete it, which makes the reversal an **explicit
> amendment** (decision 51) rather than a drift. See *Round 2* below.

---

## The three answers

One axis only: **where the just-created game becomes visible.** `addGame` builds a byte-identical row in all
three (check 3), and V2 and V3 paint it identically (check 4), so nothing here can be blamed on treatment.

| | where it becomes visible |
|---|---|
| **V1 Nada** | nowhere — 071 verbatim, the incumbent and the negative-test baseline |
| **V2 Se abre** | `Borradores` opens on create and the row is scrolled to |
| **V3 Arriba** | a `Recién agregado` block above every section, until the status resolves |

```
         en pantalla   y=        toques                  viaje    duplicado   rótulos
V1       NO            —         1 (abrir la sección)    0px      0           3
V2       sí            166-230   0                       79px     1           3
V3       sí            173-237   0                       0px      1           4
```

**V1 is provably the incumbent** — check 18 drives 071 and V1 through the same door and compares the
rendered list DOM: 28,076 characters, identical.

---

## What building it found

### V2's row was unreachable, and it was my drawing's fault, not V2's

First drawn with the scroll ceiling set to the pinned search (`--bar`), the row landed at **y121–185**:
visible, above the fold, 64px tall, every ordinary check green. `elementFromPoint` at its centre returned
**`.lhead | BORRADORES 2`**.

**d17 makes every section caption sticky**, so `Borradores`' own caption pins directly under the search and
sits on top of the row the scroll just delivered. Height, visibility and fold assertions all pass straight
through that — only a hit test sees it.

This would have been the **fourth** cost in this lineage charged to a variant that actually belonged to how
I drew it (074 had two, 075 had one). The ceiling is now measured from the pinned caption's own rect, and
**check 7 negative-tests it**: restore the `--bar`-only version and check 6 fails, naming `lhead tap`.

### V3's duplication is latent, not standing — the charge had to be corrected

Check 9 was written expecting V3 to render the row **twice** at rest, the charge 074 laid against the
duplicated back control. Measured, it renders **once**: `Borradores` is still collapsed, so its rows are not
in the DOM at all.

```
                 at rest    with Borradores open
V1               0          1
V2               1          1
V3               1          2
```

The duplication is **one tap away**, not standing. Recorded as measured rather than as expected.

### V3 says "this one failed" twice, and d24 is why

Found in a screenshot of the `falló` step. **d24** put `● 1 con error` on a collapsed caption precisely
because *"a failure inside a CLOSED section is otherwise invisible"* — but under V3 it is not invisible, it
is the row directly above. V2 does not pay this: its section is open, so d24's own rule suppresses the
caption warning.

```
how many times "this one failed" is said at rest
V1   0 rows + 1 caption = 1
V2   1 row  + 0 captions = 1
V3   1 row  + 1 caption  = 2
```

### A failed game was wearing a decorative initial

Same screenshot. 071's `cover()` falls through `thumb → .none (gap games) → a coloured letter tile`. The new
game is not `gap` — that flag means "imported without data", which this game is not — so a row whose
enrichment had just **died** rendered a cheerful green **"J"** beside the words *"Error al traer datos de
BGG"*. In the shipped app that game has no cover at all, exactly like the 49.

Fixed as a rule rather than a special case — **a cover exists only once enrichment has succeeded** — and
negative-tested (check 19): restore 071's predicate and the initial comes back.

### The negative test that could not fail, twice

Both times for the same reason, and it is worth writing down: **a top-level `const` or `let` in a classic
script is a lexical binding, not a property of `window`.** Assigning `window.noCover = …` from the harness
changed nothing while appearing to, and the first version of check 19 passed against an unmodified page.
The same trap ate the first draft of every probe in this file, which read `window.NEW` and got `undefined`,
so *every* geometry measurement was silently about `null`.

`noCover` is now a function **declaration** and `cover` calls it through `window`, so the guard is actually
falsifiable. 075 called this class "a guard that passed the thing it was written to reject"; this is the
same shape in a new place.

### Two harness measurements that were about the harness

The check proving V1 ≡ 071 was first written as a pixel diff and returned a confident, entirely false
number **twice**:

- **218,063 px** — 071 still carried `device kbd`. `openSheet` focuses its input on a 60ms timer that lands
  *after* a synchronous `closeSheet` removes the class, so the simulated keyboard reappeared on a closed
  sheet. The diff was measuring a keyboard.
- **203,651 px** — the sheet's focus call scrolls the **document**, and a screenshot `clip` is in page
  coordinates, so each page was captured from a different origin. The diff was measuring a scroll offset.

Replaced with a **rendered-DOM comparison**, which is what the claim was actually about and has neither
failure mode. That is the ninth and tenth time in this lineage a green-looking number described something
other than the page.

---

## What to look for

Open **V1** and tap `1 · Agregar 342942`. Watch the snackbar, then wait four seconds. Ask what on the page
now tells you the game exists. Then open `BORRADORES` and find it.

Then **V2**: same tap. The section opens and the row is under your thumb — but the page moved **79px** under
you to put it there.

Then **V3**: same tap, and the page does not move at all. Look at how many section labels the page now has,
and — after `2b · falla` — at how many times it tells you the same game failed.

---

## Open

- **PENDING REVIEW from the device.** No variant is recommended. V2 and V3 both answer the round's question
  outright and land the row within 7px of each other; they differ on what they charge for it — V2 moves the
  page, V3 adds a label and a latent duplicate.
- **d1 needs amending or upholding explicitly.** If V2 or V3 wins, the thing it is replacing is the filter
  d1 deleted, and that should be written down as an amendment rather than left as a fourth silent drift.
- **The snackbar's 4000ms is untouched.** Every variant still relies on it for the first four seconds. Whether
  the create moment deserves a persistent confirmation at all is not this round's question.
- **`Recién agregado` has no dismissal.** V3's block retires itself when the status resolves — but a `failed`
  game never resolves, so the block is permanent until the failure is fixed. Measured (check 15 covers only
  the success path), not designed.
- **The `.fresh` wash is not measured against the ground.** It is identical in V2 and V3 by construction, so
  it cannot bias the axis, but whether it reads in dark (`--color-accent-bg` `#33224D` on a dark ground) is
  unasked. d35's ΔE method is the tool if it matters.
- **The real app's `push_patch(:draft)` is untouched by any variant.** Whichever wins, the shipped behaviour
  and the redesign still disagree, and that is a code change owed either way.
- Everything in 075's Open list still stands, including both `TODO(palette)` items and the widened
  `no disabled buttons` conflict.


---

## Round 2 — what do you get when you tap `+`?

From the developer, pulling the round back to its first moment rather than choosing inside it:

> *"There are too many decisions that I need to do here. Go simple. What do I get when I tap +? I want to
> focus on that first."*

Answered by **reading the sheet**, not by proposing anything. Measured at 375×740, keyboard up:

```
y48    435 juegos en el club                     context
y69    Agregar juego                             title              ✕ at y35
y134   Número o link de BGG                      label
y159   [ 342942 ]                                input, 48px
y213   Traemos la tapa, los jugadores, la duración y el nivel.
       Queda como borrador hasta que lo publiques.                  hint, 36px
y266   [ Agregar ]                               outlined, full width, 44px
y326   ─── o ───                                 separator
y353   Crear a mano                              79px
                                                 sheet total: 435px
```

Three things were wrong with it. Two are fixed here; the third is recorded and deliberately left alone.

### 1. The hint promised a field enrichment never writes

*"Traemos la tapa, los jugadores, la duración **y el nivel**."*

`Enrichment.attrs_from_bgg_item/1` (`enrichment.ex:54-72`) returns year, min/max players, min/max playtime,
`playing_time`, `min_age`, description, `bgg_weight`, `bgg_rating`, `bgg_rank`, mechanics, themes, designers,
artists and publishers — plus the cover through `image_attrs/3`. **`weight_band` is not among them.** The
only things that ever write the club's `nivel` are `admin_changeset` (staff, by hand) and the band-audit
tool.

So the one screen whose job is to say *what you get for free* was promising the one value the member still
has to fill in themselves, two steps later, in the editor. `y el nivel` is deleted. Everything else the line
claims is true, and *"queda como borrador hasta que lo publiques"* is exactly `draft_changeset`'s
`put_change(:status, :draft)` (`game.ex:159`).

### 2. `Crear a mano` is deleted — and d4 is amended, not drifted

Round 1 left it on screen but disabled, reasoning that deleting it would silently reverse d4. The
developer's call makes it **explicit**, which is what d47 exists to require. Recorded as **decision 51**.

- **Unbuilt, not unfinished.** `catalog.ex:325` is the only game insert in the app and goes through
  `draft_changeset`, which does `validate_required([:bgg_id])` (`game.ex:157`). No by-name context function,
  no route, nothing to enable.
- **Never used.** The 41 `no_bgg_id` games are legacy CSV-seed rows (`seed/report.ex`) — the handoff's
  *"11% of the catalogue"* is a fact about the 2026-08-10 import, not a demand for this door.
- **Disabled, it cost 106px of 435 — 24%** — to say "no".

**d4 keeps** the 44px `+`, the BGG number-or-link field, and the edition prompt. What is withdrawn is only
the manual path, **in both places that offered it** — the sheet and the search's `Crear «…»` suggestion —
since leaving one live keeps the same door open through a different handle. The search keeps its other
create-aware answer (`Agregar desde BGG` for a pasted id); a name with no match now simply finds nothing,
which is the truth. Check 16 asserts all four together, so removing the manual path cannot quietly take the
rest with it.

### The result

```
y157   ✕                                         (page visible behind the sheet now)
y256   Número o link de BGG
y282   [ 342942 ]
y336   Traemos la tapa, los jugadores y la duración.
       Queda como borrador hasta que lo publiques.
y388   [ Agregar ]
                                                 sheet total: 313px   (435 → 313)
```

One field, one honest sentence, one button — and at 375×740 the page behind it is visible again.

### 3. Not fixed, recorded: `Agregar` is enabled with an empty field

Tap it with nothing and you get an error telling you what you should have typed. That is d44's
enabled/disabled question in miniature, and it was left alone rather than opened in a round called *go
simple*.

### A build note

`<!--` inside a JS template literal is a legal HTML-like line comment in a classic script, so it swallows the
rest of the line and breaks the literal. It broke this page **twice** — once in round 1 and once in round 2,
with the same symptom (`missing ) after argument list`, everything undefined). The function now carries a
warning above it.

## Open (round 2)

- **Round 1's question is still open** — V1 / V2 / V3 are untouched and still PENDING REVIEW.
- **`Agregar` with an empty field** — named above, not drawn.
- **The hint's voseo is unchanged.** *"hasta que lo publiques"* is tuteo-shaped; the rest of the admin uses
  voseo imperatives (`Pegá`, `Buscá`). Not touched, because it is a copy decision and this round was a
  factual correction.
- **This is a sketch change only.** The shipped `index.ex:269-285` add form and its hint still say whatever
  they say; `Crear a mano` never existed there to remove.


---

## Round 3 — the gate and the claim

> *"disable Agregar when the field is empty and the hint is simple, like we sync all the info from BGG."*

### The hint stops enumerating, and that is what makes it safe

d51 had to delete `y el nivel` from a **list** of fields — and a list has to be kept correct forever against
a changing `attrs_from_bgg_item/1`. The replacement is a **scoped general claim**:

```
Traemos toda la info de BGG. Queda como borrador hasta que lo publiques.      72 chars, one idea
```

It **cannot repeat d51's mistake by construction**: the club's `nivel` is not BGG info, so it falls outside
the claim rather than having to be remembered out of a list. Guarded as three properties rather than as a
string — scoped to BGG, silent about the nivel, and **under 90 characters**, so it cannot creep back into an
enumeration (check 16b).

### `Agregar` is dead until there is something to submit

This is the **first disabled `.obtn` in the project**, and **064 banned disabled buttons outright**, so it is
drawn deliberately rather than by default. The open 064 conflict is not resolved here — but this case is
argued rather than quietly folded into it:

> **d46 chose text paint for the top app bar because in the one dead situation the slot had NOTHING to
> offer** — a container there is "the whole silhouette of a live primary" with nothing behind it. Here the
> button is not dead, it is **waiting**: the input that makes it live is 44px above it and one tap away, and
> the container is what says where typing leads.

d47 settles the weight — 064's four roles stand for **content blocks**, and a form sheet is one — so it keeps
Principal's outline and drops both strokes to the muted stops.

Asserted in every direction so it cannot latch on (check 16d): **dead on open, live once you type, dead again
when cleared, dead on spaces alone**, 44px throughout.

**And disabling the empty case does not swallow the invalid case.** A non-empty value that does not parse
(*"mi juego favorito"*) still raises *"Pegá un número de BGG o el link del juego."* — a different failure that
still needs saying (check 16e).

### Measured on d35's axis, because a disabled state that dies in dark is d35's failure in a new place

Contrast ratio **cannot see hue** — d35 threw out a 1.15 contrast bar after the rejected pair scored 1.17 and
the accepted one 1.21, while the eye read one as obviously purple and the other as identical. Re-measured as
CIE76 **ΔE** those same pairs were 10.1 and 29.6, and a bar at 20 sat clear of both. Same bar here, both
channels, both themes (check 16d3):

| | label | borde |
|---|---|---|
| **claro** | 43,6 | 80,0 |
| **oscuro** | **28,3** | 81,6 |

All four clear it. **Recorded rather than smoothed over: the deadness is carried by different channels in the
two themes.** In light both do the work. In dark the **border does nearly all of it** while the label moves
only 28,3 and still sits at **6,9:1** on the ground — a perfectly comfortable reading colour, which is why by
eye the dark button looks more live than the light one does.

Same shape as d46's dark-only asymmetry, where W1's prominence came from its white label rather than its
fill. Not called a defect: both channels pass the bar, and the border is strongest exactly where the label is
weakest.

## Open (round 3)

- **Round 1's question is still open** — V1 / V2 / V3 untouched, still PENDING REVIEW.
- **064's `no disabled buttons` conflict is now touched in a second place.** It was already governed by
  neither rule after d46/d47 and widened from 1 dead slot to 4 by d50; this adds a fifth disabled control, in
  a different container, with its own argument. The rule still needs settling as a rule.
- **The dark label carries little of the deadness.** It passes, and the border covers it, but if the outline
  ever goes the label alone would not be enough.
- **The voseo of *"hasta que lo publiques"* is still unchanged** — a copy decision, not a factual one.


---

## Round 4 — the hint is deleted

> *"What if we remove the hint and put on the placeholder something like 'id example' para crear desde bgg?"*

**Measured before answering, because the line carried two different kinds of claim** — and a placeholder can
only hold one of them, since it vanishes on the first keystroke:

| | kind | can a placeholder carry it? |
|---|---|---|
| *"Traemos toda la info de BGG"* | a **format example** | yes — and `Número o link de BGG` + `342942` already do |
| *"Queda como borrador hasta que lo publiques"* | a **consequence** | no |

Counted across the walk, the second was **the only place the `+` path stated it before you commit**:

```
«borrador» antes de confirmar
  hoja del +     1   — y era SÓLO el hint (en el resto de la hoja: 0)
  la búsqueda    1   — "BGG 342942 · se agrega como borrador", en la fila de sugerencia
```

**The call was to delete it and replace nothing, and the cost is recorded rather than argued away:** the same
action now has **two doors, one of which warns**. After the tap there is only the 4000ms snackbar — and in V1
that is followed by a page with no trace of the game at all. Check 16b2 keeps the asymmetry visible so it
does not become folklore.

### The placeholder is left alone — and the real gap is the link form

`342942` is a clean example of the **number** form, and the label names both. What the create sheet lacks is
an example of the **link** form — while the *repair* sheet's identical field has one, because **d38** settled
a worked `…/boardgame/155426/…` → `155426` walkthrough and 075 built it (`index.html:980-983`).

**Two fields, one parser, one with an example and one without.** Named as its own slice rather than bolted on
here.

### The rhythm survived the removals, and that was checked

Deleting a block from the middle of a stack is how orphan gaps appear, and nothing else would notice — the
sheet would simply be 36px taller with a hole in it.

```
sh-top → label   16        label → campo     6     ← d36's pair, deliberately tighter
campo  → botón   16        botón → borde    16
```

### The sheet across four rounds

```
435px    R1   with the disabled `Crear a mano`  (106px of it — 24% — an unbuilt door)
313px    R2   door deleted, hint corrected
271px    R4   hint deleted
```

At 375×740 the page behind it is now visible to three rows.

## Open (round 4)

- **Round 1's question is still open** — V1 / V2 / V3 untouched, still PENDING REVIEW.
- **The `+`/search asymmetry is accepted, not fixed.** If it ever grates, the cheapest repair is the button
  (`Agregar como borrador`), which cannot vanish the way a placeholder does.
- **The link-form example is owed** — d38 settled it, the repair sheet has it, the create sheet does not.
- **064's `no disabled buttons` conflict** is unchanged from round 3 and still needs settling as a rule.


---

## Round 5 — the end of the sync speaks

> *"should return to list with a 'syncing' status to that specific row, and when the sync finish show a toast
> so user can navigate to that?"*

**Checked against the artefact before building, and the two halves had different status:**

| the proposal | status |
|---|---|
| a syncing status on that specific row | **already built** — d24 put `● Trayendo datos de BGG…` on the row's second line. What V1 denies is not the status, it is **the row** |
| a toast when the sync finishes | **not built anywhere.** `snack()` fires once, at create time. The mechanism exists (`snack(msg, action)` takes a button and lives 10000ms) and has never been called for this |

### It is a second axis, not a fourth variant

Rounds 1-4 asked **where the new row becomes visible**; this asks **whether the completion speaks**. They are
independent, so it is drawn as a toggle crossing every body-home — the shape d50 found. They are
**complementary, not substitutes**, and check 26 is the number:

```
durante la ESPERA (creado, sin terminar, el snack de creación ya se fue)
V1   la fila no se renderiza     la página no dice nada     el toast todavía no sonó
V2   «Trayendo datos de BGG…»    ✓
V3   «Trayendo datos de BGG…»    ✓
```

The toast covers the **moment** of completion and carries you to the game, so finding the row stops mattering
*then*. It says nothing about the **interval** before it, and it lasts 10s — miss it and the V1/V2/V3
question returns intact.

### Why this does not contradict d49

d49 refused a toast for the **broken state**: *"a toast is a container for **events**; this is **state**"* —
the condition has held since August across 49 games, and `snack()` clears itself.

**Enrichment finishing is genuinely an event.** It happens at a moment, it has a subject, and it is over.
d49's own reasoning **endorses** a toast here rather than forbidding one.

### What it says, and to whom

```
ok      "Ark Nova ya tiene sus datos"                     [ Ver ]  [✕]
falló   "No pudimos traer los datos de Juego #342942"     [ Ver ]  [✕]
```

**It names the game, and that is not decoration** — staff add in batches (d3's list is newest-first for
exactly that reason), so a bare *"listo"* would not say which one finished. On success the name is the one
that just arrived from BGG, which is itself the news; on failure the placeholder is all there is, because
nothing ever replaces it (check 12).

**Failure counts as finishing.** *"when the sync finish"* — a failure is a finish, and arguably the one most
worth being told about, since the row otherwise sits in a collapsed section saying *"Error al traer datos de
BGG"* to nobody.

**No toast for a game whose editor you are already reading** (check 25) — the announcement never lands on top
of its own subject.

### Measured

```
toast          y595–661   fold 673   clears the tab bar
«Ver»          44px, hit-tested, and opens the editor for THAT game (check 24)
off by default — check 23 negative-tests the silence
```

**What makes it likely to land:** queue concurrency is **1** with `attempt * 30` backoff, but a single create
on an empty queue runs immediately — one BGG round-trip — so on the happy path the wait is seconds. The
backoff only bites on retries, and **d39 already recorded that the job continues whether or not the page is
open**, so a toast can still be missed entirely.

### A defect in the round's own walk control

`↺` deleted the created game while `S.screen` was still `'editor'` — reached through the toast's own `Ver` —
so the next render called `renderEditor` on an id that no longer existed. **A reset that deletes what the
current screen is about has to change the screen too.**

## Open (round 5)

- **Round 1's axis is still open, and the toast does not close it** — check 26 is the reason. With the toast
  on, V1 is silent for the whole wait; whether that matters depends on how long the wait usually is.
- **A missed toast has no second chance.** 10s, then nothing — the row is the only durable record, which is
  the V1/V2/V3 question again.
- **The real app already broadcasts completion** (`{:game_enriched, game_id}`, `enrich_game_worker.ex:104-106`,
  consumed at `index.ex:196-198`) — the event reaches the list today and is used only to re-render the row.
  Whatever wins here is a small change on top of a signal that already exists.
