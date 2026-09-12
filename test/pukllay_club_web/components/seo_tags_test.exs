defmodule PukllayClubWeb.SEOTagsTest do
  @moduledoc """
  Unit contract for `PukllayClubWeb.SEOTags.seo_tags/1` (G-01.8-3 /
  T-01.8-22 gap closure). Anchored on the STRICT tag form a real
  link-preview crawler (WhatsApp) needs — the identifying
  `property=`/`name=`/`rel=` attribute must be the first attribute after
  the tag name, with nothing interposed. See
  `.planning/debug/whatsapp-og-image-preview.md` for the confirmed root
  cause this test suite guards against recurring.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias PukllayClubWeb.SEOTags

  # The 13 keys `seo_tags/1` must emit, in this exact fixed order, each
  # paired with the attribute name that identifies it ("property", "name"
  # or "rel"). Built once here so every test iterates the same list rather
  # than hand-writing 13 near-duplicate assertions.
  @expected_keys [
    {"name", "description"},
    {"rel", "canonical"},
    {"property", "og:type"},
    {"property", "og:title"},
    {"property", "og:description"},
    {"property", "og:url"},
    {"property", "og:image"},
    {"property", "og:image:width"},
    {"property", "og:image:height"},
    {"name", "twitter:card"},
    {"name", "twitter:title"},
    {"name", "twitter:description"},
    {"name", "twitter:image"}
  ]

  @payload %{
    title: "Zombicide",
    description: "Descubrí Zombicide en Pukllay Club, Jujuy.",
    canonical_url: "https://pukllay.club/juegos/1",
    image_url: "https://pukllay.club/images/og-fallback.webp"
  }

  defp rendered(payload), do: payload |> SEOTags.seo_tags() |> rendered_to_string()

  describe "strict tag form (G-01.8-3)" do
    test "every one of the 13 keys is present with its identifying attribute first, in fixed order" do
      html = rendered(@payload)

      for {attr, key} <- @expected_keys do
        element_tag = if attr == "rel", do: "link", else: "meta"

        pattern =
          Regex.compile!("<#{element_tag}\\s+#{Regex.escape(attr)}=\"#{Regex.escape(key)}\"\\s+content=")

        # rel="canonical" has no content attribute — it has href instead.
        pattern =
          if key == "canonical" do
            Regex.compile!("<link\\s+rel=\"canonical\"\\s+href=")
          else
            pattern
          end

        assert html =~ pattern,
               "Expected #{key} to render with #{attr}= as the first attribute after the tag name, " <>
                 "with nothing interposed. Got: #{html}"
      end
    end

    test "og:image:width and og:image:height both appear after og:image (SHARE-01, edge:ordering)" do
      html = rendered(@payload)

      image_idx = image_index(html, "og:image")
      width_idx = image_index(html, "og:image:width")
      height_idx = image_index(html, "og:image:height")

      assert image_idx && width_idx && height_idx
      assert image_idx < width_idx
      assert width_idx < height_idx
    end

    test "the rendered output carries no LiveView root-tag attribute (phx-r)" do
      html = rendered(@payload)

      refute html =~ "phx-r"
    end
  end

  describe "hostile input escaping (T-01.8-22)" do
    test "a title with a double quote, ampersand and angle brackets is entity-escaped, single content= per tag, no premature terminator" do
      payload = %{@payload | title: ~s(Zombicide "2nd" & <Ed>)}

      html = rendered(payload)

      og_title_tag = extract_tag(html, ~r/<meta\s+property="og:title"[^\n]*>/)

      assert og_title_tag =~ "&quot;"
      assert og_title_tag =~ "&amp;"
      assert og_title_tag =~ "&lt;"
      assert og_title_tag =~ "&gt;"
      refute og_title_tag =~ ~s(content=""2nd"")
      assert og_title_tag |> String.split("content=") |> length() == 2
      refute og_title_tag =~ ~r/>.*>/
    end

    test "a canonical URL with a query-string ampersand is entity-escaped, not a bare &" do
      payload = %{@payload | canonical_url: "https://pukllay.club/juegos/1?a=1&b=2"}

      html = rendered(payload)

      canonical_tag = extract_tag(html, ~r/<link\s+rel="canonical"[^\n]*>/)
      og_url_tag = extract_tag(html, ~r/<meta\s+property="og:url"[^\n]*>/)

      assert canonical_tag =~ "&amp;"
      assert og_url_tag =~ "&amp;"
      refute canonical_tag =~ "a=1&b=2"
    end
  end

  describe "nil payload (crawler-visibility contract)" do
    test "renders an empty string and raises nothing" do
      html = rendered(nil)

      assert html == ""
    end
  end

  defp image_index(html, key) do
    case :binary.match(html, ~s(property="#{key}")) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  defp extract_tag(html, regex) do
    case Regex.run(regex, html) do
      [match] -> match
      nil -> flunk_missing_tag(regex, html)
    end
  end

  defp flunk_missing_tag(regex, html) do
    raise "Expected to find a tag matching #{inspect(regex)} in: #{html}"
  end
end
