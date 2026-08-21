defmodule PukllayClubWeb.Router do
  use PukllayClubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PukllayClubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_csp
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :health do
    plug :accepts, ["text"]
  end

  scope "/", PukllayClubWeb do
    pipe_through :browser

    live "/", CatalogLive.Index, :index
    live "/juegos/:id", CatalogLive.Show, :show
    live "/club", AboutLive, :show
    live "/quienes-somos", AboutLive, :show
  end

  scope "/", PukllayClubWeb do
    pipe_through :health

    get "/up", HealthController, :up
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
    put_resp_header(conn, "content-security-policy", PukllayClubWeb.CSP.policy())
  end
end
