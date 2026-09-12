defmodule PukllayClubWeb.SEOTags do
  @moduledoc """
  Escaping-safe markup builder for the meta description/canonical/Open
  Graph/Twitter Card head block, rendered from `conn.assigns[:seo]` only —
  never a LiveView socket assign, since a JS-free crawler never opens one
  (PITFALLS Pitfall 1).

  Renders nothing at all when `seo` is absent, so an error page rendered
  outside the `:browser` pipeline (no `SiteSEO`/`GameSEO` plug) does not
  raise.

  Deliberately NOT a HEEx function component (G-01.8-3 / T-01.8-22).
  `config/config.exs:31` sets `root_tag_attribute: "phx-r"` for
  `Phoenix.LiveView.ColocatedCSS`, and `Phoenix.LiveView.TagEngine.Compiler`
  stamps that attribute as the FIRST attribute on every tag that is a
  "local root" of its template — flipping `local_root?` to `false` only
  when it descends into an HTML tag's children (an `if` block does not flip
  it). This component's template had no wrapping element, so all 13
  sibling `<meta>`/`<link>` tags were each individually a root and got
  `phx-r` interposed before `property=`/`name=`. That is invisible to
  tolerant crawlers (Facebook Sharing Debugger, Twitter Card Validator) and
  irrelevant to Google (which never evaluates `og:image`), but WhatsApp's
  strict link-preview parser cannot read past it — see
  `.planning/debug/whatsapp-og-image-preview.md`. The config offers no
  per-template opt-out, and disabling it globally would break colocated-CSS
  scoping for the rest of the app. Building the markup in Elixir instead of
  HEEx takes the tag engine out of the path entirely, so no attribute can
  ever be stamped onto these tags again.
  """

  @doc """
  Renders, in this fixed order: `<meta name="description">`,
  `<link rel="canonical">`, `og:type`, `og:title`, `og:description`,
  `og:url`, `og:image`, `og:image:width` (1200), `og:image:height` (630),
  `twitter:card` (`summary_large_image`), `twitter:title`,
  `twitter:description`, `twitter:image`.

  `og:image:width`/`og:image:height` must follow the `og:image` tag they
  describe (SHARE-01, edge:ordering). Twitter's title/description/image
  read the exact same `seo` fields their Open Graph counterparts read, so
  they can never diverge (SHARE-02).

  Every dynamic value (`description`, `canonical_url`, `title`,
  `image_url`) reaches the output only as a value handed to
  `Phoenix.HTML.attributes_escape/1` — the same primitive
  `Phoenix.LiveView.TagEngine.Compiler` itself uses for tag attributes —
  never by direct string interpolation. Dropping the HEEx template also
  drops HEEx's automatic escaping, so this is the explicit, single escaping
  seam for this module (T-01.8-22).
  """
  @spec seo_tags(map() | nil) :: Phoenix.HTML.safe()
  def seo_tags(nil), do: Phoenix.HTML.raw([])

  def seo_tags(%{} = seo) do
    Phoenix.HTML.raw([
      meta([{"name", "description"}, {"content", seo.description}]),
      link([{"rel", "canonical"}, {"href", seo.canonical_url}]),
      meta([{"property", "og:type"}, {"content", "website"}]),
      meta([{"property", "og:title"}, {"content", seo.title}]),
      meta([{"property", "og:description"}, {"content", seo.description}]),
      meta([{"property", "og:url"}, {"content", seo.canonical_url}]),
      meta([{"property", "og:image"}, {"content", seo.image_url}]),
      meta([{"property", "og:image:width"}, {"content", "1200"}]),
      meta([{"property", "og:image:height"}, {"content", "630"}]),
      meta([{"name", "twitter:card"}, {"content", "summary_large_image"}]),
      meta([{"name", "twitter:title"}, {"content", seo.title}]),
      meta([{"name", "twitter:description"}, {"content", seo.description}]),
      meta([{"name", "twitter:image"}, {"content", seo.image_url}])
    ])
  end

  defp meta(attrs), do: tag("meta", attrs)
  defp link(attrs), do: tag("link", attrs)

  # The single escaping seam: every attribute value (dynamic or literal)
  # flows through Phoenix.HTML.attributes_escape/1, never a hand-built
  # string. attributes_escape/1 preserves list order and emits a leading
  # space before each attribute, so the identifying key (the head of
  # `attrs`) is always the first attribute after the tag name.
  defp tag(name, attrs) do
    {:safe, escaped_attrs} = Phoenix.HTML.attributes_escape(attrs)
    ["<", name, escaped_attrs, ">\n"]
  end
end
