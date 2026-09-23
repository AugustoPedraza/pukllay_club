defmodule PukllayClubWeb.Admin.GameLive.Index do
  @moduledoc """
  Juegos list at `/admin/juegos` (D-09 Task 2, UI-SPEC E1): every game
  regardless of status, filterable by lifecycle state and searchable by
  name, paged via `Cargar más` over a `phx-update="stream"` table — never
  numbered pagination (ux-patterns B7).

  `estado` is parsed with literal-clause dispatch (`parse_estado/1`) and a
  `nil` catch-all for anything unrecognized — never an atom built from
  the client-supplied param (T-01-37 convention, same shape as
  `PukllayClub.Catalog`'s own `row_query/1`).

  Subscribes to the `"admin:games"` PubSub topic (D-01, 01.8.1-06) once
  connected: `Workers.EnrichGameWorker` broadcasts `{:game_enriched, id}`
  after a staff-added draft's background enrichment finishes, and this
  LiveView re-fetches and `stream_insert/3`s that one row live — no page
  reload. While a draft's `enrichment_status` is `"pending"` its row shows
  `Juego #<bgg_id> (cargando…)` next to a flat skeleton in place of a
  thumbnail (UI-SPEC E2 loading). When it is `"failed"` (D-03 — BGG
  fetching exhausted its retries, BGG had no matching item, or
  credentials are missing) the row instead shows the
  `Error al traer datos de BGG.` alert with a `Reintentar` button that
  re-enqueues enrichment via `Catalog.retry_enrichment/1`.

  **D-03 (revised 2026-09-14, gap CR-B-01): a known BGG id warns, then
  allows an edition.** Pasting a BGG id that already belongs to any game
  shows those games ("Ya tenés {nombres} con este BGG ID. ¿Es otra
  edición?", each linked to its editor) via the `:edition_prompt` assign,
  and only an explicit `"confirm-edition"` click inserts the new draft —
  the acknowledged ids always come from that server-side assign, never
  from client params (T-01.8.1-69). See `Catalog.add_game_from_bgg/2`.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog

  @page_size 50

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PukllayClub.PubSub, "admin:games")
    end

    {:ok,
     socket
     |> assign(:page_title, "Juegos")
     |> assign(:loading, not connected?(socket))
     |> assign(:status, nil)
     |> assign(:q, "")
     |> assign(:offset, 0)
     |> assign(:total, 0)
     |> assign(:bgg_id_input, "")
     |> assign(:bgg_id_error, nil)
     |> assign(:edition_prompt, nil)
     |> stream(:games, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:status, parse_estado(params["estado"]))
      |> assign(:q, params["q"] || "")
      |> load_games()

    {:noreply, socket}
  end

  defp parse_estado("borrador"), do: :draft
  defp parse_estado("publicado"), do: :published
  defp parse_estado("retirado"), do: :retired
  defp parse_estado(_unrecognized), do: nil

  defp load_games(socket) do
    if socket.assigns.loading do
      socket
    else
      %{status: status, q: q} = socket.assigns
      games = Catalog.list_admin_games(status: status, q: q, limit: @page_size)
      total = Catalog.count_admin_games(status: status, q: q)

      socket
      |> assign(:offset, length(games))
      |> assign(:total, total)
      |> stream(:games, games, reset: true)
    end
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, push_patch(socket, to: filter_path(socket.assigns.status, q))}
  end

  @impl true
  def handle_event("add-game", %{"bgg_id" => bgg_id}, socket) do
    case Catalog.add_game_from_bgg(bgg_id) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, "")
         |> assign(:bgg_id_error, nil)
         |> assign(:edition_prompt, nil)
         |> put_flash(:info, "Juego agregado como borrador.")
         |> push_patch(to: filter_path(:draft, ""))}

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
      {:ok, _game} ->
        {:noreply,
         socket
         |> assign(:bgg_id_input, "")
         |> assign(:bgg_id_error, nil)
         |> assign(:edition_prompt, nil)
         |> put_flash(:info, "Edición agregada como borrador.")
         |> push_patch(to: filter_path(:draft, ""))}

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

  @impl true
  def handle_event("load-more", _params, socket) do
    %{status: status, q: q, offset: offset} = socket.assigns
    games = Catalog.list_admin_games(status: status, q: q, limit: @page_size, offset: offset)

    {:noreply,
     socket
     |> assign(:offset, offset + length(games))
     |> stream(:games, games, at: -1)}
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
          {:ok, updated} -> {:noreply, stream_insert(socket, :games, updated)}
          {:error, :not_failed} -> {:noreply, socket}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_enriched, game_id}, socket) do
    {:noreply, stream_insert(socket, :games, Catalog.get_game!(game_id))}
  end

  defp filter_path(status, q) do
    params =
      %{}
      |> maybe_put_param("estado", estado_param(status))
      |> maybe_put_param("q", (q != "" && q) || nil)

    ~p"/admin/juegos?#{params}"
  end

  defp estado_param(:draft), do: "borrador"
  defp estado_param(:published), do: "publicado"
  defp estado_param(:retired), do: "retirado"
  defp estado_param(nil), do: nil

  defp maybe_put_param(map, _key, nil), do: map
  defp maybe_put_param(map, key, value), do: Map.put(map, key, value)

  defp status_badge_class(:draft), do: "badge badge-warning"
  defp status_badge_class(:published), do: "badge badge-success"
  defp status_badge_class(:retired), do: "badge badge-neutral"

  defp status_badge_label(:draft), do: "Borrador"
  defp status_badge_label(:published), do: "Publicado"
  defp status_badge_label(:retired), do: "Retirado"

  defp filter_link_class(true) do
    "min-h-11 inline-flex items-center px-3 rounded-box bg-primary text-primary-content font-semibold"
  end

  defp filter_link_class(false) do
    "min-h-11 inline-flex items-center px-3 rounded-box text-neutral hover:bg-base-200"
  end

  defp empty_heading(:draft), do: "Ningún juego en borrador"
  defp empty_heading(_status), do: "No hay juegos con este filtro."

  defp empty_body(:draft), do: "Agregá un juego pegando su ID o link de BGG."
  defp empty_body(_status), do: "Probá con otro filtro o con otra búsqueda."

  defp pending?(game), do: game.enrichment_status == "pending"
  defp failed?(game), do: game.enrichment_status == "failed"

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
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse admin_chrome>
      <div class="mx-auto w-full max-w-4xl space-y-6">
        <.header>Juegos</.header>

        <form
          id="add-game-form"
          phx-submit="add-game"
          class="rounded-box border border-base-300 bg-base-200 p-4 flex flex-wrap items-end gap-3"
        >
          <div class="flex-1 min-w-48">
            <.input
              type="text"
              id="add-game-bgg-id"
              name="bgg_id"
              value={@bgg_id_input}
              label="ID o link de BGG"
              errors={if @bgg_id_error, do: [@bgg_id_error], else: []}
            />
          </div>
          <.button variant="primary" phx-disable-with="Agregando…">Agregar juego</.button>
        </form>

        <div
          :if={@edition_prompt}
          id="edition-prompt"
          role="alert"
          class="alert alert-warning flex-col items-start gap-3"
        >
          <p>Ya tenés {edition_names(@edition_prompt.games)} con este BGG ID. ¿Es otra edición?</p>
          <ul class="flex flex-col gap-1">
            <li :for={game <- @edition_prompt.games} class="flex items-center gap-2">
              <.link navigate={~p"/admin/juegos/#{game.id}/editar"} class="link">{game.name}</.link>
              <span class={status_badge_class(game.status)}>{status_badge_label(game.status)}</span>
            </li>
          </ul>
          <div class="flex flex-wrap gap-2">
            <.button
              id="confirm-edition"
              variant="secondary"
              phx-click="confirm-edition"
              phx-disable-with="Agregando…"
            >
              Sí, agregar edición
            </.button>
            <.button id="cancel-edition" phx-click="cancel-edition">Cancelar</.button>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-4">
          <nav class="flex flex-wrap gap-1" aria-label="Filtrar por estado">
            <.link patch={filter_path(nil, @q)} class={filter_link_class(@status == nil)}>
              Todos
            </.link>
            <.link patch={filter_path(:draft, @q)} class={filter_link_class(@status == :draft)}>
              Borradores
            </.link>
            <.link
              patch={filter_path(:published, @q)}
              class={filter_link_class(@status == :published)}
            >
              Publicados
            </.link>
            <.link patch={filter_path(:retired, @q)} class={filter_link_class(@status == :retired)}>
              Retirados
            </.link>
          </nav>

          <form id="admin-games-search" phx-change="search" class="flex-1 min-w-40">
            <.input
              type="text"
              id="admin-games-search-input"
              name="q"
              value={@q}
              placeholder="Buscar por nombre"
              phx-debounce="300"
            />
          </form>
        </div>

        <div :if={@loading} class="space-y-2">
          <div :for={_n <- 1..8} class="skeleton h-10 w-full"></div>
        </div>

        <div :if={!@loading and @total == 0}>
          <div class="text-center py-12 space-y-2">
            <h2 class="font-display text-2xl">{empty_heading(@status)}</h2>
            <p class="text-neutral text-sm">{empty_body(@status)}</p>
          </div>
        </div>

        <div :if={!@loading and @total > 0} class="space-y-4">
          <.table
            id="admin-games"
            rows={@streams.games}
            row_click={fn {_id, game} -> JS.navigate(~p"/admin/juegos/#{game.id}/editar") end}
          >
            <:col :let={{_id, game}} label="Nombre">
              <div class="flex items-center gap-2">
                <div :if={pending?(game)} class="skeleton size-10 shrink-0 rounded-box"></div>
                <img
                  :if={!pending?(game) and game.thumbnail_url}
                  src={game.thumbnail_url}
                  alt=""
                  class="size-10 shrink-0 rounded-box object-cover"
                />
                <div class="min-w-0">
                  <span class="truncate block">{game_label(game)}</span>
                  <div :if={failed?(game)} class="alert alert-error mt-1 py-1">
                    <span>Error al traer datos de BGG.</span>
                    <.button
                      variant="secondary"
                      phx-click="retry-enrichment"
                      phx-value-game-id={game.id}
                    >
                      Reintentar
                    </.button>
                  </div>
                </div>
              </div>
            </:col>
            <:col :let={{_id, game}} label="Estado">
              <span class={status_badge_class(game.status)}>{status_badge_label(game.status)}</span>
            </:col>
          </.table>

          <div :if={@offset < @total} class="flex justify-center">
            <.button phx-click="load-more" variant="secondary">Cargar más</.button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
