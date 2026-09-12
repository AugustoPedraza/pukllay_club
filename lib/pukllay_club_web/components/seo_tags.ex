defmodule PukllayClubWeb.SEOTags do
  @moduledoc """
  Function component rendering the meta description/canonical/Open
  Graph/Twitter Card head block from `conn.assigns[:seo]` only — never a
  LiveView socket assign, since a JS-free crawler never opens one
  (PITFALLS Pitfall 1).

  Renders nothing at all when `seo` is absent, so an error page rendered
  outside the `:browser` pipeline (no `SiteSEO`/`GameSEO` plug) does not
  raise.
  """

  use Phoenix.Component

  attr :seo, :map, default: nil

  @doc """
  Renders, in this fixed order: `<meta name="description">`,
  `<link rel="canonical">`, `og:type`, `og:title`, `og:description`,
  `og:url`, `og:image`, `og:image:width` (1200), `og:image:height` (630),
  `twitter:card` (`summary_large_image`), `twitter:title`,
  `twitter:description`, `twitter:image`.

  `og:image:width`/`og:image:height` must follow the `og:image` tag they
  describe (SHARE-01, edge:ordering). Twitter's title/description/image
  read the exact same `@seo` fields their Open Graph counterparts read,
  so they can never diverge (SHARE-02).
  """
  def seo_tags(assigns) do
    ~H"""
    <%= if @seo do %>
      <meta name="description" content={@seo.description} />
      <link rel="canonical" href={@seo.canonical_url} />
      <meta property="og:type" content="website" />
      <meta property="og:title" content={@seo.title} />
      <meta property="og:description" content={@seo.description} />
      <meta property="og:url" content={@seo.canonical_url} />
      <meta property="og:image" content={@seo.image_url} />
      <meta property="og:image:width" content="1200" />
      <meta property="og:image:height" content="630" />
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={@seo.title} />
      <meta name="twitter:description" content={@seo.description} />
      <meta name="twitter:image" content={@seo.image_url} />
    <% end %>
    """
  end
end
