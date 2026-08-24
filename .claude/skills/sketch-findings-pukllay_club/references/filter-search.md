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

## Origin
Synthesized from sketches: 008, 012, 019
Source files available in: `sources/008-filter-search-ui/`, `sources/012-filter-modal-in-shell/`,
`sources/019-filter-modal-finish/`
Real implementation: `lib/pukllay_club_web/components/filter_modal.ex`
