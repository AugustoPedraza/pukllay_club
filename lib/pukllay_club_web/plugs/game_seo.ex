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

  Quick task 260913-2x6 (T-2x6-01/02/04): also owns id-slug
  canonicalization. The game is resolved FIRST (so an unknown/junk id
  still 404s before any redirect decision runs), then the raw `id` param
  is compared, via exact string equality, against
  `Phoenix.Param.to_param/1` — the single canonical-param source also used
  by every URL this app emits. A match assigns `:seo` as before; a
  mismatch (bare id, stale slug, junk tail) responds `301 Moved
  Permanently` to the canonical id-slug path and halts, never rendering
  the page. The Location is built ONLY from `~p"/juegos/\#{game}"` plus the
  request's own `conn.query_string` — never from `conn.request_path`, the
  request's host, or any other param — so a crafted path/query can never
  redirect off-site (T-2x6-01) or loop (T-2x6-04): `Phoenix.Param.to_param/1`
  always outputs digits-plus-`[a-z0-9-]`, and the empty-slug case is the
  bare id with no trailing dash, so the canonical path itself always
  compares equal to itself on the next request.
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

  Once the game is resolved, compares `id` against
  `Phoenix.Param.to_param(game)` (exact string equality — the one
  canonical-param check, T-2x6-04). Equal: assigns `:seo` and lets the
  request continue to `CatalogLive.Show`. Different: responds 301 to the
  canonical id-slug path, query string preserved, and halts — the
  LiveView never mounts for a non-canonical URL.

  Returns `conn` untouched when no `"id"` param is present, so a
  params-availability surprise degrades to the site default (`SiteSEO`)
  rather than raising.
  """
  def call(%Plug.Conn{params: %{"id" => id}} = conn, _opts) do
    game = Catalog.get_game!(id)
    canonical_id = Phoenix.Param.to_param(game)

    if id == canonical_id do
      assign(conn, :seo, SEO.for_game(conn, game))
    else
      redirect_to_canonical(conn, game)
    end
  end

  def call(conn, _opts), do: conn

  # T-2x6-01 (open redirect): `location` is built ONLY from the looked-up
  # `game` via `~p"/juegos/#{game}"` plus a literal "?" and the request's
  # own `conn.query_string` — never `conn.request_path`, the request host,
  # or any other conn/param value. `Phoenix.Controller.redirect(to:)`
  # additionally rejects a non-local target, a second, independent guard
  # against the same class of bug. T-2x6-02 (header injection): the query
  # string is appended only after that literal "?" on an already-safe
  # game-derived path; `redirect/2` raises on CR/LF in a header value.
  defp redirect_to_canonical(conn, game) do
    location = canonical_path(game, conn.query_string)

    conn
    |> put_status(:moved_permanently)
    |> Phoenix.Controller.redirect(to: location)
    |> halt()
  end

  defp canonical_path(game, ""), do: ~p"/juegos/#{game}"
  defp canonical_path(game, query_string), do: ~p"/juegos/#{game}" <> "?" <> query_string
end
