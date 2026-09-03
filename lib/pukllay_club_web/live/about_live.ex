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

  Structure (D-07): hero -> four-slide photo rail (`.AboutCarousel`) ->
  "Qué hacemos"/"Nuestra historia" two-column band -> dark FAQ band
  (`#faq`) -> Juntadas (`#juntadas`) + Contacto (`#contacto`) band ->
  closing CTA band. Every band shares the `.pk-band`/`.pk-band-inner`
  full-bleed-wrapper/capped-inner recipe so no band's content edge drifts
  from another's (the about-page-content.md double-gutter lesson).

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

  alias PukllayClubWeb.ClubLinks

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
          <h1 class="font-display pk-about-h1">Conectá jugando</h1>
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

      <%!-- "Qué hacemos" / "Nuestra historia" — verbatim D-06 copy. --%>
      <section class="pk-band">
        <div class="pk-band-inner pk-gutter grid gap-11 sm:grid-cols-2">
          <div>
            <h2 class="font-display text-2xl">Qué hacemos</h2>
            <p class="text-lg">
              De más de 400 juegos elegimos la selección del día: esa es nuestra parte. La tuya es disfrutar. Si nunca jugaste a un juego de mesa moderno no importa, porque te explicamos las reglas ahí mismo y a los pocos minutos ya estás adentro de la partida, entre risas y gente que recién conocés.
            </p>
            <p class="text-lg">
              <a href="#juntadas">Dónde y cuándo jugamos ↓</a>
            </p>
          </div>
          <div>
            <h2 class="font-display text-2xl">Nuestra historia</h2>
            <p class="text-lg">
              Todo empezó en abril de 2021, la primera vez que abrimos las mesas a la comunidad, y desde entonces no paramos. Como club representamos a la provincia en encuentros nacionales, y así terminamos haciendo jugar a personas de todo el país, y también a viajeros de Francia, España y Portugal que estaban de paso por la ciudad. Más de cinco años después nos sigue emocionando lo mismo: una mesa alcanza para que dos extraños se pongan de acuerdo, se rían y quieran volver a jugar.
            </p>
          </div>
        </div>
      </section>

      <%!-- Dark FAQ band — the #faq anchor target the footer's FAQ link
      resolves to. Per D-11 there is no separate glossary/vocabulary
      section. Token mapping (Claude's discretion, D-08): bg-primary/
      text-primary-content, the brand's own measured-contrast pair, with
      weight (font-semibold on the question) as the emphasis lever instead
      of the design source's separate muted answer colour — a banned
      opacity-modifier utility on the content token is never used here. --%>
      <section id="faq" class="pk-band pk-band-dark">
        <div class="pk-band-inner pk-gutter">
          <h2 class="font-display text-2xl">Lo que todos preguntan</h2>
          <dl class="max-w-2xl space-y-7">
            <div class="pk-faq-item">
              <dt class="text-lg font-semibold">¿Cuándo y dónde?</dt>
              <dd class="text-lg">
                Todos los sábados desde las 16 hs, en el Club de Emprendedores, San Salvador de Jujuy.
              </dd>
            </div>
            <div class="pk-faq-item">
              <dt class="text-lg font-semibold">¿Cuánto cuesta?</dt>
              <dd class="text-lg">
                Reservá tu lugar por $5.000. ¿Venís de sorpresa? Son $7.000 — pero siempre hay lugar para vos.
              </dd>
            </div>
            <div class="pk-faq-item">
              <dt class="text-lg font-semibold">¿Tengo que saber jugar?</dt>
              <dd class="text-lg">
                No. La mayoría de los juegos se aprenden en diez minutos y siempre hay alguien para explicarte.
              </dd>
            </div>
            <div class="pk-faq-item">
              <dt class="text-lg font-semibold">¿Puedo ir solo?</dt>
              <dd class="text-lg">
                Sí, mucha gente viene sola. Te sumamos a una mesa apenas llegás.
              </dd>
            </div>
          </dl>
        </div>
      </section>

      <%!-- Juntadas + Contacto (Claude's discretion per D-02, flagged for
      review) — the #juntadas and #contacto anchor targets the footer's
      remaining two links resolve to. Every clause traces back to the FAQ
      answers above or to ClubLinks; no invented facts, no contact form. --%>
      <section class="pk-band">
        <div class="pk-band-inner pk-gutter grid gap-11 sm:grid-cols-2">
          <div id="juntadas">
            <h2 class="font-display text-2xl">Juntadas</h2>
            <p class="text-lg">
              Nos juntamos los sábados en el Club de Emprendedores, San Salvador de Jujuy. Los juegos los llevamos nosotros; vos traé las ganas.
            </p>
          </div>
          <div id="contacto" class="pk-about-contact-card">
            <h2 class="font-display text-2xl">Contacto</h2>
            <p class="text-lg">
              Escribinos por el grupo de WhatsApp o por Instagram — respondemos ahí mismo.
            </p>
            <Layouts.social_links
              class="pk-about-contact-links"
              icons={[:whatsapp, :instagram]}
              labels
            />
            <a
              href={ClubLinks.maps_url()}
              target="_blank"
              rel="noopener noreferrer"
              class="pk-about-map-thumb"
            >
              <img
                src={~p"/images/about-maps-thumb.jpg"}
                alt="Ubicación del club en Google Maps — Club de Emprendedores, San Salvador de Jujuy"
              />
              <span class="pk-about-map-label">
                Club de Emprendedores, San Salvador de Jujuy — Cómo llegar ↗
              </span>
            </a>
          </div>
        </div>
      </section>

      <%!-- Closing CTA band. The design source's meta line links to a
      link-aggregator site via ClubLinks.linktree_url/0 — that function no
      longer exists: the developer explicitly removed the link-aggregator
      channel site-wide during plan 01.1-01's footer revision ("remove it,
      the channel is no longer rendered anywhere" — see ClubLinks'
      moduledoc). Re-adding a link to a function that doesn't exist would
      either fail to compile or require inventing a dead URL, so the
      trailing link instead points at Instagram (still a real, live
      channel) — same required "Pukllay Club · San Salvador de Jujuy,
      Argentina ·" prefix, honest destination. Flagged for developer
      review. --%>
      <section class="pk-band">
        <div class="pk-band-inner pk-gutter text-center">
          <h2 class="font-display text-2xl">Nos vemos el sábado</h2>
          <div class="flex flex-wrap justify-center gap-3">
            <a
              href={ClubLinks.whatsapp_group_url()}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-primary min-h-11"
            >
              Grupo de WhatsApp
            </a>
            <a
              href={ClubLinks.instagram_url()}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-outline btn-primary min-h-11"
            >
              Instagram
            </a>
          </div>
          <p class="pk-about-eyebrow">
            Pukllay Club · San Salvador de Jujuy, Argentina ·
            <a href={ClubLinks.instagram_url()} target="_blank" rel="noopener noreferrer">Instagram</a>
          </p>
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
