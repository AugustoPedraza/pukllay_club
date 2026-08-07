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
