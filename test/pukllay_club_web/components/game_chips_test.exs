defmodule PukllayClubWeb.GameChipsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.GameChips

  describe "weight_band_badge/1" do
    test "renders the plain-Spanish label and its one-line descriptor for a banded game" do
      game = %Game{weight_band: "ingenio_estratega", bgg_weight: 2.3}

      html = render_component(&GameChips.weight_band_badge/1, game: game)

      assert html =~ "Ingenio estratega"
      assert html =~ "Reglas de 15-20 minutos"
    end

    test "renders nothing for a game with no resolved weight band" do
      game = %Game{weight_band: nil, bgg_weight: nil}

      html = render_component(&GameChips.weight_band_badge/1, game: game)

      assert String.trim(html) == ""
    end

    test "never renders the game's raw bgg_weight number" do
      game = %Game{weight_band: "ingenio_estratega", bgg_weight: 2.3}

      html = render_component(&GameChips.weight_band_badge/1, game: game)

      refute html =~ "2.3"
    end

    test "renders the large, auto-height badge treatment that grows to fit a wrapped label" do
      game = %Game{weight_band: "descubre_el_hobby", bgg_weight: 1.0}

      html = render_component(&GameChips.weight_band_badge/1, game: game)

      assert html =~ "badge-lg"
      assert html =~ "h-auto"
    end
  end

  describe "chip_row/1" do
    test "renders the covered Spanish label and drops an uncovered raw mechanic value" do
      covered = Vocabulary.covered_mechanics(["Worker Placement", "Some Uncovered Mechanic"])

      html = render_component(&GameChips.chip_row/1, terms: covered, limit: 4)

      assert html =~ "Coloca trabajadores"
      refute html =~ "Some Uncovered Mechanic"
    end

    test "caps visible chips at the given limit and renders a +N overflow chip" do
      terms = for n <- 1..7, do: "Termino #{n}"

      html = render_component(&GameChips.chip_row/1, terms: terms, limit: 4)

      for n <- 1..4, do: assert(html =~ "Termino #{n}")
      for n <- 5..7, do: refute(html =~ "Termino #{n}")
      assert html =~ "+3"
    end

    test "renders nothing for an empty term list" do
      html = render_component(&GameChips.chip_row/1, terms: [], limit: 4)

      assert String.trim(html) == ""
    end
  end

  describe "editorial_tags/1" do
    test "renders every club hashtag verbatim with the leading # using one identical chip class list" do
      tags = [
        "#DescubreElHobby",
        "#IngenioEstratega",
        "#NivelExperto",
        "#CreaConexiones",
        "#EquipoGanador",
        "#DuelosMemorables"
      ]

      html = render_component(&GameChips.editorial_tags/1, tags: tags)

      for tag <- tags, do: assert(html =~ tag)

      occurrences =
        html
        |> String.split("badge badge-sm badge-accent")
        |> length()
        |> Kernel.-(1)

      assert occurrences == 6
    end

    test "with no limit renders every tag uncapped (detail-page behaviour)" do
      tags = for n <- 1..6, do: "#Tag#{n}"

      html = render_component(&GameChips.editorial_tags/1, tags: tags)

      for n <- 1..6, do: assert(html =~ "#Tag#{n}")
      refute html =~ "+"
    end

    test "with a limit caps visible tags and renders a +N overflow chip" do
      tags = for n <- 1..5, do: "#Tag#{n}"

      html = render_component(&GameChips.editorial_tags/1, tags: tags, limit: 2)

      for n <- 1..2, do: assert(html =~ "#Tag#{n}")
      for n <- 3..5, do: refute(html =~ "#Tag#{n}")
      assert html =~ "+3"
    end
  end

  describe "weight-band descriptor length budget" do
    test "every band descriptor stays within the fixed 90-character short-line budget" do
      assert Enum.all?(Vocabulary.weight_bands(), &(String.length(&1.descriptor) <= 90))
    end
  end
end
