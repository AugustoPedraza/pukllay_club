defmodule PukllayClub.CatalogTest do
  use PukllayClub.DataCase, async: true

  import Ecto.Query
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  describe "filter_games/1 — no options" do
    test "returns games ordered by name, limited to the default page size" do
      game_fixture(%{name: "Zeta"})
      game_fixture(%{name: "Alfa"})

      assert Catalog.filter_games() |> Enum.map(& &1.name) == ["Alfa", "Zeta"]
    end
  end

  describe "filter_games/1 — mechanic/theme facets (D-14)" do
    test "two mechanic labels return games matching EITHER (OR within facet)" do
      game_fixture(%{name: "Only Dice", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Only Worker", mechanics: ["Worker Placement"]})
      game_fixture(%{name: "Both", mechanics: ["Dice Rolling", "Worker Placement"]})
      game_fixture(%{name: "Neither", mechanics: ["Auction / Bidding"]})

      results =
        Catalog.filter_games(mechanics: ["Tira dados", "Coloca trabajadores"])
        |> Enum.map(& &1.name)

      assert Enum.sort(results) == ["Both", "Only Dice", "Only Worker"]
    end

    test "the OR-within-facet result set is strictly larger than the AND-of-both-mechanics result set" do
      game_fixture(%{name: "Only Dice", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Only Worker", mechanics: ["Worker Placement"]})
      game_fixture(%{name: "Both", mechanics: ["Dice Rolling", "Worker Placement"]})

      or_count = length(Catalog.filter_games(mechanics: ["Tira dados", "Coloca trabajadores"]))

      and_count =
        from(g in Game,
          where:
            fragment(
              "? @> ?",
              g.mechanics,
              type(^["Dice Rolling", "Worker Placement"], {:array, :string})
            )
        )
        |> Repo.aggregate(:count)

      assert and_count == 1
      assert or_count > and_count
    end

    test "one mechanic label and one theme label return only games matching both facets (AND across facets)" do
      game_fixture(%{name: "Match Both", mechanics: ["Dice Rolling"], themes: ["Economic"]})
      game_fixture(%{name: "Mechanic Only", mechanics: ["Dice Rolling"], themes: ["Fantasy"]})
      game_fixture(%{name: "Theme Only", mechanics: ["Auction / Bidding"], themes: ["Economic"]})

      results =
        Catalog.filter_games(mechanics: ["Tira dados"], themes: ["Economía"])
        |> Enum.map(& &1.name)

      assert results == ["Match Both"]
    end
  end

  describe "filter_games/1 — scalar filters" do
    test "min_players: 4 returns only games whose player range includes 4" do
      game_fixture(%{name: "Fits4", min_players: 2, max_players: 5})
      game_fixture(%{name: "TooFew", min_players: 5, max_players: 6})
      game_fixture(%{name: "TooMany", min_players: 1, max_players: 3})

      assert Catalog.filter_games(players: 4) |> Enum.map(& &1.name) == ["Fits4"]
    end

    test "max_playtime: 60 excludes a 120-minute game" do
      game_fixture(%{name: "Quick", playing_time: 45})
      game_fixture(%{name: "Long", playing_time: 120})

      names = Catalog.filter_games(max_playtime: 60) |> Enum.map(& &1.name)

      assert "Quick" in names
      refute "Long" in names
    end

    test "max_playtime falls back to max_playtime when playing_time is null" do
      game_fixture(%{name: "NoPlayingTime", playing_time: nil, max_playtime: 30})
      game_fixture(%{name: "TooLongNoPlayingTime", playing_time: nil, max_playtime: 180})

      names = Catalog.filter_games(max_playtime: 60) |> Enum.map(& &1.name)

      assert "NoPlayingTime" in names
      refute "TooLongNoPlayingTime" in names
    end

    test "min_age: 8 excludes a game whose min_age is 12" do
      game_fixture(%{name: "ForKids", min_age: 6})
      game_fixture(%{name: "ForTeens", min_age: 12})

      names = Catalog.filter_games(min_age: 8) |> Enum.map(& &1.name)

      assert "ForKids" in names
      refute "ForTeens" in names
    end
  end

  describe "filter_games/1 — search (CATALOG-03, D-15)" do
    test "a search term matches on title, on designer, and on publisher" do
      game_fixture(%{
        name: "Terra Mystica",
        designers: ["Jens Drögemüller"],
        publishers: ["Devir"]
      })

      game_fixture(%{name: "Otro Juego", designers: ["Otro Autor"], publishers: ["Otra Editorial"]})

      assert Catalog.filter_games(q: "Terra") |> Enum.any?(&(&1.name == "Terra Mystica"))
      assert Catalog.filter_games(q: "Drögemüller") |> Enum.any?(&(&1.name == "Terra Mystica"))
      assert Catalog.filter_games(q: "Devir") |> Enum.any?(&(&1.name == "Terra Mystica"))
    end

    test "an accent-free spelling of an accented title still matches it" do
      game_fixture(%{name: "Descifra el código"})

      assert Catalog.filter_games(q: "codigo")
             |> Enum.any?(&(&1.name == "Descifra el código"))
    end

    test "a search term AND a mechanic filter apply both — search narrows the filtered set" do
      game_fixture(%{name: "Catán Junior", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Catán Card Game", mechanics: ["Auction / Bidding"]})
      game_fixture(%{name: "Otro Juego", mechanics: ["Dice Rolling"]})

      results = Catalog.filter_games(q: "Catán", mechanics: ["Tira dados"]) |> Enum.map(& &1.name)

      assert results == ["Catán Junior"]
    end

    test "adversarial search input with quotes, a leading hyphen, and OR returns a result list instead of raising" do
      game_fixture(%{name: "Catán"})

      results = Catalog.filter_games(q: ~s("catan" -expansion OR duelo))

      assert is_list(results)
    end
  end

  describe "filter_games/1 — sort (CATALOG-04)" do
    test "sort: :playtime_asc and sort: :complexity_desc produce different, correctly-ordered results" do
      game_fixture(%{
        name: "Short Simple",
        playing_time: 20,
        weight_band: "descubre_el_hobby",
        bgg_weight: 1.2
      })

      game_fixture(%{
        name: "Long Complex",
        playing_time: 180,
        weight_band: "nivel_experto",
        bgg_weight: 4.5
      })

      assert Catalog.filter_games(sort: :playtime_asc) |> Enum.map(& &1.name) == [
               "Short Simple",
               "Long Complex"
             ]

      assert Catalog.filter_games(sort: :complexity_desc) |> Enum.map(& &1.name) == [
               "Long Complex",
               "Short Simple"
             ]
    end

    test "sort: :complexity_asc places a game with a null weight_band after every banded game" do
      game_fixture(%{name: "A Beginner", weight_band: "descubre_el_hobby", bgg_weight: 1.2})
      game_fixture(%{name: "B Moderate", weight_band: "ingenio_estratega", bgg_weight: 2.4})
      game_fixture(%{name: "C Expert", weight_band: "nivel_experto", bgg_weight: 4.1})
      game_fixture(%{name: "D Unranked", weight_band: nil, bgg_weight: nil})

      assert Catalog.filter_games(sort: :complexity_asc) |> Enum.map(& &1.name) == [
               "A Beginner",
               "B Moderate",
               "C Expert",
               "D Unranked"
             ]
    end

    test "an unrecognized sort atom falls back to :name_asc rather than raising" do
      game_fixture(%{name: "Zeta"})
      game_fixture(%{name: "Alfa"})

      assert Catalog.filter_games(sort: :not_a_real_sort) |> Enum.map(& &1.name) == [
               "Alfa",
               "Zeta"
             ]
    end
  end

  describe "count_games/1" do
    test "returns the total matching count ignoring :limit and :offset" do
      for n <- 1..5, do: game_fixture(%{name: "Game #{n}"})

      assert Catalog.count_games() == 5
      assert length(Catalog.filter_games(limit: 2)) == 2
    end
  end

  describe "list_carousel_rows/0 (D-09)" do
    test "returns the fixed rows in order, each with a key, a Spanish title, and its games" do
      game_fixture(%{name: "Tag Game", tags: ["#CreaConexiones"]})
      game_fixture(%{name: "Band Game", weight_band: "nivel_experto"})
      game_fixture(%{name: "Recent Game"})

      rows = Catalog.list_carousel_rows()

      assert Enum.map(rows, & &1.key) == [
               :destacados_del_club,
               :crea_conexiones,
               :equipo_ganador,
               :duelos_memorables,
               :descubre_el_hobby,
               :ingenio_estratega,
               :nivel_experto,
               :recientemente_anadidos
             ]

      assert Enum.all?(rows, &is_binary(&1.title))
      assert Enum.all?(rows, &is_list(&1.games))

      destacados = Enum.find(rows, &(&1.key == :destacados_del_club))
      assert destacados.title == "Destacados del club"
    end
  end
end
