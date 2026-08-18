defmodule PukllayClub.Catalog.Seed.ExpansionClassifierTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Seed.CsvImport
  alias PukllayClub.Catalog.Seed.ExpansionClassifier

  describe "expansion?/2 — parenthesised marker" do
    test "matches regardless of letter case or spacing" do
      assert ExpansionClassifier.expansion?("Bunny Kingdom Celestial(expa)", 1)
      assert ExpansionClassifier.expansion?("Catapul Feud (expa 1)", 2)

      assert ExpansionClassifier.expansion?(
               "Ghost Fightin' Treasure Hunters: Creepy Cellar (Expa)",
               3
             )
    end
  end

  describe "expansion?/2 — spelled-out expansion word" do
    test "matches both accented and unaccented forms" do
      assert ExpansionClassifier.expansion?("Root Expansion Los Rivereños", 4)
      assert ExpansionClassifier.expansion?("Kingdomino Age of Giants (Expansión)", 5)
    end
  end

  describe "expansion?/2 — promo marker" do
    test "matches" do
      assert ExpansionClassifier.expansion?("Star Wars: Las Guerras Clon - Promo Miniaturas", 6)
    end
  end

  describe "expansion?/2 — reviewed override list (01-UAT.md Test 5)" do
    test "an unmarked name classifies as an expansion when csv_row is in the reviewed override list" do
      assert ExpansionClassifier.expansion?(
               "El Señor de los Anillos: Viajes por la Tierra Media - Vientos de Guerra",
               414
             )

      assert ExpansionClassifier.expansion?(
               "El Señor de los Anillos: Viajes por la Tierra Media - Sendas Sombrias",
               415
             )

      assert ExpansionClassifier.expansion?("abyss leviatan", 417)
      assert ExpansionClassifier.expansion?("viniculture tuscany", 421)
    end
  end

  describe "expansion?/2 — base games" do
    test "an ordinary base game is not classified as an expansion" do
      refute ExpansionClassifier.expansion?("Catán", 100)
      refute ExpansionClassifier.expansion?("Wingspan", 101)
      refute ExpansionClassifier.expansion?("Everdell", 102)
      refute ExpansionClassifier.expansion?("Marco Polo 2", 46)
    end
  end

  describe "expansion?/2 — nil name" do
    test "does not raise and classifies as not an expansion when csv_row is not overridden" do
      refute ExpansionClassifier.expansion?(nil, 999)
    end

    test "still honors the reviewed override list even for a nil name" do
      assert ExpansionClassifier.expansion?(nil, 414)
    end
  end

  describe "expansion?/2 — real CSV regression" do
    test "streaming ludoteca.csv yields exactly the 26 confirmed expansion/promo rows, csv_row 410..435" do
      flagged =
        CsvImport.stream_rows()
        |> Enum.filter(fn {row_number, fields} ->
          ExpansionClassifier.expansion?(Map.get(fields, "Nombre"), row_number)
        end)
        |> Enum.map(fn {row_number, _fields} -> row_number end)
        |> Enum.sort()

      assert length(flagged) == 26
      assert flagged == Enum.to_list(410..435)
    end
  end
end
