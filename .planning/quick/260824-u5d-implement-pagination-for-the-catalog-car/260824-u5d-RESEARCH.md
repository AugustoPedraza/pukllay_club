# Quick Task 260824-u5d: In-row horizontal infinite scroll for the 8 catalog carousels — Research

**Researched:** 2026-08-24
**Domain:** Phoenix LiveView 1.2.9 streams + colocated JS hooks + Ecto offset pagination
**Confidence:** HIGH (every load-bearing claim read out of `deps/phoenix_live_view` source or the live dev DB this session)

---

<user_constraints>
## User Constraints (from CONTEXT.md — LOCKED, not revisited)

### Locked Decisions
- **In-row horizontal infinite scroll.** As the user scrolls right inside a single carousel row, more games from that row's category load automatically — the row is no longer capped at a fixed `LIMIT 20`. Explicitly NOT vertical/more-rows lazy loading, and NOT numbered pagination inside a row.
- **"Ver todo" tile removed entirely** from the 8 home carousel rows (`carousel_row.ex:131-141` + `see-all` handling in `catalog_live/index.ex`). A row that exhausts its category simply stops — no trailing CTA card. The known tradeoff (loss of the category→filtered-grid navigation path) was stated to the user and removal confirmed anyway — **do not add it back as a compromise.**
- **Loading indicator = flat, no-shimmer `CarouselRow.skeleton_card/1`**, appended at the trailing edge of the rail while the next page fetches. NOT a spinner, NOT shimmer (shimmer is reserved for filter-triggered row repopulation, sketch 025 — a different, unimplemented moment).

### Claude's Discretion
- Exact trigger mechanism (extend `.CarouselScroll` vs. other).
- Exact page size per fetch-more request; whether `@carousel_limit` stays as the *initial* page size with a separate increment.
- Whether `see_all_selection/1` / the `"see-all"` handler get deleted ("likely yes, to avoid leaving unreachable code — confirm during planning").

### Deferred / OUT OF SCOPE
- The detail page's "Juegos similares" shelf (`Catalog.similar_games/1`, `@similares_limit` 12) — untouched.
- The main grid's `@page_size 24` / `"load-more"` / "Cargar más" button — unrelated, untouched.
- Sketch 025's shimmer repopulation moment — do not build it here.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Elixir + Phoenix 1.8 LiveView, Tailwind + daisyUI, one PostgreSQL DB — fixed, flag before deviating.
- Deploy target is a **GCP e2-micro, 2 shared vCPU / 1 GB RAM + 2 GB swap**. Payload size and server-side memory per connected LiveView are real budgets here, not abstractions.
- `mix quality` gate (7 steps) ends in `test --warnings-as-errors` [VERIFIED: mix.exs:137-145] — **an unused private function left behind after deleting its only caller fails the build.** This directly constrains the `see_all_selection/1` cleanup (see §5).
- **GSD workflow enforcement:** edits must come through a GSD command.
- Mobile-first is the standing priority (user memory `priority_mobile_first.md`).
- Never `String.to_atom/1` on client input — the codebase's established convention is literal-string dispatch clauses with a final catch-all (T-01-37) [VERIFIED: lib/pukllay_club_web/live/catalog_live/index.ex:270-305].

---

## Summary

Three things drive every recommendation below, and all three were measured this session rather than assumed.

**1. The rows are far bigger than `LIMIT 20`.** Live dev-DB counts: 434 games total; the eight rows hold **112 / 61 / 54 / 19 / 179 / 183 / 46 / 408** items. Today's fixed cap hides 90%+ of four rows. One row (`Duelos memorables`, 19 items) is *already exhausted below the cap* — so "the row just stops" is not a rare edge case, it happens on day one and must render correctly.

**2. LiveView's built-in infinite-scroll binding is unusable here.** `phx-viewport-top` / `phx-viewport-bottom` are hard-coded vertical: the hook reads `scrollContainer.scrollTop` and compares `rect.top` / `rect.bottom`, and its scroll-correction calls `scrollIntoView({block: "end"})` [VERIFIED: deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js:1373-1403, 1483-1486]. There is no horizontal equivalent. A custom hook is mandatory — extending the existing `.CarouselScroll` is the right call.

**3. Per-row streams are the correct patching mechanism, but they impose four concrete changes to `carousel_row/1`'s contract** that are easy to miss and each fails loudly-or-silently. They are enumerated in §3.

