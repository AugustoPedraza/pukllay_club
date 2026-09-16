defmodule PukllayClub.SectionsFixtures do
  @moduledoc """
  Test helpers for creating `PukllayClub.Catalog.Section` rows and their
  membership (D-17..D-28, 01.8.1-10) — for tests exercising the DB-driven
  home page sections rather than the retired hardcoded carousel rows.
  """

  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.SectionGame
  alias PukllayClub.Repo

  @doc """
  Inserts a `Section` row with sane defaults, overridable via `attrs`.
  `:position` defaults to a unique, monotonically increasing integer so
  several fixture sections in one test never collide — `list_home_sections/0`
  orders by `position`.
  """
  def section_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Sección de prueba #{System.unique_integer([:positive])}",
      subtitle: "Subtítulo de prueba",
      position: System.unique_integer([:positive, :monotonic]),
      kind: :manual,
      sort: :manual
    }

    %Section{}
    |> Section.changeset(Map.merge(default_attrs, Map.new(attrs)))
    |> Repo.insert!()
  end

  @doc """
  Adds `game` to `section`'s membership at `position` (default: a unique,
  monotonically increasing integer — never a `Repo.aggregate/2` count, so
  a test inserting members out of name order still gets stable, distinct
  positions).
  """
  def add_game_to_section(section, game, position \\ nil) do
    position = position || System.unique_integer([:positive, :monotonic])

    Repo.insert!(%SectionGame{section_id: section.id, game_id: game.id, position: position})
  end
end
