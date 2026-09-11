# Quick Task 260824-u5d: Implement pagination for the catalog carousels/sections - Context

**Gathered:** 2026-08-24
**Status:** Ready for planning

<domain>
## Task Boundary

Implement pagination for the catalog carousels/sections. Decide: infinite scroll vs "ver todos"
link vs other pattern, informed by industry standards (Netflix and similar apps).

Scope is the 8 home-page carousel rows rendered by `CatalogLive.Index` via
`CarouselRow.carousel_row/1`, backed by `Catalog.list_carousel_rows/0` (8 separate
`LIMIT @carousel_limit` — 20 — Ecto queries in `catalog.ex`). The detail page's "Juegos
similares" shelf (`Catalog.similar_games/1`, `@similares_limit` 12) is NOT in scope for this
task — it already has no "ver todo" tile and was not raised as something to change.

</domain>

<decisions>
## Implementation Decisions

### Pagination pattern
- **In-row horizontal infinite scroll.** As the user scrolls right inside a single carousel row
  (e.g. "Recomendados"), more games from that row's category load automatically — the row is no
  longer capped at a fixed `LIMIT 20` with nothing beyond it. This replaces the *fixed* cap with
  real pagination (offset/limit) fetched as the rail approaches its end.
- Explicitly NOT: (a) more carousel *rows/sections* lazy-loading as the user scrolls down the
  home page (vertical infinite scroll) — out of scope; (b) a classic numbered-pagination UI
  inside a row — rejected, doesn't fit a horizontal rail.
- This still coexists with the main catalog grid's own pagination (`@page_size 24`,
  `handle_event("load-more", ...)`, the "Cargar más" button) — that pattern is unrelated and
  untouched by this task.

### "Ver todo" tile fate
- **Removed entirely** from the 8 home carousel rows (`carousel_row.ex:131-141`, the
  `.pk-see-all` tile + `see-all` event handling in `catalog_live/index.ex`). User's explicit
  rationale: "netflix doesn't have a ver todo" — once infinite scroll covers browsing a
  category's full game list within the row itself, the tile's job (escape hatch to see more) is
  redundant. A row that exhausts its category simply stops — no trailing CTA card.
- **Known tradeoff, explicitly accepted, not re-litigated:** the current "Ver todo" tile also
  serves as an entry point into the main grid's *filtered/sorted* view (`see_all_selection/1`
  maps a row's key to filter state before calling `apply_filters/1`). Removing the tile removes
  that specific navigation path. The user was told this in the discussion and confirmed removal
  anyway — do not add it back as a "safer" compromise during planning/execution.

### Loading indicator (in-row fetch-more)
- **Flat, no-shimmer skeleton cards** — reuse `CarouselRow.skeleton_card/1` as-is, appended at
  the trailing edge of the rail while the next page of games is being fetched.
