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
  """
  attr :tagline, :string, default: "JUEGOS DE MESA MODERNOS"

  # `isologo?` is deliberately not a declared `attr` — it's a test-only seam. No production call
  # site ever passes it, so `assign_new/3` always falls through to the compile-time `@isologo?`
  # constant in production, keeping behaviour byte-identical to a plain `assign/3`. This lets a
  # test force the wordmark-only fallback branch via `render_component(&brand_logo/1,
  # %{isologo?: false})`, which a compile-time constant alone would make unreachable on a
  # machine where both marks exist on disk.
  def brand_logo(assigns) do
    assigns = assign_new(assigns, :isologo?, fn -> @isologo? end)

    ~H"""
    <a href="/" class="flex-1 flex w-fit items-center gap-2 min-h-11">
      <img
        :if={@isologo?}
        src={~p"/images/isologo-light.png"}
        width="36"
        alt=""
        class="dark:hidden"
      />
      <img
        :if={@isologo?}
        src={~p"/images/isologo-dark.png"}
        width="36"
        alt=""
        class="hidden dark:block"
      />
      <span class="flex flex-col leading-none">
        <span class="font-display text-2xl uppercase tracking-wide">PUKLLAY CLUB</span>
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
          },
          updated() {
            this.publishHeaderHeight()
            this.syncMorph?.()
          },
          destroyed() {
            window.removeEventListener("scroll", this.onScroll)
            this.observer?.disconnect()
            this.heightObserver?.disconnect()
            this.morphToggle?.removeEventListener("click", this.onMorphToggleClick)
            this.morphClose?.removeEventListener("click", this.onMorphCloseClick)
            document.removeEventListener("keydown", this.onDocumentKeydown)
            document.removeEventListener("click", this.onDocumentClick)
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
    </div>
    <div :if={!@sticky} id="app-header" class="pk-header">
      <.header_inner
        nav_links={@nav_links}
        nav_search={@nav_search}
        crumb={@crumb}
        search_expanded={@search_expanded}
      />
      {render_slot(@subnav)}
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
        <div class="flex-initial">
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
            aria-expanded="false"
            aria-controls="pk-nav-search-region"
          >
            <.icon name="hero-magnifying-glass-micro" class="size-4" />
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
        <.theme_toggle />
      </div>
    </header>
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
  # header's copy (260821-umm).
  defp footer(assigns) do
    ~H"""
    <footer class="pk-footer">
      <div class="pk-footer-row mx-auto w-full max-w-7xl pk-gutter">
        <div class="pk-footer-left">
          <.brand_logo tagline="Conectá jugando" />
          <ul class="pk-footer-links">
            <li><a href="/quienes-somos#faq">FAQ</a></li>
            <li><a href="/quienes-somos#contacto">Contacto</a></li>
            <li><a href="/quienes-somos#juntadas">Juntadas</a></li>
          </ul>
        </div>
        <div class="pk-footer-right">
          <div class="pk-footer-social">
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
          <span class="pk-footer-meta">© 2026 Pukllay Club · <.bgg_attribution /></span>
        </div>
      </div>
    </footer>
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
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex items-center justify-center min-h-11 min-w-11 p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="Usar tema del sistema"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex items-center justify-center min-h-11 min-w-11 p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Usar tema claro"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex items-center justify-center min-h-11 min-w-11 p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Usar tema oscuro"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
