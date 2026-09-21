---
sketch: 078
name: admin-publish-gate
question: "r1 · ¿quién te frena al publicar un borrador incompleto? — r2 · ¿cuándo se vuelve real una edición?"
winner: null
tags: [admin, juegos, draft, publish, gate, lifecycle, d42, d47, d33, d49, 064, scenario-walk]
rounds: 4
status: r4 es el alcance vivo (hoja del borrador) · r2 RETIRADA por r4 · r1 y r3 quedan para la página del editor
---

# Sketch 078: la puerta de Publicar

**Slice 3 of four.** Picking the walk up exactly where 077 put it down: the game is created, the data has
arrived, and the sheet's `Ver` has taken you into the editor.

The developer's scope, given at intake:

> *"the data arrived, now I complete the club's own fields and publish — and this same pattern should carry
> editing an existing game, updating it, and unpublishing."*

## How to view

```
python3 -m http.server 8765          # from the repo root
open http://127.0.0.1:8765/.planning/sketches/078-admin-publish-gate/index.html
node .planning/sketches/078-admin-publish-gate/verify.js     # 57/59 — 35a/35b en rojo a propósito, ver abajo
```

**El paseo**: `1 · Agregar 207330` → `2 · llegan los datos` → `3 · abrir el borrador` → `4 · poner el nivel`
→ `5 · Publicar` → `· salir a la mitad ‹`, and `↺`.

Two axes, in this order: **Cuándo escribe** (A / B — ronda 2) and, under it, **La puerta** (G1 / G2 / G3 —
ronda 1, still open). Plus two levers that are *not* variants and exist only to make a claim falsifiable:
**Tipo** (juego base / expansión) and **Nombre de BGG** (Hellas / el roto).

---

## The measurement that reframed the round, before anything was drawn

The obvious gate — *"all six club rows filled"* — is **impossible**, and the live catalogue is what says so.
Counted against `pukllay_club_dev`, 434 published + 1 draft:

| campo | lo tienen | ¿puerta? |
|---|---|---|
| **estante** | **1 de 435** — y existe **1 solo estante** en toda la base | **no.** 433 publicados no pasarían su propia puerta |
| **copias** | 434 de 434, **todas = 1**, ninguna varía | **no** — es un *default que falta* |
| **nivel** | **408/408** base · **0/26** expansiones — correlación perfecta | **sí**, condicional a `is_expansion` |
| nombre | 434/434 | sí, pero **sólo el marcador es detectable** |

`units` has no DB default (`create_games.exs:20`), `enrichment_changeset` never casts it
(`game.ex:182-210`), and `admin_changeset` lets a blank through unvalidated (`game.ex:236-239`) — so **every
game the new flow creates has `copias = nil` forever.** The 434 that have 1 came from the CSV seed. That
makes copias a missing default, not a gate: the editor pre-fills 1 and the gate says nothing about it
(check 7).

### So the gate has exactly ONE condition — and for an expansion, none

```
juego base, enriquecido     falta el nivel          1 condición
expansión, enriquecido      nada                    0 condiciones      (check 9)
sin datos de BGG            no se publica           073:46, en las tres (check 10)
```

**That is not a thin round, it is the round's answer** — and it is the strongest thing in play about which
variant is proportionate, because G1 kills the page's primary action over one unset select.

---

## What was already drawn, and why it was narrower than the prose

```
075:798   if (CY === 'draft') return { label: 'Publicar', id: 'publish', dis: !hasData() };
075:751   const hasData = () => ST === 'enriched';
073:46    "THE PUBLISH RULE: the app must avoid publishing uncompleted games"
          ...a rule the sketch obeys, not a variant axis.
```

*"Uncompleted"* had been operationalised as **BGG answered**, and nothing else. `nivel`, `copias` and
`estante` were never in it. **That is the hole d42 names** (*"draft+complete → Publicar"*, with "complete"
existing nowhere in the code) and it is what this slice fills. The `hasData()` half is **kept verbatim and
is not a variant**.

**And the drawn gate is green on the only draft that exists.** Row 873 is `enrichment_status: "enriched"`,
so `dis: false` — `Publicar` is live on a draft with a garbage name, no nivel, no copias and no estante.

**075's lifecycle drawing is reused, not redesigned.** `Ciclo: Publicado / Borrador / Retirado` is a dot +
text in the editor's head (075:886), which is also the app-wide status rule. It is a **read-out** there,
never a control, and it stays one (check 13a). The tool panel's `Ciclo` buttons were a fixture switch in
075 and are not carried forward.

