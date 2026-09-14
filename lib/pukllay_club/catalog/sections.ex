defmodule PukllayClub.Catalog.Sections do
  @moduledoc """
  Staff section management (D-17..D-28, 01.8.1-12) — a focused sub-context
  under `Catalog`, mirroring `PukllayClub.Catalog.Shelves`' shape: section
  management is staff-only, so it stays out of `PukllayClub.Catalog`, the
  public read surface every home-page render and filter goes through
  (`list_home_sections/0`, `section_page/3`, `facet_options/0`,
  `put_section_names/1`).

  Every write here goes through the same `sections`/`section_games` rows
  `Catalog.list_home_sections/0` reads — a save on `/admin/secciones`
  or its member picker is visible on the next public home render with no
  extra plumbing (D-17/D-18).
  """

  import Ecto.Changeset
  import Ecto.Query

  alias PukllayClub.Catalog.Section
  alias PukllayClub.Repo

  @doc """
  Every section (hidden included), featured first then by `position`
  (D-17, D-18) — the admin list needs to see everything, unlike
  `Catalog.list_home_sections/0`'s public "hidden and empty sections
  never render" rule.
  """
  def list_sections do
    Repo.all(from s in Section, order_by: [desc: s.featured, asc: s.position, asc: s.id])
  end

  @doc "Fetches a section by id, raising `Ecto.NoResultsError` for an unknown id."
  def get_section!(id), do: Repo.get!(Section, id)

  @doc """
  Builds a settings-edit changeset for `section` (D-17, E6) via
  `Section.settings_changeset/2`. Used by `Admin.SectionLive.Edit` for
  both the initial form and live `phx-change="validate"` re-validation.
  """
  def change_section(%Section{} = section, attrs \\ %{}) do
    Section.settings_changeset(section, attrs)
  end

  @doc """
  Persists a settings edit to `section` (D-17, E6: name up to 40 chars,
  subtitle up to 160, hidden, and a kind-aware sort) via
  `Section.settings_changeset/2`. Returns `{:ok, section}` /
  `{:error, changeset}`.
  """
  def update_section(%Section{} = section, attrs) do
    section
    |> Section.settings_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a new hand-picked section (D-17, "Crear sección") at the last
  walking position (max existing `position` + 1, or 1 for the very first
  section) via `Section.create_changeset/2` — always `:manual`, `:sort ==
  :manual`, `featured == false` (only the migration backfill ever creates
  a `:weight_band`/`:recent`/featured section). Returns `{:ok, section}` /
  `{:error, changeset}` (e.g. a blank or over-40-character name).
  """
  def create_section(attrs) do
    %Section{}
    |> Section.create_changeset(Map.put(normalize_attrs(attrs), :position, next_position()))
    |> Repo.insert()
  end

  defp next_position do
    case Repo.one(from s in Section, select: max(s.position)) do
      nil -> 1
      max -> max + 1
    end
  end

  defp normalize_attrs(attrs) when is_map(attrs), do: attrs
  defp normalize_attrs(attrs), do: Map.new(attrs)

  @doc """
  Swaps `section`'s walking-order `position` with its immediate neighbour
  in `direction` (`:up` moves it earlier, `:down` moves it later) — D-18,
  D-19. The featured section is never movable (D-18: it is always pinned
  first, with no ↑/↓ controls in the UI) — a no-op returning `{:ok,
  section}` unchanged, mirroring `Shelves.move_shelf/2`'s own no-op-at-
  either-end shape for the first/last non-featured section. Neighbours
  are found only among OTHER non-featured sections, so the featured
  section's own `position` value (whatever it happens to be) never
  affects a non-featured reorder. Both updates happen inside one
  transaction, same reasoning as `Shelves.move_shelf/2`.
  """
  def move_section(%Section{featured: true} = section, direction) when direction in [:up, :down] do
    {:ok, section}
  end

  def move_section(%Section{featured: false, position: original_position} = section, direction)
      when direction in [:up, :down] do
    case section_neighbor(section, direction) do
      nil ->
        {:ok, section}

      neighbor ->
        Repo.transaction(fn ->
          {:ok, section} = update_position(section, neighbor.position)
          {:ok, _neighbor} = update_position(neighbor, original_position)
          section
        end)
    end
  end

  defp update_position(%Section{} = section, position) do
    section
    |> change(position: position)
    |> Repo.update()
  end

  defp section_neighbor(%Section{position: position}, :up) do
    Repo.one(
      from s in Section,
        where: s.featured == false and s.position < ^position,
        order_by: [desc: s.position],
        limit: 1
    )
  end

  defp section_neighbor(%Section{position: position}, :down) do
    Repo.one(
      from s in Section,
        where: s.featured == false and s.position > ^position,
        order_by: [asc: s.position],
        limit: 1
    )
  end
end
