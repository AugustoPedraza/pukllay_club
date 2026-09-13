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

  **G-01.2-20: this component currently has no call site in `lib/`.** Its
  only render site (the detail page's reading column) was removed by
  01.2-20 Task 1 on direct UAT instruction ("still it shows its 'category'
  pills with a description(remove it)") — the plain-Spanish band label
  survives in `GamePreview.facts_row/1`'s dificultad pill, but the one-line
  descriptor this component renders has no replacement home anywhere on
  the page. Whether that is acceptable is an open question against
  CATALOG-05 ("plain-Spanish weight-band + one-line complexity
  descriptor"), routed to the developer for a REQUIREMENTS.md amendment
  decision or a follow-up gap — not resolved here. Do not delete this
  component or its tests as dead code, and do not silently wire it back up
  as a bug fix: both are wrong until that decision is made.

  **G-01.2-26 task 3:** its declared shape (`badge-lg h-auto whitespace-normal
  py-1 text-center leading-tight`) now has a formal home in the app's pill
  variant set — `assets/css/app.css`'s `.pk-pill-large` size variant. This
  component's markup is untouched (the standing instruction above still
  holds); if a future requirements decision brings it back, `.pk-pill
  .pk-pill-large` (plus a tone) is where its shape already lives.
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
  Renders up to `limit` already-translated Spanish `terms` as `pk-pill
  pk-pill-outline` chips (01.3-07 — the neutral tone this used to carry was
  superseded; `.pk-pill-outline` is `pills-chips.md`'s current
  informational-pill treatment, matching `CatalogLive.Show`'s Diseñadores/
  Ilustradores pills in the same fact grid), plus a trailing `+N` chip when
  there are more.
  Renders nothing for an empty list. Callers pass already-covered labels
  (e.g. `Vocabulary.covered_mechanics/1`) — this component never filters
  or translates on its own. `CatalogLive.Show` (the detail page's
  Mecánicas/Temáticas fact-grid columns) is this component's only call
  site (verified — `GameCard` uses neither this nor `editorial_tags/1`).

  Optional `href_fun` (01.1-06): a 1-arity function from a term to a
  navigate target. When given, each visible chip renders inside
  `<.link navigate={...}>` and additionally carries `pk-pill-interactive`;
  the overflow `+N` chip never links (it names no single term), so it
  never carries the interactive variant either. `nil` (the default) renders
  every existing caller byte-identically to before this attr existed.

  The wrapper carries a scoping class (`pk-chip-row`, G-01.2-20) kept as a
  test selector and a name for the row — it no longer scopes an override
  (G-01.2-26 task 3 emptied the CSS rule this class used to enable; see
  that rule's own forwarding note in `app.css`). `editorial_tags/1`
  deliberately does NOT carry this class; both rows now render from the
  same `pk-pill` base in two different tones, so there is nothing left for
  either wrapper class to scope.
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
    <div :if={@terms != []} class="pk-chip-row flex flex-wrap gap-2">
      <%= for term <- @visible do %>
        <.link
          :if={@href_fun}
          navigate={@href_fun.(term)}
          class="pk-pill pk-pill-outline pk-pill-interactive"
        >
          {term}
        </.link>
        <span :if={!@href_fun} class="pk-pill pk-pill-outline">{term}</span>
      <% end %>
      <span :if={@overflow > 0} class="pk-pill pk-pill-outline">+{@overflow}</span>
    </div>
    """
  end

  @doc """
  Renders each of the game's club editorial hashtags verbatim (leading `#`
  included), using the `pk-pill` base plus the tag tone (01.3-07 — see
  `.pk-pill-tag` in `app.css`, superseding the earlier accent-fill chip
  treatment). Sketch 042's 27-round-tested winner reads hashtags as
  lightweight accent-coloured TEXT sitting right after the detail page's
  title, not as a solid filled pill — `CatalogLive.Show` is this
  component's only call site (verified — `GameCard` uses neither this nor
  `chip_row/1`). This row and `chip_row/1`'s row still render from the
  same `pk-pill` base in two different tones — they read as the same
  component in a different tone, not as two unrelated components.

  Accepts an optional `limit`. `nil` (the default) renders every tag — the
  detail page's uncapped behaviour. When `limit` is an integer and there
  are more tags than the limit, renders the visible tags followed by one
  `+N` overflow chip, mirroring `chip_row/1`'s cap pattern.

  Optional `href_fun` (01.1-06): a 1-arity function from a tag to a
  navigate target, same contract as `chip_row/1`'s — a linked tag
  additionally carries `pk-pill-interactive`. `nil` (the default) renders
  every existing caller byte-identically to before this attr existed.

  Optional `class` (01.3-07): appended to the wrapper `div` so a caller can
  pass its own spacing class (`CatalogLive.Show` passes `pk-rhythm-8` to
  tie this row to the title via `.pk-text-col`'s child-margin rhythm) —
  without adding a wrapper element around this component just to carry
  that one class. `nil` (the default) renders byte-identically to before
  this attr existed.
  """
  attr :tags, :list, required: true
  attr :limit, :integer, default: nil
  attr :href_fun, :any, default: nil
  attr :class, :string, default: nil

  def editorial_tags(assigns) do
    visible = if assigns.limit, do: Enum.take(assigns.tags, assigns.limit), else: assigns.tags
    overflow = length(assigns.tags) - length(visible)

    assigns =
      assigns
      |> assign(:visible, visible)
      |> assign(:overflow, overflow)

    ~H"""
    <div :if={@tags != []} class={["flex flex-wrap gap-x-1 gap-y-2", @class]}>
      <%= for tag <- @visible do %>
        <.link
          :if={@href_fun}
          navigate={@href_fun.(tag)}
          class="pk-pill pk-pill-tag pk-pill-interactive"
        >
          {tag}
        </.link>
        <span :if={!@href_fun} class="pk-pill pk-pill-tag">{tag}</span>
      <% end %>
      <span :if={@overflow > 0} class="pk-pill pk-pill-tag">+{@overflow}</span>
    </div>
    """
  end
end
