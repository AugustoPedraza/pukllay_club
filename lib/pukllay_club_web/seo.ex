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
  alias PukllayClub.Catalog.Vocabulary

  # D-04's brand fallback asset, produced by a later plan's /gsd-sketch
  # round — the literal path is fixed here regardless, so this plan's
  # SiteSEO/SEOTags wiring compiles and serves a correct (if 404-until-
  # shipped) URL rather than blocking on that human design round
  # (CONTEXT.md D-05's explicit "do not block the rest of the phase").
  @og_fallback_path "/images/og-fallback.webp"

  @site_title "PukllayClub"
  @site_description "La ludoteca de juegos de mesa de Pukllay Club, Jujuy — encontrá tu próximo juego."

  # D-01: the club's real, current meeting venue ("Club de Emprendedores de
  # Jujuy"), confirmed by the user — not a placeholder. D-03: Saturdays at
  # 17:00 is the only schedule to encode; no other day/hour is invented.
  @local_business_name "Pukllay Club"
  @local_business_street "Avenida España 1500"
  @local_business_locality "San Salvador de Jujuy"
  @local_business_region "Jujuy"
  @local_business_postal_code "Y4600"
  @local_business_country "AR"

  # A typical search-engine snippet truncates well before this; wide
  # enough for the D-09 template's longest clause combination without
  # ever needing to truncate mid-word in practice, narrow enough that a
  # truncation (when one does happen) still reads as a real sentence.
  @max_description_length 155

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
      description: meta_description(game),
      canonical_url: canonical_url(game),
      image_url: og_image_url(game),
      json_ld: game_json_ld(game)
    }
  end

  # AboutLive.ex's own moduledoc: "/club" and "/quienes-somos" are two URL
  # aliases pointing at the exact same LiveView and "must resolve
  # identically; neither route redirects to the other" (D-01, SHELL-02,
  # pinned by a byte-identical-output regression test). A raw
  # `conn.request_path` canonical would give each alias its own distinct
  # canonical_url/og:url, silently breaking that invariant. Canonicalizing
  # the alias to its primary path is the standard SEO treatment for
  # intentional duplicate-content URLs — one canonical target, not one per
  # alias — and is what keeps both aliases' full SEO payload identical.
  @alias_paths %{"/quienes-somos" => "/club"}

  @doc """
  Builds the site-wide default SEO payload for any hero-less route (the
  catalog index, About). Never a nil-game branch of `for_game/2` — see
  this plan's `<assumption_delta_decision>`.

  `canonical_url` is built from `conn.request_path` (path only — a
  filtered catalog URL's query string must not become its canonical),
  canonicalizing known URL aliases (`@alias_paths`) to their primary path
  first, via `PukllayClubWeb.Endpoint.url/0`, not `~p`, for the same
  reason `fallback_image_url/0` below does.
  """
  @spec site_default(Plug.Conn.t()) :: map()
  def site_default(%Plug.Conn{} = conn) do
    path = Map.get(@alias_paths, conn.request_path, conn.request_path)

    %{
      title: @site_title,
      description: @site_description,
      canonical_url: PukllayClubWeb.Endpoint.url() <> path,
      image_url: fallback_image_url()
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
  Builds the escaped, `Jason`-encoded `LocalBusiness` JSON-LD payload —
  the site-wide structured-data block (SEO-06) naming Pukllay Club's real
  Jujuy meeting venue, its public phone
  (`PukllayClubWeb.ClubLinks.public_phone/0`) and its Saturday 17:00
  schedule (D-01/D-02/D-03). Every value here is a compile-time literal —
  no game or per-request data — so this function returns the same bytes
  on every call. Escaped the same way `game_json_ld/1` escapes its
  payload (T-01.8-20): built as a plain Elixir map and encoded via
  `Jason.encode!/1`, never string interpolation.

  Deliberate deviation from RESEARCH.md's Pattern 4: this block is
  delivered under the same per-request nonce as the `Game` block, not a
  compile-time SHA-256 hash-source — see this plan's own recorded
  rationale (byte-exactness fragility of the hash approach vs. the
  nonce's already-zero marginal cost).
  """
  @spec local_business_json() :: String.t()
  def local_business_json do
    %{
      "@context" => "https://schema.org",
      "@type" => "LocalBusiness",
      "name" => @local_business_name,
      "url" => PukllayClubWeb.Endpoint.url(),
      "address" => %{
        "@type" => "PostalAddress",
        "streetAddress" => @local_business_street,
        "addressLocality" => @local_business_locality,
        "addressRegion" => @local_business_region,
        "postalCode" => @local_business_postal_code,
        "addressCountry" => @local_business_country
      },
      "telephone" => PukllayClubWeb.ClubLinks.public_phone(),
      "openingHoursSpecification" => %{
        "@type" => "OpeningHoursSpecification",
        "dayOfWeek" => "Saturday",
        "opens" => "17:00"
      }
    }
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

  @doc """
  Builds the D-09 meta description: name, then a mechanic clause, then a
  complexity clause, then the Jujuy hook — Rioplatense/Argentine voseo
  (D-11). Each clause is built by an independent nil-or-value function,
  mirroring `GamePreview.players_text/1`'s idiom, never a single
  interpolation with holes — that is exactly how the empty-list/nil cases
  would otherwise produce a dangling connector, a double space, or a
  trailing separator.

  Never interpolates `game.mechanics` (or any other array field) directly
  — only a single label taken from `Vocabulary.covered_mechanics/1`,
  which already filters/orders off the game's own stored array
  deterministically, never map-iteration order (PITFALLS Pitfall B,
  RESEARCH.md).
  """
  @spec meta_description(Game.t()) :: String.t()
  def meta_description(%Game{} = game) do
    ["Descubrí #{game.name}", mechanic_clause(game), weight_clause(game), "en Pukllay Club, Jujuy."]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(", ")
    |> String.replace(", en Pukllay Club", " en Pukllay Club")
    |> truncate(@max_description_length)
  end

  defp mechanic_clause(%Game{mechanics: mechanics}) do
    case Vocabulary.covered_mechanics(mechanics) do
      [] -> nil
      [first | _] -> "un juego de #{first}"
    end
  end

  defp weight_clause(%Game{weight_band: nil}), do: nil

  defp weight_clause(%Game{weight_band: value}) do
    case Vocabulary.weight_band(value) do
      nil -> nil
      %{label: label} -> "pensado para el nivel #{label}"
    end
  end

  defp truncate(text, max_length) do
    if String.length(text) <= max_length do
      text
    else
      text
      |> String.slice(0, max_length)
      |> String.replace(~r/\s+\S*$/u, "")
      |> Kernel.<>("…")
    end
  end

  @doc """
  Selects `game`'s og-card URL when derivable, the branded fallback
  otherwise — the add-alongside identity model from this plan's
  `<assumption_delta_decision>`: never an empty value, never a relative
  path (SHARE-01, edge:empty).
  """
  @spec og_image_url(Game.t()) :: String.t()
  def og_image_url(%Game{} = game) do
    OgCard.url_for(game) || fallback_image_url()
  end

  # Uses `Endpoint.url/0` + a literal path, deliberately not `~p`: verified
  # routes check static files at compile time, and the sketch-produced
  # asset (D-04/D-05) lands in a later plan by design, so a `~p` reference
  # here would couple this plan's compilation to a human design round that
  # CONTEXT.md explicitly says must not block the rest of the phase.
  # Everything else in this codebase that builds a route URL keeps using
  # `~p` — this is the one deliberate exception, and only for this path.
  defp fallback_image_url, do: PukllayClubWeb.Endpoint.url() <> @og_fallback_path

  # `~p"/juegos/#{game}"` (not `#{game.id}`) — routes through the one
  # `Phoenix.Param` impl on `Game` (quick task 260913-2x6), so canonical
  # link, og:url and the Game JSON-LD "url" all carry the id-slug form.
  defp canonical_url(%Game{} = game), do: url(~p"/juegos/#{game}")

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