**Primary recommendation:** extend `.CarouselScroll` with a rAF-throttled `scroll` listener on `this.rail` computing remaining-runway, guarded by a client `pending` flag cleared from the `pushEvent` reply callback; server-side use plain `OFFSET`/`LIMIT` with a `limit + 1` over-fetch to detect exhaustion (no `COUNT`); patch via one `stream/4` per row keyed `:"carousel_#{key}"` appended `at: -1` into `.pk-rail`, which becomes the `phx-update="stream"` container; render the trailing skeletons as **permanent** non-stream children of that container toggled by a CSS class, never by `:if`.

---

## §0. Measured facts (the numbers everything else derives from)

| Row key | Predicate | Items |
|---|---|---|
| `destacados_del_club` | any of the 3 editorial hashtags | **112** |
| `crea_conexiones` | `#CreaConexiones` | 61 |
| `equipo_ganador` | `#EquipoGanador` | 54 |
| `duelos_memorables` | `#DuelosMemorables` | **19** ← already under the cap |
| `descubre_el_hobby` | `weight_band` | 179 |
| `ingenio_estratega` | `weight_band` | **183** |
| `nivel_experto` | `weight_band` | 46 |
| `recientemente_anadidos` | `is_expansion = false` | **408** |

[VERIFIED: `psql pukllay_club_dev`, this session. 434 games total; 26 expansions; 26 with null `weight_band`; 49 with null `thumbnail_url`.]

Card geometry [VERIFIED: assets/css/app.css:365-372, 2465-2482]:
- `.pk-poster-card { width: 160px }`, `.is-hero { width: 240px }`, `.pk-rail { gap: 1rem }`
- `@media (max-width: 480px)`: `.pk-poster-card { width: 96px }`, `.is-hero { width: 118px }`, `.pk-rail { gap: 10px }`

**Consequence:** `recientemente_anadidos` fully paged is 408 × 106px ≈ **43,000px of horizontal scroll on a 390px mobile viewport (~110 viewport-widths)**, and 408 `GameCard`s each embedding a full `GamePreview.preview_template/1` payload [VERIFIED: lib/pukllay_club_web/components/game_card.ex:76]. See Open Question OQ-1.

**Index situation:** `games` has no btree index on `name` or `inserted_at` [VERIFIED: `pg_indexes` query — indexes exist on `id`, `csv_row`, `bgg_id`, `search_vector` (gin), `mechanics`/`themes`/`tags` (gin), `weight_band`, `min_players`, `max_players`, `playing_time`, `min_age`]. At 434 rows a seq-scan + sort is sub-millisecond. **Do not add an index for this task** — `OFFSET 400` on a 434-row table is free.

---

## §1. Scroll trigger — extend `.CarouselScroll` (do NOT use `phx-viewport-*`, do NOT add an IntersectionObserver)

### Ruled out: `phx-viewport-bottom`
Vertical-only, as verified above. Also its throttle is a fixed 500ms and it pushes `{id: lastChild.id}`, neither of which fits a per-row horizontal rail.

### Ruled out: IntersectionObserver on a trailing sentinel
Viable in principle (`root: this.rail` works for a horizontal scroller), but it costs more than it saves *in this specific codebase*:
- The sentinel would have to live inside `.pk-rail`, which becomes the `phx-update="stream"` container. LiveView's own docs state that non-stream items in a stream container **"can be added and updated, but not removed, even if the stream is reset"** [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex:1973]. So the sentinel becomes a permanent node needing CSS-only hide/show — the same bookkeeping the scroll-math approach avoids entirely.
- `.CarouselScroll` already owns `this.rail`, already runs a `sync()` on `mounted()` + `updated()` + a `ResizeObserver`, and already does `cancelAnimationFrame(this.frame)` in `destroyed()` [VERIFIED: lib/pukllay_club_web/components/carousel_row.ex:90-106]. A second observer duplicates that lifecycle for no gain.

### Recommended: a rAF-throttled `scroll` listener inside the existing hook

Add to `.CarouselScroll`'s `mounted()`, alongside the existing `this.onClick` / `this.sync`:

