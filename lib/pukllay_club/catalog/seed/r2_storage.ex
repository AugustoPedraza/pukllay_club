defmodule PukllayClub.Catalog.Seed.R2Storage do
  @moduledoc """
  `PukllayClub.Catalog.Seed.Storage` implementation backed by Cloudflare R2
  (S3-compatible) via `ex_aws_s3`.

  Configures `ExAws` per-call from the passed `Credentials` struct (never
  via global `Application` config) so R2 credentials never sit in the app
  environment at runtime (T-01-11). `put/4` is idempotent: an already-present
  key is detected via `head_object/3` and its URL is returned unchanged,
  which is what makes `mix catalog.seed` safely re-runnable (D-02).
  """

  @behaviour PukllayClub.Catalog.Seed.Storage

  alias PukllayClub.Catalog.Seed.Credentials

  require Logger

  @default_cache_control "public, max-age=31536000, immutable"

  @impl true
  def put(%Credentials{} = credentials, key, binary, opts \\ []) when is_binary(binary) do
    config = config_overrides(credentials)
    bucket = credentials.r2_catalog_bucket

    case ExAws.request(ExAws.S3.head_object(bucket, key), config) do
      {:ok, %{status_code: 200}} ->
        Logger.info("R2 object already present, skipping upload: #{key}")
        {:ok, Credentials.r2_object_url(credentials, key)}

      {:error, {:http_error, 404, _}} ->
        upload(bucket, key, binary, opts, credentials, config)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def list_keys(%Credentials{} = credentials, prefix) do
    config = config_overrides(credentials)
    bucket = credentials.r2_catalog_bucket

    list_keys_page(bucket, prefix, nil, config, [])
  end

  # S3's `ListObjectsV2` (and R2's implementation of it) caps a single
  # response at 1000 keys and signals more via `is_truncated`/
  # `next_continuation_token` — this catalog's "games/" prefix holds three
  # objects per covered game (cover-thumb/cover-large/og-card) plus two per
  # cover-less game, comfortably exceeding 1000 once every game has an
  # og-card. A caller of `list_keys/2` expects "every object key under
  # prefix" per this behaviour's own @doc; silently returning only the
  # first page would under-report coverage without ever raising.
  defp list_keys_page(bucket, prefix, continuation_token, config, acc) do
    opts = [prefix: prefix] ++ if continuation_token, do: [continuation_token: continuation_token], else: []

    case ExAws.request(ExAws.S3.list_objects_v2(bucket, opts), config) do
      {:ok, %{body: %{contents: contents, is_truncated: "true", next_continuation_token: token}}}
      when is_binary(token) and token != "" ->
        list_keys_page(bucket, prefix, token, config, acc ++ Enum.map(contents, & &1.key))

      {:ok, %{body: %{contents: contents}}} ->
        {:ok, acc ++ Enum.map(contents, & &1.key)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upload(bucket, key, binary, opts, credentials, config) do
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")
    cache_control = Keyword.get(opts, :cache_control, @default_cache_control)

    bucket
    |> ExAws.S3.put_object(key, binary, content_type: content_type, cache_control: cache_control)
    |> ExAws.request(config)
    |> case do
      {:ok, %{status_code: 200}} -> {:ok, Credentials.r2_object_url(credentials, key)}
      {:ok, response} -> {:error, {:unexpected_response, response}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp config_overrides(%Credentials{} = credentials) do
    [
      access_key_id: credentials.r2_access_key_id,
      secret_access_key: credentials.r2_secret_access_key,
      host: "#{credentials.r2_account_id}.r2.cloudflarestorage.com",
      scheme: "https://",
      region: "auto",
      # AGENTS.md requires Req over :hackney/:httpoison/:tesla for HTTP —
      # ex_aws ships a Req-based adapter (`req` is an optional dep it
      # already resolves against), so no extra HTTP client library is added.
      http_client: ExAws.Request.Req
    ]
  end
end
