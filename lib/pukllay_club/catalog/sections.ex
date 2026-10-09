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

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.SectionGame
  alias PukllayClub.Repo

  # D-26: the featured section is capped at ~20 hand-picked games; every
  # other manual section is uncapped. Checked inside the same transaction
  # as the insert (T-01.8.1-56) so two concurrent adds can never push the
  # featured section past the cap.
  @featured_cap 20

  # Postgres' bigint maximum. A deliberate, documented mirror of
  # `Catalog`'s own private copy — the two live in different layers and
  # must change together. An id above it reaches Postgrex and raises
  # `DBConnection.EncodeError` (verified), so the positional writers
  # range-check a game id before any query binds it.
  @max_bigint 9_223_372_036_854_775_807

  @doc """
  The featured section's member cap (D-26) — the one place the number
  lives, so a caller never carries a second `20` literal.
  """
  def featured_cap, do: @featured_cap

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

  @doc """
  Places `game_id` in `section` at the chosen gap `slot` — the positional
  counterpart to `add_game/2`'s append (01.8.4, CTX-01).

  **The slot index is 0-based**: `0` means before the first cover, `n`
  means after the last, where `n` is the current member count. Stored
  `section_games.position` values stay dense `1..n` — the slot index is a
  rail concept, not a column value. `add_game/2` keeps its own `max + 1`
  path untouched; this is the general positional writer beside it.

  Everything runs in one transaction that first re-reads the section row
  `FOR UPDATE`, taking `kind` and `featured` from THAT row (the passed
  struct can be stale), so the cap's count-then-insert cannot race. The
  member order is loaded inside the lock and positions are then
  **rewritten `1..n` from the new order** rather than shifted — which also
  heals any non-dense positions already stored.

  Returns `{:ok, %{section: locked_section, index: slot}}` or one of
  `{:error, :automatic_section | :already_member | :featured_full |
  :index_out_of_range | :game_not_found}`. A slot outside `0..n` is
  rejected, never clamped into range: clamping would silently place the
  game somewhere other than the gap the caller named. A retired or
  unknown game id (including one above the bigint maximum) is
  `:game_not_found` rather than a raise.
  """
  def insert_game_at(%Section{kind: :manual} = section, game_id, slot) do
    Repo.transaction(fn ->
      locked = lock_section!(section.id)

      if locked.kind != :manual, do: Repo.rollback(:automatic_section)

      rows = ordered_member_rows(locked.id)
      ids = Enum.map(rows, & &1.game_id)

      case validate_insert(locked, ids, game_id, slot) do
        :ok ->
          new_ids = List.insert_at(ids, slot, game_id)
          positions = new_ids |> Enum.with_index(1) |> Map.new()

          renumber_changed_rows(rows, positions)
          Repo.insert!(%SectionGame{section_id: locked.id, game_id: game_id, position: Map.fetch!(positions, game_id)})

          %{section: locked, index: slot}

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  def insert_game_at(%Section{}, _game_id, _slot), do: {:error, :automatic_section}

  # The order matters: the bounds check runs before the already-member
  # check, so a forged slot on an existing member reports the slot problem
  # rather than masking it.
  defp validate_insert(locked, ids, game_id, slot) do
    cond do
      not (is_integer(slot) and slot >= 0 and slot <= length(ids)) -> {:error, :index_out_of_range}
      game_id in ids -> {:error, :already_member}
      not live_game?(game_id) -> {:error, :game_not_found}
      locked.featured and length(ids) >= @featured_cap -> {:error, :featured_full}
      true -> :ok
    end
  end

  # Re-reads the section row under a row lock (`FOR UPDATE`) — the lock is
  # held until the surrounding transaction ends, so a second caller's
  # count-then-insert blocks until the first commits.
  defp lock_section!(section_id) do
    Repo.one!(from s in Section, where: s.id == ^section_id, lock: "FOR UPDATE")
  end

  defp ordered_member_rows(section_id) do
    Repo.all(from sg in SectionGame, where: sg.section_id == ^section_id, order_by: [asc: sg.position, asc: sg.id])
  end

  # Rewrites only the rows whose stored position differs from the dense
  # position the new order assigns them.
  defp renumber_changed_rows(rows, positions) do
    Enum.each(rows, fn row ->
      new_position = Map.fetch!(positions, row.game_id)
      if new_position != row.position, do: {:ok, _row} = update_member_position(row, new_position)
    end)
  end

  defp live_game?(game_id) when is_integer(game_id) and game_id >= 1 and game_id <= @max_bigint do
    retired = :retired
    Repo.exists?(from g in Game, where: g.id == ^game_id and g.status != ^retired)
  end

  defp live_game?(_game_id), do: false

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
