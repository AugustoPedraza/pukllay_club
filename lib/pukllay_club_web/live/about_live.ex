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
        <%!-- Isologo scroll-morph (sketch 045, D-01/D-02/D-03/D-10): page-owned
        second colocated hook in this file (alongside .AboutCarousel below),
        mounted on the hero section as a STATIC phx-hook string literal —
        layouts.ex:205-215 documents why a dynamic expression here would fail
        at runtime with an unqualified hook name. Reaches OUTSIDE its own
        root to #app-header (the same cross-root pattern .CatalogNav already
        establishes, layouts.ex ~line 295) to hide the header at rest and
        dock the floating mark into its brand slot at the crossing point —
        never by adding hook wiring into header_inner/1 or .CatalogNav
        itself, which is what keeps this About-only per D-10. --%>
        <section id="about-hero" class="space-y-3 py-12 text-center" phx-hook=".AboutHeaderMorph">
          <script :type={Phoenix.LiveView.ColocatedHook} name=".AboutHeaderMorph">
            export default {
              mounted() {
                try {
                  this.header = document.getElementById("app-header")
                  this.anchor = this.el.querySelector("[data-morph-anchor]")
                  this.mark = document.getElementById("pk-about-morph-mark")
                  if (!this.header || !this.anchor || !this.mark) return

                  // Hidden from first paint, not flashed visible then hidden.
                  this.header.classList.add("pk-header-about-morph")
                  // WR-02: opacity:0/pointer-events:none (the CSS this class
                  // triggers) removes the header visually and from mouse
                  // interaction, but NOT from the tab order or a11y tree —
                  // a keyboard/screen-reader user could still reach the
                  // hamburger and nav_links while the header is invisible.
                  // `inert` is this file's own established mechanism for
                  // pairing a visual-hidden state with real a11y removal
                  // (see layouts.ex's drawer/cat-menu: "inert is the closed
                  // state's a11y mechanism"). Removed below once first-paint
                  // determines the header is already docked (visible), and
                  // re-toggled in syncPosition() on every dock-state flip.
                  this.header.setAttribute("inert", "")

                  this.docked = false
                  this.entered = false
                  // Mirrors .AboutCarousel's own reduced-motion guard in this
                  // same file. Only the decorative entrance (delay + glow) is
                  // ever skipped for it — scroll tracking and the crossing-
                  // point dock always run regardless.
                  this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)")

                  // Verbatim anchor rect — no derived arithmetic. The anchor
                  // is ordinary in-flow content, so this already tracks
                  // scroll 1:1 with zero extra machinery.
                  this.naturalRect = () => this.anchor.getBoundingClientRect()

                  // The real element's rect, not a copied/forced square —
                  // the isologo is 939x1034/939x1035, not square (RESEARCH.md
                  // Pitfall 4). An opacity:0 element still reports a real
                  // rect, so suppressing the header's own mark below does
                  // not break this. brand_logo/1 renders TWO `.pk-brand-mark`
                  // images (light/dark theme), toggled via the `dark:`
                  // variant's `display: none` — querySelector() alone always
                  // returns the first (light-theme) one regardless of theme,
                  // which zeroes out in dark theme. Walk both and return the
                  // one that actually has layout size (CR-01).
                  this.dockRect = () => {
                    const marks = this.header.querySelectorAll(".pk-brand-mark")
                    for (const mark of marks) {
                      const rect = mark.getBoundingClientRect()
                      if (rect.width > 0 && rect.height > 0) return rect
                    }
                    // Fallback: neither mark has a size yet (e.g. not yet laid out).
                    return marks[0]?.getBoundingClientRect()
                  }

                  // When animate is false: force an instant, untransitioned
                  // jump (add no-anim, write the rect, force a reflow via
                  // offsetWidth, then remove no-anim) — otherwise every
                  // tracking frame animates and the mark lags the page
                  // instead of riding it pixel for pixel.
                  this.place = (rect, animate) => {
                    if (!animate) this.mark.classList.add("no-anim")
                    this.mark.style.top = rect.top + "px"
                    this.mark.style.left = rect.left + "px"
                    this.mark.style.width = rect.width + "px"
                    this.mark.style.height = rect.height + "px"
                    if (!animate) {
                      void this.mark.offsetWidth
                      this.mark.classList.remove("no-anim")
                    }
                  }

                  // The ONE eased move, in both directions, happens only on
                  // an actual state flip. Live 1:1 tracking (no transition)
                  // continues every frame while not docked and unchanged;
                  // once docked and unchanged, this is a no-op.
                  this.syncPosition = () => {
                    const natural = this.naturalRect()
                    const dock = this.dockRect()
                    const shouldDock = natural.top <= dock.top
                    if (shouldDock !== this.docked) {
                      this.docked = shouldDock
                      this.header.classList.toggle("is-docked", this.docked)
                      this.header.toggleAttribute("inert", !this.docked)
                      this.place(this.docked ? dock : natural, true)
                    } else if (!this.docked) {
                      this.place(natural, false)
                    }
                  }

                  this.ticking = false
                  this.onScroll = () => {
                    if (!this.entered || this.ticking) return
                    this.ticking = true
                    requestAnimationFrame(() => {
                      this.syncPosition()
                      this.ticking = false
                    })
                  }
                  window.addEventListener("scroll", this.onScroll, {passive: true})

                  // D-02 first paint: the SAME rect comparison syncPosition()
                  // uses on every scroll frame, run once here BEFORE starting
                  // the entrance timer — never a route/fragment/server check.
                  // A visitor landing below the crossing point (e.g. a
                  // #contacto deep link from the footer) sees the header
                  // already docked, with no jump and no replayed entrance.
                  const natural0 = this.naturalRect()
                  const dock0 = this.dockRect()
                  this.docked = natural0.top <= dock0.top

                  if (this.docked) {
                    this.header.classList.add("is-docked")
                    this.header.removeAttribute("inert")
                    this.place(dock0, false)
                    this.mark.classList.add("is-entered")
                    this.entered = true
                  } else {
                    this.place(natural0, false)
                    const startEntrance = () => {
                      this.mark.classList.add("is-entered")
                      // The glow is decorative, dropped under reduced motion;
                      // the entrance itself (is-entered) still applies so the
                      // mark becomes visible either way.
                      if (!this.reducedMotion.matches) this.mark.classList.add("is-first-play")
                      this.entered = true
                    }
                    // Entrance is a LOAD TIMER, never scroll-triggered — under
                    // reduced motion the delay itself is skipped too, not
                    // just the glow.
                    if (this.reducedMotion.matches) {
                      startEntrance()
                    } else {
                      this.entranceTimer = setTimeout(startEntrance, 500)
                    }
                  }

                  // Both naturalRect() and dockRect() are viewport-relative,
                  // and the header's own height is republished by
                  // .CatalogNav's ResizeObserver — a resize invalidates both.
                  // No animation on a resize snap, and syncPosition() after
                  // it so a resize that crosses the threshold settles into
                  // the right state. D-01: no viewport-width branch anywhere
                  // in this hook — this listener reacts to the geometry a
                  // resize changed, it never reads the new width itself.
                  this.onResize = () => {
                    this.place(this.docked ? this.dockRect() : this.naturalRect(), false)
                    this.syncPosition()
                  }
                  window.addEventListener("resize", this.onResize)
                } catch (e) {
                  console.error("AboutHeaderMorph: mount block failed to wire", e)
                }
              },
              destroyed() {
                try {
                  clearTimeout(this.entranceTimer)
                  window.removeEventListener("scroll", this.onScroll)
                  window.removeEventListener("resize", this.onResize)
                  // #app-header is rendered by the shared layout and survives
                  // LiveView navigation — state this hook adds must be state
                  // this hook removes, or every subsequent page inherits a
                  // permanently hidden header.
                  this.header?.classList.remove("pk-header-about-morph", "is-docked")
                  this.header?.removeAttribute("inert")
                } catch (e) {
                  console.error("AboutHeaderMorph: destroy block failed to wire", e)
                }
              }
            }
          </script>
          <div data-morph-anchor class="pk-about-mark-anchor" aria-hidden="true"></div>
          <p class="font-sans text-xs uppercase tracking-widest text-neutral">
            Club de juegos de mesa · Jujuy
          </p>
          <h1 class="font-display pk-about-h1">Conectá jugando</h1>
          <%!-- Mobile hero tagline split (sketch 046, RESEARCH.md Pitfall 6):
          the "Volvé a jugar..." copy is a MOBILE-only replacement — desktop
          keeps the original saturday-focused line (assumption A1). Tailwind's
          default sm (640px) breakpoint, NOT the hand-picked 480px @media
          block that governs .pk-about-cta-bar — unrelated mechanisms. --%>
          <p class="font-sans text-base text-neutral sm:hidden">
            Volvé a jugar. Volvé a encontrarte.
          </p>
          <p class="hidden font-sans text-base text-neutral sm:block">
            Nos juntamos todos los sábados a jugar. Venís, te sentás, alguien te explica.
          </p>
          <div class="flex justify-center">
            <Layouts.sumate_cta />
          </div>
        </section>
      </div>

      <%!-- Five-slide photo rail of real club photography (sketch 046, D-08,
      D-09) — the "no real club photography exists yet" placeholder flag
      carried since D-07/D-12 is retired. Every slide crops to fill its
      frame (object-fit: cover, D-08) — explicitly NOT .pk-poster-img's
      letterbox/contain treatment, which exists for official box art where
      cropping the artwork would be wrong. Hand-rolled colocated hook, same
      pattern as CarouselRow's .CarouselScroll — deliberately no scroll-
      observer-driven visibility API anywhere here (01.1-RESEARCH.md Pitfall
      3: that class of API throttles in a backgrounded tab, which would
      leave the design source's own fade-in stuck at opacity 0; that reveal
      is deliberately not reproduced, D-08 scopes it reference-only). --%>
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

                  // The rail can't scroll past its content edge, so the last
                  // slide's exact index*advance target routinely overshoots
                  // the real max scrollLeft once the slide count grows
                  // (found live during plan 01.4-04 Task 3 with 5 slides —
                  // the browser clamps the scroll and the last dot never
                  // highlights). Route the last index through the rail's own
                  // max scroll distance instead of the uniform formula.
                  this.maxScrollLeft = () => this.rail.scrollWidth - this.rail.clientWidth

                  this.goTo = (index) => {
                    const target = index === this.slideCount - 1
                      ? this.maxScrollLeft()
                      : index * this.slideAdvance()
                    this.rail.scrollTo({left: target, behavior: "smooth"})
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
                    const max = this.maxScrollLeft()
                    let index
                    if (max > 0 && this.rail.scrollLeft >= max - 1) {
                      index = this.slideCount - 1
                    } else {
                      const raw = Math.round(this.rail.scrollLeft / advance)
                      index = Math.min(Math.max(raw, 0), this.slideCount - 1)
                    }
                    if (index !== this.index) this.setActive(index)
                  }
                  this.rail.addEventListener("scroll", this.onScroll, {passive: true})

                  // WR-01: touch devices fire pointerdown on every swipe/dot
                  // tap but never fire mouseenter/mouseleave, so on
                  // mouse-only reset (the old mouseleave-only logic) a touch
                  // interaction paused autoplay permanently for the rest of
                  // the page's life. A short idle-resume timer gives touch
                  // users the same "comes back after you stop interacting"
                  // behavior mouse users already get from mouseleave, without
                  // changing the mouse-driven UX at all (mouseleave still
                  // resumes immediately, and clears the pending timer so it
                  // doesn't double-fire).
                  this.resumeTimer = null
                  this.onPointerDown = () => {
                    this.paused = true
                    clearTimeout(this.resumeTimer)
                    this.resumeTimer = setTimeout(() => { this.paused = false }, 6000)
                  }
                  this.onMouseEnter = () => {
                    this.paused = true
                    clearTimeout(this.resumeTimer)
                  }
                  this.onMouseLeave = () => {
                    this.paused = false
                    clearTimeout(this.resumeTimer)
                  }
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
                  clearTimeout(this.resumeTimer)
                  this.el.removeEventListener("click", this.onClick)
                  this.rail?.removeEventListener("scroll", this.onScroll)
                  this.rail?.removeEventListener("pointerdown", this.onPointerDown)
                  this.rail?.removeEventListener("mouseenter", this.onMouseEnter)
                  this.rail?.removeEventListener("mouseleave", this.onMouseLeave)
                }
              }
            </script>
            <div data-rail class="pk-about-rail">
              <figure class="pk-about-slide" data-slide="juego">
                <div class="pk-about-slide-ph">
                  <img
                    src={~p"/images/about-juego.jpg"}
                    alt="Un juego de mesa en pleno desarrollo, sobre una de las mesas del club"
                  />
                </div>
              </figure>
              <figure class="pk-about-slide" data-slide="explicacion">
                <div class="pk-about-slide-ph">
                  <img
                    src={~p"/images/about-explicacion.jpg"}
                    alt="Un integrante del club explicando las reglas de un juego a la mesa"
                  />
                </div>
              </figure>
              <figure class="pk-about-slide" data-slide="ludoteca">
                <div class="pk-about-slide-ph">
                  <img
                    src={~p"/images/about-ludoteca.jpg"}
                    alt="Parte de la colección de juegos de mesa del club, la ludoteca"
                  />
                </div>
              </figure>
              <figure class="pk-about-slide" data-slide="comunidad">
                <div class="pk-about-slide-ph">
                  <img
                    src={~p"/images/about-comunidad.jpg"}
                    alt="La comunidad del club reunida durante una juntada"
                  />
                </div>
              </figure>
              <figure class="pk-about-slide" data-slide="festejo">
                <div class="pk-about-slide-ph">
                  <img
                    src={~p"/images/about-festejo.jpg"}
                    alt="Festejo del aniversario del club con todo el equipo reunido"
                  />
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
              <button
                type="button"
                data-goto="4"
                aria-label="Foto 5"
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
      review.

      Sketch 049: the button pair that used to sit above this meta line
      (Grupo de WhatsApp + Instagram) was removed — by the time a reader
      scrolls this far they've already seen both links in the rebuilt
      Contacto card directly above, and repeating them a third time (after
      the hero and the mobile sticky bar) was the rhythm-killer 049
      flagged. The band now reuses the shared sumate_cta/1 component
      instead, matching the hero's exact call shape. --%>
      <section id="cierre" class="pk-band">
        <div class="pk-band-inner pk-gutter text-center">
          <h2 class="font-display text-2xl">Nos vemos el sábado</h2>
          <div class="flex justify-center">
            <Layouts.sumate_cta />
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

      <%!-- Sketch 045 isologo scroll-morph mark: the SINGLE positioned
      floating element .AboutHeaderMorph (mounted on the hero section above)
      places and animates. Its two <img> children are one theme pair —
      identical dark:hidden/hidden dark:block classes to brand_logo/1's own
      pair, so CSS (not JS) picks the visible one — never two marks;
      RESEARCH.md documents a real bug where one <img> per theme variant
      produced a stray fragment and overlapping glow animations. Position,
      size and visibility are owned entirely by the hook via inline style +
      state classes — no Tailwind utility on this markup may also touch
      those properties (Pitfall 2: an unlayered .pk-* rule always wins that
      fight silently, and a utility that "does nothing" is a debugging
      trap). --%>
      <div id="pk-about-morph-mark" class="pk-about-morph-mark" aria-hidden="true">
        <img src={~p"/images/isologo-light.png"} class="dark:hidden" alt="" />
        <img src={~p"/images/isologo-dark.png"} class="hidden dark:block" alt="" />
      </div>
    </Layouts.app>
    """
  end
end
