# Filter & Search

**Status: already shipped.** Unlike most reference files in this skill, this one documents a
component that exists in production today — `lib/pukllay_club_web/components/filter_modal.ex` —
built directly from sketch 019's winner. Sketches 008/012/019 are historical rationale for *why*
it looks the way it does, not a target still to build.

## Design Decisions

**Centered modal (desktop) / bottom sheet (mobile), not a slide-over drawer.** The retired
`FilterDrawer` was replaced by `FilterModal` — a pinned three-region shell (header / scrolling body
/ pinned footer). Header reads "Encuentra tu juego" with a one-line subtitle, framing the modal as
answering the visitor's question rather than a technical "Filtros" label — avoids the CRM/advanced-
search feel sketch 019 was explicitly trying to shed.

**Primary filters are always-visible chip clusters inside their own card.** Jugadores/Duración
máxima (`scalar_chip/1`) and the Nivel weight-band pills each render inside a
`rounded-box bg-base-200 p-4` card (sketch 019 variant D). One `<details>` disclosure — also
card-treated — holds a searchable Mecánicas/Temáticas checklist pair, auto-expanding whenever a
mechanic/theme is already selected so re-opening the modal never hides an active choice.

**No age filter, anywhere.** `min_age` has no UI control — difficulty (Nivel) already serves the
purpose an age filter would. It's still reachable via `?min_age=` URL param only. Do not add an age
control as a "fix" — this was an explicit, deliberate scope correction, not an oversight. See
[[feedback_no_age_filter]].

**The editorial-hashtag ("Destacados") facet-pill group is cut, deliberately.** `facet_options/0`
still returns `editorial_tags` and `?tags=`/`clear-filters` still work — only the UI control is
gone, pending a future decision on how it should return (sketch 019 Round 3). Don't re-add the flat
pill row as a bug fix.

**Jugadores gets a "6+" open-ended chip alongside the four exact-fit chips (2/3/4/5).** Both
families send the same `scalar="players"` so the cluster stays single-select through one shared
`toggle-scalar` handler — a second scalar name would let "4" and "6+" both show active
simultaneously, which is the regression this design avoids.

**Footer actions: ghost "Limpiar filtros" (disabled when nothing is active) + primary "Ver N
juegos" CTA.** No border/fill at rest for the ghost button — matches the app's general "hierarchy
from position/weight, not chrome" convention (see [[ui_design_system]] if that skill exists, or
`header-navigation-drawer.md`'s 013-E note for the same pattern applied to nav).

**Active-filters chip row: not yet built (Phase 01.2 gap-closure, sketch 029).** Unlike every other
decision in this file, this one is still to implement — UAT found the Resultados grid header
(`CatalogLive.Index`, heading + result count only) has no affordance at all for which filters are
currently applied; the one existing proxy, a numeric badge on the filter trigger, is itself trapped
inside a separate broken-collapsible-search-region bug (see the phase's own debug log). Three
placements were sketched (a wrapping row below the heading, a horizontally-scrollable labeled row,
chips inline with the heading itself) — **inline with the heading won**, most compact on desktop,
wraps to its own line only when space runs out.

The chip style itself went through a rebalancing round: the first pass reused the filter modal's
own `.chip.active` contract verbatim (solid `--color-primary` fill + shadow, sketch 019) and it
outweighed the "Resultados" heading it sat next to. Lightened to a soft `--color-accent-bg` tint
with a thin border and no shadow — same "this filter is applied" signal, without competing with the
heading for visual weight. This is a **different chip treatment from the filter modal's own
chips** — don't reuse `.chip.active` verbatim for this row; a removable applied-filter chip and a
selectable modal option chip are different affordances even though both derive from the same base
pill shape.

```css
.pk-active-filter-chip { display: inline-flex; align-items: center; gap: 5px; background: var(--color-accent-bg); color: var(--color-accent-text); border: 1px solid var(--color-border); font-size: var(--text-xs); font-weight: 600; padding: 4px 5px 4px 11px; border-radius: var(--radius-full); }
.pk-active-filter-chip button { border: none; background: transparent; color: var(--color-text-muted); width: 16px; height: 16px; border-radius: 50%; }
.pk-active-filter-chip button:hover { background: var(--color-danger); color: #fff; }
```
```html
<div class="heading-row">
  <div class="heading-block"><h2>Resultados</h2><p>{result_count_text(@total)}</p></div>
  <div class="chip-row">
    <span class="pk-active-filter-chip">{label} <button phx-click="clear-filter" phx-value-key={key}>×</button></span>
    <button class="clear-link" phx-click="clear-filters">Limpiar filtros</button>
  </div>
</div>
```

## CSS/Markup Patterns

- Chip clusters and pill groups: `scalar_chip/1` component, one `phx-value-scalar`/
  `phx-value-choice` pair per chip — never `phx-value-value` (LiveView silently clobbers that key
  with the element's own native `.value`). See [[feedback_no_phx_value_value]].
- Checklist disclosure: `.FilterChecklist` colocated hook gives client-side, accent-insensitive text
  filtering and keeps the `<details>` open across LiveView patches.
- Desktop-dialog / mobile-bottom-sheet is a CSS breakpoint flip on the same markup, not two
  components.

## What to Avoid

- Re-adding an age filter control (dropped deliberately)
- Re-adding the flat editorial-tag pill row inside the modal (cut deliberately, pending a future
  presentation decision)
- A second scalar name for "6+" (breaks single-select)
- `phx-value-value` as a value key on any filter control
- Reusing the filter modal's solid-filled `.chip.active` style verbatim for the active-filters
  header row — it reads too heavy next to the "Resultados" heading; use the lighter accent-tint
  treatment instead.

## Origin
Synthesized from sketches: 008, 012, 019, 029
Source files available in: `sources/008-filter-search-ui/`, `sources/012-filter-modal-in-shell/`,
`sources/019-filter-modal-finish/`, `sources/029-active-filters-chip-row/`
Real implementation: `lib/pukllay_club_web/components/filter_modal.ex` (the active-filters chip row
itself is not yet implemented — see above)
