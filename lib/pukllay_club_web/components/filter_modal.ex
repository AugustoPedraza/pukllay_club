defmodule PukllayClubWeb.FilterModal do
  @moduledoc """
  Stateless filter modal (SHELL-04, 01.1-06, quick-260824-b71) — replaces
  the slide-over `FilterDrawer` retired before it. Presents a pinned
  three-region shell (header / scrolling body / pinned footer) holding
  the free-text query input, weight-band/editorial/mechanic/theme facet
  pills, and player-count/playtime/min-age scalar controls. The footer
  holds two actions: a `Limpiar filtros` secondary button (disabled
  whenever no filter or query is active) and a `Ver N juegos` primary
  CTA.

  Every pill toggle still emits `"toggle-facet"` with `phx-value-facet`/
  `phx-value-value`; the query input still emits `"search"` with
  `phx-debounce="300"`. Selection state and open/closed state both live
  entirely in the parent `PukllayClubWeb.CatalogLive.Index` (this is a
  `Phoenix.Component`, not a `Phoenix.LiveComponent` — no state of its
  own, matching `FilterDrawer`'s discipline before it, per
  01-PATTERNS.md). Live-apply is unchanged by this shell: every control
  still applies its filter immediately on click/keystroke, nothing is
  staged. The CTA is an exit affordance, not a submit — its only effect
  is `phx-click="close-filters"`; it does not filter or apply anything
  itself, since filtering already happened underneath.

  `core_components.ex` was checked and has no modal component — this uses
  daisyUI's bundled `modal`/`modal-open`/`modal-box`/`modal-backdrop`
  classes directly (confirmed unwired-but-available per
  `ux-patterns` SKILL.md row B10). The root element also carries
  `modal-bottom sm:modal-middle`, daisyUI's own responsive modifiers:
  below Tailwind's `sm` (640px) the panel renders as a bottom sheet
  (bottom-aligned, full-width, top-corners-only rounded); at and above it,
  a centered dialog. No custom media query or `.pk-*` class is needed —
  same markup, same events, same content order at both sizes.

  The `.FilterModal` colocated hook below owns only Escape-to-close and
  Tab focus-trapping — both copied structurally from `GamePreview`'s
  `onSheetKeydown` pattern (game_preview.ex), the same pattern
  `layouts.ex`'s mobile drawer already reused. Backdrop click and the
  explicit close button both dispatch the existing `close-filters` event
  directly; the hook never talks to the server.
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
  attr :open, :boolean, default: false
  attr :q, :string, default: ""
  attr :total, :integer, default: 0
  attr :filters_active, :boolean, default: false

  def filter_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={["modal", "modal-bottom", "sm:modal-middle", @open && "modal-open"]}
      phx-hook=".FilterModal"
      data-modal-open={to_string(@open)}
    >
      <script :type={Phoenix.LiveView.ColocatedHook} name=".FilterModal">
        export default {
          mounted() {
            this.box = this.el.querySelector(".modal-box")
            this.closeBtn = this.el.querySelector("[data-modal-close]")
            this.wasOpen = this.el.dataset.modalOpen === "true"

            this.onKeydown = (event) => {
              if (event.key === "Escape") {
                event.preventDefault()
                this.closeBtn?.click()
                return
              }
              if (event.key !== "Tab" || !this.box) return
              const focusable = this.box.querySelectorAll(
                'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
              )
              if (focusable.length === 0) return
              const first = focusable[0]
              const last = focusable[focusable.length - 1]
              if (event.shiftKey && document.activeElement === first) {
                event.preventDefault()
                last.focus()
              } else if (!event.shiftKey && document.activeElement === last) {
                event.preventDefault()
                first.focus()
              }
            }
            this.el.addEventListener("keydown", this.onKeydown)

            if (this.wasOpen) this.closeBtn?.focus()
          },
          updated() {
            const isOpen = this.el.dataset.modalOpen === "true"
            if (isOpen && !this.wasOpen) this.closeBtn?.focus()
            this.wasOpen = isOpen
          },
          destroyed() {
            this.el.removeEventListener("keydown", this.onKeydown)
          }
        }
      </script>

      <button
        type="button"
        class="modal-backdrop"
        aria-label="Cerrar filtros"
        phx-click="close-filters"
      ></button>

      <div
        class="modal-box flex flex-col overflow-hidden p-0"
        role="dialog"
        aria-modal="true"
        aria-label="Filtros"
      >
        <div class="flex flex-none items-center justify-between border-b border-base-300 p-4">
          <h2 class="font-display text-xl">Filtros</h2>
          <button
            type="button"
            data-modal-close
            phx-click="close-filters"
            aria-label="Cerrar filtros"
            class="btn btn-ghost btn-circle min-h-11 min-w-11"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>

        <div class="min-h-0 flex-1 space-y-3 overflow-y-auto p-4">
          <form phx-change="search" id={"#{@id}-search"}>
            <.input
              type="text"
              name="q"
              value={@q}
              placeholder="Busca por título, autor o editorial…"
              phx-debounce="300"
              maxlength="100"
            />
          </form>

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

        <%!-- button/1 uses assign_new(:class, ...), which only fills in a
        default when :class is unset — passing class explicitly REPLACES the
        variant class list rather than appending to it. Both footer actions
        therefore pass an explicit class list and omit variant entirely. --%>
        <div class="flex flex-none items-center justify-between gap-3 border-t border-base-300 p-4">
          <.button
            class={["btn", "btn-outline", "btn-primary", "min-h-11"]}
            phx-click="clear-filters"
            disabled={not @filters_active}
          >
            Limpiar filtros
          </.button>
          <.button class={["btn", "btn-primary", "min-h-11"]} phx-click="close-filters">
            {cta_label(@total)}
          </.button>
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

  defp cta_label(1), do: "Ver 1 juego"
  defp cta_label(n), do: "Ver #{n} juegos"
end
