defmodule PukllayClub.Catalog.Seed.Credentials do
  @moduledoc """
  Resolves the BGG Bearer token and Cloudflare R2 credentials the D-02 catalog
  seed pipeline needs, and is the *only* module that reads these secrets from
  the environment or `Application` config.

  Resolution order per key: an environment variable first, then the
  `config :pukllay_club, PukllayClub.Catalog.Seed, ...` Application config —
  so the same module serves a dev machine (`config/dev.secret.exs`) and a
  CI/one-off run (plain env vars). `nil` and `""` are both treated as
  missing.

  Every seed module should log through `redacted/1`, never the raw struct —
  `inspect/1` already hides the secret fields via `@derive`, but `redacted/1`
  is what to use when building a plain map for structured logging.

  ## Required vs. optional keys

  Every key in `@keys` is **required** — `fetch/0` returns `{:error, _}` and
  `fetch!/0` raises unless every one of them resolves. `gemini_api_key` is the
  one exception: it is **optional**, resolved through the same
  environment-variable-first-then-Application-config path via `@optional_keys`,
  but it never contributes to the missing-key list. It powers exactly one
  one-off translation job (01.3-03, D-01) — a Mix task a developer runs
  manually, once, to translate every game description to Spanish. Making it
  required would break `mix catalog.seed` and every existing
  credential-dependent test for any developer who has no Gemini account.
  """

  @derive {Inspect, only: [:r2_account_id, :r2_catalog_bucket, :r2_public_base_url]}
  defstruct [
    :bgg_api_token,
    :r2_account_id,
    :r2_access_key_id,
    :r2_secret_access_key,
    :r2_catalog_bucket,
    :r2_public_base_url,
    :gemini_api_key
  ]

  @type t :: %__MODULE__{
          bgg_api_token: String.t(),
          r2_account_id: String.t(),
          r2_access_key_id: String.t(),
          r2_secret_access_key: String.t(),
          r2_catalog_bucket: String.t(),
          r2_public_base_url: String.t(),
          gemini_api_key: String.t() | nil
        }

  @app :pukllay_club
  @config_key PukllayClub.Catalog.Seed

  # {struct field, environment variable name} — every one of these is
  # required; fetch/0 raises/errors if any is missing.
  @keys [
    {:bgg_api_token, "BGG_API_TOKEN"},
    {:r2_account_id, "R2_ACCOUNT_ID"},
    {:r2_access_key_id, "R2_ACCESS_KEY_ID"},
    {:r2_secret_access_key, "R2_SECRET_ACCESS_KEY"},
    {:r2_catalog_bucket, "R2_CATALOG_BUCKET"},
    {:r2_public_base_url, "R2_PUBLIC_BASE_URL"}
  ]

  # {struct field, environment variable name} — resolved through the same
  # `resolve/2` path as @keys, but never counted as missing (01.3-03, D-01).
  @optional_keys [
    {:gemini_api_key, "GEMINI_API_KEY"}
  ]

  @secret_fields [:bgg_api_token, :r2_access_key_id, :r2_secret_access_key, :gemini_api_key]
  @redacted_mask "[REDACTED]"

  @doc """
  Every environment variable name this module resolves a credential from —
  every required key in `@keys` followed by every optional key in
  `@optional_keys`. This is the single source of truth
  `test/pukllay_club/deploy_secrets_contract_test.exs` (D-02) introspects
  to derive its expected `config/deploy.yml`/`.github/workflows/deploy.yml`
  list, rather than hardcoding a second copy that could silently drift
  from this module's real keys.
  """
  @spec env_var_names() :: [String.t()]
  def env_var_names do
    Enum.map(@keys, fn {_field, env_name} -> env_name end) ++
      Enum.map(@optional_keys, fn {_field, env_name} -> env_name end)
  end

  @doc """
  Resolves every credential, raising a `RuntimeError` naming every missing
  required key when one or more values are absent. `gemini_api_key` is
  optional and never causes this to raise.
  """
  @spec fetch!() :: t()
  def fetch! do
    case fetch() do
      {:ok, credentials} ->
        credentials

      {:error, missing_env_vars} ->
        raise "Missing seed credentials: #{Enum.join(missing_env_vars, ", ")}. " <>
                "Copy config/dev.secret.exs.example to config/dev.secret.exs and fill in " <>
                "the missing values (or set the corresponding environment variables)."
    end
  end

  @doc """
  Resolves every credential, returning `{:ok, credentials}` or
  `{:error, missing_env_var_names}` for callers that want to branch instead
  of raising. Only the required keys in `@keys` can produce `:error` — the
  optional `gemini_api_key` resolves to `nil` when absent without affecting
  the result.
  """
  @spec fetch() :: {:ok, t()} | {:error, [String.t()]}
  def fetch do
    resolved =
      Enum.map(@keys, fn {field, env_name} -> {field, env_name, resolve(field, env_name)} end)

    optional_resolved =
      Enum.map(@optional_keys, fn {field, env_name} -> {field, resolve(field, env_name)} end)

    missing_env_vars = for {_field, env_name, nil} <- resolved, do: env_name

    if missing_env_vars == [] do
      required_values = Enum.map(resolved, fn {field, _env_name, value} -> {field, value} end)
      values = required_values ++ optional_resolved
      {:ok, struct!(__MODULE__, values)}
    else
      {:error, missing_env_vars}
    end
  end

  @doc """
  Returns a plain map safe to log: `bgg_api_token`, `r2_access_key_id`,
  `r2_secret_access_key`, and `gemini_api_key` are replaced by a fixed mask
  string; the remaining fields pass through unchanged.
  """
  @spec redacted(t()) :: map()
  def redacted(%__MODULE__{} = credentials) do
    credentials
    |> Map.from_struct()
    |> Map.new(fn {field, value} ->
      if field in @secret_fields, do: {field, @redacted_mask}, else: {field, value}
    end)
  end

  @doc """
  Joins `r2_public_base_url` to `object_key` with exactly one `/`, regardless
  of whether the configured base URL has a trailing slash or the object key
  has a leading one. This is the single function that mints every stored
  image URL, enforcing CATALOG-09's "R2 host, never BGG" property.
  """
  @spec r2_object_url(t(), String.t()) :: String.t()
  def r2_object_url(%__MODULE__{r2_public_base_url: base_url}, object_key) do
    String.trim_trailing(base_url, "/") <> "/" <> String.trim_leading(object_key, "/")
  end

  defp resolve(field, env_name) do
    case blank_to_nil(System.get_env(env_name)) do
      nil ->
        @app
        |> Application.get_env(@config_key, [])
        |> Keyword.get(field)
        |> blank_to_nil()

      value ->
        value
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
