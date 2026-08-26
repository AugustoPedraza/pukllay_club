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

      assert Enum.map(Catalog.filter_games(), & &1.name) == ["Alfa", "Zeta"]
    end
  end

  describe "filter_games/1 — mechanic/theme facets (D-14)" do
    test "two mechanic labels return games matching EITHER (OR within facet)" do
      game_fixture(%{name: "Only Dice", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Only Worker", mechanics: ["Worker Placement"]})
      game_fixture(%{name: "Both", mechanics: ["Dice Rolling", "Worker Placement"]})
      game_fixture(%{name: "Neither", mechanics: ["Auction / Bidding"]})

      results =
        [mechanics: ["Tira dados", "Coloca trabajadores"]]
        |> Catalog.filter_games()
        |> Enum.map(& &1.name)

      assert Enum.sort(results) == ["Both", "Only Dice", "Only Worker"]
    end

    test "the OR-within-facet result set is strictly larger than the AND-of-both-mechanics result set" do
      game_fixture(%{name: "Only Dice", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Only Worker", mechanics: ["Worker Placement"]})
      game_fixture(%{name: "Both", mechanics: ["Dice Rolling", "Worker Placement"]})

      or_count = length(Catalog.filter_games(mechanics: ["Tira dados", "Coloca trabajadores"]))

      and_count =
        Repo.aggregate(
          from(g in Game,
            where: fragment("? @> ?", g.mechanics, type(^["Dice Rolling", "Worker Placement"], {:array, :string}))
          ),
          :count
        )

      assert and_count == 1
      assert or_count > and_count
    end

    test "one mechanic label and one theme label return only games matching both facets (AND across facets)" do
      game_fixture(%{name: "Match Both", mechanics: ["Dice Rolling"], themes: ["Economic"]})
      game_fixture(%{name: "Mechanic Only", mechanics: ["Dice Rolling"], themes: ["Fantasy"]})
      game_fixture(%{name: "Theme Only", mechanics: ["Auction / Bidding"], themes: ["Economic"]})

      results =
        [mechanics: ["Tira dados"], themes: ["Economía"]]
        |> Catalog.filter_games()
        |> Enum.map(& &1.name)

      assert results == ["Match Both"]
    end
  end

  describe "filter_games/1 — scalar filters" do
    test "min_players: 4 returns only games whose player range includes 4" do
      game_fixture(%{name: "Fits4", min_players: 2, max_players: 5})
      game_fixture(%{name: "TooFew", min_players: 5, max_players: 6})
      game_fixture(%{name: "TooMany", min_players: 1, max_players: 3})

      assert [players: 4] |> Catalog.filter_games() |> Enum.map(& &1.name) == ["Fits4"]
    end

    test "players: 6 is the open-ended top bucket — it also matches a game whose min_players exceeds 6, which the exact-fit predicate would have excluded" do
      game_fixture(%{name: "SixMax", min_players: 2, max_players: 6})
      game_fixture(%{name: "BigParty", min_players: 7, max_players: 8})
      game_fixture(%{name: "TooSmall", min_players: 2, max_players: 5})

      names = [players: 6] |> Catalog.filter_games() |> Enum.map(& &1.name) |> Enum.sort()

      assert names == ["BigParty", "SixMax"]
    end

    test "players: nil applies no players predicate at all" do
      game_fixture(%{name: "AnyPlayers", min_players: 1, max_players: 2})

      assert [players: nil] |> Catalog.filter_games() |> Enum.map(& &1.name) == ["AnyPlayers"]
    end

    test "max_playtime: 60 excludes a 120-minute game" do
      game_fixture(%{name: "Quick", playing_time: 45})
      game_fixture(%{name: "Long", playing_time: 120})

      names = [max_playtime: 60] |> Catalog.filter_games() |> Enum.map(& &1.name)

      assert "Quick" in names
      refute "Long" in names
    end

    test "max_playtime falls back to max_playtime when playing_time is null" do
      game_fixture(%{name: "NoPlayingTime", playing_time: nil, max_playtime: 30})
      game_fixture(%{name: "TooLongNoPlayingTime", playing_time: nil, max_playtime: 180})

      names = [max_playtime: 60] |> Catalog.filter_games() |> Enum.map(& &1.name)

      assert "NoPlayingTime" in names
      refute "TooLongNoPlayingTime" in names
    end

    test "min_age: 8 excludes a game whose min_age is 12" do
      game_fixture(%{name: "ForKids", min_age: 6})
      game_fixture(%{name: "ForTeens", min_age: 12})

      names = [min_age: 8] |> Catalog.filter_games() |> Enum.map(& &1.name)

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

      assert [q: "Terra"] |> Catalog.filter_games() |> Enum.any?(&(&1.name == "Terra Mystica"))
      assert [q: "Drögemüller"] |> Catalog.filter_games() |> Enum.any?(&(&1.name == "Terra Mystica"))
      assert [q: "Devir"] |> Catalog.filter_games() |> Enum.any?(&(&1.name == "Terra Mystica"))
    end

    test "an accent-free spelling of an accented title still matches it" do
      game_fixture(%{name: "Descifra el código"})

      assert [q: "codigo"]
             |> Catalog.filter_games()
             |> Enum.any?(&(&1.name == "Descifra el código"))
    end

    test "a search term AND a mechanic filter apply both — search narrows the filtered set" do
      game_fixture(%{name: "Catán Junior", mechanics: ["Dice Rolling"]})
      game_fixture(%{name: "Catán Card Game", mechanics: ["Auction / Bidding"]})
      game_fixture(%{name: "Otro Juego", mechanics: ["Dice Rolling"]})

      results = [q: "Catán", mechanics: ["Tira dados"]] |> Catalog.filter_games() |> Enum.map(& &1.name)

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

      assert [sort: :playtime_asc] |> Catalog.filter_games() |> Enum.map(& &1.name) == [
               "Short Simple",
               "Long Complex"
             ]

      assert [sort: :complexity_desc] |> Catalog.filter_games() |> Enum.map(& &1.name) == [
               "Long Complex",
               "Short Simple"
             ]
    end

    test "sort: :complexity_asc places a game with a null weight_band after every banded game" do
      game_fixture(%{name: "A Beginner", weight_band: "descubre_el_hobby", bgg_weight: 1.2})
      game_fixture(%{name: "B Moderate", weight_band: "ingenio_estratega", bgg_weight: 2.4})
      game_fixture(%{name: "C Expert", weight_band: "nivel_experto", bgg_weight: 4.1})
      game_fixture(%{name: "D Unranked", weight_band: nil, bgg_weight: nil})

      assert [sort: :complexity_asc] |> Catalog.filter_games() |> Enum.map(& &1.name) == [
               "A Beginner",
               "B Moderate",
               "C Expert",
               "D Unranked"
             ]
    end

    test "an unrecognized sort atom falls back to :name_asc rather than raising" do
      game_fixture(%{name: "Zeta"})
      game_fixture(%{name: "Alfa"})

      assert [sort: :not_a_real_sort] |> Catalog.filter_games() |> Enum.map(& &1.name) == [
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

    test "the recientemente_anadidos row excludes expansions but includes base games (G-01-5)" do
      base = game_fixture(%{name: "Base Game", is_expansion: false})
      game_fixture(%{name: "Some Expansion(expa)", is_expansion: true})

      rows = Catalog.list_carousel_rows()
      recent = Enum.find(rows, &(&1.key == :recientemente_anadidos))
      recent_ids = Enum.map(recent.games, & &1.id)

      assert base.id in recent_ids
      assert Enum.all?(recent.games, &(&1.is_expansion == false))
    end

    test "the other seven carousel rows are unaffected by is_expansion" do
      game_fixture(%{
        name: "Expansion Tag Game(expa)",
        is_expansion: true,
        tags: ["#CreaConexiones"]
      })

      game_fixture(%{
        name: "Expansion Band Game(expa)",
        is_expansion: true,
        weight_band: "nivel_experto"
      })

      rows = Catalog.list_carousel_rows()

      tag_row = Enum.find(rows, &(&1.key == :crea_conexiones))
      assert Enum.any?(tag_row.games, &(&1.name == "Expansion Tag Game(expa)"))

      band_row = Enum.find(rows, &(&1.key == :nivel_experto))
      assert Enum.any?(band_row.games, &(&1.name == "Expansion Band Game(expa)"))
    end
  end

  describe "carousel_page/3 — in-row infinite scroll pagination (quick task 260824-u5d)" do
    test "page 2 continues from page 1 with no overlap and no gap" do
      for n <- 1..25 do
        game_fixture(%{
          name: "Winner #{String.pad_leading(to_string(n), 2, "0")}",
          tags: ["#EquipoGanador"]
        })
      end

      assert {:ok, {page1, false}} = Catalog.carousel_page("equipo_ganador", 0, 20)
      assert {:ok, {page2, true}} = Catalog.carousel_page("equipo_ganador", 20)

      assert length(page1) == 20
      assert length(page2) == 5

      page1_ids = MapSet.new(page1, & &1.id)
      page2_ids = MapSet.new(page2, & &1.id)

      assert MapSet.disjoint?(page1_ids, page2_ids)
      assert MapSet.size(MapSet.union(page1_ids, page2_ids)) == 25
    end

    test "a category with fewer games than the limit is exhausted on its first page" do
      for n <- 1..5, do: game_fixture(%{name: "Duel #{n}", tags: ["#DuelosMemorables"]})

      assert {:ok, {games, true}} = Catalog.carousel_page("duelos_memorables", 0, 20)
      assert length(games) == 5
    end

    test "list_carousel_rows/0 marks a row shorter than the initial page exhausted on first paint" do
      for n <- 1..5, do: game_fixture(%{name: "Duel #{n}", tags: ["#DuelosMemorables"]})

      rows = Catalog.list_carousel_rows()
      duelos = Enum.find(rows, &(&1.key == :duelos_memorables))

      assert duelos.exhausted? == true
      assert duelos.offset == 5
    end

    test "paging stops at the 30-game ceiling even when the category holds far more" do
      for n <- 1..40 do
        game_fixture(%{
          name: "Winner #{String.pad_leading(to_string(n), 2, "0")}",
          tags: ["#EquipoGanador"]
        })
      end

      assert {:ok, {_page1, false}} = Catalog.carousel_page("equipo_ganador", 0, 20)
      assert {:ok, {page2, true}} = Catalog.carousel_page("equipo_ganador", 20, 10)

      assert length(page2) == 10
    end

    test "a fetch that would cross the ceiling is clamped to the remaining allowance" do
      for n <- 1..40 do
        game_fixture(%{
          name: "Winner #{String.pad_leading(to_string(n), 2, "0")}",
          tags: ["#EquipoGanador"]
        })
      end

      assert {:ok, {games, true}} = Catalog.carousel_page("equipo_ganador", 25, 10)
      assert length(games) == 5
    end

    test "a fetch-more request issued at or beyond the ceiling returns no games" do
      for n <- 1..40 do
        game_fixture(%{
          name: "Winner #{String.pad_leading(to_string(n), 2, "0")}",
          tags: ["#EquipoGanador"]
        })
      end

      assert {:ok, {[], true}} = Catalog.carousel_page("equipo_ganador", 30, 10)
    end

    test "an unrecognised row key returns :error rather than raising" do
      assert Catalog.carousel_page("not-a-real-row", 0) == :error
    end
  end

  describe "filter_games/1 and count_games/1 — expansions remain searchable (G-01-5)" do
    test "an expansion-flagged game is still findable by search and still counted" do
      game_fixture(%{name: "Wingspan Europa(expa)", is_expansion: true})

      names = [q: "Wingspan Europa"] |> Catalog.filter_games() |> Enum.map(& &1.name)

      assert "Wingspan Europa(expa)" in names
      assert Catalog.count_games(q: "Wingspan Europa") == 1
    end
  end

  describe "similar_games/1 (SHELL-03 — D-06 ranking + G-01.2-7 always-full widening, capped at 12)" do
    test "never includes the game itself" do
      game = game_fixture(%{name: "Self", weight_band: "nivel_experto"})
      game_fixture(%{name: "Bandmate", weight_band: "nivel_experto"})

      refute game.id in Enum.map(Catalog.similar_games(game), & &1.id)
    end

    test "band-mates rank before other-band games — band is now a preference, not a filter (G-01.2-7)" do
      game = game_fixture(%{name: "Base", weight_band: "nivel_experto"})
      same_band = game_fixture(%{name: "Same Band", weight_band: "nivel_experto"})
      other_band = game_fixture(%{name: "Other Band", weight_band: "descubre_el_hobby"})

      result_ids = game |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert same_band.id in result_ids
      assert other_band.id in result_ids
      assert Enum.find_index(result_ids, &(&1 == same_band.id)) <
               Enum.find_index(result_ids, &(&1 == other_band.id))
    end

    test "a game whose band has no other members still returns a widened, non-empty shelf (G-01.2-7)" do
      lonely = game_fixture(%{name: "Lonely", weight_band: "descubre_el_hobby"})
      other = game_fixture(%{name: "Different Band", weight_band: "nivel_experto"})

      result_ids = lonely |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert other.id in result_ids
    end

    test "a game with a nil weight_band returns a full, overlap-ranked shelf instead of an empty list (G-01.2-7)" do
      unbanded = game_fixture(%{name: "Unbanded", weight_band: nil})
      other = game_fixture(%{name: "Also Unbanded", weight_band: nil})

      result_ids = unbanded |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert other.id in result_ids
    end

    test "the result never exceeds the cap when more than 12 band-mates exist" do
      game = game_fixture(%{name: "Base", weight_band: "ingenio_estratega"})

      for n <- 1..15 do
        game_fixture(%{name: "Bandmate #{n}", weight_band: "ingenio_estratega"})
      end

      assert length(Catalog.similar_games(game)) == 12
    end

    test "ranks band-mates by overlap (zero-overlap band-mate last), and ranks the other-band game after every band-mate despite its higher overlap (G-01.2-7)" do
      # Names are deliberately chosen so alphabetical order is the OPPOSITE
      # of overlap-ranked order ("Alfa..." would sort first, "Zulu..." last)
      # — this proves ranking is driven by overlap, not incidentally by name.
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building", "Set Collection"],
          themes: ["Fantasy"]
        })

      candidate_high =
        game_fixture(%{
          name: "Zulu High Overlap",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building", "Set Collection"],
          themes: ["Fantasy"]
        })

      candidate_mid =
        game_fixture(%{
          name: "Mike Mid Overlap",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building"],
          themes: []
        })

      candidate_zero =
        game_fixture(%{
          name: "Alfa Zero Overlap",
          weight_band: "ingenio_estratega",
          mechanics: [],
          themes: []
        })

      candidate_other_band =
        game_fixture(%{
          name: "Other Band Full Overlap",
          weight_band: "descubre_el_hobby",
          mechanics: ["Deck Building", "Set Collection"],
          themes: ["Fantasy"]
        })

      result_ids = base |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert result_ids == [
               candidate_high.id,
               candidate_mid.id,
               candidate_zero.id,
               candidate_other_band.id
             ]
    end

    test "band-mates with identical overlap scores are ordered by name ascending, then id ascending" do
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building"],
          themes: []
        })

      zebra =
        game_fixture(%{name: "Zebra", weight_band: "ingenio_estratega", mechanics: [], themes: []})

      alfa =
        game_fixture(%{name: "Alfa", weight_band: "ingenio_estratega", mechanics: [], themes: []})

      assert base |> Catalog.similar_games() |> Enum.map(& &1.id) == [alfa.id, zebra.id]
    end

    test "a base game with empty mechanics and empty themes returns its band-mates without raising" do
      base =
        game_fixture(%{name: "Base", weight_band: "ingenio_estratega", mechanics: [], themes: []})

      bandmate =
        game_fixture(%{
          name: "Bandmate",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building"],
          themes: ["Fantasy"]
        })

      assert base |> Catalog.similar_games() |> Enum.map(& &1.id) == [bandmate.id]
    end

    test "the cap cannot truncate away the best matches when more than 12 band-mates exist" do
      # Names are deliberately chosen so the low-overlap candidates sort
      # BEFORE the high-overlap ones alphabetically ("Alfa..." < "Zeta...")
      # — a LIMIT applied before ranking would keep the 12 "Alfa" rows and
      # drop all 3 high-overlap "Zeta" rows entirely.
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building", "Set Collection"],
          themes: ["Fantasy"]
        })

      high_overlap =
        for n <- 1..3 do
          game_fixture(%{
            name: "Zeta High #{n}",
            weight_band: "ingenio_estratega",
            mechanics: ["Deck Building", "Set Collection"],
            themes: []
          })
        end

      for n <- 1..12 do
        game_fixture(%{
          name: "Alfa Low #{String.pad_leading(to_string(n), 2, "0")}",
          weight_band: "ingenio_estratega",
          mechanics: [],
          themes: []
        })
      end

      result_ids = base |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert length(result_ids) == 12
      assert Enum.take(result_ids, 3) == Enum.map(high_overlap, & &1.id)
    end

    test "ordering is deterministic across repeated calls" do
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building"],
          themes: []
        })

      zebra =
        game_fixture(%{name: "Zebra", weight_band: "ingenio_estratega", mechanics: [], themes: []})

      alfa =
        game_fixture(%{name: "Alfa", weight_band: "ingenio_estratega", mechanics: [], themes: []})

      expected = [alfa.id, zebra.id]

      for _ <- 1..3 do
        assert base |> Catalog.similar_games() |> Enum.map(& &1.id) == expected
      end
    end

    test "a band-mate with empty mechanics/themes is returned (score 0) when the base game has both populated" do
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building"],
          themes: ["Fantasy"]
        })

      empty_bandmate =
        game_fixture(%{
          name: "Empty Bandmate",
          weight_band: "ingenio_estratega",
          mechanics: [],
          themes: []
        })

      assert empty_bandmate.id in Enum.map(Catalog.similar_games(base), & &1.id)
    end
  end
end
