defmodule PukllayClubWeb.GameCard do
  @moduledoc """
  Stateless card rendering a single `PukllayClub.Catalog.Game` in the browse
  grid (CATALOG-01). Intentionally a `Phoenix.Component`, not a
  `Phoenix.LiveComponent` — filter state and stream updates live in the
  parent `PukllayClubWeb.CatalogLive.Index`, per 01-PATTERNS.md.

  Teaches complexity in plain Spanish (CATALOG-05/06/07, 01-06/01-07) via
  three visually ranked tiers, separated by a size step first and hue
  second (a large enough size gap outranks weight alone, per
  ui-design-system):

  1. PRIMARY — `GameChips.weight_band_badge/1` (label only — the
     descriptor line is a detail-page/hover affordance, kept off the card
     so a 434-card grid stays scannable), rendered at `badge-lg` directly
     under the title.
  2. SECONDARY — the club's editorial hashtags (`GameChips.editorial_tags`,
     capped at 2 with a `+N` overflow chip) and the mechanic chip row
     (`GameChips.chip_row`, capped at 4), grouped together in one shared
     `space-y-1` wrapper beneath the primary badge so they read as a single
     subordinate block rather than two rows competing with it.
  3. Both secondary rows render at `badge-sm` — do not "simplify" them back
     into a flat, co-equal stack; that is the exact G-01-6 defect this
     grouping fixes.

  The `Ver detalles` CTA links to `PukllayClubWeb.CatalogLive.Show`
  (01-03's inert placeholder button is now a real route).

  The cover `<img>` carries a `js-cover-fallback` class, not an inline
  `onerror` attribute — inline event-handler attributes are governed by
  `script-src` and are silently refused under this app's
  `PukllayClubWeb.CSP` (01-REVIEW.md CR-01). `assets/js/app.js` delegates a
  capture-phase `error` listener for `.js-cover-fallback` instead: a
  network/404 failure hides the broken image and reveals a hidden sibling
  brand-placeholder element, degrading to the same placeholder the
  nil-cover case already uses (01-UI-SPEC.md's "cover/gallery image load
  failure" row) — distinct from the nil-URL case, which renders the
  placeholder directly with no `<img>` at all.

  Accepts an optional `:class` so a caller (the grid vs. a horizontally
  -scrolling `CarouselRow` rail, 01-05) can control the card's width/shrink
  behavior without this component needing to know which context it's in.
  """
  use PukllayClubWeb, :html

  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.GameChips
  alias PukllayClubWeb.GamePreview

  attr :id, :string, required: true
  attr :game, PukllayClub.Catalog.Game, required: true
  attr :class, :any, default: nil

  def game_card(assigns) do
    assigns = assign(assigns, :mechanic_labels, Vocabulary.covered_mechanics(assigns.game.mechanics))

    ~H"""
    <div id={@id} data-game-card class={["card bg-base-200 shadow-sm", @class]}>
      <figure class="aspect-square overflow-hidden bg-base-300">
        <img
          :if={@game.thumbnail_url}
          src={@game.thumbnail_url}
          alt={@game.name}
          loading="lazy"
          class="h-full w-full object-cover js-cover-fallback"
        />
        <div
          :if={@game.thumbnail_url}
          class="hidden h-full w-full items-center justify-center bg-base-300 text-primary"
        >
          <.icon name="hero-puzzle-piece" class="size-12" />
          <span class="sr-only">{@game.name}</span>
        </div>
        <div
          :if={!@game.thumbnail_url}
          class="flex h-full w-full items-center justify-center bg-base-300 text-primary"
        >
          <.icon name="hero-puzzle-piece" class="size-12" />
          <span class="sr-only">{@game.name}</span>
        </div>
      </figure>
      <div class="card-body space-y-2 p-4">
        <h3 class="line-clamp-2 text-base font-semibold leading-tight">{@game.name}</h3>
        <GameChips.weight_band_badge game={@game} show_descriptor={false} />
        <div class="space-y-1">
          <GameChips.editorial_tags tags={@game.tags} limit={2} />
          <GameChips.chip_row terms={@mechanic_labels} limit={4} />
        </div>
        <div class="card-actions mt-2">
          <.link navigate={~p"/juegos/#{@game}"} class="btn btn-primary btn-sm">
            Ver detalles
          </.link>
        </div>
      </div>
      <GamePreview.preview_template game={@game} />
    </div>
    """
  end
end
