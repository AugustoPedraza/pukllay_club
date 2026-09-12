defmodule PukllayClubWeb.Plugs.SiteSEO do
  @moduledoc """
  Assigns the site-wide default SEO payload (`PukllayClubWeb.SEO.site_default/1`)
  to every `:browser`-piped response, so no route is ever left tagless
  (SHARE-04's fallback everywhere else).

  Piped in immediately after `:put_csp` in the `:browser` pipeline. On
  `/juegos/:id`, the `:game_seo` pipeline runs after `:browser` and its
  `GameSEO` plug overwrites `conn.assigns[:seo]` with the per-game
  payload — this is the mechanism that guarantees SHARE-01's "never the
  site-wide fallback" on a game page, per this plan's
  `<assumption_delta_decision>` (add-alongside, not promote).
  """

  import Plug.Conn

  alias PukllayClubWeb.SEO

  def init(opts), do: opts

  def call(conn, _opts), do: assign(conn, :seo, SEO.site_default(conn))
end
