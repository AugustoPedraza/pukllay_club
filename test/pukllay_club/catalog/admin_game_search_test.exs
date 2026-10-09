defmodule PukllayClub.Catalog.AdminGameSearchTest do
  use PukllayClub.DataCase, async: true

  import Ecto.Query
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  defp names(games), do: Enum.map(games, & &1.name)

  defp set_inserted_at(game, %NaiveDateTime{} = at) do
    Repo.update_all(from(g in Game, where: g.id == ^game.id), set: [inserted_at: at])
    game
  end

  describe "search_admin_games_ranked/2 (01.8.4, ADD-04)" do
    setup do
      for name <- ["Catán", "El Catan Jr", "Everdell", "100% Raro", "Explorers of Catan"] do
        game_fixture(%{name: name})
      end

      :ok
    end

    test "\"cat\" ranks the one starts-with match first, then contains-only matches by name" do
      assert "cat" |> Catalog.search_admin_games_ranked() |> names() ==
               ["Catán", "El Catan Jr", "Explorers of Catan"]
    end

    test "\"100%\" treats the percent sign as a literal, matching only 100% Raro" do
      assert "100%" |> Catalog.search_admin_games_ranked() |> names() == ["100% Raro"]
    end

    test "\"ev\" returns only Everdell" do
      assert "ev" |> Catalog.search_admin_games_ranked() |> names() == ["Everdell"]
    end

    test "a query matching nothing returns []" do
      assert Catalog.search_admin_games_ranked("zzz") == []
    end

    test "folds accents and case in both directions" do
      assert "CATÁN" |> Catalog.search_admin_games_ranked() |> names() |> List.first() == "Catán"
      assert "catan" |> Catalog.search_admin_games_ranked() |> names() |> List.first() == "Catán"
      assert "CAT" |> Catalog.search_admin_games_ranked() |> names() |> List.first() == "Catán"
    end

    test "a literal underscore matches only a literal underscore, never any single character" do
      game_fixture(%{name: "Mi_Juego"})
      game_fixture(%{name: "MiXJuego"})

      assert "i_J" |> Catalog.search_admin_games_ranked() |> names() == ["Mi_Juego"]
    end

    test "an empty or whitespace-only query returns [] without querying" do
      assert Catalog.search_admin_games_ranked("") == []
      assert Catalog.search_admin_games_ranked("   ") == []
    end

    test "a whitespace-only query issues no database query at all" do
      ref = make_ref()
      parent = self()

      handler = fn _event, _measure, _meta, _config -> send(parent, {ref, :query}) end
      :telemetry.attach(inspect(ref), [:pukllay_club, :repo, :query], handler, nil)

      try do
        assert Catalog.search_admin_games_ranked("   ") == []
        refute_received {^ref, :query}
      after
        :telemetry.detach(inspect(ref))
      end
    end
  end

  describe "search_admin_games_ranked/2 caps and eligibility (01.8.4, ADD-04)" do
    test "returns at most 6 rows — a 7th starts-with match is dropped" do
      for n <- 1..7, do: game_fixture(%{name: "Torre #{n}"})

      assert length(Catalog.search_admin_games_ranked("torre")) == 6
    end

    test "opts[:limit] overrides the default of 6" do
      for n <- 1..7, do: game_fixture(%{name: "Torre #{n}"})

      assert length(Catalog.search_admin_games_ranked("torre", limit: 3)) == 3
      assert length(Catalog.search_admin_games_ranked("torre", limit: 7)) == 7
    end

    test "a query longer than 120 characters is sliced, not raised on" do
      game_fixture(%{name: "Catán"})
      long = String.duplicate("a", 130)

      assert is_list(Catalog.search_admin_games_ranked(long))
    end

    test "the 120-character slice happens before the query runs" do
      name = String.duplicate("a", 120)
      game_fixture(%{name: name})

      # 120 `a`s plus a trailing marker: unsliced it would not match the
      # 120-`a` name; sliced to 120 it starts-with matches it.
      assert (name <> "ZZZ") |> Catalog.search_admin_games_ranked() |> names() == [name]
    end

    test "excludes :retired games, includes :draft games and games already in a section" do
      game_fixture(%{name: "Dado Publicado", status: :published})
      game_fixture(%{name: "Dado Borrador", status: :draft})
      game_fixture(%{name: "Dado Retirado", status: :retired})

      assert "dado" |> Catalog.search_admin_games_ranked() |> names() ==
               ["Dado Borrador", "Dado Publicado"]
    end

    test "a game already in a section is still returned — members are shown so they can be moved (ADD-05)" do
      member = game_fixture(%{name: "Miembro Fila"})
      game_fixture(%{name: "Miembro Libre"})
      section = section_fixture()
      add_game_to_section(section, member)

      assert "miembro" |> Catalog.search_admin_games_ranked() |> names() ==
               ["Miembro Fila", "Miembro Libre"]
    end

    test "a game whose name both starts with and contains the term appears exactly once" do
      game_fixture(%{name: "Catan Catan"})
      game_fixture(%{name: "Otro Catan"})

      assert "catan" |> Catalog.search_admin_games_ranked() |> names() == ["Catan Catan", "Otro Catan"]
    end

    test "starts-with matches precede contains-only matches regardless of name order" do
      game_fixture(%{name: "A Torre"})
      game_fixture(%{name: "Torre Z"})

      assert "torre" |> Catalog.search_admin_games_ranked() |> names() == ["Torre Z", "A Torre"]
    end

    test "games with identical names are ordered by id ascending" do
      first = game_fixture(%{name: "Gemelo"})
      second = game_fixture(%{name: "Gemelo"})

      assert "gemelo" |> Catalog.search_admin_games_ranked() |> Enum.map(& &1.id) ==
               [first.id, second.id]
    end
  end

  describe "recent_games_for_row/2 (01.8.4, ADD-03)" do
    test "returns at most 6 of 8 eligible games" do
      for n <- 1..8, do: game_fixture(%{name: "Reciente #{n}"})

      assert length(Catalog.recent_games_for_row([])) == 6
    end

    test "opts[:limit] overrides the default of 6" do
      for n <- 1..8, do: game_fixture(%{name: "Reciente #{n}"})

      assert length(Catalog.recent_games_for_row([], limit: 2)) == 2
      assert length(Catalog.recent_games_for_row([], limit: 8)) == 8
    end

    test "orders newest-first by explicitly set inserted_at, not by insertion order" do
      # Inserted oldest-name-first, but timestamps deliberately inverted.
      a = %{name: "Alfa"} |> game_fixture() |> set_inserted_at(~N[2026-03-01 10:00:00])
      b = %{name: "Beta"} |> game_fixture() |> set_inserted_at(~N[2026-01-01 10:00:00])
      c = %{name: "Gamma"} |> game_fixture() |> set_inserted_at(~N[2026-02-01 10:00:00])

      assert [] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) == [a.id, c.id, b.id]
    end

    test "games sharing one inserted_at second are ordered by id descending" do
      same = ~N[2026-04-01 12:00:00]
      first = %{name: "Mellizo 1"} |> game_fixture() |> set_inserted_at(same)
      second = %{name: "Mellizo 2"} |> game_fixture() |> set_inserted_at(same)
      third = %{name: "Mellizo 3"} |> game_fixture() |> set_inserted_at(same)

      assert [] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) ==
               [third.id, second.id, first.id]
    end

    test "every id in exclude_ids is absent from the result" do
      keep = game_fixture(%{name: "Queda"})
      drop = game_fixture(%{name: "Sale"})

      assert [drop.id] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) == [keep.id]
    end

    test "a :retired game is absent, a :draft game is present" do
      game_fixture(%{name: "Retirado", status: :retired})
      draft = game_fixture(%{name: "Borrador", status: :draft})

      assert [] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) == [draft.id]
    end

    test "a game with no thumbnail is present — no thumbnail requirement" do
      bare = game_fixture(%{name: "Sin Portada", thumbnail_url: nil})

      assert [] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) == [bare.id]
    end

    test "returns [] when there are no games at all" do
      assert Catalog.recent_games_for_row([]) == []
    end

    test "returns [] when every eligible game is already a member" do
      a = game_fixture(%{name: "Uno"})
      b = game_fixture(%{name: "Dos"})

      assert Catalog.recent_games_for_row([a.id, b.id]) == []
    end

    test "returns exactly one row when exactly one game is eligible" do
      a = game_fixture(%{name: "Uno"})
      b = game_fixture(%{name: "Dos"})

      assert [a.id] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) == [b.id]
    end

    test "an exclude id that matches no game is harmless" do
      only = game_fixture(%{name: "Solo"})

      assert [-1, 999_999_999] |> Catalog.recent_games_for_row() |> Enum.map(& &1.id) == [only.id]
    end
  end
end
