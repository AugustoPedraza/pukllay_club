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
  alias PukllayClub.Catalog.SectionGame
  alias PukllayClub.Repo

  # D-26: the featured section is capped at ~20 hand-picked games; every
  # other manual section is uncapped. Checked inside the same transaction
  # as the insert (T-01.8.1-56) so two concurrent adds can never push the
  # featured section past the cap.
  @featured_cap 20

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

  @doc """
  A `:manual` section's members (D-25), ordered by `position` (the order
  the phone picker's ↑/↓ controls manage), preloading `:game`.
  `:weight_band`/`:recent` sections always return `[]` — their membership
  is derived at read time from the game's own columns, never from
  `section_games` rows (see `Catalog.section_query/1`).
  """
  def section_members(%Section{} = section) do
    SectionGame
    |> where([sg], sg.section_id == ^section.id)
    |> order_by([sg], asc: sg.position, asc: sg.id)
    |> Repo.all()
    |> Repo.preload(:game)
  end

  @doc """
  The manual section ids `game_id` currently belongs to (D-07) — used by
  `Admin.GameLive.Form` to pre-check its Secciones fieldset.
  """
  def member_section_ids(game_id) do
    SectionGame
    |> where([sg], sg.game_id == ^game_id)
    |> select([sg], sg.section_id)
    |> Repo.all()
  end

  @doc """
  Adds `game_id` to `section` at the next position (D-25). Only
  `:manual` sections accept members — `:weight_band`/`:recent` sections
  return `{:error, :automatic_section}` (their membership is a rule, D-20/
  D-21, never a hand pick). Returns `{:error, :already_member}` for a
  game already in the section, and `{:error, :featured_full}` when the
  featured section already holds `@featured_cap` games (D-26) — the count
  check and the insert run inside the same transaction (T-01.8.1-56).
  """
  def add_game(%Section{kind: :manual} = section, game_id) do
    Repo.transaction(fn ->
      cond do
        already_member?(section.id, game_id) ->
          Repo.rollback(:already_member)

        section.featured and member_count(section.id) >= @featured_cap ->
          Repo.rollback(:featured_full)

        true ->
          Repo.insert!(%SectionGame{section_id: section.id, game_id: game_id, position: next_member_position(section.id)})
          section
      end
    end)
  end

  def add_game(%Section{}, _game_id), do: {:error, :automatic_section}

  defp already_member?(section_id, game_id) do
    Repo.exists?(from sg in SectionGame, where: sg.section_id == ^section_id and sg.game_id == ^game_id)
  end

  defp member_count(section_id) do
    Repo.aggregate(from(sg in SectionGame, where: sg.section_id == ^section_id), :count)
  end

  defp next_member_position(section_id) do
    case Repo.one(from sg in SectionGame, where: sg.section_id == ^section_id, select: max(sg.position)) do
      nil -> 1
      max -> max + 1
    end
  end

  @doc """
  Removes `game_id` from `section` and re-packs the remaining members'
  `position` values densely (1..n, no gaps) — D-25. Safe to call even if
  `game_id` was never a member (a no-op delete). Returns `{:ok, section}`.
  """
  def remove_game(%Section{} = section, game_id) do
    Repo.transaction(fn ->
      Repo.delete_all(from(sg in SectionGame, where: sg.section_id == ^section.id and sg.game_id == ^game_id))
      repack_positions(section.id)
      section
    end)
  end

  defp repack_positions(section_id) do
    SectionGame
    |> where([sg], sg.section_id == ^section_id)
    |> order_by([sg], asc: sg.position, asc: sg.id)
    |> Repo.all()
    |> Enum.with_index(1)
    |> Enum.each(fn {row, index} -> update_member_position(row, index) end)
  end

  @doc """
  Swaps `game_id`'s member position in `section` with its immediate
  neighbour (D-25) — `:up` moves it earlier, `:down` moves it later. A
  no-op at either end of the member list, and for a `game_id` that isn't
  a member. Returns `{:ok, section}`.
  """
  def move_game(%Section{} = section, game_id, direction) when direction in [:up, :down] do
    members = section_members(section)

    case {Enum.find_index(members, &(&1.game_id == game_id)), direction} do
      {nil, _direction} ->
        {:ok, section}

      {0, :up} ->
        {:ok, section}

      {index, :down} when index == length(members) - 1 ->
        {:ok, section}

      {index, :up} ->
        swap_member_positions(Enum.at(members, index), Enum.at(members, index - 1))
        {:ok, section}

      {index, :down} ->
        swap_member_positions(Enum.at(members, index), Enum.at(members, index + 1))
        {:ok, section}
    end
  end

  defp swap_member_positions(%SectionGame{position: a_position} = a, %SectionGame{position: b_position} = b) do
    Repo.transaction(fn ->
      {:ok, a} = update_member_position(a, b_position)
      {:ok, _b} = update_member_position(b, a_position)
      a
    end)
  end

  defp update_member_position(%SectionGame{} = member, position) do
    member
    |> change(position: position)
    |> Repo.update()
  end

  @doc """
  Sets `game_id`'s manual section membership to exactly `section_ids`
  (D-07, the game form's Secciones checkboxes) — adds any missing
  membership at that section's own end (respecting the featured cap,
  D-26) and removes any unchecked one, re-packing positions, all inside
  one transaction. Returns `{:ok, section_ids}` / `{:error,
  :featured_full}` (surfaced by `Admin.GameLive.Form` as a form-level
  error — the plan's own only documented failure mode for this path).
  """
  def set_game_sections(game_id, section_ids) when is_list(section_ids) do
    Repo.transaction(fn ->
      current_ids = member_section_ids(game_id)

      for section_id <- current_ids -- section_ids do
        section_id |> get_section!() |> remove_game(game_id)
      end

      for section_id <- section_ids -- current_ids, do: add_or_rollback(section_id, game_id)

      section_ids
    end)
  end

  defp add_or_rollback(section_id, game_id) do
    case section_id |> get_section!() |> add_game(game_id) do
      {:ok, _section} -> :ok
      {:error, reason} -> Repo.rollback(reason)
    end
  end
end
