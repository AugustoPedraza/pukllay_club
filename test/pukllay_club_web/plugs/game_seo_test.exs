defmodule PukllayClubWeb.Plugs.GameSEOTest do
  @moduledoc """
  Disconnected-response assertions for `PukllayClubWeb.Plugs.GameSEO` — a
  plain `get(conn, ...)`, never a rendered LiveView, since this plug's
  entire purpose is what a JS-free crawler sees on the very first HTTP
  response (PITFALLS Pitfall 1). First plug-specific test in this app;
  follows `PukllayClubWeb.HealthControllerTest`'s `use
  PukllayClubWeb.ConnCase` shape.
  """

  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures

  @json_ld_open ~r/<script type="application\/ld\+json"[^>]*nonce="([^"]*)"[^>]*>(.*?)<\/script>/s

  describe "Game JSON-LD (SEO-05, SEC-05)" do
    test "renders exactly one Game JSON-LD script element naming the game (phase 01.8-05 also adds a site-wide LocalBusiness script — total is now two)",
         %{conn: conn} do
      game = game_fixture(%{name: "Carcassonne"})

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      assert count_occurrences(body, ~s(type="application/ld+json")) == 2

      [_full, _nonce, payload] = game_json_ld_match(body)
      decoded = Jason.decode!(payload)

      assert decoded["@type"] == "Game"
      assert decoded["name"] == "Carcassonne"
    end

    test "the Game script's nonce attribute is byte-equal to the nonce source in the response's own CSP header",
         %{conn: conn} do
      game = game_fixture()

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      [policy] = get_resp_header(conn, "content-security-policy")
      [_, csp_nonce] = Regex.run(~r/'nonce-([^']+)'/, policy)

      [_full, script_nonce, _payload] = game_json_ld_match(body)

      assert script_nonce == csp_nonce
    end

    test "two successive requests to the same URL return two different nonce values", %{conn: conn} do
      game = game_fixture()

      conn1 = get(conn, ~p"/juegos/#{game}")
      [policy1] = get_resp_header(conn1, "content-security-policy")
      [_, nonce1] = Regex.run(~r/'nonce-([^']+)'/, policy1)

      conn2 = get(build_conn(), ~p"/juegos/#{game}")
      [policy2] = get_resp_header(conn2, "content-security-policy")
      [_, nonce2] = Regex.run(~r/'nonce-([^']+)'/, policy2)

      refute nonce1 == nonce2
    end

    test "a game with nil min/max players and nil description omits those JSON-LD keys", %{conn: conn} do
      game = game_fixture(%{min_players: nil, max_players: nil, description: nil, cover_url: nil})

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      [_full, _nonce, payload] = game_json_ld_match(body)
      decoded = Jason.decode!(payload)

      refute Map.has_key?(decoded, "numberOfPlayers")
      refute Map.has_key?(decoded, "description")
      refute Map.has_key?(decoded, "image")
    end

    test "a game whose name carries an angle bracket and a script-closing sequence still yields " <>
           "exactly one Game script element and an escaped payload",
         %{conn: conn} do
      game = game_fixture(%{name: "Ataque</script><script>alert(1)</script> Total"})

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      assert count_occurrences(body, ~s(type="application/ld+json")) == 2

      [_full, _nonce, payload] = game_json_ld_match(body)

      refute payload =~ "</"

      decoded = Jason.decode!(payload)
      assert decoded["name"] == "Ataque</script><script>alert(1)</script> Total"
    end

    test "two renders of the same game produce byte-identical Game JSON-LD payload bytes", %{conn: conn} do
      game = game_fixture()

      conn1 = get(conn, ~p"/juegos/#{game}")
      body1 = html_response(conn1, 200)
      [_full1, _nonce1, payload1] = game_json_ld_match(body1)

      conn2 = get(build_conn(), ~p"/juegos/#{game}")
      body2 = html_response(conn2, 200)
      [_full2, _nonce2, payload2] = game_json_ld_match(body2)

      assert payload1 == payload2
    end
  end

  describe "Meta description, Open Graph, Twitter Card (SEO-01, SHARE-01/02)" do
    test "GET /juegos/:id returns exactly one each of og:title/description/url/image and twitter:card, naming the game",
         %{conn: conn} do
      game = game_fixture(%{name: "Zombicide"})

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      assert count_occurrences(body, ~s(property="og:title")) == 1
      assert count_occurrences(body, ~s(property="og:description")) == 1
      assert count_occurrences(body, ~s(property="og:url")) == 1
      assert count_occurrences(body, ~s(property="og:image")) == 1
      assert count_occurrences(body, ~s(name="twitter:card")) == 1

      assert meta_content(body, "og:title") == "Zombicide"
      assert meta_content(body, "twitter:card") == "summary_large_image"
    end

    test "two games with different names return two different meta descriptions", %{conn: conn} do
      game_a = game_fixture(%{name: "Catán"})
      game_b = game_fixture(%{name: "Carcassonne"})

      body_a = conn |> get(~p"/juegos/#{game_a}") |> html_response(200)
      body_b = build_conn() |> get(~p"/juegos/#{game_b}") |> html_response(200)

      refute meta_name_content(body_a, "description") == meta_name_content(body_b, "description")
    end

    test "a game with empty mechanics, nil weight_band and nil description still yields a non-empty, well-formed description",
         %{conn: conn} do
      game = game_fixture(%{mechanics: [], weight_band: nil, description: nil})

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      description = meta_name_content(body, "description")

      refute description in [nil, ""]
      refute description =~ "  "
      refute description =~ ~r/,\s*$/
      refute description =~ ~r/,\s*en Pukllay Club/
    end

    test "GET / and GET /club return the site-wide title/description and a branded fallback og:image",
         %{conn: _conn} do
      for path <- [~p"/", ~p"/club"] do
        conn = get(build_conn(), path)
        body = html_response(conn, 200)

        image = meta_content(body, "og:image") || ""

        assert image =~ ~r/^https?:\/\//
        assert String.ends_with?(image, "/images/og-fallback.webp")
      end
    end

    test "every og:image/twitter:image value is absolute — never a relative path, cover_url present or nil",
         %{conn: _conn} do
      with_cover = game_fixture()
      without_cover = game_fixture(%{cover_url: nil})

      for game <- [with_cover, without_cover] do
        body = build_conn() |> get(~p"/juegos/#{game}") |> html_response(200)

        og_image = meta_content(body, "og:image") || ""
        twitter_image = meta_content(body, "twitter:image") || ""

        refute og_image == ""
        refute twitter_image == ""
        refute String.starts_with?(og_image, "/")
        refute String.starts_with?(twitter_image, "/")
      end
    end

    test "og:image:width (1200) and og:image:height (630) both follow the og:image tag", %{conn: conn} do
      game = game_fixture()

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      image_idx = tag_index(body, ~s(property="og:image"))
      width_idx = tag_index(body, ~s(property="og:image:width"))
      height_idx = tag_index(body, ~s(property="og:image:height"))

      assert image_idx && width_idx && height_idx,
             "Expected og:image, og:image:width and og:image:height tags all to be present"

      assert image_idx < width_idx
      assert width_idx < height_idx
      assert meta_content(body, "og:image:width") == "1200"
      assert meta_content(body, "og:image:height") == "630"
    end

    test "every SEO head tag holds the strict form on a real GET /juegos/:id response, recurrence guard for G-01.8-3",
         %{conn: conn} do
      game = game_fixture()

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      # Built here (not hand-copied) so a future tag added to seo_tags.ex is
      # automatically covered without editing this assertion.
      expected_keys = [
        {"meta", "name", "description"},
        {"link", "rel", "canonical"},
        {"meta", "property", "og:type"},
        {"meta", "property", "og:title"},
        {"meta", "property", "og:description"},
        {"meta", "property", "og:url"},
        {"meta", "property", "og:image"},
        {"meta", "property", "og:image:width"},
        {"meta", "property", "og:image:height"},
        {"meta", "name", "twitter:card"},
        {"meta", "name", "twitter:title"},
        {"meta", "name", "twitter:description"},
        {"meta", "name", "twitter:image"}
      ]

      for {element, attr, key} <- expected_keys do
        pattern = ~r/<#{element}\s+#{attr}="#{Regex.escape(key)}"/

        assert Regex.match?(pattern, body),
               ~s(G-01.8-3 recurrence guard: expected "#{key}" to render as <#{element} #{attr}="#{key}" ...> ) <>
                 "with #{attr}= immediately after the tag name (no attribute interposed, e.g. LiveView's " <>
                 "phx-r). Offending element: #{offending_element(body, key)}"
      end
    end

    test "twitter:title/description are never empty and equal their Open Graph counterparts", %{conn: conn} do
      game = game_fixture()

      conn = get(conn, ~p"/juegos/#{game}")
      body = html_response(conn, 200)

      og_title = meta_content(body, "og:title")
      og_description = meta_content(body, "og:description")
      twitter_title = meta_content(body, "twitter:title")
      twitter_description = meta_content(body, "twitter:description")

      refute twitter_title in [nil, ""]
      refute twitter_description in [nil, ""]
      assert twitter_title == og_title
      assert twitter_description == og_description
    end
  end

  # Quick task 260913-2x6: id-slug URLs (/juegos/<id>-<slug>). Request paths
  # here are PLAIN string literals, not `~p"/juegos/#{game}"` — the
  # whole point is asserting the literal id-slug form the app is supposed
  # to serve/canonicalize, not deriving the expected value from the same
  # `Phoenix.Param` impl under test.
  describe "id-slug canonical URL (quick task 260913-2x6)" do
    test "GET /juegos/<id>-<slug> returns 200 with canonical link, og:url and JSON-LD url all equal to the absolute id-slug URL",
         %{conn: conn} do
      game = game_fixture(%{name: "Catán"})
      expected = PukllayClubWeb.Endpoint.url() <> "/juegos/#{game.id}-catan"

      conn = get(conn, "/juegos/#{game.id}-catan")
      body = html_response(conn, 200)

      assert canonical_href(body) == expected
      assert meta_content(body, "og:url") == expected

      [_full, _nonce, payload] = game_json_ld_match(body)
      assert Jason.decode!(payload)["url"] == expected
    end

    test "GET /juegos/<id>abc (non-dash tail) renders the branded 404", %{conn: conn} do
      game = game_fixture()

      assert_error_sent(404, fn -> get(conn, "/juegos/#{game.id}abc") end)
    end

    test "GET /juegos/99999999999999999999-catan (out-of-bigint-range id) renders the branded 404",
         %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, "/juegos/99999999999999999999-catan") end)
    end
  end

  # Quick task 260913-2x6 (T-2x6-01/02/04): request paths for deliberately
  # non-canonical URLs are PLAIN string literals, never `~p"/juegos/#{game}"`
  # — this suite exists specifically to assert what the plug does to a URL
  # that ISN'T what the app's own Phoenix.Param impl would produce.
  describe "canonical URL redirects (quick task 260913-2x6)" do
    test "GET /juegos/<id> (bare id) redirects 301 to the canonical id-slug path", %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      conn = get(conn, "/juegos/#{game.id}")

      assert redirected_to(conn, 301) == "/juegos/#{game.id}-catan"
    end

    test "GET /juegos/<id>-<stale-slug>?from=... redirects 301 to the current slug, query string byte-preserved",
         %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      conn = get(conn, "/juegos/#{game.id}-nombre-viejo?from=q%3Dcatan")

      assert redirected_to(conn, 301) == "/juegos/#{game.id}-catan?from=q%3Dcatan"
    end

    test "GET /juegos/<id>-<current-slug> renders 200 with no location header (no self-redirect)",
         %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      conn = get(conn, "/juegos/#{game.id}-catan")

      assert conn.status == 200
      assert get_resp_header(conn, "location") == []
    end

    test "a game whose name has no letters/digits: bare id renders 200 (no loop); trailing-dash and junk-tail both 301 to the bare id",
         %{conn: conn} do
      game = game_fixture(%{name: "!!!"})

      bare_conn = get(conn, "/juegos/#{game.id}")
      assert bare_conn.status == 200
      assert get_resp_header(bare_conn, "location") == []

      for path <- ["/juegos/#{game.id}-", "/juegos/#{game.id}-x"] do
        conn = get(build_conn(), path)
        assert redirected_to(conn, 301) == "/juegos/#{game.id}"
      end
    end

    test "the redirect Location is host-less and path-only even when the query string carries a schema-relative URL (open-redirect guard, T-2x6-01)",
         %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      conn = get(conn, "/juegos/#{game.id}-x?next=//evil.example/path")

      [location] = get_resp_header(conn, "location")
      uri = URI.parse(location)

      assert uri.host == nil
      assert uri.path == "/juegos/#{game.id}-catan"
    end

    test "GET /juegos/999999999-catan and GET /juegos/999999999 both still render the branded 404 (unknown id, before any redirect decision)",
         %{conn: _conn} do
      for path <- ["/juegos/999999999-catan", "/juegos/999999999"] do
        assert_error_sent(404, fn -> get(build_conn(), path) end)
      end
    end
  end

  defp canonical_href(html) do
    case Regex.run(~r/<link\s+rel="canonical"\s+href="([^"]*)"/, html) do
      [_, value] -> value
      nil -> nil
    end
  end

  # Phase 01.8-05 added a second, site-wide LocalBusiness JSON-LD script to
  # every page (including /juegos/:id) — this helper isolates the Game-typed
  # match among the (now two) script elements so this file's pre-existing
  # assertions keep testing what they always tested, not "whichever script
  # happens to match first."
  defp game_json_ld_match(body) do
    @json_ld_open
    |> Regex.scan(body, capture: :all)
    |> Enum.find(fn [_full, _nonce, payload] -> Jason.decode!(payload)["@type"] == "Game" end)
  end

  defp count_occurrences(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  # Extracts a `<meta property="X" content="...">`/`<meta name="X" content="...">`
  # value with `property=`/`name=` anchored as the FIRST attribute after the
  # tag name — never order-agnostic. That order-agnostic form was this
  # helper's shape from 01.8-05 through 01.8-05-SUMMARY.md, deliberately
  # loosened at the time to tolerate LiveView's phx-r root-tag attribute
  # (config/config.exs:31, Phoenix.LiveView.ColocatedCSS) interposing before
  # the identifying key. That loosening is exactly what let production keep
  # serving markup WhatsApp's strict link-preview parser cannot read while
  # this whole suite stayed green (G-01.8-3, .planning/debug/whatsapp-og-
  # image-preview.md). Task 1 of this plan removed the phx-r stamping at the
  # source (seo_tags.ex is no longer a HEEx template), so the strict form is
  # now both correct and enforceable — reintroducing an interposed attribute
  # must fail this suite loudly, not pass silently.
  defp meta_content(html, key) do
    meta_name_content(html, key) || meta_property_content(html, key)
  end

  defp meta_property_content(html, key) do
    case Regex.run(~r/<meta\s+property="#{Regex.escape(key)}"\s+content="([^"]*)"/, html) do
      [_, value] -> value
      nil -> nil
    end
  end

  defp meta_name_content(html, key) do
    case Regex.run(~r/<meta\s+name="#{Regex.escape(key)}"\s+content="([^"]*)"/, html) do
      [_, value] -> value
      nil -> nil
    end
  end

  # Prints the actual served element for a failed strict-form assertion —
  # a diagnostic that names the offending key AND shows the real markup,
  # rather than a bare nil/false comparison.
  defp offending_element(html, key) do
    case Regex.run(~r/<(?:meta|link)[^>]*#{Regex.escape(key)}[^>]*>/, html) do
      [match] -> match
      nil -> "(no element found containing #{inspect(key)})"
    end
  end

  defp tag_index(html, needle) do
    case :binary.match(html, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
