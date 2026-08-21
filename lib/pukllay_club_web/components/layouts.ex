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

  # The brand isologo (Andean llama + hexagon + meeple silhouette per the brand manual) has no
  # vector source yet — only the identity PDF. Gate on its presence at compile time so dropping
  # priv/static/images/isologo.svg in later completes the horizontal lockup with no code change.
  @isologo_path "priv/static/images/isologo.svg"
  @external_resource @isologo_path
  @isologo? File.exists?(@isologo_path)

  @doc """
  Renders the PUKLLAY CLUB horizontal logo lockup (isologo + wordmark + tagline).

  Renders the isologo mark when `priv/static/images/isologo.svg` exists at compile time, and
  degrades to the wordmark + tagline lockup without a broken image reference when it does not.
  """
  def brand_logo(assigns) do
    assigns = assign(assigns, :isologo?, @isologo?)

    ~H"""
    <a href="/" class="flex-1 flex w-fit items-center gap-2 min-h-11">
      <img :if={@isologo?} src={~p"/images/isologo.svg"} width="36" alt="" />
      <span class="flex flex-col leading-none">
        <span class="font-display text-2xl uppercase tracking-wide">PUKLLAY CLUB</span>
        <span class="font-sans text-xs uppercase tracking-widest text-neutral">
          JUEGOS DE MESA MODERNOS
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
          },
          destroyed() {
            window.removeEventListener("scroll", this.onScroll)
            this.observer?.disconnect()
          }
        }
      </script>
      <.header_inner nav_links={@nav_links} nav_search={@nav_search} crumb={@crumb} />
      {render_slot(@subnav)}
    </div>
    <div :if={!@sticky} id="app-header" class="pk-header">
      <.header_inner nav_links={@nav_links} nav_search={@nav_search} crumb={@crumb} />
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

  defp header_inner(assigns) do
    ~H"""
    <header class="navbar pk-nav">
      <div class="pk-nav-inner mx-auto w-full max-w-7xl pk-gutter">
        <div class="flex-1">
          <.brand_logo />
        </div>
        <nav :if={@crumb != []} class="pk-nav-crumb" aria-label="Ruta de navegación">
          {render_slot(@crumb)}
        </nav>
        <div :if={@nav_links != []} class="pk-nav-links">
          {render_slot(@nav_links)}
        </div>
        <div :if={@nav_search != []} class="pk-nav-search">
          {render_slot(@nav_search)}
        </div>
        <.sumate_cta />
        <div class="flex-none">
          <ul class="flex flex-column px-1 space-x-4 items-center">
            <li>
              <.theme_toggle />
            </li>
          </ul>
        </div>
      </div>
    </header>
    """
  end

  # The site-wide "Sumate" join CTA (D-05) — a built-in element of
  # header_inner/1, deliberately NOT a caller-owned slot (unlike
  # nav_links/nav_search/crumb above), so no page can fork by forgetting to
  # pass it. This is this plan's one documented deviation from
  # 01.1-PATTERNS.md's suggested `sumate_cta` slot: a slot can be omitted by
  # a caller, which would silently reintroduce the exact per-page-fork risk
  # SHELL-01 exists to prevent, so it's rendered unconditionally instead.
  defp sumate_cta(assigns) do
    ~H"""
    <a
      href={PukllayClubWeb.ClubLinks.whatsapp_group_url()}
      target="_blank"
      rel="noopener noreferrer"
      class="btn btn-primary btn-sm min-h-11"
    >
      Sumate
    </a>
    """
  end

  # Shared footer (SHELL-01) — one row, two natural-width clusters
  # (page-shell.md sketch 011), sharing the header's exact max-width +
  # pk-gutter recipe on the same element (never a wrapper around it) so
  # header/footer/content edges line up at any viewport width. The links
  # list, social icons, and BGG attribution render as structural
  # placeholders in this plan (01.1-01) — plan 01.1-01's Task 3 fills them
  # with the content decided at the Task 2 checkpoint.
  defp footer(assigns) do
    ~H"""
    <footer class="pk-footer">
      <div class="pk-footer-row mx-auto w-full max-w-7xl pk-gutter">
        <div class="pk-footer-left">
          <.brand_logo />
          <ul class="pk-footer-links"></ul>
        </div>
        <div class="pk-footer-right">
          <div class="pk-footer-social"></div>
          <span class="pk-footer-meta"></span>
        </div>
      </div>
    </footer>
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
