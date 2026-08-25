---
phase: quick-260824-u5d
plan: 01
subsystem: ui
tags: [phoenix, liveview, streams, ecto, pagination, infinite-scroll, colocated-hook, carousel]

# Dependency graph
requires:
  - phase: 01-05
    provides: the fixed-LIMIT carousel rows (Catalog.list_carousel_rows/0, @carousel_limit 20) this task replaces with real pagination
  - phase: 01-08
    provides: the .CarouselScroll colocated hook (arrow scroll + overflow-visibility sync) this task extends with a fetch-more trigger
  - phase: 01-11
    provides: the .pk-see-all "Ver todo" tile this task removes entirely
provides:
  - Catalog.carousel_page/3 — server-authoritative offset/limit pagination for one carousel row, shared row_query/1 dispatch with list_carousel_rows/0, limit+1 over-fetch, a 30-game ceiling
  - Per-row LiveView streams (:"carousel_#{key}") created once in CatalogLive.Index's connected mount, plus a carousel-load-more event handler
  - CarouselRow.carousel_row/1's stream-shaped contract (:games :any, :empty, :row_key, :exhausted attrs; .pk-rail as phx-update="stream")
  - .CarouselScroll hook extended with a rAF-throttled scroll-proximity fetch-more trigger, a pending/exhausted client guard, and a client-driven loading indicator
  - Permanent trailing skeleton_card/1 placeholders toggled by CSS (.pk-rail[data-loading] .pk-trailing-skel)
  - Full removal of the "Ver todo" tile, its event handler, its filter-selection helper, and its CSS/tests
affects: [catalog-carousel, catalog-index, catalog-show, ux-loading-states]

# Actuals (#2632)
actuals:
  tokens: 9232
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Single row_query/1 string-dispatch shared by both the first page (list_carousel_rows/0) and every later page (carousel_page/3) so the two predicates can never silently diverge"
    - "limit+1 over-fetch to detect exhaustion with no second COUNT query, combined with a pre-query ceiling clamp so a client cannot force unbounded queries by repeatedly scrolling an exhausted rail"
    - "Per-row LiveView streams named by a server-derived atom (never client input) to keep 8 structurally-overlapping carousel rows from colliding on the same generated DOM id"
    - "Client-side-only loading indicator (a data attribute toggled by the JS hook around a synchronous pushEvent), since a server-driven flag would flip within the same round trip and never actually render"
    - "Permanent non-stream trailing children inside a phx-update=\"stream\" container, visibility toggled by CSS class/attribute rather than :if — LiveView forbids removing non-stream items from a stream container once it exists"
    - "LiveSocket.main.pushEvent + enableLatencySim, driven from a from-scratch Node/CDP script, used to prove both the nested-stream mechanism and the otherwise-sub-frame loading flash in a real browser without any client-side automation tooling"

key-files:
  created: []
  modified:
    - lib/pukllay_club/catalog.ex
    - lib/pukllay_club_web/components/carousel_row.ex
    - lib/pukllay_club_web/live/catalog_live/index.ex
    - lib/pukllay_club_web/live/catalog_live/show.ex
    - assets/css/app.css
    - test/pukllay_club/catalog_test.exs
    - test/pukllay_club_web/live/catalog_live_test.exs

key-decisions:
  - "carousel_row_specs/0 is private (defp), not public — nothing outside Catalog needs the ordered {key, title} pairs directly, list_carousel_rows/0 is the public contract"
  - "The out-of-scope Juegos similares shelf (CatalogLive.Show) is adapted to the new stream-shaped component contract with a manually-built {dom_id, game} list and exhausted={true} — not migrated to a real stream, since it is never paginated and CONTEXT.md scoped this task to the 8 home carousel rows only"
  - "Row size ceiling arithmetic (locked at 30 in CONTEXT.md, unchanged initial page of 20) yields exactly one 10-game increment per row before exhaustion — confirmed live rather than just derived: recientemente_anadidos jumped straight from 20 to 30 cards on its first append"

patterns-established:
  - "Server-authoritative pagination guard: an unknown or already-exhausted row key short-circuits to a no-op reply with zero queries, never building an atom from client input (T-01-37 convention extended to a new event)"
  - "Client pending-flag release exclusively from pushEvent's reply callback, never a timeout — one round trip carries both the new cards and the stop signal"

