defmodule PukllayClub.Catalog.Seed.CredentialsTest do
  use ExUnit.Case, async: false

  alias PukllayClub.Catalog.Seed.Credentials

  @app :pukllay_club
  @config_key PukllayClub.Catalog.Seed

  @env_vars ~w(BGG_API_TOKEN R2_ACCOUNT_ID R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_CATALOG_BUCKET R2_PUBLIC_BASE_URL)

  setup do
    original_config = Application.get_env(@app, @config_key)
    original_env = for name <- @env_vars, into: %{}, do: {name, System.get_env(name)}

    on_exit(fn ->
      if original_config do
        Application.put_env(@app, @config_key, original_config)
      else
        Application.delete_env(@app, @config_key)
      end

      for {name, value} <- original_env do
        case value do
          nil -> System.delete_env(name)
          value -> System.put_env(name, value)
        end
      end
    end)

    for name <- @env_vars, do: System.delete_env(name)

    :ok
  end

  describe "fetch!/0" do
    test "returns a populated struct when every value is configured via Application config" do
      Application.put_env(@app, @config_key,
        bgg_api_token: "bgg-token",
        r2_account_id: "acct",
        r2_access_key_id: "key-id",
        r2_secret_access_key: "secret",
        r2_catalog_bucket: "bucket",
        r2_public_base_url: "https://example.r2.dev"
      )

      assert %Credentials{
               bgg_api_token: "bgg-token",
               r2_account_id: "acct",
               r2_access_key_id: "key-id",
               r2_secret_access_key: "secret",
               r2_catalog_bucket: "bucket",
               r2_public_base_url: "https://example.r2.dev"
             } = Credentials.fetch!()
    end

    test "an environment variable takes precedence over Application config for the same key" do
      Application.put_env(@app, @config_key,
        bgg_api_token: "config-token",
        r2_account_id: "acct",
        r2_access_key_id: "key-id",
        r2_secret_access_key: "secret",
        r2_catalog_bucket: "bucket",
        r2_public_base_url: "https://example.r2.dev"
      )

      System.put_env("BGG_API_TOKEN", "env-token")

      assert %Credentials{bgg_api_token: "env-token"} = Credentials.fetch!()
    end

    test "raises with a message naming every missing key when multiple values are absent" do
      Application.put_env(@app, @config_key,
        bgg_api_token: "bgg-token",
        r2_account_id: nil,
        r2_access_key_id: "",
        r2_catalog_bucket: "bucket",
        r2_public_base_url: "https://example.r2.dev"
      )

      error =
        assert_raise(RuntimeError, fn ->
          Credentials.fetch!()
        end)

      assert error.message =~ "R2_ACCOUNT_ID"
      assert error.message =~ "R2_ACCESS_KEY_ID"
      assert error.message =~ "R2_SECRET_ACCESS_KEY"
      assert error.message =~ "config/dev.secret.exs.example"
      refute error.message =~ "BGG_API_TOKEN"
    end

    test "inspecting the struct never reveals the token or secret key" do
      Application.put_env(@app, @config_key,
        bgg_api_token: "super-secret-token",
        r2_account_id: "acct",
        r2_access_key_id: "key-id",
        r2_secret_access_key: "super-secret-key",
        r2_catalog_bucket: "bucket",
        r2_public_base_url: "https://example.r2.dev"
      )

      credentials = Credentials.fetch!()

      refute inspect(credentials) =~ "super-secret-token"
      refute inspect(credentials) =~ "super-secret-key"
    end
  end

  describe "fetch/0" do
    test "returns {:error, missing_keys} instead of raising" do
      Application.delete_env(@app, @config_key)

      assert {:error, missing_keys} = Credentials.fetch()
      assert length(missing_keys) == 6
    end

    test "returns {:ok, struct} when everything is configured" do
      Application.put_env(@app, @config_key,
        bgg_api_token: "bgg-token",
        r2_account_id: "acct",
        r2_access_key_id: "key-id",
        r2_secret_access_key: "secret",
        r2_catalog_bucket: "bucket",
        r2_public_base_url: "https://example.r2.dev"
      )

      assert {:ok, %Credentials{}} = Credentials.fetch()
    end
  end

  describe "redacted/1" do
    test "masks exactly the three secret fields and passes the rest through unchanged" do
      credentials = %Credentials{
        bgg_api_token: "bgg-token",
        r2_account_id: "acct",
        r2_access_key_id: "key-id",
        r2_secret_access_key: "secret",
        r2_catalog_bucket: "bucket",
        r2_public_base_url: "https://example.r2.dev"
      }

      redacted = Credentials.redacted(credentials)

      assert redacted.bgg_api_token == "[REDACTED]"
      assert redacted.r2_access_key_id == "[REDACTED]"
      assert redacted.r2_secret_access_key == "[REDACTED]"
      assert redacted.r2_account_id == "acct"
      assert redacted.r2_catalog_bucket == "bucket"
      assert redacted.r2_public_base_url == "https://example.r2.dev"
    end
  end

  describe "r2_object_url/2" do
    test "joins with exactly one slash when the base URL has no trailing slash" do
      credentials = %Credentials{r2_public_base_url: "https://example.r2.dev"}

      assert Credentials.r2_object_url(credentials, "games/184267.jpg") ==
               "https://example.r2.dev/games/184267.jpg"
    end

    test "joins with exactly one slash when the base URL has a trailing slash" do
      credentials = %Credentials{r2_public_base_url: "https://example.r2.dev/"}

      assert Credentials.r2_object_url(credentials, "games/184267.jpg") ==
               "https://example.r2.dev/games/184267.jpg"
    end

    test "joins with exactly one slash when the object key has a leading slash" do
      credentials = %Credentials{r2_public_base_url: "https://example.r2.dev/"}

      assert Credentials.r2_object_url(credentials, "/games/184267.jpg") ==
               "https://example.r2.dev/games/184267.jpg"
    end
  end
end