```js
// Fetch-more trigger. One viewport of runway ahead of the rail's end —
// ~7 cards on desktop (160+16px), ~4 on mobile (96+10px), which at a
// sub-millisecond local query is comfortably more than one page of lead time.
this.pending = false
this.exhausted = this.el.dataset.exhausted === "true"
this.rowKey = this.el.dataset.carouselRow

this.maybeLoadMore = () => {
  if (this.pending || this.exhausted) return
  const runway = this.rail.scrollWidth - this.rail.scrollLeft - this.rail.clientWidth
  if (runway > this.rail.clientWidth) return

  this.pending = true
  this.pushEvent("carousel-load-more", {row: this.rowKey}, (reply) => {
    this.pending = false
    if (reply && reply.exhausted) this.exhausted = true
  })
}

// rAF-throttled: a touch-momentum scroll fires `scroll` far more often than
// once per frame, and the read of scrollWidth/scrollLeft/clientWidth forces
// layout — doing it per event rather than per frame is a jank source on the
// mobile-first target.
this.onScroll = () => {
  if (this.scrollFrame) return
  this.scrollFrame = requestAnimationFrame(() => {
    this.scrollFrame = null
    this.maybeLoadMore()
  })
}
this.rail.addEventListener("scroll", this.onScroll, {passive: true})
```

`destroyed()` must gain `this.rail.removeEventListener("scroll", this.onScroll)` and `cancelAnimationFrame(this.scrollFrame)`, matching the existing cleanup discipline.

`updated()` must re-read `this.exhausted = this.el.dataset.exhausted === "true"` so a server-driven exhaustion (or a future filter-triggered row reset) is picked up.

**Why `data-carousel-row` and not parsing `this.el.id`:** the section id is `"carousel-#{row.key}"` [VERIFIED: lib/pukllay_club_web/live/catalog_live/index.ex:540] and is *also* the scroll-spy anchor target consumed by `[data-chip-target]` in `.CatalogNav` [VERIFIED: lib/pukllay_club_web/components/layouts.ex:205-210, index.ex:504-505]. Deriving the row key by string-slicing that id couples two unrelated contracts. Pass it explicitly.

**Why `pushEvent`'s reply callback is the right `pending` release:** `handle_event/3`'s documented return type is `{:noreply, Socket.t()} | {:reply, map, Socket.t()}` [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex:343-344], so the server can hand back `%{exhausted: true}` in the same round trip that delivers the new cards. No polling, no timeout guess.

---

## §2. Server-side pagination — plain `OFFSET`/`LIMIT`, with a tiebreaker and a `limit + 1` over-fetch

### Offset, not keyset. Reasons, in order of weight:
1. **Scale makes keyset's only real advantage irrelevant.** The largest row is 408 rows out of a 434-row table. `OFFSET 400` costs microseconds. Keyset exists to avoid `O(offset)` scans on tables orders of magnitude larger.
2. **Keyset's stability advantage doesn't apply.** It protects against rows being inserted/deleted *between page fetches*. This catalog is a one-time re-runnable seed mix task (D-02) with no writes during a browse session.
3. **The `recientemente_anadidos` row would be materially harder.** Its ordering is `[desc: g.inserted_at, desc: g.csv_row]` [VERIFIED: lib/pukllay_club/catalog.ex:248-253] and `inserted_at` is `timestamp(0)` — second precision, so a bulk seed produces dense ties. A keyset cursor there needs a composite row-value comparison; offset needs nothing.

### Add an `:id` tiebreaker to the name-ordered rows
The seven name-ordered rows use `order_by: [asc: g.name]` [VERIFIED: catalog.ex:237, 244]. There are **0 duplicate names today** [VERIFIED: psql `group by name having count(*) > 1` returned zero rows], but nothing enforces uniqueness — `games` has a unique index only on `id` and `csv_row`. Without a tiebreaker, Postgres may order tied rows differently between the page-1 and page-2 queries, silently duplicating one card and skipping another. Add `asc: g.id`. The recent row already has its `csv_row` tiebreak and needs nothing.

### Recommended shape in `catalog.ex`

The current private helpers bake `limit: ^@carousel_limit` into each query [VERIFIED: catalog.ex:238, 245, 252]. **Lift the limit out** so one paginator serves both the initial page and every increment:

