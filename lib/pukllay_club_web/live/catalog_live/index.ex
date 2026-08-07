defmodule PukllayClubWeb.CatalogLive.Index do
  @moduledoc """
  Public browse entry point at `/` (CATALOG-01, CATALOG-08). Fully
  unauthenticated — no auth plug, no `current_scope` requirement, the
  `:browser` pipeline is reused unmodified. Reads exclusively through
  `PukllayClub.Catalog`, never `Repo` directly — the context boundary later
  plans (01-04/01-05) extend with filtering, sorting, and search.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClubWeb.GameCard

  @impl true
  def mount(_params, _session, socket) do
    games = Catalog.list_games(limit: 24)

    socket =
      socket
      |> assign(:page_title, "Catálogo")
      |> stream(:games, games)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        id="games"
        phx-update="stream"
        class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4"
      >
        <GameCard.game_card :for={{id, game} <- @streams.games} id={id} game={game} />
      </div>
    </Layouts.app>
    """
  end
end
