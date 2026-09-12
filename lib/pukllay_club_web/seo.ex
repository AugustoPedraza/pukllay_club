defmodule PukllayClubWeb.SEO do
  @moduledoc """
  The single builder for every SEO payload this app renders: the site-wide
  default (hero-less routes) and the per-game payload (`/juegos/:id`).

  Per this phase's `<assumption_delta_decision>` (add-alongside, not
  promote), the two are named, independent functions — `for_game/2` and
  `site_default/1` — never one function with a nil-game branch, so neither
  identity can silently degrade into the other.

  Every payload is written to `conn.assigns[:seo]` by a pre-mount Plug
  (`PukllayClubWeb.Plugs.GameSEO`/`SiteSEO`) and read only from
  `conn.assigns` by `root.html.heex`/`SEOTags` — never from a LiveView
  socket assign, since a JS-free crawler never opens one (PITFALLS
  Pitfall 1).
  """

  use PukllayClubWeb, :verified_routes

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.OgCard

  @doc """
  Builds the per-game SEO payload for `game`. `conn` is accepted (but
  currently unused) so this function's shape matches `site_default/1`'s —
  a future per-request field can be added without changing every call
  site.
  """
  @spec for_game(Plug.Conn.t(), Game.t()) :: map()
  def for_game(_conn, %Game{} = game) do
    %{
      title: game.name,
      canonical_url: canonical_url(game),
      json_ld: game_json_ld(game)
    }
  end

  @doc """
  Builds the escaped, `Jason`-encoded `Game` JSON-LD payload for `game`,
  ready to render inside a `<script type="application/ld+json">` element
  via `Phoenix.HTML.raw/1`.

  Never emits `aggregateRating`, `review`, `offers` or `price` — the club
  holds no ratings or sales data of its own, and fabricated review markup
  would misrepresent the club to every member who sees the search result
  (this plan's threat model prohibition).

  Omits `image`, `description`, and `numberOfPlayers` entirely when their
  source values are absent, rather than emitting `null`/empty-string
  values — built by putting present keys onto a base map, never a fixed
  map with null holes (T-01.8-02).
  """
  @spec game_json_ld(Game.t()) :: String.t()
  def game_json_ld(%Game{} = game) do
    %{"@context" => "https://schema.org", "@type" => "Game"}
    |> Map.put("name", game.name)
    |> Map.put("url", canonical_url(game))
    |> maybe_put("image", image_for(game))
    |> maybe_put("description", game.description)
    |> put_number_of_players(game)
    |> Jason.encode!()
    |> escape_script_close()
  end

  @doc """
  Renders the full `<script type="application/ld+json">` element for
  `json_ld` under `nonce`, as safe raw HTML.

  Built here as a plain string, not as inline HEEx markup in
  `root.html.heex`, because HEEx's tokenizer treats `<script>`/`<style>`
  tag bodies as opaque raw text and never evaluates `{}` interpolation
  inside them (`Phoenix.LiveView.TagEngine.Tokenizer`'s `handle_script/6`)
  — an inline `<script ...>{raw(json_ld)}</script>` in the template would
  render those literal characters, not the payload. `json_ld` is already
  `Jason`-encoded and script-close-escaped by `game_json_ld/1`; `nonce` is
  a router-generated base64 value (alphabet `A-Za-z0-9+/=`, never a quote
  or angle bracket), so both are safe to splice directly into this
  hand-built tag string.
  """
  @spec json_ld_tag(String.t(), String.t()) :: Phoenix.HTML.safe()
  def json_ld_tag(json_ld, nonce) do
    Phoenix.HTML.raw([
      ~s(<script type="application/ld+json" nonce="),
      nonce,
      ~s(">),
      json_ld,
      "</script>"
    ])
  end

  defp canonical_url(%Game{id: id}), do: url(~p"/juegos/#{id}")

  defp image_for(game), do: OgCard.url_for(game) || game.cover_url

  defp put_number_of_players(map, %Game{min_players: nil, max_players: nil}), do: map

  defp put_number_of_players(map, %Game{min_players: min, max_players: max}) do
    players =
      %{"@type" => "QuantitativeValue"}
      |> maybe_put("minValue", min)
      |> maybe_put("maxValue", max)

    Map.put(map, "numberOfPlayers", players)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # T-01.8-02: escapes every "/" to "\/" — the standard JSON-in-HTML
  # mitigation. A raw "</script>" sequence requires a literal "/", so this
  # guarantees no script-closing sequence survives into the rendered
  # payload regardless of what a game's own `name`/`description` contains.
  # A backslash-escaped forward slash is valid JSON that decodes back to
  # the identical unescaped string, so this changes no semantic value.
  defp escape_script_close(json) do
    String.replace(json, "/", "\\/")
  end
end
