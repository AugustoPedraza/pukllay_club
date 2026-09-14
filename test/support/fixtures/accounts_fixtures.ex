defmodule PukllayClub.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PukllayClub.Accounts` context.
  """

  import Ecto.Query

  alias PukllayClub.Accounts
  alias PukllayClub.Accounts.Scope
  alias PukllayClub.Accounts.User

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  A valid password for the schema-level `password_changeset`/`valid_password?`
  coverage — dead code in production (no password login path ships, D-31),
  kept exercisable at the unit level per the plan's "leave in place, harmless"
  guidance.
  """
  def valid_user_password, do: "hello world!"

  @doc "Sets a password on `user` via `Accounts.update_user_password/2` (dead code, see above)."
  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  @doc "Inserts an unconfirmed `:owner` user (D-32) via `Accounts.create_owner/1`."
  def unconfirmed_owner_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Map.fetch!(:email)
      |> Accounts.create_owner()

    user
  end

  @doc """
  Inserts an unconfirmed `:staff` user.

  No production code path creates a staff account without an owner inviting
  them (a future plan), so this builds the row directly via the schema
  changeset rather than through `Accounts` — `:role` is put explicitly, never
  cast from `attrs`, matching the "never cast role from user-facing params"
  rule.
  """
  def unconfirmed_staff_fixture(attrs \\ %{}) do
    {:ok, user} =
      %User{}
      |> User.email_changeset(valid_user_attributes(attrs))
      |> Ecto.Changeset.put_change(:role, :staff)
      |> PukllayClub.Repo.insert()

    user
  end

  @doc "Inserts and confirms an `:owner` user via the real magic-link round trip."
  def owner_fixture(attrs \\ %{}) do
    attrs
    |> unconfirmed_owner_fixture()
    |> confirm_via_magic_link()
  end

  @doc "Inserts and confirms a `:staff` user via the real magic-link round trip."
  def staff_fixture(attrs \\ %{}) do
    attrs
    |> unconfirmed_staff_fixture()
    |> confirm_via_magic_link()
  end

  defp confirm_via_magic_link(user) do
    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} = Accounts.login_user_by_magic_link(token)
    user
  end

  def user_scope_fixture do
    user = staff_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    PukllayClub.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    PukllayClub.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    PukllayClub.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
