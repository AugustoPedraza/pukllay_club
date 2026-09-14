defmodule PukllayClub.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  @moduledoc """
  Generator-produced `users`/`users_tokens` tables (phx.gen.auth), hand-edited
  to add `role` (D-31, D-33, T-01.8.1-02).

  `role` carries **no column default** and is `NOT NULL` — deliberately, unlike
  `add_games_is_expansion`'s safe-default backfill pattern. That pattern exists
  because `games` already held live rows a new column had to backfill correctly.
  This table is brand new (this migration creates it), so there is no
  pre-existing row to backfill and no reason to pick a default a future insert
  could silently inherit. Every code path that creates a `User` (the owner
  release command, the staff-invite flow) must explicitly choose `owner` or
  `staff` — least privilege by construction, not by convention. A future Phase 2
  member-account row must make the same explicit choice rather than defaulting
  into staff access by omission.

  The `users_role_must_be_known` check constraint is a second, DB-level backstop
  against the same omission — even a hand-run `INSERT`/`Repo.insert_all` that
  bypasses the schema's `Ecto.Enum` cast is rejected by Postgres itself.
  """

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :role, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create constraint(:users, :users_role_must_be_known, check: "role IN ('owner', 'staff')")

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
