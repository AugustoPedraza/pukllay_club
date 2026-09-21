---
sketch: 078
name: admin-publish-gate
question: "El borrador está incompleto y vas a tocar Publicar — ¿quién te frena, y cómo?"
winner: null
tags: [admin, juegos, draft, publish, gate, lifecycle, d42, d47, d33, d49, 064, scenario-walk]
rounds: 1
status: PENDING REVIEW
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
node .planning/sketches/078-admin-publish-gate/verify.js     # 30/30
```

**El paseo**: `1 · Agregar 207330` → `2 · llegan los datos` → `3 · abrir el borrador` → `4 · poner el nivel`
→ `5 · Publicar`, and `↺`. Two extra levers, neither of them a variant: **Tipo** (juego base / expansión)
and **Nombre de BGG** (Hellas / el roto). Both exist to make a claim falsifiable — see below.

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
