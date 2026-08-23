defmodule PukllayClubWeb.CarouselRow do
  @moduledoc """
  Full-bleed, edge-fade horizontally-scrolling rail of `GameCard`s (sketch
  001, variant D), plus the matching `skeleton_card/1` loading placeholder.
  Renders one of the 8 fixed D-09 carousel rows above the browse grid.

  Not daisyUI's `.carousel` component (used pre-01-11): that component
  hides the scrollbar with no replacement cue, which is precisely why the
  rail read as an unresponsive grid before this plan. The edge-fade width,
  the rail gap, the card width and the side gutter are a co-dependent set
  of numbers that only work when declared together in one CSS location —
  which is also why the card width now lives in `assets/css/app.css`'s
  `.pk-poster-card` rather than in Tailwind width utilities passed here.

  `variant`/`subtitle` (G-01-4) exist so the caller can differentiate the
  8 D-09 rows from one another: `variant: :hero` ranks a row above the
  rest by colour (never by a fourth type size — see ui-design-system), and
  `subtitle` is a one-line plain-Spanish explanation of what that shelf is.
  The caller owns the copy; this component only renders it.

  G-01-3: the rail's horizontal scroll is intentional — it is NOT the
  responsive `#games` grid. The always-visible `.pk-rail-wrap` edge-fade
  is now the primary passive scroll cue (01-11); the persistent prev/next
  controls below stay as a secondary, pointer-device cue: a
  `.CarouselScroll` colocated hook scrolls the rail and hides the controls
  whenever the rail has nothing to scroll to.
  """
  use Phoenix.Component

  alias PukllayClubWeb.CoreComponents
  alias PukllayClubWeb.GameCard

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :games, :list, required: true
  attr :variant, :atom, default: :standard, values: [:standard, :hero]
  attr :subtitle, :string, default: nil
  attr :see_all_row, :string, default: nil

  def carousel_row(assigns) do
    ~H"""
    <section :if={@games != []} id={@id} class="pk-shelf space-y-3" phx-hook=".CarouselScroll">
      <script :type={Phoenix.LiveView.ColocatedHook} name=".CarouselScroll">
        export default {
          mounted() {
            this.rail = this.el.querySelector("[data-rail]")
            this.controls = this.el.querySelector("[data-controls]")

            this.onClick = (e) => {
              const button = e.target.closest("[data-scroll]")
              if (!button || !this.el.contains(button)) return
              const direction = button.dataset.scroll === "prev" ? -1 : 1
              this.rail.scrollBy({left: direction * this.rail.clientWidth * 0.9, behavior: "smooth"})
            }
            this.el.addEventListener("click", this.onClick)

            this.sync = () => {
              const overflows = this.rail.scrollWidth > this.rail.clientWidth
              this.controls.classList.toggle("hidden", !overflows)
            }
            this.sync()

            this.resizeObserver = new ResizeObserver(() => this.sync())
            this.resizeObserver.observe(this.rail)
          },
          updated() {
            this.sync()
          },
          destroyed() {
            this.el.removeEventListener("click", this.onClick)
            this.resizeObserver?.disconnect()
          }
        }
      </script>
      <div class="pk-row-header pk-gutter flex items-end justify-between gap-4">
        <div class="space-y-1">
          <h2 class={["font-display text-2xl", @variant == :hero && "text-primary"]}>{@title}</h2>
          <p :if={@subtitle} class="text-neutral text-sm">{@subtitle}</p>
        </div>
        <div data-controls class="hidden flex items-center gap-2">
          <button
            type="button"
            data-scroll="prev"
            aria-label="Desplazar hacia la izquierda"
            class="btn btn-circle size-11"
          >
            <CoreComponents.icon name="hero-chevron-left" class="size-5" />
          </button>
          <button
            type="button"
            data-scroll="next"
            aria-label="Desplazar hacia la derecha"
            class="btn btn-circle size-11"
          >
            <CoreComponents.icon name="hero-chevron-right" class="size-5" />
          </button>
        </div>
      </div>
      <div class="pk-rail-wrap pk-gutter">
        <div data-rail class="pk-rail">
          <GameCard.game_card
            :for={game <- @games}
            id={"#{@id}-#{game.id}"}
            game={game}
            class={["pk-poster-card", @variant == :hero && "is-hero"]}
          />
          <button
            :if={@see_all_row}
            type="button"
            phx-click="see-all"
            phx-value-row={@see_all_row}
            class={["pk-poster-card pk-see-all", @variant == :hero && "is-hero"]}
          >
            <CoreComponents.icon name="hero-arrow-right" class="size-5" />
            <span>Ver todo</span>
            <span>{@title}</span>
          </button>
        </div>
      </div>
    </section>
    """
  end

  @doc """
  Renders the same-footprint flat-skeleton-row treatment (`.pk-skel`, no
  shimmer) as `carousel_row/1`, for the loading backstop (01-UI-SPEC.md
  "Carousel rows" loading row).
  """
  attr :id, :string, required: true
  attr :count, :integer, default: 6

  def skeleton_row(assigns) do
    ~H"""
    <section id={@id} class="pk-shelf space-y-3">
      <div class="pk-row-header pk-gutter space-y-1">
        <div class="pk-skel h-7 w-48"></div>
        <div class="pk-skel h-4 w-32"></div>
      </div>
      <div class="pk-rail-wrap pk-gutter">
        <div class="pk-rail">
          <.skeleton_card :for={n <- 1..@count} id={"#{@id}-#{n}"} class="pk-poster-card" />
        </div>
      </div>
    </section>
    """
  end

  @doc """
  A single flat-skeleton-card placeholder, matching `GameCard.game_card/1`'s footprint (a
  `.pk-card-poster`-proportioned figure over a caption block) so the
  layout does not jump once real content replaces it.
  """
  attr :id, :string, required: true
  attr :class, :any, default: nil

  def skeleton_card(assigns) do
    ~H"""
    <div id={@id} class={["pk-card overflow-hidden rounded-box bg-base-200 shadow-sm", @class]}>
      <div class="pk-card-poster pk-skel w-full rounded-b-none"></div>
      <div class="pk-card-caption space-y-1">
        <div class="pk-skel h-4 w-3/4"></div>
      </div>
    </div>
    """
  end
end
