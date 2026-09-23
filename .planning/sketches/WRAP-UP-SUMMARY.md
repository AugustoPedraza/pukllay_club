# Sketch Wrap-Up Summary

**Date:** 2026-09-22
**Sketches processed:** 29 (052–080)
**Design areas:** 9 — 7 new, 2 folded into existing areas
**Skill output:** `./.claude/skills/sketch-findings-pukllay_club/`

This is the largest wrap-up so far, and the first to cover the **staff admin** surface. Everything
wrapped before this (001–051) was the public site; 059 onward is a second application living in the
same Phoenix app, with its own shell, its own button system and its own composition rules.

## Included Sketches

| # | Name | Winner | Design Area |
|---|------|--------|-------------|
| 053 | about-mobile-cta-bar-footer-clearance | D (refined) — hero-synced full-width bar, reserved footer clearance | About — Mobile CTA |
| 054 | dark-mode-color-composition | A (Lifted Ladder) + W2 (Deep Jewel) | Dark Mode & Palette |
| 055 | dark-primary-as-text-contrast-fix | A2 | Dark Mode & Palette |
| 056 | dark-cta-contrast-fix | B | Dark Mode & Palette |
| 057 | og-fallback-share-card | B — ramp-800 + isologo-dark + wordmark + tagline | Share Card |
| 058 | dark-purple-hue | C | Dark Mode & Palette |
| 059 | admin-shell | C2 (final, single design) | Admin — Shell & Navigation |
| 060 | admin-panel-entries | B layout — centered 2-col boxes, no chevron | Admin — Shell & Navigation |
| 062 | admin-list-rows | B — Modo ordenar + hojas | Admin — Shell & Navigation |
| 064 | admin-button-system | S3 (Contorno), tuned in round 2 | Admin — Button System |
| 065 | admin-composition | composition, 10 rounds, 11 drift bugs | Admin — Shell & Navigation |
| 069 | estantes-ubicar | 68 developer decisions, no variants | Admin — Estantes |
| 070 | web-destacados | one page — destacada inline + Otras filas (d1–20) | Admin — Web / Destacados |
| 071 | admin-juegos | single, refined across decisions 1–17 | Admin — Juegos |
| 072 | admin-game-editor | A (spine) + D+B (affordance) | Admin — Game Editor |
| 073 | admin-bgg-state | D · D2 · F2 (r2 later superseded) | Admin — Game Editor |
| 074 | admin-header | N1 · W3 Texto (d43–44) | Admin — Game Editor |
| 076 | admin-create-visibility | V2 Se abre + Toast «Ver» | Admin — Juegos |
| 077 | admin-pending-sheet | AV1 sólo la hoja | Admin — Juegos |
| 078 | admin-publish-gate | P2 · la hoja del borrador, un solo CTA | Admin — Game Editor |
| 079 | admin-lifecycle | el ⋮ arriba · tinte + lápiz · hoja · franja de estado | Admin — Game Editor |
| 080 | admin-guardar-fijo | `Guardar` fijo al pie · divisor · ancho natural a la derecha | Admin — Game Editor |

## Superseded and Closed — folded in as "What to Avoid"

Kept as anti-patterns rather than dropped, so a future build does not re-propose a shape that was
already tried and rejected.

