defmodule PukllayClub.Catalog.VocabularyTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Vocabulary

  describe "weight_bands/0" do
    test "returns the three bands in ascending order, each with DB value, label, and descriptor" do
      bands = Vocabulary.weight_bands()

      assert Enum.map(bands, & &1.value) == [
               "descubre_el_hobby",
               "ingenio_estratega",
               "nivel_experto"
             ]

      assert Enum.all?(bands, &is_binary(&1.label))
      assert Enum.all?(bands, &is_binary(&1.descriptor))
    end
  end

  describe "weight_band/1" do
    test "returns the band map for a known DB value" do
      assert %{value: "ingenio_estratega", label: "Ingenio estratega"} =
               Vocabulary.weight_band("ingenio_estratega")
    end

    test "returns nil for an unknown value" do
      assert Vocabulary.weight_band("not_a_band") == nil
    end
  end

  describe "weight_band_level/1" do
    test "returns the 1-based index of each band in ascending order" do
      assert Vocabulary.weight_band_level("descubre_el_hobby") == 1
      assert Vocabulary.weight_band_level("ingenio_estratega") == 2
      assert Vocabulary.weight_band_level("nivel_experto") == 3
    end

    test "returns nil for an unknown or nil value" do
      assert Vocabulary.weight_band_level("no_existe") == nil
      assert Vocabulary.weight_band_level(nil) == nil
    end
  end

  describe "mechanic_label/1" do
    test "returns the Spanish chip label for a covered BGG mechanic" do
      assert Vocabulary.mechanic_label("Worker Placement") == "Coloca trabajadores"
    end

    test "returns nil for an uncovered mechanic" do
      assert Vocabulary.mechanic_label("Some Uncovered Mechanic") == nil
    end
  end

  describe "theme_label/1" do
    test "returns the Spanish chip label for a covered BGG category" do
      assert Vocabulary.theme_label("Fantasy") == "Fantasía"
    end

    test "returns nil for an uncovered category" do
      assert Vocabulary.theme_label("Some Uncovered Category") == nil
    end
  end

  describe "mechanic_terms_for/1" do
    test "maps a Spanish chip label back to the raw BGG mechanic values it covers" do
      assert Vocabulary.mechanic_terms_for("Coloca trabajadores") == ["Worker Placement"]
    end

    test "returns an empty list for an unrecognized label" do
      assert Vocabulary.mechanic_terms_for("Etiqueta inventada") == []
    end
  end

  describe "theme_terms_for/1" do
    test "maps a Spanish chip label back to the raw BGG category values it covers" do
      assert Vocabulary.theme_terms_for("Fantasía") == ["Fantasy"]
    end
  end

  describe "covered_mechanics/1" do
    test "filters a game's raw mechanic list down to covered labels, dropping uncovered ones" do
      raw = ["Worker Placement", "Some Uncovered Mechanic", "Dice Rolling"]

      assert Vocabulary.covered_mechanics(raw) == ["Coloca trabajadores", "Tira dados"]
    end
  end

  describe "covered_themes/1" do
    test "filters a game's raw theme list down to covered labels, dropping uncovered ones" do
      raw = ["Fantasy", "Some Uncovered Category", "Economic"]

      assert Vocabulary.covered_themes(raw) == ["Fantasía", "Economía"]
    end
  end

  describe "vocabulary surface size (must match 01-VOCABULARY.md exactly)" do
    test "exposes exactly 35 mechanic options" do
      assert length(Vocabulary.mechanic_options()) == 35
    end

    test "exposes exactly 32 theme options" do
      assert length(Vocabulary.theme_options()) == 32
    end

    test "mechanic_options/0 returns sorted distinct Spanish labels" do
      options = Vocabulary.mechanic_options()

      assert options == Enum.sort(options)
      assert options == Enum.uniq(options)
    end

    test "theme_options/0 returns sorted distinct Spanish labels" do
      options = Vocabulary.theme_options()

      assert options == Enum.sort(options)
      assert options == Enum.uniq(options)
    end
  end
end
