defmodule PukllayClub.ShelvesFixtures do
  @moduledoc """
  Test helpers for creating `PukllayClub.Catalog.Shelf` fixtures
  (01.8.1-09).
  """

  alias PukllayClub.Catalog.Shelves

  @doc """
  Creates a shelf via `Shelves.create_shelf/1` (so `:position` is always
  assigned the same way production does — the next walking-order slot),
  overridable via `attrs`. Defaults to a unique name so callers can create
  several fixtures in the same test without a unique-constraint collision.
  """
  def shelf_fixture(attrs \\ %{}) do
    default_attrs = %{name: "L#{System.unique_integer([:positive])}"}

    {:ok, shelf} = Shelves.create_shelf(Map.merge(default_attrs, attrs))
    shelf
  end
end
