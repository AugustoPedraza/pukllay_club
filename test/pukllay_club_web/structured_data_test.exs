defmodule PukllayClubWeb.StructuredDataTest do
  @moduledoc """
  Site-wide `LocalBusiness` JSON-LD assertions (SEO-06) — a plain
  `get(conn, ...)`, never a rendered LiveView, since a JS-free crawler
  never opens the LiveView socket (PITFALLS Pitfall 1), mirroring
  `PukllayClubWeb.Plugs.GameSEOTest`'s own approach for the `Game` block.

  Task 3 (SHARE-04) extends this same file with the OG-fallback asset's
  dimension and served-response gates, rather than adding a third
  structured-data test file.
  """

  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures

  @json_ld_open ~r/<script type="application\/ld\+json"[^>]*nonce="([^"]*)"[^>]*>(.*?)<\/script>/s

  # Task 3 (SHARE-04): the real asset Task 2's checkpoint placed on disk,
  # read the same way `stylesheet_integrity_test.exs` reads `app.css` —
  # a real file path expanded relative to this test file, never a
  # hand-typed absolute path.
  @og_fallback_disk_path Path.expand("../../priv/static/images/og-fallback.webp", __DIR__)

  describe "LocalBusiness JSON-LD (SEO-06)" do
    test "GET /, GET /club and GET /juegos/:id each return exactly one LocalBusiness JSON-LD payload" do
      game = game_fixture()

      for path <- [~p"/", ~p"/club", ~p"/juegos/#{game.id}"] do
        body = build_conn() |> get(path) |> html_response(200)

        local_business_payloads =
          body
          |> decode_json_ld_payloads()
          |> Enum.filter(&(&1["@type"] == "LocalBusiness"))

        assert length(local_business_payloads) == 1,
               "Expected exactly one LocalBusiness JSON-LD payload at #{path}, got " <>
                 "#{length(local_business_payloads)}"
      end
    end

    test "the LocalBusiness payload's address, telephone and openingHoursSpecification carry the locked D-01/D-02/D-03 values" do
      body = build_conn() |> get(~p"/") |> html_response(200)

      payload = local_business_payload(body)

      assert payload["@type"] == "LocalBusiness"
      assert payload["name"] == "Pukllay Club"
      assert payload["address"]["@type"] == "PostalAddress"
      assert payload["address"]["streetAddress"] == "Avenida España 1500"
      assert payload["address"]["addressLocality"] == "San Salvador de Jujuy"
      assert payload["address"]["addressRegion"] == "Jujuy"
      assert payload["address"]["postalCode"] == "Y4600"
      assert payload["address"]["addressCountry"] == "AR"
      assert payload["telephone"] == PukllayClubWeb.ClubLinks.public_phone()
      assert payload["openingHoursSpecification"]["@type"] == "OpeningHoursSpecification"
      assert payload["openingHoursSpecification"]["dayOfWeek"] == "Saturday"
      assert payload["openingHoursSpecification"]["opens"] == "17:00"
      refute Map.has_key?(payload["openingHoursSpecification"], "closes")
    end

    test "the LocalBusiness script's nonce attribute is byte-equal to the nonce source in the response's own CSP header" do
      conn = get(build_conn(), ~p"/")
      body = html_response(conn, 200)

      [policy] = get_resp_header(conn, "content-security-policy")
      [_, csp_nonce] = Regex.run(~r/'nonce-([^']+)'/, policy)

      [script_nonce] =
        @json_ld_open
        |> Regex.scan(body, capture: :all)
        |> Enum.filter(fn [_full, _nonce, payload] ->
          Jason.decode!(payload)["@type"] == "LocalBusiness"
        end)
        |> Enum.map(fn [_full, nonce, _payload] -> nonce end)

      assert script_nonce == csp_nonce
    end

    test "GET /juegos/:id returns two JSON-LD script elements; GET / returns one" do
      game = game_fixture()

      detail_body = build_conn() |> get(~p"/juegos/#{game.id}") |> html_response(200)
      index_body = build_conn() |> get(~p"/") |> html_response(200)

      assert count_occurrences(detail_body, ~s(type="application/ld+json")) == 2
      assert count_occurrences(index_body, ~s(type="application/ld+json")) == 1
    end

    test "a game detail page's two JSON-LD payloads are Game and LocalBusiness, no duplicates" do
      game = game_fixture()

      body = build_conn() |> get(~p"/juegos/#{game.id}") |> html_response(200)

      types = body |> decode_json_ld_payloads() |> Enum.map(& &1["@type"]) |> Enum.sort()

      assert types == ["Game", "LocalBusiness"]
    end

    # Quick task 260913-2x6: id-slug URLs — literal expectation, not derived
    # from the same `Phoenix.Param` impl under test.
    test "the Game JSON-LD payload's url is the absolute id-slug URL" do
      game = game_fixture(%{name: "Catán"})

      body = build_conn() |> get("/juegos/#{game.id}-catan") |> html_response(200)

      payload = body |> decode_json_ld_payloads() |> Enum.find(&(&1["@type"] == "Game"))

      assert payload["url"] == PukllayClubWeb.Endpoint.url() <> "/juegos/#{game.id}-catan"
    end
  end

  describe "OG fallback asset (SHARE-04)" do
    test "the fallback asset's real decoded dimensions are exactly 1200x630" do
      assert {:ok, vimage} = Image.open(@og_fallback_disk_path)
      assert Image.width(vimage) == 1200
      assert Image.height(vimage) == 630
    end

    test "the fallback asset is actually served, as an image, at the path the og:image tag emits" do
      body = build_conn() |> get(~p"/") |> html_response(200)

      # Derived from the real rendered og:image tag (which reads
      # `@seo.image_url`, itself built by `SEO.site_default/1` via plan
      # 01's `fallback_image_url/0`) — never a separately typed literal,
      # so a future rename of the asset fails this gate loudly instead of
      # silently emitting a dead image URL to every social crawler.
      # Strict form (G-01.8-3): property= must be the first attribute after
      # the tag name, matching game_seo_test.exs's meta_property_content/2 —
      # this is the one og:image assertion that walks the value all the way
      # through to a real served response, so it holds the strict form too.
      [[_full, image_url]] =
        Regex.scan(~r/<meta\s+property="og:image"\s+content="([^"]+)"/, body)

      path = URI.parse(image_url).path

      asset_conn = get(build_conn(), path)

      assert asset_conn.status == 200
      assert [content_type] = get_resp_header(asset_conn, "content-type")
      assert content_type =~ "image/"
    end
  end

  defp decode_json_ld_payloads(body) do
    @json_ld_open
    |> Regex.scan(body, capture: :all)
    |> Enum.map(fn [_full, _nonce, payload] -> Jason.decode!(payload) end)
  end

  defp local_business_payload(body) do
    body
    |> decode_json_ld_payloads()
    |> Enum.find(&(&1["@type"] == "LocalBusiness"))
  end

  defp count_occurrences(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