requirements-completed: [CATALOG-01]

coverage:
  - id: D1
    description: "Scrolling a carousel rail toward its right edge loads the next page of that row's category into that same rail, with no page reload, no scroll-position jump, and no effect on sibling rails"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs#carousel_page/3 — in-row infinite scroll pagination (quick task 260824-u5d) (6 tests)"
        status: pass
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#in-row horizontal infinite scroll: carousel-load-more (quick task 260824-u5d) (3 tests)"
        status: pass
      - kind: automated_ui
        ref: "headless Chrome CDP session against the dev server (Task 1: programmatic pushEvent proving the nested-stream mechanism; Task 2: real scroll-to-end gesture at 390px and 1280px) — see Live Browser Verification below"
        status: pass
    human_judgment: false
  - id: D2
    description: "A row stops — no trailing CTA, no message, no further requests — once it reaches its true category end or the locked 30-game ceiling, whichever comes first; a row already shorter than the initial page (e.g. the 19-game Duelos memorables row) renders correctly on first paint and never issues a fetch-more request at all"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "test/pukllay_club/catalog_test.exs#carousel_page/3 (ceiling-clamp and short-row-exhausted cases)"
        status: pass
      - kind: automated_ui
        ref: "headless Chrome CDP — duelos_memorables (19 games) scrolled to its end at both viewports never fires a request; recientemente_anadidos (408 games) stops growing at 30 cards"
        status: pass
    human_judgment: false
  - id: D3
    description: "Flat, no-shimmer skeleton cards mark an in-flight fetch at the trailing edge of the fetching rail only, and are absent everywhere else including an exhausted rail"
    requirement: "CATALOG-01"
    verification:
      - kind: integration
        ref: "test/pukllay_club_web/live/catalog_live_test.exs#trailing skeleton placeholders + hook data attributes (Task 2, quick task 260824-u5d) (2 tests)"
        status: pass
      - kind: automated_ui
        ref: "headless Chrome CDP with LiveSocket.enableLatencySim(700) to widen the otherwise sub-frame round trip — placeholder confirmed visible mid-flight and confirmed absent at rest, at both viewports"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Ver todo tile is removed entirely from code, CSS, and tests — no dead code, dead CSS, or dead test remains"
    requirement: "CATALOG-01"
    verification:
      - kind: unit
        ref: "grep -rn -e 'pk-see-all' -e 'see_all_selection' -e 'see_all_row' -e '\"see-all\"' lib/ assets/css/ (no matches)"
        status: pass
      - kind: unit
        ref: "mix quality (7 steps: hex.audit, deps.audit, deps.unlock --check-unused, format --check-formatted, credo --strict, sobelow --config, test --warnings-as-errors) — 393 tests, 0 failures"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-08-24
status: complete
---

# Quick Task 260824-u5d: In-Row Horizontal Infinite Scroll for the 8 Catalog Carousels Summary

