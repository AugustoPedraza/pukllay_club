defmodule PukllayClub.Catalog.Copy do
  @moduledoc """
  A single physical copy of a game (D-01, D-02, D-03, D-04, 01.8.2-01) —
  place/move act on a copy, never on a game, reversing 01.8.1 D-11's
  "at most one shelf per game, no in-shelf position". `shelf_id`/`position`
  are both `nil` for an unplaced copy ("Sin ubicar"); `number` is the
  stable "copia N de M" identity, assigned once and never renumbered by a
  later place or move (D-03). See `PukllayClub.Catalog.Shelves` for the
  position-aware read/write paths (`copies_on_shelf/1`, `place_copy/3`).
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "copies" do
    belongs_to :game, PukllayClub.Catalog.Game
    belongs_to :shelf, PukllayClub.Catalog.Shelf
    field :position, :integer
    field :number, :integer

    timestamps()
  end

  @doc """
  Changeset casting every writable field. `:game_id` and `:number` are
  required; `:shelf_id`/`:position` are optional (both `nil` = unplaced).
  Both unique indexes from the `create_copies` migration are mirrored
  here as changeset-level `unique_constraint/2` calls so a violation
  surfaces as a changeset error instead of a raised `Ecto.ConstraintError`.
  """
  def changeset(copy, attrs) do
    copy
    |> cast(attrs, [:game_id, :shelf_id, :position, :number])
    |> validate_required([:game_id, :number])
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:shelf_id)
    |> unique_constraint([:game_id, :number])
    |> unique_constraint([:shelf_id, :position], name: :copies_shelf_position_unique)
  end
end
