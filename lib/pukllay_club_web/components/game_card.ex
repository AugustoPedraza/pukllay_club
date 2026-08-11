defmodule PukllayClubWeb.GameCard do
  @moduledoc """
  Stateless card rendering a single `PukllayClub.Catalog.Game` in the browse
  grid (CATALOG-01). Intentionally a `Phoenix.Component`, not a
  `Phoenix.LiveComponent` — filter state and stream updates live in the
  parent `PukllayClubWeb.CatalogLive.Index`, per 01-PATTERNS.md.

  The `Ver detalles` CTA is not yet a working link: the game detail page
  (CATALOG-02) is built in phase plan 01-06, after this tracer. Rendering it
  as an inert button (rather than a route to `/games/<id>` that does not
  exist yet, or a bare `#` href that looks like a real dead link) keeps the
  UI-SPEC Copywriting Contract's CTA visible without claiming navigation
  this plan does not implement.

  Accepts an optional `:class` so a caller (the grid vs. a horizontally
  -scrolling `CarouselRow` rail, 01-05) can control the card's width/shrink
  behavior without this component needing to know which context it's in.
  """
  use Phoenix.Component

  import PukllayClubWeb.CoreComponents

  attr :id, :string, required: true
  attr :game, PukllayClub.Catalog.Game, required: true
  attr :class, :any, default: nil

  def game_card(assigns) do
    ~H"""
    <div id={@id} class={["card bg-base-200 shadow-sm", @class]}>
      <figure class="aspect-square overflow-hidden bg-base-300">
        <img
          :if={@game.thumbnail_url}
          src={@game.thumbnail_url}
          alt={@game.name}
          loading="lazy"
          class="h-full w-full object-cover"
        />
        <div
          :if={!@game.thumbnail_url}
          class="flex h-full w-full items-center justify-center bg-base-300 text-primary"
        >
          <.icon name="hero-puzzle-piece" class="size-12" />
          <span class="sr-only">{@game.name}</span>
        </div>
      </figure>
      <div class="card-body p-4">
        <h3 class="line-clamp-2 text-base font-semibold leading-tight">{@game.name}</h3>
        <div class="card-actions mt-2">
          <button type="button" class="btn btn-primary btn-sm">Ver detalles</button>
        </div>
      </div>
    </div>
    """
  end
end