**Replaced the fixed `LIMIT 20` on all 8 home-page carousel rows with real server-paginated, per-row LiveView streams driven by a scroll-proximity trigger in `.CarouselScroll`, capped at a locked 30-game ceiling, with flat trailing skeleton placeholders — and removed the "Ver todo" tile entirely, verified end-to-end in a real headless browser via raw Chrome DevTools Protocol.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- `Catalog.carousel_page/3`: a single `row_query/1` string-dispatch shared by `list_carousel_rows/0` (page 1) and every later page, a `limit + 1` over-fetch to detect exhaustion with no extra `COUNT` query, and a `@carousel_infinite_scroll_max` (30) ceiling enforced *before* any query runs once reached — a client cannot force unbounded queries by repeatedly scrolling an exhausted rail.
- `CatalogLive.Index` creates 8 per-row LiveView streams (`:"carousel_#{key}"`, atoms derived only from the server's own row list) exactly once, in the connected `mount/3` branch, and a new `carousel-load-more` handler appends a page into exactly one row's stream, replying `%{exhausted: bool}` in the same round trip. An unknown or already-exhausted row key short-circuits with zero queries.
- `CarouselRow.carousel_row/1`'s contract changed to accept a stream (`:games` is now `:any`), gained `:empty`/`:row_key`/`:exhausted` attrs, and `.pk-rail` became the `phx-update="stream"` container.
- `.CarouselScroll` extended with a rAF-throttled scroll listener computing remaining runway, a `pending` flag released only from `pushEvent`'s reply callback, and a client-driven `data-loading` attribute (not a server assign — the handler is synchronous, so a server flag would flip within one round trip and never actually render).
- Two permanent trailing `skeleton_card/1` placeholders per rail, toggled purely by CSS (`.pk-rail[data-loading] .pk-trailing-skel`) since LiveView forbids removing non-stream items from a stream container once one exists.
- The "Ver todo" tile — its markup, event handler, `see_all_selection/1` filter-mapping helper, CSS, and 4 dedicated tests — removed entirely, per CONTEXT.md's confirmed (not re-litigated) decision.
- **All three tasks verified live against a real headless Chrome via raw CDP** (no browser-automation MCP tools available), not just ExUnit: the nested-stream-inside-`:for` mechanism (Task 1's biggest open question per RESEARCH.md §7) was proven correct in a browser before Task 2 built the scroll trigger on top of it.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end "one rail pages in more games" — server pagination + per-row streams, proven in a browser** - `f2e9459` (feat)
2. **Task 2: Scroll trigger + trailing skeleton cards** - `1a595f5` (feat)
3. **Task 3: Remove the Ver todo path entirely and close the quality gate** - `f3f3b20` (fix)

**Plan metadata:** not committed by this executor — orchestrator handles the docs commit separately per this quick task's own instructions.

## Files Created/Modified

- `lib/pukllay_club/catalog.ex` — `@carousel_page_size`/`@carousel_infinite_scroll_max` module attrs; `carousel_row_specs/0`, `row_query/1` (literal-string dispatch, catch-all returns `nil`), `fetch_row_page/3` (the shared paginator), and the public `carousel_page/3`; `list_carousel_rows/0` rewritten to route through the same dispatch; `tags_query/1`/`weight_band_query/1` lost their baked-in `limit:` and gained an `:id` tiebreaker after `:name`
- `lib/pukllay_club_web/components/carousel_row.ex` — stream-shaped `:games`/`:empty`/`:row_key`/`:exhausted` attrs; `.pk-rail` is now the `phx-update="stream"` container; `.CarouselScroll` gained the fetch-more trigger and its cleanup; two permanent trailing `skeleton_card/1`s; the `.pk-see-all` tile and its `:see_all_row` attr removed (Task 3)
- `lib/pukllay_club_web/live/catalog_live/index.ex` — `assign_carousel_rows/2`, `carousel_row_metadata/1`, `carousel_stream_name/1`, `find_carousel_row/2`, `update_carousel_row/3`; new `handle_event("carousel-load-more", ...)`; the chip-nav filter now reads `row.empty?` instead of `row.games != []`; `handle_event("see-all", ...)` and `see_all_selection/1` (all 9 clauses) removed (Task 3)
- `lib/pukllay_club_web/live/catalog_live/show.ex` — the out-of-scope "Juegos similares" shelf adapted to the new component contract (a manually-shaped `{dom_id, game}` list, `empty={@similar_games == []}`, `row_key="similares"`, `exhausted={true}`) — a Rule 1 auto-fix, see Deviations
- `assets/css/app.css` — new `.pk-trailing-skel` visibility-toggle rule; `.pk-see-all`/`.pk-see-all:hover` removed (Task 3)
- `test/pukllay_club/catalog_test.exs` — new `carousel_page/3` describe block (6 tests: page continuity, short-row exhaustion, ceiling stop, ceiling clamp, at-ceiling no-op, unknown-key error)
- `test/pukllay_club_web/live/catalog_live_test.exs` — new `carousel-load-more` describe block (3 tests) and new trailing-placeholder describe block (2 tests); the 4-test "Ver todo tile wired to real filter state" block deleted; the composite test's tile assertion inverted (Task 3)

## Decisions Made

See `key-decisions` in frontmatter — summarized: `carousel_row_specs/0` stayed private since nothing outside `Catalog` needs it; the similar-games shelf was adapted to the new contract rather than migrated to a real stream (it's never paginated and explicitly out of scope); the locked 30-ceiling/20-initial/10-increment arithmetic (documented in the plan's `<sizing_note>`) was confirmed live — every multi-page row jumps straight from 20 to 30 cards on its one and only append.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `CatalogLive.Show`'s "Juegos similares" shelf broke when `CarouselRow.carousel_row/1`'s contract changed**
- **Found during:** Task 1 (first `mix compile` after the component's four contract changes)
- **Issue:** The plan's file list for Task 1 didn't include `show.ex`, but it's a second caller of the same shared `carousel_row/1` component, passing a plain list of `Game` structs and no `row_key`/`empty` attrs. The compiler immediately flagged a missing required `row_key` attribute, and — more seriously — the new `:for={{dom_id, game} <- @games}` comprehension would have raised a `MatchError` at runtime the first time that page rendered with any similar games, since a bare `%Game{}` doesn't destructure as a 2-tuple. The prior `:if={@games != []}` empty-hides-shelf behavior would also have silently broken (a plain list is never a stream, but the guard moved to a new `:empty` attr that show.ex wasn't passing).
- **Fix:** `show.ex` now builds the same `{dom_id, game}` tuple shape the stream comprehension expects (`Enum.map(@similar_games, &{"similares-#{&1.id}", &1})`, byte-identical dom ids to the pre-change behavior), passes `empty={@similar_games == []}` to preserve the "no band-mates → no shelf" behavior, `row_key="similares"`, and `exhausted={true}` so the (irrelevant, since there's no `carousel-load-more` handler on `CatalogLive.Show`) scroll-trigger hook never attempts a fetch on this shelf.
- **Files modified:** `lib/pukllay_club_web/live/catalog_live/show.ex`
- **Verification:** `mix test test/pukllay_club_web/live/catalog_show_test.exs --warnings-as-errors` — 53 tests, 0 failures, including the pre-existing empty-band-hides-shelf and disconnected-skeleton tests.
- **Committed in:** `f2e9459` (Task 1 commit)

**2. [Rule 1 - Bug] Setting `.pk-rail` to `phx-update="stream"` in Task 1 broke every existing carousel test — LiveView requires an id on *every* child of a stream container, not just stream items**
- **Found during:** Task 1 (first `mix test` run against the two target files — 58 of 106 tests failed with `ArgumentError: setting phx-update to "stream" requires setting an ID on each child`)
- **Issue:** The still-present `.pk-see-all` button (not removed until Task 3) sat inside `.pk-rail` with no `id` attribute — legal before the container became a stream container, illegal after.
- **Fix:** Added `id={"#{@id}-see-all"}` to the button. (It was deleted entirely in Task 3, so this was a one-commit-lifetime fix.)
- **Files modified:** `lib/pukllay_club_web/components/carousel_row.ex`
- **Verification:** Re-ran the same two target test files — 106 tests, 0 failures.
- **Committed in:** `f2e9459` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs surfaced by the compiler/test suite immediately, not discovered later)
**Impact on plan:** Both fixes were mechanical consequences of changing a *shared* component's contract (`carousel_row/1` has two callers, only one of which — `CatalogLive.Index` — was in the plan's stated file list) and of a genuine LiveView constraint (every child of a `phx-update="stream"` container needs an id, non-stream children included) that wasn't called out in RESEARCH.md's four-contract-changes list. No scope creep — neither fix touches this task's actual feature (in-row pagination); both exist solely to keep pre-existing behavior working.

## Issues Encountered

- **No MCP browser-automation tools available in this executor's tool set.** Same fallback pattern as prior quick tasks in this project (260824-jkc): a from-scratch Node 22 script (~250 lines total across both verification scripts, zero npm installs) driving a headless `google-chrome --remote-debugging-port` instance over the raw Chrome DevTools Protocol (`Page.navigate`, `Runtime.evaluate`, `Emulation.setDeviceMetricsOverride`). Task 1 needed `window.liveSocket.main.pushEvent(...)` to dispatch `carousel-load-more` programmatically since Task 2's real scroll trigger didn't exist yet at that point in the plan's own sequencing; Task 2 additionally used `window.liveSocket.enableLatencySim(700)` (exposed for exactly this kind of debugging per `app.js`'s own comment) to widen the otherwise sub-frame local round trip enough to positively observe the loading flash. Both are read-only debugging aids already built into LiveView's own client, not new production code.
- **A same-tick `element.scrollLeft = n` assignment read back as `0`.** `.pk-rail` declares `scroll-behavior: smooth`, and Chrome's `.scrollLeft` setter honors that CSS property for programmatic scrolls too (spec-compliant, if easy to forget) — so a plain assignment animates asynchronously and the very next read in the same script sees the pre-animation value. Switched the verification script to `rail.scrollTo({left: n, behavior: "instant"})`, which is unaffected. This was a test-harness-only issue, not a product bug.
- **Dev deps/assets were not yet built in this fresh worktree.** `mix deps.get` and the first `mix compile`/asset build took several minutes before the dev server could serve `/assets/css/app.css`; the first curl against it 404'd mid-build and resolved once the pipeline finished. No code change needed.

## User Setup Required

None - no external service configuration required.

## Live Browser Verification (mandatory per plan instruction, recorded with actual numbers)

All measurements below are from a real headless Chrome session against the running dev server (`pukllay_club_dev`, 434 seeded games; row sizes per RESEARCH.md §0: `nivel_experto`=46, `duelos_memorables`=19, `ingenio_estratega`=183, `descubre_el_hobby`=179, `recientemente_anadidos`=408), not eyeballed or claimed without measurement.

**Task 1 — nested-stream mechanism, dispatched programmatically (no scroll trigger exists yet at this point):**

| | Before | After one `carousel-load-more` on `nivel_experto` |
|---|---|---|
| `nivel_experto` card count | 20 | **30** (46-game category, hit the 30 ceiling in one 10-card increment) |
| `ingenio_estratega` (sibling) card count | 20 | 20 — unchanged |
| `descubre_el_hobby` (sibling) card count | 20 | 20 — unchanged |
| `ingenio_estratega` `scrollLeft` (pre-set to 40 via `scrollTo(..., {behavior:"instant"})`) | 40 | 40 — unchanged |
| `descubre_el_hobby` `scrollLeft` (pre-set to 25) | 25 | 25 — unchanged |

Confirms cards land in exactly the right rail with no cross-row bleed, and sibling rails are untouched in both content and scroll position.

**Task 2 — real scroll-to-end gesture, both required viewports:**

| Check | 390px (mobile) | 1280px (desktop) |
|---|---|---|
| `duelos_memorables` (19 games) card count before/after scroll-to-end | 19 / 19 | 19 / 19 |
| `duelos_memorables` `data-exhausted` | `"true"` throughout | `"true"` throughout |
| `duelos_memorables` ever set `data-loading` | No | No |
| `recientemente_anadidos` (408 games) card count before → after first append | 20 → 30 | 20 → 30 |
| `recientemente_anadidos` card count after a second scroll-to-end (already exhausted) | 30 (no-op) | 30 (no-op) |
| `recientemente_anadidos` `scrollLeft` right after the gesture vs. ~1.1s later (post-append) | 1854 → 1854 | 2479 → 2479 |
| Trailing placeholder visible mid-flight (`LiveSocket.enableLatencySim(700)`, sampled 200ms into the request) | `loading: true`, `skelVisible: true` | `loading: true`, `skelVisible: true` |
| Trailing placeholder visible at rest (post-settle) | `loading: false`, `skelVisible: false` | `loading: false`, `skelVisible: false` |

Confirms: the 19-game row genuinely never fires a request at either viewport; the 408-game row stops exactly at the 30-game ceiling per the locked sizing arithmetic (20 initial + one 10-card increment); no scroll-position jump on append; the flat skeleton placeholder is observably visible only during the in-flight window and absent otherwise.

## Next Phase Readiness

- All 8 home carousel rows now support real in-row browsing depth up to 30 games (previously hard-capped at 20, hiding 90%+ of four rows' true category size); no further pagination work queued for this surface.
- The "Ver todo" tile's removed navigation path (category shelf → filtered main-grid view) is a known, accepted tradeoff per CONTEXT.md — not re-opened here, not a blocker.
- No blockers for Phase 2 (Natural-Language Spanish Search + Auth), which remains the project's next planned phase per STATE.md.

## Self-Check: PASSED

All 7 modified files confirmed present on disk with the expected changes. All 3 task commit hashes (`f2e9459`, `1a595f5`, `f3f3b20`) confirmed present in `git log --oneline`. `mix quality` re-verified green (393 tests, 0 failures) after the Task 3 removals. Both browser-verification grep/CDP checks re-run and confirmed passing immediately before writing this summary.

---
*Phase: quick-260824-u5d*
*Completed: 2026-08-24*
