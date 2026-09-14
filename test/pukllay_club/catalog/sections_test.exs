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
