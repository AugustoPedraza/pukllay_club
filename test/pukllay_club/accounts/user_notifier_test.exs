defmodule PukllayClub.Accounts.UserNotifierTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias PukllayClub.Accounts.User
  alias PukllayClub.Accounts.UserNotifier

  # D-36: the sender is declared exactly once (config :pukllay_club,
  # :mail_from) and read via Application.fetch_env!/2 — never a literal in
  # UserNotifier itself.
  @expected_from Application.compile_env!(:pukllay_club, :mail_from)

  describe "deliver_login_instructions/2 sender (D-36)" do
    test "a returning-login email is sent from the single configured sender" do
      user = %User{email: "staff@example.com", confirmed_at: DateTime.utc_now()}

      {:ok, _email} = UserNotifier.deliver_login_instructions(user, "https://pukllay.club/admin")

      assert_email_sent(from: @expected_from)
    end

    test "an invite (unconfirmed) email is sent from the single configured sender" do
      user = %User{email: "new-staff@example.com", confirmed_at: nil}

      {:ok, _email} = UserNotifier.deliver_login_instructions(user, "https://pukllay.club/admin")

      assert_email_sent(from: @expected_from)
    end
  end
end
