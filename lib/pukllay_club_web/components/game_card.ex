defmodule PukllayClubWeb.GameCard do
  @moduledoc """
  Stateless card rendering a single `PukllayClub.Catalog.Game` poster-forward
  at rest (CATALOG-01, sketch 002 variant D): cover art plus one truncated
  line of title, and nothing else. Intentionally a `Phoenix.Component`, not
  a `Phoenix.LiveComponent` — filter state and stream updates live in the
  parent `PukllayClubWeb.CatalogLive.Index`, per 01-PATTERNS.md.

  Every secondary fact — players, tiempo, difficulty, one editorial tag,
  the `Ver detalles` CTA — lives behind interaction in
  `PukllayClubWeb.GamePreview`: the desktop hover-intent portal or the
  mobile full-screen sheet. None of it renders on the resting card. The
  card's whole surface is itself a link to the detail page, so a click or
  Enter keypress navigates there without any hover having occurred; the
  full chip set (weight band, mechanics, editorial tags) still renders on
  that detail page via `GameChips`.

  The cover `<img>` carries a `js-cover-fallback` class, not an inline
  `onerror` attribute — inline event-handler attributes are governed by
  `script-src` and are silently refused under this app's
  `PukllayClubWeb.CSP` (01-REVIEW.md CR-01). `assets/js/app.js` delegates a
  capture-phase `error` listener for `.js-cover-fallback` instead: a
  network/404 failure hides the broken image and reveals a hidden sibling
  brand-placeholder element, degrading to the same placeholder the
  nil-cover case already uses (01-UI-SPEC.md's "cover/gallery image load
  failure" row) — distinct from the nil-URL case, which renders the
  placeholder directly with no `<img>` at all. The image's `alt` is empty
  because the adjacent caption heading already names the game inside the
  same link — repeating it would announce the name twice to a screen
  reader.

  Accepts an optional `:class` so a caller (the grid vs. a horizontally
  -scrolling `CarouselRow` rail, 01-05) can control the card's width/shrink
  behavior without this component needing to know which context it's in.

  Accepts an optional `:from` (D-08) — the caller's current catalog filter
  query string, as produced by `PukllayClubWeb.CatalogFilters.to_query/1`.
  When present, the detail-page link carries it as a `?from=` param so
  `CatalogLive.Show`'s breadcrumb can return the visitor to this same
  filtered view. Defaults to `nil`, in which case the link is unchanged
  from before this attr existed — only the grid (an active filter/search
  result set) passes a real value; carousel rows never do, since they only
  render when no filter is active (nothing to forward).
  """
  use PukllayClubWeb, :html

  alias PukllayClubWeb.GamePreview

  attr :id, :string, required: true
  attr :game, PukllayClub.Catalog.Game, required: true
  attr :class, :any, default: nil
  attr :from, :string, default: nil

  def game_card(assigns) do
    ~H"""
    <.link
      navigate={detail_path(@game, @from)}
      id={@id}
      data-game-card
      class={["pk-card block overflow-hidden rounded-box bg-base-200 shadow-sm", @class]}
    >
      <figure class="pk-card-poster overflow-hidden bg-base-300">
        <img
          :if={@game.thumbnail_url}
          src={@game.thumbnail_url}
          alt=""
          loading="lazy"
          class="h-full w-full object-cover js-cover-fallback"
        />
        <div
          :if={@game.thumbnail_url}
          class="hidden h-full w-full items-center justify-center bg-base-300 text-primary"
        >
          <.icon name="hero-puzzle-piece" class="size-12" />
        </div>
        <div
          :if={!@game.thumbnail_url}
          class="flex h-full w-full items-center justify-center bg-base-300 text-primary"
        >
          <.icon name="hero-puzzle-piece" class="size-12" />
        </div>
      </figure>
      <div class="pk-card-caption">
        <h3>{@game.name}</h3>
      </div>
      <GamePreview.preview_template game={@game} />
    </.link>
    """
  end

  # D-08: three literal clauses, never a dynamic path assembled from raw
  # strings — `nil`/`""` (no active filter to forward, the overwhelming
  # majority of call sites, including every carousel row) returns the
  # plain route; a real query string appends it as `?from=`, letting
  # Phoenix's verified-routes encoder do the percent-encoding.
  defp detail_path(game, nil), do: ~p"/juegos/#{game}"
  defp detail_path(game, ""), do: ~p"/juegos/#{game}"
  defp detail_path(game, from), do: ~p"/juegos/#{game}?#{[from: from]}"
end
