# Phase 1 — Plain-Spanish Vocabulary Draft (for user review)

**Drafted:** 2026-07-28 (plan-phase, Claude's Discretion per D-05 / D-07)
**Status:** DRAFT — awaiting user review. Implemented verbatim in
`lib/pukllay_club/catalog/vocabulary.ex`; edit this file and re-run the module's tests to change
the shipped copy.

This file is the single review surface for the three Claude-drafted / Claude-derived data sets that
CONTEXT.md flagged as "Claude's Discretion":

1. Weight-band descriptive copy (D-05)
2. `Peso_BGG` numeric tie-break thresholds for the D-20 conflict/missing fallback path
3. The mechanic/theme chip glossary (D-07)

---

## 1. Weight-band descriptive copy (D-05)

The three band **labels** are the club's own, verbatim, non-negotiable strings. Only the one-line
descriptor is Claude-drafted. Framing follows `.planning/research/FEATURES.md`: rules-explanation
time + decision depth, never a bare 1-5 number (CATALOG-05).

| Band key (DB `weight_band`) | Club hashtag (verbatim) | Display label | One-line descriptor (DRAFT) |
|---|---|---|---|
| `descubre_el_hobby` | `#DescubreElHobby` | Descubre el hobby | Reglas cortas que se explican en 5-10 minutos. Ideal si es tu primera vez. |
| `ingenio_estratega` | `#IngenioEstratega` | Ingenio estratega | Reglas de 15-20 minutos y decisiones pensando un par de jugadas por delante. |
| `nivel_experto` | `#NivelExperto` | Nivel experto | Reglas largas y decisiones profundas. Para mesas con experiencia. |

Descriptors are authored to a fixed short-line budget by design (UI-SPEC `long-text` row) — keep
any edit under ~90 characters so the card layout never needs truncation handling.

---

## 2. `Peso_BGG` tie-break thresholds (D-20 fallback path only)

**Scope of use — read this before editing.** These thresholds are used **only** when the CSV's own
weight hashtags fail to resolve a band, per 01-RESEARCH.md Pitfall 3's three-branch rule:

1. Exactly one weight hashtag true → use it. (377 / 434 games. Thresholds are **not** consulted.)
2. Zero or 2+ true, **and** `Peso_BGG` present → use the thresholds below. (31 games: 11 conflicts +
   20 of the 46 zero-hashtag rows.)
3. Neither resolves → `weight_band` stays `nil`, no badge rendered (same "omit missing chip" rule as
   D-18), and the row is written to the manual-review report. (26 games.)

| `Peso_BGG` range | Resulting band |
|---|---|
| `< 1.9` | `descubre_el_hobby` |
| `>= 1.9` and `<= 3.1` | `ingenio_estratega` |
| `> 3.1` | `nivel_experto` |

**How these were derived (empirical, from the real 434-row `ludoteca.csv`):** median-midpoint splits
of the `Peso_BGG` distribution across the 377 games that already carry one unambiguous hashtag.
Band medians are 1.385 / 2.46 / 3.79 → midpoints 1.92 and 3.13, rounded to 1.9 and 3.1.

**Known imperfection, accepted deliberately:** replaying these thresholds against those same 377
clean rows reproduces the club's own hashtag for **321 / 377 = 85.1%** of them. The bands genuinely
overlap in the source data (`#DescubreElHobby` spans 1.00-2.40; `#IngenioEstratega` spans 1.34-4.42;
`#NivelExperto` spans 2.26-4.63) — this is a soft heuristic applied to 31 games, not a clean
separator, and it never overrides an unambiguous club hashtag.

---

## 3. Mechanic / theme chip glossary (D-07)

Separate from the 6 editorial hashtags. Translates BGG's raw English `boardgamemechanic` /
`boardgamecategory` link values into short plain-Spanish chip labels (CATALOG-06). Curated, not
exhaustive — REQUIREMENTS.md explicitly excludes a full BGG-depth taxonomy.

Labels are 1-3 words by design (UI-SPEC `long-text` filter-facet row) so the drawer facet list and
the card chip row never need truncation.

### 3a. Mechanics (25 terms)

Derived from the actual `Mecanicas` distribution in `ludoteca.csv` (174 distinct values across 394
populated rows) — these 25 are the most frequent, covering the long-tail head.

| BGG mechanic (raw) | CSV occurrences | Chip label (DRAFT) |
|---|---|---|
| Set Collection | 128 | Colecciona sets |
| Hand Management | 120 | Gestión de mano |
| Open Drafting | 119 | Elige y pasa |
| End Game Bonuses | 96 | Bonus finales |
| Solo / Solitaire Game | 89 | Modo solitario |
| Tile Placement | 81 | Coloca losetas |
| Variable Set-up | 79 | Partida distinta |
| Dice Rolling | 79 | Tira dados |
| Variable Player Powers | 74 | Poderes únicos |
| Worker Placement | 61 | Coloca trabajadores |
| Contracts | 58 | Cumple encargos |
| Area Majority / Influence | 54 | Domina zonas |
| Cooperative Game | 51 | Juego cooperativo |
| Modular Board | 46 | Tablero variable |
| Take That | 39 | Ataques directos |
| Push Your Luck | 39 | Tienta la suerte |
| Pattern Building | 37 | Forma patrones |
| Race | 34 | Carrera |
| Deck, Bag, and Pool Building | 31 | Construye tu mazo |
| Simultaneous Action Selection | 31 | Todos a la vez |
| Grid Movement | 30 | Movimiento en casillas |
| Auction / Bidding | 19 | Subastas |
| Memory | 20 | Memoria |
| Real-Time | 17 | Contrarreloj |
| Deduction | 18 | Deducción |

### 3b. Themes / categories (22 terms) — provisional

`Categorias` is populated on only **1 / 434** CSV rows (D-17), so this list cannot be frequency-fitted
against real club data before the seed runs. It is drafted from BGG's standard
`boardgamecategory` vocabulary.

**Follow-up built into the plan (not left to chance):** `mix catalog.seed` emits
`priv/repo/seed_data/catalog_seed_report.md` listing every mechanic/category value observed across
the seeded games that is **not** covered by this glossary, ranked by frequency. Reviewing that list
and extending section 3a/3b is an explicit task in `01-06-PLAN.md` — the glossary is finalized
against real data, not guessed once.

| BGG category (raw) | Chip label (DRAFT) |
|---|---|
| Card Game | Juego de cartas |
| Party Game | Juego de fiesta |
| Fantasy | Fantasía |
| Science Fiction | Ciencia ficción |
| Animals | Animales |
| Economic | Economía |
| Adventure | Aventura |
| Medieval | Medieval |
| Ancient | Mundo antiguo |
| Nautical | Náutico |
| Farming | Granja |
| City Building | Construye ciudades |
| Deduction | Deducción |
| Horror | Terror |
| Miniatures | Miniaturas |
| Puzzle | Rompecabezas |
| Racing | Carreras |
| Space Exploration | Exploración espacial |
| Trains | Trenes |
| Wargame | Bélico |
| Word Game | Juego de palabras |
| Children's Game | Para peques |

### Uncovered-term behavior (locked)

A mechanic/category returned by BGG that is **not** in this glossary is **not** rendered as a chip
and is **not** offered as a filter facet. Raw English hobbyist jargon never reaches the UI — that is
the entire point of CATALOG-06 ("not raw hobbyist jargon") and of REQUIREMENTS.md's exclusion of a
BGG-depth taxonomy. The raw values still land in `bgg_payload` (D-17), so extending the glossary
later is a code-only change with no re-seed.

---

## 4. Editorial hashtags (D-06) — reference only, NOT Claude-drafted

Verbatim club strings. Listed here so the review pass sees the full displayed vocabulary in one
place. Do not rename or reframe (CONTEXT.md `<specifics>`).

| Hashtag | Meaning (club-provided) | Games in CSV |
|---|---|---|
| `#CreaConexiones` | Reglas simples, familiar / diversión garantizada | 61 |
| `#EquipoGanador` | Cooperativo | 54 |
| `#DuelosMemorables` | Solo 2 jugadores | 19 |

The 4 extra hashtag columns present in the CSV (`#InicioRápido`, `#GestionaTusRecursos`,
`#DominaElTablero`, `#ArteEnLaMesa`) are **ignored** for Phase 1 per D-16 — not seeded, not
displayed, not filterable.
