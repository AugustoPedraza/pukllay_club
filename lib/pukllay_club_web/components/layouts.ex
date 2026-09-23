defmodule PukllayClubWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PukllayClubWeb, :html

  # Plan 01.8.2-08 Task 2 (D-19c): admin_flash/1 below renders every admin
  # flash through AdminComponents.snackbar/1 instead of flash_group/1's
  # top toast.
  alias PukllayClubWeb.AdminComponents

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
  Renders the PUKLLAY CLUB horizontal logo lockup (isologo + wordmark), one line.

  Renders a theme-aware isologo pair — the dark-purple mark for light theme, the white mark for
  dark theme, toggled by the `dark:` custom variant — when both
  `priv/static/images/isologo-light.png` and `isologo-dark.png` exist at compile time, and
  degrades to the wordmark alone with no `<img>` at all when either is missing.

  **Header-only since this session's minimalism pass (2026-09-09).** Used to also render on the
  footer (with `mark={false}` suppressing the isologo and a `tagline` attr overriding the
  header's copy) — both the two-line name+tagline lockup and the footer's reuse of it are gone
  (see `footer/1`'s own doc for the footer's replacement). With exactly one caller left, the
  `mark`/`tagline`/`pk-brand-quiet` plumbing that only ever served the footer branch is removed
  rather than kept dead. The wordmark itself is now a SINGLE line ("PUKLLAY CLUB", no tagline) —
  previously a two-line vertical stack next to the nav's single-line links, which read as an
  inconsistent rhythm and forced the wordmark to hide below `56rem`/896px (bare isologo only on
  mobile/tablet, reported as "feels so empty"). One line is narrow enough to render at every
  width instead — see `header_capacity_test.exs` for the re-derived row-capacity arithmetic.
  """

  # `isologo?` is deliberately not a declared `attr` — it's a test-only seam. No production call
  # site ever passes it, so `assign_new/3` always falls through to the compile-time `@isologo?`
  # constant in production, keeping behaviour byte-identical to a plain `assign/3`. This lets a
  # test force the wordmark-only fallback branch via `render_component(&brand_logo/1,
  # %{isologo?: false})`, which a compile-time constant alone would make unreachable on a
  # machine where both marks exist on disk.
  def brand_logo(assigns) do
    assigns = assign_new(assigns, :isologo?, fn -> @isologo? end)

    ~H"""
    <a href="/" class="flex-initial flex w-fit items-center gap-2 min-h-11">
      <%!-- Sketch 045, D-10: the two isologo images below carry a pure
      styling-hook class (added to both, nowhere else in this file) — no
      attr, no branch, no new state. It exists so the About page's
      page-owned isologo scroll-morph hook (about_live.ex) can suppress and
      locate the header's own mark from OUTSIDE this module without D-10
      extending the shared header with a fourth state; only About-scoped
      CSS ever selects it. The alternative was a brittle structural
      selector reaching through `.pk-nav-inner > .shrink-0 > a > img`,
      which breaks the moment this markup's wrapping changes. --%>
      <img
        :if={@isologo?}
        src={~p"/images/isologo-light.png"}
        width="36"
        alt=""
        class="dark:hidden pk-brand-mark"
      />
      <img
        :if={@isologo?}
        src={~p"/images/isologo-dark.png"}
        width="36"
        alt=""
        class="hidden dark:block pk-brand-mark"
      />
      <span class="pk-brand-wordmark pk-brand-name font-display text-2xl uppercase tracking-wide leading-none">
        PUKLLAY CLUB
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

  attr :boundary_collapse, :boolean,
    default: false,
    doc:
      "when true, collapses this page's top and bottom boundary spacing to one deliberate " <>
        "24px value, for a page that owns its own rhythm at both ends (01.2-22). Mutually " <>
        "exclusive with <main>'s default vertical-padding utilities below — the two never " <>
        "both render at once, so default false means every existing caller renders " <>
        "byte-identically"

  attr :bottom_collapse, :boolean,
    default: false,
    doc:
      "when true, collapses ONLY this page's bottom boundary spacing (cancelling <main>'s " <>
        "own bottom padding and the last `.pk-shelf`'s trailing margin), leaving the default " <>
        "top-padding utilities (`pt-8 sm:pt-20`) in place (260902-il3). For a page whose " <>
        "bottom boundary double-stacks but whose top spacing is already correct and must not " <>
        "move — unlike `boundary_collapse`, which owns both ends. It is a no-op when " <>
        "`boundary_collapse` is true: that attr already owns both boundaries, so the two are " <>
        "structurally exclusive branches, never competing declarations (D-02)"

  attr :sticky, :boolean,
    default: false,
    doc:
      "when true, wraps the header in a position: sticky shell that tints flat-translucent past " <>
        "a 40px scroll threshold (the .CatalogNav hook), and enables the nav_links/nav_search/" <>
        "subnav slots. false renders no hook attribute at all — the non-sticky path is byte-" <>
        "compatible with pages that don't opt in."

  attr :admin_chrome, :boolean,
    default: false,
    doc:
      "Task 3 (01.8.2-09, D-00b): true for every /admin page — gates <.footer /> off (D-00b: " <>
        "no footer on /admin). Passed explicitly by each admin LiveView's own <Layouts.app> " <>
        "call, the same shorthand-boolean pattern already used for `bottom_collapse` — there is " <>
        "no separate admin layout module in this app, Layouts.app IS the one shared layout for " <>
        "both scopes, so this is the structural signal the admin routes carry ('an app/1 attr " <>
        "the admin layout passes', per the plan). Deliberately never derived from a URL string " <>
        "match: a future admin route prefix would silently break a path-based predicate, while " <>
        "this one is pinned at the call site of every admin LiveView, verified by an explicit " <>
        "test per route family (dashboard_live_test.exs) rather than assumed to generalize."

  attr :search_expanded, :boolean,
    default: false,
    doc:
      "single source of truth for whether the search-morph is open (01.2-11, superseding the " <>
        "previous open-only-never-closes contract that produced G-01.2-2/G-01.2-3). The class " <>
        "list is rendered from this value server-side — no client JS ever adds or removes " <>
        "`.is-open`/`.is-search-open` — so a LiveView patch can neither strip an open box shut " <>
        "nor fail to reopen one. `.CatalogNav`'s hook reads data-search-expanded (still present) " <>
        "only to decide where to move focus on a transition; it owns no visual state. Any page " <>
        "that fills the `nav_search` slot must handle the `open-search`/`close-search` events " <>
        "the toggle and close buttons dispatch — see the `nav_search` slot doc."

  attr :active_nav, :atom,
    default: nil,
    doc:
      "which top-level nav entry is current — :inicio, :quienes_somos, or nil for a drill-down " <>
        "page that is neither. Drives the mobile drawer's own aria-current-based active row " <>
        "(the drawer's link list is shell-owned, not slot-owned, so Detalle — which passes no " <>
        "nav_links slot — still gets a real menu)."

  attr :active_tab, :atom,
    default: nil,
    doc:
      "Plan 01.8.2-10 (D-13b): which of the tab bar's five destinations is current — " <>
        ":admin, :juegos, :estantes, :web, or nil. Mirrors `active_nav`'s own contract: the " <>
        "caller states its own position explicitly (never derived from the request path — " <>
        "T-01.8.2-45 forbids a URL-string admin predicate anywhere in this module). A page " <>
        "outside the five destinations (Revisar niveles, Staff — admin-shell-navigation.md's " <>
        "documented 'overflow' sections) passes nil; no tab lights."

  attr :badges, :map,
    default: %{},
    doc:
      "Plan 01.8.2-10 (D-19g): %{tab_atom => pending_count} for the tab bar's badges. " <>
        "Defaults to %{} — no admin LiveView computes a real count yet (D-19's 'one derived " <>
        "counter source' is future work); this attr ships the component's contract."

  slot :nav_links, doc: "shelf anchor links, rendered between the brand and the search box"

  slot :nav_search,
    doc:
      "the search form, rendered inside the header aligned with row content. The toggle and " <>
        "close buttons that reveal/hide this slot's content dispatch page-owned " <>
        "`open-search`/`close-search` events (01.2-11) — any page filling this slot must " <>
        "implement both `handle_event` clauses AND pass back a `search_expanded` it flips from " <>
        "them. A missing clause crashes that LiveView on an icon click; a no-op clause is worse " <>
        "than a crash, because it fails silently — the pill can never open and its slot content " <>
        "stays unreachable (debug search-broken-on-mobile-detail). `CatalogLive.Index` and " <>
        "`CatalogLive.Show` both set `:search_expanded` from them; they differ only in the slot " <>
        "content (Show renders a plain native GET form to `/`)."

  slot :crumb, doc: "breadcrumb content for a genuine drill-down page (Detalle only)"

  slot :nav_menu,
    doc:
      "an on-demand category overlay rendered inside the header row; the shell owns " <>
        "placement (inside .pk-nav-inner, immediately before .pk-search-morph), the page " <>
        "owns contents"

  slot :subnav,
    doc:
      "content rendered below the header row and OUTSIDE the sticky wrapper, in normal page " <>
        "flow (e.g. the mobile category chip row). It scrolls away with the page — only the nav " <>
        "itself stays pinned. Rendered into #app-subnav, which the .CatalogNav hook reads by id " <>
        "when collecting scroll-spy targets, so anything carrying data-chip-target still joins " <>
        "the header's own observer."

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
            // Search-morph (01.2-11): wires FIRST, ahead of every other
            // optional block below, so a throw in one of those can never
            // prevent the search controls from wiring (the second candidate
            // cause debug session G-01.2-2 could not rule out — an uncaught
            // exception earlier in mounted() silently aborting the rest of
            // the callback). Every block here (including this one) is now
            // wrapped in its own try/catch for the same reason: one throwing
            // block must never take any sibling block down with it.
            //
            // State (is-open, is-search-open, aria-expanded, tabindex) is
            // now rendered by the SERVER off @search_expanded — this hook's
            // only remaining job is FOCUS, driven by a TRANSITION of
            // data-search-expanded, never by the current value alone (an
            // unconditional focus in updated() would steal it back on every
            // unrelated round trip, and grabbing it on mount would hijack
            // the keyboard/scroll position on a ?q= deep link that arrives
            // already open).
            //
            // The pre-01.2-11 document-level outside-click listener is
            // deliberately gone: it treated any FilterModal control as an
            // "outside" click because the modal is never a DOM descendant
            // of .pk-search-morph — its only trigger (.pk-filter-trigger)
            // is nested INSIDE the morph, but the modal itself renders as a
            // page-level sibling elsewhere in the tree. No correct
            // inside/outside test could exist here without this hook
            // hardcoding knowledge of another page's DOM (G-01.2-3/G-01.2-4
            // defect A). The pill already has an always-visible 44px close
            // control and an Escape binding, so a press outside was never
            // its only dismissal path.
            try {
              this.morph = this.el.querySelector(".pk-search-morph")
              if (this.morph) {
                this.morphToggle = this.morph.querySelector(".pk-search-morph-toggle")
                this.morphInput = this.morph.querySelector(".pk-nav-search input")
                this.wasExpanded = this.morph.dataset.searchExpanded

                this.onDocumentKeydown = (e) => {
                  if (e.key === "Escape" && this.morph.dataset.searchExpanded === "true") {
                    this.pushEvent("close-search", {})
                  }
                }
                document.addEventListener("keydown", this.onDocumentKeydown)
              }
            } catch (e) {
              console.error("CatalogNav: search-morph block failed to wire", e)
            }

            try {
              this.nav = this.el.querySelector(".pk-nav")

              this.onScroll = () => {
                this.nav.classList.toggle("is-scrolled", window.scrollY > 40)
              }
              window.addEventListener("scroll", this.onScroll, {passive: true})
              this.onScroll()
            } catch (e) {
              console.error("CatalogNav: scroll listener block failed to wire", e)
            }

            try {
              // Scroll-spy: highlights whichever element (a mobile chip or a
              // desktop category-panel row) shares data-chip-target with the
              // shelf currently under the header. Widened from a chip-only
              // selector so the desktop panel's items join this one observer
              // instead of getting a second, parallel one — both surfaces
              // light up from the same mechanism. Guarded on there being at
              // least one target and one resolvable section so the detail
              // page and filtered views (neither renders either surface) are
              // unaffected.
              //
              // Collected from TWO roots, not from this.el alone (debug
              // search-right-align-mobile, cycle 5). The two surfaces no longer
              // live in the same element: .pk-cat-item is inside the header, but
              // the mobile chips moved out to #app-subnav when the chip row was
              // un-stuck. Scoped to this.el this would still find all 8 desktop
              // rows and zero chips — the chips would keep rendering and silently
              // stop highlighting, which is exactly the kind of half-working
              // failure a DOM move produces. Named roots rather than a bare
              // document query so the two participating surfaces stay explicit.
              this.spyRoots = [this.el, document.getElementById("app-subnav")].filter(Boolean)
              this.spyTargets = this.spyRoots.flatMap((root) =>
                Array.from(root.querySelectorAll("[data-chip-target]"))
              )
              this.spyTargetsBySection = new Map()
              this.spyTargets.forEach((target) => {
                const section = target.dataset.chipTarget && document.getElementById(target.dataset.chipTarget)
                if (section) this.spyTargetsBySection.set(section, target)
              })

              if (this.spyTargets.length > 0 && this.spyTargetsBySection.size > 0) {
                this.observer = new IntersectionObserver(
                  (entries) => {
                    const topmost = entries
                      .filter((entry) => entry.isIntersecting)
                      .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0]
                    if (!topmost) return

                    const activeTarget = this.spyTargetsBySection.get(topmost.target)
                    if (!activeTarget) return

                    this.spyTargets.forEach((target) => target.classList.remove("is-active"))
                    activeTarget.classList.add("is-active")
                  },
                  {rootMargin: "-20% 0px -70% 0px"}
                )
                this.spyTargetsBySection.forEach((_target, section) => this.observer.observe(section))
              }
            } catch (e) {
              console.error("CatalogNav: scroll-spy block failed to wire", e)
            }

            try {
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
            } catch (e) {
              console.error("CatalogNav: height publisher block failed to wire", e)
            }

            try {
              // Desktop category mega-menu (SHELL-01, sketch 020): guarded on
              // this.catTrigger existing so Quiénes Somos and Detalle (neither
              // renders the nav_menu slot) are untouched no-ops. Modelled line
              // for line on the drawer block above.
              this.catTrigger = this.el.querySelector(".pk-cat-trigger")
              if (this.catTrigger) {
                this.catBackdrop = this.el.querySelector(".pk-cat-backdrop")
                this.catPanel = this.el.querySelector("#pk-cat-menu")
                this.catItems = Array.from(this.el.querySelectorAll(".pk-cat-item"))

                this.openCatMenu = () => {
                  this.catTrigger.classList.add("is-open")
                  this.catPanel?.classList.add("is-open")
                  this.catBackdrop?.classList.add("is-open")
                  this.catTrigger.setAttribute("aria-expanded", "true")
                  this.catPanel?.removeAttribute("inert")
                }

                // Idempotent: no-ops when already closed, same reason
                // closeDrawer() is above — safe to call unconditionally from
                // updated() on every server round trip.
                this.closeCatMenu = () => {
                  if (!this.catTrigger.classList.contains("is-open")) return
                  this.catTrigger.classList.remove("is-open")
                  this.catPanel?.classList.remove("is-open")
                  this.catBackdrop?.classList.remove("is-open")
                  this.catTrigger.setAttribute("aria-expanded", "false")
                  this.catPanel?.setAttribute("inert", "")
                }

                this.onCatTriggerClick = () => {
                  if (this.catTrigger.classList.contains("is-open")) {
                    this.closeCatMenu()
                  } else {
                    this.openCatMenu()
                  }
                }
                this.onCatBackdropClick = () => this.closeCatMenu()
                this.onCatItemClick = () => this.closeCatMenu()
                this.onCatDocumentKeydown = (e) => {
                  if (e.key === "Escape") this.closeCatMenu()
                }

                this.catTrigger.addEventListener("click", this.onCatTriggerClick)
                this.catBackdrop?.addEventListener("click", this.onCatBackdropClick)
                this.catItems.forEach((item) => item.addEventListener("click", this.onCatItemClick))
                document.addEventListener("keydown", this.onCatDocumentKeydown)
              }
            } catch (e) {
              console.error("CatalogNav: category menu block failed to wire", e)
            }
          },
          updated() {
            // Focus-transition only (01.2-11): compare the PREVIOUS
            // data-search-expanded value against the current one and move
            // focus only on an actual change, never on every render — see
            // the mounted() comment above for why an unconditional focus
            // (on every round trip, or on mount) is wrong here.
            if (this.morph) {
              const isExpanded = this.morph.dataset.searchExpanded
              if (this.wasExpanded === "false" && isExpanded === "true") {
                this.morphInput?.focus()
              } else if (this.wasExpanded === "true" && isExpanded === "false") {
                this.morphToggle?.focus()
              }
              this.wasExpanded = isExpanded
            }
            this.publishHeaderHeight?.()
            this.closeCatMenu?.()
          },
          destroyed() {
            window.removeEventListener("scroll", this.onScroll)
            this.observer?.disconnect()
            this.heightObserver?.disconnect()
            document.removeEventListener("keydown", this.onDocumentKeydown)
            this.catTrigger?.removeEventListener("click", this.onCatTriggerClick)
            this.catBackdrop?.removeEventListener("click", this.onCatBackdropClick)
            this.catItems?.forEach((item) => item.removeEventListener("click", this.onCatItemClick))
            document.removeEventListener("keydown", this.onCatDocumentKeydown)
          }
        }
      </script>
      <.header_inner
        nav_links={@nav_links}
        nav_search={@nav_search}
        crumb={@crumb}
        nav_menu={@nav_menu}
        search_expanded={@search_expanded}
        current_scope={@current_scope}
      />
    </div>
    <div :if={!@sticky} id="app-header" class="pk-header">
      <.header_inner
        nav_links={@nav_links}
        nav_search={@nav_search}
        crumb={@crumb}
        nav_menu={@nav_menu}
        search_expanded={@search_expanded}
        current_scope={@current_scope}
      />
    </div>

    <%!--
    WINDOWS #4: the mobile nav drawer is a MODAL overlay and must render as a
    page-level sibling of #app-header, deliberately like #connection-status
    below — never as a child of either #app-header branch above.
    #app-header.pk-header-sticky is a z-index: 50 stacking context; rendered
    inside it, the drawer's own z-index only ordered it inside the header, and
    the whole header (drawer included) composited into the root at effective z
    50 — losing to the root-level About page floating isologo
    (#pk-about-morph-mark, z 60) and to the z-50 flash toast (WINDOWS #4,
    .planning/debug/resolved/about-logo-over-nav-drawer.md). It must stay
    outside the header with no ancestor that creates a stacking context
    (positioned + z-index, transform, opacity below 1, filter, contain,
    isolation, will-change). It still renders here, inside the LiveView root,
    so LiveView continues to mount/patch it normally; .CatalogNav's hook reaches
    it by id.
    --%>
    <.nav_drawer active_nav={@active_nav} current_scope={@current_scope} />

    <%!--
    G-01.2-8 gap closure (01.2-15). Replaces the stock `phx.new` `#client-error`
    / `#server-error` toast that flash_group/1 used to render — that toast fired
    on a genuine WEBSOCKET TRANSPORT DISCONNECT (a dropped LiveView socket, e.g.
    real offline or a server restart), which is a categorically different
    failure mode from CatalogLive.Index's `:more_error` inline retry line
    (`.pk-shelf`'s load-more failure, which only fires on a live, connected
    query failure over an already-established channel). The two surfaces stay
    separate on purpose — see connection-feedback.md's "What to Avoid".

    Placement is deliberate and both halves of it matter:
      1. It is a sibling of the two #app-header branches above, inside the
         LiveView root container, so LiveView's binding scan finds this
         element's `phx-disconnected` / `phx-connected` attributes. A bar
         rendered outside the root would never fire.
      2. It is OUTSIDE #app-header, whose own getBoundingClientRect().height is
         what .CatalogNav publishes as --pk-header-h. .pk-shelf's
         scroll-margin-top and .DetailChrome's title-echo threshold both
         consume that variable, so a bar nested inside the header would shift
         both of them at the exact moment the socket drops. In flow beneath
         the header instead, showing this bar only pushes content down.

    Sketch 030 Round 3's deliberate colour choice: the accent tint, not
    --color-error — a brief, usually self-recovering reconnect must not read
    as an alarm.
    --%>
    <div
      id="connection-status"
      class="pk-conn-banner"
      role="status"
      aria-live="polite"
      phx-disconnected={
        show("#connection-status") |> JS.remove_attribute("hidden", to: "#connection-status")
      }
      phx-connected={
        hide("#connection-status") |> JS.set_attribute({"hidden", ""}, to: "#connection-status")
      }
      hidden
    >
      <span class="pk-conn-spinner" aria-hidden="true"></span>
      <span>Reconectando… no encontramos tu conexión a internet</span>
    </div>

    <%!--
    OUTSIDE #app-header, deliberately (debug search-right-align-mobile, cycle 5,
    on the user's explicit call). This slot used to render as a child of the
    header, and .pk-header-sticky is `position: sticky; top: 0` — sticky pins the
    whole box, so the chip row shared the header's common fate at every scroll
    position (measured y=0..133 at scrollY 0 AND at scrollY 1400). No CSS can
    exempt a child from its ancestor's sticky box; the row has to leave the
    element, which is why this is a markup change and not a rule.

    Only the nav stays pinned now; the chip row scrolls away with the page and
    is occluded by the nav (z-index 50) on its way up. Two consequences worth
    knowing before moving it back:

      1. --pk-header-h is published from #app-header's own height, so it now
         reports the nav alone (65px, was 133px at <=480px). That is what makes
         .pk-shelf's `scroll-margin-top: calc(var(--pk-header-h) + 1rem)` land a
         chip-anchor jump correctly — clearing only what actually occludes it.
      2. The .CatalogNav hook collects scroll-spy targets from BOTH this element
         and the header (the desktop .pk-cat-item rows stay inside the header and
         share the same data-chip-target contract). A hook scoped to this.el
         alone would silently orphan every chip — they would still render and
         simply stop highlighting.

    The id is what the hook keys off, so it is load-bearing, not decorative.
    --%>
    <div :if={@subnav != []} id="app-subnav">
      {render_slot(@subnav)}
    </div>

    <%!--
    pt-8 at mobile, pt-20 from `sm` up (debug search-right-align-mobile, cycle 5).
    This was a flat `py-20`: 5rem/80px of top padding at EVERY width, a
    desktop-scale value shipped unconditionally to phones. Measured at 390px it
    put the first heading at y=213 — 25% of an 844px viewport, ~32% of a 667px
    iPhone SE — spent before the first pixel of content, and it was 100% of the
    gap the user photographed between the chip row and "DESTACADOS DEL CLUB"
    (gapWrapToHeading measured 80.00px exactly; nothing else contributed).

    TOP only. `pb-20` is NOT symmetric decoration — it is the clearance that
    keeps the last content on Detalle (.pk-mobile-cta-bar) and Quiénes Somos
    (.pk-about-cta-bar) from sitting permanently behind their `position: fixed;
    bottom: 0` CTA bars. Cutting the bottom to match the top would trade a
    spacing complaint for a content-occlusion bug on two other pages.

    Restored at `sm` because 80px under a 65px desktop header is a normal airy
    layout and was never what was reported — desktop stays byte-identical. 32px
    rather than 0 because this layer's documented page-container value is
    py-6/24px and its section rhythm is space-y-6; 32px sits just above that
    floor while cutting the reported gap by 60%.

    01.2-22: `@boundary_collapse` and the default vertical-padding utility
    string below are mutually exclusive branches of one `if`, never two
    simultaneously-emitted classes — this file's own CASCADE-LAYER HAZARD
    note (app.css, top of file) is exactly why: an unlayered `.pk-*` rule
    always beats a layered Tailwind utility on the same property, so
    letting the collapse class and the default padding utilities both
    render and relying on that hazard to pick a winner would work by
    accident. One field, one declaration, per state. See app.css's own
    `main.pk-boundary-collapse` rule for what the collapsed state applies.

    260902-il3: `@bottom_collapse` is nested INSIDE the `else` branch above
    — a third sibling branch alongside `@boundary_collapse` was rejected,
    because that would let a future caller pass both attrs and get an
    ambiguous two-class cascade-layer race (the same hazard the paragraph
    above names) rather than a structurally guaranteed winner. Nesting
    inside `else` means `boundary_collapse` short-circuits first: when it
    is true, `bottom_collapse` is never even evaluated, so
    `pk-boundary-collapse` and `pk-bottom-collapse` are incapable of both
    rendering (D-02). The bottom token is emitted first and the unchanged
    `pt-8 sm:pt-20` string second, so the default (both attrs false) state's
    class list keeps its original token order and stays byte-identical to
    the pre-existing exact-string contract test. See app.css's own
    `main.pk-bottom-collapse` rule for what the collapsed state applies.
    --%>
    <main class={[
      if(@boundary_collapse,
        do: "pk-boundary-collapse",
        else: [
          if(@bottom_collapse, do: "pk-bottom-collapse", else: "pb-20"),
          "pt-8 sm:pt-20"
        ]
      ),
      !@fullbleed && "px-4 sm:px-6 lg:px-8"
    ]}>
      <div class="mx-auto space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <%!-- D-00b: no footer on /admin. Gated on @admin_chrome (the structural
    per-call-site attr every admin LiveView passes — see its own attr doc
    above for why this is not a URL string match). --%>
    <.footer :if={!@admin_chrome} />

    <%!-- D-13b (plan 01.8.2-10): the 5-tab admin bar renders for a
    signed-in staff member on EVERY page this layout renders — admin and
    public alike, never gated on @admin_chrome or any other route signal.
    tab_bar/1's own :if guards staff_session?(@current_scope) so an
    anonymous visitor's markup carries none of it. --%>
    <.tab_bar current_scope={@current_scope} active_tab={@active_tab} badges={@badges} />

    <%!-- D-19c (plan 01.8.2-08 Task 2): the admin has exactly ONE feedback
    component, the bottom snackbar — the top toast (`flash_group/1` ->
    `CoreComponents.flash/1`'s `.toast.toast-top`) is deleted for every
    `@admin_chrome` page and its messages (including `Sesión cerrada.` from
    `UserSessionController`) route through `admin_flash/1` instead. Scope B
    (public catalog pages) keeps `flash_group/1` unchanged — D-16 leaves
    that scope alone. --%>
    <.admin_flash :if={@admin_chrome} flash={@flash} />
    <.flash_group :if={!@admin_chrome} flash={@flash} />
    """
  end

  # D-19c: renders every present flash (`:info`/`:error`) through
  # `AdminComponents.snackbar/1` instead of `flash_group/1`'s top toast —
  # the admin's one feedback component. A plain flash (no undo/retry
  # action attached) always renders without an action, per D-19c's own
  # example (`Cerraste sesión`/`Sesión cerrada.`): 4s, no ✕.
  attr :flash, :map, required: true

  defp admin_flash(assigns) do
    ~H"""
    <AdminComponents.snackbar
      :if={msg = Phoenix.Flash.get(@flash, :info)}
      id="admin-snackbar-info"
      message={msg}
      on_close={JS.push("lv:clear-flash", value: %{key: :info})}
    />
    <AdminComponents.snackbar
      :if={msg = Phoenix.Flash.get(@flash, :error)}
      id="admin-snackbar-error"
      message={msg}
      on_close={JS.push("lv:clear-flash", value: %{key: :error})}
    />
    """
  end

  attr :nav_links, :list, required: true
  attr :nav_search, :list, required: true
  attr :crumb, :list, required: true
  attr :nav_menu, :list, required: true
  attr :search_expanded, :boolean, default: false
  attr :current_scope, :map, default: nil

  defp header_inner(assigns) do
    ~H"""
    <header class="navbar pk-nav px-0">
      <div class={[
        "pk-nav-inner mx-auto w-full max-w-7xl pk-gutter",
        @search_expanded && "is-search-open"
      ]}>
        <%!-- Task 1 (D-12/G-01.8.1-1b): the drawer's open/close state is owned
        entirely by the PukllayClubWeb.Layouts.NavDrawer LiveComponent below
        (id="pk-nav-drawer"), so this click is routed there directly via
        phx-target — no hook wiring required. This is what fixes the diagnosed
        cause of G-01.8.1-1b: the previous mechanism lived inside the
        .CatalogNav hook, which app/1 only attached to #app-header when
        @sticky was true, so every admin LiveView (dashboard, estantes,
        staff, secciones, niveles, the game form) and every non-sticky public
        page (About, login, confirmation) rendered a header with NO hook at
        all — the hamburger had no click handler and "I click and nothing
        happens" (G-01.8.1-1b) was reported from exactly one of those pages
        (/admin). A plain phx-click/phx-target binding needs no hook and
        therefore no @sticky gate; it fires on every page this header
        renders on. No aria-expanded here: the target is a role="dialog"
        modal (D-19e's admin sheet family, and 059/017's public drawer
        both agree on this shape), and its own open/inert state is what
        assistive tech reads — see NavDrawer's moduledoc. --%>
        <button
          type="button"
          class="pk-nav-hamburger"
          aria-label="Abrir menú"
          aria-controls="pk-nav-drawer"
          phx-click="open"
          phx-target="#pk-nav-drawer"
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
        {render_slot(@nav_menu)}
        <%!-- D-34: a one-tap way into /admin for a signed-in staff/owner
        session — nothing renders here for a visitor (staff_session?/1
        false). Sits immediately before the search morph, hidden at
        <=480px (app.css's PK block) since mobile staff use the drawer's
        own Admin row instead. --%>
        <.link
          :if={staff_session?(@current_scope)}
          navigate={~p"/admin"}
          class="pk-nav-admin min-h-11 min-w-11"
          aria-label="Admin"
        >
          <.icon name="hero-cog-6-tooth" class="size-5" />
        </.link>
        <%!-- Open/closed state is server-owned (01.2-11): the class list is
        computed from @search_expanded on every render, so no LiveView patch
        (a query flipping, a filter-badge count appearing, a nav_menu/subnav
        sibling slot disappearing) can ever strip an open pill shut or leave
        a closed one stuck. data-search-expanded stays for .CatalogNav's
        focus-transition logic only — it never drives a class from JS. --%>
        <div
          :if={@nav_search != []}
          class={["pk-search-morph", @search_expanded && "is-open"]}
          data-search-expanded={to_string(@search_expanded)}
        >
          <button
            type="button"
            class="pk-search-morph-toggle"
            aria-label="Buscar"
            title="Buscar"
            aria-expanded={to_string(@search_expanded)}
            aria-controls="pk-nav-search-region"
            tabindex={if @search_expanded, do: "-1", else: "0"}
            phx-click="open-search"
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
            tabindex={if @search_expanded, do: "0", else: "-1"}
            phx-click="close-search"
          >
            <.icon name="hero-x-mark-micro" class="size-4" />
          </button>
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Desktop "Explorar categorías" mega-menu — trigger + backdrop + panel
  (SHELL-01, sketch 020 Round 2 items 4/5 + Round 3 alignment fix).
  Rendered via the `nav_menu` slot on `app/1`, threaded into `header_inner/1`
  immediately before `.pk-search-morph` — the shell owns placement (inside
  `.pk-nav-inner`, already `position: relative` and this panel's containing
  block), the page owns contents (`rows`, one map per populated shelf).

  Checked daisyUI's `dropdown` component first (`ui-design-system`'s "state
  which one you checked and why it doesn't fit" rule): its CSS-only
  focus/`popover` show mechanism has no first-class way to pair a dimmed
  backdrop, a document-level Escape handler, and the `.CatalogNav`
  scroll-spy's `is-active` class on individual rows — all three are required
  here. Hand-rolled instead, following the exact
  `inert`/`aria-expanded`/idempotent-close pattern the mobile drawer below
  already established as this page's sanctioned precedent for this kind of
  overlay.

  `data-chip-target` on each `.pk-cat-item` is deliberate, not incidental —
  it is the same attribute the mobile chip row already carries, so the
  `.CatalogNav` scroll-spy's widened selector highlights this panel's rows
  for free instead of needing a second, parallel mechanism.
  """
  attr :rows, :list, required: true, doc: "one map per populated shelf: %{key:, title:, subtitle:}"

  def category_menu(assigns) do
    ~H"""
    <button
      type="button"
      class="pk-cat-trigger"
      aria-expanded="false"
      aria-controls="pk-cat-menu"
      aria-label="Explorar categorías"
    >
      <.icon name="hero-squares-2x2" class="size-5" />
      <span class="pk-cat-trigger-label">Explorar categorías</span>
      <.icon name="hero-chevron-down-micro" class="pk-cat-trigger-chevron size-4" />
    </button>
    <div class="pk-cat-backdrop" aria-hidden="true"></div>
    <div id="pk-cat-menu" class="pk-cat-panel" inert>
      <div class="pk-cat-grid">
        <a
          :for={row <- @rows}
          href={"#carousel-#{row.key}"}
          data-chip-target={"carousel-#{row.key}"}
          class="pk-cat-item"
        >
          <strong>{row.title}</strong>
          <span>{row.subtitle}</span>
        </a>
      </div>
    </div>
    """
  end

  # Mobile nav drawer (SHELL-01, sketch 011 + sketch 017 Rounds 4-5; rebuilt
  # as a stateful LiveComponent for Task 1 of plan 01.8.2-09, D-12/
  # G-01.8.1-1b — see PukllayClubWeb.Layouts.NavDrawer's moduledoc for the
  # diagnosed cause and the fix). This wrapper only owns the backdrop (a
  # plain, always-rendered div — its own `.is-open`-equivalent styling is
  # driven by app.css's `body:has(#pk-nav-drawer.is-open)` rule, since the
  # backdrop itself carries no reactive state) and threads active_nav/
  # current_scope into the component. The backdrop's close-tap targets the
  # component directly by DOM id — the same phx-target mechanism the
  # hamburger uses (header_inner/1) — so it works identically regardless of
  # which LiveView rendered this page.
  attr :active_nav, :atom, default: nil
  attr :current_scope, :map, default: nil

  defp nav_drawer(assigns) do
    ~H"""
    <div
      id="pk-nav-drawer-backdrop"
      class="pk-drawer-backdrop"
      aria-hidden="true"
      phx-click="close"
      phx-target="#pk-nav-drawer"
    >
    </div>
    <.live_component
      module={PukllayClubWeb.Layouts.NavDrawer}
      id="pk-nav-drawer"
      active_nav={@active_nav}
      current_scope={@current_scope}
    />
    """
  end

  # D-34: `current_scope` is `nil` for a visitor (every LiveView's own
  # `mount_current_scope/2` default), a real `Scope` struct for a signed-in
  # one — never a bare `false`/missing key, so the two-clause match below
  # is exhaustive. Public (not `defp`) since Task 1 (01.8.2-09) moved the
  # drawer's own staff branch into the separate `NavDrawer` LiveComponent
  # module, which needs this same predicate — see D-13a's "same drawer
  # everywhere" gate.
  def staff_session?(nil), do: false
  def staff_session?(scope), do: PukllayClub.Accounts.User.staff?(scope.user)

  @doc """
  Renders D-13b's 5-destination admin tab bar (Admin · Juegos · Estantes · Web · Perfil), fixed
  at the screen's bottom for a signed-in staff member on EVERY page this app renders — admin
  and public alike, never gated on the current route (D-13b; T-01.8.2-45's structural-predicate
  requirement bans any URL-string admin classification anywhere in this module, and Task 3's own
  `<verify>` greps for it).

  Geometry is `01.8.2-BENCHMARK.md`'s measured Tab bar row, taken verbatim: 67px tall, a 56×30
  pill indicator behind the active icon, 11px/600 labels. `Perfil` renders as the avatar tab
  the BENCHMARK requires — tapping it opens the nav drawer's already-shipped account section
  (`NavDrawer`'s `Tu cuenta` group, plan 01.8.2-09) rather than a dedicated account sheet, since
  no `/admin/perfil` page or account sheet exists yet in this phase's scope (01.8.2-09's own
  recorded boundary) and building one is not this plan's job.

  `active_tab` is passed explicitly by the LiveView rendering `Layouts.app/1` — the same
  "caller states its own nav position" contract `active_nav` already uses for the public
  header, chosen specifically so this component never has to read the request path itself. A
  page outside the five destinations (`Revisar niveles`, `Staff` — `admin-shell-navigation.md`'s
  documented "overflow" sections) passes no `active_tab`; no tab lights, matching the design
  source of truth.

  `badges` (`%{tab_atom => pending_count}`) renders D-19g's pending-work badge: 18px, primary
  fill, `99+` above 99, absent at a count of 0, and the count folded into the destination's
  accessible name via `aria-label` — never the top-right filled shape doubling as D-19m's
  neutral count pill (that shape means pending work here, and only here).

  The bar's own height is declared **once**, as `--pk-tab-bar-h` (`assets/css/admin/chrome.css`),
  mirroring `--pk-save-bar-h`'s single-source pattern (D-28): `AdminComponents.snackbar/1`
  already reads it (0px fallback, plan 01.8.2-08) for its bottom offset, and
  `.pk-admin-has-tab-bar` derives a page's own bottom clearance from the same property — never a
  second, independently typed pixel figure.
  """
  attr :current_scope, :map, default: nil
  attr :active_tab, :atom, default: nil
  attr :badges, :map, default: %{}

  def tab_bar(assigns) do
    ~H"""
    <nav :if={staff_session?(@current_scope)} class="pk-admin-tab-bar" aria-label="Secciones de Admin">
      <.tab_bar_link to={~p"/admin"} active={@active_tab == :admin} icon="hero-home" label="Admin" />
      <.tab_bar_link
        to={~p"/admin/juegos"}
        active={@active_tab == :juegos}
        icon="hero-puzzle-piece"
        label="Juegos"
        count={Map.get(@badges, :juegos, 0)}
      />
      <.tab_bar_link
        to={~p"/admin/estantes"}
        active={@active_tab == :estantes}
        icon="hero-archive-box"
        label="Estantes"
        count={Map.get(@badges, :estantes, 0)}
      />
      <.tab_bar_link
        to={~p"/admin/secciones"}
        active={@active_tab == :web}
        icon="hero-globe-alt"
        label="Web"
        count={Map.get(@badges, :web, 0)}
      />
      <button
        type="button"
        class="pk-admin-tab pk-admin-tab--avatar"
        data-pk-pressable="true"
        aria-label="Tu perfil"
        aria-haspopup="dialog"
        aria-controls="pk-nav-drawer"
        phx-click="open"
        phx-target="#pk-nav-drawer"
      >
        <span class="pk-admin-tab-icon">
          <span class="pk-admin-tab-avatar-mark" aria-hidden="true">{tab_bar_avatar_initial(
            @current_scope
          )}</span>
        </span>
        <span class="pk-admin-tab-label">Perfil</span>
      </button>
    </nav>
    """
  end

  attr :to, :string, required: true
  attr :active, :boolean, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :count, :integer, default: 0

  defp tab_bar_link(assigns) do
    ~H"""
    <.link
      navigate={@to}
      class={["pk-admin-tab", @active && "is-active"]}
      aria-current={@active && "page"}
      aria-label={@count > 0 && tab_bar_badge_aria_label(@label, @count)}
      data-pk-pressable="true"
    >
      <span class="pk-admin-tab-icon">
        <.icon name={@icon} class="size-6" />
        <span :if={@count > 0} class="pk-admin-tab-badge" aria-hidden="true">
          {tab_bar_badge_text(@count)}
        </span>
      </span>
      <span class="pk-admin-tab-label">{@label}</span>
    </.link>
    """
  end

  defp tab_bar_badge_text(count) when count > 99, do: "99+"
  defp tab_bar_badge_text(count), do: Integer.to_string(count)

  defp tab_bar_badge_aria_label(label, count), do: "#{label}, #{count} pendientes"

  defp tab_bar_avatar_initial(%{user: %{email: email}}) when is_binary(email) and email != "" do
    email |> String.slice(0, 1) |> String.upcase()
  end

  defp tab_bar_avatar_initial(_), do: "?"

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
  reason: search became cheap enough to spread to *more* pages (Ludoteca and
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

  **Size, superseded (G-01.5-1/G-01.5-3 item 5, plan 01.5-05).** The
  composition below used to be daisyUI's `btn-lg` step composed with the
  app's 44px touch-floor utility (`min-h-11`) — a correct fix for a real
  proportion defect: the button had been a bare `min-h-12` one-axis height
  override that produced a 1.03:1 squat, square-padded label box, and
  `btn-lg` + `min-h-11` (matching `catalog_live/show.ex`'s reserve CTA)
  repaired that mechanism, landing a healthy 1.74:1 ratio. It did NOT close
  a separate, independent fidelity delta against sketch 051 — the human-
  approved design source this composition's BALANCE was actually judged
  against — because `btn-lg`'s own coupled height/padding-inline/font-size
  (42px/16px/18px in this app's theme) never matched that source's spec
  (48px/28px/16px). See `.planning/debug/G-01.5-4-hero-cierre-composition-
  balance.md` for the full differential.

  **Size, current (G-01.5-4, plan 01.5-10).** `pk-sumate-btn` (declared once
  in `assets/css/app.css`, near the About page's own CSS group) now owns
  every axis of the button's size — height, inline padding, font-size and
  corner radius — as the sketch 051 spec measures them, restoring the
  composition the design was approved with. `btn-lg` and `min-h-11` are both
  gone: leaving either alongside `pk-sumate-btn` would have two rules
  compete on height again, exactly the failure mode this composition already
  fixed once. The 44px touch floor is met by `pk-sumate-btn`'s own 48px
  `min-height` and is verified in `test/visual/about_geometry.mjs` by
  measuring the RENDERED height, not by asserting a utility class is
  present — a utility class can be silently outbid; a measured height cannot.

  **Why this now diverges from the catalog page's reserve CTA
  (`catalog_live/show.ex`'s `btn btn-primary btn-lg min-h-11 w-full`), the
  very button plan 01.5-05 matched it to.** The reserve CTA is a different
  surface, on a different page, with no counterpart in sketch 051, and no
  UAT round has ever reported it — it is untouched by this plan. The Sumate
  CTA is the object a human-approved composition (sketch 051, rounds 9/10)
  was actually judged against, and that composition's own button geometry is
  what this class restores. The two buttons no longer sharing a size
  mechanism is a recorded decision, not drift.
  """
  attr :class, :string, default: nil

  def sumate_cta(assigns) do
    ~H"""
    <a
      href={PukllayClubWeb.ClubLinks.whatsapp_group_url()}
      target="_blank"
      rel="noopener noreferrer"
      class={["btn btn-outline btn-primary pk-sumate-btn", @class]}
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
  # REMOVED (this session's header/footer minimalism pass, 2026-09-09): the
  # left cluster used to open with `<.brand_logo tagline="Conectá jugando"
  # mark={false} />` — a wordmark-only, muted-colour repeat of the header's
  # own brand identity (D-A/D-B, 260823-snj). The header already establishes
  # brand identity on every page; repeating it in the footer read as visual
  # weight with no new information, and this footer specifically has an
  # unusually long history of "feels overloaded"/"feels imbalanced" reports
  # (debug sessions footer-desktop-overloaded, footer-desktop-imbalance,
  # footer-theme-toggle-balance — all fixed by retuning SPACING, none by
  # removing an ELEMENT) — see `.planning/debug/knowledge-base.md`'s own
  # generalizable lesson from that history: "hierarchy has three channels —
  # proximity, weight/contrast, colour — fixing one and declaring victory is
  # how 'still overloaded' survives a correct spacing fix." Dropping the
  # brand block is the first fix to this footer that touches WEIGHT (an
  # element's own footprint) rather than only proximity. The left cluster is
  # now just the links list — a single navigational concern, not two
  # different KINDS of concern (identity + navigation) sharing one cluster.
  #
  # The right cluster's "Tema" label and the toggle it labels are wrapped
  # together in `.pk-footer-theme` (debug footer-desktop-overloaded). They are
  # ONE control, and the wrapper is what lets CSS bind them at the item spacing
  # tier instead of the group tier — before it, the label sat exactly as far
  # from its own buttons (24px) as from the unrelated social icons, so the
  # cluster's three concerns read as one flat run. This mirrors the mobile
  # drawer, where `.pk-drawer-utility` already groups the identical label +
  # theme_toggle pair; the footer was the surface that had drifted, not the
  # drawer.
  #
  # That label is now `sr-only` and promoted to the control's accessible GROUP
  # NAME via role="group" + aria-labelledby (debug footer-theme-toggle-balance).
  # It is CONVERTED, not deleted, and the distinction matters: plan
  # 01.1-08-PLAN.md:429-433 added it "so the control is discoverable in a place
  # users are not yet used to looking for it", and that single stated premise is
  # what changed. Vercel's Geist design system documents the footer as the
  # CANONICAL home for a Light/System/Dark control ("Place it once per app, in
  # the footer or settings"), so the location is no longer unfamiliar. Geist's
  # own footer-density variant carries no visible text either — it ships
  # `<legend class="sr-only">Select a display theme:</legend>`, which is exactly
  # the shape adopted here. This is also a net accessibility GAIN rather than a
  # trade: the three buttons already had per-button aria-labels but the control
  # had NO group name at all, so assistive tech now announces one where it
  # previously announced three unrelated buttons.
  #
  # UPDATE (quick task 260824-q8z): the drawer's `.pk-drawer-utility-label` is
  # now ALSO `sr-only`, superseding the paragraph above's original claim that it
  # "survives where Geist says it should" as a full-size, visible label. That
  # claim rested on Geist's "room for the labels to breathe" framing for a
  # settings-like surface — but sketch 021 independently ran the drawer's own
  # theme control through 6 rounds of this same developer's feedback and
  # converged on E1 (Icon-Only, Centered) with NO visible label, the same
  # answer this debug session reached for the footer. Both surfaces now carry
  # "Tema" as an sr-only accessible group name only (role="group" +
  # aria-labelledby on each wrapper). The drawer's real distinguishing property
  # is its 44px touch floor — `.pk-footer-theme .pk-theme-toggle button` shrinks
  # to 28px, footer-scoped; the drawer's buttons do not shrink, because the
  # drawer is the sole mobile home for this control below 480px
  # (`.pk-footer-right` is `display: none` there).
  #
  # The legal line lives in its OWN full-width row, `.pk-footer-legal`, not
  # inside the right cluster (debug footer-desktop-imbalance). Sketch 011 gave
  # this footer two peer clusters; the right one then accreted a third concern
  # and, worse, one of a different KIND — two interactive utilities plus one
  # passive compliance run — so the row read as 2 concerns on the left against
  # 3 on the right (364.11px vs 604.81px of ink, 1.66x, with a 247.08px void
  # between them). Promoting the legal line to its own band makes KIND map to
  # ROW: utilities above, small print below, two concerns per cluster. That is
  # the structural repair the spacing tiers could not reach — proximity can
  # group unlike things, it cannot make them alike.
  #
  # `.pk-footer-legal` is a normal child of `.pk-footer-row`, not a second
  # capped-width wrapper. Its `width: 100%` is what forces the line break, so
  # the row's own row-gap (the cluster tier) provides the separation — no
  # divider (sketch 011 forbids one), no fifth spacing token, and no second
  # element carrying the max-width/padding recipe that page-shell.md warns
  # about twice.
  #
  # The band holds TWO sibling `.pk-footer-meta` spans, not one run with a "·"
  # separator, and that split is the fix rather than a formatting preference
  # (debug footer-desktop-imbalance). Once the legal line had its own
  # full-width band, 241.75px of ink was being asked to occupy a 1216px band —
  # 19.88% filled, with the other 80.1% sitting as ONE unbroken 974.25px void,
  # so it read as an orphaned fragment rather than a peer band. Measured, that
  # is a FILL problem and not an alignment one: left, centre and right all
  # produce the identical 19.88%, because alignment only relocates the void.
  # Splitting the run into two edge-anchored pieces is the only treatment that
  # changes the number the eye is responding to (19.88% -> 100%), and the only
  # one that stays correct in the wrapped 481-790px band as well as at 1280px.
  #
  # Two spans is therefore load-bearing, not cosmetic: `justify-content:
  # space-between` over a SINGLE flex item is a no-op, so re-merging these
  # back into one span silently restores the 19.88% stub. The "·" separator
  # goes with it — it existed to join two things sitting next to each other,
  # and they are now ~984px apart at 1280px.
  #
  # Deliberately NOT undoing the earlier baseline fix: the two spans remain
  # flex items on ONE line, and `.pk-footer-legal`'s `align-items: baseline`
  # keeps their text on a single shared baseline by construction, at any
  # separation. That was this session's originally-reported defect, so it is
  # pinned by its own test rather than left to the coincidence that two boxes
  # of equal height happen to align.
  #
  # UPDATE (2026-09-02, quick task 260902-fdm, sketch 044 winner H): at
  # ≤480px this footer renders as the BGG attribution line alone. The left
  # cluster and the copyright span (`pk-footer-copyright`, added below) are
  # hidden in CSS rather than removed from the markup, so every desktop
  # contract documented above continues to describe the shipped DOM at every
  # width — only the ≤480px `@media` block in app.css differs. The
  # FAQ/Contacto/Juntadas removal at that width is a developer-accepted
  # tradeoff (sketch 044's "Real Tradeoff, Verified" section grepped the
  # codebase and confirmed those three anchors exist nowhere else in the
  # app), not an oversight. The attribution rendered by `bgg_attribution/1`
  # is the one element in this footer that may never be hidden at any width
  # (D-04).
  defp footer(assigns) do
    assigns = assign(assigns, :copyright_year, Date.utc_today().year)

    ~H"""
    <footer class="pk-footer">
      <div class="pk-footer-row mx-auto w-full max-w-7xl pk-gutter">
        <div class="pk-footer-left">
          <ul class="pk-footer-links">
            <li><a href="/quienes-somos#faq">FAQ</a></li>
            <li><a href="/quienes-somos#contacto">Contacto</a></li>
            <li><a href="/quienes-somos#juntadas">Juntadas</a></li>
          </ul>
        </div>
        <div class="pk-footer-right">
          <.social_links class="pk-footer-social" />
          <div class="pk-footer-theme" role="group" aria-labelledby="pk-footer-theme-label">
            <span id="pk-footer-theme-label" class="pk-footer-toggle-tag sr-only">Tema</span>
            <.theme_toggle />
          </div>
        </div>
        <div class="pk-footer-legal">
          <span class="pk-footer-meta pk-footer-copyright">© {@copyright_year} Pukllay Club</span>
          <span class="pk-footer-meta"><.bgg_attribution /></span>
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
  #
  # Promoted to public (plan 01.4-02 Task 3): the About page's rebuilt
  # Contacto card is now a third consumer, alongside the footer
  # (`.pk-footer-social`) and the mobile drawer (`.pk-drawer-social`).
  # `icons` (which channels render) and `labels` (whether each renders a
  # visible Spanish text label after its icon) are both optional and both
  # DEFAULT to today's exact behavior — neither the footer nor the drawer
  # call site passes either attr, so their rendered output stays
  # byte-identical. Only the Contacto card passes `icons={[:whatsapp,
  # :instagram]} labels` to get the card-row treatment. Not a single SVG
  # `d`/`viewBox`/`width`/`height`/`aria-label`/`href`/`target`/`rel` value
  # changed in this promotion — those are the shared definition this whole
  # exercise exists to preserve.
  attr :class, :string, required: true
  attr :icons, :list, default: [:whatsapp, :facebook, :instagram, :email]
  attr :labels, :boolean, default: false

  def social_links(assigns) do
    ~H"""
    <div class={@class}>
      <a
        :if={:whatsapp in @icons}
        href={PukllayClubWeb.ClubLinks.whatsapp_group_url()}
        target="_blank"
        rel="noopener noreferrer"
        aria-label={if @labels, do: nil, else: "WhatsApp"}
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
        <span :if={@labels}>Grupo de WhatsApp</span>
      </a>
      <a
        :if={:facebook in @icons}
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
        <span :if={@labels}>Facebook</span>
      </a>
      <a
        :if={:instagram in @icons}
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
        <span :if={@labels}>Instagram</span>
      </a>
      <a
        :if={:email in @icons}
        href={"mailto:#{PukllayClubWeb.ClubLinks.contact_email()}"}
        aria-label="Correo"
      >
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
        <span :if={@labels}>Correo</span>
      </a>
    </div>
    """
  end

  # BGG attribution (D-04, decided at the Task 2 checkpoint): the exact
  # required wording is "Powered by BGG", linking to boardgamegeek.com and
  # carrying the BGG logo mark (priv/static/images/bgg-logo.jpeg — a flat
  # 400x400 JPEG with its own baked-in background, not a transparent
  # icon). Styled with .pk-bgg-note (underlined small print, no extra
  # box/border/shadow beyond what the image itself already contains).
  #
  # This anchor is deliberately PLAIN INLINE, never `inline-flex` (debug
  # footer-desktop-imbalance). It used to carry `inline-flex items-center
  # gap-1`, and that is a trap for any icon+text run that sits inside a
  # sentence: an inline-level flex container with no baseline-aligned item
  # must SYNTHESIZE its baseline from the first flex item's border box
  # (CSS Flexbox §8.3), and the first item here is the logo. So the image's
  # BOTTOM edge became this link's baseline and sat on the copyright text's
  # baseline — measured coinciding exactly — shoving "Powered by BGG" 5px
  # above the "© 2026 Pukllay Club ·" it is supposed to sit beside, and
  # inflating the meta line box from 18px to 23px.
  #
  # Being plain inline means the attribution words share ONE inline
  # formatting context (and therefore one baseline, by construction) with
  # the copyright text they follow. There is no offset number to keep in
  # sync — which is the point; a `vertical-align: -5px` compensator would
  # have hard-coded the output of the very computation that was wrong and
  # broken again on the next font-size or logo-size change.
  #
  # The words are wrapped in their own <span> so the underline decorates
  # the TEXT and not the logo tile: on a plain inline anchor the decoration
  # would otherwise be drawn straight across the image.
  defp bgg_attribution(assigns) do
    ~H"""
    <a href="https://boardgamegeek.com/" target="_blank" rel="noopener noreferrer" class="pk-bgg-note">
      <img src={~p"/images/bgg-logo.jpeg"} width="14" height="14" alt="" /><span>Powered by BGG</span>
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

defmodule PukllayClubWeb.Layouts.NavDrawer do
  @moduledoc """
  The site-wide mobile nav drawer (SHELL-01, sketch 011 + sketch 017 Rounds 4-5), rebuilt as a
  stateful LiveComponent for Task 1 of plan 01.8.2-09 (D-12/G-01.8.1-1b).

  **Diagnosed cause of G-01.8.1-1b** ("drawer stop working (I click and nothing happens)",
  reported from `/admin`, 01.8.1-UAT.md test 1): the drawer's entire open/close wiring used to
  live inside the `.CatalogNav` colocated hook, which `Layouts.app/1` only attached
  (`phx-hook=".CatalogNav"`) to `#app-header` when the `sticky` attr was `true`. Every admin
  LiveView (dashboard, estantes, staff, secciones, niveles, the game form) and every non-sticky
  public page (About, login, confirmation) called `<Layouts.app>` without `sticky`, so on those
  pages the hook never mounted at all — the hamburger had no click handler, no keydown listener,
  nothing. Clicking it did exactly what was reported: nothing.

  **The fix:** move the drawer's open/close state into this LiveComponent, addressed by a stable
  DOM id (`#pk-nav-drawer`) that both the hamburger (`Layouts.header_inner/1`) and the backdrop
  (`Layouts.nav_drawer/1`) target directly via `phx-target` — a plain declarative `phx-click`
  binding needs no hook and therefore no `@sticky` gate, so it fires identically on every page
  (`Layouts.app/1` renders this component unconditionally, itself outside either `#app-header`
  branch).

  `@open` drives the state class (`"is-open"`), `aria-expanded` and `inert` straight from the
  component's own assign — server-rendered, so a LiveView test can `render_click/1` the hamburger
  and assert the drawer's open state in the rendered markup without a browser. The colocated
  `.NavDrawerFocus` hook is reduced to what a server round trip cannot do on its own: Escape-to-
  close, Tab focus-trapping while open, moving focus into the panel on open and back to whatever
  had it before on close, and the `body.pk-drawer-open` scroll lock — it never toggles the open
  state itself, only reacts to it (`updated()` compares the previous vs current `"is-open"` class,
  the same before/after-transition idiom `.CatalogNav`'s search-morph focus logic already uses).

  Kept as exactly one drawer component (D-13a "same drawer everywhere"): this module renders the
  identical public content on every page for a visitor; Task 3 adds the staff sectioned content
  (PANEL / SITIO / TU CUENTA) as a second branch inside this same render, never a second component.
  """
  use PukllayClubWeb, :live_component

  alias PukllayClubWeb.AdminComponents
  alias PukllayClubWeb.Layouts

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :open, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <aside
      id="pk-nav-drawer"
      class={["pk-drawer", @open && "is-open"]}
      role="dialog"
      aria-modal="true"
      aria-label="Menú"
      aria-expanded={to_string(@open)}
      inert={!@open}
      phx-hook=".NavDrawerFocus"
    >
      <script :type={Phoenix.LiveView.ColocatedHook} name=".NavDrawerFocus">
        export default {
          mounted() {
            // Unconditional — this hook lives on the LiveComponent's OWN
            // root, rendered by Layouts.app/1 on every page, so it mounts
            // regardless of @sticky. This is the other half of the
            // G-01.8.1-1b fix: focus management no longer depends on which
            // page rendered the header.
            this.wasOpen = this.el.classList.contains("is-open")
            this.returnFocus = null
            this.closeButton = this.el.querySelector(".pk-drawer-close")
            document.body.classList.toggle("pk-drawer-open", this.wasOpen)

            // Escape closes unconditionally; Tab traps focus inside the
            // panel — same shape as GamePreview's onSheetKeydown
            // focusable-elements query and first/last wrap (game_preview.ex).
            this.onKeydown = (e) => {
              if (e.key === "Escape") {
                this.pushEventTo(this.el, "close", {})
                return
              }
              if (e.key !== "Tab") return
              const focusable = this.el.querySelectorAll(
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
            this.el.addEventListener("keydown", this.onKeydown)
          },
          updated() {
            const isOpen = this.el.classList.contains("is-open")
            document.body.classList.toggle("pk-drawer-open", isOpen)

            if (!this.wasOpen && isOpen) {
              this.returnFocus = document.activeElement
              this.closeButton?.focus()
            } else if (this.wasOpen && !isOpen) {
              const target =
                (this.returnFocus && document.contains(this.returnFocus) && this.returnFocus) ||
                document.querySelector(".pk-nav-hamburger")
              target?.focus()
              this.returnFocus = null
            }
            this.wasOpen = isOpen
          },
          destroyed() {
            this.el.removeEventListener("keydown", this.onKeydown)
            // Defensive: a LiveView teardown mid-open must never leave the
            // page permanently unscrollable.
            document.body.classList.remove("pk-drawer-open")
          }
        }
      </script>
      <div class="pk-drawer-header">
        <span class="font-display text-lg">Menú</span>
        <button
          type="button"
          class="pk-drawer-close"
          aria-label="Cerrar menú"
          phx-click="close"
          phx-target={@myself}
        >
          <.icon name="hero-x-mark" class="size-5" />
        </button>
      </div>
      <%!-- Task 3 (01.8.2-09, D-13a): ONE drawer component, TWO content
      branches — never a second component. A signed-in staff member gets
      the sectioned drawer (Panel / Sitio / Tu cuenta) on every page,
      public or admin; an anonymous visitor keeps today's plain public
      drawer, byte-identical to before this task (the `else` branch below
      is untouched from Task 1/2). --%>
      <nav
        :if={Layouts.staff_session?(@current_scope)}
        class="pk-drawer-links pk-drawer-links--staff"
        aria-label="Navegación principal"
      >
        <%!-- Section labels: resolves the BENCHMARK's "noticed on the way"
        item (11px UPPERCASE drawer labels vs 13px sentence-case page group
        labels — two looks for one "labelled group" role). Chosen: the
        13px/600 sentence-case look, routed through plan 01.8.2-07's
        `form_label/1 rank="group"` so there is one implementation, not
        two — see the plan SUMMARY for the recorded decision. --%>
        <AdminComponents.form_label rank="group">Panel</AdminComponents.form_label>
        <.link navigate={~p"/admin"}>
          Admin <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
        <.link navigate={~p"/admin/secciones"}>
          Web <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>

        <AdminComponents.form_label rank="group">Sitio</AdminComponents.form_label>
        <.link navigate={~p"/"} aria-current={@active_nav == :inicio && "page"}>
          Inicio <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
        <.link navigate={~p"/quienes-somos"} aria-current={@active_nav == :quienes_somos && "page"}>
          Quiénes Somos <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>

        <AdminComponents.form_label rank="group">Tu cuenta</AdminComponents.form_label>
        <%!-- D-00b: Salir moves here (the drawer's account section) — the
        loose `Salir` link that used to sit on the dashboard page itself is
        deleted (dashboard_live.ex). This identity row is static (no href,
        no chevron — it acts as a label, not a destination), matching
        admin-shell-navigation.md's account-sheet identity-row anatomy. --%>
        <div class="pk-drawer-account" aria-label="Perfil">
          <span class="pk-drawer-account-label">Perfil</span>
          <span class="pk-drawer-account-email">{@current_scope.user.email}</span>
        </div>
        <.link href={~p"/admin/salir"} method="delete">
          Salir <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
      </nav>
      <nav
        :if={!Layouts.staff_session?(@current_scope)}
        class="pk-drawer-links"
        aria-label="Navegación principal"
      >
        <.link navigate={~p"/"} aria-current={@active_nav == :inicio && "page"}>
          Inicio <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
        <.link navigate={~p"/quienes-somos"} aria-current={@active_nav == :quienes_somos && "page"}>
          Quiénes Somos <.icon name="hero-chevron-right-micro" class="pk-drawer-chevron size-4" />
        </.link>
      </nav>
      <div class="pk-drawer-bottom">
        <div class="pk-drawer-divider"></div>
        <Layouts.social_links class="pk-drawer-social" />
        <div class="pk-drawer-divider"></div>
        <div class="pk-drawer-utility" role="group" aria-labelledby="pk-drawer-theme-label">
          <span id="pk-drawer-theme-label" class="pk-drawer-utility-label sr-only">Tema</span>
          <Layouts.theme_toggle />
        </div>
      </div>
    </aside>
    """
  end

  @impl true
  def handle_event("open", _params, socket), do: {:noreply, assign(socket, :open, true)}
  def handle_event("close", _params, socket), do: {:noreply, assign(socket, :open, false)}
end
