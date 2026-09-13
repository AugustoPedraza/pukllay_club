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

  `handle_event("select-image", ...)` swaps the page's own main image only
  when the client-supplied `url` is a member of the game's own
  `[cover_url | gallery_urls]` list — a crafted url is never echoed
  unchecked into an `img src` (T-01-26). The lightbox (`handle_event(
  "open-lightbox"/"close-lightbox"/"select-lightbox-image", ...)`) has its
  OWN selection assign, `@lightbox_image`, seeded from the page's current
  selection when it opens and never synced back when it closes —
  navigating inside the open lightbox must never move the page's own
  poster image, thumbnail border or dot underneath it (G-01.2-25,
  diagnosed in
  `.planning/debug/G-01.2-16-lightbox-scrim-width-carousel-sync.md`). This
  supersedes the earlier "there is a single guarded image-selection path,
  not a second one" contract (T-01.1-16, 01.1-04): that contract literally
  shared ONE assign between the page and the lightbox, which is exactly
  why the lightbox's own chevrons visibly dragged the underlying
  gallery/dots along with them. What survives from T-01.1-16 is narrower
  and still true: there is exactly one membership whitelist
  (`valid_gallery_image?/2`), called by both `select-image` and
  `select-lightbox-image` — two selection assigns, one shared guard.

  Every field from this plan's `<planner_assumption>` omission table is
  individually conditional: an absent field removes its whole row/element,
  never a blank placeholder. The reading column's supplementary content
  (01.3-07, closing UAT gap G-01.3-1) is split across two independently
  guarded blocks instead of one "ficha técnica" section: a single unheaded
  fact grid (`fact_grid?/3` — year, plus Diseñadores/Ilustradores/Mecánicas/
  Temáticas as a two-column `.pk-fact-cols` grid, each column its own `:if`)
  and a separate Comunidad BGG block (`comunidad_bgg?/1` — weight/rating/
  rank, each independently gated, plus a Fuente link). Neither block ever
  renders an empty heading over an empty grid — `fact_grid?/3` and
  `comunidad_bgg?/1` are each the disjunction of every field their own block
  can show, exactly as `ficha_tecnica?/1` used to guard the single merged
  section this replaces. The publisher-name field this section used to
  carry was dropped entirely in the G-01.2-10 mobile masthead rework
  (01.2-17) — the UAT called it useless information, and the removal is
  unconditional (every viewport width), not a mobile-only cut. The minimum-
  age row was dropped in this same 01.3-07 restructure (UAT gap G-01.3-1
  item 2) — `min_age` remains a live schema field and a live `?min_age=`
  filter param, only its render site on this page is gone.

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
     # G-01.2-25 task 2: the lightbox's own selection, initialised the same
     # way the page's is. Never read until "open-lightbox" reseeds it from
     # @selected_image — this default only matters for the always-rendered
     # (but closed/hidden) lightbox's very first static render.
     |> assign(:lightbox_image, game.cover_url)
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
     |> assign(:reservation_error, nil)
     # Header search-morph open/closed state (01.2-11 contract). Always
     # closed on arrival — unlike CatalogLive.Index there is no ?q= on this
     # URL to seed it from.
     |> assign(:search_expanded, false)}
  end

  # Quick task 260913-2x6 (T-2x6-04): the live-navigation half of the same
  # canonicalization contract `PukllayClubWeb.Plugs.GameSEO` enforces over
  # HTTP. Live navigation to a non-canonical id (e.g. a patch from within
  # this same LiveView) never issues a fresh HTTP request, so the plug
  # never runs — this handler is the only thing that can correct it.
  #
  # Must be `handle_params`, not `mount/3` — LiveView raises if
  # `push_patch/2` is called during `mount/3`. Compares `id` against
  # `Phoenix.Param.to_param/1` (the SAME canonical-param source the plug
  # uses) with exact string equality; a match is a no-op. A mismatch
  # issues a `replace: true` patch to the canonical path, so the browser's
  # history entry is corrected in place rather than growing a new one. The
  # patched navigation re-enters `handle_params/3` with the now-canonical
  # id, which takes the no-op branch — this cannot loop.
  @impl true
  def handle_params(%{"id" => id}, uri, socket) do
    canonical_id = Phoenix.Param.to_param(socket.assigns.game)

    if id == canonical_id do
      {:noreply, socket}
    else
      {:noreply, push_patch(socket, to: canonical_path(socket.assigns.game, uri), replace: true)}
    end
  end

  defp canonical_path(game, uri) do
    case URI.parse(uri).query do
      query when query in [nil, ""] -> ~p"/juegos/#{game}"
      query -> ~p"/juegos/#{game}" <> "?" <> query
    end
  end

  # header_inner/1 renders `.pk-search-morph.is-open` ONLY from this page's
  # :search_expanded assign (01.2-11: no client JS toggles the class), and
  # its toggle/close buttons dispatch open-search/close-search. These two
  # clauses must therefore really flip the assign, exactly like
  # CatalogLive.Index's. They used to be `{:noreply, socket}` no-ops next to
  # a hardcoded `search_expanded={false}`: that avoided a crash, but left the
  # detail page's search input permanently collapsed (width 0, opacity 0,
  # pointer-events none) at every viewport — tapping the icon did nothing
  # (debug search-broken-on-mobile-detail). What stays different from Index
  # is only the slot's CONTENT: a plain native GET form to "/", submitted by
  # the browser, so no search/filter event exists here.
  @impl true
  def handle_event("open-search", _params, socket), do: {:noreply, assign(socket, :search_expanded, true)}

  @impl true
  def handle_event("close-search", _params, socket), do: {:noreply, assign(socket, :search_expanded, false)}

  # CarouselRow's .CarouselScroll hook pushes `carousel-load-more` from the
  # rail's own scroll listener on ANY page that renders a carousel row —
  # this page's "Juegos similares" shelf included. Today the push is
  # client-guarded: this page passes `exhausted={true}`, which the hook
  # reads into `this.exhausted` and early-returns on, so the event never
  # actually leaves the browser. That guard is a single template attribute,
  # and without this clause the server has nothing behind it — exactly the
  # gap the open-search/close-search no-ops above exist to close.
  #
  # This is NOT a no-op stand-in: replying `exhausted: true` is the truthful
  # answer here. The shelf is a fixed, already-complete `similar_games/1`
  # result with no paging behind it, so "load more" genuinely has nothing to
  # load. The reply shape matches what the hook consumes (`if (reply &&
  # reply.exhausted) this.exhausted = true`) and what CatalogLive.Index's own
  # handler returns for an exhausted row, so a client that ignores
  # data-exhausted and fires anyway is told to stop instead of crashing the
  # page. `_params` rather than `%{"row" => _}`: the whole point of this
  # clause is that no payload shape may reach handle_event/3 unmatched.
  @impl true
  def handle_event("carousel-load-more", _params, socket) do
    {:reply, %{exhausted: true}, socket}
  end

  @impl true
  def handle_event("select-image", %{"url" => url}, socket) do
    if valid_gallery_image?(socket.assigns.game, url) do
      {:noreply, assign(socket, :selected_image, url)}
    else
      {:noreply, socket}
    end
  end

  # G-01.2-25 task 2: the lightbox's OWN selection event, distinct from the
  # page's "select-image" above. Assigns only @lightbox_image — the page's
  # poster, thumbnail border and dot (all readers of @selected_image) never
  # move while the lightbox is open. Guarded by the SAME
  # valid_gallery_image?/2 predicate "select-image" uses (T-01.2-25-01): one
  # whitelist, two callers, never a second one written fresh for this
  # handler.
  @impl true
  def handle_event("select-lightbox-image", %{"url" => url}, socket) do
    if valid_gallery_image?(socket.assigns.game, url) do
      {:noreply, assign(socket, :lightbox_image, url)}
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
        # G-01.2-25 task 2: seed the lightbox's own selection from whatever
        # the page is currently showing, so it opens on the image the
        # visitor was looking at. Re-seeded on every open, not just the
        # first — closing without syncing back (see close-lightbox below)
        # means a stale @lightbox_image from a prior visit must never leak
        # into the next open.
        socket
        |> assign(:lightbox_image, socket.assigns.selected_image)
        |> assign(:lightbox_open, true)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("close-lightbox", _params, socket) do
    # G-01.2-25 task 2: deliberately does NOT sync @lightbox_image back
    # onto @selected_image. The diagnosed gap was that navigating inside
    # the open lightbox moved the page's own selection underneath it;
    # syncing back on close would reintroduce that exact defect, only
    # delayed by one interaction (close). Answered conservatively as NO —
    # see the module doc's two-selection paragraph. If a later round wants
    # the lightbox's last-viewed image to become the page's, that is a
    # designed decision with its own UAT item, not an implementation
    # detail to slip in here.
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
  #
  # The params key is "value", NOT "nombre", and that is load-bearing. A
  # `phx-blur` is not a form event: nothing serializes the <form>, so the
  # input's `name="nombre"` never reaches the payload. LiveView's client
  # builds a blur payload with `extractMeta`
  # (deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js) — every
  # `phx-value-*` attribute, PLUS the element's native `.value` under the
  # key "value" for any non-<form> element that has one. This input carries
  # no `phx-value-*` attributes, so "value" is the ONLY key that arrives.
  #
  # This is the mirror image of the trap documented in filter_modal.ex's
  # moduledoc: there, extractMeta's unconditional `meta.value = el.value`
  # CLOBBERED an intended `phx-value-value` binding; here that same line is
  # the only reason we get a payload at all. Do NOT "tidy" this pattern
  # back to `%{"nombre" => name}` to match the input's name attribute —
  # that mismatch crashed the LiveView on every blur in prod (Sentry
  # ELIXIR-1, diagnosed in
  # `.planning/debug/resolved/catalog-show-no-clause.md`), and `mix test`
  # cannot catch it from markup alone: LiveViewTest builds the params map
  # in the test process and never runs `extractMeta`, so only a test that
  # pins this exact payload shape (catalog_show_test.exs) guards it.
  #
  # `reserve` below deliberately keeps `%{"nombre" => name}` — it IS a real
  # `phx-submit` on the <form>, so it genuinely receives serialized form
  # params.
  @impl true
  def handle_event("validate-reservation", %{"value" => name}, socket) do
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

  defp reservation_name_error(""), do: "Falta tu nombre."

  defp reservation_name_error(name) do
    if String.length(name) > 60 do
      "Ese nombre es muy largo."
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- active_nav={nil} passed explicitly, not defaulted into: Detalle is a
    drill-down of the catalog and a peer of neither top-level nav entry
    (sketch 017's own page switcher marks no drawer link active here). --%>
    <Layouts.app
      flash={@flash}
      fullbleed
      sticky
      search_expanded={@search_expanded}
      active_nav={nil}
      boundary_collapse
    >
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
                //
                // No viewport-width check here (G-01.2-24 task 1): the
                // stylesheet already hides #detail-title-echo at and above
                // the 48rem detail-layout breakpoint (app.css's single
                // block that owns every mobile-vs-desktop swap on this
                // page). Toggling a class on an element the stylesheet is
                // not rendering is inert — a pixel/rem literal here would
                // just be a second declaration of a value the stylesheet
                // already owns once.
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
          <div class="mx-auto w-full max-w-7xl pk-gutter pk-title-echo-inner">
            <span class="pk-title-echo-name">{@game.name}</span>
            <button
              type="button"
              data-scroll-top
              aria-label="Volver arriba"
              class="pk-scroll-top min-h-11 min-w-11"
            >
              <.icon name="hero-arrow-up" class="size-4" />
            </button>
          </div>
        </div>

        <div class="space-y-4">
          <div id="detail-masthead-wrap" class="mx-auto w-full max-w-7xl pk-gutter">
            <div class="pk-detail-masthead">
              <div class="pk-poster-col">
                <div class="pk-poster-panel">
                  <%!-- G-01.2-19 task 1 (was G-01.2-10 task 2): one facts
                  row exists on the page, above the poster photo, at every
                  viewport width — the mobile absolute overlay and the
                  desktop inline copy are gone. Its own root already
                  carries pk-facts-row, so no wrapper div is added.
                  G-01.2-23 task 2 (round 3, sketch 037): moved from being
                  the poster COLUMN's first child to being the poster
                  PANEL's first child — the row's position relative to the
                  photo is unchanged (the UAT approved it: "the pills are
                  ok on the position"), only its containing box changed.
                  Inside the panel, the pills now share the exact 1rem card
                  padding the photo already had, so the pills and the
                  photo's left/right edges coincide and the phone's buy-box
                  reads as one card with one edge instead of two floating
                  pieces. Addressed in CSS as a direct child of
                  .pk-poster-panel (.pk-poster-panel > .pk-facts-row). See
                  G-01.2-11/G-01.2-12 and sketch 032, and G-01.2-23 and
                  sketch 037 for this move. --%>
                  <GamePreview.facts_row game={@game} linked={true} />

                  <div class="pk-poster-frame">
                    <div class="absolute right-3 top-3 z-10">
                      <.share_control id="detail-share-buybox" game={@game} />
                    </div>

                    <button
                      :if={@selected_image}
                      id="detail-lightbox-trigger"
                      type="button"
                      phx-click="open-lightbox"
                      aria-label="Ampliar imagen del juego"
                      class="pk-card-poster overflow-hidden rounded-box bg-base-300 block w-full min-h-11 cursor-zoom-in"
                    >
                      <img
                        src={@selected_image}
                        alt={@game.name}
                        class="pk-poster-img js-cover-fallback"
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
                  against the page's own @selected_image assign, sharing the
                  same membership-check whitelist (valid_gallery_image?/2).
                  The lightbox has since gained its OWN separate selection
                  and event (@lightbox_image / select-lightbox-image,
                  G-01.2-25) — but these two strips still drive one
                  page-level assign between them, not two. Exactly one of
                  the two renders per viewport, swap declared in app.css's
                  single 48rem block. --%>
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
                <%!-- Sketch 042 (27 rounds): the title is its own reading
                section (always renders, no :if — the wrapper only ever
                needs one for a conditional child). --%>
                <div class="pk-reading-section">
                  <h1 id="detail-title-block" class="font-display text-3xl">{@game.name}</h1>
                </div>

                <%!-- Sketch 042's winner: hashtags sit right after the
                title, before the description — NOT between the description
                and a divider as the UAT text itself suggested (see this
                plan's <planner_note> departure #1). The divider sketch 042
                removed entirely is gone from this page: once sketch 040
                dropped every section heading, rhythm alone was already
                doing all the separating work the line used to help with.
                class="pk-rhythm-8" (not pk-reading-section) ties this row
                tightly to the title via .pk-text-col's own child-margin
                rhythm rule, not the section gap. --%>
                <GameChips.editorial_tags
                  tags={@game.tags}
                  href_fun={fn tag -> ~p"/?tags=#{tag}" end}
                  class="pk-rhythm-8"
                />

                <%!-- G-01.2-10 task 3 / 01.3-08 / 01.3-10 (gap closure
                G-01.3-4): description wrapper's spacing class is its own
                pk-rhythm-16 section. ONE paragraph and ONE sibling toggle
                button, both driven by @description_expanded — the toggle
                is never nested inside the paragraph, in either state,
                which is what fixes G-01.3-4 (see .pk-desc-toggle's own
                CSS comment for why). This is still the LiveView-native
                equivalent of sketch 042's JS DOM-relocation
                (description-truncation.md): server-owned state renders
                the right markup directly, with no client-side node move
                and no colocated hook. Do not restore the sketch's JS
                relocation function here; it solved a problem (no
                server-side state to render from) that does not exist in
                this app. --%>
                <div :if={@game.description} class="pk-reading-section pk-rhythm-16">
                  <div class={["pk-desc-shell", @description_expanded && "is-expanded"]}>
                    <p
                      class={["pk-desc", !@description_expanded && "is-clamped"]}
                      id="game-description"
                    >
                      {@game.description}
                    </p>
                    <button
                      type="button"
                      phx-click="toggle-description"
                      class="pk-desc-toggle min-h-11 min-w-11"
                      aria-controls="game-description"
                      aria-expanded={to_string(@description_expanded)}
                      aria-label={if @description_expanded, do: "Ver menos", else: "Ver más"}
                    >
                      <.icon
                        name={
                          if @description_expanded, do: "hero-chevron-up", else: "hero-chevron-down"
                        }
                        class="pk-desc-toggle-icon"
                      />
                    </button>
                  </div>
                </div>

                <%!-- G-01.2-20 task 1 (was D2's "keep the badge, relocate it
                here"): the badge block and its explanatory sentence are
                gone — the next UAT pass reversed the prior round's
                keep-decision ("still it shows its 'category' pills with a
                description(remove it)"). The dificultad fact now appears
                exactly once, in the facts row above the poster
                (`GamePreview.facts_row/1`, `linked={true}`), which also
                inherited this badge's filter-link target
                (`?weight_bands=`). The weight-band badge component itself
                is kept with zero call sites — see its own doc comment
                (in `GameChips`) for why. --%>

                <%!-- Sketch 040: one unheaded fact grid replaces the old
                Mecánicas/Temáticas headed sections and the creators half of
                ficha técnica — no <h2> anywhere in this block, the grid's
                own <dt> labels carry that job now. fact_grid?/3 gates the
                whole block on the same zero-one-many backstop
                ficha_tecnica?/1 used to apply, widened across two derived
                assigns (mechanic_labels/theme_labels) as well as the
                struct. Minimum age (UAT gap G-01.3-1 item 2) has no render
                site anywhere in this block or this page — the field and
                its ?min_age= filter param remain live, only the row is
                gone. --%>
                <div
                  :if={fact_grid?(@game, @mechanic_labels, @theme_labels)}
                  class="pk-reading-section pk-rhythm-16"
                >
                  <dl class="pk-spec-list">
                    <div :if={@game.year_published} class="pk-spec-row">
                      <dt>Año</dt>
                      <dd>{@game.year_published}</dd>
                    </div>

                    <div class="pk-fact-cols">
                      <%!-- Sketch 039: Diseñadores/Ilustradores become
                      filter-linked pills, matching every other structured
                      fact on the page, instead of comma-joined plain text.
                      creator_pills/1 (below share_control/1) renders them;
                      the ~p sigil percent-encodes the interpolated name, so
                      a space- or accent-bearing name never needs manual
                      encoding. --%>
                      <div :if={@game.designers != []} class="pk-fact-col">
                        <dt>Diseñadores</dt>
                        <dd>
                          <.creator_pills
                            names={@game.designers}
                            href_fun={fn name -> ~p"/?designers=#{name}" end}
                          />
                        </dd>
                      </div>

                      <div :if={@game.artists != []} class="pk-fact-col">
                        <dt>Ilustradores</dt>
                        <dd>
                          <.creator_pills
                            names={@game.artists}
                            href_fun={fn name -> ~p"/?artists=#{name}" end}
                          />
                        </dd>
                      </div>

                      <div :if={@mechanic_labels != []} class="pk-fact-col">
                        <dt>Mecánicas</dt>
                        <dd>
                          <GameChips.chip_row
                            terms={@mechanic_labels}
                            limit={99}
                            href_fun={fn label -> ~p"/?mechanics=#{label}" end}
                          />
                        </dd>
                      </div>

                      <div :if={@theme_labels != []} class="pk-fact-col">
                        <dt>Temáticas</dt>
                        <dd>
                          <GameChips.chip_row
                            terms={@theme_labels}
                            limit={99}
                            href_fun={fn label -> ~p"/?themes=#{label}" end}
                          />
                        </dd>
                      </div>
                    </div>
                  </dl>
                </div>

                <%!-- Sketch 039 (with departure #2/#3 from this plan's
                <planner_note> — each stat keeps its own BGG link per D-06,
                and the "BGG" qualifier moves to the group label instead of
                repeating on every row). comunidad_bgg?/1 gates on the same
                fields advanced_stats?/1 already checks plus bgg_id itself,
                so a game with a bgg_id but no populated stat still shows
                the group (label + Fuente line), and a game with neither
                shows nothing. --%>
                <div :if={comunidad_bgg?(@game)} class="pk-reading-section pk-rhythm-32">
                  <div class="pk-bgg-label">Comunidad BGG</div>
                  <div class="pk-bgg-row">
                    <a
                      :if={@game.bgg_rating}
                      href={"https://boardgamegeek.com/boardgame/#{@game.bgg_id}"}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="pk-bgg-stat"
                    >
                      <span class="pk-bgg-num">{format_bgg_rating(@game.bgg_rating)}</span>
                      <span class="pk-bgg-lbl">Valoración</span>
                    </a>

                    <a
                      :if={@game.bgg_weight}
                      href={"https://boardgamegeek.com/boardgame/#{@game.bgg_id}"}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="pk-bgg-stat"
                    >
                      <span class="pk-bgg-num">{format_bgg_weight(@game.bgg_weight)}</span>
                      <span class="pk-bgg-lbl">Peso</span>
                    </a>

                    <%!-- D-06: a game BGG has never ranked simply omits
                    this stat via the :if guard below — no placeholder. The
                    literal `#` is a plain character (this template sigil
                    performs no Elixir string interpolation) immediately
                    followed by the template engine's own `{...}`
                    interpolation. --%>
                    <a
                      :if={@game.bgg_rank}
                      href={"https://boardgamegeek.com/boardgame/#{@game.bgg_id}"}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="pk-bgg-stat"
                    >
                      <span class="pk-bgg-num">#{@game.bgg_rank}</span>
                      <span class="pk-bgg-lbl">Ranking</span>
                    </a>
                  </div>

                  <p :if={@game.bgg_id} class="pk-bgg-foot">
                    Fuente:
                    <a
                      href={"https://boardgamegeek.com/boardgame/#{@game.bgg_id}"}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="link link-primary"
                    >
                      BoardGameGeek
                    </a>
                  </p>
                </div>
              </div>
            </div>
          </div>

          <%!-- G-01.2-18 task 1: boundary between the detail content above
          and the recommendations shelf below, so a reader can tell the
          page has changed subject rather than reading the shelf as more of
          the masthead's own content. This is the ONLY divider left
          anywhere on the detail page (01.3-07 removed the reading
          column's own — see this plan's <planner_note> departure #1).
          G-01.2-19 task 2 removed the width-cap class this line used
          to carry — this wrapper already shares the shell's own
          mx-auto/w-full/max-w-7xl/pk-gutter recipe with the masthead and
          the CTA bar's inner wrapper, so no per-element width override is
          needed for the line to start and end level with both. Renders on
          the loading pass too (the skeleton shelf reserves the real
          shelf's footprint, so the boundary must exist ahead of it as
          well, or it would pop in only once the connected mount replaces
          the skeleton) and, on the connected pass, is gated on the exact
          same emptiness the shelf itself checks — a boundary above an
          empty shelf is worse than no boundary at all. --%>
          <div
            :if={@loading or @similar_games != []}
            id="detail-shelf-separator"
            class="mx-auto w-full max-w-7xl pk-gutter"
          >
            <div class="divider pk-divider" role="separator"></div>
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

        <%!-- G-01.2-21 task 2: always rendered now (no `:if`) — state lives in
        the `is-open` class + aria-hidden, not in whether this element
        exists, which is what lets the open/close transition below actually
        transition (there is no closed DOM state to fade from/to on a
        conditionally-rendered element). The image itself keeps its own
        `:if` so a game with no selected image renders an empty, hidden
        container rather than an <img> with no src. --%>
        <div
          id="detail-lightbox"
          class={["pk-lightbox", @lightbox_open && "is-open"]}
          role="dialog"
          aria-modal="true"
          aria-label="Imágenes del juego"
          aria-hidden={to_string(!@lightbox_open)}
          phx-hook=".Lightbox"
        >
          <script :type={Phoenix.LiveView.ColocatedHook} name=".Lightbox">
            export default {
              mounted() {
                // The element is always present now, so mount only ever
                // observes the closed state (lightbox_open defaults false
                // before first mount) — this deliberately does NOT focus
                // anything on mount, which would otherwise steal focus on
                // every page load.
                this.wasOpen = false
                this.syncFocusOnOpenChange()

                this.onKeydown = (e) => {
                  // Inert-while-closed guard: a stray key event (this
                  // listener lives on an element that is always in the DOM)
                  // must never act on a hidden overlay.
                  if (!this.el.classList.contains("is-open")) return

                  if (e.key === "Escape") {
                    this.pushEvent("close-lightbox", {})
                    return
                  }
                  // Arrow keys click the SAME chevron buttons the pointer
                  // already uses — no url is computed here and no event is
                  // pushed, so the keyboard route goes through the exact
                  // same select-image handler and membership whitelist as
                  // the buttons (T-01.2-21-01), never a second selection
                  // path.
                  if (e.key === "ArrowLeft") {
                    this.el.querySelector("[data-lightbox-prev]")?.click()
                    return
                  }
                  if (e.key === "ArrowRight") {
                    this.el.querySelector("[data-lightbox-next]")?.click()
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
                this.syncFocusOnOpenChange()
              },
              // Single routine driving focus off a state TRANSITION (not
              // the current state alone), called from both mounted() and
              // updated() so it never runs twice for the same transition
              // and never runs on an unrelated re-render.
              syncFocusOnOpenChange() {
                const isOpen = this.el.classList.contains("is-open")
                if (isOpen && !this.wasOpen) {
                  this.el.querySelector("[data-lightbox-close]")?.focus()
                } else if (!isOpen && this.wasOpen) {
                  document.getElementById("detail-lightbox-trigger")?.focus()
                }
                this.wasOpen = isOpen
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
          <%!-- Arrow-anchoring decision, SUPERSEDED (G-01.2-21 -> G-01.2-28
          task 2): the previous round anchored both chevrons to the
          browser's own edge (left-4/right-4) rather than the shell's
          content edge, for three reasons. Two survive here, one does not.
          (1) survives, differently: no wrapper element was needed then,
          and none is needed now either — both buttons read
          --pk-shell-content-width directly (see .pk-lightbox-chevron-prev/
          -next in app.css) instead of sitting inside a bounds element.
          (2) survives outright: at phone widths these buttons barely move,
          so the 44px touch targets stay clear of the photo's own tap area
          exactly as before. (3) did not survive: "no complaint recorded"
          stopped being true when the user asked for shell-width arrows
          twice, in UAT tests 12 and 17 — the original decision itself
          named that as the condition for reopening it, and the condition
          fired. The values themselves live in app.css, not here. --%>
          <button
            :if={length(gallery_thumbnails(@game)) > 1}
            type="button"
            data-lightbox-prev
            phx-click="select-lightbox-image"
            phx-value-url={lightbox_neighbor(@game, @lightbox_image, -1)}
            aria-label="Imagen anterior"
            class="pk-lightbox-chevron pk-lightbox-chevron-prev btn btn-circle min-h-11 min-w-11 absolute top-1/2 -translate-y-1/2"
          >
            <.icon name="hero-chevron-left" class="size-5" />
          </button>
          <img
            :if={@lightbox_image}
            src={@lightbox_image}
            alt={@game.name}
            class="pk-lightbox-img"
          />
          <button
            :if={length(gallery_thumbnails(@game)) > 1}
            type="button"
            data-lightbox-next
            phx-click="select-lightbox-image"
            phx-value-url={lightbox_neighbor(@game, @lightbox_image, 1)}
            aria-label="Imagen siguiente"
            class="pk-lightbox-chevron pk-lightbox-chevron-next btn btn-circle min-h-11 min-w-11 absolute top-1/2 -translate-y-1/2"
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
              Las reservas están cerradas por ahora. Escribinos y lo coordinamos.
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
                    Seguir
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
                  Mandar por WhatsApp
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
  # Saturday session — never to lend/take it home. That FRAMING is the part
  # 01.1-05 approved (see 01.1-05-SUMMARY.md for the decision record) and it is
  # unchanged here; the wording was loosened afterwards to drop the stilted
  # "para jugarlo el próximo". Unlike everything else in this modal, this string
  # is not UI chrome — it is the message a member actually SENDS to the club, so
  # re-read it end to end before touching it again.
  defp reservation_message(name, game_name) do
    "¡Hola! Soy #{name}, quiero reservar #{game_name} para el sábado en el club."
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
    # `#{assigns.game}` (the struct, not `.id`) — quick task 260913-2x6:
    # routes through the one `Phoenix.Param` impl on `Game` so the share
    # URL carries the id-slug form.
    assigns = assign(assigns, :share_url, url(~p"/juegos/#{assigns.game}"))

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

  # Sketch 039 (01.3-07): Diseñadores/Ilustradores render as filter-linked
  # pills, matching every other structured fact on the page, instead of the
  # comma-joined plain text they used to be. `href_fun` mirrors
  # `GameChips.chip_row/1`'s own contract (a 1-arity function from the term
  # to a navigate target) — kept as a separate component rather than
  # reusing `chip_row/1` because these two rows carry raw creator names
  # (not `Vocabulary`-derived labels) and the outline tone/no-overflow-cap
  # shape is specific to this fact grid. The `~p` sigil percent-encodes the
  # interpolated name, so a space- or accent-bearing value never needs
  # manual encoding before it reaches the query string (T-01.3-07-01).
  attr :names, :list, required: true
  attr :href_fun, :any, required: true

  defp creator_pills(assigns) do
    ~H"""
    <div class="pk-chip-row flex flex-wrap gap-2">
      <.link
        :for={name <- @names}
        navigate={@href_fun.(name)}
        class="pk-pill pk-pill-outline pk-pill-interactive"
      >
        {name}
      </.link>
    </div>
    """
  end

  # `cover_url` first so it's always the initial thumbnail/main image when
  # present; nils filtered so an absent cover never mints a broken `<img>`.
  defp gallery_thumbnails(game) do
    Enum.reject([game.cover_url | game.gallery_urls], &is_nil/1)
  end

  # T-01.2-25-01: the single membership whitelist both "select-image" (the
  # page's own selection) and "select-lightbox-image" (the lightbox's own,
  # G-01.2-25) call before ever assigning a client-supplied url. One
  # predicate, two callers — a client-supplied url reaching an `img src`
  # unchecked is the exact defect this guards against, and adding the
  # lightbox's own selection event must never add a second, independently
  # written whitelist alongside this one.
  defp valid_gallery_image?(game, url) do
    url in gallery_thumbnails(game)
  end

  # The lightbox's previous/next controls compute their target url by
  # walking gallery_thumbnails/1's own list — there is no second,
  # independently-derived image list (T-01.1-16). Called with
  # @lightbox_image as `current` (G-01.2-25) — the lightbox's own
  # selection, not the page's @selected_image. Wraps around both ends.
  defp lightbox_neighbor(game, current, offset) do
    urls = gallery_thumbnails(game)

    case Enum.find_index(urls, &(&1 == current)) do
      nil -> current
      idx -> Enum.at(urls, rem(idx + offset + length(urls), length(urls)))
    end
  end

  # D-04/D-05-lineage `zero-one-many` backstop, split in two by 01.3-07's
  # restructure of the old merged "Ficha técnica" section: this predicate
  # now guards only the unheaded fact grid (year + Diseñadores/Ilustradores/
  # Mecánicas/Temáticas) — the block renders only when at least one of its
  # five carriable inputs is present, so a minimal-data game never shows an
  # empty grid. `comunidad_bgg?/1` below guards the separate BGG stats
  # block that used to share this same or-chain via `bgg_id`; `bgg_id`
  # itself has left this function's or-chain for exactly that reason — it
  # no longer gates the fact grid, only the Comunidad BGG block.
  #
  # Five inputs across two sources: `year_published` (a nullable integer on
  # the struct) and `designers`/`artists` (array columns with `default: []`
  # on the struct) are read directly off `game`; `mechanic_labels`/
  # `theme_labels` are NOT struct fields — they are `Vocabulary`-derived
  # assigns computed once in `mount/3` and passed in here, because the
  # fact grid's own Mecánicas/Temáticas columns render the SAME translated
  # labels the reading column's chip rows already use, not the raw
  # `game.mechanics`/`game.themes` codes. No nil-dereference path exists
  # for any of the five.
  defp fact_grid?(game, mechanic_labels, theme_labels) do
    not is_nil(game.year_published) or
      game.designers != [] or
      game.artists != [] or
      mechanic_labels != [] or
      theme_labels != []
  end

  # 01.3-07: guards the separate "Comunidad BGG" block (label + up to three
  # independently-gated stat links + a Fuente line) that this plan split out
  # of the old merged Ficha técnica section. Widens `advanced_stats?/1`'s
  # own or-chain with `bgg_id` itself so a game that has a `bgg_id` but no
  # populated stat (rating/weight/rank all nil — BGG enrichment ran but
  # returned nothing usable) still shows the group with its Fuente line,
  # matching sketch 039/043's "Comunidad BGG" block always carrying at
  # least the source link when a bgg_id exists.
  defp comunidad_bgg?(game) do
    advanced_stats?(game) or not is_nil(game.bgg_id)
  end

  # D-06 (01.3-05 Task 2, superseded label in 01.3-07 — see comunidad_bgg?/1
  # above): the underlying or-chain (weight/rating/rank) is unchanged and
  # still guards whether any BGG stat exists to show. Deliberately does NOT
  # also check bgg_id: any game that can carry a weight, rating or rank
  # necessarily carries a bgg_id (BGG enrichment is keyed on it) —
  # `comunidad_bgg?/1` is the one that widens with `bgg_id` on top of this,
  # for the Fuente-line-only case this predicate alone would miss.
  defp advanced_stats?(game) do
    not is_nil(game.bgg_weight) or
      not is_nil(game.bgg_rating) or
      not is_nil(game.bgg_rank)
  end

  # D-06 (01.3-01 Task 1): BGG's rating is a ten-point scale — formatted via
  # Erlang stdlib (no existing float-formatting helper in this codebase, no
  # new dependency needed) and never renormalized to a five-point scale,
  # which would misrepresent the source.
  defp format_bgg_rating(rating), do: :erlang.float_to_binary(rating, decimals: 1) <> "/10"

  # D-06 (01.3-05 Task 2): BGG's weight is its own 1-5 "complexity" scale —
  # distinct from bgg_rating's 1-10 average-rating scale above. Same Erlang
  # stdlib formatting call, one decimal, suffixed per the Copywriting
  # Contract.
  defp format_bgg_weight(weight), do: :erlang.float_to_binary(weight, decimals: 1) <> "/5"

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
