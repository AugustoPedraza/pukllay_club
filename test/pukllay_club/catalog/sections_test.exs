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
end
