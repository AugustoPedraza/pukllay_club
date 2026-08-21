defmodule PukllayClubWeb.FilterDrawer do
  @moduledoc """
  Stateless slide-over filter panel (D-13) — a `Filtros` trigger button plus
  a `drawer-side` panel holding weight-band pills, editorial-hashtag pills,
  mechanic pills, theme pills, and player-count/playtime/min-age number
  inputs.

  Every pill toggle emits `"toggle-facet"` with `phx-value-facet`/
  `phx-value-value`; every number input lives in one
  `phx-change="set-scalar"` form. Selection state lives entirely in the
  parent `PukllayClubWeb.CatalogLive.Index` (this is a `Phoenix.Component`,
  not a `Phoenix.LiveComponent` — no state of its own, per 01-PATTERNS.md).
  daisyUI's `drawer`/`drawer-toggle`/`drawer-side`/`drawer-content`/
  `drawer-overlay` class names are confirmed unchanged between v4 and v5
  (01-RESEARCH.md Pitfall 5).
  """
  use Phoenix.Component

  import PukllayClubWeb.CoreComponents

  attr :id, :string, required: true
  attr :facet_options, :map, required: true
  attr :mechanics, :list, default: []
  attr :themes, :list, default: []
  attr :weight_bands, :list, default: []
  attr :tags, :list, default: []
  attr :players, :integer, default: nil
  attr :max_playtime, :integer, default: nil
  attr :min_age, :integer, default: nil

  def filter_drawer(assigns) do
    ~H"""
    <div class="drawer drawer-end w-fit shrink-0">
      <input id={"#{@id}-toggle"} type="checkbox" class="drawer-toggle" />
      <div class="drawer-content">
        <label for={"#{@id}-toggle"} class="btn btn-primary min-h-11">
          <.icon name="hero-adjustments-horizontal" class="size-5" /> Filtros
        </label>
      </div>
      <div class="drawer-side z-40">
        <label for={"#{@id}-toggle"} aria-label="Cerrar filtros" class="drawer-overlay"></label>
        <div class="bg-base-200 min-h-full w-80 space-y-6 p-6">
          <h2 class="font-display text-xl">Filtros</h2>

          <section>
            <h3 class="mb-2 text-sm font-semibold">Nivel</h3>
            <div class="flex flex-wrap gap-2">
              <.facet_pill
                :for={band <- @facet_options.weight_bands}
                facet="weight_bands"
                value={band.value}
                label={band.label}
                selected={band.value in @weight_bands}
              />
            </div>
          </section>

          <section>
            <h3 class="mb-2 text-sm font-semibold">Destacados</h3>
            <div class="flex flex-wrap gap-2">
              <.facet_pill
                :for={tag <- @facet_options.editorial_tags}
                facet="tags"
                value={tag.tag}
                label={String.trim_leading(tag.tag, "#")}
                selected={tag.tag in @tags}
              />
            </div>
          </section>

          <section>
            <h3 class="mb-2 text-sm font-semibold">Mecánicas</h3>
            <div class="flex flex-wrap gap-2">
              <.facet_pill
                :for={label <- @facet_options.mechanics}
                facet="mechanics"
                value={label}
                label={label}
                selected={label in @mechanics}
              />
            </div>
          </section>

          <section>
            <h3 class="mb-2 text-sm font-semibold">Temáticas</h3>
            <div class="flex flex-wrap gap-2">
              <.facet_pill
                :for={label <- @facet_options.themes}
                facet="themes"
                value={label}
                label={label}
                selected={label in @themes}
              />
            </div>
          </section>

          <section>
            <h3 class="mb-2 text-sm font-semibold">Otros filtros</h3>
            <form phx-change="set-scalar" id={"#{@id}-scalars"} class="space-y-2">
              <.input type="number" name="players" value={@players} label="Jugadores" min="1" />
              <.input
                type="number"
                name="max_playtime"
                value={@max_playtime}
                label="Duración máxima (min)"
                min="1"
              />
              <.input type="number" name="min_age" value={@min_age} label="Edad mínima" min="0" />
            </form>
          </section>
        </div>
      </div>
    </div>
    """
  end

  attr :facet, :string, required: true
  attr :value, :string, required: true
  attr :label, :string, required: true
  attr :selected, :boolean, default: false

  defp facet_pill(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="toggle-facet"
      phx-value-facet={@facet}
      phx-value-value={@value}
      aria-pressed={@selected}
      class={[
        "badge min-h-11 px-3",
        (@selected && "badge-primary") || "badge-neutral badge-outline"
      ]}
    >
      {@label}
    </button>
    """
  end
end