---

## The three answers

One axis: **who stops you, and how.** `missing()` is computed once and all three read the same array
(check 4), so nothing below is attributable to treatment.

| | |
|---|---|
| **G1 bloquea** | `Publicar` is dead until the draft is complete; the bar says what is missing |
| **G2 avisa** | `Publicar` is live; the tap opens a confirm that names what is missing and lets you through |
| **G3 la ficha** | no gate — the row carries its own hole and `Publicar` just works. **The do-nothing baseline**: exactly what `publish_game/1` does today, and what makes G1/G2 falsifiable |

**G2 and G3 render a byte-identical bar** (check 5a: same top, same height, same two buttons). They diverge
**only at the tap** — which is deliberate, and is why every G2/G3 assertion drives the tap rather than
reading the resting page.

```
                     la barra en reposo          al tocar Publicar
G1                   Publicar muerto + frase     nada
G2                   idéntica a G3               confirm que nombra el nivel -> «Publicar igual» publica
G3                   idéntica a G2 + punto       publica de una, sin decir nada
```

---

## What building it found

### A live, public-facing production bug, found while measuring the draft's name

The one real draft's name is not a placeholder — no name rule would catch it:

```
"HellasDutch/English/French/German editionEnglish/Korean edition"
```

**It is a one-character bug.** `bgg_client.ex:130` uses `~x".//name[@type='primary']/@value"so`. The `.//`
descends into `<versions>` (added when `versions=1` landed) and SweetXml's `s` modifier **concatenates every
match**. Reproduced byte-identically against the real row:

```
HOY   (.//): "HellasDutch/English/French/German editionEnglish/Korean edition"
FIX   (./ ): "Hellas"
BASE  id873: "HellasDutch/English/French/German editionEnglish/Korean edition"    MATCH: true
```

The comment at `bgg_client.ex:118-122` shows this exact hazard **was already found and fixed for `//item`**
when `versions=1` was added. `name` was missed — **and so were `publishers` and `artists`**, which use
`.//link[...]` and absorb every localized edition's publisher:

```
Codenames  172 editoriales (37 únicas)   ·   Similo Myths 178   ·   Takenoko 161
id 873     ["Playte", "White Goblin Games", "White Goblin Games", "Playte"]   ← duplicadas
```

`GameText.editorial_text/1` joins them all, so the public Codenames page renders **3.304 caracteres** of
*"editado por …"* right now. `mechanics`, `categories` and `designers` tested clean — version items carry no
such links.

**Deliberately NOT designed around.** A gate that rejected that name would be papering over a one-character
bug. The fixture's name is `Hellas`; the broken string is a **tool-panel toggle** whose only job is to make
one claim falsifiable — *the gate cannot tell a bad name from a good one* — asserted in check 8 rather than
left as prose. **Filed separately; it is not this round's question.**

### G1's gate was pure paint, and the harness found it

Check 11d drives step 5 of the walk, which calls `doPublish()` the way any other caller would. **The first
version of this page published a draft with no nivel while the button on screen was visibly dead.**

**That is not a sketch artefact — it is exactly the shipped situation.** `publish_game/1` →
`status_changeset/2` casts and validates only `:status` (`catalog.ex:490-494`, `game.ex:218-222`), so
whatever the editor renders, the transition itself has no opinion. **G1 is only a real gate if the refusal
lives in the function and is merely reflected in the button.** Checks 11d and 11e now assert both doors.

### Both status dots were invisible — and three checks were green

The first draft painted the `Borrador` dot and G3's `falta` dot with `var(--color-accent)`. **That name does
not exist in this theme** — `themes/default.css:22` records the rename to `--color-accent-bg` — so the
declaration resolved to nothing and both rendered as **8×8 transparent squares**. Checks 13a and 6a counted
the nodes, found them, and passed.

**That is the twelfth time in this lineage a green number described something other than the page.** Checks
6b and 13c now assert a **resolved, non-transparent colour**, not a node count. 075 had already hit the same
gap and defined its own `--warn`; that definition is reused verbatim.

### d55's toast buries the bar, and `Publicar` is not reachable

```
.savebar   z-index 19    top 608
.snack     z-index 30    609 → 661
elementFromPoint en el centro exacto de Publicar  ->  "snack show"
```

