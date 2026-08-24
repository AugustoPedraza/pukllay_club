defmodule PukllayClubWeb.GameChips do
  @moduledoc """
  The three complexity-teaching / plain-Spanish chip components shared by
  `PukllayClubWeb.GameCard` (browse card) and `PukllayClubWeb.CatalogLive.Show`
  (detail page): the weight-band badge (CATALOG-05), the covered
  mechanic/theme chip row (CATALOG-06), and the club's editorial hashtag
  chips (CATALOG-07).

  Every label rendered here is produced by `PukllayClub.Catalog.Vocabulary`
  — these components never read a raw mechanics/themes value directly, and
  never render `Game.bgg_weight`. That is the single enforcement point for
  CATALOG-06's "no raw hobbyist jargon" rule.
  """
  use Phoenix.Component

  alias PukllayClub.Catalog.Vocabulary

  @doc """
  Renders the plain-Spanish weight-band label (and, when
  `show_descriptor` is true, its one-line descriptor) for `game`. Renders
  nothing when `game.weight_band` has no resolved band (D-18/D-20's
  "omit the missing chip" rule) — never a bare 1-5 number.
  """
  attr :game, PukllayClub.Catalog.Game, required: true
  attr :show_descriptor, :boolean, default: true

  def weight_band_badge(assigns) do
    assigns = assign(assigns, :band, Vocabulary.weight_band(assigns.game.weight_band))

    ~H"""
    <div :if={@band} class="space-y-1">
      <span class="badge badge-secondary badge-lg h-auto whitespace-normal py-1 text-center leading-tight">
        {@band.label}
      </span>
      <p :if={@show_descriptor} class="text-neutral text-sm">{@band.descriptor}</p>
    </div>
    """
  end

  @doc """
  Renders up to `limit` already-translated Spanish `terms` as
  `badge badge-sm` chips, plus a trailing `+N` chip when there are more.
  Renders nothing for an empty list. Callers pass already-covered labels
  (e.g. `Vocabulary.covered_mechanics/1`) — this component never filters
  or translates on its own.

  Optional `href_fun` (01.1-06): a 1-arity function from a term to a
  navigate target. When given, each visible chip renders inside
  `<.link navigate={...}>`; the overflow `+N` chip never links (it names no
  single term). `nil` (the default) renders every existing caller
  byte-identically to before this attr existed.
  """
  attr :terms, :list, required: true
  attr :limit, :integer, default: 4
  attr :href_fun, :any, default: nil

  def chip_row(assigns) do
    visible = Enum.take(assigns.terms, assigns.limit)
    overflow = length(assigns.terms) - length(visible)

    assigns =
      assigns
      |> assign(:visible, visible)
      |> assign(:overflow, overflow)

    ~H"""
    <div :if={@terms != []} class="flex flex-wrap gap-1">
      <%= for term <- @visible do %>
        <.link :if={@href_fun} navigate={@href_fun.(term)} class="badge badge-sm">{term}</.link>
        <span :if={!@href_fun} class="badge badge-sm">{term}</span>
      <% end %>
      <span :if={@overflow > 0} class="badge badge-sm">+{@overflow}</span>
    </div>
    """
  end

  @doc """
  Renders each of the game's club editorial hashtags verbatim (leading `#`
  included), using the single uniform small accent-chip treatment
  01-UI-SPEC.md's Color section locks for all 6 club hashtags — never a
  per-hashtag color.

  Accepts an optional `limit`. `nil` (the default) renders every tag — the
  detail page's uncapped behaviour. When `limit` is an integer and there
  are more tags than the limit, renders the visible tags followed by one
  `+N` overflow chip, mirroring `chip_row/1`'s cap pattern.

  Optional `href_fun` (01.1-06): a 1-arity function from a tag to a
  navigate target, same contract as `chip_row/1`'s. `nil` (the default)
  renders every existing caller byte-identically to before this attr
  existed.
  """
  attr :tags, :list, required: true
  attr :limit, :integer, default: nil
  attr :href_fun, :any, default: nil

  def editorial_tags(assigns) do
    visible = if assigns.limit, do: Enum.take(assigns.tags, assigns.limit), else: assigns.tags
    overflow = length(assigns.tags) - length(visible)

    assigns =
      assigns
      |> assign(:visible, visible)
      |> assign(:overflow, overflow)

    ~H"""
    <div :if={@tags != []} class="flex flex-wrap gap-1">
      <%= for tag <- @visible do %>
        <.link :if={@href_fun} navigate={@href_fun.(tag)} class="badge badge-sm badge-accent">
          {tag}
        </.link>
        <span :if={!@href_fun} class="badge badge-sm badge-accent">{tag}</span>
      <% end %>
      <span :if={@overflow > 0} class="badge badge-sm badge-accent">+{@overflow}</span>
    </div>
    """
  end
end
