---
sketch: 019
name: filter-modal-finish
question: "What does a modern, minimal, non-technical filter modal look like for this app — resolving the CRM/advanced-search feel, chip chrome weight, CTA hierarchy, and copy — without re-litigating the already-validated information hierarchy (primary chip clusters → secondary → collapsed checklist disclosure)?"
winner: "D — Synthesis: A's soft-bordered pill chips + C's grouped accent-card sections"
tags: [filter, modal, polish, microcopy, responsive]
---

# Sketch 019: Filter Modal Finish

## Design Question

Quick task 260824-b71 rebuilt the filter modal's structure (chip clusters, searchable checklist
disclosure, footer CTA) and a follow-up debug session fixed a critical bug that made every filter
control non-functional — but the *visual execution* landed flat and technical: bare daisyUI
outline buttons, no color accent beyond the primary CTA, a heavy `Limpiar filtros` button
competing with the CTA, redundant "Hasta N min" labels, no "6+" bucket for Jugadores, a generic
"Filtros" title, a dry search placeholder, and no visual coordination between the modal opening
and the grid updating live behind it.

This sketch answers: **what does the finish pass look like?** — same content/hierarchy, three
different levels of chrome weight.

## Grounding

- Content/hierarchy is locked from the 260824-b71 discussion (primary: Jugadores/Duración/Nivel,
  secondary: Destacados, collapsed: Mecánica/Temática checklist) — not re-explored here.
- Copy fixes (same across all 3 variants, isolating chrome as the only variable):
  - Title: **"Encuentra tu juego"** (+ subtitle "Combina filtros para llegar a los juegos que te
    interesan") instead of the bare technical "Filtros".
  - Search placeholder: **"¿Qué juego buscas?"** instead of "Busca por título, autor o
    editorial…" — shorter, conversational, frames the box as answering the user's own question
    rather than listing technical fields to search by.
  - Duración chips: **"30 min" / "60 min" / "90 min" / "120 min"** — the "Duración máxima" section
    heading now carries the "up to" meaning, so the redundant "Hasta" is dropped from every chip.
  - Jugadores: added a **"6+"** chip alongside 2/3/4/5.
  - `Limpiar filtros`: demoted to a plain text button (no border/fill) next to the primary CTA,
    disabled until a filter is active — no longer competing visually with `Ver N juegos`.
- Background coordination: the catalog grid behind the modal blurs + dims while the modal is
  open (`filter: blur(3px) saturate(0.7) brightness(0.94)`), so the live-updating grid reads as
  "paused/backgrounded while you focus on filtering" instead of "something happening
  independently while a dialog floats on top."
- Real facet/game data pulled from `lib/pukllay_club/catalog/vocabulary.ex` and the live catalog
  (game names, mechanic/theme labels, weight bands, editorial tags) — not lorem ipsum.
- Theme: this project's real `../themes/default.css` tokens (light/dark via the toolbar).

## How to View

```
open .planning/sketches/019-filter-modal-finish/index.html
```
Click "⚙ Filtrar" in the faux header to open the modal. Toggle chips, expand the disclosure,
type in a checklist search box, click "Limpiar filtros" — everything is live/functional against
fake state (the CTA count is a plausible-looking narrowing estimate, not a real query).

## Variants

- **A: Soft-bordered pills** — daisyUI-adjacent but refined: 1px border pills at rest, filled
  primary + a subtle colored shadow when selected. Closest to "the current app, but finished
  properly" — lowest implementation risk, still reads calmer than the shipped version because of
  the copy fixes, spacing, and backdrop blur alone.
- **B: Borderless / color-underline** — no chip chrome at rest (plain text), a 2px colored
  underline + bold weight marks the selected state. This is the direction
  `.planning/sketches/008-filter-search-ui` Round 8 actually landed on and had approved before
  this modal got rebuilt in daisyUI and drifted from it — closest to "recover what was already
  validated." Reads the most minimal of the three; asks the most of Tailwind/daisyUI to express
  cleanly (no native daisyUI "underline chip" primitive, would need custom classes).
- **C: Grouped accent cards** — each filter section (Jugadores, Duración, Nivel, Destacados, the
  disclosure) sits inside a `--color-surface` card with rounded corners, visually separating
  groups more strongly than a bare heading + row. Slightly more visual weight than A/B but clearer
  scannability at a glance — leans toward "each section is its own decision," which may read as
  more structured/guided for a newcomer audience (ties to the "teach, don't assume familiarity"
  core UX principle) at some cost to the "minimal" ask.

## Round 2 — Synthesis (winner)

User picked A and C together: "I like A and C." Built as a 4th tab (**D: Synthesis**) rather than
forcing a single choice — A's chip visual contract (1px border pill at rest, filled primary +
subtle colored shadow when selected) placed inside C's grouped `--color-surface` section cards
(Jugadores/Duración/Nivel/Destacados/disclosure each in their own soft accent-wash card). No new
CSS beyond combining the two existing rule sets under a `.vd` scope — confirmed live: chip
select/toggle, count update, and `Limpiar filtros` enable/disable all work identically to A and C
individually. **Winner: D.** Set as the sketch's default-active tab; A/B/C preserved as reference,
not deleted.

## What to Look For

- Does any variant actually stop reading as "CRM advanced search"? Which one crosses that line
  most convincingly?
- Is the borderless underline treatment (B) too subtle to discover as clickable, or does it read
  as confidently minimal?
- Does the grouped-card treatment (C) help a newcomer understand "these are different kinds of
  filters" — or does it just add visual weight without adding clarity?
- Does the blurred/dimmed background read as "intentional focus" now, or still distracting?
- Is "Encuentra tu juego" the right title, or does another framing feel more natural in Spanish?
- Is "¿Qué juego buscas?" too casual/conversational for the search box, or does it land well?

## Open Questions (flagged for the build task, not resolved here)

- **"6+" bucket semantics.** The real SQL predicate for Jugadores today is an exact seat-count fit
  (`min_players <= n AND max_players >= n`). A genuine "6 or more players" filter needs a
  different predicate shape (e.g. `max_players >= 6`, no upper bound) — this sketch shows the chip
  visually but the actual backend/query decision needs to happen during implementation, not here.
