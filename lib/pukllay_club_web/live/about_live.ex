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
        <section
          id="about-hero"
          data-morph-armed
          class="space-y-3 pt-2 pb-12 text-center"
          phx-hook=".AboutHeaderMorph"
        >
          <script :type={Phoenix.LiveView.ColocatedHook} name=".AboutHeaderMorph">
            export default {
              mounted() {
                try {
                  this.header = document.getElementById("app-header")
                  this.anchor = this.el.querySelector("[data-morph-anchor]")
                  this.mark = document.getElementById("pk-about-morph-mark")
                  if (!this.header || !this.anchor || !this.mark) {
                    this.el.removeAttribute("data-morph-armed")
                    return
                  }

                  // T-01.4-20: removes the no-JS <noscript><div id="pk-no-
                  // js-marker"> escape hatch now that this hook has proven
                  // it can actually run — this is the mechanism that makes
                  // the marker's CSS override (app.css) JS-conditional. A
                  // parser-level trick alone (the marker being discarded by
                  // the HTML parser while scripting is enabled) does NOT
                  // survive LiveView's own connect-time DOM reconciliation
                  // (live-verified via CDP: the marker reappeared after
                  // connect even with JS running) — this explicit removal,
                  // which runs strictly after that reconciliation has
                  // settled (mounted() cannot fire any earlier), is what
                  // actually ties the override to "JS is running", not the
                  // parsing quirk by itself.
                  document.getElementById("pk-no-js-marker")?.remove()

                  // S1 fix (G-01.4-1): the header-hidden state is now
                  // SERVER-rendered — the `data-morph-armed` marker on this
                  // section plus the `body:has(...)` rule in app.css hide
                  // #app-header with `visibility: hidden` and no transition
                  // before a single line of this hook has run, so there is
                  // no solid-header-then-fade-out blink. This hook no longer
                  // applies (or removes) any class to hide the header — it
                  // only handles the DOCKED reveal (is-docked, below) and
                  // teardown. A hook that fails to wire (this guard, or the
                  // catch block below) hands the header back by removing the
                  // marker, rather than leaving it permanently invisible.
                  // WR-02: `visibility: hidden` already removes the header
                  // from the tab order and the a11y tree from first paint
                  // (stronger than the old opacity+pointer-events pair,
                  // which left it reachable until this hook ran). `inert` is
                  // kept here as defence in depth, mirroring this file's own
                  // established a11y mechanism (see layouts.ex's drawer/
                  // cat-menu: "inert is the closed state's a11y mechanism").
                  // Removed below once first-paint determines the header is
                  // already docked (visible), and re-toggled in
                  // syncPosition() on every dock-state flip.
                  this.header.setAttribute("inert", "")

                  this.docked = false
                  // Mirrors .AboutCarousel's own reduced-motion guard in this
                  // same file. Only the decorative entrance (delay + glow) is
                  // ever skipped for it — scroll tracking and the crossing-
                  // point dock always run regardless. Reduced motion also
                  // collapses this.frame()'s own transform interpolation to
                  // a single instant step (see below).
                  this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)")

                  // Read once, from the design token, rather than a
                  // hard-coded millisecond literal — this is the SAME
                  // duration the stylesheet's own eased transitions use (the
                  // header reveal, the entrance), so the JS-driven transform
                  // and the CSS-driven transitions read as one motion
                  // system. 280 (the token's own literal value) is used only
                  // if the custom property fails to parse.
                  const durationRaw = parseFloat(
                    getComputedStyle(document.documentElement).getPropertyValue("--duration-slow")
                  )
                  this.duration = Number.isFinite(durationRaw) ? durationRaw : 280

                  // cubic-bezier(0.4, 0, 0.2, 1) — the EXACT control points
                  // of --ease-standard (app.css), so this hook's per-frame
                  // transform interpolation and the stylesheet's own eased
                  // transitions share one motion curve. Not a hand-rolled
                  // approximation: this codebase has three recorded
                  // incidents (see the About morph CSS block's own
                  // --ease-standard-vs-amplitude comments) of a motion curve
                  // chosen by feel and later measured wrong. Bisects on the
                  // X component (which uses the curve's own 0.4/0.2 control
                  // values) to invert the curve, then evaluates Y (which
                  // uses the curve's fixed 0/1 start/end control values) at
                  // the solved parameter.
                  const bezierComponent = (t, p1, p2) => {
                    const inv = 1 - t
                    return 3 * inv * inv * t * p1 + 3 * inv * t * t * p2 + t * t * t
                  }
                  this.ease = (x) => {
                    if (x <= 0) return 0
                    if (x >= 1) return 1
                    let lo = 0
                    let hi = 1
                    let t = x
                    for (let i = 0; i < 20; i++) {
                      t = (lo + hi) / 2
                      if (bezierComponent(t, 0.4, 0.2) > x) {
                        hi = t
                      } else {
                        lo = t
                      }
                    }
                    return bezierComponent(t, 0, 1)
                  }

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
                  // one that actually has layout size (CR-01). Returns null
                  // — not a zero-height fallback rect — when neither mark
                  // has laid out yet: a zero-height dock rect would scale
                  // the floating mark to nothing, the "shrink-to-zero"
                  // symptom the UAT truth explicitly forbids.
                  this.dockRect = () => {
                    const marks = this.header.querySelectorAll(".pk-brand-mark")
                    for (const mark of marks) {
                      const rect = mark.getBoundingClientRect()
                      if (rect.width > 0 && rect.height > 0) return rect
                    }
                    return null
                  }

                  // Writes the mark's position AND size as one `transform`,
                  // never top/left/width/height — those are layout-inducing,
                  // cannot be composited, and were the root cause of the
                  // scroll-tracking jank this replaces. The untransformed
                  // layout size is read via offsetWidth/offsetHeight, never
                  // getBoundingClientRect(), which would include the
                  // transform this function itself just wrote and compound
                  // every frame. transform-origin: 0 0 (app.css) means the
                  // box's own top-left corner lands exactly at (x, y)
                  // regardless of scale, which is what lets one
                  // translate3d + scale pair land the box correctly at both
                  // ends of the move.
                  this.write = (natural, dock) => {
                    const markWidth = this.mark.offsetWidth
                    const markHeight = this.mark.offsetHeight
                    const restX = natural.left + (natural.width - markWidth) / 2
                    const restY = natural.top
                    const dockScale = dock.height / markHeight
                    const x = restX + (dock.left - restX) * this.progress
                    const y = restY + (dock.top - restY) * this.progress
                    const scale = 1 + (dockScale - 1) * this.progress
                    this.mark.style.transform = `translate3d(${x}px, ${y}px, 0) scale(${scale})`
                  }

                  // The single per-frame driver, replacing syncPosition()/
                  // onScroll(). Re-reads BOTH the anchor rect and the dock
                  // rect every time it runs, so a scroll mid-move retargets
                  // the interpolation continuously instead of leaving a
                  // stale destination — this is what makes the undock
                  // reverse cleanly instead of surviving one frame and then
                  // hard-snapping the rest.
                  this.frame = () => {
                    this.rafId = null
                    const natural = this.naturalRect()
                    const dock = this.dockRect()
                    if (!dock) {
                      // Brand mark hasn't laid out yet — a self-terminating
                      // poll: try again next frame, write nothing this one.
                      this.schedule()
                      return
                    }

                    const shouldDock = natural.top <= dock.top
                    if (shouldDock !== this.docked) {
                      this.docked = shouldDock
                      this.header.classList.toggle("is-docked", this.docked)
                      this.header.toggleAttribute("inert", !this.docked)
                      this.from = this.progress
                      this.to = this.docked ? 1 : 0
                      this.startedAt = performance.now()
                    }

                    if (this.progress !== this.to) {
                      // Under reduced motion the state change is instant —
                      // treat elapsed as already complete.
                      const raw = this.reducedMotion.matches
                        ? 1
                        : Math.min((performance.now() - this.startedAt) / this.duration, 1)
                      this.progress =
                        raw >= 1 ? this.to : this.from + (this.to - this.from) * this.ease(raw)
                    }

                    this.write(natural, dock)

                    if (this.progress !== this.to) this.schedule()
                  }

                  // Requests a frame only when none is already pending, so a
                  // burst of scroll events still costs exactly one frame.
                  this.rafId = null
                  this.schedule = () => {
                    if (this.rafId != null) return
                    this.rafId = requestAnimationFrame(this.frame)
                  }

                  // Tracking is live from mount — never gated behind the
                  // entrance timer (the S3(c) fix: the old guard dropped
                  // every scroll event during the 500ms entrance window,
                  // leaving the mark stale until the next tick teleported
                  // it). Registered directly as the listener: every scroll/
                  // resize event just asks for a frame. Both naturalRect()
                  // and dockRect() are viewport-relative, and the header's
                  // own height is republished by .CatalogNav's
                  // ResizeObserver, so a resize invalidates both the same
                  // way a scroll does — no separate resize-only logic is
                  // needed. D-01: no viewport-width branch anywhere in this
                  // hook — this listener reacts to the geometry a resize
                  // changed, it never reads the new width itself.
                  window.addEventListener("scroll", this.schedule, {passive: true})
                  window.addEventListener("resize", this.schedule)

                  // D-02 first paint: the SAME rect comparison this.frame()
                  // uses on every scroll frame, computed once here BEFORE
                  // starting the entrance timer — never a route/fragment/
                  // server check. A visitor landing below the crossing
                  // point (e.g. a #contacto deep link from the footer) sees
                  // the header already docked, with no jump and no replayed
                  // entrance. A null dock rect is treated as not-docked —
                  // there is nothing yet to compare against.
                  const natural0 = this.naturalRect()
                  const dock0 = this.dockRect()
                  this.docked = dock0 ? natural0.top <= dock0.top : false
                  this.progress = this.docked ? 1 : 0
                  this.from = this.progress
                  this.to = this.progress
                  this.header.classList.toggle("is-docked", this.docked)
                  this.header.toggleAttribute("inert", !this.docked)
                  // Writes the mark's transform immediately, at whichever
                  // state first paint resolved to.
                  this.frame()

                  // Entrance is a LOAD TIMER, never scroll-triggered, and it
                  // no longer sets any position-related flag — position is
                  // owned entirely by this.frame()/this.write() now. Fires
                  // immediately when the page opens already docked or under
                  // reduced motion (no decorative delay/glow to replay), and
                  // under reduced motion the delay itself is skipped too,
                  // not just the glow.
                  const startEntrance = () => {
                    this.mark.classList.add("is-entered")
                    if (!this.reducedMotion.matches) this.mark.classList.add("is-first-play")
                  }
                  if (this.docked || this.reducedMotion.matches) {
                    startEntrance()
                  } else {
                    this.entranceTimer = setTimeout(startEntrance, 500)
                  }
                } catch (e) {
                  this.el.removeAttribute("data-morph-armed")
                  console.error("AboutHeaderMorph: mount block failed to wire", e)
                }
              },
              destroyed() {
                try {
                  clearTimeout(this.entranceTimer)
                  if (this.rafId != null) cancelAnimationFrame(this.rafId)
                  window.removeEventListener("scroll", this.schedule)
                  window.removeEventListener("resize", this.schedule)
                  // The header-hidden state now un-applies BY ITSELF: it is
                  // driven by `body:has(#about-hero[data-morph-armed])`, and
                  // `#about-hero` leaves the DOM on navigation away from
                  // About, so the `:has()` guard simply stops matching —
                  // there is no hiding class left over here to clean up
                  // (S1 fix, G-01.4-1). `is-docked` and `inert` are still
                  // this hook's own state on a shared element, so those
                  // still need explicit teardown.
                  this.header?.classList.remove("is-docked")
                  this.header?.removeAttribute("inert")
                } catch (e) {
                  console.error("AboutHeaderMorph: destroy block failed to wire", e)
                }
              }
            }
          </script>
          <%!-- mb-0 is not a spacing tier — the tier now lives in
          --pk-about-mark-clear (app.css). It exists solely to neutralize
          the parent's `space-y-3`, which compiles under Tailwind v4 to a
          zero-specificity `:where(& > :not(:last-child))
          { margin-block-end: .75rem }` and would otherwise stack 12px on
          top of the declared clearance (G-01.4-3). --%>
          <div data-morph-anchor class="pk-about-mark-anchor mb-0" aria-hidden="true"></div>
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
              <%!-- Two caption variants (G-01.4-2 gap closure, sketch 048's own
              short/long strings, same hero-tagline precedent above): the
              short one below lg, the long one at/above lg. lg (1024px), NOT
              sm, is load-bearing — the parent's sm:grid-cols-2 halves this
              card at exactly 640px, and the long caption is worst (3 wrapped
              lines) in the 640-767px band, not at 375px. See
              .planning/debug/G-01.4-2-map-thumb-coverage.md. --%>
              <span class="pk-about-map-label lg:hidden">Cómo llegar ↗</span>
              <span class="pk-about-map-label hidden lg:block">
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
        <div class="pk-about-morph-mark-inner">
          <img src={~p"/images/isologo-light.png"} class="dark:hidden" alt="" />
          <img src={~p"/images/isologo-dark.png"} class="hidden dark:block" alt="" />
        </div>
      </div>

      <%!-- No-JS escape hatch (S1 fix, G-01.4-1, T-01.4-20): the header-hidden
      state above is now unconditional server-rendered CSS, so a visitor with
      scripting disabled or failed would otherwise get a page with NO header
      at all — strictly worse than the blink being fixed.

      Two live-verified-via-CDP findings shaped this (neither is something
      ExUnit can catch):

      1. A `<style>` placed DIRECTLY inside `<noscript>` does NOT work as a
         JS-conditional override: per the HTML parsing spec, `<noscript>`
         redirects to the SAME restricted child allowlist (base/link/meta/
         noframes/style) used in `<head>`, regardless of whether scripting
         is enabled — so that style becomes an ALWAYS-ACTIVE stylesheet and
         would have permanently defeated the header-hidden rule in every
         browser, JS or not (confirmed: document.styleSheets grew by one,
         and the rule showed up as matched/origin:"regular" against a live
         #app-header with a real LiveSocket connection running).

      2. A bare element NOT on that allowlist (this <div>) IS correctly
         discarded by the parser on a plain static HTML parse with
         scripting enabled (confirmed against this exact markup served as
         a static file: getElementById returns null with JS on, non-null
         with JS off) — but that discard does NOT survive LiveView's own
         connect-time DOM reconciliation: on the real running page, the
         marker reappeared in the DOM after the LiveSocket connected, even
         though app.js clearly executed. The CSS rule this marker drives
         (app.css) is therefore only half the mechanism — see the explicit
         `document.getElementById("pk-no-js-marker")?.remove()` call in
         the hook below, which is what actually makes this JS-conditional
         end to end on THIS app: it fires only once the hook has proven it
         can run, after any connect-time reconciliation has settled.

      A sibling of the mark above, deliberately NOT inside #about-hero —
      space-y-3 counts every rendered child, and an extra one there would
      silently add 12px above the mark (S2 fix). --%>
      <noscript>
        <div id="pk-no-js-marker" data-no-js aria-hidden="true"></div>
      </noscript>
    </Layouts.app>
    """
  end
end
