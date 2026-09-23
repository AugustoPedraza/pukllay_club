defmodule PukllayClubWeb.Admin.GameLive.Index do
  @moduledoc """
  Juegos list at `/admin/juegos` (D-25, plan 01.8.2-14) — one continuous
  list grouped by `status`: **Borradores · Juegos del club · Retirados**,
  in that order, a group rendered only when it has rows. `status` is
  durable and mutually exclusive (an `Ecto.Enum`, D-04), so the partition
  is guaranteed by the schema rather than by predicate ordering — see
  `Catalog.list_admin_games_by_status/1`. A retired game finally has a
  home: under the superseded flat-table design it landed silently inside
  "Juegos del club", a name asserting exactly what its state denies.

  Superseded by this plan: the daisyUI table render, the load-more pager
  (every matching row is fetched — D-25 groups the whole list, it does not
  page it), and the `estado` filter-chip nav — lifecycle state is now a
  group, never a filter axis, matching 01.8.1-05's "no default status
  filter" admin-read contract (every status is always shown, just
  partitioned).

  Borradores and Retirados are collapsible and **collapsed at rest**
  (D-19g-bis decision 18); Juegos del club never collapses (decision 15 —
  a page whose one job is a catalog must never be able to show zero rows
  because its only section collapsed). `Sin datos` — a draft published
  with no description and no cover image (the same predicate the D-36
  unpublish migration used) — renders as a `kind_tag/1`-style row
  attribute inside Borradores, never a section of its own and never a
  `status_dot/1` (D-19g-bis: "sin datos" is not a status).

  **D-37 gate 4 — the post-add landing behaviour.** The superseded
  post-add `push_patch` onto the drafts filter (line 105 of this module
  before this plan) has no referent once groups replace filters. This
  plan lands on Borradores: a successful add (or a confirmed edition) opens the
  Borradores section if it was collapsed and marks the new row `fresh`
  (076's `.fresh` + scroll-into-view pattern, reused via
  `assets/js/hooks/admin_list.js` rather than re-invented) — the same
  session that just created the game is the one shown where it landed.

  Subscribes to `"admin:games"` (D-01, 01.8.1-06) once connected:
  `Workers.EnrichGameWorker` broadcasts `{:game_enriched, id}` after a
  staff-added draft's background enrichment finishes; this LiveView
  reloads the grouped list live — no page reload. A `pending` draft's row
  shows a skeleton cover and `Juego #<bgg_id> (cargando…)`; a `failed` row
  shows the `Error al traer datos de BGG.` alert with `Reintentar`
  (`Catalog.retry_enrichment/1`). Neither carries a trailing chevron
  (D-19i: a chevron means "opens another page"; a pending/failed row acts
  in place).

  **D-03 (revised 2026-09-14, gap CR-B-01): a known BGG id warns, then
  allows an edition** — unchanged by this plan, see
  `Catalog.add_game_from_bgg/2`.

  D-19n's scrolled context (the pinned page bar + the pinned section
  caption) is wired via `AdminComponents.page_bar/1`/`back_row/1` and
  `assets/js/hooks/admin_list.js` — see that hook's own header comment for
  the position:absolute-at-rest/position:fixed-while-visible mechanism
  (Rule 1 fix to `components.css`, documented in this plan's SUMMARY: no
  live call site had ever proven the pinning half of that component before
  this screen).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.AdminComponents

  # D-19g-bis decision 18 / D-25: exceptions first, collapsed at rest;
  # the body section (Juegos del club) is never collapsible (decision 15).
  @sections [
    {:draft, "Borradores"},
    {:published, "Juegos del club"},
    {:retired, "Retirados"}
  ]
  @collapsible_keys [:draft, :retired]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:games")
    end

    {:ok,
     socket
     |> assign(:page_title, "Juegos")
     |> assign(:loading, not connected?(socket))
     |> assign(:q, "")
     |> assign(:collapsed_sections, MapSet.new(@collapsible_keys))
     |> assign(:fresh_game_id, nil)
     |> assign(:groups, %{draft: [], published: [], retired: []})
     |> assign(:copy_counts, %{})
     |> assign(:total, 0)
     |> assign(:bgg_id_input, "")
     |> assign(:bgg_id_error, nil)
     |> assign(:edition_prompt, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:q, params["q"] || "")
      |> load_groups()

    {:noreply, socket}
  end

  defp load_groups(socket) do
    if socket.assigns.loading do
      socket
    else
      %{q: q} = socket.assigns
      groups = Catalog.list_admin_games_by_status(q: q)
      all_games = groups.draft ++ groups.published ++ groups.retired

      socket
      |> assign(:groups, groups)
      |> assign(:total, length(all_games))
      |> assign(:copy_counts, Shelves.counts_for_games(Enum.map(all_games, & &1.id)))
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: search_path(q))}
  end

  @impl true
  def handle_event("toggle-section", %{"section-key" => key}, socket) do
    case parse_section_key(key) do
      nil -> {:noreply, socket}
      section_key -> {:noreply, update(socket, :collapsed_sections, &toggle_collapsed(&1, section_key))}
    end
  end

  @impl true
  def handle_event("add-game", %{"bgg_id" => bgg_id}, socket) do
    case Catalog.add_game_from_bgg(bgg_id) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, "")
         |> assign(:bgg_id_error, nil)
         |> assign(:edition_prompt, nil)
         |> put_flash(:info, "Juego agregado como borrador.")
         |> land_on_fresh_draft(game)}

      # D-03 (revised 2026-09-14): a BGG id already claimed by any game
      # (draft, published, or retired) — warn and show every current
      # holder instead of rejecting outright; only an explicit
      # "confirm-edition" click inserts a new edition.
      {:existing_editions, games} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, bgg_id)
         |> assign(:bgg_id_error, nil)
         |> assign(:edition_prompt, %{input: bgg_id, games: games})}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, bgg_id)
         |> assign(:bgg_id_error, "Pegá un número de BGG o el link del juego.")
         |> assign(:edition_prompt, nil)}
    end
  end

  # T-01.8.1-69: acknowledged ids come ONLY from the server-side
  # `:edition_prompt` assign — never from client params — so a forged
  # `confirm-edition` payload can't claim an id it was never shown.
  @impl true
  def handle_event("confirm-edition", _params, %{assigns: %{edition_prompt: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("confirm-edition", _params, socket) do
    %{edition_prompt: prompt} = socket.assigns

    case Catalog.add_game_from_bgg(prompt.input, acknowledged_game_ids: Enum.map(prompt.games, & &1.id)) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, "")
         |> assign(:bgg_id_error, nil)
         |> assign(:edition_prompt, nil)
         |> put_flash(:info, "Edición agregada como borrador.")
         |> land_on_fresh_draft(game)}

      # A stale prompt (double-tap, a second tab) never inserts again — it
      # just re-warns with whatever the current holder set now is.
      {:existing_editions, games} ->
        {:noreply, assign(socket, :edition_prompt, %{prompt | games: games})}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:bgg_id_error, "Pegá un número de BGG o el link del juego.")
         |> assign(:edition_prompt, nil)}
    end
  end

  @impl true
  def handle_event("cancel-edition", _params, socket) do
    {:noreply, assign(socket, :edition_prompt, nil)}
  end

  # D-03: `game-id` (never the reserved `value` key — project memory rule)
  # is parsed defensively even though the button only ever renders a real
  # integer id, so a malformed/tampered client payload is ignored rather
  # than crashing the LiveView.
  @impl true
  def handle_event("retry-enrichment", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} ->
        case int_id |> Catalog.get_game!() |> Catalog.retry_enrichment() do
          {:ok, _updated} -> {:noreply, load_groups(socket)}
          {:error, :not_failed} -> {:noreply, socket}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_enriched, _game_id}, socket) do
    {:noreply, load_groups(socket)}
  end

  defp search_path(""), do: ~p"/admin/juegos"
  defp search_path(q), do: ~p"/admin/juegos?#{%{q: q}}"

  # T-01-37 convention: literal-clause dispatch on client input, never
  # `String.to_atom/1`. `:published` (the body section, D-19g-bis decision
  # 15) is deliberately unreachable here — no `phx-value-section-key` for
  # it is ever rendered — but a forged payload naming it still falls
  # through to `nil` rather than toggling the one section that must never
  # collapse.
  defp parse_section_key("draft"), do: :draft
  defp parse_section_key("retired"), do: :retired
  defp parse_section_key(_unrecognized), do: nil

  defp toggle_collapsed(collapsed, key) do
    if MapSet.member?(collapsed, key) do
      MapSet.delete(collapsed, key)
    else
      MapSet.put(collapsed, key)
    end
  end

  # D-37 gate 4: the chosen post-add landing behaviour — open Borradores
  # (if it was collapsed) and mark the new row `fresh` so
  # `assets/js/hooks/admin_list.js` scrolls it into view, following 076's
  # `.fresh` + scroll-into-view pattern rather than the superseded
  # `push_patch(to: filter_path(:draft, ""))`.
  defp land_on_fresh_draft(socket, game) do
    socket
    |> update(:collapsed_sections, &MapSet.delete(&1, :draft))
    |> assign(:fresh_game_id, game.id)
    |> load_groups()
  end

  defp visible_sections(groups) do
    Enum.filter(@sections, fn {key, _label} -> groups[key] != [] end)
  end

  defp expanded?(collapsed_sections, key), do: key not in collapsed_sections
  defp collapsible?(key), do: key in @collapsible_keys

  defp empty_heading(""), do: "Ningún juego todavía"
  defp empty_heading(_q), do: "Ningún juego coincide con la búsqueda"

  defp empty_body(""), do: "Agregá un juego pegando su ID o link de BGG."
  defp empty_body(_q), do: "Probá con otro nombre."

  defp pending?(game), do: game.status == :draft and game.enrichment_status == "pending"
  defp failed?(game), do: game.status == :draft and game.enrichment_status == "failed"

  # D-36's own predicate, mirrored (not re-derived): a game with no real
  # content at all. Scoped to Borradores rows only (D-25) — a published
  # game this empty would already have been moved to Borradores by the
  # `unpublish_still_empty_games` migration.
  defp missing_data?(%{description: description, cover_url: cover_url}) do
    (is_nil(description) or description == "") and is_nil(cover_url)
  end

  defp game_label(%{enrichment_status: "pending", bgg_id: bgg_id}), do: "Juego ##{bgg_id} (cargando…)"
  defp game_label(%{name: name}), do: name

  # D-03 (revised): natural Spanish list join for the edition-prompt
  # heading — "A", "A y B", "A, B y C". Names render through HEEx
  # escaping via the `<p>` interpolation, never raw.
  defp edition_names(games) do
    games
    |> Enum.map(& &1.name)
    |> join_with_y()
  end

  defp join_with_y([name]), do: name
  defp join_with_y([a, b]), do: "#{a} y #{b}"

  defp join_with_y(names) do
    {last, rest} = List.pop_at(names, -1)
    Enum.join(rest, ", ") <> " y " <> last
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      bottom_collapse
      admin_chrome
      active_tab={:juegos}
    >
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <div id="juegos-page" phx-hook="AdminList" class="pk-admin-juegos space-y-6">
          <%!-- T-01.8.2-64: this in-page back row and `page_bar/1` below
          are the two halves of D-19n's ONE focusable back control. Neither
          passes `inert` explicitly — `back_row/1` defaults `inert={false}`
          (focusable at rest, matching `page_bar/1`'s own default
          `visible={false}` → its internal back link computes
          `inert={true}`), and `assets/js/hooks/admin_list.js` flips both
          `inert` attributes together whenever the page bar's visibility
          toggles, so exactly one is ever focusable. --%>
          <AdminComponents.back_row to={~p"/admin"} />
          <h1 class="pk-admin-page-title">Juegos</h1>

          <div class="pk-admin-juegos-add">
            <form id="add-game-form" phx-submit="add-game" class="pk-admin-juegos-add-form">
              <AdminComponents.field
                type="text"
                id="add-game-bgg-id"
                name="bgg_id"
                value={@bgg_id_input}
                label="ID o link de BGG"
                errors={if @bgg_id_error, do: [@bgg_id_error], else: []}
              />
              <AdminComponents.action
                anatomy="a1"
                role="principal"
                type="submit"
                phx-disable-with="Agregando…"
              >
                Agregar juego
              </AdminComponents.action>
            </form>
          </div>

          <div :if={@edition_prompt} id="edition-prompt">
            <AdminComponents.section_panel class="pk-admin-juegos-edition-prompt">
              <p>
                Ya tenés {edition_names(@edition_prompt.games)} con este BGG ID. ¿Es otra edición?
              </p>
              <ul class="pk-admin-juegos-edition-list">
                <li :for={game <- @edition_prompt.games} class="pk-admin-juegos-edition-item">
                  <AdminComponents.action
                    anatomy="a2"
                    role="terciaria"
                    navigate={~p"/admin/juegos/#{game.id}/editar"}
                  >
                    {game.name}
                  </AdminComponents.action>
                  <AdminComponents.status_dot status={game.status} />
                </li>
              </ul>
              <div class="pk-admin-juegos-edition-actions">
                <AdminComponents.action
                  id="confirm-edition"
                  anatomy="a1"
                  role="principal"
                  phx-click="confirm-edition"
                  phx-disable-with="Agregando…"
                >
                  Sí, agregar edición
                </AdminComponents.action>
                <AdminComponents.action
                  id="cancel-edition"
                  anatomy="a2"
                  role="terciaria"
                  phx-click="cancel-edition"
                >
                  Cancelar
                </AdminComponents.action>
              </div>
            </AdminComponents.section_panel>
          </div>

          <form id="admin-games-search" phx-change="search" class="pk-admin-juegos-search">
            <AdminComponents.field
              type="text"
              id="admin-games-search-input"
              name="q"
              value={@q}
              label="Buscar por nombre"
              phx-debounce="300"
            />
          </form>

          <div :if={@loading} class="pk-admin-juegos-loading">
            <div :for={_n <- 1..8} class="skeleton h-10 w-full"></div>
          </div>

          <div :if={!@loading and @total == 0} class="pk-admin-juegos-empty">
            <h2>{empty_heading(@q)}</h2>
            <p>{empty_body(@q)}</p>
          </div>

          <div :if={!@loading and @total > 0} class="pk-admin-juegos-sections">
            <.section
              :for={{key, label} <- visible_sections(@groups)}
              key={key}
              label={label}
              games={@groups[key]}
              expanded={expanded?(@collapsed_sections, key)}
              collapsible={collapsible?(key)}
              copy_counts={@copy_counts}
              fresh_game_id={@fresh_game_id}
            />
          </div>

          <AdminComponents.page_bar title="Juegos" back_to={~p"/admin"} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :key, :atom, required: true
  attr :label, :string, required: true
  attr :games, :list, required: true
  attr :expanded, :boolean, required: true
  attr :collapsible, :boolean, required: true
  attr :copy_counts, :map, required: true
  attr :fresh_game_id, :integer, default: nil

  defp section(assigns) do
    ~H"""
    <section id={"juegos-section-#{@key}"} class="pk-admin-juegos-section">
      <div class="pk-admin-juegos-sentinel" data-pk-section-sentinel aria-hidden="true"></div>
      <h2 class="pk-admin-juegos-section-heading-wrap" data-pk-section-heading>
        <button
          :if={@collapsible}
          type="button"
          id={"juegos-section-toggle-#{@key}"}
          class="pk-admin-juegos-section-header pk-admin-juegos-section-header--collapsible"
          phx-click="toggle-section"
          phx-value-section-key={@key}
          aria-expanded={to_string(@expanded)}
          data-pk-section-toggle
        >
          <AdminComponents.list_section_label>
            {@label}<span class="pk-admin-juegos-count">{length(@games)}</span>
          </AdminComponents.list_section_label>
          <span class="pk-admin-juegos-caret" aria-hidden="true">
            <.icon name="hero-chevron-down-mini" class="size-4" />
          </span>
        </button>
        <div :if={!@collapsible} class="pk-admin-juegos-section-header">
          <AdminComponents.list_section_label>
            {@label}<span class="pk-admin-juegos-count">{length(@games)}</span>
          </AdminComponents.list_section_label>
        </div>
      </h2>
      <p :if={@expanded and @key == :draft} class="pk-admin-juegos-section-hint">
        Todavía no se ven en la web.
      </p>
      <div :if={@expanded} class="pk-admin-juegos-rows">
        <.game_row
          :for={game <- @games}
          game={game}
          copy_count={Map.get(@copy_counts, game.id, 0)}
          fresh={game.id == @fresh_game_id}
        />
      </div>
    </section>
    """
  end

  attr :game, :map, required: true
  attr :copy_count, :integer, required: true
  attr :fresh, :boolean, default: false

  defp game_row(assigns) do
    cond do
      pending?(assigns.game) -> pending_row(assigns)
      failed?(assigns.game) -> failed_row(assigns)
      true -> normal_row(assigns)
    end
  end

  # `list_row/1` cannot express a loading skeleton in place of its `cover`
  # img (it only ever accepts a URL), so this state is composed directly
  # against `list_row/1`'s own `pk-admin-row` markup shape rather than
  # forking the atom for every caller (D-18: "compose, do not
  # re-implement" — the exception is narrow and named, not a silent fork).
  defp pending_row(assigns) do
    ~H"""
    <div
      id={"game-row-#{@game.id}"}
      class={["pk-admin-row", @fresh && "pk-admin-juegos-row--fresh"]}
      data-pk-pressable="true"
    >
      <div class="skeleton pk-admin-row__cover" aria-hidden="true"></div>
      <span class="pk-admin-row__body">
        <span class="pk-admin-row__name">{game_label(@game)}</span>
      </span>
    </div>
    """
  end

  defp failed_row(assigns) do
    ~H"""
    <div
      id={"game-row-#{@game.id}"}
      class={["pk-admin-row", @fresh && "pk-admin-juegos-row--fresh"]}
      data-pk-pressable="true"
    >
      <span class="pk-admin-row__body">
        <span class="pk-admin-row__name">{game_label(@game)}</span>
        <span class="pk-admin-juegos-row-error" role="alert">
          <span>Error al traer datos de BGG.</span>
          <AdminComponents.action
            anatomy="a2"
            role="terciaria"
            phx-click="retry-enrichment"
            phx-value-game-id={@game.id}
          >
            Reintentar
          </AdminComponents.action>
        </span>
      </span>
    </div>
    """
  end

  defp normal_row(assigns) do
    ~H"""
    <AdminComponents.list_row
      id={"game-row-#{@game.id}"}
      cover={@game.thumbnail_url}
      name={@game.name}
      meta={@game.year_published && to_string(@game.year_published)}
      navigate={~p"/admin/juegos/#{@game.id}/editar"}
      opens_page
      class={@fresh && "pk-admin-juegos-row--fresh"}
    >
      <:trailing>
        <AdminComponents.kind_tag :if={missing_data?(@game)} label="Sin datos" />
        <AdminComponents.count_pill count={@copy_count} />
      </:trailing>
    </AdminComponents.list_row>
    """
  end
end