- Explicitly NOT a spinner, and NOT the shimmer treatment.
- **Why this specific choice (per user's own instruction — "don't forget to include the semantic
  defined for loading"):** `.claude/skills/sketch-findings-pukllay_club/references/
  carousel-mechanics.md` already defines two distinct loading moments in this codebase:
  1. Flat `.pk-skel` skeleton (`skeleton_row/1`) for full-page/initial load (sketch 009's
     winner) — content appearing for the first time.
  2. Shimmer (sketch 025's winner) for filter-triggered row *repopulation* — replacing content
     that's already visible with new content, not yet implemented.
  Appending new cards at a row's trailing edge is a "content appearing for the first time"
  moment (case 1's semantic), not a "replacing what's already shown" moment (case 2's semantic)
  — so it must use the flat skeleton treatment, not shimmer, to stay consistent with the
  existing distinction rather than inventing a third ad hoc loading style.

### Row size ceiling (added after research surfaced real row sizes)
- Research measured actual dev-DB row sizes: 19 to **408** games per row (not the assumed ~20).
  A 408-item row with no "Ver todo" escape hatch would be ~43,000px of horizontal scroll on a
  390px mobile viewport — unacceptable for a mobile-first app.
- **Decision: cap infinite scroll at a fixed ceiling, not truly unbounded.** Ceiling = **30
  games per row**. Once a row has loaded 30 games, treat it as "exhausted" for rendering
  purposes and stop fetching more, even if the underlying category has more (e.g.
  `recientemente_anadidos`'s real 408 stops surfacing new cards at 30). This is a fixed cap, not
  a "Ver todo" escape hatch — "Ver todo" stays removed per the earlier decision.
  - **Revision note:** the first pass at this decision picked 60 (3x the initial page of 20)
    purely as a scroll-depth/perf ceiling. User pushed back citing choice-overload research
    (Miller's Law ~7±2 working-memory items, Hick's Law, and specifically the Iyengar & Lepper
    jam study: a 24-flavor tasting table converted at 3% vs. 30% for a 6-flavor table). No
    single validated number mandates a specific cap — the jam study is about a forced
    simultaneous comparison, not scroll-based browsing, and no verified Netflix-specific figure
    could be found via web search — but the user chose to lean partway into that framing anyway.
    **30 is the final, locked number**, landing between the jam study's 24 and the original 60.
- Implement the cap as part of the server-side `exhausted?` signal research recommended (not via
  `stream/4`'s `:limit`, which scroll-jumps on a horizontal rail) — i.e. `exhausted?` becomes
  true when either the category truly runs out OR the 30-item ceiling is reached, whichever
  comes first.
- 30 is a starting number, not a load-bearing constant from user testing — fine to expose as a
  module attribute (e.g. `@carousel_infinite_scroll_max`) so it's easy to tune later without
  re-discussing this decision.

### Claude's Discretion
- Exact trigger mechanism (e.g. extending the existing `.CarouselScroll` JS hook to detect
  scroll-proximity to the rail's end and push an event to the LiveView) is an implementation
  detail for planning, not discussed with the user.
- Exact page size per fetch-more request, and whether to keep `@carousel_limit` as the *initial*
  page size (first load) while adding a separate increment size for subsequent in-row fetches,
  is left to planning — informed by the research phase.
- Whether "ver todo" removal also requires touching `see_all_selection/1` / the `see-all` event
  handler (dead code once no caller passes `see_all_row`) is an implementation detail — likely
  yes, to avoid leaving unreachable code, but confirm during planning. **Research already
  resolved this: yes, delete both — `see_all_selection/1` has exactly one caller and
  `mix test --warnings-as-errors` fails the build on an orphaned private function. 4 tests in
  `catalog_live_test.exs:932-999` and one assertion at `:1090` must be deleted too.**

</decisions>

<specifics>
## Specific Ideas

User's reference point: "I just saw android app for netflix and they have infinite scroll" —
specifically the Netflix Android app's horizontal in-row infinite scroll (option confirmed via
follow-up: "within a row (horizontal)", not more rows appearing vertically).

</specifics>

<canonical_refs>
## Canonical References

- `.claude/skills/ux-patterns/SKILL.md` — B7 (long lists: load-more, not infinite scroll —
  applies to the *main grid*, unaffected by this task) and B9 (carousels: cap at ~5 visible
  frames, visible in-carousel controls, no auto-advance — still applies to what's visible in the
  viewport at once, distinct from how many total items the row can page through).
- `.claude/skills/sketch-findings-pukllay_club/references/carousel-mechanics.md` — the two
  existing loading-semantic definitions cited above; also documents free-momentum scroll (no
  snap), no position/pagination indicator, and the approved-but-unimplemented edge-overlay arrow
  relocation (sketch 022) — unrelated to this task, do not touch incidentally.
- `lib/pukllay_club/catalog.ex` — `@carousel_limit` (20), `list_carousel_rows/0`,
  `carousel_row/3` private helper (the 8 bounded `Repo.all` queries to change to real
  offset/limit pagination).
- `lib/pukllay_club_web/components/carousel_row.ex` — `carousel_row/1`, `skeleton_card/1`, the
  `.pk-see-all` tile markup to remove, the `.CarouselScroll` JS hook to extend.
- `lib/pukllay_club_web/live/catalog_live/index.ex` — `see_all_row` prop wiring, `"see-all"`
  event handler, `see_all_selection/1` to evaluate for removal.

</canonical_refs>
