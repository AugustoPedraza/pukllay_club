defmodule PukllayClubWeb.CarouselRow do
  @moduledoc """
  Stateless horizontally-scrolling rail of `GameCard`s, plus the matching
  `skeleton_card/1` loading placeholder. Renders one of the 8 fixed D-09
  carousel rows above the browse grid.

  daisyUI's `carousel`/`carousel-item` class names are confirmed v5-safe
  by 01-RESEARCH.md Pitfall 5 (unchanged from v4). A row backed by zero
  games renders nothing at all — an empty titled rail would read as
  breakage, not as "nothing here yet".

  `variant`/`subtitle` (G-01-4) exist so the caller can differentiate the
  8 D-09 rows from one another: `variant: :hero` ranks a row above the
  rest by colour (never by a fourth type size — see ui-design-system), and
  `subtitle` is a one-line plain-Spanish explanation of what that shelf is.
  The caller owns the copy; this component only renders it.

  G-01-3: the rail's horizontal scroll is intentional (daisyUI `.carousel`
  is `overflow-x` scroll with no wrap, capped at the Catalog context's
  `@carousel_limit`) — it is NOT the responsive `#games` grid, and it was
  originally misread as an unresponsive grid precisely because daisyUI's
  `.carousel` also sets `scrollbar-width: none`, leaving no visible cue
  that the rail scrolls at all. The persistent prev/next controls below
  are the fix: a `.CarouselScroll` colocated hook scrolls the rail and
  hides the controls whenever the rail has nothing to scroll to.
  """
  use Phoenix.Component

  alias PukllayClubWeb.CoreComponents
  alias PukllayClubWeb.GameCard

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :games, :list, required: true
  attr :variant, :atom, default: :standard, values: [:standard, :hero]
  attr :subtitle, :string, default: nil

  def carousel_row(assigns) do
    ~H"""
    <section :if={@games != []} id={@id} class="space-y-3" phx-hook=".CarouselScroll">
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
      <div class="flex items-end justify-between gap-4">
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
      <div data-rail class="carousel carousel-center gap-4 rounded-box">
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
      <div class="space-y-1">
        <div class="skeleton h-7 w-48"></div>
        <div class="skeleton h-4 w-32"></div>
      </div>
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