```elixir
@carousel_limit 20        # initial page — unchanged, keeps first-paint cost identical
@carousel_page_size 20    # subsequent in-row increments

def list_carousel_rows do
  Enum.map(carousel_row_specs(), fn {key, title} ->
    {games, exhausted?} = fetch_row_page(key, 0, @carousel_limit)
    %{key: key, title: title, games: games, offset: length(games), exhausted?: exhausted?}
  end)
end

@doc "Next page for one carousel row. Returns `{games, exhausted?}`, or `:error` for an unknown key."
def carousel_page(key, offset, limit \\ @carousel_page_size)

def carousel_page(key, offset, limit) when is_integer(offset) and offset >= 0 do
  case row_query(key) do
    nil -> :error
    _q  -> {:ok, fetch_row_page(key, offset, limit)}
  end
end

# `limit + 1` over-fetch: one extra row tells us whether more exist, with no
# second COUNT query per row. Also makes the *initial* exhausted? correct for
# free — `duelos_memorables` has 19 items, so it is exhausted at first paint.
defp fetch_row_page(key, offset, limit) do
  rows =
    key
    |> row_query()
    |> offset(^offset)
    |> limit(^(limit + 1))
    |> Repo.all()

  {Enum.take(rows, limit), length(rows) <= limit}
end

# Literal clauses with a final catch-all — the T-01-37 convention already used
# by facet_assign_key/1, scalar_assign_key/1 and see_all_selection/1. The client
# sends a STRING row key; never String.to_atom it.
defp row_query("destacados_del_club"), do: tags_query(editorial_tag_values())
defp row_query("crea_conexiones"),     do: tags_query(["#CreaConexiones"])
defp row_query("equipo_ganador"),      do: tags_query(["#EquipoGanador"])
defp row_query("duelos_memorables"),   do: tags_query(["#DuelosMemorables"])
defp row_query("descubre_el_hobby"),   do: weight_band_query("descubre_el_hobby")
defp row_query("ingenio_estratega"),   do: weight_band_query("ingenio_estratega")
defp row_query("nivel_experto"),       do: weight_band_query("nivel_experto")
defp row_query("recientemente_anadidos"), do: recent_query()
defp row_query(_unrecognized),         do: nil
```

Note `list_carousel_rows/0` should then be expressed in terms of the *same* `row_query/1` dispatch (via a `carousel_row_specs/0` list of `{key_string, title}` pairs) so the initial page and the increment can never drift onto different predicates. That drift is the single most likely silent bug in this change: a row whose page 2 comes from a different `WHERE` clause than page 1.

**Page size:** keep initial at 20 and increment at 20. On desktop a 1280px shell (`max-w-7xl`) shows ~7 standard cards, so 20 ≈ 2.9 screens; on a 390px mobile viewport ~3.7 cards, so 20 ≈ 5.4 screens. With a one-viewport trigger threshold that is 2–5 pages of buffer already loaded. There is no case for a larger increment on a 1 GB box.

**`Enum.take(rows, limit)` matters:** the over-fetched 21st row must not reach the stream, or the next page's `offset` (which advances by `@carousel_page_size`) skips it. Prefer advancing offset by `length(games)` rather than a constant, so the two can't disagree.

---

## §3. UI patching — per-row streams, with four contract changes to `carousel_row/1`

### Streams, not assign-append. Why, with the real numbers:
A HEEx comprehension re-sends **every entry's dynamics** when the collection changes — it is not an incremental append. Appending by growing `row.games` therefore re-transmits the whole row on every fetch: for `recientemente_anadidos` that is 20 → 40 → … → 408 cards, each carrying a full `GamePreview.preview_template/1` payload, on a 1 GB e2-micro serving a mobile-first audience. `stream/4` transmits only the new items. The main grid already uses `stream(:games, games, at: -1)` [VERIFIED: index.ex:263], so this is the codebase's existing pattern, not a new one.

Passing a stream into the `CarouselRow` function component **works**: `LiveStream.mark_consumable/1` is applied by the compiler to *whatever* collection expression appears in a HEEx `for` comprehension — it is not special-cased to `@streams.name` syntax [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/engine.ex:485-490].

### The four contract changes (each one breaks silently or loudly if missed)

**(a) `attr :games, :list` must become `attr :games, :any`.**
A `%Phoenix.LiveView.LiveStream{}` is not a list.

**(b) `<section :if={@games != []}>` must be replaced.** [VERIFIED: carousel_row.ex:50]
A struct is never `== []`, so this guard silently becomes always-true and empty rows start rendering. Add an explicit `attr :empty, :boolean` (or `attr :count, :integer`) and guard on that.

**(c) `.pk-rail` becomes the stream container and needs a unique DOM id.**
LiveView requires `phx-update="stream"` on the **immediate parent** with a unique id, and forbids altering the generated item ids [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex:1900-1910]. `.pk-rail` currently has neither [VERIFIED: carousel_row.ex:124]. Becomes `<div data-rail id={"#{@id}-rail"} phx-update="stream" class="pk-rail">`, with `:for={{dom_id, game} <- @games}` and `id={dom_id}` on the card.

