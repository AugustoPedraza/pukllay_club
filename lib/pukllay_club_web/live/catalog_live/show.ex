defmodule PukllayClubWeb.CatalogLive.Show do
  @moduledoc """
  Game detail page (CATALOG-05/06/07 full picture, CATALOG-08 public/no
  auth). Reached from `PukllayClubWeb.GameCard`'s `Ver detalles` CTA.

  `mount/3` loads the game via `Catalog.get_game!/1`, which raises
  `Ecto.NoResultsError` for an unknown id — Phoenix renders the generated
  404 page for that case rather than crashing (T-01-30).

  `handle_event("select-image", ...)` swaps the main image only when the
  client-supplied `url` is a member of the game's own
  `[cover_url | gallery_urls]` list — a crafted url is never echoed
  unchecked into an `img src` (T-01-26).

  Every field from this plan's `<planner_assumption>` omission table is
  individually conditional: an absent field removes its whole row/element,
  never a blank placeholder.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.GameChips

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    game = Catalog.get_game!(id)

    {:ok,
     socket
     |> assign(:page_title, game.name)
     |> assign(:game, game)
     |> assign(:selected_image, game.cover_url)
     |> assign(:mechanic_labels, Vocabulary.covered_mechanics(game.mechanics))
     |> assign(:theme_labels, Vocabulary.covered_themes(game.themes))}
  end

  @impl true
  def handle_event("select-image", %{"url" => url}, socket) do
    if url in gallery_thumbnails(socket.assigns.game) do
      {:noreply, assign(socket, :selected_image, url)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} fullbleed sticky>
      <:crumb>
        <.link navigate={~p"/"}>Ludoteca</.link>
        <span class="pk-crumb-sep">/</span>
        <span class="pk-crumb-current">{@game.name}</span>
      </:crumb>

      <div class="mx-auto w-full max-w-7xl pk-gutter space-y-6">
        <div class="aspect-video overflow-hidden rounded-box bg-base-300">
          <img
            :if={@selected_image}
            src={@selected_image}
            alt={@game.name}
            class="h-full w-full object-cover"
          />
          <div
            :if={!@selected_image}
            class="flex h-full w-full items-center justify-center text-primary"
          >
            <.icon name="hero-puzzle-piece" class="size-16" />
            <span class="sr-only">{@game.name}</span>
          </div>
        </div>

        <div
          :if={@game.gallery_urls != []}
          id="gallery-thumbnails"
          class="flex gap-2 overflow-x-auto"
        >
          <button
            :for={url <- gallery_thumbnails(@game)}
            type="button"
            phx-click="select-image"
            phx-value-url={url}
            class={[
              "h-16 w-16 shrink-0 overflow-hidden rounded-box border-2",
              (url == @selected_image && "border-primary") || "border-transparent"
            ]}
          >
            <img src={url} alt={@game.name} class="h-full w-full object-cover" />
          </button>
        </div>

        <h1 class="font-display text-3xl">{@game.name}</h1>

        <GameChips.weight_band_badge game={@game} show_descriptor={true} />
        <GameChips.editorial_tags tags={@game.tags} />
        <GameChips.chip_row terms={@mechanic_labels} limit={99} />
        <GameChips.chip_row terms={@theme_labels} limit={99} />

        <dl class="grid grid-cols-2 gap-x-4 gap-y-2 text-sm sm:grid-cols-3">
          <div :if={@game.min_players && @game.max_players}>
            <dt class="text-neutral">Jugadores</dt>
            <dd>{@game.min_players}-{@game.max_players}</dd>
          </div>
          <div :if={playtime_text(@game)}>
            <dt class="text-neutral">Duración</dt>
            <dd>{playtime_text(@game)}</dd>
          </div>
          <div :if={@game.min_age}>
            <dt class="text-neutral">Edad mínima</dt>
            <dd>{@game.min_age}+</dd>
          </div>
          <div :if={@game.year_published}>
            <dt class="text-neutral">Año</dt>
            <dd>{@game.year_published}</dd>
          </div>
          <div :if={@game.designers != []}>
            <dt class="text-neutral">Diseñadores</dt>
            <dd>{Enum.join(@game.designers, ", ")}</dd>
          </div>
          <div :if={@game.publishers != []}>
            <dt class="text-neutral">Editorial</dt>
            <dd>{Enum.join(@game.publishers, ", ")}</dd>
          </div>
        </dl>

        <p :if={@game.description}>{@game.description}</p>
      </div>
    </Layouts.app>
    """
  end

  # `cover_url` first so it's always the initial thumbnail/main image when
  # present; nils filtered so an absent cover never mints a broken `<img>`.
  defp gallery_thumbnails(game) do
    Enum.reject([game.cover_url | game.gallery_urls], &is_nil/1)
  end

  defp playtime_text(%{playing_time: t}) when is_integer(t), do: "#{t} min"

  defp playtime_text(%{min_playtime: min, max_playtime: max}) when is_integer(min) and is_integer(max) and min != max,
    do: "#{min}-#{max} min"

  defp playtime_text(%{min_playtime: min}) when is_integer(min), do: "#{min} min"
  defp playtime_text(%{max_playtime: max}) when is_integer(max), do: "#{max} min"
  defp playtime_text(_game), do: nil
end