Reachable in the real app: the completion toast fires on the list, you open the game by tapping the **row**
rather than the toast's `Ver` (which would dismiss it), and d55's **10000ms** toast follows you into the
editor and sits on top of d42's action bar. 076's suppression rule only stops the toast *firing* while you
are already in the editor; **nothing dismisses one you navigate underneath.**

Same shape as 077's AV2 finding — **and worse here, because what is buried is a control, not an
announcement.** Check 16 measures it with a hit test and keeps it counted; `toEditor` clears the snackbar so
the rest of the suite measures the gate rather than the toast, and check 16 is what stops that convenience
from hiding the cost.

### The confirm was painted as a delete

The dialog is shared with 077, whose only caller was destructive, so `dlg-yes` carried danger red
unconditionally — and **`Publicar igual` came out in the same red the app uses for throwing something
away.** Publishing is the opposite of destructive: it is the thing the whole flow exists to reach. `danger`
now defaults to false, so a caller has to ask for red rather than inherit it (check 18, compared against the
app's own `--color-danger` rather than a hardcoded hex).

### G1's two costs, measured rather than argued

```
17    la frase vive en 145px de 375 — 39% — y se parte en 2 renglones
17b   el Publicar MUERTO ocupa 4203px² rellenos (opacidad .42)
      contra 3634px² de texto del Guardar VIVO   —   1,16x
```

The explanation has nowhere to live: `why` + `Guardar` + `Publicar` share one 375px row. And d42 gives the
primary the filled treatment while `disabled` only drops its opacity (075's `.btn[disabled]`), **so the
loudest element in G1's bar is the thing you cannot do.** G2 and G3 pay neither cost — their bar carries no
sentence at all.

**And this is the sixth disabled control against 064's outright ban** (076 round 3 was the fifth, in a
different container, with its own argument). The rule still needs settling as a rule.

---

## What to look for

Walk `1` → `2` → `3`, then **look at the bar before touching anything**. In G1 read the sentence and ask
whether 145px over two lines is where an explanation belongs. In G3 find the dot — it sits at the far right
of the Nivel row, about 300px from the words *"Sin nivel"* it is about.

Then tap `Publicar` in each. G2 is the only one that says anything at the moment it matters; G3 is the only
one where a game reaches the public catalogue with nothing having been said at all.

Then flip **Tipo → expansión** and watch the gate vanish in all three — and **Nombre de BGG → el roto** and
watch it *not* notice.

---

## Open

- **Round 1's question is open.** G1 / G2 / G3 are PENDING REVIEW; nothing is decided.
- **The `bgg_client.ex` xpath bug is filed, not fixed here.** `./` for `name`, `publishers` and `artists`;
  a backfill is needed for the 434 published rows' publisher/artist arrays and for row 873's name. **The
  3.304-character `editado por` is live on the public site right now.**
- **The toast/bar collision (check 16) is counted, not repaired.** The cheapest fix is dismissing the toast
  on navigation rather than reordering z-indices, since raising the bar above the toast would put a control
  over an announcement instead.
- **G3's dot is ~300px from the value it marks.** Putting it beside *"Sin nivel"* instead of at the row's
  trailing edge is untested, and would collide with D-19i's reserved trailing slot if it moved the other way.
- **Despublicar does not exist, and `Retirar` says the wrong thing.** `publish_game` → `:published`,
  `retire_game` → `:retired` (both unguarded), `restore_game` `:retired` → `:published` (guarded). There is
  no `:published` → `:draft` path anywhere; `status` defaults to `:published` (`game.ex:55`); and a retired
  game can be published directly, bypassing `restore`'s guard. 434 published, 1 draft, 0 retired — neither
  path has ever been used. Check 14 records the absence so **slice 079 starts from a number rather than from
  memory.** That is the developer's second scope item and it is *not* answered here.
- **`Nivel` is the gate's one condition, so the gate is only as good as the nivel vocabulary.** Whether a
  base game can honestly be published *without* one — the 26 expansions say the column is optional in
  general — is a club policy question this round assumes rather than settles.
- **Copias pre-filling to 1 is silent.** 434/434 say it is right, but a club that ever buys a second copy
  gets it wrong with nothing on screen having asked.
- **`Guardar` vs `Guardar cambios`.** The shipped form says `Guardar cambios` (`form.ex:314-319`); the bar
  here says `Guardar` to fit three things in 375px. Untested as a copy decision.
- Everything in 077's and 076's Open lists still stands.


---

# Ronda 2 — ¿cuándo se vuelve real una edición?

> *"each field can't have a `›` chevron since that is navigation. Also, before proceeding I'd like to define
> if here we need the same shell as the other pages (header and bottom nav) or a full-screen form with the
> CTA stacked at bottom. Also, could it be save and publish? How does this mark required fields vs not?"*

Four things. **Three were already on the record, and two of those I had drifted from.**

## The chevron, and the tint that went with it — my drift, settled twice

D-19i is explicit: *"a chevron means THIS ROW OPENS ANOTHER PAGE. Rows that act in place (show an answer,
open a sheet) have none."* **072 round 1 removed it for exactly this reason (d34), and round 2 then removed
the `⌄` that replaced it too — landing on no glyph at all.** What says "editable" instead is d37's anatomy:
label prominent, value subordinate, and the value carries `--val`, *"a tint that marks the datum you are
about to change."*

