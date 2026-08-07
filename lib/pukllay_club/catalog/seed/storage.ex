defmodule PukllayClub.Catalog.Seed.Storage do
  @moduledoc """
  Behaviour for the seed pipeline's object storage boundary. The default
  implementation is `PukllayClub.Catalog.Seed.R2Storage`; tests substitute a
  double via `config :pukllay_club, :catalog_storage, MyDouble` so
  `ImagePipeline` tests never touch the network.
  """

  alias PukllayClub.Catalog.Seed.Credentials

  @doc """
  Uploads `binary` at `key`, or skips the upload and returns the existing
  object's URL when `key` is already present (idempotent re-run, D-02).
  """
  @callback put(Credentials.t(), key :: String.t(), binary :: binary(), opts :: keyword()) ::
              {:ok, url :: String.t()} | {:error, term()}

  @doc """
  Lists every object key under `prefix`.
  """
  @callback list_keys(Credentials.t(), prefix :: String.t()) ::
              {:ok, [String.t()]} | {:error, term()}

  @doc "Resolves the configured storage implementation (default: `R2Storage`)."
  @spec impl() :: module()
  def impl do
    Application.get_env(:pukllay_club, :catalog_storage, PukllayClub.Catalog.Seed.R2Storage)
  end
end