| # | Name | Why it is not the target |
|---|------|--------------------------|
| 052 | about-mobile-cta-alternatives | Winner B (content-sized floating pill) **rejected on real-device UAT** — it overlays the footer's "Powered by BGG" line at the real scrolled page bottom. 053 replaces it. |
| 061 | admin-juegos-page | Predates the 01.8.2 restart. 071 states it is "the starting point to question, not the target" — its estado chips filter 435 games into 435. |
| 063 | admin-game-editor | Same restart. Superseded by the 072→080 editor chain (d33's spine replaces the long form). |
| 066 | estante-focus | 069 states it replaces everything 065-R8 and 066 drew for estantes. |
| 067 | estante-read | Same restart; check `admin-estantes.md` for which of its cover/clamp findings 069 kept. |
| 068 | locate-box | `winner: null`. The developer's response was *"let's start over all of this UI"* — which is what 069 is. |
| 075 | admin-remedy-dirty | **Closed with no winner, 2026-09-22.** Four rounds, 26/26, and the question dissolved twice — see below. |

## Two restarts run through this batch

Neither is visible from the sketch numbers, and both were verified against the artefacts rather than
inferred from names:

1. **The estantes restart (068 → 069).** 069's README states outright that it replaces 065-R8 and
   066. What survived: search answers *where it is*, the order of games IS the shelf order,
   neighbours are one tap away, and "Asignar" is deleted.
2. **The 01.8.2 admin restart (061/063 → 071/072…).** 071 states 061 and 063 "predate the estante
   restart and the Web redesign, so they are the starting point to question, not the target."

## Sketch 075 — closed, not answered

Worth recording because it is the only sketch here that produced no design and still changed the
product. It asked where the BGG remedy (`Vincular` / `Corregir ID`) lives while the editor is dirty.
The question stopped existing twice:

- **079 and 080 removed the CTA slot** the question depended on. Round 4 re-measured on the decided
  chrome and found the remedy was not demoted but **absent** — reachable 0 of 8 while the d38
  accusation *«Se está viendo así en la web»* was present word for word. That is the configuration
  round 3's own guard had declared must not ship.
- **Then the scenario itself was removed.** Asked to delete the games with no/bad BGG id, the dev-DB
  query contradicted the premise: ~26 of the 41 `no_bgg_id` are **expansions and promos the club
  owns and lends**, and the 8 `bgg_missing` carry plausible ids that could not be verified because
  BGG's API answers 401 unauthenticated while `bgg_missing` is assigned on an *empty list*, not an
  error. Decision: **the 49 are unpublished, not deleted** — see
  `.planning/notes/staff-admin-decisions.md`.

A draft is not on the web, so the sentence the whole sketch rested on becomes false. **The editor
must not ship d38's accusation copy on a draft.** That is the single easiest thing for a future build
to get wrong, and it is recorded in `references/admin-game-editor.md`.

## Design Direction

The admin is **not** a smaller version of the public site. Its rules, established across 059–080:

- **Mobile-first, phone-width primary** — staff use this standing at a shelf, not at a desk.
- **One row anatomy, one field anatomy, one list label, one component per job** (065's 10 rounds of
  drift-hunting). Persistent controls never move between states.
- **A value is a row that opens a sheet** (d33), and such a row carries **no chevron** (d34).
- **One outline button system** (064 S3 "Contorno"), cited as "064 A1" by every later sketch.
- **Status is a dot + text**, never a pill.
- **The sheet prepares, the foot writes** (080) — sheets stage edits into a draft; a fixed footer
  bar commits.
- Pages are shaped by **what staff actually do**, measured against real dev-DB counts, rather than
  by the filter-and-table habit (071, 069, 070 all opened this way).

## Key Decisions

- **Dark mode** resolved as a chain, not a single pick: 054's lifted ladder, 055's text-contrast fix
  for the primary, 056's CTA fix, and 058's hue change to the ramp. `references/dark-mode-palette.md`
  records the final combined state — do not implement any one of the four in isolation.
- **Admin chrome (current):** top bar `‹ · título · ⋮` with the ⋮ as the only control; body carries a
  status note then the ficha; a fixed foot bar with a 1px background-coloured divider and `Guardar`
  at natural width on the right, 14px keel, enabled only when dirty.
- **Create flow:** `+` sheet → V2 "Se abre" → completion toast «Ver» → the pending sheet speaks
  alone (AV1). 076 and 077 are one continuous scenario.
- **Estantes** is the locate-and-return surface: search to one game, see it raised among its
  neighbours, place it by choosing the gap. 9 horizontal estantes, up to 50 boxes each.

## Caveats carried into implementation

- **Nothing in 069–080 is confirmed on a real device.** Every one of those sketches says so in its
  own status line. They are decided on measurements taken in headless Chrome at 375×667 and 360×640.
- **064's "no disabled buttons" rule is in open conflict** with 080's `Guardar`, which ships
  disabled while clean. Recorded as unresolved in `references/admin-button-system.md`.
- **`TODO(palette)` ×2** — `--val` and `--warn` are local tokens inherited through 073/075/079/080
  and still owed a real stop in `app.css`.
- **The shared sketch theme had drifted** from the copy stored in the skill; `sources/themes/default.css`
  was refreshed during this wrap-up.