Round 1 added **six chevrons one sketch after 077 used D-19i to take one away**, and dropped the tint that
was doing the work the chevron was wrongly hired for. Both restored, asserted in both directions (check 19).

**Reading a decision's prose instead of its artefact is the failure mode 072 named by name.** This is it
again, by me.

## The shell was decided in 074 — and round 1 ignored that too

```
d43/d44 · N1 + W3 texto      .hdr + .pbar + .back  ->  UN top app bar de 56px
                             ‹ · título (aparece al scrollear) · UN CTA
```

> *"I have the 'back' chevron for leave this page. So not need of main menu."* — el desarrollador, en 074

074 measured HOY's chrome at **97px before the game's name**, with the back affordance existing **twice**
and neither hittable at the same scroll offset. Round 1 built the editor on exactly that, plus a bottom
savebar. **Now corrected**, and the developer settled the remaining half this round:

> *"this is a destination page where I need the user to leave because saved/published or go back with the `‹`"*

So the editor is a **full-screen destination**: no wordmark, no `.pbar`, **no bottom tab bar**, one back
control (check 20).

## "Could it be save and publish?" — it already is, and that is what decides the shell

```
form.ex:84-92    handle_event("save") -> update_game_admin(...) -> after_save(_action)
form.ex:165-177  after_save("publish") -> Catalog.publish_game(...)
form.ex:311-320  Publicar y Guardar cambios son AMBOS submitters del MISMO form
```

**`Publicar` has always saved first.** The two buttons were never save-vs-publish — they are *"guardar y
publicar"* vs *"guardar y seguir después"*.

But `Guardar` cannot simply be deleted, and that was measured before the round was framed:

```
form.ex:269   <.form phx-change="validate" phx-submit="save">   validate NO persiste
075:750       dirty() = CLUB_KEYS.some(k => G[k] !== START[k])  las hojas preparan, la barra confirma
```

In both the app and the prior sketch, **`Guardar` is the only thing that writes.** So the axis is not *how
many buttons* — it is **when the write happens**, and the buttons fall out of it. The first framing of this
round had it backwards and the developer was right to stop it.

| | al elegir en la hoja | botones | estado sucio | salir con `‹` |
|---|---|---|---|---|
| **A · la hoja guarda** | se escribe ya | `Publicar`, en la barra de 074 | **no existe** | sale y ya |
| **B · la hoja prepara** | queda pendiente | `Guardar` + `Publicar`, apilados al pie | sí | pregunta |

**What makes A plausible is d33, which is already decided**: every value is a row that opens a sheet, and a
sheet's pick is a discrete, complete choice with a tick. *That is already a commit gesture.* A is the change
that lets it commit — not a new interaction, the same one meaning what it looks like.

## What the three measurements said

### 1 · Los toques son IGUALES — y esa era la pregunta equivocada

```
24 · completar y publicar:   A 3 toques · B 3 toques   (escrituras: A 1 · B 1)
```

Because `Publicar` already saves, the publish path costs the same in both. **The framing implied A would be
cheaper and it is not.** Where they differ is everywhere else.

### 2 · El pliegue: A no lo toca nunca; en B la puerta se come una fila

```
23a · A   6/6 filas enteras con cualquier puerta      (piso 740px)
23b · B   6/6 con G3 (piso 611 — zafa por 3px) · 5/6 con G1 (piso 585)
23c · en reposo B ofrece 2 de 2 botones MUERTOS en 155px de pie; A ofrece 1 de 1, de 36px
```

