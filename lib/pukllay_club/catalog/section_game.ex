defmodule PukllayClub.Catalog.SectionGame do
  @moduledoc """
  Join row between a `PukllayClub.Catalog.Section` and a
  `PukllayClub.Catalog.Game` (D-17..D-28, 01.8.1-10) — membership for a
  `manual`-kind section, ordered by `position` when the section's own
  `sort` is `:manual`. `weight_band`/`recent` sections never have rows
  here; their membership is derived at read time from the game's own
  columns (see `PukllayClub.Catalog.section_query/1`).
  """
  use Ecto.Schema

  schema "section_games" do
    belongs_to :section, PukllayClub.Catalog.Section
    belongs_to :game, PukllayClub.Catalog.Game
    field :position, :integer

    timestamps()
  end
end
