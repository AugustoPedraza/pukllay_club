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

  @doc """
  Staff settings edit changeset (D-17, D-19, E6, 01.8.1-12) — `name`,
  `subtitle`, `hidden`, and `sort`. `kind` is never cast here: it is
  fixed at creation (D-17: hand-picked sections are always `:manual`;
  `:weight_band`/`:recent` sections only ever come from the migration
  backfill) and staff never change which kind a section is, only its
  settings. `sort`'s legal values depend on the section's OWN `kind`
  (read from the struct, not from `attrs`, since `kind` is never cast):
  `:manual` sections may pick any sort (D-19); `:weight_band` sections
  may never go back to `:manual` (D-20: membership always comes from
  `weight_band`, a manual pick order makes no sense without a manual
  member list); `:recent` sections are locked to `:recent` (D-21, the
  ordering IS the rule).
  """
  def settings_changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :subtitle, :hidden, :sort])
    |> validate_required([:name])
    |> validate_length(:name, max: 40)
    |> validate_length(:subtitle, max: 160)
    |> validate_sort_for_kind(section.kind)
  end

  defp validate_sort_for_kind(changeset, :weight_band) do
    validate_exclusion(changeset, :sort, [:manual], message: "no admite orden manual — el nivel define los miembros")
  end

  defp validate_sort_for_kind(changeset, :recent) do
    validate_inclusion(changeset, :sort, [:recent], message: "solo admite orden por más recientes")
  end

  defp validate_sort_for_kind(changeset, _manual_or_new), do: changeset

  @doc """
  Creation changeset for a new hand-picked section (D-17, "Crear
  sección", 01.8.1-12). Only `name`/`subtitle`/`position` are staff
  input — `kind`/`sort`/`featured` are forced rather than cast, since a
  section created through this form is always a fresh manual row: `kind`
  is always `:manual` (only the migration backfill ever creates a
  `:weight_band`/`:recent` section), `sort` defaults to `:manual` (D-19,
  the natural starting order for a section with no members yet), and
  `featured` is always `false` (D-18: the featured section is a fixed,
  pre-existing row — this form can never create a second one, which the
  migration's own partial unique index would reject anyway).
  """
  def create_changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :subtitle, :position])
    |> put_change(:kind, :manual)
    |> put_change(:sort, :manual)
    |> put_change(:featured, false)
    |> validate_required([:name, :position, :kind, :sort])
    |> validate_length(:name, max: 40)
    |> validate_length(:subtitle, max: 160)
  end
end