**23c was found in a screenshot, not in a number.** On a fresh draft `Publicar` is blocked and `Guardar` is
dead because nothing is staged — so the heaviest thing on the page is two controls you cannot press. 064
banned disabled buttons outright; round 1 counted the sixth, and this is **the seventh, in the same view as
the sixth.**

### 3 · Salir a la mitad — el único lugar donde de verdad difieren

```
25 · A   no pregunta, y el nivel QUEDA escrito
     B   pregunta, y al salir el nivel SE PIERDE
```

## The cross-round finding: G1 is only buildable in B

074's bar is `‹ · título · CTA`. **There is no slot for a sentence**, so a blocked `Publicar` in A cannot say
why (check 22). Round 1 and round 2 are therefore **not independent**, and round 1's checks are pinned to B
so they keep measuring what they were written to measure.

And the corollary, measured: **moving the CTA into 074's bar fixes round 1's toast collision.**

```
16b · el toast tapa el Publicar de B (y=624) · NO alcanza al de A (y=10)
```

## Required vs optional — nearly free here, and unanswered on purpose

The measured gate has **one** required field. Marking "required" means marking one row of six, which is a
different problem from a form where half are mandatory — so it is **not drawn this round**. What exists is
G3's dot on the row the gate names (check 6), which marks *unmet*, not *required*: it disappears once the
nivel is set, and never appears on an expansion. **Whether a draft should mark required fields up front, at
rest, before you have failed anything, is its own question.**

## Five instances of one trap, in one file

`display` set on a **class** out-specifies the UA stylesheet's `[hidden] { display: none }`, so
`el.hidden = true` hides nothing. 074 lost a round to it. This file hit it **five times**: `.tbar`, `.hdr`,
`.tabs`, `.pbar`, and then `.savebar` + `.stack` — the last two found in a screenshot of mode A as **two
stray bordered strips** under a form that is supposed to have nothing below it, **and they made check 23
lie**: it computed A's floor as `stack.hidden ? 740 : …`, reading the attribute while the real floor was
~715.

The rule is now stated once, in the stylesheet: **any class that sets `display` carries its own `[hidden]`
companion, and any check that asks whether something is on screen uses `offsetParent`, never `.hidden`.**
Check 20 is negative-tested by forcing the display back.

## Open (ronda 2)

- **Both rounds are open.** G1/G2/G3 and A/B are all PENDING REVIEW.
- **A's real cost is that there is no "descartar todo".** Per field the undo is reopening the sheet and
  picking the old value; there is no bulk edit to abandon on a six-row form. Untested against a longer form.
- **A writes six times instead of once.** Fine on a draft, and each write is one column — but it is six
  round-trips where B has one, and that was not measured under a slow connection.
- **A on a PUBLISHED game is not drawn.** Every pick writing straight to a live catalogue row is a different
  proposition from writing to a draft, and this round only walked the draft.
- **074's rider is unbuilt in A by construction** — *"confirm on back when there is unsaved data"* has
  nothing to confirm. That is a feature of A, but it means the rider only ever applies to B.
- **`Guardar` vs `Guardar cambios`** — unchanged from round 1, still untested as copy.


---

# Ronda 3 — ¿dónde se marca que un campo es requerido?

> *"I like B. But the rest of 'data', it must mark fields as required. The toast should show like 'publicado'
> and allow the user jump to admin the sections of the web so the new game can be managed."*

**B queda decidida** (la hoja prepara, `Guardar` confirma; par apilado al pie). A sigue en la página y
navegable. Lo que sigue son las dos cosas que agregaste — la marca de requerido acá, el toast en la 079.

## La medición que le dio una razón al requisito — y corrigió mi propio fixture

```
sections.rule_value    "Descubre el hobby"  -> descubre_el_hobby    179 publicados
                       "Ingenio estratega"  -> ingenio_estratega    183
                       "Nivel experto"      -> nivel_experto         46
                       (ninguna)                                     26   ← las expansiones
```

**El nivel ES la sección.** Cada sección `weight_band` mapea 1:1 contra un valor de banda, así que poner el
nivel es lo que **coloca el juego en una de las tres filas que organizan el catálogo público**. Sin él, el
juego se publica y no entra en ninguna.

Eso convierte la única condición de la puerta de una preferencia en **una consecuencia**, y por lo tanto en
algo decible. 075 ya lo sabía y lo había escrito — *"Sin nivel · No aparece en ninguna fila por nivel"* —
pero no podía decir en cuál, porque el mapeo no estaba medido.