**(d) Stream names must be per-row — and this is not optional.**
Default `dom_id` is `"#{stream_name}-#{item.id}"` [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/live_stream.ex:41 — `defp default_id(dom_prefix, %{id: id}), do: dom_prefix <> "-#{to_string(id)}"`]. **The 8 rows overlap by construction** — a `#CreaConexiones` game is simultaneously in `destacados_del_club`, in its weight band, and in `recientemente_anadidos` (112 games carry an editorial tag; 408 are non-expansions) — so a single shared stream name would emit the same DOM id in four different rails. Use `:"carousel_#{key}"`, giving `carousel_crea_conexiones-42` vs `carousel_nivel_experto-42` vs the grid's `games-42`. All globally unique.

`stream/4` accepts `name :: atom | String.t()` [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex:1984-1990], and the 8 keys are a compile-time-fixed hardcoded set (D-10 explicitly forbids a dynamic registry), so building the atom is safe — **but derive it from the server-side row list, never from the client's payload string.**

### Where the trailing skeletons go (this is the subtle one)

The skeletons must sit inside `.pk-rail` for the flex layout — i.e. as non-stream children of a stream container. Two verified facts govern this:

1. **They can never be removed.** *"Items can be added and updated, but not removed, even if the stream is reset"* [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view.ex:1973]. So render them **always**, with stable unique ids (`id={"#{@id}-skel-#{n}"}` — `skeleton_card/1` already requires an `id` [VERIFIED: carousel_row.ex:185]), and toggle visibility with a class bound to the row's `loading?` flag. **Never `:if`.**
2. **They will stay at the trailing edge automatically.** For `at: -1`, LiveView's `addChild` checks whether the container's `lastElementChild` carries a stream ref; if it does not, the new item is inserted *before* the first non-stream child [VERIFIED: deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js:2486-2495]. Permanent trailing skeletons therefore remain trailing as pages append — no manual re-ordering needed.

### Scroll position is preserved for free — but only with `at: -1`
Appending nodes to the end of a horizontally scrolled flex container does not move content already to the left of the viewport, so `scrollLeft` is untouched. `at: 0` (prepend) *would* jump. The grid's existing `at: -1` [VERIFIED: index.ex:263] is the same reason.

### Do NOT reach for `stream/4`'s `:limit` option to bound DOM growth
`:limit` prunes items *"from the beginning of the container"* for a negative limit [VERIFIED: deps/phoenix_live_view.ex:1880-1883]. Removing nodes from the left of a horizontally scrolled rail shifts everything and produces a visible scroll jump. It is the obvious-looking tool here and it is wrong.

### `sync()` / `data-overflows` needs no change
`.CarouselScroll` already observes `this.rail` with a `ResizeObserver` [VERIFIED: carousel_row.ex:96-97], so appended cards widening the rail re-fire `sync()` and `data-overflows` stays correct without touching the arrow logic.

---

## §4. Debounce / race guards — two layers, both needed

**Client (prevents the storm):** the `pending` flag above, released only in the `pushEvent` reply callback, plus the rAF throttle. Without the rAF throttle a single momentum fling on touch fires dozens of `scroll` events, each forcing a layout read of `scrollWidth`/`scrollLeft`/`clientWidth`.

**Server (the authoritative guard):** a client can push any event at any time, so the LiveView must be idempotent-ish on its own.

```elixir
def handle_event("carousel-load-more", %{"row" => row_key}, socket) when is_binary(row_key) do
  case find_row(socket.assigns.carousel_rows, row_key) do
    # Unknown key, or already exhausted → no-op reply, no query.
    nil -> {:reply, %{exhausted: true}, socket}
    %{exhausted?: true} -> {:reply, %{exhausted: true}, socket}

    row ->
      case Catalog.carousel_page(row_key, row.offset) do
        {:ok, {games, exhausted?}} ->
          {:reply, %{exhausted: exhausted?},
           socket
           |> stream(:"carousel_#{row.key}", games, at: -1)
           |> update_row(row.key, offset: row.offset + length(games), exhausted?: exhausted?)}

        :error ->
          {:reply, %{exhausted: true}, socket}
      end
  end
end
```

**A LiveView process handles messages sequentially**, so two rapid events cannot interleave into a genuine double-fetch of the same offset — the second sees the already-advanced `offset`. The server guard's real jobs are: (1) refusing unknown/forged row keys without ever building an atom or a query from them, (2) short-circuiting once exhausted so a scroll-happy client can't issue unbounded queries, (3) telling the client to stop.

