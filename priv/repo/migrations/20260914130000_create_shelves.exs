defmodule PukllayClub.Repo.Migrations.CreateShelves do
  use Ecto.Migration

  @moduledoc """
  `shelves` (D-10, D-11, 01.8.1-09): a staff-managed table of physical
  storage locations (e.g. `L1`, `S2`, `Cooperativos`) with a walking-order
  `position`. Games are given **at most one location** — `games.shelf_id`
  is nullable (an unplaced game has none) and `on_delete: :nilify_all` so
  deleting a shelf never deletes the games on it, it just unplaces them.
  Copies of a multi-unit game (`games.units > 1`) are assumed stored
  together — there is no in-shelf position, "shelf number is enough"
  (staff-admin-decisions.md).

  No seed rows: the room layout is entered by staff on `/admin/estantes`
  (UI-SPEC E5 has an explicit empty state for zero shelves) — this is
  deliberately not hardcoded.
  """

  def change do
    create table(:shelves) do
      add :name, :string, null: false
      add :position, :integer, null: false

      timestamps()
    end

    create unique_index(:shelves, [:name])

    alter table(:games) do
      add :shelf_id, references(:shelves, on_delete: :nilify_all)
    end

    create index(:games, [:shelf_id])
  end
end
