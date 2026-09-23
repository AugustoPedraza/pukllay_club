defmodule PukllayClub.CopiesFixtures do
  @moduledoc """
  Test helpers for creating `PukllayClub.Catalog.Copy` fixtures
  (01.8.2-01).
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Repo

  @doc """
  Inserts a `Copy` row via `Copy.changeset/2`, overridable via `attrs`.
  Requires `:game_id` (a copy always belongs to a specific game — there
  is no sensible default). Defaults `:number` to the next free number
  for that game, so several fixture copies of one game in the same test
  never collide on the unique `[:game_id, :number]` index.
  """
  def copy_fixture(attrs) do
    attrs = Map.new(attrs)
    game_id = Map.fetch!(attrs, :game_id)
    default_attrs = %{number: next_number(game_id)}

    %Copy{}
    |> Copy.changeset(Map.merge(default_attrs, attrs))
    |> Repo.insert!()
  end

  defp next_number(game_id) do
    case Repo.one(from c in Copy, where: c.game_id == ^game_id, select: max(c.number)) do
      nil -> 1
      max -> max + 1
    end
  end
end
