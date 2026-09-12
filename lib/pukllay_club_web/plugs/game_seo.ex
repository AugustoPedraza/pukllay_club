defmodule PukllayClubWeb.Plugs.GameSEO do
  @moduledoc """
  Pre-mount plug resolving the game named by the `/juegos/:id` route and
  writing `conn.assigns[:seo]` before `CatalogLive.Show` mounts — so a
  JS-free crawler's disconnected HTTP response already carries that game's
  own meta description, Open Graph/Twitter tags and `Game` JSON-LD
  (PITFALLS Pitfall 1: a crawler never opens the LiveView socket, so
  nothing here may be gated on `connected?/1`).

  Piped in only for `/juegos/:id` via the router's `:game_seo` pipeline,
  after `:browser` has already merged path params into `conn.params`.
  """

  use PukllayClubWeb, :verified_routes

  import Plug.Conn

  alias PukllayClub.Catalog
  alias PukllayClubWeb.SEO

  def init(opts), do: opts

  @doc """
  Resolves the game named by `conn.params["id"]` via
  `PukllayClub.Catalog.get_game!/1` — the same call `CatalogLive.Show.mount/3`
  already makes, which already converts both a nonexistent and a
  non-numeric id into `Ecto.NoResultsError` (a `Plug.Exception`, rendering
  the branded 404). Never calls `Repo.get!/2` directly.

  Returns `conn` untouched when no `"id"` param is present, so a
  params-availability surprise degrades to the site default (`SiteSEO`)
  rather than raising.
  """
  def call(%Plug.Conn{params: %{"id" => id}} = conn, _opts) do
    game = Catalog.get_game!(id)
    assign(conn, :seo, SEO.for_game(conn, game))
  end

  def call(conn, _opts), do: conn
end
