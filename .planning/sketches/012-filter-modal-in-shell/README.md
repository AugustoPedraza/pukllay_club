---
sketch: 012
name: filter-modal-in-shell
question: "Does sketch 008's approved filter modal hold together once it's composed into 011's real header and GAMES dataset, instead of 008's own standalone placeholder file — and does it reconcile cleanly with 011's separate, older mobile filters panel?"
winner: "single composed view — consistency check, found+fixed 1 real crash risk (see below)"
tags: [consistency, filter, search, navigation, shell, mobile]
---

# Sketch 012: Filter Modal in Shell

## Design Question
Sketch 008's Round 8 filter modal (icon-free, rebalanced, checklist-in-dropdown Autor/Mecánica) was
approved and confirmed working — but only ever verified inside its own standalone file, against its
own 14-game demo dataset. Sketch 011 (the real composed shell) had never gotten this modal at all —
it still shipped its own, much older filters system: a bottom-sheet panel reachable only from the
mobile hamburger drawer, offering just Dificultad and Duración (single-select radios), with no
desktop access and no Autor/Mecánica facets (011's own README explicitly flagged "no per-game
mechanics field exists in this dataset, so mechanics filtering isn't offered here"). This sketch
composes 008's approved modal into 011's real shell, reconciling that gap — following the same
"compose into the real page, catch real drift" pattern this project already used for 007
(001+002 → shell) and 011 itself (005+004 → shell).

## Grounding
011's `GAMES` array (6 games) lacked `author`/`mechanics`/`type` fields entirely — added them by
pulling matching data from 008's own `GAMES` for the titles that overlap (Catán, Wingspan, Hanabi,
Terraforming Mars: Ares Expedition, 7 Wonders Duel, La Resistencia), so the two sketches' data agrees
rather than inventing fresh values. Found a real, unrelated typo while touching this array: 011 had
"El Resistencia" (incorrect) where 008 correctly has "La Resistencia" — fixed.

## How to View
open .planning/sketches/012-filter-modal-in-shell/index.html
(this sketch modifies 011's file directly — 012 has no separate directory content beyond this
README; see "Changed" below for exactly what moved)

## What Changed
Ported into `.planning/sketches/011-full-shell-composition/index.html`:

1. **Desktop filter trigger added.** 011's header never had one — search sat alone. Added the same
   `.search-filter-cluster` (search + 🎚 icon button) 008 validated, wired to a new `openFilterModal()`.
2. **One filter modal replaces two divergent filter UIs.** Removed 011's old `.filters-panel`
   bottom-sheet (`.pill-btn`/`.filter-group`, Dificultad+Duración radios only, mobile-drawer-only) and
   replaced it with 008's full modal — same component now serves both viewports via its own
   `max-width:640px` query (centered dialog on desktop, bottom sheet on mobile), opened from either
   the new desktop icon or the existing drawer trigger, instead of two independent systems that could
   drift apart.
3. **Full facet set now available**, including Autor/Mecánica as the checklist-in-dropdown — real
   data now exists for it (see Grounding).
4. **Header search wired live for the first time.** 011's search input was decorative-only before
   this round. Both the desktop header input and the drawer's duplicate input now drive the same
   `filterState.q`, kept in sync with each other (typing in one live-updates the other's displayed
   value) so neither goes stale if the user opens the drawer mid-search.
5. **Card lookup adapted, not copy-pasted.** 008 matched filter state to cards via a stable
   `data-key` joined against `GAMES.find()`. 011 renders each shelf's cards with unique numeric ids
   and already stashes the full game object per-id in `window.__cardGames` (used by its hover-portal/
   tap-sheet code) — reused that existing mechanism instead of introducing a second lookup pattern.

## Bug Found + Fixed
`applyFilters()` was first ported as a global `document.querySelectorAll('.card')` scan — but 011 has
a *second* place real `.card` elements render: the detail page's "Juegos similares" shelf
(`#similar-rail`), populated from `SIMILAR_GAMES`, which doesn't carry `author`/`mechanics`/`type`
fields at all. The mobile drawer's "🎚 Filtros" trigger was never gated to the catalog page (pre-
existing 011 behavior, not introduced here), so a user could open it from the detail page and select
a mechanics filter — which would then crash on `g.mechanics.some(...)` for an undefined `.mechanics`
on every similar-game card. Caught this via a targeted JS-console reproduction (not visually — the
crash only fires on interaction, not on page load) before it ever shipped to a real browser click.
Fixed by scoping `applyFilters()` to `#rows .card` only (the catalog shelves) — filtering is a
catalog-browsing concept, not something that should touch a detail page's recommendation shelf, and
this was true before this composition too, just never exercised since the old mobile panel's facets
(band/duración) happened not to reference an undefined field.

## Verified Live
- Desktop: modal opens from the new header icon, all six facets render against 011's real GAMES/
  SHELVES; combining Jugadores(2) + Autor(Antoine Bauza) narrows correctly to Hanabi across every
  shelf instance (`totalFilterMatches()` → 1, `Ver 1 juego`).
- Autor/Mecánica checklist renders real derived values (Antoine Bauza, Don Eskridge, Elizabeth
  Hargrave, etc. / Comercio, Construcción, Cooperativo, Draft, etc.) — not placeholder demo data.
- Detail page: opened the filter modal and applied a mechanics filter via direct JS invocation
  (`toggleComboValue('mechanic', ...)`) while on `/juegos/:id` — no crash, and all 8 "Juegos
  similares" cards stayed unaffected (`hiddenSimilar: 0`), confirming the `#rows`-scoping fix.
- Theme: opened the modal under the dark theme — `.filter-modal` background correctly resolves to
  the dark palette (`rgb(21, 8, 38)`), same token-driven mechanism as the rest of the shell.
- No console errors across all of the above.

## Known Limitation (Not Verified)
This session's browser-automation tooling could not actually resize the tab's viewport (`resize_window`
reported success but `window.innerWidth` stayed at the desktop value across repeated attempts) — a
tooling quirk this project's own sketches have hit before at wide viewports (see 007/011's own notes).
The mobile bottom-sheet CSS itself is not new — it's ported byte-for-byte from 008 Round 7/8, which
*was* browser-verified at narrow width in its own standalone file — so this is a known gap in
re-verification, not a reason to doubt the CSS. Worth a real device/DevTools check before this ships.

## What to Look For
- Does the modal feel native to 011's real header, or does anything about its width/spacing clash
  now that it's next to the real brand lockup and Inicio/Quiénes Somos links (008 never had those)?
- Is gating the mobile drawer's filter trigger to catalog-only worth doing now that filtering has a
  full facet set (vs. the old 2-facet panel) — does offering it from Detalle/Acerca de still make
  sense, or should it hide there too?
- Real mobile-width check once tooling allows it, or via an actual device/DevTools responsive mode.
