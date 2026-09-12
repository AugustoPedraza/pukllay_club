defmodule PukllayClubWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use PukllayClubWeb, :controller
      use PukllayClubWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Phoenix.Controller
      import Phoenix.LiveView.Router

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]
      use Gettext, backend: PukllayClubWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      # Records a Sentry breadcrumb for every mount/handle_params/handle_event,
      # so an unhandled event reports WHICH event and WHICH param keys it
      # carried. Without it a whole-function clause mismatch only ever names
      # the module's first clause — the exact dead end that made Sentry
      # ELIXIR-1 expensive to diagnose (see
      # `.planning/debug/resolved/catalog-show-no-clause.md`).
      #
      # The custom scrubber is not optional: Sentry's default only redacts
      # credential-shaped keys (`password`/`passwd`/`secret`), and this app's
      # user-typed data arrives under `nombre` and `value`. See
      # `PukllayClubWeb.SentryScrubber` for the keep-the-keys/drop-the-values
      # policy and why it is written that way.
      on_mount {Sentry.LiveViewHook, scrubber: {PukllayClubWeb.SentryScrubber, :scrub, []}}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: PukllayClubWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import PukllayClubWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias PukllayClubWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PukllayClubWeb.Endpoint,
        router: PukllayClubWeb.Router,
        statics: PukllayClubWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
