defmodule PukllayClub.Catalog.Shelf do
  @moduledoc """
  A single physical storage location (D-10, 01.8.1-09) — a shelf/zone name
  (e.g. `L1`, `S2`, `Cooperativos`) plus its `position` in the room's
  walking order. Staff-managed only, created/renamed/reordered on
  `/admin/estantes`; never hardcoded.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "shelves" do
    field :name, :string
    field :position, :integer

    has_many :games, PukllayClub.Catalog.Game

    timestamps()
  end

  @doc """
  Changeset for create/rename (D-10). `:position` is set by
  `Catalog.Shelves.create_shelf/1`/`move_shelf/2`, not by this changeset's
  caller directly, but is castable here so both flows share one changeset.
  Name is capped at 40 characters (UI-SPEC E4 long-text).
  """
  def changeset(shelf, attrs) do
    shelf
    |> cast(attrs, [:name, :position])
    |> validate_required([:name])
    |> validate_length(:name, max: 40)
    |> unique_constraint(:name)
  end
end
