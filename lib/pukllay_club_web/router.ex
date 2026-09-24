defmodule PukllayClubWeb.Router do
  use PukllayClubWeb, :router

  import PukllayClubWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PukllayClubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :put_csp
    plug PukllayClubWeb.Plugs.SiteSEO
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :health do
    plug :accepts, ["text"]
  end

  # SEO-04: request-time XML sitemap — no session/CSRF/CSP needed for a
  # machine-read document, mirrors the :health pipeline's shape exactly.
  pipeline :sitemap do
    plug :accepts, ["xml"]
  end

  # Phase 01.8 (SEC-05/SEO-05): resolves the game and writes conn.assigns[:seo]
  # before CatalogLive.Show mounts, so a JS-free crawler's disconnected
  # response already carries per-game meta/OG/JSON-LD (Pitfall 1 — a crawler
  # never opens the LiveView socket). Scoped to /juegos/:id only.
  pipeline :game_seo do
    plug PukllayClubWeb.Plugs.GameSEO
  end

  # Phase 01.8.1 (D-33): staff role gate, layered on top of the generator's
  # own :require_authenticated_user. Runs after it in the pipe_through list
  # below, so an unauthenticated request is redirected to /admin/ingresar
  # before this plug ever runs.
  pipeline :require_staff do
    plug :require_authenticated_user
    plug :require_staff_user
  end

  scope "/", PukllayClubWeb do
    pipe_through :browser

    live "/", CatalogLive.Index, :index
    live "/club", AboutLive, :show
    live "/quienes-somos", AboutLive, :show
  end

  scope "/", PukllayClubWeb do
    pipe_through [:browser, :game_seo]

    live "/juegos/:id", CatalogLive.Show, :show
  end

  scope "/", PukllayClubWeb do
    pipe_through :health

    get "/up", HealthController, :up
  end

  scope "/", PukllayClubWeb do
    pipe_through :sitemap

    get "/sitemap.xml", SitemapController, :index
  end

  # Phase 01.8.1 (D-34): staff sign-in — unlinked, unauthenticated. Mirrors
  # the generator's own :current_user scope shape.
  scope "/admin", PukllayClubWeb do
    pipe_through [:browser]

    live_session :admin_login,
      on_mount: [{PukllayClubWeb.UserAuth, :mount_current_scope}] do
      live "/ingresar", UserLive.Login, :new
      live "/ingresar/:token", UserLive.Confirmation, :new
    end

    post "/ingresar", UserSessionController, :create
    delete "/salir", UserSessionController, :delete
  end

  # Phase 01.8.1 (D-33/D-35): the staff-gated admin area.
  scope "/admin", PukllayClubWeb.Admin do
    pipe_through [:browser, :require_staff]

    live_session :require_staff,
      on_mount: [
        {PukllayClubWeb.UserAuth, :require_authenticated},
        {PukllayClubWeb.UserAuth, :require_staff}
      ] do
      live "/", DashboardLive, :index
      live "/juegos", GameLive.Index, :index
      live "/juegos/:id/editar", GameLive.Form, :edit
      live "/staff", StaffLive.Index, :index
      live "/estantes", EstanteLive.Index, :index
      live "/estantes/pendientes", EstanteLive.Pendientes, :index
      live "/estantes/administrar", EstanteLive.Administrar, :index
      live "/secciones", SectionLive.Index, :index
      live "/secciones/:id", SectionLive.Edit, :edit
      live "/niveles", BandAuditLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PukllayClubWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pukllay_club, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PukllayClubWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Closes Phase 0's deferred Sobelow `Config.CSP` finding (.sobelow-conf).
  # `put_secure_browser_headers` above does not set a Content-Security-Policy
  # by default — Sobelow's static Config.CSP check only inspects that call's
  # own arguments and cannot observe a header set by a separate plug, which
  # is why this exemption is named there instead of silenced here.
  defp put_csp(conn, _opts) do
    nonce = 24 |> :crypto.strong_rand_bytes() |> Base.encode64(padding: false)

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header("content-security-policy", PukllayClubWeb.CSP.policy(nonce))
  end
end
