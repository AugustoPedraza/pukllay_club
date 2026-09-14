defmodule PukllayClub.MailerRuntimeConfigTest do
  # Mutates process-wide System env vars, so this suite must not run
  # concurrently with any other test that reads/relies on them.
  use ExUnit.Case, async: false

  # Every env var config/runtime.exs's :prod block reads (required or
  # optional) — snapshotted and restored so this test never leaks state into
  # CI's own DATABASE_URL or a developer's shell.
  @env_vars ~w(DATABASE_URL SECRET_KEY_BASE PHX_HOST R2_PUBLIC_BASE_URL RESERVATION_WHATSAPP_NUMBER MAILER_API_KEY)

  setup do
    original = Map.new(@env_vars, &{&1, System.get_env(&1)})

    on_exit(fn ->
      Enum.each(original, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    :ok
  end

  defp put_required_env(overrides \\ %{}) do
    base = %{
      "DATABASE_URL" => "ecto://user:pass@localhost/pukllay_club_prod",
      "SECRET_KEY_BASE" => String.duplicate("a", 64),
      "PHX_HOST" => "pukllay.club",
      "R2_PUBLIC_BASE_URL" => "https://pub-example.r2.dev",
      "RESERVATION_WHATSAPP_NUMBER" => "5493884103255",
      "MAILER_API_KEY" => "re_test_1234567890"
    }

    base
    |> Map.merge(overrides)
    |> Enum.each(fn {key, value} ->
      if is_nil(value) do
        System.delete_env(key)
      else
        System.put_env(key, value)
      end
    end)
  end

  describe "config/runtime.exs :prod Mailer config (D-36)" do
    test "with every required var set, reads the Resend adapter and api_key from MAILER_API_KEY" do
      put_required_env()

      config = Config.Reader.read!("config/runtime.exs", env: :prod)

      mailer_config = get_in(config, [:pukllay_club, PukllayClub.Mailer])

      assert mailer_config[:adapter] == Swoosh.Adapters.Resend
      assert mailer_config[:api_key] == "re_test_1234567890"
    end

    test "raises naming MAILER_API_KEY when it is unset" do
      put_required_env(%{"MAILER_API_KEY" => nil})

      assert_raise RuntimeError, ~r/MAILER_API_KEY/, fn ->
        Config.Reader.read!("config/runtime.exs", env: :prod)
      end
    end

    test "raises naming MAILER_API_KEY when it is blank" do
      put_required_env(%{"MAILER_API_KEY" => ""})

      assert_raise RuntimeError, ~r/MAILER_API_KEY/, fn ->
        Config.Reader.read!("config/runtime.exs", env: :prod)
      end
    end
  end
end
