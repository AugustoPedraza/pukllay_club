defmodule PukllayClub.Catalog.Section do
  @moduledoc """
  A staff-owned home page row (D-17..D-28, 01.8.1-10). `kind` decides how
  membership is determined: `manual` (hand-picked via `section_games`),
  `weight_band` (automatic — every game whose `weight_band` column equals
  `rule_value`, D-20), or `recent` (automatic — every non-expansion game,
  D-21). `sort` decides ordering within the section: `manual` orders by
  `section_games.position`, `name`/`bgg_weight`/`bgg_rating`/`recent` order
  by the matching `Game` column (see `PukllayClub.Catalog.section_query/1`).

  At most one section may have `featured: true` (enforced by a partial
  unique index in the migration) — that section always renders first, as
  the home page's hero row (D-18). `hidden` is a staff toggle, independent
  of `PukllayClub.Catalog.list_home_sections/0`'s own rule that a section
  with no published members never renders (D-24).

  No admin CRUD exists yet for this schema — Secciones management is a
  later plan's scope (D-17, D-19, D-25). `changeset/2` exists only so test
  fixtures (`PukllayClub.SectionsFixtures`) can build a section through
  the normal Ecto casting/validation path rather than hand-writing every
  `Ecto.Enum` atom's dump behaviour themselves.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias PukllayClub.Catalog.SectionGame

  @kinds [:manual, :weight_band, :recent]
  @sorts [:manual, :name, :bgg_weight, :bgg_rating, :recent]

  schema "sections" do
    field :name, :string
    field :subtitle, :string
    field :position, :integer
    field :featured, :boolean, default: false
    field :hidden, :boolean, default: false
    field :kind, Ecto.Enum, values: @kinds
    field :rule_value, :string
    field :sort, Ecto.Enum, values: @sorts, default: :name

    has_many :section_games, SectionGame
    many_to_many :games, PukllayClub.Catalog.Game, join_through: SectionGame

    timestamps()
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :subtitle, :position, :featured, :hidden, :kind, :rule_value, :sort])
    |> validate_required([:name, :position, :kind, :sort])
    |> validate_length(:name, max: 40)
    |> validate_length(:subtitle, max: 160)
  end
end
