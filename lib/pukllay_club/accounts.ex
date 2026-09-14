defmodule PukllayClub.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  ## Database getters
  alias PukllayClub.Accounts.Scope
  alias PukllayClub.Accounts.User
  alias PukllayClub.Accounts.UserNotifier
  alias PukllayClub.Accounts.UserToken
  alias PukllayClub.Repo

  @max_staff 3

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """

  ## Owner creation

  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates the club owner account (D-32).

  Invoked exactly once, from `PukllayClub.Release.create_owner/1` via
  `bin/pukllay_club eval` over SSH — never through a public route. Builds an
  unconfirmed `%User{role: :owner}` through `User.email_changeset/2`; the
  owner confirms and signs in the same way a magic-link invite would.

  ## Examples

      iex> create_owner("owner@example.com")
      {:ok, %User{}}

      iex> create_owner("not an email")
      {:error, %Ecto.Changeset{}}

  """

  ## Settings

  def create_owner(email) do
    %User{}
    |> User.email_changeset(%{email: email})
    |> Ecto.Changeset.put_change(:role, :owner)
    |> Repo.insert()
  end

  ## Staff (D-32, D-33)

  @doc """
  Invites a new staff member by email.

  Only the owner may invite (D-33) — returns `{:error, :unauthorized}` for
  any other scope, checked here directly (not just at the LiveView mount)
  so this holds even if `Admin.StaffLive.Index` is bypassed (T-01.8.1-32).
  The roster is capped at #{@max_staff} invited staff plus the owner; once
  reached, returns `{:error, :staff_limit_reached}` instead of inserting.

  On success, inserts an unconfirmed `%User{role: :staff}` (no password) via
  `User.email_changeset/2` — the same shape `create_owner/1` uses. This
  function does not send the invite email: the caller delivers it via
  `deliver_login_instructions/2` and, if delivery fails, rolls the insert
  back via `delete_invited_user/1` (UI-SPEC "Error state (invite email
  failed)").

  ## Examples

      iex> invite_staff(owner_scope, "nueva@example.com")
      {:ok, %User{role: :staff, confirmed_at: nil}}

      iex> invite_staff(staff_scope, "nueva@example.com")
      {:error, :unauthorized}

  """
  def invite_staff(%Scope{user: %User{} = user}, email) do
    cond do
      not User.owner?(user) ->
        {:error, :unauthorized}

      count_staff() >= @max_staff ->
        {:error, :staff_limit_reached}

      true ->
        %User{}
        |> User.email_changeset(%{email: email})
        |> Ecto.Changeset.put_change(:role, :staff)
        |> Repo.insert()
    end
  end

  defp count_staff, do: Repo.aggregate(from(u in User, where: u.role == :staff), :count)

  @doc """
  Lists every account (owner then invited staff, ordered by email within
  each), for the owner-only staff roster (D-33, UI-SPEC E9).

  Returns `{:error, :unauthorized}` for a non-owner scope (defense in depth
  — `Admin.StaffLive.Index` also redirects a non-owner at mount).

  ## Examples

      iex> list_staff(owner_scope)
      [%User{role: :owner}, %User{role: :staff}, ...]

  """
  def list_staff(%Scope{user: %User{} = user}) do
    if User.owner?(user) do
      # ":owner" sorts before ":staff" lexicographically, so plain ascending
      # order on the enum's underlying string already puts the owner first.
      Repo.all(from(u in User, order_by: [asc: u.role, asc: u.email]))
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a still-unconfirmed invited user — the rollback `invite_staff/2`'s
  caller uses when `deliver_login_instructions/2` fails right after the
  insert, so a failed invite email never leaves an orphaned staff row
  (UI-SPEC "Error state (invite email failed)").
  """
  def delete_invited_user(%User{} = user), do: Repo.delete(user)

  @doc """
  Removes a staff member's account (D-33), revoking their panel access.

  Returns `{:error, :unauthorized}` unless the scope user is the owner AND
  the target exists with role `:staff` AND is not the scope user itself —
  the owner can never remove themself or another owner (T-01.8.1-34).

  On success returns `{:ok, tokens}`: the target's tokens, snapshotted
  before the delete (which cascades to `users_tokens` via
  `on_delete: :delete_all`) so the caller can broadcast-disconnect them via
  `PukllayClubWeb.UserAuth.disconnect_sessions/1` — deleting the user row
  alone does not sever an already-open LiveView socket.

  ## Examples

      iex> remove_staff(owner_scope, staff.id)
      {:ok, [%UserToken{}, ...]}

      iex> remove_staff(owner_scope, owner.id)
      {:error, :unauthorized}

  """
  def remove_staff(%Scope{user: %User{} = actor}, user_id) do
    with true <- User.owner?(actor),
         %User{role: :staff} = target when target.id != actor.id <- Repo.get(User, user_id) do
      Repo.transact(fn ->
        tokens = Repo.all_by(UserToken, user_id: target.id)
        {:ok, _deleted} = Repo.delete(target)
        {:ok, tokens}
      end)
    else
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.shift(DateTime.utc_now(), minute: minutes))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `PukllayClub.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `PukllayClub.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  ## Session

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  ## Token helper
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun) when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    notifier().deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc false
  # Test-only override seam for the invite-email delivery-failure path
  # (`Admin.StaffLive.Index`'s rollback via `delete_invited_user/1`).
  # `Swoosh.Adapters.Test` (config/test.exs) always succeeds, so there is no
  # real way to make `deliver_login_instructions/2` fail in test without
  # this indirection — a test sets `Application.put_env(:pukllay_club,
  # :accounts_notifier, SomeFakeNotifier)` (and resets it in `on_exit/1`) to
  # simulate a failed send. Never set outside a test.
  def notifier, do: Application.get_env(:pukllay_club, :accounts_notifier, UserNotifier)

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
