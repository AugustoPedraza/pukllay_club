defmodule PukllayClubWeb.CatalogLive.Show do
  @moduledoc """
  Game detail page (CATALOG-05/06/07 full picture, CATALOG-08 public/no
  auth). Reached from `PukllayClubWeb.GameCard`'s `Ver detalles` CTA.

  `mount/3` loads the game via `Catalog.get_game!/1`, which raises
  `Ecto.NoResultsError` for an unknown id — Phoenix renders the generated
  404 page for that case rather than crashing (T-01-30).

  `handle_event("select-image", ...)` swaps the main image only when the
  client-supplied `url` is a member of the game's own
  `[cover_url | gallery_urls]` list — a crafted url is never echoed
  unchecked into an `img src` (T-01-26). The lightbox (`handle_event(
  "open-lightbox"/"close-lightbox", ...)`) reuses this exact handler and
  whitelist for its own previous/next controls, so there is a single
  guarded image-selection path, not a second one (T-01.1-16).

  Every field from this plan's `<planner_assumption>` omission table is
  individually conditional: an absent field removes its whole row/element,
  never a blank placeholder.

  Mobile chrome (SHELL-03, plan 01.1-04): `.DetailChrome` drives the fixed
  bottom CTA bar and the sticky title-echo bar off a single passive
  `scroll` listener + `getBoundingClientRect()` — deliberately not the
  viewport-observer API Chrome throttles/suspends in a backgrounded tab.
  `.Lightbox` and `.ShareButton` never assemble markup or a URL from
  strings/`dataset` values (T-01.1-08) — share intent hrefs are built
  server-side in HEEx with `URI.encode_www_form/1`.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.CarouselRow
  alias PukllayClubWeb.GameChips
  alias PukllayClubWeb.GamePreview

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    game = Catalog.get_game!(id)

    {:ok,
     socket
     |> assign(:page_title, game.name)
     |> assign(:game, game)
     |> assign(:selected_image, game.cover_url)
     |> assign(:mechanic_labels, Vocabulary.covered_mechanics(game.mechanics))
     |> assign(:theme_labels, Vocabulary.covered_themes(game.themes))
     |> assign(:similar_games, Catalog.similar_games(game))
     |> assign(:similares_subtitle, similares_subtitle(game))
     |> assign(:description_expanded, false)
     |> assign(:lightbox_open, false)}
  end

  @impl true
  def handle_event("select-image", %{"url" => url}, socket) do
    if url in gallery_thumbnails(socket.assigns.game) do
      {:noreply, assign(socket, :selected_image, url)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle-description", _params, socket) do
    {:noreply, update(socket, :description_expanded, &(!&1))}
  end

  @impl true
  def handle_event("open-lightbox", _params, socket) do
    {:noreply, assign(socket, :lightbox_open, true)}
  end

  @impl true
  def handle_event("close-lightbox", _params, socket) do
    {:noreply, assign(socket, :lightbox_open, false)}
  end

  # Inert stub — wired to a real reservation flow by plan 01.1-05. Returning
  # {:noreply, socket} unchanged means clicking either reservation CTA
  # (buy-box or mobile bar) does nothing visible yet rather than crashing
  # in the interim.
  @impl true
  def handle_event("open-reservation", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- active_nav={nil} passed explicitly, not defaulted into: Detalle is a
    drill-down of the catalog and a peer of neither top-level nav entry
    (sketch 017's own page switcher marks no drawer link active here). --%>
    <Layouts.app flash={@flash} fullbleed sticky search_expanded={false} active_nav={nil}>
      <:crumb>
        <.link navigate={~p"/"}>Ludoteca</.link>
        <span class="pk-crumb-sep">/</span>
        <span class="pk-crumb-current">{@game.name}</span>
      </:crumb>
      <:nav_search>
        <form action={~p"/"} method="get" role="search">
          <label for="detail-search-q" class="sr-only">Buscar juegos</label>
          <.input
            type="text"
            id="detail-search-q"
            name="q"
            value=""
            placeholder="Buscar juegos…"
            maxlength="100"
          />
        </form>
      </:nav_search>

      <%!-- Single outermost detail wrapper (01.1-04): the .DetailChrome hook
      is mounted here once and drives both the fixed CTA bar and the sticky
      title-echo bar via document-level lookups (the real <footer> has no
      other stable handle for a position:fixed element to park against).
      The inner "space-y-4" div reproduces the exact gap Layouts.app's own
      wrapper used to provide between the masthead and the carousel row
      before this wrapper existed, so introducing it is not a visual
      regression. --%>
      <div id="detail-page" phx-hook=".DetailChrome">
        <script :type={Phoenix.LiveView.ColocatedHook} name=".DetailChrome">
          export default {
            mounted() {
              this.ctaBar = document.getElementById("detail-cta-bar")
              this.titleEcho = document.getElementById("detail-title-echo")
              this.titleBlock = document.getElementById("detail-title-block")
              this.footer = document.querySelector("footer.pk-footer")
              document.body.classList.add("pk-has-cta-bar")
              this.footerReached = false
              this.scrollEndTimer = null

              this.onScroll = () => {
                // 1. Debounced hide-while-scrolling. Never fights the
                // parked state — return immediately once the footer has
                // been reached.
                if (!this.footerReached) {
                  this.ctaBar?.classList.add("is-hidden")
                  clearTimeout(this.scrollEndTimer)
                  this.scrollEndTimer = setTimeout(() => {
                    this.ctaBar?.classList.remove("is-hidden")
                  }, 200)
                }

                // 2. Footer park — the position:fixed equivalent of
                // position:sticky's natural "unstick at the container
                // boundary".
                if (this.footer) {
                  this.footerReached = this.footer.getBoundingClientRect().top < window.innerHeight
                  this.ctaBar?.classList.toggle("is-parked", this.footerReached)
                  this.titleEcho?.classList.toggle("is-parked", this.footerReached)
                  document.body.classList.toggle("pk-cta-parked", this.footerReached)
                }

                // 3. Title echo. The offsetParent guard is mandatory: a
                // hidden element's rect is all zeros, which would satisfy
                // the "scrolled past" threshold and show the bar when it
                // should not. headerHeight is read from the real
                // --pk-header-h custom property published by .CatalogNav —
                // never a literal pixel value.
                const headerHeight =
                  parseFloat(
                    getComputedStyle(document.documentElement).getPropertyValue("--pk-header-h")
                  ) || 0
                const scrolledPast =
                  this.titleBlock?.offsetParent !== null &&
                  this.titleBlock?.getBoundingClientRect().bottom < headerHeight
                this.titleEcho?.classList.toggle("is-visible", !!scrolledPast && !this.footerReached)
              }

              window.addEventListener("scroll", this.onScroll, {passive: true})
              this.onScroll()

              this.onClick = (e) => {
                if (e.target.closest("[data-scroll-top]")) {
                  window.scrollTo({top: 0, behavior: "smooth"})
                }
              }
              this.el.addEventListener("click", this.onClick)
            },
            destroyed() {
              window.removeEventListener("scroll", this.onScroll)
              this.el.removeEventListener("click", this.onClick)
              clearTimeout(this.scrollEndTimer)
              document.body.classList.remove("pk-has-cta-bar")
              document.body.classList.remove("pk-cta-parked")
            }
          }
        </script>

        <div id="detail-title-echo" class="pk-title-echo">
          <span>{@game.name}</span>
          <button
            type="button"
            data-scroll-top
            aria-label="Volver arriba"
            class="pk-scroll-top min-h-11 min-w-11"
          >
            <.icon name="hero-arrow-up" class="size-4" />
          </button>
        </div>

        <div class="space-y-4">
          <div class="mx-auto w-full max-w-7xl pk-gutter">
            <div class="pk-detail-masthead">
              <div class="pk-poster-col">
                <button
                  :if={@selected_image}
                  type="button"
                  phx-click="open-lightbox"
                  aria-label="Ampliar imagen del juego"
                  class="aspect-video overflow-hidden rounded-box bg-base-300 block w-full min-h-11 cursor-zoom-in"
                >
                  <img src={@selected_image} alt={@game.name} class="h-full w-full object-cover" />
                </button>
                <div
                  :if={!@selected_image}
                  class="aspect-video overflow-hidden rounded-box bg-base-300 flex h-full w-full items-center justify-center text-primary"
                >
                  <.icon name="hero-puzzle-piece" class="size-16" />
                  <span class="sr-only">{@game.name}</span>
                </div>

                <div
                  :if={@game.gallery_urls != []}
                  id="gallery-thumbnails"
                  class="flex gap-2 overflow-x-auto"
                >
                  <button
                    :for={url <- gallery_thumbnails(@game)}
                    type="button"
                    phx-click="select-image"
                    phx-value-url={url}
                    class={[
                      "h-16 w-16 shrink-0 overflow-hidden rounded-box border-2",
                      (url == @selected_image && "border-primary") || "border-transparent"
                    ]}
                  >
                    <img src={url} alt={@game.name} class="h-full w-full object-cover" />
                  </button>
                </div>

                <%!-- Real handler lands in plan 01.1-05; open-reservation is
                an inert stub until then so the button never crashes. --%>
                <div class="flex items-center gap-2">
                  <button
                    type="button"
                    phx-click="open-reservation"
                    class="btn btn-primary min-h-11 flex-1"
                  >
                    {reservation_cta_label()}
                  </button>
                  <.share_control id="detail-share-buybox" game={@game} />
                </div>
              </div>

              <div class="pk-text-col">
                <GamePreview.facts_row game={@game} />

                <h1 id="detail-title-block" class="font-display text-3xl">{@game.name}</h1>

                <GameChips.weight_band_badge game={@game} show_descriptor={true} />
                <GameChips.editorial_tags tags={@game.tags} />

                <div :if={@game.description} class="pk-description">
                  <p class={["pk-clamp", @description_expanded && "is-expanded"]}>
                    {@game.description}
                  </p>
                  <button
                    type="button"
                    phx-click="toggle-description"
                    class="link link-primary text-sm"
                  >
                    {(@description_expanded && "Ver menos") || "Ver más"}
                  </button>
                </div>

                <h2 :if={@mechanic_labels != []} class="pk-section-heading">Mecánicas</h2>
                <GameChips.chip_row terms={@mechanic_labels} limit={99} />

                <h2 :if={@theme_labels != []} class="pk-section-heading">Temáticas</h2>
                <GameChips.chip_row terms={@theme_labels} limit={99} />

                <h2 class="pk-section-heading">Ficha técnica</h2>
                <dl class="pk-spec-list">
                  <div :if={@game.min_players && @game.max_players} class="pk-spec-row">
                    <dt>Jugadores</dt>
                    <dd>{@game.min_players}-{@game.max_players}</dd>
                  </div>
                  <div :if={playtime_text(@game)} class="pk-spec-row">
                    <dt>Duración</dt>
                    <dd>{playtime_text(@game)}</dd>
                  </div>
                  <div :if={@game.min_age} class="pk-spec-row">
                    <dt>Edad mínima</dt>
                    <dd>{@game.min_age}+</dd>
                  </div>
                  <div :if={@game.year_published} class="pk-spec-row">
                    <dt>Año</dt>
                    <dd>{@game.year_published}</dd>
                  </div>
                  <div :if={@game.designers != []} class="pk-spec-row pk-spec-row--wide">
                    <dt>Diseñadores</dt>
                    <dd>{Enum.join(@game.designers, ", ")}</dd>
                  </div>
                  <div :if={@game.publishers != []} class="pk-spec-row pk-spec-row--wide">
                    <dt>Editorial</dt>
                    <dd>{Enum.join(@game.publishers, ", ")}</dd>
                  </div>
                  <div class="pk-spec-row pk-spec-row--wide">
                    <dt>Ilustrador</dt>
                    <dd>No disponible</dd>
                  </div>
                  <div class="pk-spec-row pk-spec-row--wide">
                    <dt>Puesto en el ranking BGG</dt>
                    <dd>No disponible</dd>
                  </div>
                  <div :if={@game.bgg_id} class="pk-spec-row pk-spec-row--wide">
                    <dd>
                      <a
                        href={"https://boardgamegeek.com/boardgame/#{@game.bgg_id}"}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="link link-primary"
                      >
                        Ver ficha completa en BoardGameGeek
                      </a>
                    </dd>
                  </div>
                </dl>
              </div>
            </div>
          </div>

          <CarouselRow.carousel_row
            id="similares"
            title="Juegos similares"
            games={@similar_games}
            subtitle={@similares_subtitle}
          />
        </div>

        <div id="detail-cta-bar" class="pk-mobile-cta-bar">
          <button type="button" phx-click="open-reservation" class="btn btn-primary min-h-11 flex-1">
            {reservation_cta_label()}
          </button>
          <.share_control id="detail-share-ctabar" game={@game} />
        </div>

        <div
          :if={@lightbox_open}
          id="detail-lightbox"
          class="pk-lightbox is-open"
          role="dialog"
          aria-modal="true"
          aria-label="Imágenes del juego"
          phx-hook=".Lightbox"
        >
          <script :type={Phoenix.LiveView.ColocatedHook} name=".Lightbox">
            export default {
              mounted() {
                this.closeBtn = this.el.querySelector("[data-lightbox-close]")
                this.closeBtn?.focus()

                this.onKeydown = (e) => {
                  if (e.key === "Escape") {
                    this.pushEvent("close-lightbox", {})
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
              destroyed() {
                this.el.removeEventListener("keydown", this.onKeydown)
              }
            }
          </script>
          <button
            type="button"
            data-lightbox-close
            phx-click="close-lightbox"
            aria-label="Cerrar"
            class="pk-lightbox-close btn btn-circle min-h-11 min-w-11"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
          <button
            :if={length(gallery_thumbnails(@game)) > 1}
            type="button"
            phx-click="select-image"
            phx-value-url={lightbox_neighbor(@game, @selected_image, -1)}
            aria-label="Imagen anterior"
            class="btn btn-circle min-h-11 min-w-11 absolute left-4 top-1/2 -translate-y-1/2"
          >
            <.icon name="hero-chevron-left" class="size-5" />
          </button>
          <img src={@selected_image} alt={@game.name} class="pk-lightbox-img" />
          <button
            :if={length(gallery_thumbnails(@game)) > 1}
            type="button"
            phx-click="select-image"
            phx-value-url={lightbox_neighbor(@game, @selected_image, 1)}
            aria-label="Imagen siguiente"
            class="btn btn-circle min-h-11 min-w-11 absolute right-4 top-1/2 -translate-y-1/2"
          >
            <.icon name="hero-chevron-right" class="size-5" />
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Shared by both reservation CTAs (buy-box and mobile bar) so the label
  # string exists in exactly one place in the source and can never drift
  # between the two surfaces.
  defp reservation_cta_label, do: "Reservar para el sábado"

  @doc false
  attr :id, :string, required: true
  attr :game, Game, required: true

  # Shared by the buy-box column and the mobile CTA bar (01.1-04) so the
  # two share controls can never drift. Native Web Share API first
  # (.ShareButton hook); the fallback popover's WhatsApp/X intent hrefs and
  # the copy-link target are built server-side in HEEx with
  # URI.encode_www_form/1 — no client-side URL assembly (T-01.1-08).
  defp share_control(assigns) do
    assigns = assign(assigns, :share_url, url(~p"/juegos/#{assigns.game.id}"))

    ~H"""
    <div class="pk-share-wrap relative inline-block">
      <button
        type="button"
        id={@id}
        phx-hook=".ShareButton"
        data-share-title={@game.name}
        data-share-url={@share_url}
        aria-label="Compartir juego"
        class="btn btn-circle btn-outline btn-primary min-h-11 min-w-11"
      >
        <.icon name="hero-share" class="size-5" />
      </button>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".ShareButton">
        export default {
          mounted() {
            this.title = this.el.dataset.shareTitle
            this.url = this.el.dataset.shareUrl
            this.popover = this.el.parentElement.querySelector(".pk-share-popover")
            this.copyBtn = this.popover?.querySelector("[data-copy-link]")
            this.copyConfirm = this.popover?.querySelector("[data-copy-confirm]")
            this.copyTimer = null

            this.onClick = () => {
              if (navigator.share) {
                navigator.share({title: this.title, url: this.url}).catch(() => {})
                return
              }
              this.popover?.classList.toggle("is-open")
            }
            this.el.addEventListener("click", this.onClick)

            this.onCopyClick = () => {
              navigator.clipboard.writeText(this.copyBtn.dataset.shareUrl).then(() => {
                this.copyConfirm?.classList.remove("hidden")
                clearTimeout(this.copyTimer)
                this.copyTimer = setTimeout(() => this.copyConfirm?.classList.add("hidden"), 2000)
              })
            }
            this.copyBtn?.addEventListener("click", this.onCopyClick)

            this.onDocumentClick = (e) => {
              if (this.popover?.classList.contains("is-open") && !this.el.parentElement.contains(e.target)) {
                this.popover.classList.remove("is-open")
              }
            }
            document.addEventListener("click", this.onDocumentClick)
          },
          destroyed() {
            this.el.removeEventListener("click", this.onClick)
            this.copyBtn?.removeEventListener("click", this.onCopyClick)
            document.removeEventListener("click", this.onDocumentClick)
            clearTimeout(this.copyTimer)
          }
        }
      </script>
      <div id={"#{@id}-popover"} class="pk-share-popover" role="menu" aria-label="Compartir por">
        <a
          href={"https://wa.me/?text=" <> URI.encode_www_form("#{@game.name} #{@share_url}")}
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Compartir por WhatsApp"
          class="btn btn-outline min-h-11 justify-start"
        >
          WhatsApp
        </a>
        <a
          href={
            "https://twitter.com/intent/tweet?text=" <>
              URI.encode_www_form(@game.name) <> "&url=" <> URI.encode_www_form(@share_url)
          }
          target="_blank"
          rel="noopener noreferrer"
          aria-label="Compartir por X"
          class="btn btn-outline min-h-11 justify-start"
        >
          X (Twitter)
        </a>
        <button
          type="button"
          data-copy-link
          data-share-url={@share_url}
          aria-label="Copiar enlace"
          class="btn btn-outline min-h-11 justify-start"
        >
          Copiar enlace
        </button>
        <span data-copy-confirm class="pk-copy-confirm hidden text-sm text-neutral">
          Enlace copiado
        </span>
      </div>
    </div>
    """
  end

  # `cover_url` first so it's always the initial thumbnail/main image when
  # present; nils filtered so an absent cover never mints a broken `<img>`.
  defp gallery_thumbnails(game) do
    Enum.reject([game.cover_url | game.gallery_urls], &is_nil/1)
  end

  # The lightbox's previous/next controls reuse this against the same
  # whitelist gallery_thumbnails/1 builds — there is no second,
  # independently-derived image list (T-01.1-16). Wraps around both ends.
  defp lightbox_neighbor(game, current, offset) do
    urls = gallery_thumbnails(game)

    case Enum.find_index(urls, &(&1 == current)) do
      nil -> current
      idx -> Enum.at(urls, rem(idx + offset + length(urls), length(urls)))
    end
  end

  defp playtime_text(%{playing_time: t}) when is_integer(t), do: "#{t} min"

  defp playtime_text(%{min_playtime: min, max_playtime: max}) when is_integer(min) and is_integer(max) and min != max,
    do: "#{min}-#{max} min"

  defp playtime_text(%{min_playtime: min}) when is_integer(min), do: "#{min} min"
  defp playtime_text(%{max_playtime: max}) when is_integer(max), do: "#{max} min"
  defp playtime_text(_game), do: nil

  # Subtitle for the Juegos similares shelf — reuses Vocabulary.weight_band/1's
  # existing plain-Spanish descriptor label rather than authoring new copy
  # (01.1-03 checkpoint decision). nil when the game has no band, matching
  # Catalog.similar_games/1's own nil-band guard (there is nothing to name).
  defp similares_subtitle(%{weight_band: nil}), do: nil

  defp similares_subtitle(game) do
    case Vocabulary.weight_band(game.weight_band) do
      nil -> nil
      band -> "Otros juegos del mismo nivel: " <> band.label
    end
  end
end
