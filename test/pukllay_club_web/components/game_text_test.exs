defmodule PukllayClubWeb.GameTextTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Game
  alias PukllayClubWeb.GameText

  describe "editorial_text/1" do
    test "returns nil for a game with publishers: [] (the schema default)" do
      game = %Game{name: "Catán", publishers: []}

      assert GameText.editorial_text(game) == nil
    end

    test "returns the 'editado por' clause for a single publisher" do
      game = %Game{name: "Catán", publishers: ["Devir"]}

      assert GameText.editorial_text(game) == "editado por Devir"
    end

    test "joins several publishers readably, with no list-inspect syntax" do
      game = %Game{name: "Catán", publishers: ["Devir", "Asmodee", "Kosmos"]}

      text = GameText.editorial_text(game)

      assert text == "editado por Devir, Asmodee, Kosmos"
      refute text =~ "["
      refute text =~ "\""
    end
  end

  describe "cover_alt/1" do
    test "returns the D-10 name-plus-editorial form for a single publisher" do
      game = %Game{name: "Catán", publishers: ["Devir"]}

      assert GameText.cover_alt(game) == "Portada de Catán, editado por Devir"
    end

    test "returns only the name-only form for publishers: [], with no trailing connector" do
      game = %Game{name: "Catán", publishers: []}

      alt = GameText.cover_alt(game)

      assert alt == "Portada de Catán"
      refute alt =~ ","
      refute alt =~ "  "
      refute String.ends_with?(alt, "editado por")
      refute String.ends_with?(alt, " ")
    end

    test "renders several publishers joined readably, never as Elixir list-inspect syntax" do
      game = %Game{name: "Catán", publishers: ["Devir", "Asmodee"]}

      alt = GameText.cover_alt(game)

      assert alt == "Portada de Catán, editado por Devir, Asmodee"
      refute alt =~ "["
      refute alt =~ "\""
    end

    test "a game name and publisher containing an ampersand, angle bracket and double quote round-trip unchanged" do
      game = %Game{
        name: ~s(Sid Meier's Civilization: A New Dawn & Beyond <Deluxe> "Edition"),
        publishers: ["Fantasy Flight & Friends"]
      }

      alt = GameText.cover_alt(game)

      assert alt ==
               ~s(Portada de Sid Meier's Civilization: A New Dawn & Beyond <Deluxe> "Edition", editado por Fantasy Flight & Friends)
    end

    test "a game name and publisher containing accented Latin characters and ñ round-trip as valid UTF-8" do
      game = %Game{name: "El Pequeño Señor de los Anillos: Edición Española", publishers: ["Ñoquis Ediciones"]}

      alt = GameText.cover_alt(game)

      assert alt ==
               "Portada de El Pequeño Señor de los Anillos: Edición Española, editado por Ñoquis Ediciones"

      assert String.valid?(alt)
    end
  end
end
