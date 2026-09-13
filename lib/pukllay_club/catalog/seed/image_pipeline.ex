defmodule PukllayClub.Catalog.Seed.ImagePipeline do
  @moduledoc """
  Downloads one BGG-hosted cover image, produces two club-hosted WebP
  variants, and uploads them to R2 (D-03, CATALOG-09).

  The download is host-allowlisted and size-capped (T-01-09/T-01-10): a URL
  parsed out of an untrusted BGG XML response is only as trustworthy as this
  allowlist, and an oversized/misdeclared response is rejected before it
  ever reaches the libvips decoder.

  A second, gallery-specific download-and-upload path existed here through
  phase 01.3 and was removed in phase 01.3.1: it traversed every BGG edition's
  version image with no language gate, which surfaced other-edition,
  other-language box covers as if they were extra photos of the game. See
  `process_gallery/3`'s `@doc` for why, and git history for the removed
  implementation.

  `og_card/1` (phase 01.8, D-06/D-07/D-08) is a third transform living
  alongside `process/3`: it letterboxes a game's own already-stored R2 cover
  (never the BGG original) onto a 1200x630 brand-coloured canvas for social
  sharing. It reuses `download/1`'s 15 MB cap and content-type check
  unchanged, but validates against a different host allowlist — the
  configured `:pukllay_club, :image_origin` host, the same single key
  `PukllayClubWeb.CSP.img_src/0` derives the browser policy from — so this
  module never hardcodes an R2 hostname (`csp.ex`'s moduledoc states that
  rule explicitly, for the same reason).
  """

  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.Storage

  @allowed_hosts ~w(cf.geekdo-images.com boardgamegeek.com www.boardgamegeek.com)
  @max_download_bytes 15 * 1024 * 1024
  @thumb_width 300
  @large_width 800
  @max_gallery_images 3
  @spanish_language_link "Spanish"
  @og_card_width 1200
  @og_card_height 630
  # D-07: the letterbox background is the dark theme's --color-primary,
  # which resolves to --pk-ramp-600 in assets/css/app.css (verbatim:
  # `--pk-ramp-600: #7B2DCE;`, rotated to sketch 058's H300 by quick task
  # 260912-waa). The light theme's own --color-primary (--pk-ramp-900) is
  # deliberately not used — a static social-preview image can't be
  # theme-aware, so this is the one correct literal, not a discretion call.
  @og_card_background "#7B2DCE"

  @doc """
  Downloads `source_url`, resizes it to a #{@thumb_width}px-wide thumbnail
  (cards/carousels) and an #{@large_width}px-wide large variant (detail
  page), uploads both as `<key_prefix>/cover-thumb.webp` and
  `<key_prefix>/cover-large.webp`, and returns their R2 URLs.
  """
  @spec process(String.t(), String.t(), Credentials.t()) ::
          {:ok, %{thumbnail_url: String.t(), cover_url: String.t()}} | {:error, term()}
  def process(source_url, key_prefix, %Credentials{} = credentials) do
    with :ok <- validate_url(source_url, @allowed_hosts),
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
  Always returns an empty gallery (D-01/D-02/D-03, phase 01.3.1).

  BGG's XML API v2 exposes exactly one `image` per thing and one per
  version, with no per-image caption or category field, so there is no
  gameplay/component photo to select from that surface and no signal to
  select one by. The traversal this function used to run instead walked
  every version's single box-art `image`, which meant a game's "gallery"
  was really a set of other-edition, other-language box covers presented as
  if they were extra photos of the game — confirmed at the code level on
  BGG id 305096 (Endless Winter: Paleoamericans), whose gallery included a
  Taiwanese-edition box alongside its correct Spanish cover.

  An empty gallery is the accepted outcome (01.3.1-CONTEXT.md D-03); the
  detail page already renders a cover-only game correctly. The
  #{@max_gallery_images}-image cap this function used to enforce is kept as
  a module attribute, unused for now, so a future reinstatement of gallery
  sourcing (e.g. a real gameplay/component-photo source) has a documented
  cap to pick back up rather than a number invented from scratch.
  """
  @spec process_gallery(map(), String.t(), Credentials.t()) :: {:ok, [String.t()]}
  def process_gallery(_item, _key_prefix, %Credentials{}) do
    {:ok, []}
  end

  defp spanish_version?(%{languages: languages, image: image}) do
    @spanish_language_link in languages and usable_image?(image)
  end

  defp select_primary_cover(%{image: image}) when is_binary(image) and image != "" do
    {:ok, image, :primary}
  end

  defp select_primary_cover(_item), do: {:error, :no_image}

  defp usable_image?(image), do: is_binary(image) and image != ""

  @doc """
  Fetches `cover_url` — a game's own already-stored R2 cover (D-06), never a
  BGG original — and returns a #{@og_card_width}x#{@og_card_height} WebP with
  the source letterboxed (fit, never cropped) onto the brand-coloured canvas
  (D-07/D-08).

  `cover_url`'s host must resolve against the configured `:pukllay_club,
  :image_origin` application key; every other mitigation on this download
  path (the streaming #{@max_download_bytes}-byte cap, the image
  content-type check) is byte-identical to `process/3`'s (T-01-09/T-01-10).

  Uses `Image.thumbnail/3` with `fit: :contain` to scale the source to fit
  inside the target box first, then `Image.embed/4` to pad it onto the exact
  canvas — both steps are required and the order matters: `embed/4` only
  pads and requires the canvas to be at least as large as the source on both
  axes, and the stored cover variant (produced at `@large_width` wide,
  near-square) can be taller than #{@og_card_height}px, so calling `embed/4`
  alone would fail or misbehave on exactly the images this function exists
  to handle.

  Returns `{:ok, binary}` — the caller decides the object key and the
  storage write; this function never uploads.
  """
  @spec og_card(String.t()) :: {:ok, binary()} | {:error, term()}
  def og_card(cover_url) do
    with :ok <- validate_url(cover_url, og_card_allowed_hosts()),
         {:ok, image_bytes} <- download(cover_url),
         {:ok, vimage} <- Image.open(image_bytes),
         {:ok, fitted} <- Image.thumbnail(vimage, "#{@og_card_width}x#{@og_card_height}", fit: :contain),
         {:ok, canvas} <-
           Image.embed(fitted, @og_card_width, @og_card_height, background: @og_card_background) do
      Image.write(canvas, :memory, suffix: ".webp")
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

  defp validate_url(url, allowed_hosts) do
    uri = URI.parse(url)

    if uri.scheme == "https" and uri.host in allowed_hosts do
      :ok
    else
      {:error, {:disallowed_url, url}}
    end
  end

  # Never a literal R2 hostname here (csp.ex's moduledoc states this rule
  # for exactly this reason) — derived from the same single application key
  # PukllayClubWeb.CSP.img_src/0 already scopes the browser policy to, so
  # the fetch allowlist and the rendered CSP can never name different hosts.
  defp og_card_allowed_hosts do
    case Application.get_env(:pukllay_club, :image_origin) do
      origin when is_binary(origin) and origin != "" ->
        case URI.parse(origin).host do
          nil -> []
          host -> [host]
        end

      _missing ->
        []
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
