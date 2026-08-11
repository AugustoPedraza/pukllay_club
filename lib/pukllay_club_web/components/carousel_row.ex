defmodule PukllayClubWeb.CarouselRow do
  @moduledoc """
  Stateless horizontally-scrolling rail of `GameCard`s, plus the matching
  `skeleton_card/1` loading placeholder. Renders one of the 8 fixed D-09
  carousel rows above the browse grid.

  daisyUI's `carousel`/`carousel-item` class names are confirmed v5-safe
  by 01-RESEARCH.md Pitfall 5 (unchanged from v4). A row backed by zero
  games renders nothing at all — an empty titled rail would read as
  breakage, not as "nothing here yet".
  """
  use Phoenix.Component

  alias PukllayClubWeb.GameCard

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :games, :list, required: true

  def carousel_row(assigns) do
    ~H"""
    <section :if={@games != []} id={@id} class="space-y-3">
      <h2 class="font-display text-2xl">{@title}</h2>
      <div class="carousel carousel-center gap-4 rounded-box">
        <div :for={game <- @games} class="carousel-item">
          <GameCard.game_card id={"#{@id}-#{game.id}"} game={game} class="w-40 shrink-0 sm:w-48" />
        </div>
      </div>
    </section>
    """
  end

  @doc """
  Renders the same-footprint skeleton treatment as `carousel_row/1`, for
  the loading backstop (01-UI-SPEC.md "Carousel rows" loading row).
  """
  attr :id, :string, required: true
  attr :count, :integer, default: 6

  def skeleton_row(assigns) do
    ~H"""
    <section id={@id} class="space-y-3">
      <div class="skeleton h-7 w-48"></div>
      <div class="carousel carousel-center gap-4 rounded-box">
        <div :for={n <- 1..@count} class="carousel-item">
          <.skeleton_card id={"#{@id}-#{n}"} class="w-40 shrink-0 sm:w-48" />
        </div>
      </div>
    </section>
    """
  end

  @doc """
  A single skeleton card, matching `GameCard.game_card/1`'s footprint (a
  square figure over a `card-body`) so the layout does not jump once real
  content replaces it.
  """
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def skeleton_card(assigns) do
    ~H"""
    <div id={@id} class={["card bg-base-200 shadow-sm", @class]}>
      <div class="skeleton aspect-square w-full rounded-b-none"></div>
      <div class="card-body space-y-2 p-4">
        <div class="skeleton h-4 w-3/4"></div>
        <div class="skeleton h-8 w-24"></div>
      </div>
    </div>
    """
  end
end
