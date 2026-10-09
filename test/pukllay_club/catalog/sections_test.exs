defmodule PukllayClub.Catalog.SectionsTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Repo

  describe "list_sections/0 (D-17, 01.8.1-12)" do
    test "returns every section, hidden included, featured first then by position" do
      # The migration's own D-22 backfill already seeds one featured
      # section ("Destacados del club") — the partial unique index allows
      # only one, so tests reuse it rather than creating a second one.
      featured = Repo.get_by!(Section, featured: true)
      hidden = section_fixture(%{name: "Vieja", hidden: true})
      first = section_fixture(%{name: "Primera"})

      all = Sections.list_sections()
      assert List.first(all).id == featured.id
      assert Enum.any?(all, &(&1.id == hidden.id))
      assert Enum.any?(all, &(&1.id == first.id))
    end
  end

  describe "update_section/2 — rename (D-17, UI-SPEC E6 long-text)" do
    test "renaming a section persists the new name" do
      section = section_fixture(%{name: "Vieja"})

      assert {:ok, updated} = Sections.update_section(section, %{name: "Para arrancar"})
      assert updated.name == "Para arrancar"
    end

    test "rejects a 41-character name" do
      section = section_fixture()
      too_long = String.duplicate("a", 41)

      assert {:error, changeset} = Sections.update_section(section, %{name: too_long})
      assert "should be at most 40 character(s)" in errors_on(changeset).name
    end
  end

  describe "update_section/2 — hide (D-17, D-24)" do
    test "hiding a section removes it from list_home_sections/0" do
      section = section_fixture(%{name: "Se oculta", hidden: false})
      add_game_to_section(section, game_fixture(%{name: "Un juego"}))

      assert Enum.any?(Catalog.list_home_sections(), &(&1.section_id == section.id))

      assert {:ok, hidden} = Sections.update_section(section, %{hidden: true})
      assert hidden.hidden

      refute Enum.any?(Catalog.list_home_sections(), &(&1.section_id == section.id))
    end

    test "showing a hidden section restores it to list_home_sections/0" do
      section = section_fixture(%{name: "Vuelve", hidden: true})
      add_game_to_section(section, game_fixture(%{name: "Otro juego"}))

      refute Enum.any?(Catalog.list_home_sections(), &(&1.section_id == section.id))

      assert {:ok, _shown} = Sections.update_section(section, %{hidden: false})

      assert Enum.any?(Catalog.list_home_sections(), &(&1.section_id == section.id))
    end
  end

  describe "update_section/2 — sort validation by kind (D-19, D-20, D-21)" do
    test "a manual section accepts every sort value" do
      section = section_fixture(%{kind: :manual, sort: :manual})

      for sort <- [:manual, :name, :bgg_weight, :bgg_rating, :recent] do
        assert {:ok, updated} = Sections.update_section(section, %{sort: sort})
        assert updated.sort == sort
      end
    end

    test "a weight_band section rejects :manual" do
      section =
        section_fixture(%{kind: :weight_band, rule_value: "nivel_experto", sort: :name})

      assert {:error, changeset} = Sections.update_section(section, %{sort: :manual})
      assert changeset.errors[:sort]
    end

    test "a weight_band section accepts a non-manual sort" do
      section =
        section_fixture(%{kind: :weight_band, rule_value: "nivel_experto", sort: :name})

      assert {:ok, updated} = Sections.update_section(section, %{sort: :bgg_weight})
      assert updated.sort == :bgg_weight
    end

    test "a recent section only accepts :recent" do
      section = section_fixture(%{kind: :recent, sort: :recent})

      assert {:error, changeset} = Sections.update_section(section, %{sort: :name})
      assert changeset.errors[:sort]

      assert {:ok, updated} = Sections.update_section(section, %{sort: :recent})
      assert updated.sort == :recent
    end
  end

  describe "create_section/1 (D-17, \"Crear sección\")" do
    test "creates a manual, non-featured, not-hidden section at the last position" do
      max_position_before =
        Sections.list_sections() |> Enum.map(& &1.position) |> Enum.max(fn -> 0 end)

      assert {:ok, section} = Sections.create_section(%{name: "Spiel des Jahres"})

      assert section.kind == :manual
      assert section.sort == :manual
      assert section.featured == false
      assert section.hidden == false
      assert section.position > max_position_before
    end

    test "rejects a blank name" do
      assert {:error, changeset} = Sections.create_section(%{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects a 41-character name" do
      assert {:error, changeset} = Sections.create_section(%{name: String.duplicate("a", 41)})
      assert "should be at most 40 character(s)" in errors_on(changeset).name
    end
  end

  describe "move_section/2 (D-18, D-19)" do
    test "moving a non-featured section down swaps it with its next non-featured neighbour" do
      a = section_fixture(%{name: "A", position: 100})
      b = section_fixture(%{name: "B", position: 101})

      assert {:ok, moved} = Sections.move_section(a, :down)
      assert moved.position == 101

      assert Sections.get_section!(b.id).position == 100
    end

    test "moving the first non-featured section up is a no-op" do
      # The migration backfill already seeds non-featured sections at
      # positions 1-7 (and the featured one at 0) — these fixtures use
      # deliberately far-below-everything positions so "first" is
      # unambiguous regardless of that pre-existing data.
      first = section_fixture(%{name: "Primera", position: -1000})
      _second = section_fixture(%{name: "Segunda", position: -999})

      assert {:ok, unchanged} = Sections.move_section(first, :up)
      assert unchanged.position == first.position
    end

    test "moving the last non-featured section down is a no-op" do
      _first = section_fixture(%{name: "Primera", position: 100_000})
      last = section_fixture(%{name: "Última", position: 100_001})

      assert {:ok, unchanged} = Sections.move_section(last, :down)
      assert unchanged.position == last.position
    end

    test "the featured section can never be moved" do
      featured = Repo.get_by!(Section, featured: true)
      original_position = featured.position

      assert {:ok, unchanged} = Sections.move_section(featured, :up)
      assert unchanged.position == original_position

      assert {:ok, unchanged} = Sections.move_section(featured, :down)
      assert unchanged.position == original_position
    end

    test "a non-featured section's neighbour search ignores the featured section's own position" do
      # The featured section's real position (0, per the migration
      # backfill) is smaller than this fixture's own -2000 — moving the
      # (now genuinely first) non-featured section up must still be a
      # no-op, never swap with the featured row.
      first_non_featured = section_fixture(%{name: "Primera no destacada", position: -2000})

      assert {:ok, unchanged} = Sections.move_section(first_non_featured, :up)
      assert unchanged.position == first_non_featured.position
      assert Repo.get_by!(Section, featured: true).position != first_non_featured.position
    end
  end

  describe "add_game/2 (D-25, D-26, T-01.8.1-56)" do
    test "appends at the next position" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game_a = game_fixture(%{name: "A"})
      game_b = game_fixture(%{name: "B"})

      assert {:ok, _section} = Sections.add_game(section, game_a.id)
      assert {:ok, _section} = Sections.add_game(section, game_b.id)

      assert section |> Sections.section_members() |> Enum.map(& &1.game_id) == [
               game_a.id,
               game_b.id
             ]
    end

    test "adding the same game twice returns {:error, :already_member}" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture()

      assert {:ok, _section} = Sections.add_game(section, game.id)
      assert {:error, :already_member} = Sections.add_game(section, game.id)
    end

    test "adding to a weight_band section returns {:error, :automatic_section}" do
      section = section_fixture(%{kind: :weight_band, rule_value: "nivel_experto", sort: :name})
      game = game_fixture()

      assert {:error, :automatic_section} = Sections.add_game(section, game.id)
    end

    test "adding to a recent section returns {:error, :automatic_section}" do
      section = section_fixture(%{kind: :recent, sort: :recent})
      game = game_fixture()

      assert {:error, :automatic_section} = Sections.add_game(section, game.id)
    end

    test "the featured section with 20 members returns {:error, :featured_full} on a 21st add" do
      featured = Repo.get_by!(Section, featured: true)

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      end

      assert {:error, :featured_full} = Sections.add_game(featured, game_fixture().id)
    end

    test "a manual (non-featured) section with 20 members accepts a 21st" do
      section = section_fixture(%{kind: :manual, sort: :manual})

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(section, game_fixture().id)
      end

      assert {:ok, _section} = Sections.add_game(section, game_fixture().id)
    end
  end

  describe "insert_game_at/3 (01.8.4, CTX-01) — places at the chosen slot" do
    setup do
      section = section_fixture(%{kind: :manual, sort: :manual})
      a = game_fixture(%{name: "A"})
      b = game_fixture(%{name: "B"})
      {:ok, _} = Sections.add_game(section, a.id)
      {:ok, _} = Sections.add_game(section, b.id)
      %{section: section, a: a, b: b, new: game_fixture(%{name: "Nuevo"})}
    end

    test "slot 0 places before the first member, positions dense 1..3", ctx do
      assert {:ok, %{index: 0}} = Sections.insert_game_at(ctx.section, ctx.new.id, 0)

      members = Sections.section_members(ctx.section)
      assert Enum.map(members, & &1.game_id) == [ctx.new.id, ctx.a.id, ctx.b.id]
      assert Enum.map(members, & &1.position) == Enum.to_list(1..3)
    end

    test "a middle slot places between two members, positions dense 1..3", ctx do
      assert {:ok, %{index: 1}} = Sections.insert_game_at(ctx.section, ctx.new.id, 1)

      members = Sections.section_members(ctx.section)
      assert Enum.map(members, & &1.game_id) == [ctx.a.id, ctx.new.id, ctx.b.id]
      assert Enum.map(members, & &1.position) == Enum.to_list(1..3)
    end

    test "slot n places after the last member, positions dense 1..3", ctx do
      assert {:ok, %{index: 2}} = Sections.insert_game_at(ctx.section, ctx.new.id, 2)

      members = Sections.section_members(ctx.section)
      assert Enum.map(members, & &1.game_id) == [ctx.a.id, ctx.b.id, ctx.new.id]
      assert Enum.map(members, & &1.position) == Enum.to_list(1..3)
    end

    test "returns the locked section row", ctx do
      assert {:ok, %{section: section}} = Sections.insert_game_at(ctx.section, ctx.new.id, 0)
      assert section.id == ctx.section.id
    end
  end

  describe "insert_game_at/3 (01.8.4, CTX-01) — the edge matrix" do
    defp snapshot(section), do: section |> Sections.section_members() |> Enum.map(&{&1.game_id, &1.position})

    defp positions(section), do: section |> Sections.section_members() |> Enum.map(& &1.position)

    defp manual_section_with(count) do
      section = section_fixture(%{kind: :manual, sort: :manual})
      games = for i <- 1..count//1, do: game_fixture(%{name: "G#{i}"})
      for game <- games, do: {:ok, _} = Sections.add_game(section, game.id)
      {section, games}
    end

    test "slot -1 and slot n + 1 are :index_out_of_range and write nothing" do
      {section, _games} = manual_section_with(2)
      before = snapshot(section)

      assert {:error, :index_out_of_range} = Sections.insert_game_at(section, game_fixture().id, -1)
      assert {:error, :index_out_of_range} = Sections.insert_game_at(section, game_fixture().id, 3)
      assert snapshot(section) == before
    end

    test "a slot that is not an integer is :index_out_of_range and writes nothing" do
      {section, _games} = manual_section_with(2)
      before = snapshot(section)

      for bad <- ["1", 1.0, nil, :one, [1]] do
        assert {:error, :index_out_of_range} = Sections.insert_game_at(section, game_fixture().id, bad)
      end

      assert snapshot(section) == before
    end

    test "the bounds check runs before the already-member check" do
      {section, [first | _]} = manual_section_with(2)

      assert {:error, :index_out_of_range} = Sections.insert_game_at(section, first.id, 99)
    end

    test "an empty row accepts slot 0 only" do
      {section, []} = manual_section_with(0)

      assert {:error, :index_out_of_range} = Sections.insert_game_at(section, game_fixture().id, 1)
      assert {:ok, %{index: 0}} = Sections.insert_game_at(section, game_fixture().id, 0)
      assert positions(section) == [1]
    end

    test "a game id above Postgres' bigint maximum is :game_not_found, not a raise" do
      {section, _games} = manual_section_with(1)
      before = snapshot(section)

      assert {:error, :game_not_found} = Sections.insert_game_at(section, 99_999_999_999_999_999_999, 0)
      assert snapshot(section) == before
    end

    test "an unknown but in-range game id is :game_not_found, not an Ecto.ConstraintError" do
      {section, _games} = manual_section_with(1)
      before = snapshot(section)

      assert {:error, :game_not_found} = Sections.insert_game_at(section, 9_000_000_000_000, 0)
      assert snapshot(section) == before
    end

    test "a retired game is :game_not_found" do
      {section, _games} = manual_section_with(1)
      retired = game_fixture(%{status: :retired})

      assert {:error, :game_not_found} = Sections.insert_game_at(section, retired.id, 0)
    end

    test "inserting the same game twice is :already_member and positions stay dense" do
      {section, _games} = manual_section_with(2)
      game = game_fixture()

      assert {:ok, _} = Sections.insert_game_at(section, game.id, 1)
      assert {:error, :already_member} = Sections.insert_game_at(section, game.id, 0)
      assert positions(section) == Enum.to_list(1..3)
    end

    test "the featured row at exactly 20 members is :featured_full for a 21st" do
      featured = Repo.get_by!(Section, featured: true)
      for _ <- 1..20, do: {:ok, _} = Sections.add_game(featured, game_fixture().id)
      before = snapshot(featured)

      assert {:error, :featured_full} = Sections.insert_game_at(featured, game_fixture().id, 0)
      assert snapshot(featured) == before
    end

    test "the cap is read from the locked row, not the passed (stale) struct" do
      featured = Repo.get_by!(Section, featured: true)
      for _ <- 1..20, do: {:ok, _} = Sections.add_game(featured, game_fixture().id)

      stale = %{featured | featured: false}

      assert {:error, :featured_full} = Sections.insert_game_at(stale, game_fixture().id, 0)
    end

    test "a non-featured manual row at 20 members accepts a 21st" do
      {section, _games} = manual_section_with(20)

      assert {:ok, _} = Sections.insert_game_at(section, game_fixture().id, 20)
      assert positions(section) == Enum.to_list(1..21)
    end

    test "weight_band and recent rows are :automatic_section and write nothing" do
      for attrs <- [%{kind: :weight_band, rule_value: "nivel_experto", sort: :name}, %{kind: :recent, sort: :recent}] do
        section = section_fixture(attrs)
        assert {:error, :automatic_section} = Sections.insert_game_at(section, game_fixture().id, 0)
        assert snapshot(section) == []
      end
    end

    test "the kind is read from the locked row, not the passed (stale) struct" do
      automatic = section_fixture(%{kind: :recent, sort: :recent})
      stale = %{automatic | kind: :manual}

      assert {:error, :automatic_section} = Sections.insert_game_at(stale, game_fixture().id, 0)
      assert snapshot(automatic) == []
    end

    test "renumbering heals non-dense stored positions" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      add_game_to_section(section, game_fixture(), 500)
      add_game_to_section(section, game_fixture(), 700)

      assert {:ok, _} = Sections.insert_game_at(section, game_fixture().id, 1)
      assert positions(section) == Enum.to_list(1..3)
    end

    test "two members sharing one position value keep one deterministic id order" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      g1 = game_fixture()
      g2 = game_fixture()
      add_game_to_section(section, g1, 7)
      add_game_to_section(section, g2, 7)

      assert section |> Sections.section_members() |> Enum.map(& &1.game_id) == [g1.id, g2.id]

      new = game_fixture()
      assert {:ok, _} = Sections.insert_game_at(section, new.id, 1)
      assert section |> Sections.section_members() |> Enum.map(& &1.game_id) == [g1.id, new.id, g2.id]
      assert positions(section) == [1, 2, 3]
    end

    test "mixed-writer invariant: any interleaving of add_game, insert_game_at and remove_game leaves positions 1..n" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      [a, b, c, d, e] = for _ <- 1..5, do: game_fixture()

      {:ok, _} = Sections.add_game(section, a.id)
      {:ok, _} = Sections.insert_game_at(section, b.id, 0)
      {:ok, _} = Sections.add_game(section, c.id)
      {:ok, _} = Sections.insert_game_at(section, d.id, 1)
      {:ok, _} = Sections.remove_game(section, b.id)
      {:ok, _} = Sections.insert_game_at(section, e.id, 3)
      {:ok, _} = Sections.remove_game(section, a.id)

      members = Sections.section_members(section)
      assert Enum.map(members, & &1.position) == Enum.to_list(1..length(members))
      assert Enum.map(members, & &1.game_id) == [d.id, c.id, e.id]
    end
  end

  describe "rest_index/2 (01.8.4, CTX-02) — the one documented off-by-one" do
    test "a mover sitting before the chosen gap shifts the gap down by one" do
      assert Sections.rest_index(0, 2) == 1
      assert Sections.rest_index(1, 3) == 2
    end

    test "a mover sitting at or after the chosen gap leaves the gap unchanged" do
      assert Sections.rest_index(3, 0) == 0
      assert Sections.rest_index(2, 2) == 2
    end
  end

  describe "move_game_to/3 (01.8.4, CTX-02) — rest-list coordinates" do
    setup do
      section = section_fixture(%{kind: :manual, sort: :manual})
      [a, b, c, d] = for name <- ~w(A B C D), do: game_fixture(%{name: name})
      for game <- [a, b, c, d], do: {:ok, _} = Sections.add_game(section, game.id)
      %{section: section, a: a, b: b, c: c, d: d}
    end

    defp order(section), do: section |> Sections.section_members() |> Enum.map(& &1.game_id)

    test "A to rest-index 2 gives [B, C, A, D], positions dense, returning the original full index", ctx do
      assert {:ok, %{from: 0, index: 2}} = Sections.move_game_to(ctx.section, ctx.a.id, 2)
      assert order(ctx.section) == [ctx.b.id, ctx.c.id, ctx.a.id, ctx.d.id]
      assert positions(ctx.section) == Enum.to_list(1..4)
    end

    test "D to rest-index 0 gives [D, A, B, C], positions dense", ctx do
      assert {:ok, %{from: 3, index: 0}} = Sections.move_game_to(ctx.section, ctx.d.id, 0)
      assert order(ctx.section) == [ctx.d.id, ctx.a.id, ctx.b.id, ctx.c.id]
      assert positions(ctx.section) == Enum.to_list(1..4)
    end

    test "B to rest-index 1 is B's own spot and changes nothing", ctx do
      assert {:ok, %{from: 1, index: 1}} = Sections.move_game_to(ctx.section, ctx.b.id, 1)
      assert order(ctx.section) == [ctx.a.id, ctx.b.id, ctx.c.id, ctx.d.id]
    end

    test "rest-index -1 and rest-index 4 (the rest list holds three) are :index_out_of_range and write nothing",
         ctx do
      before = snapshot(ctx.section)

      assert {:error, :index_out_of_range} = Sections.move_game_to(ctx.section, ctx.a.id, -1)
      assert {:error, :index_out_of_range} = Sections.move_game_to(ctx.section, ctx.a.id, 4)
      assert {:error, :index_out_of_range} = Sections.move_game_to(ctx.section, ctx.a.id, "1")
      assert snapshot(ctx.section) == before
    end

    test "rest-index 3 (the end of the rest list) is accepted", ctx do
      assert {:ok, %{index: 3}} = Sections.move_game_to(ctx.section, ctx.a.id, 3)
      assert order(ctx.section) == [ctx.b.id, ctx.c.id, ctx.d.id, ctx.a.id]
    end

    test "a game that is not a member is :not_member and writes nothing", ctx do
      before = snapshot(ctx.section)

      assert {:error, :not_member} = Sections.move_game_to(ctx.section, game_fixture().id, 0)
      assert snapshot(ctx.section) == before
    end

    test "weight_band and recent rows are :automatic_section" do
      for attrs <- [%{kind: :weight_band, rule_value: "nivel_experto", sort: :name}, %{kind: :recent, sort: :recent}] do
        section = section_fixture(attrs)
        assert {:error, :automatic_section} = Sections.move_game_to(section, game_fixture().id, 0)
      end
    end

    test "the kind is read from the locked row, not the passed (stale) struct" do
      automatic = section_fixture(%{kind: :recent, sort: :recent})

      assert {:error, :automatic_section} =
               Sections.move_game_to(%{automatic | kind: :manual}, game_fixture().id, 0)
    end

    test "the featured row at exactly 20 members still moves: the count does not grow" do
      featured = Repo.get_by!(Section, featured: true)
      games = for _ <- 1..20, do: game_fixture()
      for game <- games, do: {:ok, _} = Sections.add_game(featured, game.id)
      last = List.last(games)

      assert {:ok, %{from: 19, index: 0}} = Sections.move_game_to(featured, last.id, 0)
      assert hd(order(featured)) == last.id
      assert positions(featured) == Enum.to_list(1..20)
    end

    test "non-dense stored positions are healed by one move" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      [x, y, z] = for _ <- 1..3, do: game_fixture()
      add_game_to_section(section, x, 500)
      add_game_to_section(section, y, 700)
      add_game_to_section(section, z, 900)

      assert {:ok, _} = Sections.move_game_to(section, z.id, 0)
      assert order(section) == [z.id, x.id, y.id]
      assert positions(section) == Enum.to_list(1..3)
    end

    test "undo round trip: moving back to the returned `from` restores the original order exactly", ctx do
      original = order(ctx.section)

      assert {:ok, %{from: from}} = Sections.move_game_to(ctx.section, ctx.a.id, 2)
      assert order(ctx.section) != original
      assert {:ok, _} = Sections.move_game_to(ctx.section, ctx.a.id, from)
      assert order(ctx.section) == original
    end

    test "move_game/3, the shipped adjacent swap, still exists", ctx do
      assert {:ok, _} = Sections.move_game(ctx.section, ctx.b.id, :up)
      assert order(ctx.section) == [ctx.b.id, ctx.a.id, ctx.c.id, ctx.d.id]
    end
  end

  describe "featured_cap/0" do
    test "is the one place the featured cap lives" do
      assert Sections.featured_cap() == 20
    end
  end

  describe "remove_game/2 (D-25)" do
    test "removes and re-packs positions densely" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game_a = game_fixture(%{name: "A"})
      game_b = game_fixture(%{name: "B"})
      game_c = game_fixture(%{name: "C"})
      {:ok, _} = Sections.add_game(section, game_a.id)
      {:ok, _} = Sections.add_game(section, game_b.id)
      {:ok, _} = Sections.add_game(section, game_c.id)

      assert {:ok, _section} = Sections.remove_game(section, game_b.id)

      members = Sections.section_members(section)
      assert Enum.map(members, & &1.game_id) == [game_a.id, game_c.id]
      assert Enum.map(members, & &1.position) == [1, 2]
    end
  end

  describe "move_game/3 (D-25)" do
    test "swaps with the previous member" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game_a = game_fixture(%{name: "A"})
      game_b = game_fixture(%{name: "B"})
      {:ok, _} = Sections.add_game(section, game_a.id)
      {:ok, _} = Sections.add_game(section, game_b.id)

      assert {:ok, _section} = Sections.move_game(section, game_b.id, :up)

      assert section |> Sections.section_members() |> Enum.map(& &1.game_id) == [
               game_b.id,
               game_a.id
             ]
    end

    test "moving the first member up is a no-op" do
      section = section_fixture(%{kind: :manual, sort: :manual})
      game_a = game_fixture(%{name: "A"})
      {:ok, _} = Sections.add_game(section, game_a.id)

      assert {:ok, _section} = Sections.move_game(section, game_a.id, :up)
      assert section |> Sections.section_members() |> Enum.map(& &1.game_id) == [game_a.id]
    end
  end

  describe "set_game_sections/2 (D-07)" do
    test "adds missing memberships and removes unchecked ones" do
      section_a = section_fixture(%{kind: :manual, sort: :manual})
      section_b = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture()
      {:ok, _} = Sections.add_game(section_a, game.id)

      assert {:ok, _ids} = Sections.set_game_sections(game.id, [section_b.id])

      refute Enum.any?(Sections.section_members(section_a), &(&1.game_id == game.id))
      assert Enum.any?(Sections.section_members(section_b), &(&1.game_id == game.id))
    end

    test "returns {:error, :featured_full} without adding to any other requested section" do
      featured = Repo.get_by!(Section, featured: true)
      other = section_fixture(%{kind: :manual, sort: :manual})
      game = game_fixture()

      for _ <- 1..20 do
        {:ok, _section} = Sections.add_game(featured, game_fixture().id)
      end

      assert {:error, :featured_full} =
               Sections.set_game_sections(game.id, [other.id, featured.id])

      refute Enum.any?(Sections.section_members(other), &(&1.game_id == game.id))
    end
  end
end
