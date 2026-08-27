defmodule PukllayClubWeb.CatalogLive.Show do
  @moduledoc """
  Game detail page (CATALOG-05/06/07 full picture, CATALOG-08 public/no
  auth). Reached from `PukllayClubWeb.GameCard`'s `Ver detalles` CTA.

  `mount/3` loads the game via `Catalog.get_game!/1`, which raises
  `Ecto.NoResultsError` for an unknown id — Phoenix renders the branded
  404 page (`PukllayClubWeb.ErrorHTML`'s `404.html.heex`, 01.1-07) for that
  case rather than crashing (T-01-30).

  `:loading` (01.1-07) mirrors `CatalogLive.Index`'s own two-phase mount
  trick: `not Phoenix.LiveView.connected?/1` of the socket, set once in
  `mount/3` and never toggled by any `handle_event`. The disconnected
  static render skips
  `Catalog.similar_games/1` entirely (`:similar_games` stays `[]`) and
  paints a flat skeleton shelf in its place, occupying the same footprint;
  the connected mount runs the real query via `safe_similar_games/1`, whose
  `rescue` degrades a failed "more like this" lookup to no shelf rather than
  taking down a detail page whose primary content already loaded fine.

  `handle_event("select-image", ...)` swaps the main image only when the
  client-supplied `url` is a member of the game's own
  `[cover_url | gallery_urls]` list — a crafted url is never echoed
  unchecked into an `img src` (T-01-26). The lightbox (`handle_event(
  "open-lightbox"/"close-lightbox", ...)`) reuses this exact handler and
  whitelist for its own previous/next controls, so there is a single
  guarded image-selection path, not a second one (T-01.1-16).

  Every field from this plan's `<planner_assumption>` omission table is
  individually conditional: an absent field removes its whole row/element,
  never a blank placeholder. Ficha técnica applies this at two levels
  (01.2-04, D-04/D-05): each remaining row keeps its own independent `:if`
  guard, AND the section heading plus the list are themselves wrapped in
  `ficha_tecnica?/1` so a game with none of the four carriable fields
  (min_age, year_published, designers, bgg_id) shows no empty heading over
  an empty grid. The publisher-name field this section used to carry was
  dropped entirely in the G-01.2-10 mobile masthead rework (01.2-17) — the
  UAT called it useless information, and the removal is unconditional
  (every viewport width), not a mobile-only cut.

  Mobile chrome (SHELL-03, plan 01.1-04): `.DetailChrome` drives the fixed
  bottom CTA bar and the sticky title-echo bar off a single passive
  `scroll` listener + `getBoundingClientRect()` — deliberately not the
  viewport-observer API Chrome throttles/suspends in a backgrounded tab.
  `.Lightbox` and `.ShareButton` never assemble markup or a URL from
  strings/`dataset` values (T-01.1-08) — share intent hrefs are built
  server-side in HEEx with `URI.encode_www_form/1`.

  Reservation flow (SHELL-03's reservation half, D-09/D-10, plan 01.1-05):
  the buy-box and mobile-bar CTAs both dispatch `open-reservation`, which
  opens a name-capture modal. `reservation_url/3` builds the destination
  link entirely server-side (T-01.1-02) — the visitor's name is
  percent-encoded via `URI.encode_www_form/1` before it ever reaches the
  query string, and is never persisted, logged, or sent anywhere else. The
  destination number comes from `Application.get_env(:pukllay_club,
  :reservation_whatsapp_number)`, a runtime-configured value distinct from
  `PukllayClubWeb.ClubLinks`' group-invite URL — a different WhatsApp
  destination for a different purpose.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.CarouselRow
  alias PukllayClubWeb.CatalogFilters
  alias PukllayClubWeb.GameChips
  alias PukllayClubWeb.GamePreview

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    game = Catalog.get_game!(id)
    # 01.1-07: the same disconnected/connected two-phase mount trick
    # CatalogLive.Index already uses. :loading is set once here and never
    # toggled by an event; the disconnected static render skips the
    # similar-games query entirely (a skeleton shelf occupies the same
    # footprint instead), the connected mount runs it for real.
    loading? = not connected?(socket)
    similar_games = if(loading?, do: [], else: safe_similar_games(game))
    # G-01.2-7 / sketch 031: pure comparison over at most @similares_limit
    # already-loaded structs — no extra query, and no change to
    # similar_games/1's return type. A no-band game's every returned game
    # differs from `nil`, so widened? is true — correct, since that shelf
    # is entirely a widened pool.
    similares_widened? = Enum.any?(similar_games, &(&1.weight_band != game.weight_band))

    {:ok,
     socket
     |> assign(:page_title, game.name)
     |> assign(:game, game)
     |> assign(:catalog_path, CatalogFilters.catalog_path(params["from"]))
     |> assign(:selected_image, game.cover_url)
     |> assign(:mechanic_labels, Vocabulary.covered_mechanics(game.mechanics))
     |> assign(:theme_labels, Vocabulary.covered_themes(game.themes))
     |> assign(:loading, loading?)
     |> assign(:similar_games, similar_games)
     |> assign(:similares_widened, similares_widened?)
     |> assign(:similares_subtitle, similares_subtitle(game, similares_widened?))
     |> assign(:description_expanded, false)
     |> assign(:lightbox_open, false)
     |> assign(:reservation_number, Application.get_env(:pukllay_club, :reservation_whatsapp_number))
     |> assign(:reservation_open, false)
     |> assign(:reservation_name, "")
     |> assign(:reservation_error, nil)}
  end

  # header_inner/1's search-morph toggle/close buttons now dispatch
  # open-search/close-search unconditionally on any page filling the
  # nav_search slot (01.2-11) — this page passes a hardcoded
  # search_expanded={false} and never varies it (its nav_search slot is a
  # plain native GET form to "/", not the catalog's live-filtered box), so
  # both clauses are deliberate no-ops. Without them, clicking the search
  # icon here would crash the LiveView with no matching handle_event clause.
  @impl true
  def handle_event("open-search", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("close-search", _params, socket), do: {:noreply, socket}

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
    socket =
      if socket.assigns.selected_image do
        assign(socket, :lightbox_open, true)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("close-lightbox", _params, socket) do
    {:noreply, assign(socket, :lightbox_open, false)}
  end

  # Opens the reservation modal, reset to a blank/untouched state every time
  # (not just on first open) so a name typed and abandoned in a prior visit
  # never leaks into a later one.
  @impl true
  def handle_event("open-reservation", _params, socket) do
    {:noreply,
     socket
     |> assign(:reservation_open, true)
     |> assign(:reservation_name, "")
     |> assign(:reservation_error, nil)}
  end

  @impl true
  def handle_event("close-reservation", _params, socket) do
    {:noreply, assign(socket, :reservation_open, false)}
  end

  # Validate on blur only (ux-patterns B12: "validate after the action —
  # blur/submit — not while typing"). No phx-change is wired on the form
  # for this reason; only the name input's own phx-blur reaches here.
  @impl true
  def handle_event("validate-reservation", %{"nombre" => name}, socket) do
    {:noreply, assign_reservation_name(socket, name)}
  end

  @impl true
  def handle_event("reserve", %{"nombre" => name}, socket) do
    {:noreply, assign_reservation_name(socket, name)}
  end

  defp assign_reservation_name(socket, name) do
    trimmed = String.trim(name)

    socket
    |> assign(:reservation_name, trimmed)
    |> assign(:reservation_error, reservation_name_error(trimmed))
  end

  defp reservation_name_error(""), do: "Ingresá tu nombre para continuar."

  defp reservation_name_error(name) do
    if String.length(name) > 60 do
      "El nombre es demasiado largo (máximo 60 caracteres)."
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- active_nav={nil} passed explicitly, not defaulted into: Detalle is a
    drill-down of the catalog and a peer of neither top-level nav entry
    (sketch 017's own page switcher marks no drawer link active here). --%>
    <Layouts.app flash={@flash} fullbleed sticky search_expanded={false} active_nav={nil}>
      <:crumb>
        <.link navigate={@catalog_path}>Ludoteca</.link>
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
          <div id="detail-masthead-wrap" class="mx-auto w-full max-w-7xl pk-gutter">
            <div class="pk-detail-masthead">
              <div class="pk-poster-col">
                <%!-- G-01.2-19 task 1 (was G-01.2-10 task 2): one facts
                row exists on the page, above the poster panel, at every
                viewport width — the mobile absolute overlay and the
                desktop inline copy are gone. Its own root already carries
                pk-facts-row, so no wrapper div is added; it is addressed
                in CSS as a direct child of .pk-poster-col
                (.pk-poster-col > .pk-facts-row). See G-01.2-11/G-01.2-12
                and sketch 032. --%>
                <GamePreview.facts_row game={@game} linked={true} />

                <div class="pk-poster-panel">
                  <div class="pk-poster-frame">
                    <div class="absolute right-2 top-2 z-10">
                      <.share_control id="detail-share-buybox" game={@game} />
                    </div>

                    <button
                      :if={@selected_image}
                      type="button"
                      phx-click="open-lightbox"
                      aria-label="Ampliar imagen del juego"
                      class="pk-card-poster overflow-hidden rounded-box bg-base-300 block w-full min-h-11 cursor-zoom-in"
                    >
                      <img
                        src={@selected_image}
                        alt={@game.name}
                        class="h-full w-full object-cover js-cover-fallback"
                      />
                      <div class="hidden h-full w-full items-center justify-center bg-base-300 text-primary">
                        <.icon name="hero-puzzle-piece" class="size-16" />
                      </div>
                    </button>
                    <div
                      :if={!@selected_image}
                      class="pk-card-poster overflow-hidden rounded-box bg-base-300 flex h-full w-full items-center justify-center text-primary"
                    >
                      <.icon name="hero-puzzle-piece" class="size-16" />
                      <span class="sr-only">{@game.name}</span>
                    </div>
                  </div>

                  <%!-- G-01.2-10 task 2, D3 (recommended: dots on mobile,
                  thumbnails on desktop). Both strips are built from the same
                  gallery_thumbnails/1 list and both dispatch select-image
                  with the same phx-value-url key, so the existing
                  membership-check whitelist (mount/handle_event above) stays
                  the single guarded image-selection path — not a second one
                  (T-01.1-16-style). Exactly one of the two renders per
                  viewport, swap declared in app.css's single 48rem block. --%>
                  <div
                    :if={@game.gallery_urls != []}
                    id="gallery-thumbnails"
                    class="gap-2 overflow-x-auto pk-gallery-thumbnails"
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

                  <div :if={@game.gallery_urls != []} id="gallery-dots" class="pk-gallery-dots">
                    <button
                      :for={{url, idx} <- Enum.with_index(gallery_thumbnails(@game))}
                      type="button"
                      phx-click="select-image"
                      phx-value-url={url}
                      aria-label={"Ver imagen #{idx + 1} de #{length(gallery_thumbnails(@game))}"}
                      aria-current={(url == @selected_image && "true") || nil}
                      class={["pk-gallery-dot", (url == @selected_image && "is-active") || nil]}
                    >
                      <span class="pk-gallery-dot-mark"></span>
                    </button>
                  </div>
                </div>

                <%!-- G-01.2-19 task 1 (was G-01.2-10 task 2, ask #3):
                hidden below the detail layout breakpoint so the phone
                shows exactly one Reservar control (the fixed
                .pk-mobile-cta-bar below), revealed at/above it in the same
                48rem block where the bar itself becomes hidden — both
                halves of the invariant live in one place. Now a sibling
                AFTER the bordered/shadowed panel above, not a descendant
                of it, so it reads as a separate decision rather than a
                fourth carousel control. --%>
                <button
                  type="button"
                  phx-click="open-reservation"
                  class="btn btn-primary btn-lg min-h-11 w-full pk-poster-reserve"
                >
                  {reservation_cta_label()}
                </button>
              </div>

              <div class="pk-text-col">
                <h1 id="detail-title-block" class="font-display text-3xl">{@game.name}</h1>

                <%!-- G-01.2-10 task 3: the description sits immediately
                after the title with nothing in between (ask #2) — every
                element that used to be wedged here (weight-band badge,
                editorial hashtags) moved below the separator. --%>
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

                <%!-- Boundary between the primary reading block (title +
                description) and supplementary "more information" content
                (ask #4/#6). daisyUI's own divider component checked and
                used as-is for the line's colour/thickness (already
                theme-aware via color-mix, no hand-rolled rule needed for
                that); only its own default margin fought .pk-text-col's
                already-established 1rem flex gap (doubling the visible
                gap around the line), so .pk-divider neutralizes just that
                one property. Reused verbatim by 01.2-18 for the boundary
                before the recommendations shelf. --%>
                <div class="divider pk-divider" role="separator"></div>

                <GameChips.editorial_tags
                  tags={@game.tags}
                  href_fun={fn tag -> ~p"/?tags=#{tag}" end}
                />

                <%!-- D2 (recommended: keep the badge, relocate it here).
                Every literal ask is satisfied: nothing sits between title
                and description any more, the difficulty filter link
                survives, and the teaching sentence survives — the
                duplication with the facts row's own dificultad pill now
                reads as "summary pill up top, explanation further down"
                rather than the same thing twice in one block. --%>
                <.link :if={@game.weight_band} navigate={~p"/?weight_bands=#{@game.weight_band}"}>
                  <GameChips.weight_band_badge game={@game} show_descriptor={true} />
                </.link>

                <h2 :if={@mechanic_labels != []} class="pk-section-heading">Mecánicas</h2>
                <GameChips.chip_row
                  terms={@mechanic_labels}
                  limit={99}
                  href_fun={fn label -> ~p"/?mechanics=#{label}" end}
                />

                <h2 :if={@theme_labels != []} class="pk-section-heading">Temáticas</h2>
                <GameChips.chip_row
                  terms={@theme_labels}
                  limit={99}
                  href_fun={fn label -> ~p"/?themes=#{label}" end}
                />

                <%!-- G-01.2-10 task 3, ask #5: the publisher row is gone
                (unconditional, every viewport width) and ficha_tecnica?/1
                below narrowed from five fields to four — see that
                function's own comment. --%>
                <h2 :if={ficha_tecnica?(@game)} class="pk-section-heading">Ficha técnica</h2>
                <dl :if={ficha_tecnica?(@game)} class="pk-spec-list">
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

          <%!-- G-01.2-18 task 1: boundary between the detail content above
          and the recommendations shelf below, so a reader can tell the
          page has changed subject rather than reading the shelf as more of
          the masthead's own content. Second call site of 01.2-17's
          .pk-divider (see that rule's own comment); .pk-shelf-separator
          here only adds the width cap, reading the same
          --pk-detail-col-width token the masthead and the CTA bar's inner
          wrapper both read, so the line starts and ends level with the
          reading column above it. Renders on the loading pass too (the
          skeleton shelf reserves the real shelf's footprint, so the
          boundary must exist ahead of it as well, or it would pop in only
          once the connected mount replaces the skeleton) and, on the
          connected pass, is gated on the exact same emptiness the shelf
          itself checks — a boundary above an empty shelf is worse than no
          boundary at all. --%>
          <div
            :if={@loading or @similar_games != []}
            id="detail-shelf-separator"
            class="mx-auto w-full max-w-7xl pk-gutter"
          >
            <div class="divider pk-divider pk-shelf-separator" role="separator"></div>
          </div>

          <%!-- 01.1-07: skeleton shelf while @loading (disconnected pass) —
          reserves the shelf's own footprint so nothing jumps once the
          connected mount replaces it with real (or, if there are none,
          absent) content. --%>
          <CarouselRow.skeleton_row :if={@loading} id="similares-skeleton" />
          <CarouselRow.carousel_row
            :if={!@loading}
            id="similares"
            title="Juegos similares"
            badge={if @similares_widened, do: "Ampliado"}
            games={Enum.map(@similar_games, &{"similares-#{&1.id}", &1})}
            subtitle={@similares_subtitle}
            empty={@similar_games == []}
            row_key="similares"
            exhausted={true}
          />
        </div>

        <%!-- G-01.2-18 task 2: the bar's own second row (a stacked share
        control duplicating the poster's corner share icon) is gone — the
        reserve button is now the wrapper's only child. .pk-cta-bar-inner
        itself stays (see its own comment in app.css: it survives for the
        alignment cap, not for the stacking it was introduced for). --%>
        <div id="detail-cta-bar" class="pk-mobile-cta-bar">
          <div class="mx-auto w-full max-w-7xl pk-gutter">
            <div class="pk-cta-bar-inner">
              <button
                type="button"
                phx-click="open-reservation"
                class="btn btn-primary min-h-11 w-full"
              >
                {reservation_cta_label()}
              </button>
            </div>
          </div>
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

        <%!-- Reservation modal (SHELL-03, D-09/D-10, plan 01.1-05): pure
        daisyUI .modal/.modal-open/.modal-box/.modal-backdrop classes — no
        .pk-* CSS needed, daisyUI's own modal is already the highest
        z-index (999) in this page's overlay stack. Focus-trap/Escape reuse
        .Lightbox's exact pattern above (T-01.1-16-style single mechanism,
        not a second bespoke one). Server builds the wa.me link entirely —
        reservation_url/3 below, never client-assembled (mirrors
        .ShareButton's own T-01.1-08 rule). --%>
        <div
          :if={@reservation_open}
          id="reservation-modal"
          class="modal modal-open"
          role="dialog"
          aria-modal="true"
          aria-labelledby="reservation-modal-title"
          phx-hook=".ReservationModal"
        >
          <script :type={Phoenix.LiveView.ColocatedHook} name=".ReservationModal">
            export default {
              mounted() {
                this.el.querySelector("input, a, button")?.focus()

                this.onKeydown = (e) => {
                  if (e.key === "Escape") {
                    this.pushEvent("close-reservation", {})
                    return
                  }
                  if (e.key !== "Tab") return
                  const focusable = this.el.querySelectorAll(
                    'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
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
          <div class="modal-box">
            <button
              type="button"
              phx-click="close-reservation"
              aria-label="Cerrar"
              class="btn btn-circle btn-ghost btn-sm absolute right-2 top-2"
            >
              <.icon name="hero-x-mark" class="size-5" />
            </button>
            <h3 id="reservation-modal-title" class="font-display text-xl pr-8">
              {reservation_cta_label()}
            </h3>

            <p :if={is_nil(@reservation_number)} class="text-sm text-neutral mt-4">
              La reserva no está disponible por el momento. Escribinos directamente para coordinar.
            </p>

            <div :if={@reservation_number}>
              <div
                :if={@reservation_name == "" or @reservation_error}
                class="mt-4"
              >
                <form phx-submit="reserve">
                  <.input
                    type="text"
                    id="reservation-nombre"
                    name="nombre"
                    label="Tu nombre"
                    value={@reservation_name}
                    placeholder="¿Cómo te llamás?"
                    required
                    maxlength="60"
                    phx-blur="validate-reservation"
                    errors={if @reservation_error, do: [@reservation_error], else: []}
                  />
                  <button type="submit" class="btn btn-primary min-h-11 w-full mt-2">
                    Continuar
                  </button>
                </form>
              </div>

              <div
                :if={@reservation_name != "" and is_nil(@reservation_error)}
                class="mt-4 space-y-3"
              >
                <p class="text-sm text-base-content">
                  {reservation_message(@reservation_name, @game.name)}
                </p>
                <a
                  href={reservation_url(@reservation_number, @reservation_name, @game.name)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-primary min-h-11 w-full"
                >
                  Abrir WhatsApp
                </a>
              </div>
            </div>
          </div>
          <div class="modal-backdrop" phx-click="close-reservation"></div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Shared by both reservation CTAs (buy-box and mobile bar) so the label
  # string exists in exactly one place in the source and can never drift
  # between the two surfaces.
  defp reservation_cta_label, do: "Reservar para el sábado"

  # D-09/D-10 framing: asks the club to have the game set up at the next
  # Saturday session — never to lend/take it home. Approved verbatim at the
  # 01.1-05 checkpoint; see 01.1-05-SUMMARY.md for the decision record.
  defp reservation_message(name, game_name) do
    "¡Hola! Soy #{name} y quiero reservar #{game_name} para jugarlo el próximo sábado en el club."
  end

  # Built entirely server-side (T-01.1-02) — URI.encode_www_form/1 percent-
  # (or +-)encodes the visitor's name so it cannot break out of the `text=`
  # query parameter, superseding 01.1-RESEARCH.md's client-side
  # encodeURIComponent suggestion with a strictly stronger mitigation.
  defp reservation_url(number, name, game_name) do
    "https://wa.me/" <> number <> "?text=" <> URI.encode_www_form(reservation_message(name, game_name))
  end

  @doc false
  attr :id, :string, required: true
  attr :game, Game, required: true

  # Shared by the buy-box column (the mobile CTA bar's own copy was removed
  # in G-01.2-18 task 2) so a future second call site can never drift from
  # this one. Native Web Share API first (.ShareButton hook); the fallback
  # popover's WhatsApp/X intent hrefs and the copy-link target are built
  # server-side in HEEx with URI.encode_www_form/1 — no client-side URL
  # assembly (T-01.1-08).
  #
  # G-01.2-18 task 2: this component briefly carried a `variant` attribute
  # (Phase 01.2 gap-closure, G-01.2-6) so the buy-box panel and the mobile
  # CTA bar could render two different shapes for the same trigger — a
  # bordered circle on the panel (sketch 027) vs a full-width labelled pill
  # in the bar (sketch 028). With the bar's own copy removed, only the
  # panel's bordered-circle shape remains: the attribute, the conditional
  # visible "Compartir" label, the conditional `aria-label`, and the
  # class-per-variant helper behind them all collapsed back to one shape
  # rather than being kept "in case" a second call site returns.
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
        class="pk-share-trigger min-h-11 min-w-11"
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

  # D-04/D-05 (01.2-04): the UI-SPEC `zero-one-many` backstop for Ficha
  # técnica — the section (heading + list) renders only when at least one
  # of the four remaining carriable fields is present, so a minimal-data
  # game never shows a bare heading over an empty grid. Every field read
  # here is present on every %Game{} (two integers, one array column with
  # `default: []`, one nullable integer) — no nil-dereference path exists.
  # Narrowed from five fields to four in the G-01.2-10 mobile masthead
  # rework (01.2-17): the publisher-name clause was dropped in the same
  # edit as the spec-row it guarded — the two must move together, or a
  # game whose only remaining data was that field re-opens the exact
  # empty-heading hole this guard exists to close.
  defp ficha_tecnica?(game) do
    not is_nil(game.min_age) or
      not is_nil(game.year_published) or
      game.designers != [] or
      not is_nil(game.bgg_id)
  end

  # Subtitle for the Juegos similares shelf — reuses Vocabulary.weight_band/1's
  # existing plain-Spanish descriptor label rather than authoring new copy
  # (01.1-03 checkpoint decision).
  # 01.1-07: mirrors CatalogLive.Index's safe_filter_games/1 shape — a
  # failure in the "more like this" row must never take down a detail page
  # whose primary content already loaded fine. carousel_row/1's own
  # :if={@games != []} guard already renders nothing for an empty list,
  # which is the correct minimal outcome for a supplementary row: no error
  # banner for a shelf that is not the page's primary content.
  defp safe_similar_games(game) do
    Catalog.similar_games(game)
  rescue
    _error -> []
  end

  # G-01.2-7 / sketch 031: similares_subtitle/1 became similares_subtitle/2,
  # taking the widened? flag alongside the game. A widened shelf (including
  # every no-band game, which is always widened per Catalog.similar_games/1's
  # new contract) gets sketch 031's copy; a true same-band shelf keeps
  # exactly the copy it returned before this plan.
  defp similares_subtitle(_game, true), do: "Otras opciones que te van a encantar"
  defp similares_subtitle(%{weight_band: nil}, false), do: nil

  defp similares_subtitle(game, false) do
    case Vocabulary.weight_band(game.weight_band) do
      nil -> nil
      band -> "Otros juegos del mismo nivel: " <> band.label
    end
  end
end