**Note the existing precedent for wrapping catalog reads:** `apply_filters/1` rescues query failures into a `:load_error` banner rather than crashing the LiveView (T-01-24) [VERIFIED: index.ex:344-368]. `carousel_page/3` should follow the same discipline — but a failed *carousel* fetch should degrade to "row stops" (set `exhausted?: true`), **not** raise the full-page `:load_error` banner, which is scoped to the main grid.

---

## §5. Removing "Ver todo" — the full blast radius

Every reference found by exhaustive grep this session:

| Location | What | Disposition |
|---|---|---|
| `carousel_row.ex:46` | `attr :see_all_row, :string, default: nil` | Delete |
| `carousel_row.ex:131-141` | The `.pk-see-all` `<button phx-click="see-all">` tile | Delete |
| `index.ex:545` | `see_all_row={to_string(row.key)}` | Delete |
| `index.ex:226-249` | `handle_event("see-all", %{"row" => row}, socket)` | Delete — no caller remains |
| `index.ex:286-305` | `see_all_selection/1`, 9 clauses | **Must be deleted in the same commit** |
| `assets/css/app.css:374-398` | `.pk-see-all` + `.pk-see-all:hover` | Delete (dead selectors) |
| `catalog_live_test.exs:932-999` | `describe "Ver todo tile wired to real filter state (01-11)"`, 4 tests | **Delete the whole block — all 4 break** |
| `catalog_live_test.exs:1090` | `assert carousel_html =~ "pk-see-all"` | **Delete this one line** (inside a larger structural test that otherwise stays) |
| `catalog_show_test.exs:336` | `refute html =~ "pk-see-all"` | Still passes (a refute) — becomes vacuous. Leave or delete; no build impact. |

**The build-breaking coupling:** `see_all_selection/1` is called from exactly one place, the `"see-all"` handler. Deleting the handler and leaving the helper produces an unused-private-function warning, and `mix quality` step 7 is `test --warnings-as-errors` [VERIFIED: mix.exs:144]. **They must go together.** Answer to CONTEXT.md's open question: **yes, delete both.**

**Safe to leave alone:** the `Vocabulary` alias in `index.ex` — it is still used by `handle_params/3` (`Vocabulary.mechanic_options()` etc., index.ex:95-98) and by `editorial_tag_meaning/1` / `weight_band_descriptor/1` (index.ex:409-423). Removing `see_all_selection/1` does not orphan it.

**One factual consequence, not a recommendation:** the mega-menu and mobile chip row render `href={"#carousel-#{row.key}"}` anchors [VERIFIED: index.ex:503-506] that *scroll to* a shelf; they do not apply filter state. With the tile gone, no UI surface reaches a category's filtered grid view. CONTEXT.md records this as accepted.

---

## §6. Coupling that will bite: `index_rows/1` and `@carousel_rows`

`index_rows/1` feeds **both** the desktop mega-menu and the mobile chip row from one derived list, and filters with `Enum.filter(&(&1.games != []))` [VERIFIED: index.ex:431-435 — `assigns.carousel_rows |> Enum.filter(&(&1.games != [])) |> Enum.map(...)`]. The moduledoc for that function calls the single-source rule "sketch-findings' single most load-bearing rule for this layer."

Once games move into streams, `row.games` no longer exists on the row map — `&(&1.games != [])` either raises or silently passes. **Keep a non-stream emptiness signal on each row map** (`empty?: games == []`, or the `offset` count) and update this filter to read it. Same signal feeds `carousel_row/1`'s `:if` guard from §3(b), so define it once.

## §7. The one genuinely uncertain mechanism

The 8 rows render inside `:for={row <- @carousel_rows}` [VERIFIED: index.ex:538-546], so a stream comprehension would sit **nested inside another comprehension**. Reading `diff.ex`, `traverse/6` recurses through `Comprehension` structs generically and `maybe_add_stream/2` attaches the stream payload at whatever depth it appears [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/diff.ex:483-536, 859-860] — so nesting is *structurally* supported. But the outer comprehension is diffed **positionally** unless keyed, and I found no test or doc guaranteeing nested-stream behaviour. [ASSUMED — mechanism inferred from source, not verified end-to-end.]

