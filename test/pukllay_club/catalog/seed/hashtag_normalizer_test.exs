defmodule PukllayClub.Catalog.Seed.HashtagNormalizerTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Seed.HashtagNormalizer

  # Builds a raw CSV row map with every hashtag/weight column blank by
  # default, so each test only sets the cells it cares about — mirrors the
  # real `ludoteca.csv` header shape (D-16).
  defp row(overrides) do
    Map.merge(
      %{
        "#DescubreElHobby" => "",
        "#IngenioEstratega" => "",
        "#NivelExperto" => "",
        "#CreaConexiones" => "",
        "#EquipoGanador" => "",
        "#DuelosMemorables" => "",
        "#InicioRápido" => "",
        "#GestionaTusRecursos" => "",
        "#DominaElTablero" => "",
        "#ArteEnLaMesa" => "",
        "Peso_BGG" => ""
      },
      overrides
    )
  end

  describe "truthy?/1" do
    test "recognizes si/sí case and accent variants, plus surrounding whitespace, as true" do
      for value <- ["si", "Sí", "sí", "SI", " Si "] do
        assert HashtagNormalizer.truthy?(value) == true, "expected #{inspect(value)} to be true"
      end
    end

    test "treats nil, blank, and no/No/NO as false" do
      for value <- [nil, "", "no", "No", "NO"] do
        assert HashtagNormalizer.truthy?(value) == false, "expected #{inspect(value)} to be false"
      end
    end

    test "treats observed typo cells as false while flagging them unrecognized" do
      for value <- ["n", "s", "di"] do
        assert HashtagNormalizer.truthy?(value) == {false, {:unrecognized, value}}
      end
    end
  end

  describe "resolve_weight_band/1 — single hashtag wins" do
    test "returns the band for the one true weight hashtag, source :hashtag" do
      csv_row = row(%{"#IngenioEstratega" => "Sí"})

      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "ingenio_estratega", :hashtag}
    end

    test "the Pitfall-3 inversion: a single true hashtag wins even when Peso_BGG implies a different band" do
      csv_row = row(%{"#DescubreElHobby" => "si", "Peso_BGG" => "4.5"})

      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "descubre_el_hobby", :hashtag}
    end
  end

  describe "resolve_weight_band/1 — conflict tie-break via Peso_BGG" do
    test "two true hashtags with a present Peso_BGG resolve via the threshold, source :peso_tie_break" do
      csv_row = row(%{"#DescubreElHobby" => "si", "#NivelExperto" => "sí", "Peso_BGG" => "2.5"})

      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "ingenio_estratega", :peso_tie_break}
    end

    test "two true hashtags with no usable Peso_BGG are unresolved with reason :conflict" do
      csv_row = row(%{"#DescubreElHobby" => "si", "#NivelExperto" => "sí"})

      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:unresolved, :conflict}
    end
  end

  describe "resolve_weight_band/1 — zero hashtags" do
    test "zero true hashtags with a present Peso_BGG resolve via the threshold, source :peso_tie_break" do
      csv_row = row(%{"Peso_BGG" => "1.5"})

      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "descubre_el_hobby", :peso_tie_break}
    end

    test "zero true hashtags with no usable Peso_BGG are unresolved with reason :missing" do
      csv_row = row(%{})

      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:unresolved, :missing}
    end
  end

  describe "resolve_weight_band/1 — reviewed threshold boundaries (01-VOCABULARY.md section 2)" do
    test "1.89 resolves to the beginner band" do
      csv_row = row(%{"Peso_BGG" => "1.89"})
      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "descubre_el_hobby", :peso_tie_break}
    end

    test "1.9 resolves to the middle band (inclusive lower bound)" do
      csv_row = row(%{"Peso_BGG" => "1.9"})
      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "ingenio_estratega", :peso_tie_break}
    end

    test "3.1 resolves to the middle band (inclusive upper bound)" do
      csv_row = row(%{"Peso_BGG" => "3.1"})
      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "ingenio_estratega", :peso_tie_break}
    end

    test "3.11 resolves to the expert band" do
      csv_row = row(%{"Peso_BGG" => "3.11"})
      assert HashtagNormalizer.resolve_weight_band(csv_row) == {:ok, "nivel_experto", :peso_tie_break}
    end
  end

  describe "resolve_weight_band/1 — Peso_BGG decimal comma" do
    test "a decimal-comma Peso_BGG parses to the same value as a decimal-point one" do
      comma_row = row(%{"Peso_BGG" => "2,5"})
      point_row = row(%{"Peso_BGG" => "2.5"})

      assert HashtagNormalizer.resolve_weight_band(comma_row) == HashtagNormalizer.resolve_weight_band(point_row)
      assert HashtagNormalizer.resolve_weight_band(comma_row) == {:ok, "ingenio_estratega", :peso_tie_break}
    end
  end

  describe "editorial_tags/1" do
    test "returns only the true D-06 hashtags verbatim, in declaration order" do
      csv_row =
        row(%{
          "#DuelosMemorables" => "sí",
          "#CreaConexiones" => "Si",
          "#EquipoGanador" => "no"
        })

      assert HashtagNormalizer.editorial_tags(csv_row) == ["#CreaConexiones", "#DuelosMemorables"]
    end

    test "never returns a D-16 out-of-scope hashtag even when its cell is true" do
      csv_row =
        row(%{
          "#InicioRápido" => "si",
          "#GestionaTusRecursos" => "si",
          "#DominaElTablero" => "si",
          "#ArteEnLaMesa" => "si"
        })

      assert HashtagNormalizer.editorial_tags(csv_row) == []
    end
  end

  describe "unrecognized_cells/1" do
    test "collects every non-empty unrecognized hashtag cell across weight and editorial columns" do
      csv_row =
        row(%{
          "#IngenioEstratega" => "n",
          "#NivelExperto" => "S",
          "#CreaConexiones" => "N"
        })

      cells = HashtagNormalizer.unrecognized_cells(csv_row)

      assert length(cells) == 3
      assert {"#IngenioEstratega", "n"} in cells
      assert {"#NivelExperto", "S"} in cells
      assert {"#CreaConexiones", "N"} in cells
    end

    test "ignores clean si/no cells and blanks" do
      csv_row = row(%{"#DescubreElHobby" => "si", "#IngenioEstratega" => "no"})

      assert HashtagNormalizer.unrecognized_cells(csv_row) == []
    end
  end
end