**Y corrigió el fixture de la ronda 1**, que había copiado de 075 **cuatro bandas inventadas**
(`intro/medio/estratega/experto`). Ninguno de esos valores existe. `Vocabulary.@weight_bands`
(`vocabulary.ex:24-40`) y la columna viva coinciden en **tres**, con estas etiquetas y descriptores
(check 30). Tercera deriva de fixture en este sketch, y la tercera que salió de mirar los datos y no el
sketch anterior.

## Lo que ya existe, medido antes de proponer nada

**El editor YA administra secciones.** `form.ex:289-294` renderiza un fieldset `Secciones` con un checkbox
por cada sección `:manual`, y `apply_section_ids/3` las guarda apenas se guarda el juego. Las cuatro reales:

```
Destacados del club   featured, tope 20 (D-26)    7 juegos
Crea conexiones                                  61
Equipo ganador                                   54
Duelos memorables                                19
```

Y **publicar ya mete el juego en dos secciones automáticas**: la de su nivel, y *Recientemente añadidos*
(`kind: :recent`). Nadie tiene que hacer nada para eso.

**Así que "saltar a administrar las secciones" es la misma forma que 076 ronda 5 y 077**: la mitad ya está
construida, y lo que queda genuinamente abierto es **cuál de los dos lugares** — el fieldset del editor o la
pestaña Web — y **si hace falta un salto** cuando el juego ya quedó en dos filas solo. Eso es la ronda 4, no
ésta.

## Las tres respuestas

| | |
|---|---|
| **R1 · en la etiqueta** | `Nivel` lleva una marca chica *para publicar* |
| **R2 · en el valor** | el valor vacío deja de decir *Sin nivel* y dice qué pasa: *Falta — sin esto no aparece en ninguna fila de la web* |
| **R3 · sólo en el pie** | la línea base: lo que B ya hace, y lo que hace falsificables a R1 y R2 |

**Requerido acá significa requerido PARA PUBLICAR, nunca para guardar** — y en B esa distinción es real: se
puede guardar un borrador sin nivel y volver. Una marca que dijera *"obligatorio"* sería mentira sobre lo
que la página deja hacer. Check 27 lo asserta en las dos variantes **y además guarda de verdad con el campo
vacío**, para que el recorte sea un hecho y no una afirmación.

## Lo que midió

### Marcar en la ficha lo dice en dos lugares — siempre

```
26a   R3+G1   el pie                    1 lugar
      R3+G3   el punto de la fila       1 lugar
26b   R1+G1 / R2+G1                     2 lugares
26c   R1+G3 / R2+G3                     2 lugares
```

Es la forma que 077 contó cuando la fila y la hoja decían *"Trayendo datos de BGG"* a 310px una de otra. Acá
la distancia es ~580px entre *"Falta — sin esto…"* en la fila y *"Falta el nivel para publicarlo"* en el
pie, **con la misma palabra abriendo las dos**.

### R2 desaparece cuando el campo se llena; R1 no

```
28   con el nivel puesto   R1 sigue marcando el campo   ·   R2 ya no dice nada
```

**Requerido y faltante son dos afirmaciones distintas.** R1 va en la etiqueta, así que sigue diciendo que el
campo importa. R2 va en el valor vacío, así que sólo puede hablar mientras falta — y el punto de G3 hace
exactamente lo mismo, correctamente, porque sólo era sobre el hueco. **R2 no es una marca de requerido: es
una segunda marca de faltante, más elocuente.**

### Y una defensa que hay que hacer siempre

```
29   en una expansión no se marca nada, en las tres
```

## Un defecto real en B, encontrado por el check 27save

El stepper de `Copias` es el único control que edita **dentro** de la hoja en vez de elegir y cerrar. Mutaba
`units` y volvía, y **nada repintaba el pie**: `Guardar` quedaba MUERTO habiendo cambios sin guardar, y
cerrar la hoja tampoco lo despertaba porque `closeSheet` no renderizaba. **Una edición preparada que el botón
de confirmar no puede ver es el modelo entero de B fallando en silencio.**

Arreglado en las dos mitades — el stepper renderiza, y `closeSheet` también, para que ningún control futuro
dentro de una hoja lo reintroduzca por olvido. Y el arreglo **volvió a entrar por una puerta vieja**: ↺
borra el juego del walk y recién después limpia `S.editing`, así que renderizar por id solo corría
`renderEditor` contra una fila eliminada — el mismo peligro que 076 ya había registrado. Ahora se guarda
contra la fila, no contra el id.

