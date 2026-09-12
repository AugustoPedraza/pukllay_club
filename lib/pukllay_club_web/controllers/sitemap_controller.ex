defmodule PukllayClubWeb.SitemapController do
  @moduledoc """
  Request-time XML sitemap (SEO-04). Deliberately outside the `:browser`
  pipeline: no session, no CSRF token, no CSP needed for a machine-read XML
  document — mirrors `HealthController`'s reasoning.

  Generated fresh from `Catalog.sitemap_entries/0` on every request, never
  from a build-time or cached snapshot: Kamal's Docker build has no
  database access, so a compile-time sitemap could not be correct even
  once (PITFALLS Pitfall 4). Built by explicit string construction with an
  escape function applied to every interpolated value (RESEARCH.md's Don't
  Hand-Roll table permits this shape as an alternative to a template).
  Emits no `<priority>`/`<changefreq>` — this catalog has no real signal to
  base a fabricated value on.
  """
  use PukllayClubWeb, :controller

  alias PukllayClub.Catalog

  def index(conn, _params) do
    entries = Catalog.sitemap_entries()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, render_sitemap(entries))
  end

  defp render_sitemap(entries) do
    [
      ~s(<?xml version="1.0" encoding="UTF-8"?>),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">),
      url_entry(url(~p"/"), nil),
      Enum.map(entries, &game_entry/1),
      "</urlset>"
    ]
    |> IO.iodata_to_binary()
  end

  defp game_entry(%{id: id, updated_at: updated_at}) do
    url_entry(url(~p"/juegos/#{id}"), lastmod(updated_at))
  end

  defp url_entry(loc, nil), do: ["<url><loc>", escape(loc), "</loc></url>"]

  defp url_entry(loc, lastmod) do
    ["<url><loc>", escape(loc), "</loc><lastmod>", lastmod, "</lastmod></url>"]
  end

  # `games.updated_at` comes from a bare `timestamps()` call with no
  # `type:` override in both the schema and its migration — the loaded
  # Elixir struct type (`NaiveDateTime` vs `DateTime`) is not determinable
  # from source alone (RESEARCH.md Pitfall C). Matching both clauses
  # sidesteps the ambiguity instead of betting on one and raising a
  # `FunctionClauseError` on a public URL if the bet is wrong.
  defp lastmod(%DateTime{} = dt), do: Date.to_iso8601(DateTime.to_date(dt))
  defp lastmod(%NaiveDateTime{} = dt), do: Date.to_iso8601(NaiveDateTime.to_date(dt))

  defp escape(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
