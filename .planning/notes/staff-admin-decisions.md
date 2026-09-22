---
title: Staff admin — auth, ludoteca CRUD, shelf locations, curated Destacados, band audit
date: 2026-09-13
context: /gsd-explore "admin side: carousels, ludoteca management, physical storage convention"
---

# Staff admin decisions

## Priority

Admin is the **#1 priority**, ahead of Phase 2 (NL search + member auth) and Phase 3 (rules
oracle). Driven by both Saturday operations (finding/restoring games, keeping the catalog
correct) and a home page that can feature changing editorial content.

## Auth

- `phx.gen.auth` (Phoenix 1.8 generator — magic link by default) for **staff only**.
- **Invite-only**: no public registration; ~1 owner + up to 3 staff accounts created manually.
- A role flag (e.g. `role: :staff`) so Phase 2's future member accounts can reuse the same
  users table without gaining admin access.
- Keep the generator's long-lived "remember me" session — staff use phones on Saturdays, and
  magic links opened inside an email app's in-app browser can otherwise force frequent re-login.
- Hard dependency: production outbound email. GCP blocks outbound port 25, so an HTTP email API
  via a Swoosh adapter is needed (see todo `email-provider-and-dns`).
- This reverses Phase 4's original assumption ("admin role distinct from member magic-link
  auth", with member auth landing first in Phase 2) — staff auth now lands first.

## Ludoteca CRUD

Add / edit / remove games from an admin area. Today the catalog only enters via the CSV seed +
BGG enrichment pipeline.

## Physical storage convention

Room layout (as described by the club owner):

| Zone | Shelves | Rule |
|---|---|---|
| Main run | 4 long + 4 short, nearly continuous | Sorted by BGG weight, light → heavy |
| Cooperatives | separate | Pure co-ops pulled out of the weight run |
| Pocket | separate | Small-box games regardless of weight |
| Floor (5th level) | long + short | Loose: mostly 2-player, party, ~1.0 weight |

Decisions:
- **Store an explicit shelf-level location per game** (e.g. `L3`, `S2`, co-op, pocket, floor).
  No in-shelf position — "shelf number is enough".
- **No rules engine / auto-suggested location.** New acquisitions are rare (~2 games every 2–3
  months) and get squeezed in nearby, so derivation isn't worth building.
- The real cost is the **one-time assignment of ~400 existing games** → a mobile
  "walk the shelf" flow: pick a shelf, tap every game on it.
- Same data enables a **Saturday pick list sorted by shelf** (walking order).
- Open for planning: exact shelf identifiers, and how `units` > 1 copies are handled if copies
  are stored in different places.

## Carousels

- Long-term direction is **Option B** (every row managed: reorder/hide/rename, each row either
  hand-picked or automatic rule). Deferred — see seed `saturday-sessions-and-managed-carousels`.
- **Now:** only the first slot becomes curated — staff can rename it ("Destacados", "Novedades
  de Spiel", "Noche de fiesta", …) and hand-pick + order its games. The other rows (hashtag
  rows, weight-band rows, Recientemente añadidos) stay automatic as today
  (`Catalog.carousel_row_specs/0`).

## Band audit

Verified in code: a game's weight-band carousel row is **not** derived from BGG weight.
`weight_band` comes from the club CSV's hashtag columns
(`Seed.HashtagNormalizer.resolve_weight_band/1`), and `row_query("ingenio_estratega")` filters
on that stored value. The CSV was not perfectly curated, so e.g. expert-weight games can
appear in "Ingenio estratega".

Both `weight_band` and `bgg_weight` are already on `games`, so admin needs a **band audit
view**: games whose CSV band disagrees with their BGG weight, both values shown, fix or keep
(explicit override) per game. Band ↔ weight thresholds are to be decided during planning.

## Los 49 sin datos de BGG — se despublican, no se borran

**Decidido 2026-09-22.** Salió de la ronda 4 de la 075, cuando la pregunta pasó a ser si valía la
pena diseñar un remedio para los juegos rotos o si convenía sacarlos de encima.

Medido sobre `pukllay_club_dev` antes de decidir nada:

```
enrichment_status   status      count
bgg_missing         published       8
no_bgg_id           published      41
enriched            published     385
enriched            draft           1
```

**No son filas basura.** Unas 26 de las 41 `no_bgg_id` son **expansiones y promos** — `Wingspan
Europa (expa)`, `Root Expansion Los Rivereños`, `Kingdomino Age of Giants (Expansión)`, las dos de
`El Señor de los Anillos: Viajes por la Tierra Media`, `Catapul Feud (expa 1)` y `(expa 2)`… — cajas
que el club tiene y presta. El resto son juegos base con el nombre cargado a mano y sin matchear:
`ganges`, `obscurio`, `luxor`, `discover`, `union`, `bot factory`. Y el cliente ya soporta
vincularlas: `bgg_client.ex:62` dice textualmente que pedir los dos tipos permite agregar una
expansión por id de BGG, no sólo un juego base. Están **sin matchear**, no son inmatcheables.

**Y las 8 `bgg_missing` probablemente no estén rotas.** Las ocho llevan ids plausibles y del rango
correcto para su año de salida (Alma Mater 295777, Great Western Trail: Argentina 364312, Planet
252981, Alubari 259616). No se pudieron verificar: la API de BGG devuelve **401 Unauthorized** sin
credenciales. Y `bgg_missing` se asigna con `{:ok, []}` — una lista **vacía**, no un error
(`enrichment.ex:99`), así que un cambio de auth o de forma de la respuesta es una causa posible de
ocho falsos positivos. **Sin confirmar en ninguno de los dos sentidos.**

**La decisión:** los 49 pasan a `draft`. No se borran.

- La ludoteca pública deja de servir 49 fichas sin tapa (435 → 386).
- El editor no vuelve a mostrar un juego roto **publicado**, que es la simplificación pedida.
- Las 49 filas siguen existiendo y siguen siendo arreglables — el club no pierde el registro de
  tener esas cajas.
- Es reversible.

**Lo que hay que mirar aparte:** por qué 8 juegos con ids que parecen válidos quedaron marcados
`bgg_missing`. Si es el 401, se arreglan solos al re-enriquecer y no habría que haberlos tocado.

**Consecuencia de diseño, y es la parte que más simplifica:** un borrador **no se ve en la web**, así
que la frase que sostenía todo el sketch 075 — *«Se está viendo así en la web»* — pasa a ser **falsa**
y se va. Con ella se va también la colisión que la ronda 4 midió a 16px contra la nota de la 080, que
para un borrador ya dice *«No se ve en la web ni está en el estante.»*