## Open (ronda 3)

- **R1 / R2 / R3 están abiertas, y la ronda 1 también.**
- **El toast y el salto a secciones son la ronda 4** — con lo medido arriba: el editor ya tiene el fieldset,
  publicar ya mete el juego en dos secciones automáticas, y Destacados tiene 7 de 20.
- **R1 y R2 no son excluyentes con la puerta, son acumulativas.** Si se elige R3, la ficha en reposo no dice
  nada sobre requisitos y todo el peso queda en el pie — que es donde G1/G2/G3 todavía está sin decidir.
- **Ninguna variante marca los campos NO requeridos.** *"the rest of data"* puede querer decir lo contrario
  de lo que dibujé: marcar los opcionales en vez de el requerido. Con 5 de 6 opcionales eso sería marcar
  cinco filas, que la convención habitual desaconseja — pero no está medido acá.
- **`Copias` sigue pre-cargándose en 1 en silencio** (ronda 1), y ahora convive con una marca de requerido
  en otra fila, lo cual podría leerse como que copias no importa.


---

# Ronda 4 — la hoja del borrador

> *"This is becoming too hard. The main goal of a borrador is to ASK the user to fill the missing data and
> publish. Only publish. Maybe they can cancel that with the chevron. (...) what if we show that as part of a
> bottom sheet from the list, asking to verify the correct weight assignment and some basic information like
> name, image, description and if or isn't an expansion. (...) after publish, go back to the list (with the
> correct scrolling) and highlight the created one."*

**Tenía razón: lo compliqué de más.** Tres rondas discutiendo una página de editor para un borrador, cuando
el borrador no es una página que se edita — **es una pregunta**: completá esto y publicá.

**Esto retira la ronda 2.** B existía para sostener un `Guardar` que acaba de ser eliminado: sin segundo
botón no hay par apilado, ni estado sucio, ni confirmar-al-salir. Escrito, no derivado (d47).
**Lo que NO se retira:** la página del editor (072-075) sigue viva para corregir un juego **ya publicado**,
con la barra de 074 y el spine de d33 — decisión del desarrollador, explícita. Las rondas 1 y 3 siguen
abiertas **para esa superficie**, y el panel las mantiene navegables.

**Y no hay conflicto con d33.** d37 ya delimitó su propio alcance: *"los campos dentro de una hoja no son
este patrón: una vez abierta la hoja ya estás editando"*. Un formulario clásico dentro de una hoja cae
justo afuera del spine.

## Lo que se midió antes de dibujar

### La condición para abrir la hoja ya existe — y yo había afirmado lo contrario

El desarrollador avisó que pasar de borrador a la hoja depende del trabajo asíncrono: BGG + **procesamiento
de imagen** + **traducción**. Lo di por medio construido. **Estaba mal, y chequearlo lo corrigió:**

```
enrichment.ex:106   image_attrs(...)              baja la tapa, la sube a R2, genera la OG card 1200x630
enrichment.ex:113   maybe_translate_description   traduce al español con Gemini (InstructorLite)
enrich/2                                          las TRES cosas en una sola llamada
enrichment_status = "enriched"                    la única señal de que las tres terminaron
```

(`mix catalog.translate_descriptions` es el backfill de las filas viejas, no el camino vivo. Confundirlas me
hizo afirmar que la traducción no era automática.) La hoja se abre con una condición que **ya existe, ya se
emite** (`enrich_game_worker:104-106`) y a la que **la lista ya está suscripta** (`index.ex:41-43`).

### La imagen: se muestra para verificar, no para editar

`gallery_urls` está **vacío en los 435 juegos, a propósito**: `GalleryBackfill` (01.3.1, D-07) es un
*limpiador*, no un llenador. Su propio moduledoc dice que `bgg_payload["versions"]` conserva los URLs
fuente, así que **es recomputable sin refetch** — pero ofrecer un selector de imágenes significa **revertir
esa decisión**, no construir una pantalla. Mientras tanto `cover_url` sí está y se sirve desde R2, así que la
hoja muestra la tapa real (la de la fila 873) para que la verifiques.

### Las expansiones: la regla es verdad, pero el código sólo la garantiza a medias

> *"an expansion of a game never will be listed on any web section for now"*

```
section_query(:recent)       where: g.is_expansion == false     ← garantizado en código
section_query(:weight_band)  where: g.weight_band == ^band      ← NO excluye expansiones
manual                       sin filtro                          ← 0 de 26, por costumbre
```

