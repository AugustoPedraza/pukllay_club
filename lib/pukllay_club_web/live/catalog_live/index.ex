defmodule PukllayClubWeb.CatalogLive.Index do
  @moduledoc """
  Public browse entry point at `/` (CATALOG-01, CATALOG-02, CATALOG-03,
  CATALOG-04, CATALOG-08). Fully unauthenticated — no auth plug, no
  `current_scope` requirement, the `:browser` pipeline is reused
  unmodified. Reads exclusively through `PukllayClub.Catalog`, never
  `Repo` directly.

  Filter state (`:q`, `:mechanics`, `:themes`, `:weight_bands`, `:tags`,
  `:players`, `:max_playtime`, `:min_age`, `:sort`, `:offset`, `:total`)
  lives in assigns. Every filter-changing event funnels through
  `apply_filters/1` — the one place that decides pagination-reset
  semantics (D-12): it recomputes results, resets `:offset` to the first
  page, sets `:total`, and resets the `:games` stream. `"load-more"` is
  the only event that appends instead (01-RESEARCH.md Pattern 4).

  Catalog reads are wrapped in `apply_filters/1`'s `rescue` so a query
  failure (e.g. a crafted scalar value Postgres rejects) renders the
  UI-SPEC error banner instead of crashing the LiveView (T-01-24).

  `:loading` is true only for the very first, *disconnected* static render
  (`connected?(socket) == false`) — the standard LiveView two-phase mount
  trick: the disconnected render paints instantly with skeleton
  placeholders (no DB round-trip on that pass), then the connected
  websocket mount replaces it with real carousel/grid data. It is set once
  in `mount/3` and never toggled again by any `handle_event`.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.CarouselRow
  alias PukllayClubWeb.CatalogFilters
  alias PukllayClubWeb.FilterModal
  alias PukllayClubWeb.GameCard
  alias PukllayClubWeb.GamePreview

  @page_size 24
  @skeleton_carousel_rows 8

  @impl true
  def mount(params, _session, socket) do
    loading? = not connected?(socket)
    q = CatalogFilters.q(params)

    socket =
      socket
      |> assign(:page_title, "Ludoteca")
      |> assign(:q, q)
      # Member-owned, server-rendered open/closed state for the header's
      # search-morph (01.2-11, closes G-01.2-2/G-01.2-3). Seeded true only
      # when the mount URL already carries a query — handle_params/3 widens
      # this (never narrows it) as more filter params arrive; only the
      # close-search event ever sets it back to false. apply_filters/1 never
      # reads or writes this assign — opening/closing the box changes no
      # filter.
      |> assign(:search_expanded, q != "")
      |> assign(:mechanics, [])
      |> assign(:themes, [])
      |> assign(:weight_bands, [])
      |> assign(:tags, [])
      |> assign(:designers, [])
      |> assign(:artists, [])
      |> assign(:players, nil)
      |> assign(:max_playtime, nil)
      |> assign(:min_age, nil)
      |> assign(:sort, :name_asc)
      |> assign(:filters_open, false)
      |> assign(:loading, loading?)
      |> assign(:page_size, @page_size)
      |> assign(:skeleton_carousel_rows, @skeleton_carousel_rows)
      |> assign(:facet_options, if(loading?, do: empty_facet_options(), else: Catalog.facet_options()))
      |> assign_carousel_rows(loading?)

    # 01.1-06: mount/3 no longer calls apply_filters/1 on the connected
    # branch — it only ever set *default* filter state anyway, and
    # handle_params/3 (which Phoenix always invokes right after mount, on
    # both the disconnected and connected phases) is what applies whatever
    # the URL actually supplied. Calling apply_filters/1 (and therefore
    # stream/4 with reset: true) from BOTH callbacks before the first render
    # is a real bug, not just redundant work: LiveView's stream diff
    # accumulates insert operations across multiple stream/4 calls issued
    # before any render has flushed, so a second reset: true does not
    # actually clear the first call's entries — the initial page would
    # render every game from the connected-mount default pass AND every
    # game from the handle_params pass concatenated together. Skeleton
    # placeholders on both branches keep parity until handle_params runs.
    socket =
      socket
      |> assign(:offset, 0)
      |> assign(:total, 0)
      |> assign(:load_error, false)
      # D-03: a second, deliberately separate error channel from
      # :load_error. :load_error means "the catalog read that produces
      # this page failed" and owns the full-page banner with its
      # Reintentar action; :more_error means "one additional page failed
      # while the member was already reading results" and owns a compact
      # inline line under the grid instead. Merging them would blank a
      # working grid over a transient mid-scroll failure.
      |> assign(:more_error, false)
      |> assign(:from_query, "")
      # D-01/D-02: records that the member explicitly asked to see the
      # full-catalog grid (the filter modal's primary CTA, "apply-filters"
      # below) — deliberately socket-only, never a URL param. Unlike every
      # other filter assign, it never narrows or reorders the result set;
      # it only picks which of the two browse surfaces (carousels vs.
      # grid) renders over an otherwise identical query, so it takes no
      # part in filter_opts/1, apply_filters/1, or
      # CatalogFilters.to_query/1's D-08 breadcrumb query string.
      |> assign(:browse_all, false)
      # Bug found while implementing D-01/D-02 (Rule 1): a
      # `phx-update="stream"` container that gets removed from the DOM
      # (as carousel-rows now is, via the :if below, whenever
      # browsing_results? flips true) does NOT automatically repopulate
      # its items when the container reappears — LiveView only ever sends
      # *new* inserts, and the per-row streams already delivered their
      # one and only batch back at this same mount. Left unfixed, every
      # "clear filters" / empty-submission-then-dismiss round trip would
      # return the member to a carousel section with the right headings
      # but zero cards. :carousel_needs_reset tracks whether the carousel
      # was hidden since it was last populated; see sync_carousel_visibility/1.
      |> assign(:carousel_needs_reset, false)
      |> stream(:games, [])

    # Seeds :rendered_results correctly for the very first paint (Task 2,
    # G-01.2-4 defect C) — settle_surface/1 is a no-op only while
    # :filters_open is true, which it never is at mount, so this always
    # runs and computes from whatever :q the URL already supplied above
    # (matching the disconnected-render behaviour the inline predicate call
    # used to have, byte for byte).
    socket = settle_surface(socket)

    {:ok, socket}
  end

  # Read-in-only URL deep-linking (01.1-06, SHELL-04). Runs after mount/3's
  # defaults and overrides only what the URL actually supplied — this module
  # never writes filter state back to the address bar (deliberately out of
  # scope, see 01.1-06-PLAN.md flagged_assumptions #3). Skipped on the
  # disconnected static render — the skeleton state from mount/3 is fine
  # there; the connected mount is what needs the real params.
  @impl true
  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      # Captured BEFORE reassigning filters, so this reads whatever the
      # member's session already had (including a deliberate close-search).
      was_filtered? = filters_active?(socket.assigns)
      filters = CatalogFilters.from_params(params)

      socket =
        socket
        |> assign(:q, filters.q)
        |> assign(:mechanics, filters.mechanics)
        |> assign(:themes, filters.themes)
        |> assign(:weight_bands, filters.weight_bands)
        |> assign(:tags, filters.tags)
        |> assign(:designers, filters.designers)
        |> assign(:artists, filters.artists)
        |> assign(:players, filters.players)
        |> assign(:max_playtime, filters.max_playtime)
        |> assign(:min_age, filters.min_age)
        |> assign(:sort, filters.sort)

      # Widen-only, and only on a genuine TRANSITION into "has active
      # filters" caused by THIS params application — a URL that newly
      # carries a query or facet may OPEN the box, but nothing derived from
      # params may ever force it closed, and re-processing filter state
      # that was ALREADY active before this call (e.g. a patch to the exact
      # same query after the member explicitly closed the box) must not
      # resurrect it either — that's the exact contract violation that let
      # a server round-trip strip an open box shut, and its mirror image
      # (a member's close being immediately undone), both G-01.2-2/
      # G-01.2-3. Only the close-search event ever sets this false.
      now_filtered? = filters_active?(socket.assigns)

      socket =
        socket
        |> assign(:search_expanded, socket.assigns.search_expanded or (now_filtered? and not was_filtered?))
        |> apply_filters()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp empty_facet_options, do: %{mechanics: [], themes: [], weight_bands: [], editorial_tags: []}

  # Connected-mount-only (never also in handle_params/3, see the comment on
  # mount/3 above about accumulating stream diffs across two stream/4 calls
  # issued before the first render flush) construction of the 8 per-row
  # carousel streams plus their metadata (quick task 260824-u5d, in-row
  # infinite scroll). Per-row stream names are mandatory, not stylistic —
  # the 8 rows genuinely overlap (a tagged game sits in up to 4 rows at
  # once), so one shared stream name would emit the same DOM id in four
  # different rails. The atom is derived only from Catalog's own
  # server-side row list, never from client input.
  defp assign_carousel_rows(socket, true), do: assign(socket, :carousel_rows, [])

  defp assign_carousel_rows(socket, false) do
    rows = Catalog.list_carousel_rows()

    socket =
      Enum.reduce(rows, socket, fn row, acc ->
        stream(acc, carousel_stream_name(row.key), row.games)
      end)

    assign(socket, :carousel_rows, Enum.map(rows, &carousel_row_metadata/1))
  end

  # The games themselves now live only in the per-row streams — this
  # metadata map carries everything else `carousel_row/1`'s render and
  # `handle_event("carousel-load-more", ...)` need: `empty?` is the one
  # shared non-stream emptiness signal both the chip-nav filter below and
  # `CarouselRow.carousel_row/1`'s section guard read (a `%LiveStream{}`
  # is never `== []`, so a guard left reading `row.games != []` would
  # silently start rendering empty rows).
  defp carousel_row_metadata(row) do
    %{
      key: row.key,
      title: row.title,
      offset: row.offset,
      exhausted?: row.exhausted?,
      empty?: row.games == []
    }
  end

  defp carousel_stream_name(key), do: :"carousel_#{key}"

  defp find_carousel_row(rows, row_key) do
    Enum.find(rows, &(Atom.to_string(&1.key) == row_key))
  end

  defp update_carousel_row(socket, key, changes) do
    changes = Map.new(changes)

    rows =
      Enum.map(socket.assigns.carousel_rows, fn
        %{key: ^key} = row -> Map.merge(row, changes)
        row -> row
      end)

    assign(socket, :carousel_rows, rows)
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, socket |> assign(:q, String.slice(q, 0, 100)) |> apply_filters()}
  end

  # Server-owned search-morph open/close (01.2-11). Neither calls
  # apply_filters/1 — opening or closing the box changes no filter, only
  # whether it is visible.
  def handle_event("open-search", _params, socket) do
    {:noreply, assign(socket, :search_expanded, true)}
  end

  def handle_event("close-search", _params, socket) do
    {:noreply, assign(socket, :search_expanded, false)}
  end

  def handle_event("open-filters", _params, socket) do
    {:noreply, assign(socket, :filters_open, true)}
  end

  # Dismissal (X/backdrop) — changes no filter, but Task 2 (G-01.2-4 defect
  # C) now makes it re-enter apply_filters/1 once :filters_open is false,
  # exactly like "apply-filters" below. This is what settles
  # :rendered_results onto whatever surface was already live underneath
  # the modal, and — if the grid is about to reappear — repopulates its
  # stream with a reset in the same round trip the grid reappears in. The
  # extra query this costs is identical to the one every keystroke already
  # ran while the modal was open; it now fires once per close instead.
  def handle_event("close-filters", _params, socket) do
    {:noreply, socket |> assign(:filters_open, false) |> apply_filters()}
  end

  # D-02's one explicit submission signal, dispatched only by the filter
  # modal's footer CTA (FilterModal Task 1). Sets :browse_all (see mount/3's
  # comment on that assign) and closes the modal, then re-enters
  # apply_filters/1 (Task 2, G-01.2-4 defect C) — :filters_open must
  # already be false when apply_filters/1 runs, since settle_surface/1
  # (called from inside apply_filters/1) is a no-op while the modal is
  # open. This is what settles :rendered_results onto the surface
  # :browse_all now dictates AND repopulates the grid stream with a reset
  # in the same round trip the grid reappears in — without it, a grid
  # frozen out of the DOM while the member filtered would come back empty,
  # the mirror of the carousel bug sync_carousel_visibility/1 was written
  # to fix. :carousel_needs_reset is no longer set explicitly here:
  # sync_carousel_visibility/1 (now reached via apply_filters/1) derives it
  # from :rendered_results itself.
  def handle_event("apply-filters", _params, socket) do
    socket =
      socket
      |> assign(:browse_all, true)
      |> assign(:filters_open, false)
      |> apply_filters()

    {:noreply, socket}
  end

  # The active-filters summary's query chip (Task 1, sketch 029) has no
  # existing toggle to reuse — shaped like `retry` below: parameterless,
  # reads nothing from the client, re-enters the shared apply_filters/1
  # pipeline every other filter-changing handler uses.
  def handle_event("clear-query", _params, socket) do
    {:noreply, socket |> assign(:q, "") |> apply_filters()}
  end

  # The payload key is `choice`, not `value`: LiveView's client-side
  # `extractMeta` overwrites `payload.value` with the clicked element's
  # native `.value` DOM property (`""` for a `<button>`, `"on"` for a
  # checkbox), silently clobbering any `phx-value-value` binding. See the
  # `FilterModal` moduledoc for the full mechanism — this key must stay in
  # sync with the `phx-value-choice` attributes there.
  def handle_event("toggle-facet", %{"facet" => facet, "choice" => value}, socket) do
    case facet_assign_key(facet) do
      nil ->
        {:noreply, socket}

      key ->
        current = Map.get(socket.assigns, key, [])
        updated = if value in current, do: List.delete(current, value), else: [value | current]

        {:noreply, socket |> assign(key, updated) |> apply_filters()}
    end
  end

  # Chip-shaped toggle for the players/max_playtime scalar filters
  # (quick-260824-b71) — shaped like `toggle-facet` above rather than a
  # form-wide scalar-setting handler: each chip click sends exactly one
  # scalar/value pair, so clicking one scalar chip never touches another
  # scalar's current value (the regression a shared form would have
  # caused via `parse_int(nil)` on the untouched fields). `min_age` has
  # no chip and no entry in `scalar_assign_key/1` — it stays unfilterable
  # via the UI, exactly as it is today; the field remains a valid
  # `?min_age=` URL param via `handle_params/3` only.
  def handle_event("toggle-scalar", %{"scalar" => scalar, "choice" => value}, socket) do
    case scalar_assign_key(scalar) do
      nil ->
        {:noreply, socket}

      key ->
        current = Map.get(socket.assigns, key)
        parsed = CatalogFilters.parse_int(value)
        new_value = if parsed == current, do: nil, else: parsed

        {:noreply, socket |> assign(key, new_value) |> apply_filters()}
    end
  end

  # 01.1-07: the load-error state's Reintentar action. Re-enters the same
  # apply_filters/1 pipeline every other filter-changing event uses — it
  # already clears :load_error on success and re-sets it on failure, so no
  # new error handling is needed here.
  def handle_event("retry", _params, socket) do
    {:noreply, apply_filters(socket)}
  end

  # Dispatched both from FilterModal's own footer (inside the modal — Task
  # 2, G-01.2-4 defect C) and from the empty-state banner (outside it,
  # :filters_open already false there). :filters_open is set false
  # unconditionally so both call sites end up settled the same way — a
  # no-op re-assignment when it was already false, the modal-closing half
  # of the contract when it wasn't.
  def handle_event("clear-filters", _params, socket) do
    socket =
      socket
      |> assign(:q, "")
      |> assign(:mechanics, [])
      |> assign(:themes, [])
      |> assign(:weight_bands, [])
      |> assign(:tags, [])
      |> assign(:designers, [])
      |> assign(:artists, [])
      |> assign(:players, nil)
      |> assign(:max_playtime, nil)
      |> assign(:min_age, nil)
      |> assign(:sort, :name_asc)
      |> assign(:browse_all, false)
      |> assign(:filters_open, false)
      |> apply_filters()

    {:noreply, socket}
  end

  # In-row horizontal infinite scroll (quick task 260824-u5d). The client
  # (`.CarouselScroll`'s rAF-throttled scroll listener, added in Task 2)
  # sends the row key it read off its own section's data attribute — fully
  # attacker-controlled, so this handler is the authoritative guard
  # (T-u5d-01/T-u5d-02): an unknown key, or a row the server already
  # considers exhausted, short-circuits to a no-op reply with no query at
  # all, never building an atom from `row_key`. A LiveView process handles
  # events sequentially, so two rapid taps can't interleave into a
  # double-fetch of the same offset — the second sees the already-advanced
  # offset from the first. A failed carousel fetch degrades that one row
  # to exhausted; it must NOT raise the full-page :load_error banner,
  # which is scoped to the main grid (T-01-24's precedent).
  def handle_event("carousel-load-more", %{"row" => row_key}, socket) when is_binary(row_key) do
    case find_carousel_row(socket.assigns.carousel_rows, row_key) do
      nil ->
        {:reply, %{exhausted: true}, socket}

      %{exhausted?: true} ->
        {:reply, %{exhausted: true}, socket}

      row ->
        case Catalog.carousel_page(row_key, row.offset) do
          {:ok, {games, exhausted?}} ->
            socket =
              socket
              |> stream(carousel_stream_name(row.key), games, at: -1)
              |> update_carousel_row(row.key, offset: row.offset + length(games), exhausted?: exhausted?)

            {:reply, %{exhausted: exhausted?}, socket}

          :error ->
            {:reply, %{exhausted: true}, update_carousel_row(socket, row.key, exhausted?: true)}
        end
    end
  end

  # D-03 (auto-loading infinite scroll): reply-carrying on all three paths,
  # mirroring carousel-load-more's own discipline above. The pre-query
  # guard is the handler's first action and the AUTHORITATIVE stop
  # (T-01.2-17) — data-exhausted on the client is only an optimisation, so
  # a client that ignores it and keeps firing this event can never force
  # an unbounded read past :total: once :offset has reached :total, this
  # replies exhausted without a single query against the database, the
  # same clamp-before-query discipline fetch_row_page/3 applies per
  # carousel row. On success, one round trip carries both the new cards
  # and the stop signal. On failure, :more_error is set — never
  # :load_error, which stays scoped to the initial catalog read — so the
  # cards already on screen are never disturbed by a mid-scroll failure.
  def handle_event("load-more", _params, socket) do
    %{offset: offset, total: total} = socket.assigns

    if offset >= total do
      {:reply, %{exhausted: true}, socket}
    else
      opts =
        socket.assigns
        |> filter_opts()
        |> Map.put(:offset, offset)
        |> Map.put(:limit, @page_size)

      case safe_filter_games(opts) do
        {:ok, games} ->
          new_offset = offset + @page_size

          socket =
            socket
            |> assign(:offset, new_offset)
            |> assign(:more_error, false)
            |> stream(:games, games, at: -1)

          {:reply, %{exhausted: new_offset >= total}, socket}

        :error ->
          {:reply, %{error: true}, assign(socket, :more_error, true)}
      end
    end
  end

  defp facet_assign_key("mechanics"), do: :mechanics
  defp facet_assign_key("themes"), do: :themes
  defp facet_assign_key("weight_bands"), do: :weight_bands
  defp facet_assign_key("tags"), do: :tags
  # 01.3-06: literal clauses only, never a dynamic-atom conversion from
  # client input (T-01-37) — a creator-pill chip's `toggle-facet`
  # removal routes through the same dispatcher as every other facet, so
  # these two keys need no new remove-creator handler.
  defp facet_assign_key("designers"), do: :designers
  defp facet_assign_key("artists"), do: :artists
  defp facet_assign_key(_unrecognized), do: nil

  # Same never-build-an-atom-from-client-input discipline as
  # `facet_assign_key/1` above (T-01-37) — literal clauses with a final
  # catch-all, no dynamic atom conversion from the client-supplied string.
  # Only `players`/`max_playtime` are chip-controlled; `min_age`
  # deliberately has no clause here (quick-260824-b71 scope correction: no
  # age filter control anywhere in the UI).
  defp scalar_assign_key("players"), do: :players
  defp scalar_assign_key("max_playtime"), do: :max_playtime
  defp scalar_assign_key(_unrecognized), do: nil

  defp filter_opts(assigns) do
    %{
      q: assigns.q,
      mechanics: assigns.mechanics,
      themes: assigns.themes,
      weight_bands: assigns.weight_bands,
      tags: assigns.tags,
      designers: assigns.designers,
      artists: assigns.artists,
      players: assigns.players,
      max_playtime: assigns.max_playtime,
      min_age: assigns.min_age,
      sort: assigns.sort
    }
  end

  defp apply_filters(socket) do
    opts = socket.assigns |> filter_opts() |> Map.put(:offset, 0) |> Map.put(:limit, @page_size)
    socket = assign(socket, :from_query, CatalogFilters.to_query(filter_opts(socket.assigns)))

    # :more_error is reset on both branches here: a filter change resets
    # pagination (D-12), so a stale mid-scroll failure must not survive it.
    socket =
      case safe_filter_games(opts) do
        {:ok, games} ->
          socket
          |> assign(:offset, @page_size)
          |> assign(:total, Catalog.count_games(opts))
          |> assign(:load_error, false)
          |> assign(:more_error, false)
          |> stream(:games, games, reset: true)

        :error ->
          socket = assign(socket, :load_error, true)

          socket
          |> assign(:offset, 0)
          |> assign(:total, 0)
          |> assign(:more_error, false)
          |> stream(:games, [], reset: true)
      end

    # settle_surface/1 MUST run before sync_carousel_visibility/1: the
    # latter reasons about what's already in the DOM, so it has to read
    # the very value the DOM was (or is about to be) rendered from — see
    # settle_surface/1's own comment for the full ordering rationale
    # (Task 2, G-01.2-4 defect C).
    socket
    |> settle_surface()
    |> sync_carousel_visibility()
  end

  # Freezes which of the two browse surfaces is actually RENDERED while the
  # modal is open (Task 2, closes G-01.2-4 defect C). browsing_results?/1
  # stays the pure DESIRED-surface predicate — this is the only remaining
  # caller of it — and every template `:if`, both slot guards and
  # sync_carousel_visibility/1 read `:rendered_results` instead, so they
  # can never disagree with what the DOM actually holds. A no-op while
  # `@filters_open` is true: the assign stays frozen no matter how many
  # facets the member clicks behind the blur, so the background surface
  # never restructures underneath the open modal. Called from mount/3
  # (`:filters_open` is always false there, so this also seeds the correct
  # first-paint value from whatever `:q` the URL supplied) and from
  # apply_filters/1 above.
  defp settle_surface(%{assigns: assigns} = socket) do
    if assigns.filters_open do
      socket
    else
      assign(socket, :rendered_results, browsing_results?(assigns))
    end
  end

  # See mount/3's comment on :carousel_needs_reset for the bug this fixes.
  # Every filter-changing event funnels through apply_filters/1, which
  # (Task 2) now always calls settle_surface/1 immediately before this, so
  # this is the single place that keeps the flag and the carousel's actual
  # DOM/stream state in sync:
  #   - the grid is about to show (or already is) -> the carousel-rows
  #     container will be (or stays) removed from the DOM -> mark it dirty.
  #   - the carousel is about to show and it was marked dirty -> the
  #     container is reappearing after being removed -> its per-row
  #     streams need a fresh reset: true population before that happens,
  #     or every row renders permanently empty.
  #   - the carousel is about to show and it was NOT marked dirty -> it
  #     never left the DOM (e.g. the very first connected handle_params
  #     call) -> touching the streams again here would double-populate
  #     them before the first render ever flushes (mount/3's own
  #     accumulation warning) -> no-op.
  defp sync_carousel_visibility(socket) do
    cond do
      socket.assigns.rendered_results -> assign(socket, :carousel_needs_reset, true)
      socket.assigns.carousel_needs_reset -> refresh_carousel_rows(socket)
      true -> socket
    end
  end

  defp refresh_carousel_rows(socket) do
    rows = Catalog.list_carousel_rows()

    socket =
      Enum.reduce(rows, socket, fn row, acc ->
        stream(acc, carousel_stream_name(row.key), row.games, reset: true)
      end)

    socket
    |> assign(:carousel_rows, Enum.map(rows, &carousel_row_metadata/1))
    |> assign(:carousel_needs_reset, false)
  end

  defp safe_filter_games(opts) do
    {:ok, Catalog.filter_games(opts)}
  rescue
    _error -> :error
  end

  # Public (not defp) — reused verbatim by PukllayClubWeb.FilterModal's live
  # match-count line, per 01.1-06's "reuse result_count_text/1 rather than
  # authoring second copy" instruction. Same pluralization for both surfaces.
  def result_count_text(1), do: "1 juego encontrado"
  def result_count_text(n), do: "#{n} juegos encontrados"

  # Count of active facet/scalar filters, for the nav-search filter button's
  # badge (01.1-06). Deliberately excludes @q — the free-text query has its
  # own visible presence in the search input, this badge is about facets a
  # visitor can't otherwise see once the search control is collapsed.
  defp active_filter_count(assigns) do
    length(assigns.mechanics) + length(assigns.themes) + length(assigns.weight_bands) +
      length(assigns.tags) + length(assigns.designers) + length(assigns.artists) +
      Enum.count([assigns.players, assigns.max_playtime, assigns.min_age], &(not is_nil(&1)))
  end

  # Chip descriptors for the active-filters summary row inline with the
  # Resultados heading (Task 1, sketch 029 winner C, gap-closure G-01.2-4).
  # One chip per filter active_filter_count/1 already counts — each
  # selected mechanic/theme/weight band/editorial tag, the players/
  # max_playtime scalars — PLUS a chip for the free-text query, which that
  # counter deliberately excludes (see its own comment above). Every
  # chip's :event/:facet/:scalar/:choice dispatch through the
  # already-shipped `toggle-facet`/`toggle-scalar` handlers with the value
  # that is currently selected, which those handlers already treat as a
  # removal — no new server-side parsing, no new dynamic-key surface.
  # Removal for mechanics/themes/weight_bands/tags routes through
  # `facet_assign_key/1`; players/max_playtime through
  # `scalar_assign_key/1`; the query chip has no equivalent toggle and
  # dispatches the new parameterless `clear-query` handler instead.
  # `min_age` gets no chip, matching its deliberate absence from every
  # other filter control.
  defp active_filter_chips(assigns) do
    facet_chips(assigns.mechanics, "mechanics", "Mecánica") ++
      facet_chips(assigns.themes, "themes", "Temática") ++
      weight_band_chips(assigns.weight_bands) ++
      tag_chips(assigns.tags) ++
      creator_chips(assigns.designers, "designers", "Diseñador") ++
      creator_chips(assigns.artists, "artists", "Ilustrador") ++
      scalar_chips(assigns) ++
      query_chip(assigns.q)
  end

  # Mechanics/themes selections are already the Spanish label the modal's
  # own checklist renders (facet_options.mechanics/themes come from
  # Vocabulary.mechanic_options/0 / theme_options/0 — sorted Spanish
  # labels — and `toggle-facet` stores the clicked option's value
  # verbatim), so no second label lookup exists here.
  defp facet_chips(selected, facet, facet_label) do
    Enum.map(selected, fn value ->
      %{
        event: "toggle-facet",
        facet: facet,
        scalar: nil,
        choice: value,
        label: "#{facet_label}: #{value}",
        aria_label: "Quitar filtro: #{facet_label} — #{value}"
      }
    end)
  end

  defp weight_band_chips(selected) do
    Enum.map(selected, fn value ->
      label = weight_band_label(value)

      %{
        event: "toggle-facet",
        facet: "weight_bands",
        scalar: nil,
        choice: value,
        label: "Nivel: #{label}",
        aria_label: "Quitar filtro: Nivel — #{label}"
      }
    end)
  end

  defp weight_band_label(value) do
    case Vocabulary.weight_band(value) do
      %{label: label} -> label
      nil -> value
    end
  end

  # Editorial hashtags render verbatim (never renamed/reframed — same
  # convention as GameChips.editorial_tags/1). "Etiqueta" is this chip's
  # facet-name prefix since the modal itself has no rendered section for
  # this facet to match against (sketch 019 Round 3 cut it, still
  # deliberately unreturned — see FilterModal's moduledoc).
  defp tag_chips(selected) do
    Enum.map(selected, fn tag ->
      %{
        event: "toggle-facet",
        facet: "tags",
        scalar: nil,
        choice: tag,
        label: "Etiqueta: #{tag}",
        aria_label: "Quitar filtro: Etiqueta — #{tag}"
      }
    end)
  end

  # Creator filter chips for the :designers/:artists socket assigns,
  # 01.3-06 — the exit half of the detail page's navigable
  # Diseñadores/Ilustradores pills (UAT gap G-01.3-1 item 3). Same
  # descriptor shape as `facet_chips/3` (this is deliberately not a
  # distinct shape); removal reuses the existing
  # `toggle-facet` event via the two literal `facet_assign_key/1` clauses
  # added above — no new remove-creator handler.
  defp creator_chips(selected, facet, facet_label) do
    Enum.map(selected, fn value ->
      %{
        event: "toggle-facet",
        facet: facet,
        scalar: nil,
        choice: value,
        label: "#{facet_label}: #{value}",
        aria_label: "Quitar filtro: #{facet_label} — #{value}"
      }
    end)
  end

  defp scalar_chips(assigns) do
    players_chip(assigns.players) ++ max_playtime_chip(assigns.max_playtime)
  end

  defp players_chip(nil), do: []

  defp players_chip(6) do
    [scalar_chip_descriptor("players", "6", "Jugadores: 6+", "Quitar filtro: Jugadores — 6+")]
  end

  defp players_chip(n) do
    [
      scalar_chip_descriptor(
        "players",
        to_string(n),
        "Jugadores: #{n}",
        "Quitar filtro: Jugadores — #{n}"
      )
    ]
  end

  defp max_playtime_chip(nil), do: []

  defp max_playtime_chip(n) do
    [
      scalar_chip_descriptor(
        "max_playtime",
        to_string(n),
        "Duración máx.: #{n} min",
        "Quitar filtro: Duración máx. — #{n} min"
      )
    ]
  end

  defp scalar_chip_descriptor(scalar, choice, label, aria_label) do
    %{
      event: "toggle-scalar",
      facet: nil,
      scalar: scalar,
      choice: choice,
      label: label,
      aria_label: aria_label
    }
  end

  defp query_chip(q) when q in [nil, ""], do: []

  defp query_chip(q) do
    [
      %{
        event: "clear-query",
        facet: nil,
        scalar: nil,
        choice: nil,
        label: "Búsqueda: #{q}",
        aria_label: "Quitar filtro: Búsqueda — #{q}"
      }
    ]
  end

  # Ranks the curated row above the other 7 by colour (G-01-4) — never by a
  # fourth type size, per ui-design-system's 3-level cap.
  defp row_variant(:destacados_del_club), do: :hero
  defp row_variant(_key), do: :standard

  # One plain-Spanish line per D-09 row so all 8 shelves read as 8 distinct
  # things (G-01-4). Six of the eight reuse already-user-reviewed D-05/D-06
  # copy from Vocabulary; :destacados_del_club and :recientemente_anadidos
  # are newly authored here and flagged in the SUMMARY for review. Any
  # unmatched key degrades to a bare heading rather than crashing.
  defp row_subtitle(:crea_conexiones), do: editorial_tag_meaning("#CreaConexiones")
  defp row_subtitle(:equipo_ganador), do: editorial_tag_meaning("#EquipoGanador")
  defp row_subtitle(:duelos_memorables), do: editorial_tag_meaning("#DuelosMemorables")
  defp row_subtitle(:descubre_el_hobby), do: weight_band_descriptor("descubre_el_hobby")
  defp row_subtitle(:ingenio_estratega), do: weight_band_descriptor("ingenio_estratega")
  defp row_subtitle(:nivel_experto), do: weight_band_descriptor("nivel_experto")

  defp row_subtitle(:destacados_del_club), do: "La selección del club — los juegos que más recomendamos ahora mismo."

  defp row_subtitle(:recientemente_anadidos), do: "Las incorporaciones más nuevas a la ludoteca."

  defp row_subtitle(_unrecognized), do: nil

  # quick task 260913-0h6: the shelf's filtered-landing path, one literal
  # clause per key (mirrors row_subtitle/1's own pattern rather than a
  # case, to keep Credo's cyclomatic-complexity check happy). Every href
  # is built only from server-side shelf keys and Vocabulary constants,
  # never from client input, and every landing param is re-validated by
  # CatalogFilters.from_params/1's closed-Vocabulary whitelist — no new
  # param key, no new parsing path.
  # Same derivation Catalog.row_query("destacados_del_club") uses, so the
  # shelf and its own filtered landing can never drift on which tags
  # count as "destacados". Encoded via the verified-routes keyword form so
  # it produces a repeated-key ?tags=...&tags=... list, which
  # CatalogFilters.parse_list_param/2 already accepts.
  defp row_href(:destacados_del_club) do
    tags = Enum.map(Vocabulary.editorial_tags(), & &1.tag)
    ~p"/?#{[tags: tags]}"
  end

  defp row_href(:crea_conexiones), do: tag_href("#CreaConexiones")
  defp row_href(:equipo_ganador), do: tag_href("#EquipoGanador")
  defp row_href(:duelos_memorables), do: tag_href("#DuelosMemorables")
  defp row_href(:descubre_el_hobby), do: band_href("descubre_el_hobby")
  defp row_href(:ingenio_estratega), do: band_href("ingenio_estratega")
  defp row_href(:nivel_experto), do: band_href("nivel_experto")

  # No URL filter reproduces "newest non-expansion additions" (no sort
  # alone flips filters_active?/1, and there's no expansion-flag facet),
  # so this header stays a plain heading instead of becoming a dead or
  # misleading link.
  defp row_href(:recientemente_anadidos), do: nil

  defp row_href(_unrecognized), do: nil

  defp tag_href(tag), do: ~p"/?tags=#{tag}"
  defp band_href(band), do: ~p"/?weight_bands=#{band}"

  defp editorial_tag_meaning(tag) do
    Vocabulary.editorial_tags()
    |> Enum.find(&(&1.tag == tag))
    |> case do
      %{meaning: meaning} -> meaning
      nil -> nil
    end
  end

  defp weight_band_descriptor(value) do
    case Vocabulary.weight_band(value) do
      %{descriptor: descriptor} -> descriptor
      nil -> nil
    end
  end

  # One derived list feeding BOTH the mobile chip row (:subnav) AND the
  # desktop mega-menu (:nav_menu) — sketch-findings' single most load-bearing
  # rule for this layer is that two independently-built lists here is exactly
  # how the two surfaces silently drift apart on shelf count or subtitle
  # copy. Both consumers read this one call, under the same
  # not-filters_active? guard the chip row already carried.
  defp index_rows(assigns) do
    assigns.carousel_rows
    |> Enum.reject(& &1.empty?)
    |> Enum.map(fn row -> %{key: row.key, title: row.title, subtitle: row_subtitle(row.key)} end)
  end

  # "Toda la ludoteca" is a false claim once filters narrow the result
  # set — the heading text depends on whether a filter is active, but the
  # header itself always renders (even on a zero-result view).
  defp main_grid_heading(assigns) do
    if filters_active?(assigns), do: "Resultados", else: "Toda la ludoteca"
  end

  # A filtered view shows one authoritative result set — the curated
  # carousel rows step aside rather than competing with it (Task 3 action
  # text). Split into two clauses (01.3-06) to keep Credo's cyclomatic
  # complexity check under its threshold now that designers/artists have
  # grown the facet list to six — any_facet_active?/1 is not otherwise
  # reused, this is a complexity-budget split, not a new abstraction.
  defp filters_active?(assigns) do
    assigns.q not in [nil, ""] or
      any_facet_active?(assigns) or
      not is_nil(assigns.players) or
      not is_nil(assigns.max_playtime) or
      not is_nil(assigns.min_age)
  end

  # 01.3-06: designers/artists included alongside the five pre-existing
  # facets — without them a `/?designers=`/`/?artists=` landing would stay
  # on the unfiltered carousel surface (D-01/D-02) instead of the narrowed
  # grid, the exact broken round-trip this plan exists to close (UAT gap
  # G-01.3-1 item 3).
  defp any_facet_active?(assigns) do
    assigns.mechanics != [] or
      assigns.themes != [] or
      assigns.weight_bands != [] or
      assigns.tags != [] or
      assigns.designers != [] or
      assigns.artists != []
  end

  # D-01/D-02: the single source of truth for which of the two browse
  # surfaces renders — carousels, or the flat "Toda la ludoteca" grid.
  # CALLS filters_active?/1 rather than restating its clauses, so the
  # carousel gate and the grid gate can never drift apart:
  # filters_active?/1 stays the narrower "is a filter actually applied"
  # question (still used by main_grid_heading/1 and the header's
  # search_expanded state below), while browsing_results?/1 answers
  # "should the member be looking at the results view right now" — true
  # whenever a filter is active OR the member explicitly submitted the
  # empty filter modal (the :browse_all signal set by "apply-filters").
  defp browsing_results?(assigns) do
    filters_active?(assigns) or assigns.browse_all
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      fullbleed
      sticky
      bottom_collapse
      search_expanded={@search_expanded}
      active_nav={:inicio}
    >
      <%!-- Quick task 260902-il3: only the bottom boundary is opted in
      (`bottom_collapse`) — the top spacing is deliberately left on the
      shared default (`pt-8 sm:pt-20`) per D-01, since it is a separately-
      tuned, closed decision this task must not move. --%>
      <:nav_links>
        <.link navigate={~p"/"} aria-current="page">Inicio</.link>
        <.link navigate={~p"/quienes-somos"}>Quiénes Somos</.link>
      </:nav_links>
      <:nav_search>
        <%!-- G-01.2-9 (Task 2): `page_loading: true` opts this specific
        push into LiveView's own phx:page-loading-start/phx:page-loading-stop
        window events (the mechanism assets/js/app.js's progress bar already
        listens to and the results-region .ResultsLoading hook below now
        also listens to) — the ONLY practical, single in-flight signal for
        this pipeline, since phx-change="search" alone fires no window
        event by default (that per-element .phx-change-loading class LiveView
        adds automatically has no equivalent window-level signal). The plan's
        own acceptance criteria named this `phx-page-loading`, but no such
        attribute exists in this pinned phoenix_live_view (1.2.9) — verified
        via `grep -rln phx-page-loading deps/phoenix_live_view/` returning
        nothing; `JS.push/2`'s documented `:page_loading` option (js.ex) is
        the real, correct API and is what is used here and at the two other
        annotation sites below (Rule 1 fix, see SUMMARY). --%>
        <form
          phx-change={JS.push("search", page_loading: true)}
          id="catalog-search-form"
          class="pk-nav-search-form"
        >
          <.input
            type="text"
            name="q"
            value={@q}
            placeholder="¿Qué juego buscas?"
            phx-debounce="300"
            maxlength="100"
          />
        </form>
        <button
          type="button"
          phx-click="open-filters"
          aria-label="Abrir filtros"
          class="pk-filter-trigger min-h-11 min-w-11"
        >
          <.icon name="hero-adjustments-horizontal" class="size-5" />
          <span :if={active_filter_count(assigns) > 0} class="pk-filter-badge" aria-hidden="true">
            {active_filter_count(assigns)}
          </span>
        </button>
      </:nav_search>
      <:nav_menu :if={not @rendered_results}>
        <Layouts.category_menu rows={index_rows(assigns)} />
      </:nav_menu>
      <:subnav :if={not @rendered_results}>
        <div class="pk-chip-nav-wrap">
          <nav class="pk-chip-nav" aria-label="Categorías">
            <span class="pk-chip-spacer" aria-hidden="true"></span>
            <a
              :for={row <- index_rows(assigns)}
              href={"#carousel-#{row.key}"}
              data-chip-target={"carousel-#{row.key}"}
              class="pk-chip"
            >
              {row.title}
            </a>
            <span class="pk-chip-spacer" aria-hidden="true"></span>
          </nav>
        </div>
      </:subnav>
      <div class="pk-page">
        <%!-- quick-260824-eqc: `space-y-6` moved from the outer div to this
        inner one — left on the outer div it would apply to a single child
        and silently collapse every gap between the page's sections.
        `pk-dimmable`/`is-dimmed` (below, sketch 019) blur+dim this wrapper
        while the filter modal is open, driven by the existing
        `@filters_open` assign (the same one already passed to the modal as
        `open=`) — no new assign. The modal and GamePreview.preview_host
        MUST stay OUTSIDE this wrapper: a CSS `filter` on an ancestor
        establishes a containing block for `position: fixed` descendants,
        so nesting them here would both blur the modal itself and re-anchor
        its fixed positioning to this wrapper's box. Deliberately NOT
        `aria-hidden`/`inert` on the wrapper either — the `.FilterModal`
        hook already traps Tab focus inside the dialog, and `aria-hidden`
        over a subtree containing focusable elements is itself an
        accessibility violation. --%>
        <%!-- G-01.2-9 (Task 2): id + colocated hook mirror LiveView's own
        phx:page-loading-start/stop window events (fired by the three
        page_loading: true-annotated controls above) onto this element as a
        `data-loading` attribute — the same idiom `.GridScroll` already uses
        client-side for its own fetch-more state, just window-scoped instead
        of a local pushEvent callback. This wrapper (not #carousel-rows or
        #grid-scroll individually) is the correct hook host: it is the only
        element present on BOTH browse surfaces and it survives every flip
        between them, since the carousel and grid containers are each
        `:if`-gated out of the DOM on the other surface — a hook needs a
        stable mount point. app.css's `.pk-dimmable[data-loading]` rule
        consumes the attribute this hook sets. --%>
        <div
          id="results-region"
          phx-hook=".ResultsLoading"
          class={["space-y-6", "pk-dimmable", @filters_open && "is-dimmed"]}
        >
          <script :type={Phoenix.LiveView.ColocatedHook} name=".ResultsLoading">
            export default {
              mounted() {
                // T-01.2-16-01: a stop event that never arrives (a dropped
                // response, a transport blip, a backgrounded tab) would
                // otherwise leave this surface dimmed indefinitely. The
                // failsafe clears the attribute a few seconds after start
                // regardless — the one behaviour this hook adds beyond
                // mirroring, and the reason it exists rather than a bare
                // CSS variant. Deliberately does not filter on the event's
                // `detail` payload: only the three annotated controls plus a
                // live navigation away from this page can produce these
                // events here, and a momentary dim while the page is being
                // left is harmless — a filter that depends on an
                // undocumented payload shape (confirmed empty/best-effort
                // across LiveView 1.2.9's own call sites — see the
                // SUMMARY) is a worse trade than an occasionally
                // one-event-too-generous dim.
                this.onStart = () => {
                  this.el.dataset.loading = "true"
                  clearTimeout(this.failsafeTimer)
                  this.failsafeTimer = setTimeout(() => {
                    delete this.el.dataset.loading
                  }, 5000)
                }
                this.onStop = () => {
                  delete this.el.dataset.loading
                  clearTimeout(this.failsafeTimer)
                }
                window.addEventListener("phx:page-loading-start", this.onStart)
                window.addEventListener("phx:page-loading-stop", this.onStop)
              },
              destroyed() {
                window.removeEventListener("phx:page-loading-start", this.onStart)
                window.removeEventListener("phx:page-loading-stop", this.onStop)
                clearTimeout(this.failsafeTimer)
              }
            }
          </script>
          <div :if={not @rendered_results} id="carousel-rows" class="space-y-8 pk-surface-fade">
            <%= if @loading do %>
              <CarouselRow.skeleton_row
                :for={n <- 1..@skeleton_carousel_rows}
                id={"carousel-skeleton-#{n}"}
              />
            <% else %>
              <CarouselRow.carousel_row
                :for={row <- @carousel_rows}
                :key={row.key}
                id={"carousel-#{row.key}"}
                title={row.title}
                games={Map.fetch!(@streams, carousel_stream_name(row.key))}
                variant={row_variant(row.key)}
                subtitle={row_subtitle(row.key)}
                href={row_href(row.key)}
                empty={row.empty?}
                row_key={to_string(row.key)}
                exhausted={row.exhausted?}
              />
            <% end %>
          </div>

          <div :if={@load_error} class="mx-auto w-full max-w-7xl pk-gutter">
            <div class="pk-state">
              <h2>No pudimos cargar la ludoteca</h2>
              <p>Hubo un problema de conexión.</p>
              <%!-- CoreComponents.button/1 checked first (ui-design-system's
            "check core_components.ex before hand-rolling markup" rule) —
            its "primary" variant is btn-primary, matching this page's one
            action per non-happy-path state (01.1-07). --%>
              <.button phx-click="retry" variant="primary">Reintentar</.button>
            </div>
          </div>

          <div :if={@rendered_results} class="mx-auto w-full max-w-7xl pk-gutter">
            <%!-- sketch 029 winner C ("Inline with Heading", Round 2
            rebalanced): chips share the heading's row, right after the
            result count. `gap-x-3.5 gap-y-2` is Tailwind's named-scale
            translation of the sketch's `gap: 8px 14px`. The chip row is a
            SIBLING of the heading block, not nested inside it, so it wraps
            to its own line independently on narrow widths. --%>
            <div class="flex flex-wrap items-baseline gap-x-3.5 gap-y-2">
              <div class="flex flex-col">
                <h2 class="font-display text-2xl">{main_grid_heading(assigns)}</h2>
                <p class="text-neutral text-sm">{result_count_text(@total)}</p>
              </div>
              <div
                :if={active_filter_chips(assigns) != []}
                class="flex flex-wrap items-center gap-1.5"
              >
                <%!-- G-01.2-9 (Task 2): `phx-value-*` still merges normally
                alongside a JS.push-valued `phx-click` — JS.push's own
                `value:` option is left unset here, so this chip's payload is
                unchanged from before, only page_loading is added on top
                (see the search form's comment above for the full
                phx-page-loading rationale). --%>
                <button
                  :for={chip <- active_filter_chips(assigns)}
                  type="button"
                  phx-click={JS.push(chip.event, page_loading: true)}
                  phx-value-facet={chip.facet}
                  phx-value-scalar={chip.scalar}
                  phx-value-choice={chip.choice}
                  aria-label={chip.aria_label}
                  class="pk-active-filter-chip pk-pill pk-pill-accent pk-pill-comfortable pk-pill-interactive"
                >
                  {chip.label}<span class="pk-active-filter-chip-x" aria-hidden="true">×</span>
                </button>
                <button
                  type="button"
                  phx-click={JS.push("clear-filters", page_loading: true)}
                  class="pk-clear-filters-link min-h-11"
                >
                  Limpiar filtros
                </button>
              </div>
            </div>
          </div>

          <div
            :if={@rendered_results and @total == 0 and not @load_error}
            class="mx-auto w-full max-w-7xl pk-gutter"
          >
            <div class="pk-state">
              <h2>No se encontraron juegos</h2>
              <p>Probá con otros filtros o términos de búsqueda.</p>
              <.button phx-click="clear-filters" variant="primary">Limpiar filtros</.button>
            </div>
          </div>

          <div
            :if={@rendered_results and @loading}
            class="mx-auto w-full max-w-7xl pk-gutter"
          >
            <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
              <CarouselRow.skeleton_card :for={n <- 1..@page_size} id={"grid-skeleton-#{n}"} />
            </div>
          </div>

          <%!-- D-03: the vertical twin of .CarouselScroll (carousel_row.ex),
          adapted to a sentinel + IntersectionObserver instead of a rail
          scroll listener. data-exhausted folds in @more_error on purpose:
          it parks the hook while a mid-scroll failure's inline retry is on
          screen, so a failed page never auto-retries in a loop — the
          member's own Reintentar click (a plain phx-click, not routed
          through this hook) is what tries again. --%>
          <div
            :if={@rendered_results and not @loading}
            id="grid-scroll"
            phx-hook=".GridScroll"
            data-exhausted={to_string(@offset >= @total or @more_error)}
            class="mx-auto w-full max-w-7xl pk-gutter pk-surface-fade"
          >
            <script :type={Phoenix.LiveView.ColocatedHook} name=".GridScroll">
              export default {
                mounted() {
                  this.grid = this.el.querySelector("[data-grid]")
                  this.sentinel = this.el.querySelector("[data-grid-sentinel]")

                  // Same pending/exhausted guard-flag pair and single
                  // pushEvent(..., reply => ...) round trip as
                  // .CarouselScroll (carousel_row.ex) — release pending
                  // ONLY from the reply callback, so no fixed-timeout guess
                  // is needed and at most one request is ever in flight.
                  // The loading indicator is driven here, client-side,
                  // rather than through a server assign: the handler is
                  // synchronous, so a server-driven flag would be set and
                  // cleared within the same round trip and the trailing
                  // skeletons would never actually be visible.
                  this.pending = false
                  this.exhausted = this.el.dataset.exhausted === "true"

                  this.maybeLoadMore = () => {
                    if (this.pending || this.exhausted) return

                    this.pending = true
                    this.grid.dataset.loading = "true"
                    this.pushEvent("load-more", {}, (reply) => {
                      this.pending = false
                      delete this.grid.dataset.loading
                      if (reply && reply.exhausted) this.exhausted = true

                      // An IntersectionObserver only fires on a CHANGE of
                      // intersection state: if the sentinel is still
                      // inside the root margin after a page lands, no
                      // second callback would ever arrive and loading
                      // would silently stop one page in. Force a fresh
                      // evaluation by re-observing, unless the server has
                      // parked us (data-exhausted, re-read by updated()
                      // below, already ran by the time this callback
                      // fires — it folds in @more_error, so a failed page
                      // does not auto-retry here).
                      if (!this.exhausted) {
                        this.observer.unobserve(this.sentinel)
                        this.observer.observe(this.sentinel)
                      }
                    })
                  }

                  this.observer = new IntersectionObserver(
                    (entries) => {
                      if (entries.some((entry) => entry.isIntersecting)) this.maybeLoadMore()
                    },
                    {rootMargin: "400px"}
                  )
                  this.observer.observe(this.sentinel)
                },
                updated() {
                  // Re-read in case a server-driven change (a filter
                  // reset, a recovered mid-scroll error) changed the data
                  // attribute — same one-line resync as
                  // .CarouselScroll.updated().
                  this.exhausted = this.el.dataset.exhausted === "true"
                },
                destroyed() {
                  this.observer?.disconnect()
                }
              }
            </script>
            <div
              id="games"
              phx-update="stream"
              data-grid
              class={[
                "pk-grid grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4",
                @total == 0 && "hidden"
              ]}
            >
              <GameCard.game_card
                :for={{id, game} <- @streams.games}
                id={id}
                game={game}
                from={@from_query}
              />
              <%!-- Permanent trailing skeleton placeholders, mirroring
              carousel_row.ex's own comment verbatim: non-stream items in a
              phx-update="stream" container can be added/updated but never
              removed, so these render unconditionally with stable ids and
              are toggled by CSS (.pk-grid[data-loading], set/cleared by
              the hook above) rather than by :if — a conditional render
              would put them in the DOM once and strand them there
              permanently. Four covers the widest column count (lg); at
              narrower breakpoints they wrap, which is acceptable. --%>
              <CarouselRow.skeleton_card id="grid-skel-1" class="pk-trailing-skel" />
              <CarouselRow.skeleton_card id="grid-skel-2" class="pk-trailing-skel" />
              <CarouselRow.skeleton_card id="grid-skel-3" class="pk-trailing-skel" />
              <CarouselRow.skeleton_card id="grid-skel-4" class="pk-trailing-skel" />
            </div>
            <div data-grid-sentinel aria-hidden="true" class="h-px w-full"></div>
          </div>

          <%!-- D-03: compact inline retry for a mid-scroll load-more
          failure — deliberately NOT a .pk-state block. Content already
          exists above it, so the padded empty-state treatment would read
          as the whole page having failed rather than one page having
          failed. Gated on @more_error, the second error channel
          mount/3 documents. --%>
          <div
            :if={@rendered_results and @more_error}
            class="mx-auto w-full max-w-7xl pk-gutter"
          >
            <div class="flex items-center justify-center gap-2">
              <p class="text-neutral text-sm">No pudimos cargar más juegos.</p>
              <.button phx-click="load-more" variant="secondary">Reintentar</.button>
            </div>
          </div>
        </div>

        <GamePreview.preview_host />

        <%!-- G-01.2-9 (Task 2) scope decision, not an omission: the modal's
        own facet/scalar/search controls are deliberately NOT annotated with
        `page_loading: true`. The modal already renders its own live result
        count in its footer CTA, and the surface behind it is already
        blurred and inert (`@filters_open`, above) while it's open — a
        second in-flight signal on the results region here would land on a
        surface nobody is looking at. See the SUMMARY's human-check item for
        whether this reads as fine or needs a follow-up extending the
        annotation into filter_modal.ex once seen on production latency. --%>
        <FilterModal.filter_modal
          id="filter-modal"
          facet_options={@facet_options}
          mechanics={@mechanics}
          themes={@themes}
          weight_bands={@weight_bands}
          tags={@tags}
          players={@players}
          max_playtime={@max_playtime}
          open={@filters_open}
          q={@q}
          total={@total}
          filters_active={filters_active?(assigns)}
        />
      </div>
    </Layouts.app>
    """
  end
end
