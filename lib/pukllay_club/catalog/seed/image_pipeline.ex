defmodule PukllayClub.Catalog.Seed.ImagePipeline do
  @moduledoc """
  Downloads one BGG-hosted cover image, produces two club-hosted WebP
  variants, and uploads them to R2 (D-03, CATALOG-09).

  The download is host-allowlisted and size-capped (T-01-09/T-01-10): a URL
  parsed out of an untrusted BGG XML response is only as trustworthy as this
  allowlist, and an oversized/misdeclared response is rejected before it
  ever reaches the libvips decoder.
  """

  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.Storage

  @allowed_hosts ~w(cf.geekdo-images.com boardgamegeek.com www.boardgamegeek.com)
  @max_download_bytes 15 * 1024 * 1024
  @thumb_width 300
  @large_width 800
  @max_gallery_images 3
  @spanish_language_link "Spanish"

  @doc """
  Downloads `source_url`, resizes it to a #{@thumb_width}px-wide thumbnail
  (cards/carousels) and an #{@large_width}px-wide large variant (detail
  page), uploads both as `<key_prefix>/cover-thumb.webp` and
  `<key_prefix>/cover-large.webp`, and returns their R2 URLs.
  """
  @spec process(String.t(), String.t(), Credentials.t()) ::
          {:ok, %{thumbnail_url: String.t(), cover_url: String.t()}} | {:error, term()}
  def process(source_url, key_prefix, %Credentials{} = credentials) do
    with :ok <- validate_url(source_url),
         {:ok, image_bytes} <- download(source_url),
         {:ok, vimage} <- Image.open(image_bytes),
         {:ok, thumb_url} <-
           resize_and_upload(vimage, @thumb_width, "#{key_prefix}/cover-thumb.webp", credentials),
         {:ok, cover_url} <-
           resize_and_upload(vimage, @large_width, "#{key_prefix}/cover-large.webp", credentials) do
      {:ok, %{thumbnail_url: thumb_url, cover_url: cover_url}}
    end
  end

  @doc """
  Picks the cover source image from a parsed BGG `thing` item (D-04):
  Spanish-language edition preferred, falling back to the item's own
  primary `image` when no version lists `Spanish` among its language links
  (or the item has no `versions` at all). Returns `{:error, :no_image}`
  when neither exists.
  """
  @spec select_cover(map()) :: {:ok, String.t(), :spanish_edition | :primary} | {:error, :no_image}
  def select_cover(item) do
    item
    |> Map.get(:versions, [])
    |> Enum.find(&spanish_version?/1)
    |> case do
      %{image: image} -> {:ok, image, :spanish_edition}
      nil -> select_primary_cover(item)
    end
  end

  @doc """
  Builds up to #{@max_gallery_images} additional club-hosted images from
  distinct BGG version images (excluding whichever one `select_cover/1`
  already chose), reusing this module's own host allowlist, size cap, and
  `head_object` skip (T-01-14) — no second, unguarded download path. A game
  with no extra version images returns `{:ok, []}` rather than a padded
  placeholder list.
  """
  @spec process_gallery(map(), String.t(), Credentials.t()) :: {:ok, [String.t()]}
  def process_gallery(item, key_prefix, %Credentials{} = credentials) do
    cover_source_url =
      case select_cover(item) do
        {:ok, url, _source} -> url
        {:error, :no_image} -> nil
      end

    item
    |> Map.get(:versions, [])
    |> Enum.map(&Map.get(&1, :image))
    |> Enum.filter(&usable_image?/1)
    |> Enum.uniq()
    |> Enum.reject(&(&1 == cover_source_url))
    |> Enum.take(@max_gallery_images)
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {source_url, index}, acc ->
      case upload_gallery_image(source_url, key_prefix, index, credentials) do
        {:ok, gallery_url} -> [gallery_url | acc]
        {:error, _reason} -> acc
      end
    end)
    |> then(&{:ok, Enum.reverse(&1)})
  end

  defp spanish_version?(%{languages: languages, image: image}) do
    @spanish_language_link in languages and usable_image?(image)
  end

  defp select_primary_cover(%{image: image}) when is_binary(image) and image != "" do
    {:ok, image, :primary}
  end

  defp select_primary_cover(_item), do: {:error, :no_image}

  defp usable_image?(image), do: is_binary(image) and image != ""

  defp upload_gallery_image(source_url, key_prefix, index, credentials) do
    with :ok <- validate_url(source_url),
         {:ok, image_bytes} <- download(source_url),
         {:ok, vimage} <- Image.open(image_bytes),
         {:ok, _thumb_url} <-
           resize_and_upload(vimage, @thumb_width, "#{key_prefix}/gallery-#{index}-thumb.webp", credentials) do
      resize_and_upload(vimage, @large_width, "#{key_prefix}/gallery-#{index}-large.webp", credentials)
    end
  end

  @doc """
  Req options merged into the download request, letting tests plug in
  `Req.Test` without that configuration ever reaching production.
  """
  @spec req_options() :: keyword()
  def req_options do
    Application.get_env(:pukllay_club, :image_download_req_options, [])
  end

  defp validate_url(url) do
    uri = URI.parse(url)

    if uri.scheme == "https" and uri.host in @allowed_hosts do
      :ok
    else
      {:error, {:disallowed_url, url}}
    end
  end

  # Req (as pinned via mix.lock) has no built-in `:max_length` option, so the
  # 15 MB cap (T-01-10) is enforced by hand: `into:` streams response chunks
  # through this accumulator, halting mid-download the moment the running
  # total exceeds the cap rather than buffering an unbounded body first.
  defp download(url) do
    into = fn {:data, data}, {req, resp} ->
      body = (resp.body || "") <> data

      if byte_size(body) > @max_download_bytes do
        {:halt, {req, %{resp | body: :too_large}}}
      else
        {:cont, {req, %{resp | body: body}}}
      end
    end

    req_opts = Keyword.merge([into: into], req_options())

    case Req.get(url, req_opts) do
      {:ok, %Req.Response{status: 200, body: :too_large}} ->
        {:error, :download_too_large}

      {:ok, %Req.Response{status: 200} = response} ->
        check_content_type(response)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_content_type(response) do
    content_type = response |> Req.Response.get_header("content-type") |> List.first() || ""

    if String.starts_with?(content_type, "image/") do
      {:ok, response.body}
    else
      {:error, {:unexpected_content_type, content_type}}
    end
  end

  defp resize_and_upload(vimage, width, key, credentials) do
    with {:ok, thumb} <- Image.thumbnail(vimage, width),
         {:ok, binary} <- Image.write(thumb, :memory, suffix: ".webp") do
      Storage.impl().put(credentials, key, binary, content_type: "image/webp")
    end
  end
end
