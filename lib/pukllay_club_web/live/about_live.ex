defmodule PukllayClubWeb.AboutLive do
  @moduledoc """
  The club's About/landing page (SHELL-01/02).

  Reachable at two URL aliases pointing at this same LiveView — `/club`
  and `/quienes-somos` (D-01) — both must resolve identically; neither
  route redirects to the other.

  Content is the user-supplied real copy from `about-page-design-source.html`
  (D-06), used verbatim. The club model is play-at-the-club-only (D-09):
  members come play on Saturdays at a physical venue, the club brings the
  games — this page never describes borrowing or taking games home
  (D-09, prohibitions).

  Structure (D-07): hero -> four-slide photo rail (`.AboutCarousel`) -> the
  remaining content bands land in the rest of this plan (01.1-02). Every
  band shares the `.pk-band`/`.pk-band-inner` full-bleed-wrapper/capped-
  inner recipe so no band's content edge drifts from another's (the
  about-page-content.md double-gutter lesson).

  Renders inside the shared `Layouts.app` shell with the "Quiénes Somos"
  nav-links state (page-shell.md: About is a sibling top-level page, not
  a drill-down, so it gets the same nav-links row Inicio has with
  "Quiénes Somos" marked active — never a breadcrumb, per D-07/page-shell.md).

  **The hero's `Layouts.sumate_cta/1` call and the trailing
  `.pk-about-cta-spacer`/`.pk-about-cta-bar` pair (plans 01.1-08/01.1-09)
  are this club's ONLY join CTA site-wide (D-05 superseded) — every band
  this plan adds lives strictly between them, never inside or around them.**
  """
  use PukllayClubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Quiénes somos")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} fullbleed sticky active_nav={:quienes_somos}>
      <:nav_links>
        <.link navigate={~p"/"}>Inicio</.link>
        <.link navigate={~p"/quienes-somos"} aria-current="page">Quiénes Somos</.link>
      </:nav_links>

      <div class="mx-auto w-full max-w-7xl pk-gutter space-y-6">
        <section class="space-y-3 py-12 text-center">
          <p class="font-sans text-xs uppercase tracking-widest text-neutral">
            Club de juegos de mesa · Jujuy
          </p>
          <h1 class="font-display text-5xl">Conectá jugando</h1>
          <p class="font-sans text-base text-neutral">
            Nos juntamos todos los sábados a jugar. Venís, te sentás, alguien te explica.
          </p>
          <div class="flex justify-center">
            <Layouts.sumate_cta />
          </div>
        </section>
      </div>

      <%!-- Four-slide photo rail (D-07, D-12: labelled placeholders — no real
      club photography exists yet). Hand-rolled colocated hook, same pattern
      as CarouselRow's .CarouselScroll — deliberately no scroll-observer-
      driven visibility API anywhere here (01.1-RESEARCH.md Pitfall 3: that
      class of API throttles in a backgrounded tab, which would leave the
      design source's own fade-in stuck at opacity 0; that reveal is
      deliberately not reproduced, D-08 scopes it reference-only). --%>
      <section id="fotos" class="pk-band">
        <div class="pk-band-inner pk-gutter">
          <div id="about-carousel" phx-hook=".AboutCarousel">
            <script :type={Phoenix.LiveView.ColocatedHook} name=".AboutCarousel">
              export default {
                mounted() {
                  this.rail = this.el.querySelector("[data-rail]")
                  this.dots = Array.from(this.el.querySelectorAll("[data-goto]"))
                  this.slideCount = this.dots.length
                  this.index = 0
                  this.paused = false
                  this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)")

                  this.slideAdvance = () => {
                    const first = this.rail.firstElementChild
                    if (!first) return this.rail.clientWidth
                    const style = getComputedStyle(this.rail)
                    const gap = parseFloat(style.columnGap || style.gap || "0") || 0
                    return first.getBoundingClientRect().width + gap
                  }

                  this.goTo = (index) => {
                    this.rail.scrollTo({left: index * this.slideAdvance(), behavior: "smooth"})
                  }

                  this.setActive = (index) => {
                    this.index = index
                    this.dots.forEach((dot, i) => {
                      dot.classList.toggle("is-active", i === index)
                      if (i === index) {
                        dot.setAttribute("aria-current", "true")
                      } else {
                        dot.removeAttribute("aria-current")
                      }
                    })
                  }

                  this.onClick = (e) => {
                    const button = e.target.closest("[data-goto]")
                    if (!button || !this.el.contains(button)) return
                    this.paused = true
                    this.goTo(parseInt(button.dataset.goto, 10))
                  }
                  this.el.addEventListener("click", this.onClick)

                  this.onScroll = () => {
                    const advance = this.slideAdvance()
                    if (advance <= 0) return
                    const raw = Math.round(this.rail.scrollLeft / advance)
                    const index = Math.min(Math.max(raw, 0), this.slideCount - 1)
                    if (index !== this.index) this.setActive(index)
                  }
                  this.rail.addEventListener("scroll", this.onScroll, {passive: true})

                  this.onPointerDown = () => { this.paused = true }
                  this.onMouseEnter = () => { this.paused = true }
                  this.onMouseLeave = () => { this.paused = false }
                  this.rail.addEventListener("pointerdown", this.onPointerDown)
                  this.rail.addEventListener("mouseenter", this.onMouseEnter)
                  this.rail.addEventListener("mouseleave", this.onMouseLeave)

                  this.timer = setInterval(() => {
                    if (this.paused || !document.hasFocus() || this.reducedMotion.matches) return
                    this.goTo((this.index + 1) % this.slideCount)
                  }, 4500)
                },
                destroyed() {
                  clearInterval(this.timer)
                  this.el.removeEventListener("click", this.onClick)
                  this.rail?.removeEventListener("scroll", this.onScroll)
                  this.rail?.removeEventListener("pointerdown", this.onPointerDown)
                  this.rail?.removeEventListener("mouseenter", this.onMouseEnter)
                  this.rail?.removeEventListener("mouseleave", this.onMouseLeave)
                }
              }
            </script>
            <div data-rail class="pk-about-rail">
              <figure class="pk-about-slide">
                <div class="pk-about-slide-ph">
                  <span class="text-primary text-xs uppercase tracking-widest">
                    foto — mesa llena un sábado
                  </span>
                </div>
              </figure>
              <figure class="pk-about-slide">
                <div class="pk-about-slide-ph">
                  <span class="text-primary text-xs uppercase tracking-widest">
                    foto — explicando un juego
                  </span>
                </div>
              </figure>
              <figure class="pk-about-slide">
                <div class="pk-about-slide-ph">
                  <span class="text-primary text-xs uppercase tracking-widest">
                    foto — la ludoteca
                  </span>
                </div>
              </figure>
              <figure class="pk-about-slide">
                <div class="pk-about-slide-ph">
                  <span class="text-primary text-xs uppercase tracking-widest">
                    foto — la comunidad
                  </span>
                </div>
              </figure>
            </div>
            <div data-dots class="pk-about-dots">
              <button
                type="button"
                data-goto="0"
                aria-label="Foto 1"
                aria-current="true"
                class="pk-about-dot is-active min-h-11 min-w-11"
              ></button>
              <button
                type="button"
                data-goto="1"
                aria-label="Foto 2"
                class="pk-about-dot min-h-11 min-w-11"
              ></button>
              <button
                type="button"
                data-goto="2"
                aria-label="Foto 3"
                class="pk-about-dot min-h-11 min-w-11"
              ></button>
              <button
                type="button"
                data-goto="3"
                aria-label="Foto 4"
                class="pk-about-dot min-h-11 min-w-11"
              ></button>
            </div>
          </div>
        </div>
      </section>

      <%!-- About-scoped mobile sticky join-CTA bar (01.1-09, D-05 superseded).
      Page-owned, not shell-owned: no other route can accidentally inherit it,
      which is the whole point of the D-05 supersession — a site-wide sticky
      bar would put the join ask back on every page the header just stopped
      putting it on. Reuses the hero's own sumate_cta/1 so the two placements
      can never drift to different labels/destinations. Both elements are
      display:none at base, turned on only in the trailing @media (max-width:
      480px) block. --%>
      <div class="pk-about-cta-spacer" aria-hidden="true"></div>
      <div class="pk-about-cta-bar"><Layouts.sumate_cta class="w-full" /></div>
    </Layouts.app>
    """
  end
end
