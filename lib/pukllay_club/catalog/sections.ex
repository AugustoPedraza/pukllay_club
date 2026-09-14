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
end
