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

  # Quick task 260922-pni: the two paths whose live/committed values the
  # recurrence guards below re-derive from disk, mirroring
  # `stylesheet_integrity_test.exs`'s own `Path.expand(..., __DIR__)` idiom
  # for `app.css` — never a hand-typed hex literal on either side.
  @app_css_path Path.expand("../../assets/css/app.css", __DIR__)
  @og_generator_path Path.expand("../../tools/og-fallback/generate_og_fallback.py", __DIR__)

  describe "LocalBusiness JSON-LD (SEO-06)" do
    test "GET /, GET /club and GET /juegos/:id each return exactly one LocalBusiness JSON-LD payload" do
      game = game_fixture()

      for path <- [~p"/", ~p"/club", ~p"/juegos/#{game}"] do
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

      detail_body = build_conn() |> get(~p"/juegos/#{game}") |> html_response(200)
      index_body = build_conn() |> get(~p"/") |> html_response(200)

      assert count_occurrences(detail_body, ~s(type="application/ld+json")) == 2
      assert count_occurrences(index_body, ~s(type="application/ld+json")) == 1
    end

    test "a game detail page's two JSON-LD payloads are Game and LocalBusiness, no duplicates" do
      game = game_fixture()

      body = build_conn() |> get(~p"/juegos/#{game}") |> html_response(200)

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

    test "the shipped asset's background pixel matches app.css's live --pk-ramp-800 (recurrence guard)" do
      # Motivating incident (quick task 260922-pni): the asset was baked at
      # `#551670` on 2026-09-12; sketch 058 rotated --pk-ramp-800 to
      # `#4A187F` that same day and nothing downstream noticed. The
      # expectation is PARSED from app.css, never hand-typed, or this test
      # stops tracking the ramp and becomes decorative — the exact failure
      # mode that let the drift through the first time.
      expected_rgb = parse_pk_ramp_800!()

      assert {:ok, vimage} = Image.open(@og_fallback_disk_path)
      assert {:ok, actual_rgb} = Image.get_pixel(vimage, 0, 0)

      assert actual_rgb == expected_rgb,
             "priv/static/images/og-fallback.webp's (0,0) pixel is #{inspect(actual_rgb)}, " <>
               "but assets/css/app.css's --pk-ramp-800 is currently #{inspect(expected_rgb)}. " <>
               "Re-run `python3 tools/og-fallback/generate_og_fallback.py` to re-bake the asset."
    end

    test "the generator's tagline constant matches app.css's live light --color-base-300 (tagline guard)" do
      # The tagline is guarded at its SOURCE (the generator's own TAGLINE_HEX
      # constant) rather than by a pixel read: a 1/255-per-channel colour
      # difference in antialiased text is not robustly distinguishable
      # through decode/re-encode, whereas the generator's own run-time pixel
      # census (Task 1's self-verification) already proves this exact
      # constant reached the shipped pixels. Both sides here are parsed off
      # disk, neither is hand-typed.
      expected_hex = parse_light_color_base_300!()
      generator_hex = parse_generator_tagline_hex!()

      assert generator_hex == expected_hex,
             "tools/og-fallback/generate_og_fallback.py's TAGLINE_HEX is #{inspect(generator_hex)}, " <>
               "but assets/css/app.css's light --color-base-300 is currently #{inspect(expected_hex)}. " <>
               "Update TAGLINE_HEX in the generator and re-run it to re-bake the asset."
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

  # ── Quick task 260922-pni: OG-fallback colour-recurrence parsing helpers ──

  defp parse_pk_ramp_800! do
    src = File.read!(@app_css_path)

    case Regex.run(~r/--pk-ramp-800:\s*(#[0-9A-Fa-f]{6})\s*;/, src) do
      [_, hex] -> hex_to_rgb!(hex)
      nil -> flunk("Could not parse --pk-ramp-800 out of assets/css/app.css")
    end
  end

  # `--color-base-300` is declared inside more than one daisyUI theme block
  # (light and dark each have their own value) — scope the search to the
  # `@plugin "...daisyui-theme"` block whose `name:` is `"light"`, mirroring
  # the generator's own `parse_css_var(..., within_light_theme: True)`.
  defp parse_light_color_base_300! do
    src = File.read!(@app_css_path)

    light_block =
      case Regex.run(
             ~r/@plugin\s+"[^"]*daisyui-theme"\s*\{[^{}]*?name:\s*"light";.*?\n\}/s,
             src
           ) do
        [block] -> block
        nil -> flunk("Could not locate the daisyUI theme block with name: \"light\" in app.css")
      end

    case Regex.run(~r/--color-base-300:\s*(#[0-9A-Fa-f]{6})\s*;/, light_block) do
      [_, hex] -> hex_to_rgb!(hex)
      nil -> flunk("Could not parse --color-base-300 out of app.css's light theme block")
    end
  end

  defp parse_generator_tagline_hex! do
    src = File.read!(@og_generator_path)

    case Regex.run(~r/^TAGLINE_HEX\s*=\s*"(#[0-9A-Fa-f]{6})"/m, src) do
      [_, hex] -> hex_to_rgb!(hex)
      nil -> flunk("Could not parse the literal TAGLINE_HEX constant out of #{@og_generator_path}")
    end
  end

  defp hex_to_rgb!("#" <> hex) do
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> = hex
    [String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)]
  end
end