Two mitigations, in order of preference:
1. **Add `:key={row.key}` to the outer `:for`.** `:key` is a supported special attribute in LiveView 1.2.9 [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/tag_engine/compiler.ex:708, 1074, 1136-1143 — `@special_attrs ~w(:let :if :for :key)`; note `:key` raises without `:for`, and is rejected on slots]. This makes the outer entries keyed rather than positional.
2. **Unroll the 8 rows** into 8 explicit `<CarouselRow.carousel_row ... />` calls. The set is hardcoded by design (D-10 defers a dynamic registry to Phase 4), so this costs only verbosity. Falls back to the fully-documented flat-stream case.

**Either way, verify in a real browser before building the rest:** append a page to row 3 and confirm only row 3's rail gains cards, and that rows 1/2/4-8 keep their scroll positions.

---

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Appending items without re-sending the list | A manual "only new games" assign + `phx-update="append"` | `stream/4` with `at: -1` | `phx-update="append"` is legacy; streams are the supported path and the grid already uses them |
| Detecting "more pages exist" | A second `COUNT(*)` per row per fetch (8 extra queries) | `limit + 1` over-fetch | One query, and it makes the *initial* `exhausted?` correct for free (matters for the 19-item row) |
| Throttling scroll | `setTimeout`/`lodash.debounce` | `requestAnimationFrame` gate | Already the hook's idiom (`this.frame`, `cancelAnimationFrame` in `destroyed()`); a layout-reading handler should run at most once per frame |
| Knowing when the fetch finished | A fixed `setTimeout` before clearing `pending` | `pushEvent`'s reply callback + `{:reply, map, socket}` | Exact, and carries `exhausted` in the same round trip |
| A loading placeholder | A new spinner or shimmer variant | `CarouselRow.skeleton_card/1` verbatim | Locked by CONTEXT.md; shimmer is reserved for sketch 025's repopulation moment |

## Common Pitfalls

1. **Page 1 and page N built from different predicates.** The most likely silent bug. Route `list_carousel_rows/0` and `carousel_page/3` through one `row_query/1`.
2. **Over-fetched 21st row leaking into the stream** → next `offset` skips a game. `Enum.take(rows, limit)`, and advance offset by `length(games)`.
3. **Shared stream name across rows** → duplicate DOM ids, because the rows genuinely overlap (§3d).
4. **`:if` on the trailing skeletons** → they render once and can never be removed (§3, verified doc quote). Class toggle only.
5. **`@games != []` guard left in place** with a stream → empty rows start rendering (§3b).
6. **`index_rows/1`'s `&(&1.games != [])`** left reading a field that no longer exists (§6).
7. **`see_all_selection/1` left behind** after deleting its caller → `mix quality` fails on `--warnings-as-errors` (§5).
8. **Reaching for `stream/4`'s `:limit`** to bound DOM growth → visible scroll jump on a horizontal rail (§3).
9. **Creating the 8 streams in both `mount/3` and `handle_params/3`.** `index.ex:63-75` documents at length that stream diffs accumulate across multiple `stream/4` calls issued before the first render flush, so a second `reset: true` does not clear the first. Create the carousel streams in exactly one place — the connected `mount/3` branch, where `list_carousel_rows/0` is already called [VERIFIED: index.ex:61].

## Validation Architecture

`nyquist_validation: true` [VERIFIED: .planning/config.json].

| Property | Value |
|---|---|
| Framework | ExUnit + `Phoenix.LiveViewTest` + `LazyHTML` |
| Quick run | `mix test test/pukllay_club/catalog_test.exs test/pukllay_club_web/live/catalog_live_test.exs` |
| Full suite | `mix quality` (7 steps, ends `test --warnings-as-errors`) |

| Behavior | Test type | Command | File |
|---|---|---|---|
| `carousel_page/3` returns page 2 with no overlap/gap vs page 1 | unit | `mix test test/pukllay_club/catalog_test.exs` | exists |
| `carousel_page/3` sets `exhausted?` when a row is shorter than the limit (the 19-item case) | unit | same | exists |
| `carousel_page/3` returns `:error` for an unknown row key without creating an atom | unit | same | exists |
| `"carousel-load-more"` appends to one row's rail only | integration | `mix test test/pukllay_club_web/live/catalog_live_test.exs` | exists |
| `"carousel-load-more"` on an exhausted/unknown row is a no-op | integration | same | exists |
| No `pk-see-all` / `phx-click="see-all"` anywhere in the rendered `/` | integration | same | exists |

