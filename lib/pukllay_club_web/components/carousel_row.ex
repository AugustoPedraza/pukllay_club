defmodule PukllayClubWeb.CarouselRow do
  @moduledoc """
  Shell-capped, edge-fade horizontally-scrolling rail of `GameCard`s (sketch
  001, variant D), plus the matching `skeleton_card/1` loading placeholder.
  Renders one of the 8 fixed D-09 carousel rows above the browse grid.

  The rail's width comes from the shared shell column recipe (see
  `ui-design-system`'s SKILL.md) applied to `.pk-row-header`/`.pk-rail-wrap`,
  the same recipe the header and footer use — not from full-bleed viewport
  width (quick task 260824-9zo).

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

  `badge` (G-01.2-7, sketch 031): an optional small daisyUI `badge-accent`
  pill rendered inside the `<h2>` right after `@title` — the sole visible
  signal that `CatalogLive.Show`'s Juegos similares shelf had to widen
  beyond the viewed game's own weight band to stay full. Defaults `nil`;
  every one of the 8 home-page callers leaves it unset, so those rows are
  byte-identical to before this attr existed.

  G-01-3: the rail's horizontal scroll is intentional — it is NOT the
  responsive `#games` grid. The always-visible `.pk-rail-wrap` edge-fade
  is the primary passive scroll cue (01-11); Netflix-style edge-overlay
  chevrons (sketch 022, winner C) are a secondary cue gated to
  pointer-fine devices only — `@media (hover: hover) and (pointer: fine)`
  removes them from the rendered layout entirely on touch, so no dead tap
  target ever sits over the swipe area. A `.CarouselScroll` colocated hook
  writes `data-overflows` on `.pk-rail-wrap` (combined with the pointer-fine
  gate in CSS, not replaced by it) and scrolls the rail on click.
  """
  use Phoenix.Component

  alias PukllayClubWeb.CoreComponents
  alias PukllayClubWeb.GameCard

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :games, :any, required: true
  attr :variant, :atom, default: :standard, values: [:standard, :hero]
  attr :subtitle, :string, default: nil
  attr :empty, :boolean, default: false
  attr :row_key, :string, required: true
  attr :exhausted, :boolean, default: false
  # G-01.2-7 / sketch 031: an optional quiet annotation next to the title
  # (e.g. "Ampliado" on a widened Juegos similares shelf). `nil` for every
  # existing caller (the 8 home-page rows never pass it), so those rows
  # render byte-identically — see catalog_show_test.exs's home-page
  # invariance test.
  attr :badge, :string, default: nil

  def carousel_row(assigns) do
    ~H"""
    <section
      :if={not @empty}
      id={@id}
      class="pk-shelf space-y-3"
      phx-hook=".CarouselScroll"
      data-carousel-row={@row_key}
      data-exhausted={to_string(@exhausted)}
    >
      <script :type={Phoenix.LiveView.ColocatedHook} name=".CarouselScroll">
        export default {
          mounted() {
            this.rail = this.el.querySelector("[data-rail]")
            this.wrap = this.el.querySelector("[data-rail-wrap]")

            // Sketch 023-B, corrected by debug carousel-scroll-easing-jump.
            // 200ms over 0.85 of the rail's client width, replacing the browser's
            // fixed "smooth" behavior so an arrow click stays snappier than
            // native (measured: native scrollBy takes ~530ms for the same 1034px).
            //
            // This curve is the JS twin of --ease-standard, NOT of --ease-out-soft.
            // It used to be `1 - Math.pow(1 - t, 5)` (a quintic ease-out) on the
            // stated intent of matching a touch fling's feel. That was a category
            // error: a fling reads as continuous only because the FINGER supplied
            // the launch velocity — the hand is the ease-in. A click starts from
            // REST, so an ease-out's maximal t=0 velocity (v0 = nA/D for any
            // 1-(1-t)^n) is a velocity discontinuity, i.e. a teleport.
            // Measured at the amplitude cap (0.85 x 1216px = 1033.6px, where
            // 1216 = max-w-7xl 1280 minus 2x2rem gutter, so this is the true worst
            // case on any display >= 1440px): the quintic put 341px into the first
            // painted frame — 2.5x the PEAK frame of native smooth scroll, out of a
            // standing start, and more than two 176px card pitches. This bezier
            // puts 17.8px there instead.
            //
            // DO NOT "restore consistency" by putting an ease-OUT back here, and do
            // not try to fix a pop by lengthening scrollDuration: neither works.
            // Every 1-(1-t)^n starts at maximum velocity regardless of exponent
            // (the cubic n=3 still measures 237.5px), and rescuing the quintic by
            // duration alone would need 3591ms. Only v0 = 0 — an ease-in-out —
            // fixes it. Curve only; the 200ms is not implicated and shortening it
            // makes any front-loaded curve strictly worse.
            //
            // Kept as a closed-form solver rather than handing the scroll to CSS
            // because .pk-rail deliberately sets `scroll-behavior: auto` (see the
            // rule comment in app.css) — this loop assigns scrollLeft every frame,
            // and native smooth-scroll mode would start a competing animation per
            // assignment.
            //
            // Cancelled before a new loop starts and again in destroyed() so rapid
            // clicks never leave two loops writing scrollLeft in the same frame.
            const cubicBezier = (x1, y1, x2, y2) => {
              const cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx
              const cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by
              const xAt = (u) => ((ax * u + bx) * u + cx) * u
              const dxAt = (u) => (3 * ax * u + 2 * bx) * u + cx
              return (t) => {
                if (t <= 0) return 0
                if (t >= 1) return 1
                let u = t
                for (let i = 0; i < 8; i++) {
                  const dx = dxAt(u)
                  if (dx < 1e-6) break
                  const err = xAt(u) - t
                  if (Math.abs(err) < 1e-6) break
                  u -= err / dx
                }
                return ((ay * u + by) * u + cy) * u
              }
            }
            const easeStandard = cubicBezier(0.4, 0, 0.2, 1)
            const scrollDuration = 200

            this.onClick = (e) => {
              const button = e.target.closest("[data-scroll]")
              if (!button || !this.el.contains(button)) return
              const direction = button.dataset.scroll === "prev" ? -1 : 1
              const delta = direction * this.rail.clientWidth * 0.85
              const start = this.rail.scrollLeft

              cancelAnimationFrame(this.frame)

              if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
                this.rail.scrollLeft = start + delta
                return
              }

              const startTime = performance.now()
              const step = (now) => {
                const t = Math.min(1, (now - startTime) / scrollDuration)
                this.rail.scrollLeft = start + delta * easeStandard(t)
                if (t < 1) this.frame = requestAnimationFrame(step)
              }
              this.frame = requestAnimationFrame(step)
            }
            this.el.addEventListener("click", this.onClick)

            this.sync = () => {
              const overflows = this.rail.scrollWidth > this.rail.clientWidth
              this.wrap.dataset.overflows = String(overflows)
            }
            this.sync()

            this.resizeObserver = new ResizeObserver(() => this.sync())
            this.resizeObserver.observe(this.rail)

            // Fetch-more trigger (quick task 260824-u5d). No horizontal
            // equivalent of phx-viewport-bottom exists, so this rail's own
            // scroll position drives it. `pending` is released ONLY from
            // pushEvent's reply callback — one round trip carries both the
            // new cards and the stop signal, so no fixed-timeout guess is
            // needed. The loading indicator is driven here, client-side,
            // rather than through a server assign: the handler is
            // synchronous, so a server-driven flag would be set and cleared
            // within the same round trip and the placeholders would never
            // actually be visible.
            this.pending = false
            this.exhausted = this.el.dataset.exhausted === "true"
            this.rowKey = this.el.dataset.carouselRow

            this.maybeLoadMore = () => {
              if (this.pending || this.exhausted) return
              const runway = this.rail.scrollWidth - this.rail.scrollLeft - this.rail.clientWidth
              if (runway > this.rail.clientWidth) return

              this.pending = true
              this.rail.dataset.loading = "true"
              this.pushEvent("carousel-load-more", {row: this.rowKey}, (reply) => {
                this.pending = false
                delete this.rail.dataset.loading
                if (reply && reply.exhausted) this.exhausted = true
              })
            }

            // rAF-throttled, with its own frame handle distinct from the
            // arrow-scroll animation above — a touch-momentum fling fires
            // `scroll` far more often than once per frame, and the runway
            // computation forces layout each time.
            this.onScroll = () => {
              if (this.scrollFrame) return
              this.scrollFrame = requestAnimationFrame(() => {
                this.scrollFrame = null
                this.maybeLoadMore()
              })
            }
            this.rail.addEventListener("scroll", this.onScroll, {passive: true})
          },
          updated() {
            this.sync()
            // Re-read in case a server-driven stop (the reply above, or a
            // future filter-triggered row reset) changed the data attribute.
            this.exhausted = this.el.dataset.exhausted === "true"
          },
          destroyed() {
            this.el.removeEventListener("click", this.onClick)
            this.rail.removeEventListener("scroll", this.onScroll)
            cancelAnimationFrame(this.scrollFrame)
            this.resizeObserver?.disconnect()
            cancelAnimationFrame(this.frame)
          }
        }
      </script>
      <div class="pk-row-header mx-auto w-full max-w-7xl pk-gutter flex items-end justify-between gap-4">
        <div class="space-y-1">
          <h2 class={["font-display text-2xl", @variant == :hero && "text-primary"]}>
            {@title}<span
              :if={@badge}
              class="badge badge-accent badge-sm rounded-full font-bold ml-2 align-middle"
            >{@badge}</span>
          </h2>
          <p :if={@subtitle} class="text-neutral text-sm">{@subtitle}</p>
        </div>
      </div>
      <div data-rail-wrap class="pk-rail-wrap mx-auto w-full max-w-7xl pk-gutter">
        <button
          type="button"
          data-scroll="prev"
          aria-label="Desplazar hacia la izquierda"
          class="pk-rail-btn"
        >
          <CoreComponents.icon name="hero-chevron-left-solid" class="size-8" />
        </button>
        <div data-rail id={"#{@id}-rail"} phx-update="stream" class="pk-rail">
          <GameCard.game_card
            :for={{dom_id, game} <- @games}
            id={dom_id}
            game={game}
            class={["pk-poster-card", @variant == :hero && "is-hero"]}
          />
          <%!-- Permanent trailing skeleton placeholders (quick task
          260824-u5d): non-stream items in a phx-update="stream" container
          can be added/updated but never removed, so these render
          unconditionally with stable ids and are toggled by CSS
          (.pk-rail[data-loading], set/cleared by the hook above) rather
          than by :if — a conditional render would put them in the DOM
          once and strand them there permanently. Two is enough to signal
          "more is coming"; they land trailing for free since LiveView
          inserts at: -1 items before the first non-stream child. --%>
          <.skeleton_card
            id={"#{@id}-skel-1"}
            class={["pk-poster-card pk-trailing-skel", @variant == :hero && "is-hero"]}
          />
          <.skeleton_card
            id={"#{@id}-skel-2"}
            class={["pk-poster-card pk-trailing-skel", @variant == :hero && "is-hero"]}
          />
        </div>
        <button
          type="button"
          data-scroll="next"
          aria-label="Desplazar hacia la derecha"
          class="pk-rail-btn"
        >
          <CoreComponents.icon name="hero-chevron-right-solid" class="size-8" />
        </button>
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
      <div class="pk-row-header mx-auto w-full max-w-7xl pk-gutter space-y-1">
        <div class="pk-skel h-7 w-48"></div>
        <div class="pk-skel h-4 w-32"></div>
      </div>
      <div class="pk-rail-wrap mx-auto w-full max-w-7xl pk-gutter">
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