**Se sostiene sólo porque las 26 expansiones tienen el nivel vacío.** Y acá está el riesgo concreto de esta
misma ronda: pediste *validar el weight band* — si el formulario le exigiera nivel a una expansión, **esa
expansión aparecería en una fila de la web**, rompiendo la regla que acabás de enunciar. Por eso el switch
apaga el bloque entero (check 33a) y publica sin nivel (33b). **Y el código necesita el guard**
`and g.is_expansion == false` en `section_query(:weight_band)`: está anotado abajo, no dibujado.

### El resaltado al volver no es nuevo

`076` (d55, d18-enmendada) ya decidió `.row.fresh` + `scrollNewIntoView()` **para el momento de crear**.
Esto es la misma conducta repetida en el momento de **publicar** — medido antes de proponerla, no inventado.

## El único eje: cómo habla la validación del nivel

El formulario lo diste vos, así que no se ofrece como variantes. Lo abierto es sólo esto:

| | |
|---|---|
| **P1 · al tocar Publicar** | el botón siempre vive; al tocar, no publica, aparece el error bajo el bloque y el foco va al nivel |
| **P2 · botón muerto** | `Publicar` nace deshabilitado y revive al elegir; nunca hay mensaje de error |

```
34a · P1 · el botón vive · al tocar NO publica · el error dice la consecuencia · el foco va al nivel
34b · P2 · nace muerto y sin mensaje · revive al elegir
31  · la hoja se abre sobre la LISTA, con UN solo botón, y la fila no lleva chevron (D-19i)
32  · escribir y cancelar con el ✕ no deja rastro: nada se escribe hasta Publicar
33  · expansión: borra el nivel, esconde el bloque, publica igual, y la fila lleva el pill informativo
```

El error de P1 dice **la consecuencia, no la regla**: *"Elegí un nivel: sin esto el juego no aparece en
ninguna fila de la web."* Eso sólo se pudo escribir porque la ronda 3 midió que `sections.rule_value` mapea
cada sección de banda 1:1 contra un valor de nivel.

## Los checks 35a y 35b quedan EN ROJO a propósito

```
aislado, página recién cargada     y = 165, alcanzable, con captura (R4-lista.png) — reproducido 3 veces
dentro de esta suite               y = -587 / -467 / -293 · MISMO scrollTop (184)
                                   · MISMO G.length (436, verificado: no se acumulan juegos)
                                   · MISMAS secciones (Sin datos:0 | Borradores:1 | Juegos del club:50)
```

**Dos hipótesis descartadas con medición**, no con argumentos: contaminación por haber pasado antes por el
editor (35b la aísla y sigue fallando) y acumulación del fixture (`G` no crece). **La causa no se encontró.**

**No se silencia ni se "arregla" con un scroll diferido.** El resaltado es la única pista que queda después
de publicar — pediste *"a subtle affordance of the recently created game"* — así que una pista fuera de
pantalla es el hallazgo entero de la ronda fallando en silencio. Y un verde comprado con un
`requestAnimationFrame` sin entender la causa sería exactamente la clase de verde que este linaje ya contó
doce veces. **Queda rojo hasta que se entienda.**

## Open (ronda 4)

- **P1 / P2 sin decidir.**
- **35a/35b sin explicar** — es lo primero a resolver antes de construir nada de esto.
- **El guard que falta en el código:** `and g.is_expansion == false` en `section_query(:weight_band)`
  (`catalog.ex:851`). Sin él, la regla de las expansiones depende de que nadie les ponga nivel.
- **El selector de imagen es una reversión, no una pantalla.** Si lo querés, la decisión a revertir es
  01.3.1/D-07, y los URLs fuente siguen en `bgg_payload["versions"]`.
- **El resaltado puede ser demasiado fuerte para "subtle"** — es el lavado completo de 076, heredado tal
  cual. No se tocó porque estaba decidido, pero *sutil* quizás pida menos.
- **La hoja no dice nada de copias ni estante**, a propósito: copias se pre-carga en 1 (ronda 1) y estante
  lo tienen 1 de 435. Si alguna vez importan, la hoja es el lugar equivocado.
- **El bug de `bgg_client.ex` sigue sin archivar** (ronda 1) — `./` en `name`, `publishers`, `artists`, y la
  página pública de Codenames sigue mostrando 3.304 caracteres de *"editado por"*.
- Las rondas 1 y 3 siguen abiertas **para la página del editor**, no para esta hoja.
