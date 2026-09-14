defmodule PukllayClubWeb.Admin.GameLive.Form do
  @moduledoc """
  Edit screen for a single game's club-owned fields, at
  `/admin/juegos/:id/editar` (D-07, UI-SPEC E3).

  `mount/3` loads via `Catalog.get_game!/1` — the unfiltered ADMIN read —
  so a `:draft` or `:retired` game opens here exactly as readily as a
  `:published` one, even though its public `/juegos/:id` 404s (D-04,
  D-08). Only `Catalog.change_game_admin/2`/`update_game_admin/2` ever
  touch this form's data, and those route through
  `Game.admin_changeset/2`'s five-field cast allowlist — a BGG-derived
  fact submitted in the form params (`bgg_weight`, `mechanics`, ...) is
  silently dropped, never persisted (T-01.8.1-21).

  Every BGG-derived fact is rendered read-only via `CoreComponents.list/1`
  below the form — values only, no inputs, no changeset field for any of
  them.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Vocabulary

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    game = Catalog.get_game!(id)

    {:ok,
     socket
     |> assign(:page_title, game.name)
     |> assign(:game, game)
     |> assign(:form, to_form(Catalog.change_game_admin(game)))}
  end

  @impl true
  def handle_event("validate", %{"game" => params}, socket) do
    changeset =
      socket.assigns.game
      |> Catalog.change_game_admin(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"game" => params}, socket) do
    case Catalog.update_game_admin(socket.assigns.game, params) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:page_title, game.name)
         |> assign(:form, to_form(Catalog.change_game_admin(game)))
         |> put_flash(:info, "Cambios guardados.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp weight_band_options do
    Enum.map(Vocabulary.weight_bands(), &{&1.label, &1.value})
  end

  defp status_badge_class(:draft), do: "badge badge-warning"
  defp status_badge_class(:published), do: "badge badge-success"
  defp status_badge_class(:retired), do: "badge badge-neutral"

  defp status_badge_label(:draft), do: "Borrador"
  defp status_badge_label(:published), do: "Publicado"
  defp status_badge_label(:retired), do: "Retirado"

  defp players_text(%{min_players: nil, max_players: nil}), do: "—"
  defp players_text(%{min_players: min, max_players: max}) when min == max, do: to_string(min || max)
  defp players_text(%{min_players: min, max_players: max}), do: "#{min || "?"}–#{max || "?"}"

  defp playtime_text(%{playing_time: t}) when is_integer(t), do: "#{t} min"

  defp playtime_text(%{min_playtime: nil, max_playtime: nil}), do: "—"

  defp playtime_text(%{min_playtime: min, max_playtime: max}) when min == max,
    do: "#{min || max} min"

  defp playtime_text(%{min_playtime: min, max_playtime: max}), do: "#{min || "?"}–#{max || "?"} min"

  defp mechanics_text(%{mechanics: mechanics}), do: join_or_dash(Vocabulary.covered_mechanics(mechanics))
  defp themes_text(%{themes: themes}), do: join_or_dash(Vocabulary.covered_themes(themes))

  defp join_names(names), do: join_or_dash(names)

  defp join_or_dash([]), do: "—"
  defp join_or_dash(values), do: Enum.join(values, ", ")

  defp value_or_dash(nil), do: "—"
  defp value_or_dash(value), do: value

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>
          {@game.name}
          <:subtitle>
            <span class={status_badge_class(@game.status)}>{status_badge_label(@game.status)}</span>
          </:subtitle>
          <:actions>
            <%!-- Task 2 (this same plan) adds the "/admin/juegos" route and
            promotes this to `navigate={~p"/admin/juegos"}` — a plain href
            for now avoids Phoenix.VerifiedRoutes failing compilation for
            a route that does not exist until that task lands. --%>
            <.link href="/admin/juegos" class="text-sm text-neutral">
              ← Volver
            </.link>
          </:actions>
        </.header>

        <.form for={@form} id="game-form" phx-change="validate" phx-submit="save" class="space-y-2">
          <.input field={@form[:name]} type="text" label="Nombre" />
          <.input field={@form[:units]} type="number" label="Unidades" />
          <.input
            field={@form[:weight_band]}
            type="select"
            label="Nivel"
            prompt="Sin nivel"
            options={weight_band_options()}
          />
          <.input field={@form[:is_expansion]} type="checkbox" label="Es expansión" />
          <.input field={@form[:description]} type="textarea" label="Descripción en español" />

          <.button variant="primary">Guardar cambios</.button>
        </.form>

        <div class="bg-base-200 rounded-box p-4">
          <.list>
            <:item title="Jugadores">{players_text(@game)}</:item>
            <:item title="Duración">{playtime_text(@game)}</:item>
            <:item title="Edad mínima">{value_or_dash(@game.min_age)}</:item>
            <:item title="Mecánicas">{mechanics_text(@game)}</:item>
            <:item title="Temáticas">{themes_text(@game)}</:item>
            <:item title="Diseñadores">{join_names(@game.designers)}</:item>
            <:item title="Ilustradores">{join_names(@game.artists)}</:item>
            <:item title="Editorial">{join_names(@game.publishers)}</:item>
            <:item title="Valoración BGG">{value_or_dash(@game.bgg_rating)}</:item>
            <:item title="Ranking BGG">{value_or_dash(@game.bgg_rank)}</:item>
            <:item title="Peso BGG">{value_or_dash(@game.bgg_weight)}</:item>
          </.list>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