**Wave 0 gaps:** none — both target test files exist. Note that `render_click(view, "carousel-load-more", %{...})` exercises the server contract but **cannot** exercise the JS trigger, `pending` flag, or scroll-position preservation. Those need the headless-Chrome CDP measurement approach this repo already used in quick task 260824-jkc (which caught two layout bugs ExUnit could not).

## Environment Availability

| Dependency | Available | Notes |
|---|---|---|
| PostgreSQL (`pukllay_club_dev`) | ✓ | `pg_isready` OK; 434 games seeded |
| Phoenix LiveView | ✓ 1.2.9 | Colocated hooks auto-registered via `import {hooks as colocatedHooks} from "phoenix-colocated/pukllay_club"` [VERIFIED: assets/js/app.js:25,32] — no `app.js` edit needed for the hook change |

**No new packages are installed by this task**, so the Package Legitimacy Audit is not applicable.

## Open Questions

**OQ-1 — Should a row have a hard ceiling?** `recientemente_anadidos` fully paged is 408 cards ≈ 43,000px of horizontal scroll on mobile (~110 viewport-widths), each card carrying a `GamePreview.preview_template/1` payload, on a 1 GB e2-micro. Netflix caps its own rows. But CONTEXT.md locks "the row just stops when its category is exhausted," and a ceiling is arguably a deviation.
- *What we know:* the numbers above, all measured.
- *What's unclear:* whether the user considers a `@carousel_max` (e.g. 100/row) a violation of the locked decision or an unstated implementation detail.
- *Recommendation:* **surface this to the user during planning rather than deciding silently.** If a cap is accepted, implement it as a server-side ceiling that sets `exhausted?: true` (the row stops, indistinguishable from exhaustion) — **not** as `stream/4`'s `:limit`, which scroll-jumps.

**OQ-2 — Nested stream comprehension.** See §7. Resolve with `:key` or unrolling, then verify in a browser before building on it.

## Sources

**Primary (HIGH — read from vendored source this session):**
- `deps/phoenix_live_view/lib/phoenix_live_view.ex` — `stream/4` docs & spec (1806-1995), `handle_event` return spec (343-344), stream DOM requirements (1895-1911), non-stream-items-in-stream-containers (1963-1982), `:limit` pruning direction (1871-1894)
- `deps/phoenix_live_view/lib/phoenix_live_view/live_stream.ex` — `default_id/2` (41), `mark_consumable/1`
- `deps/phoenix_live_view/lib/phoenix_live_view/engine.ex` — comprehension→stream compilation (477-548)
- `deps/phoenix_live_view/lib/phoenix_live_view/diff.ex` — recursive `Comprehension` traversal + `maybe_add_stream/2` (483-604, 859-860)
- `deps/phoenix_live_view/lib/phoenix_live_view/tag_engine/compiler.ex` — `:key` special attr (708-716, 1074, 1128-1143)
- `deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js` — vertical-only `InfiniteScroll` hook (1373-1486), `addChild` stream-insert ordering (2482-2500)
- Live dev DB via `psql pukllay_club_dev` — all row counts, duplicate-name check, index inventory
- Repo files read in full: `lib/pukllay_club/catalog.ex`, `lib/pukllay_club_web/components/carousel_row.ex`, `lib/pukllay_club_web/live/catalog_live/index.ex`, `lib/pukllay_club_web/components/game_card.ex`, `assets/css/app.css` (rail/skeleton blocks), `mix.exs` aliases, the three affected test files

**Secondary (MEDIUM):**
- `.claude/skills/sketch-findings-pukllay_club/references/carousel-mechanics.md` — the two loading semantics, no-snap/free-momentum, no position indicator
- `.claude/skills/ux-patterns/SKILL.md` — B7 (load-more for the main grid), B9 (carousels)

## Metadata

- Standard stack: HIGH — no new dependencies; everything already in the tree
- Architecture: HIGH for §1/§2/§3/§4/§5/§6; MEDIUM for §7 (nested-stream mechanism inferred from source)
- Pitfalls: HIGH — each traced to a specific verified line
- **Research date:** 2026-08-24 · **Valid until:** stable (pinned deps, in-repo facts)

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | A stream comprehension nested inside an outer `:for` diffs correctly | §7 | Cards land in the wrong rail or fail to append; mitigated by `:key` / unrolling + a browser check before further work |
| A2 | One viewport of runway is the right trigger threshold | §1 | Only tuning — too early wastes a query, too late shows a gap; adjust the multiplier after a live feel test |
