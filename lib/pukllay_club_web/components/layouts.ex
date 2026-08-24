defmodule PukllayClubWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PukllayClubWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  # The brand isologo (Andean llama + hexagon + meeple silhouette per the brand manual) is a
  # theme-aware pair: the dark-purple mark for light theme, the white mark for dark theme,
  # toggled by the app's `dark:` custom variant (assets/css/app.css). Gate on both files
  # existing at compile time — if either is missing the component degrades to the wordmark +
  # tagline lockup with no <img> at all, never a half-rendered pair.
  @isologo_light_path "priv/static/images/isologo-light.png"
  @isologo_dark_path "priv/static/images/isologo-dark.png"
  @external_resource @isologo_light_path
  @external_resource @isologo_dark_path
  @isologo? File.exists?(@isologo_light_path) and File.exists?(@isologo_dark_path)

  @doc """
  Renders the PUKLLAY CLUB horizontal logo lockup (isologo + wordmark + tagline).

  Renders a theme-aware isologo pair — the dark-purple mark for light theme, the white mark for
  dark theme, toggled by the `dark:` custom variant — when both
  `priv/static/images/isologo-light.png` and `isologo-dark.png` exist at compile time, and
  degrades to the wordmark + tagline lockup with no `<img>` at all when either is missing.

  The second-line tagline is overridable via the `tagline` attr — the header uses the default,
  the footer overrides it with the About page's hero tagline so the two clusters don't repeat
  the same copy (260821-umm).

  **The mark is the header's (D-A, 260823-snj).** `brand_logo/1` renders on both the header and
  the footer, and rendering the isologo pair unconditionally on both doubled the brand identity
  on every page. The `mark` attr (default `true`) selects between the two: the header keeps the
  default and renders the full pair, the footer passes `mark={false}` and renders the wordmark +
  tagline lockup only, demoted to the muted colour tier via the `pk-brand-quiet` class (D-B).
  """
  attr :tagline, :string, default: "JUEGOS DE MESA MODERNOS"

  attr :mark, :boolean,
    default: true,
    doc:
      "when false, renders the wordmark + tagline lockup with no isologo <img> at all, and " <>
        "demotes the wordmark to the muted colour tier via pk-brand-quiet. The footer is the " <>
        "one call site that passes false (D-A) — the header keeps the true default."

  # `isologo?` is deliberately not a declared `attr` — it's a test-only seam. No production call
  # site ever passes it, so `assign_new/3` always falls through to the compile-time `@isologo?`
  # constant in production, keeping behaviour byte-identical to a plain `assign/3`. This lets a
  # test force the wordmark-only fallback branch via `render_component(&brand_logo/1,
  # %{isologo?: false})`, which a compile-time constant alone would make unreachable on a
  # machine where both marks exist on disk.
  def brand_logo(assigns) do
    assigns = assign_new(assigns, :isologo?, fn -> @isologo? end)

    ~H"""
    <a
      href="/"
      class={["flex-initial flex w-fit items-center gap-2 min-h-11", !@mark && "pk-brand-quiet"]}
    >
      <img
        :if={@isologo? and @mark}
        src={~p"/images/isologo-light.png"}
        width="36"
        alt=""
        class="dark:hidden"
      />
      <img
        :if={@isologo? and @mark}
        src={~p"/images/isologo-dark.png"}
        width="36"
        alt=""
        class="hidden dark:block"
      />
      <span class="pk-brand-wordmark flex flex-col leading-none">
        <span class="pk-brand-name font-display text-2xl uppercase tracking-wide">
          PUKLLAY CLUB
        </span>
        <span class="font-sans text-xs uppercase tracking-widest text-neutral">
          {@tagline}
        </span>
      </span>
    </a>
    """
  end

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :fullbleed, :boolean,
    default: false,
    doc:
      "when true, the header uses the shared pk-gutter token instead of its own padding and " <>
        "<main> drops its horizontal padding, so a page whose content must reach the viewport " <>
        "edge (full-bleed carousel shelves) can opt out of the layout's gutter without " <>
        "stripping padding from pages that rely on it"

  attr :sticky, :boolean,
    default: false,
    doc:
      "when true, wraps the header in a position: sticky shell that tints flat-translucent past " <>
        "a 40px scroll threshold (the .CatalogNav hook), and enables the nav_links/nav_search/" <>
        "subnav slots. false renders no hook attribute at all — the non-sticky path is byte-" <>
        "compatible with pages that don't opt in."

  attr :search_expanded, :boolean,
    default: false,
    doc:
      "when true, the search-morph opens on mount (e.g. a catalog URL carrying ?q=) instead of " <>
        "resting as a 44px icon. syncMorph() in .CatalogNav reads this via data-search-expanded " <>
        "and only ever opens, never closes, so a server round-trip can never yank an open box shut."

  attr :active_nav, :atom,
    default: nil,
    doc:
      "which top-level nav entry is current — :inicio, :quienes_somos, or nil for a drill-down " <>
        "page that is neither. Drives the mobile drawer's own aria-current-based active row " <>
        "(the drawer's link list is shell-owned, not slot-owned, so Detalle — which passes no " <>
        "nav_links slot — still gets a real menu)."

  slot :nav_links, doc: "shelf anchor links, rendered between the brand and the search box"
  slot :nav_search, doc: "the search form, rendered inside the header aligned with row content"
  slot :crumb, doc: "breadcrumb content for a genuine drill-down page (Detalle only)"

  slot :subnav,
    doc: "content rendered below the header row, inside the sticky wrapper (e.g. mobile chips)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%!--
    Two separate wrapper elements, not one with a dynamic phx-hook expression:
    Phoenix only qualifies a colocated hook's leading-dot name (".CatalogNav"
    -> "PukllayClubWeb.Layouts.CatalogNav") when phx-hook is a static string
    literal in the template. A dynamic expression like `@sticky && ".CatalogNav"`
    is never rewritten, so the browser receives the bare, unqualified
    ".CatalogNav" and fails with "unknown hook found for ..." at runtime.
    --%>
    <div :if={@sticky} id="app-header" class="pk-header pk-header-sticky" phx-hook=".CatalogNav">
      <script :type={Phoenix.LiveView.ColocatedHook} name=".CatalogNav">
        export default {
          mounted() {
            this.nav = this.el.querySelector(".pk-nav")

            this.onScroll = () => {
              this.nav.classList.toggle("is-scrolled", window.scrollY > 40)
            }
            window.addEventListener("scroll", this.onScroll, {passive: true})
            this.onScroll()

            // Chip scroll-spy: highlights the chip whose shelf is currently
            // under the header. Guarded on there being at least one chip and
            // one resolvable target section so the detail page and filtered
            // views (which render no chip row) are unaffected.
            this.chips = Array.from(this.el.querySelectorAll(".pk-chip"))
            this.chipsByTarget = new Map()
            this.chips.forEach((chip) => {
              const section = chip.dataset.chipTarget && document.getElementById(chip.dataset.chipTarget)
              if (section) this.chipsByTarget.set(section, chip)
            })

            if (this.chips.length > 0 && this.chipsByTarget.size > 0) {
              this.observer = new IntersectionObserver(
                (entries) => {
                  const topmost = entries
                    .filter((entry) => entry.isIntersecting)
                    .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0]
                  if (!topmost) return

                  const activeChip = this.chipsByTarget.get(topmost.target)
                  if (!activeChip) return

                  this.chips.forEach((chip) => chip.classList.remove("is-active"))
                  activeChip.classList.add("is-active")
                },
                {rootMargin: "-20% 0px -70% 0px"}
              )
              this.chipsByTarget.forEach((_chip, section) => this.observer.observe(section))
            }

            // Header-height publisher (01.1-08): this hook already owns the
            // header DOM and this plan is what changes the header's real
            // height (the CTA and the theme toggle both leave the row), so
            // it is the one place that publishes --pk-header-h. Plans
            // 01.1-03/01.1-04 are consumers only — never a second publisher.
            this.publishHeaderHeight = () => {
              const height = this.el.getBoundingClientRect().height
              document.documentElement.style.setProperty("--pk-header-h", height + "px")
            }
            this.heightObserver = new ResizeObserver(() => this.publishHeaderHeight())
            this.heightObserver.observe(this.el)
            this.publishHeaderHeight()

            // Search-morph (01.1-08): guarded on this.morph existing so the
            // Quiénes Somos header (no search slot) is unaffected.
            this.morph = this.el.querySelector(".pk-search-morph")
            if (this.morph) {
              this.morphToggle = this.morph.querySelector(".pk-search-morph-toggle")
              this.morphClose = this.morph.querySelector(".pk-search-morph-close")
              this.morphInput = this.morph.querySelector(".pk-nav-search input")
              this.navInner = this.el.querySelector(".pk-nav-inner")

              this.openMorph = ({focus = true} = {}) => {
                this.morph.classList.add("is-open")
                this.navInner?.classList.add("is-search-open")
                this.morphToggle?.setAttribute("aria-expanded", "true")
                this.morphToggle?.setAttribute("tabindex", "-1")
                this.morphClose?.setAttribute("tabindex", "0")
                if (focus) this.morphInput?.focus()
              }

              this.closeMorph = () => {
                this.morph.classList.remove("is-open")
                this.navInner?.classList.remove("is-search-open")
                this.morphToggle?.setAttribute("aria-expanded", "false")
                this.morphToggle?.setAttribute("tabindex", "0")
                this.morphClose?.setAttribute("tabindex", "-1")
                this.morphToggle?.focus()
              }

              this.syncMorph = () => {
                if (this.morph.dataset.searchExpanded === "true" && !this.morph.classList.contains("is-open")) {
                  this.openMorph({focus: false})
                }
              }

              this.onMorphToggleClick = () => this.openMorph()
              this.onMorphCloseClick = () => this.closeMorph()
              this.onDocumentKeydown = (e) => {
                if (e.key === "Escape" && this.morph.classList.contains("is-open")) this.closeMorph()
              }
              this.onDocumentClick = (e) => {
                if (this.morph.classList.contains("is-open") && !this.morph.contains(e.target)) {
                  this.closeMorph()
                }
              }

              this.morphToggle?.addEventListener("click", this.onMorphToggleClick)
              this.morphClose?.addEventListener("click", this.onMorphCloseClick)
              document.addEventListener("keydown", this.onDocumentKeydown)
              document.addEventListener("click", this.onDocumentClick)

              this.syncMorph()
            }

            // Mobile nav drawer (01.1-09): guarded on this.drawer existing so
            // this hook is a no-op everywhere the drawer markup isn't present.
            // Extends this one hook rather than adding a second — the drawer
            // reaches its own DOM via this.el.querySelector, never outside it
            // except the one documented body-class scroll lock.
            this.drawer = this.el.querySelector("#pk-nav-drawer")
            if (this.drawer) {
              this.drawerBackdrop = this.el.querySelector(".pk-drawer-backdrop")
              this.hamburger = this.el.querySelector(".pk-nav-hamburger")
              this.drawerClose = this.el.querySelector(".pk-drawer-close")
              this.drawerReturnFocus = null

              this.openDrawer = () => {
                this.drawer.classList.add("is-open")
                this.drawerBackdrop?.classList.add("is-open")
                this.drawer.removeAttribute("inert")
                this.hamburger?.setAttribute("aria-expanded", "true")
                document.body.classList.add("pk-drawer-open")
                this.drawerReturnFocus = document.activeElement
                this.drawerClose?.focus()
              }

              // Idempotent: no-ops when already closed, so calling it
              // unconditionally from updated() on every server round trip
              // (see below) never steals focus back to the hamburger on an
              // unrelated re-render.
              this.closeDrawer = () => {
                if (!this.drawer.classList.contains("is-open")) return
                this.drawer.classList.remove("is-open")
                this.drawerBackdrop?.classList.remove("is-open")
                this.drawer.setAttribute("inert", "")
                this.hamburger?.setAttribute("aria-expanded", "false")
                document.body.classList.remove("pk-drawer-open")
                const returnTarget = this.drawerReturnFocus || this.hamburger
                returnTarget?.focus()
                this.drawerReturnFocus = null
              }

              this.onHamburgerClick = () => this.openDrawer()
              this.onDrawerCloseClick = () => this.closeDrawer()
              this.onDrawerBackdropClick = () => this.closeDrawer()

              // Escape closes unconditionally; Tab traps focus inside the
              // panel — copied verbatim from GamePreview's onSheetKeydown
              // focusable-elements query and first/last wrap (game_preview.ex).
              this.onDrawerKeydown = (e) => {
                if (e.key === "Escape") {
                  this.closeDrawer()
                  return
                }
                if (e.key !== "Tab") return
                const focusable = this.drawer.querySelectorAll(
                  'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
                )
                if (focusable.length === 0) return
                const first = focusable[0]
                const last = focusable[focusable.length - 1]
                if (e.shiftKey && document.activeElement === first) {
                  e.preventDefault()
                  last.focus()
                } else if (!e.shiftKey && document.activeElement === last) {
                  e.preventDefault()
                  first.focus()
                }
              }

              this.hamburger?.addEventListener("click", this.onHamburgerClick)
              this.drawerClose?.addEventListener("click", this.onDrawerCloseClick)
              this.drawerBackdrop?.addEventListener("click", this.onDrawerBackdropClick)
              this.drawer.addEventListener("keydown", this.onDrawerKeydown)
            }
          },
          updated() {
            this.publishHeaderHeight()
            this.syncMorph?.()
            // A drawer-link navigation is the only way this hook's updated()
            // fires while the drawer is open; closeDrawer() is idempotent, so
            // calling it unconditionally here needs no old/new-link diffing.
            this.closeDrawer?.()
          },
          destroyed() {
            window.removeEventListener("scroll", this.onScroll)
            this.observer?.disconnect()
            this.heightObserver?.disconnect()
            this.morphToggle?.removeEventListener("click", this.onMorphToggleClick)
            this.morphClose?.removeEventListener("click", this.onMorphCloseClick)
            document.removeEventListener("keydown", this.onDocumentKeydown)
            document.removeEventListener("click", this.onDocumentClick)
            this.hamburger?.removeEventListener("click", this.onHamburgerClick)
            this.drawerClose?.removeEventListener("click", this.onDrawerCloseClick)
            this.drawerBackdrop?.removeEventListener("click", this.onDrawerBackdropClick)
            this.drawer?.removeEventListener("keydown", this.onDrawerKeydown)
            // Defensive: a LiveView teardown mid-open must never leave the
            // page permanently unscrollable.
            document.body.classList.remove("pk-drawer-open")
          }
        }
      </script>
      <.header_inner
        nav_links={@nav_links}
        nav_search={@nav_search}
        crumb={@crumb}
        search_expanded={@search_expanded}
      />
      {render_slot(@subnav)}
      <.nav_drawer active_nav={@active_nav} />
    </div>
    <div :if={!@sticky} id="app-header" class="pk-header">
      <.header_inner
        nav_links={@nav_links}
        nav_search={@nav_search}
        crumb={@crumb}
        search_expanded={@search_expanded}
      />
      {render_slot(@subnav)}
      <.nav_drawer active_nav={@active_nav} />
    </div>

    <main class={["py-20", !@fullbleed && "px-4 sm:px-6 lg:px-8"]}>
      <div class="mx-auto space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.footer />

    <.flash_group flash={@flash} />
    """
  end

  attr :nav_links, :list, required: true
  attr :nav_search, :list, required: true
  attr :crumb, :list, required: true
  attr :search_expanded, :boolean, default: false

  defp header_inner(assigns) do
    ~H"""
    <header class="navbar pk-nav px-0">
      <div class="pk-nav-inner mx-auto w-full max-w-7xl pk-gutter">
        <button
          type="button"
          class="pk-nav-hamburger"
          aria-label="Abrir menú"
          aria-expanded="false"
          aria-controls="pk-nav-drawer"
        >
          <.icon name="hero-bars-3" class="size-6" />
        </button>
        <%!-- shrink-0, not flex-initial: this row is a single-line auto-height
        flex row, so a shrinkable brand does not get narrower — it reflows its
        wordmark onto extra lines and the row inherits that height (debug
        header-height-wordmark-wrap). The lockup is a fixed-size composition;
        the search pill is the row's designated give. --%>
        <div class="shrink-0">
          <.brand_logo />
        </div>
        <nav :if={@crumb != []} class="pk-nav-crumb" aria-label="Ruta de navegación">
          {render_slot(@crumb)}
        </nav>
        <div :if={@nav_links != []} class="pk-nav-links">
          {render_slot(@nav_links)}
        </div>
        <div
          :if={@nav_search != []}
          class="pk-search-morph"
          data-search-expanded={to_string(@search_expanded)}
        >
          <button
            type="button"
            class="pk-search-morph-toggle"
            aria-label="Buscar"
            title="Buscar"
            aria-expanded="false"
            aria-controls="pk-nav-search-region"
          >
            <.icon name="hero-magnifying-glass" class="size-5" />
          </button>
          <div id="pk-nav-search-region" class="pk-nav-search">
            {render_slot(@nav_search)}
          </div>
          <button
            type="button"
            class="pk-search-morph-close"
            aria-label="Cerrar búsqueda"
            tabindex="-1"
          >
            <.icon name="hero-x-mark-micro" class="size-4" />
          </button>
        </div>
      </div>
    </header>
    """
  end

  # Mobile nav drawer (SHELL-01, sketch 011 + sketch 017 Rounds 4-5): the
  # drawer's link list is defined ONCE here, shell-owned rather than
  # slot-owned, so it is identical on all three routes — including Detalle,
  # which passes no nav_links slot and would otherwise get an empty drawer.
  # `inert` is the closed state's a11y mechanism (removes the panel from the
  # tab order/a11y tree without display:none, which would kill the slide
  # transition); `.CatalogNav` adds/removes it. Content (chevrons, the
  # pinned theme-toggle/social bottom block) is filled in by plan 01.1-09
  # Task 2 — Task 1 ships the empty `.pk-drawer-bottom` placeholder only.
  attr :active_nav, :atom, default: nil

  defp nav_drawer(assigns) do
    ~H"""
    <div class="pk-drawer-backdrop" aria-hidden="true"></div>
    <aside
      id="pk-nav-drawer"
      class="pk-drawer"
      role="dialog"
      aria-modal="true"
      aria-label="Menú"
      inert
    >
      <div class="pk-drawer-header">
        <span class="font-display text-lg">Menú</span>
        <button type="button" class="pk-drawer-close" aria-label="Cerrar menú">
          <.icon name="hero-x-mark" class="size-5" />
        </button>
      </div>
      <nav class="pk-drawer-links" aria-label="Navegación principal">
        <.link navigate={~p"/"} aria-current={@active_nav == :inicio && "page"}>
          Inicio <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
        <.link navigate={~p"/quienes-somos"} aria-current={@active_nav == :quienes_somos && "page"}>
          Quiénes Somos <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
      </nav>
      <div class="pk-drawer-bottom">
        <div class="pk-drawer-divider"></div>
        <div class="pk-drawer-utility">
          <span class="pk-drawer-utility-label">Tema</span>
          <.theme_toggle />
        </div>
        <.social_links class="pk-drawer-social" />
      </div>
    </aside>
    """
  end

  @doc """
  The "Sumate" join CTA — the club's WhatsApp group invite link.

  **D-05 superseded (plan 01.1-08).** D-05 originally put this CTA in the
  header site-wide, rendered unconditionally inside `header_inner/1` (never a
  slot) precisely because *a slot can be omitted by a caller*, which would
  silently reintroduce the per-page-fork risk SHELL-01 exists to prevent.
  Sketch 013 asked the scope question and deferred it; sketch 017 Round 3
  reopened it on the developer's direct, twice-repeated instruction. The CTA
  is no longer a header element in any form — not a slot, not a built-in. It
  renders on the About page's hero only (`AboutLive`), and, below 480px, in
  a page-scoped mobile CTA bar (plan 01.1-09).

  Search and the CTA moved in opposite directions for the same underlying
  reason: search became cheap enough to spread to *more* pages (Catálogo and
  Detalle) once it stopped needing a permanent box and became a 44px icon
  (sketch 017 Round 4). The CTA was never a space problem, it was a
  **context** problem — "Sumate al club" asks for a commitment before the
  value case has been made, and only Quiénes Somos makes that case.

  The omission risk D-05 feared is not lost — it is replaced by a stronger,
  executable guarantee: tests assert the CTA is **absent** from `#app-header`
  on `/` and `/juegos/:id`, and **present** in the hero of both `/club` and
  `/quienes-somos` (D-01's two aliases). That catches accidental
  reintroduction into the header too, which unconditional rendering could not.

  Styled per sketch 013-E: outline at rest, filling on hover — checked
  `CoreComponents.button/1`'s `"secondary"` variant (`btn-outline
  btn-primary`, added by quick task 260821-dah) first and reused its exact
  classes directly rather than the component itself, since `button/1`'s
  `:rest` global attr list does not include `target`/`rel` (needed here for
  an external link) and would silently drop them.
  """
  attr :class, :string, default: nil

  def sumate_cta(assigns) do
    ~H"""
    <a
      href={PukllayClubWeb.ClubLinks.whatsapp_group_url()}
      target="_blank"
      rel="noopener noreferrer"
      class={["btn btn-outline btn-primary min-h-12", @class]}
    >
      Sumate
    </a>
    """
  end

  # Shared footer (SHELL-01) — one row, two natural-width clusters
  # (page-shell.md sketch 011), sharing the header's exact max-width +
  # pk-gutter recipe on the same element (never a wrapper around it) so
  # header/footer/content edges line up at any viewport width. Content
  # decided at the Task 2 checkpoint (recorded verbatim in the plan
  # SUMMARY): the links list is FAQ/Contacto/Juntadas (D-02), the social
  # set is WhatsApp/Facebook/Instagram/Email (revised post-Task-1 by the
  # developer — supersedes the plan's original WhatsApp/Instagram/
  # linktr.ee menu), and the BGG attribution is "Powered by BGG" + the
  # BGG logo mark, rendered by `bgg_attribution/1` below.
  #
  # The left cluster overrides brand_logo/1's tagline with the About page's
  # hero tagline ("Conectá jugando", verbatim from about_live.ex) instead of
  # the header's default subtitle, so the footer doesn't just repeat the
  # header's copy (260821-umm). It also passes mark={false} (D-A, 260823-snj):
  # the isologo belongs to the header alone — see brand_logo/1's @doc for the
  # full contract. The footer's wordmark is demoted to the muted colour tier
  # by the pk-brand-quiet class mark={false} adds, not by shrinking it (D-B).
  #
  # The right cluster's "Tema" label and the toggle it labels are wrapped
  # together in `.pk-footer-theme` (debug footer-desktop-overloaded). They are
  # ONE control, and the wrapper is what lets CSS bind them at the item spacing
  # tier instead of the group tier — before it, the label sat exactly as far
  # from its own buttons (24px) as from the unrelated social icons, so the
  # cluster's three concerns read as one flat run. This mirrors the mobile
  # drawer, where `.pk-drawer-utility` already groups the identical label +
  # theme_toggle pair; the footer was the surface that had drifted, not the
  # drawer. The wrapper also gives the <=480px block a single element to hide
  # when the control moves into the drawer.
  defp footer(assigns) do
    assigns = assign(assigns, :copyright_year, Date.utc_today().year)

    ~H"""
    <footer class="pk-footer">
      <div class="pk-footer-row mx-auto w-full max-w-7xl pk-gutter">
        <div class="pk-footer-left">
          <.brand_logo tagline="Conectá jugando" mark={false} />
          <ul class="pk-footer-links">
            <li><a href="/quienes-somos#faq">FAQ</a></li>
            <li><a href="/quienes-somos#contacto">Contacto</a></li>
            <li><a href="/quienes-somos#juntadas">Juntadas</a></li>
          </ul>
        </div>
        <div class="pk-footer-right">
          <.social_links class="pk-footer-social" />
          <div class="pk-footer-theme">
            <span class="pk-footer-toggle-tag">Tema</span>
            <.theme_toggle />
          </div>
          <span class="pk-footer-meta">© {@copyright_year} Pukllay Club · <.bgg_attribution /></span>
        </div>
      </div>
    </footer>
    """
  end

  # Extracted (01.1-09 Task 2) from what was previously the footer's own
  # inline block — one definition of the club's four social links, shared
  # verbatim by the footer and the mobile drawer via two container classes
  # (`ui-design-system`'s single-shared-definition rule: the alternative is
  # two hand-maintained copies of four SVGs, exactly the drift this project
  # has already been bitten by). Every href resolves through ClubLinks (one
  # source), and every external link carries target="_blank" rel="noopener
  # noreferrer" — the mailto: link keeps its existing shape with neither.
  attr :class, :string, required: true

  defp social_links(assigns) do
    ~H"""
    <div class={@class}>
      <a
        href={PukllayClubWeb.ClubLinks.whatsapp_group_url()}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="WhatsApp"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          width="16"
          height="16"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M20.5 11.5a8.5 8.5 0 1 1-3.9-7.15L20.5 3l-1.28 3.72A8.46 8.46 0 0 1 20.5 11.5Z"
          />
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M8.5 8.75c0-.41.34-.75.75-.75h.68c.32 0 .6.2.71.5l.5 1.35c.1.27.05.57-.13.8l-.5.63a5.4 5.4 0 0 0 2.51 2.51l.63-.5c.23-.18.53-.23.8-.13l1.35.5c.3.11.5.39.5.71v.68a.75.75 0 0 1-.75.75h-.5C11.32 15.8 8.2 12.68 8.5 9.25v-.5Z"
          />
        </svg>
      </a>
      <a
        href={PukllayClubWeb.ClubLinks.facebook_url()}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Facebook"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          width="16"
          height="16"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M14.5 8.5h2V5.5h-2c-1.93 0-3.5 1.57-3.5 3.5v2H9v3h2v6.5h3V14h2.2l.5-3H14v-1.5c0-.55.45-1 1-1Z"
          />
        </svg>
      </a>
      <a
        href={PukllayClubWeb.ClubLinks.instagram_url()}
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Instagram"
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          width="16"
          height="16"
        >
          <rect x="4" y="4" width="16" height="16" rx="4" />
          <circle cx="12" cy="12" r="3.5" />
          <circle cx="16.7" cy="7.3" r="0.6" fill="currentColor" stroke="none" />
        </svg>
      </a>
      <a href={"mailto:#{PukllayClubWeb.ClubLinks.contact_email()}"} aria-label="Correo">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          width="16"
          height="16"
        >
          <rect x="4" y="5.5" width="16" height="13" rx="2" />
          <path stroke-linecap="round" stroke-linejoin="round" d="m5 7 7 5.5L19 7" />
        </svg>
      </a>
    </div>
    """
  end

  # BGG attribution (D-04, decided at the Task 2 checkpoint): the exact
  # required wording is "Powered by BGG", linking to boardgamegeek.com and
  # carrying the BGG logo mark (priv/static/images/bgg-logo.jpeg — a flat
  # 400x400 JPEG with its own baked-in background, not a transparent
  # icon). Styled with .pk-bgg-note (underlined small print, no extra
  # box/border/shadow beyond what the image itself already contains) — see
  # the plan SUMMARY's "Claude's Discretion" note for the sizing rationale.
  defp bgg_attribution(assigns) do
    ~H"""
    <a
      href="https://boardgamegeek.com/"
      target="_blank"
      rel="noopener noreferrer"
      class="pk-bgg-note inline-flex items-center gap-1"
    >
      <img src={~p"/images/bgg-logo.jpeg"} width="18" height="18" alt="" />Powered by BGG
    </a>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.

  Rebuilt bare (sketch 014 Round 3 — the "too yellow" complaint was caused by
  emoji glyphs rendering in their own fixed native colour, not by anything
  fixable with CSS opacity; the fix is the already-shipped Heroicons micro
  set, which is inherently single-colour and inherits `currentColor`, not a
  new icon set) and relocated to the footer (sketch 017 Round 2 — the
  conventional home for utility controls). Every behaviour contract is
  unchanged: the same `phx-click={JS.dispatch("phx:set-theme")}` dispatch,
  the same three per-button theme-selecting attribute values, the three
  distinct Spanish `aria-label`s, and `min-h-11 min-w-11` on each button.
  Only the chrome changes — the card, border, background and sliding pill
  are gone; the active state is a small underline expressed in `app.css`'s
  `.pk-theme-toggle` rules, reading the same `<html>` theme attributes
  `assets/js/theme.js` already sets.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="pk-theme-toggle">
      <button
        class="flex items-center justify-center min-h-11 min-w-11 p-2 cursor-pointer"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="Usar tema del sistema"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>

      <button
        class="flex items-center justify-center min-h-11 min-w-11 p-2 cursor-pointer"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Usar tema claro"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>

      <button
        class="flex items-center justify-center min-h-11 min-w-11 p-2 cursor-pointer"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Usar tema oscuro"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end
end
