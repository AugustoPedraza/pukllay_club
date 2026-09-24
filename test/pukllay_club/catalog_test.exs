defmodule PukllayClub.CatalogTest do
  use PukllayClub.DataCase, async: true
  use Oban.Testing, repo: PukllayClub.Repo

  import Ecto.Query
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Section
  alias PukllayClub.Repo
  alias PukllayClub.Workers.EnrichGameWorker

  # `priv/repo/migrations/*.exs` files are not part of the app's normal
  # compilation path — `Ecto.Migrator` loads them dynamically at migrate
  # time, not at `mix compile`/`mix test` — so
  # `UnpublishStillEmptyGames.still_empty_query/0` (D-36 migration
  # predicate test below) must be required explicitly. Guarded against
  # redefinition warnings on a re-run within the same VM (`mix test.watch`,
  # iex -S mix test).
  if !Code.ensure_loaded?(PukllayClub.Repo.Migrations.UnpublishStillEmptyGames) do
    Code.require_file("priv/repo/migrations/20260923122000_unpublish_still_empty_games.exs")
  end

  describe "published-only public reads (D-04, D-08)" do
    # Table-driven over every public read function that must exclude
    # draft/retired games (RESEARCH.md Pitfall 2). Each case seeds one
    # published, one draft, and one retired game sharing the same weight
    # band, tag, and mechanics, then asserts the published game's presence
    # and the draft/retired games' absence via that specific read function.
    setup do
      shared = %{
        weight_band: "ingenio_estratega",
        tags: ["#EquipoGanador"],
        mechanics: ["Dice Rolling"],
        themes: ["Economic"],
        is_expansion: false
      }

      published = game_fixture(Map.merge(shared, %{name: "Published Game", status: :published}))
      draft = game_fixture(Map.merge(shared, %{name: "Draft Game", status: :draft}))
      retired = game_fixture(Map.merge(shared, %{name: "Retired Game", status: :retired}))

      section = section_fixture(%{name: "Shared Setup Section"})
      add_game_to_section(section, published)
      add_game_to_section(section, draft)
      add_game_to_section(section, retired)

      %{published: published, draft: draft, retired: retired, section: section}
    end

    test "list_games/1 excludes draft and retired games", %{
      published: published,
      draft: draft,
      retired: retired
    } do
      ids = Enum.map(Catalog.list_games(), & &1.id)

      assert published.id in ids
      refute draft.id in ids
      refute retired.id in ids
    end

    test "filter_games/1 excludes draft and retired games", %{
      published: published,
      draft: draft,
      retired: retired
    } do
      ids = Enum.map(Catalog.filter_games(), & &1.id)

      assert published.id in ids
      refute draft.id in ids
      refute retired.id in ids
    end

    test "count_games/1 counts only the published game", %{published: _p, draft: _d, retired: _r} do
      assert Catalog.count_games() == 1
    end

    test "list_home_sections/0 excludes draft and retired games from every row", %{
      published: published,
      draft: draft,
      retired: retired
    } do
      rows = Catalog.list_home_sections()
      all_ids = rows |> Enum.flat_map(& &1.games) |> Enum.map(& &1.id)

      assert published.id in all_ids
      refute draft.id in all_ids
      refute retired.id in all_ids
    end

    test "section_page/3 excludes draft and retired games", %{
      published: published,
      draft: draft,
      retired: retired,
      section: section
    } do
      {:ok, {games, _exhausted?}} = Catalog.section_page("section-#{section.id}", 0)
      ids = Enum.map(games, & &1.id)

      assert published.id in ids
      refute draft.id in ids
      refute retired.id in ids
    end

    test "similar_games/1 excludes draft and retired candidates", %{
      published: published,
      draft: draft,
      retired: retired
    } do
      # A separate viewed game in the same band so `published`/`draft`/
      # `retired` are all candidates, never the viewed game itself.
      viewed = game_fixture(%{name: "Viewed", weight_band: "ingenio_estratega"})

      ids = viewed |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert published.id in ids
      refute draft.id in ids
      refute retired.id in ids
    end

    test "sitemap_entries/0 excludes draft and retired games", %{
      published: published,
      draft: draft,
      retired: retired
    } do
      ids = Enum.map(Catalog.sitemap_entries(), & &1.id)

      assert published.id in ids
      refute draft.id in ids
      refute retired.id in ids
    end

    test "get_game!/1 (unfiltered admin read) still returns a draft and a retired game", %{
      draft: draft,
      retired: retired
    } do
      assert Catalog.get_game!(to_string(draft.id)).id == draft.id
      assert Catalog.get_game!(to_string(retired.id)).id == retired.id
    end

    test "get_published_game!/1 raises Ecto.NoResultsError for a draft or retired id", %{
      draft: draft,
      retired: retired
    } do
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_published_game!(to_string(draft.id)) end
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_published_game!(to_string(retired.id)) end
    end

    test "get_published_game!/1 returns a published game", %{published: published} do
      assert Catalog.get_published_game!(to_string(published.id)).id == published.id
    end
  end

  describe "status transitions (D-04, D-08)" do
    test "publish_game/1 moves a draft game to published, making it appear in filter_games/1" do
      game = game_fixture(%{name: "Recién publicado", status: :draft})

      refute game.id in Enum.map(Catalog.filter_games(), & &1.id)

      assert {:ok, published} = Catalog.publish_game(game)
      assert published.status == :published
      assert game.id in Enum.map(Catalog.filter_games(), & &1.id)
    end

    test "publish_game/1 on a retired game refuses, leaving status unchanged (D-37 gate 1)" do
      game = game_fixture(%{name: "Vuelve", status: :retired})

      assert Catalog.publish_game(game) == {:error, :not_publishable}
      assert Catalog.get_game!(game.id).status == :retired
    end

    test "publish_game/1 on an already-published game refuses (D-37 gate 1)" do
      game = game_fixture(%{name: "Ya publicado", status: :published})

      assert Catalog.publish_game(game) == {:error, :not_publishable}
      assert Catalog.get_game!(game.id).status == :published
    end

    test "publish_game/1 on a nivel-less non-expansion draft refuses with :nivel_required (D-30/D-37)" do
      game =
        game_fixture(%{
          name: "Sin nivel",
          status: :draft,
          weight_band: nil,
          is_expansion: false
        })

      assert Catalog.publish_game(game) == {:error, :nivel_required}
      assert Catalog.get_game!(game.id).status == :draft
    end

    test "publish_game/1 on a nivel-less EXPANSION draft succeeds — D-30 has no nivel condition for an expansion" do
      game =
        game_fixture(%{
          name: "Expansión sin nivel",
          status: :draft,
          weight_band: nil,
          is_expansion: true
        })

      assert {:ok, published} = Catalog.publish_game(game)
      assert published.status == :published
    end

    test "publish_game/1 on a draft that already carries a nivel succeeds" do
      game =
        game_fixture(%{
          name: "Con nivel",
          status: :draft,
          weight_band: "descubre_el_hobby",
          is_expansion: false
        })

      assert {:ok, published} = Catalog.publish_game(game)
      assert published.status == :published
    end

    test "saving a nivel-less non-expansion draft succeeds — required to publish, never to save (D-30)" do
      game = game_fixture(%{name: "Guardable", status: :draft, weight_band: nil, is_expansion: false})

      assert {:ok, updated} = Catalog.update_game_admin(game, %{"description" => "Nueva descripción"})
      assert updated.weight_band == nil
      assert updated.description == "Nueva descripción"
    end

    test "retire_game/1 moves a published game to retired, removing it from filter_games/1" do
      game = game_fixture(%{name: "Se retira", status: :published})

      assert game.id in Enum.map(Catalog.filter_games(), & &1.id)

      assert {:ok, retired} = Catalog.retire_game(game)
      assert retired.status == :retired
      refute game.id in Enum.map(Catalog.filter_games(), & &1.id)
    end

    test "retire_game/1 on a draft game refuses, leaving status unchanged (D-37 gate 1)" do
      game = game_fixture(%{name: "Borrador", status: :draft})

      assert Catalog.retire_game(game) == {:error, :not_retirable}
      assert Catalog.get_game!(game.id).status == :draft
    end

    test "restore_game/1 on a retired game moves it back to published, reappearing in filter_games/1" do
      game = game_fixture(%{name: "Restaurado", status: :retired})

      refute game.id in Enum.map(Catalog.filter_games(), & &1.id)

      assert {:ok, restored} = Catalog.restore_game(game)
      assert restored.status == :published
      assert game.id in Enum.map(Catalog.filter_games(), & &1.id)
    end

    test "restore_game/1 on a non-retired game returns an error tuple without changing status" do
      game = game_fixture(%{name: "No estaba retirado", status: :published})

      assert Catalog.restore_game(game) == {:error, :not_retired}
    end

    test "a game inserted without an explicit status is published" do
      game = game_fixture(%{name: "Sin status explícito"})

      assert game.status == :published
    end
  end

  describe "enrichment_status validation (D-37 gate 3)" do
    test "Game.enrichment_changeset/2 rejects an unknown enrichment_status" do
      game = game_fixture(%{name: "Estado desconocido"})

      changeset = Game.enrichment_changeset(game, %{enrichment_status: "nonsense"})

      refute changeset.valid?
      assert %{enrichment_status: ["is invalid"]} = errors_on(changeset)
    end

    test "Game.enrichment_changeset/2 accepts every known enrichment_status" do
      game = game_fixture(%{name: "Estado conocido"})

      for status <- ~w(pending enriched no_bgg_id bgg_missing failed) do
        changeset = Game.enrichment_changeset(game, %{enrichment_status: status})
        assert changeset.valid?, "expected #{status} to be valid: #{inspect(errors_on(changeset))}"
      end
    end

    test "a raw SQL write of an unknown enrichment_status is rejected by the database CHECK constraint" do
      game = game_fixture(%{name: "SQL directo"})

      assert_raise Postgrex.Error, fn ->
        Repo.query!("UPDATE games SET enrichment_status = 'nonsense' WHERE id = $1", [game.id])
      end
    end
  end

  describe "filter_games/1 — no options" do
    test "returns games ordered by name, limited to the default page size" do
      game_fixture(%{name: "Zeta"})
      game_fixture(%{name: "Alfa"})

      assert Enum.map(Catalog.filter_games(), & &1.name) == ["Alfa", "Zeta"]
    end
  end

  describe "filter_games/1 — sections facet (D-27)" do
    test "returns only published members of a non-hidden manual section" do
      section = section_fixture(%{kind: :manual})
      in_section = game_fixture(%{name: "In Section"})
      outside = game_fixture(%{name: "Outside"})
      add_game_to_section(section, in_section)

      results = [sections: [section.id]] |> Catalog.filter_games() |> Enum.map(& &1.name)

      assert results == [in_section.name]
      refute outside.name in results
    end

    test "a hidden section's id returns nothing" do
      section = section_fixture(%{kind: :manual, hidden: true})
      game = game_fixture(%{name: "Hidden Section Game"})
      add_game_to_section(section, game)

      assert Catalog.filter_games(sections: [section.id]) == []
    end

    test "a weight_band-kind section's id returns nothing (manual-only facet)" do
      section =
        Repo.get_by!(Section, name: "Ingenio estratega")

      game_fixture(%{name: "Weight Band Game", weight_band: "ingenio_estratega"})

      assert Catalog.filter_games(sections: [section.id]) == []
    end

    test "a nonexistent section id returns nothing" do
      assert Catalog.filter_games(sections: [999_999]) == []
    end

    test "two section ids return the union" do
      section_a = section_fixture(%{kind: :manual})
      section_b = section_fixture(%{kind: :manual})
      a_game = game_fixture(%{name: "A Section Game"})
      b_game = game_fixture(%{name: "B Section Game"})
      add_game_to_section(section_a, a_game)
      add_game_to_section(section_b, b_game)

      results = [sections: [section_a.id, section_b.id]] |> Catalog.filter_games() |> Enum.map(& &1.name)

      assert Enum.sort(results) == Enum.sort([a_game.name, b_game.name])
    end

    test "count_games/1 matches filter_games/1's result count" do
      section = section_fixture(%{kind: :manual})
      add_game_to_section(section, game_fixture(%{name: "Counted Game"}))
      game_fixture(%{name: "Uncounted Game"})

      assert Catalog.count_games(sections: [section.id]) == 1
    end
  end

  describe "facet_options/0 — sections facet (D-27)" do
    test "includes non-hidden manual sections with at least one published game, featured first then position" do
      featured = Repo.get_by!(Section, name: "Destacados del club")
      manual_a = section_fixture(%{name: "Manual A", position: 100})
      manual_b = section_fixture(%{name: "Manual B", position: 50})
      hidden = section_fixture(%{name: "Hidden Manual", hidden: true, position: 1})
      empty = section_fixture(%{name: "Empty Manual", position: 2})
      weight_band_section = Repo.get_by!(Section, name: "Ingenio estratega")

      add_game_to_section(featured, game_fixture(%{name: "Featured Facet Game"}))
      add_game_to_section(manual_a, game_fixture(%{name: "Manual A Game"}))
      add_game_to_section(manual_b, game_fixture(%{name: "Manual B Game"}))
      add_game_to_section(hidden, game_fixture(%{name: "Hidden Facet Game"}))

      ids = Enum.map(Catalog.facet_options().sections, & &1.id)

      assert ids == [featured.id, manual_b.id, manual_a.id]
      refute empty.id in ids
      refute hidden.id in ids
      refute weight_band_section.id in ids
    end

    test "entries carry :id and :name only" do
      section = section_fixture(%{name: "Named Facet Section"})
      add_game_to_section(section, game_fixture())

      assert %{id: id, name: "Named Facet Section"} =
               Enum.find(Catalog.facet_options().sections, &(&1.id == section.id))

      assert is_integer(id)
    end

    test "no longer returns editorial_tags" do
      refute Map.has_key?(Catalog.facet_options(), :editorial_tags)
    end
  end

  describe "put_section_names/1 — public chips data source (D-17, 01.8.1-11)" do
    test "fills a single game's virtual field with its visible manual sections' names, ordered by position" do
      first = section_fixture(%{name: "Crea conexiones", position: 1})
      second = section_fixture(%{name: "Spiel des Jahres", position: 2})
      game = game_fixture(%{name: "Chipped Game"})
      add_game_to_section(second, game)
      add_game_to_section(first, game)

      assert Catalog.put_section_names(game).section_names == ["Crea conexiones", "Spiel des Jahres"]
    end

    test "omits a hidden section's name" do
      hidden = section_fixture(%{name: "Hidden Section", hidden: true})
      game = game_fixture()
      add_game_to_section(hidden, game)

      assert Catalog.put_section_names(game).section_names == []
    end

    test "omits the featured section's name" do
      featured = Repo.get_by!(Section, name: "Destacados del club")
      game = game_fixture()
      add_game_to_section(featured, game)

      assert Catalog.put_section_names(game).section_names == []
    end

    test "omits a weight_band-kind section's name (chips come from manual membership only)" do
      band_section = Repo.get_by!(Section, name: "Ingenio estratega")
      game = game_fixture(%{weight_band: "ingenio_estratega"})

      assert Catalog.put_section_names(game).section_names == []
      refute band_section.name in Catalog.put_section_names(game).section_names
    end

    test "accepts a list of games and fills each independently, in one query" do
      section = section_fixture(%{name: "Shared Section"})
      a = game_fixture(%{name: "A"})
      b = game_fixture(%{name: "B"})
      add_game_to_section(section, a)

      [a_result, b_result] = Catalog.put_section_names([a, b])

      assert a_result.section_names == ["Shared Section"]
      assert b_result.section_names == []
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

  describe "filter_games/1 and count_games/1 — designers/artists creator filters (01.3-06, UAT gap G-01.3-1 item 3)" do
    test "designers returns only games whose designers array contains the exact name" do
      game_fixture(%{name: "Robinson Crusoe", designers: ["Ignacy Trzewiczek"]})
      game_fixture(%{name: "51st State", designers: ["Ignacy Trzewiczek", "Bartłomiej Kordowski"]})
      game_fixture(%{name: "Other", designers: ["Someone Else"]})

      results =
        [designers: ["Ignacy Trzewiczek"]]
        |> Catalog.filter_games()
        |> Enum.map(& &1.name)

      assert Enum.sort(results) == ["51st State", "Robinson Crusoe"]

      assert Catalog.count_games(designers: ["Ignacy Trzewiczek"]) == 2
    end

    test "artists returns only games whose artists array contains the exact name" do
      game_fixture(%{name: "With Artist", artists: ["Jason Behnke"]})
      game_fixture(%{name: "Other Artist", artists: ["Someone Else"]})

      results =
        [artists: ["Jason Behnke"]]
        |> Catalog.filter_games()
        |> Enum.map(& &1.name)

      assert results == ["With Artist"]
      assert Catalog.count_games(artists: ["Jason Behnke"]) == 1
    end

    test "a designer name matching no game returns an empty list" do
      game_fixture(%{name: "Any Game", designers: ["Real Designer"]})

      assert Catalog.filter_games(designers: ["Nobody At All"]) == []
      assert Catalog.count_games(designers: ["Nobody At All"]) == 0
    end

    test "designers composes with an existing facet (AND across facets, narrows not widens)" do
      game_fixture(%{
        name: "Match Both",
        designers: ["R. Eric Reuss"],
        mechanics: ["Dice Rolling"]
      })

      game_fixture(%{
        name: "Designer Only",
        designers: ["R. Eric Reuss"],
        mechanics: ["Auction / Bidding"]
      })

      game_fixture(%{
        name: "Mechanic Only",
        designers: ["Someone Else"],
        mechanics: ["Dice Rolling"]
      })

      designer_only_count = length(Catalog.filter_games(designers: ["R. Eric Reuss"]))

      combined_results =
        [designers: ["R. Eric Reuss"], mechanics: ["Tira dados"]]
        |> Catalog.filter_games()
        |> Enum.map(& &1.name)

      assert designer_only_count == 2
      assert combined_results == ["Match Both"]
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

  describe "list_home_sections/0 (D-17..D-28, 01.8.1-10)" do
    test "each returned row carries a key, a Spanish title, and its games; a manual section only shows hand-picked members" do
      crea = Repo.get_by!(Section, name: "Crea conexiones")
      tag_game = game_fixture(%{name: "Tag Game", weight_band: nil})
      add_game_to_section(crea, tag_game)

      band_game = game_fixture(%{name: "Band Game", weight_band: "nivel_experto"})

      rows = Catalog.list_home_sections()

      assert Enum.all?(rows, &is_binary(&1.title))
      assert Enum.all?(rows, &is_list(&1.games))
      assert Enum.all?(rows, &String.starts_with?(&1.key, "section-"))

      crea_row = Enum.find(rows, &(&1.title == "Crea conexiones"))
      assert Enum.map(crea_row.games, & &1.id) == [tag_game.id]

      nivel_row = Enum.find(rows, &(&1.title == "Nivel experto"))
      assert band_game.id in Enum.map(nivel_row.games, & &1.id)

      refute Enum.any?(rows, &(&1.title == "Equipo ganador"))
      refute Enum.any?(rows, &(&1.title == "Duelos memorables"))
      refute Enum.any?(rows, &(&1.title == "Destacados del club"))
    end

    test "the featured section renders first, with featured?: true, once it has a published member (D-18, D-23)" do
      featured = Repo.get_by!(Section, featured: true)
      game = game_fixture(%{name: "Featured Game", weight_band: nil})
      add_game_to_section(featured, game)

      [first_row | _] = Catalog.list_home_sections()

      assert first_row.title == "Destacados del club"
      assert first_row.featured? == true
      assert Enum.map(first_row.games, & &1.id) == [game.id]
    end

    test "a section with every member draft or retired is hidden (D-24)" do
      crea = Repo.get_by!(Section, name: "Crea conexiones")
      draft = game_fixture(%{name: "Draft Game", weight_band: nil, status: :draft})
      add_game_to_section(crea, draft)

      refute Enum.any?(Catalog.list_home_sections(), &(&1.title == "Crea conexiones"))
    end

    test "the recent section excludes expansions but includes base games (G-01-5)" do
      base = game_fixture(%{name: "Base Game", weight_band: nil, is_expansion: false})
      game_fixture(%{name: "Some Expansion(expa)", weight_band: nil, is_expansion: true})

      recent = Enum.find(Catalog.list_home_sections(), &(&1.title == "Recientemente añadidos"))
      recent_ids = Enum.map(recent.games, & &1.id)

      assert base.id in recent_ids
      assert Enum.all?(recent.games, &(&1.is_expansion == false))
    end

    test "weight-band sections exclude expansions, even with a matching band (D-37 gate 2)" do
      base = game_fixture(%{name: "Base Band Game", is_expansion: false, weight_band: "nivel_experto"})

      game_fixture(%{
        name: "Expansion Band Game(expa)",
        is_expansion: true,
        weight_band: "nivel_experto"
      })

      band_row = Enum.find(Catalog.list_home_sections(), &(&1.title == "Nivel experto"))
      names = Enum.map(band_row.games, & &1.name)

      assert base.name in names
      refute "Expansion Band Game(expa)" in names
    end
  end

  describe "section_page/3 — in-row infinite scroll pagination (quick task 260824-u5d, ported to sections 01.8.1-10)" do
    test "page 2 continues from page 1 with no overlap and no gap" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..25 do
        game = game_fixture(%{name: "Winner #{String.pad_leading(to_string(n), 2, "0")}", weight_band: nil})
        add_game_to_section(section, game)
      end

      key = "section-#{section.id}"
      assert {:ok, {page1, false}} = Catalog.section_page(key, 0, 20)
      assert {:ok, {page2, true}} = Catalog.section_page(key, 20)

      assert length(page1) == 20
      assert length(page2) == 5

      page1_ids = MapSet.new(page1, & &1.id)
      page2_ids = MapSet.new(page2, & &1.id)

      assert MapSet.disjoint?(page1_ids, page2_ids)
      assert MapSet.size(MapSet.union(page1_ids, page2_ids)) == 25
    end

    test "page 1 and page 2 stay duplicate-free and gap-free even when two members share a name (D-26 :id tiebreaker)" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..25 do
        # Every member shares the exact same name — the :id tiebreaker
        # (asc: g.name, asc: g.id) is the only thing that can keep page 1
        # and page 2 from silently duplicating or skipping a member.
        game = game_fixture(%{name: "Tied Name", weight_band: nil})
        add_game_to_section(section, game)
        _ = n
      end

      key = "section-#{section.id}"
      assert {:ok, {page1, false}} = Catalog.section_page(key, 0, 20)
      assert {:ok, {page2, true}} = Catalog.section_page(key, 20)

      assert length(page1) == 20
      assert length(page2) == 5

      page1_ids = MapSet.new(page1, & &1.id)
      page2_ids = MapSet.new(page2, & &1.id)

      assert MapSet.disjoint?(page1_ids, page2_ids)
      assert MapSet.size(MapSet.union(page1_ids, page2_ids)) == 25
    end

    test "a section with fewer games than the limit is exhausted on its first page" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..5 do
        game = game_fixture(%{name: "Duel #{n}", weight_band: nil})
        add_game_to_section(section, game)
      end

      assert {:ok, {games, true}} = Catalog.section_page("section-#{section.id}", 0, 20)
      assert length(games) == 5
    end

    test "list_home_sections/0 marks a row shorter than the initial page exhausted on first paint" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..5 do
        game = game_fixture(%{name: "Duel #{n}", weight_band: nil})
        add_game_to_section(section, game)
      end

      rows = Catalog.list_home_sections()
      row = Enum.find(rows, &(&1.section_id == section.id))

      assert row.exhausted? == true
      assert row.offset == 5
    end

    test "paging stops at the 30-game ceiling even when the section holds far more" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..40 do
        game = game_fixture(%{name: "Winner #{String.pad_leading(to_string(n), 2, "0")}", weight_band: nil})
        add_game_to_section(section, game)
      end

      key = "section-#{section.id}"
      assert {:ok, {_page1, false}} = Catalog.section_page(key, 0, 20)
      assert {:ok, {page2, true}} = Catalog.section_page(key, 20, 10)

      assert length(page2) == 10
    end

    test "a fetch that would cross the ceiling is clamped to the remaining allowance" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..40 do
        game = game_fixture(%{name: "Winner #{String.pad_leading(to_string(n), 2, "0")}", weight_band: nil})
        add_game_to_section(section, game)
      end

      assert {:ok, {games, true}} = Catalog.section_page("section-#{section.id}", 25, 10)
      assert length(games) == 5
    end

    test "a fetch-more request issued at or beyond the ceiling returns no games" do
      section = section_fixture(%{kind: :manual, sort: :name})

      for n <- 1..40 do
        game = game_fixture(%{name: "Winner #{String.pad_leading(to_string(n), 2, "0")}", weight_band: nil})
        add_game_to_section(section, game)
      end

      assert {:ok, {[], true}} = Catalog.section_page("section-#{section.id}", 30, 10)
    end

    test "an unrecognised row key returns :error rather than raising" do
      assert Catalog.section_page("not-a-real-row", 0) == :error
    end

    test "a well-formed key for a hidden section returns :error (T-01.8.1-47)" do
      section = section_fixture(%{kind: :manual, sort: :name, hidden: true})
      assert Catalog.section_page("section-#{section.id}", 0) == :error
    end

    test "the featured section is capped at ~20 games (D-26); load-more returns nothing further" do
      featured = Repo.get_by!(Section, featured: true)

      for n <- 1..25 do
        game =
          game_fixture(%{name: "Featured #{String.pad_leading(to_string(n), 2, "0")}", weight_band: nil})

        add_game_to_section(featured, game)
      end

      key = "section-#{featured.id}"
      assert {:ok, {page1, true}} = Catalog.section_page(key, 0, 20)
      assert length(page1) == 20

      assert {:ok, {[], true}} = Catalog.section_page(key, 20)
    end

    test "a weight_band section never contains a game of another band" do
      hobby_section = Repo.get_by!(Section, name: "Descubre el hobby")
      hobby_game = game_fixture(%{name: "Hobby Only", weight_band: "descubre_el_hobby"})
      game_fixture(%{name: "Expert Only", weight_band: "nivel_experto"})

      {:ok, {games, _exhausted?}} = Catalog.section_page("section-#{hobby_section.id}", 0)
      ids = Enum.map(games, & &1.id)

      assert hobby_game.id in ids
      assert Enum.all?(games, &(&1.weight_band == "descubre_el_hobby"))
    end

    test "a weight_band section never contains an expansion, even with a matching band (D-37 gate 2)" do
      hobby_section = Repo.get_by!(Section, name: "Descubre el hobby")
      base = game_fixture(%{name: "Hobby Base", weight_band: "descubre_el_hobby", is_expansion: false})

      expansion =
        game_fixture(%{name: "Hobby Expansion(expa)", weight_band: "descubre_el_hobby", is_expansion: true})

      {:ok, {games, _exhausted?}} = Catalog.section_page("section-#{hobby_section.id}", 0)
      ids = Enum.map(games, & &1.id)

      assert base.id in ids
      refute expansion.id in ids
    end

    test "the recent section never contains an expansion" do
      recent_section = Repo.get_by!(Section, name: "Recientemente añadidos")
      base = game_fixture(%{name: "Base Only", weight_band: nil, is_expansion: false})
      game_fixture(%{name: "Expansion Only(expa)", weight_band: nil, is_expansion: true})

      {:ok, {games, _exhausted?}} = Catalog.section_page("section-#{recent_section.id}", 0)
      ids = Enum.map(games, & &1.id)

      assert base.id in ids
      assert Enum.all?(games, &(&1.is_expansion == false))
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

  describe "similar_games/1 — G-01.2-7 always-full guarantee" do
    test "the shelf fills to the 12-card cap even when only 3 band-mates exist" do
      base = game_fixture(%{name: "Base", weight_band: "ingenio_estratega"})

      for n <- 1..3 do
        game_fixture(%{name: "Bandmate #{n}", weight_band: "ingenio_estratega"})
      end

      for n <- 1..8 do
        game_fixture(%{name: "OtherHobby #{n}", weight_band: "descubre_el_hobby"})
      end

      for n <- 1..7 do
        game_fixture(%{name: "OtherExperto #{n}", weight_band: "nivel_experto"})
      end

      assert length(Catalog.similar_games(base)) == 12
    end

    test "the 3 band-mates occupy the leading positions and no band-mate appears after position 3" do
      base = game_fixture(%{name: "Base", weight_band: "ingenio_estratega"})

      bandmate_ids =
        for n <- 1..3 do
          game_fixture(%{name: "Bandmate #{n}", weight_band: "ingenio_estratega"}).id
        end

      for n <- 1..15 do
        game_fixture(%{name: "OtherBand #{n}", weight_band: "descubre_el_hobby"})
      end

      result_ids = base |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert MapSet.new(Enum.take(result_ids, 3)) == MapSet.new(bandmate_ids)
      refute Enum.any?(Enum.drop(result_ids, 3), &(&1 in bandmate_ids))
    end

    test "band-mates are ordered overlap desc, then name, then id, even amid widening" do
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building", "Set Collection"],
          themes: ["Fantasy"]
        })

      high =
        game_fixture(%{
          name: "Zulu High",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building", "Set Collection"],
          themes: ["Fantasy"]
        })

      mid =
        game_fixture(%{
          name: "Mike Mid",
          weight_band: "ingenio_estratega",
          mechanics: ["Deck Building"],
          themes: []
        })

      zero =
        game_fixture(%{name: "Alfa Zero", weight_band: "ingenio_estratega", mechanics: [], themes: []})

      for n <- 1..10, do: game_fixture(%{name: "Filler #{n}", weight_band: "nivel_experto"})

      result_ids = base |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert Enum.take(result_ids, 3) == [high.id, mid.id, zero.id]
    end

    test "the top-up block orders by band distance before overlap — an adjacent-band zero-overlap game outranks a far-band high-overlap game" do
      base =
        game_fixture(%{
          name: "Base",
          weight_band: "descubre_el_hobby",
          mechanics: ["Deck Building"],
          themes: []
        })

      adjacent_zero_overlap =
        game_fixture(%{
          name: "Adjacent Zero",
          weight_band: "ingenio_estratega",
          mechanics: [],
          themes: []
        })

      far_high_overlap =
        game_fixture(%{
          name: "Far High",
          weight_band: "nivel_experto",
          mechanics: ["Deck Building"],
          themes: []
        })

      result_ids = base |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert result_ids == [adjacent_zero_overlap.id, far_high_overlap.id]
    end

    test "a nil weight_band game gets a full shelf when the catalog can fill it" do
      base = game_fixture(%{name: "Base Nil", weight_band: nil})

      for n <- 1..8, do: game_fixture(%{name: "Hobby #{n}", weight_band: "descubre_el_hobby"})
      for n <- 1..7, do: game_fixture(%{name: "Experto #{n}", weight_band: "nivel_experto"})

      assert length(Catalog.similar_games(base)) == 12
    end

    test "a catalog holding fewer than 12 other games returns all of them exactly once, excluding the viewed game" do
      base = game_fixture(%{name: "Base Small", weight_band: "ingenio_estratega"})

      others = for n <- 1..5, do: game_fixture(%{name: "Other #{n}", weight_band: "descubre_el_hobby"})

      result_ids = base |> Catalog.similar_games() |> Enum.map(& &1.id)

      assert length(result_ids) == 5
      assert Enum.sort(result_ids) == Enum.sort(Enum.map(others, & &1.id))
      refute base.id in result_ids
    end
  end

  describe "parse_bgg_input/1 (D-01, 01.8.1-08)" do
    test "a bare digits-only id parses, surrounding whitespace trimmed" do
      assert Catalog.parse_bgg_input("266192") == {:ok, 266_192}
      assert Catalog.parse_bgg_input(" 266192 ") == {:ok, 266_192}
    end

    test "a BGG game or expansion URL parses to its id" do
      assert Catalog.parse_bgg_input("https://boardgamegeek.com/boardgame/266192/wingspan") ==
               {:ok, 266_192}

      assert Catalog.parse_bgg_input("https://www.boardgamegeek.com/boardgameexpansion/290837/x") ==
               {:ok, 290_837}
    end

    test "an off-host URL is rejected (T-01.8.1-37)" do
      assert Catalog.parse_bgg_input("https://evil.example/boardgame/1") == :error
    end

    test "non-numeric, zero, empty, and out-of-range input are rejected" do
      assert Catalog.parse_bgg_input("abc") == :error
      assert Catalog.parse_bgg_input("0") == :error
      assert Catalog.parse_bgg_input("") == :error
      assert Catalog.parse_bgg_input("2147483648") == :error
    end
  end

  describe "retry_enrichment/1 (D-03, open item 3/D-38 plan 01.8.2-21: gate moved to has-a-bgg_id)" do
    test "on a game with no bgg_id returns {:error, :no_bgg_id} without touching the row" do
      game = game_fixture(%{bgg_id: nil, enrichment_status: "no_bgg_id"})

      assert Catalog.retry_enrichment(game) == {:error, :no_bgg_id}
      assert Catalog.get_game!(game.id).enrichment_status == "no_bgg_id"
    end

    test "on a failed game (bgg_id present) sets it back to pending and enqueues exactly one new enrichment job" do
      game =
        game_fixture(%{bgg_id: 184_267, status: :draft, enrichment_status: "failed"})

      assert {:ok, updated} = Catalog.retry_enrichment(game)
      assert updated.enrichment_status == "pending"

      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end

    test "reachable for a game with a bgg_id regardless of enrichment_status (the old gate matched 0 rows)" do
      enriched = game_fixture(%{bgg_id: 174_430, enrichment_status: "enriched"})

      assert {:ok, updated} = Catalog.retry_enrichment(enriched)
      assert updated.enrichment_status == "pending"
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => enriched.id})
    end
  end

  # link_bgg_id/3's own tests live in bgg_editions_test.exs (async: false)
  # alongside add_game_from_bgg/2's — both take the SAME per-BGG-id
  # `pg_advisory_xact_lock`, and that lock is held until the test's own
  # sandbox transaction ends (see add_game_from_bgg/2's own @doc for why
  # an async: true module is unsafe for it).

  describe "clear_bgg_id/1, restore_bgg_id/3 (open item 3, plan 01.8.2-21)" do
    test "clears bgg_id and resets enrichment_status to no_bgg_id" do
      game = game_fixture(%{bgg_id: 184_267, enrichment_status: "bgg_missing"})

      assert {:ok, updated} = Catalog.clear_bgg_id(game)
      assert updated.bgg_id == nil
      assert updated.enrichment_status == "no_bgg_id"
    end

    test "restore_bgg_id/3 puts the exact snapshotted id and status back" do
      game = game_fixture(%{bgg_id: 184_267, enrichment_status: "bgg_missing"})
      {:ok, cleared} = Catalog.clear_bgg_id(game)

      assert {:ok, restored} = Catalog.restore_bgg_id(cleared, 184_267, "bgg_missing")
      assert restored.bgg_id == 184_267
      assert restored.enrichment_status == "bgg_missing"
    end
  end

  describe "UnpublishStillEmptyGames.still_empty_query/0 (D-36 migration predicate)" do
    alias PukllayClub.Repo.Migrations.UnpublishStillEmptyGames

    test "selects a published game with no description and no cover" do
      empty = game_fixture(%{name: "Vacío", status: :published, description: nil, cover_url: nil})

      ids = Repo.all(UnpublishStillEmptyGames.still_empty_query())

      assert ids == [empty.id]
    end

    test "treats a blank-string description the same as a nil one" do
      empty = game_fixture(%{name: "Descripción vacía", status: :published, description: "", cover_url: nil})

      ids = Repo.all(UnpublishStillEmptyGames.still_empty_query())

      assert ids == [empty.id]
    end

    test "excludes a game with a description, even with no cover" do
      game_fixture(%{name: "Con descripción", status: :published, description: "Algo", cover_url: nil})

      assert Repo.all(UnpublishStillEmptyGames.still_empty_query()) == []
    end

    test "excludes a game with a cover, even with no description" do
      game_fixture(%{
        name: "Con portada",
        status: :published,
        description: nil,
        cover_url: "https://images.test.invalid/games/1/cover-large.webp"
      })

      assert Repo.all(UnpublishStillEmptyGames.still_empty_query()) == []
    end

    test "excludes a draft or retired game even when empty (only :published rows are candidates)" do
      game_fixture(%{name: "Borrador vacío", status: :draft, description: nil, cover_url: nil})
      game_fixture(%{name: "Retirado vacío", status: :retired, description: nil, cover_url: nil})

      assert Repo.all(UnpublishStillEmptyGames.still_empty_query()) == []
    end
  end

  describe "list_admin_games/1, count_admin_games/1 (D-09 Task 2)" do
    test "with no :status opt, returns games of every status (unlike every public read)" do
      draft = game_fixture(%{name: "A Borrador", status: :draft})
      published = game_fixture(%{name: "B Publicado", status: :published})
      retired = game_fixture(%{name: "C Retirado", status: :retired})

      ids = Enum.map(Catalog.list_admin_games(), & &1.id)

      assert draft.id in ids
      assert published.id in ids
      assert retired.id in ids
      assert Catalog.count_admin_games() == 3
    end

    test ":status filters to exactly that lifecycle state" do
      game_fixture(%{name: "Borrador", status: :draft})
      game_fixture(%{name: "Publicado", status: :published})
      game_fixture(%{name: "Retirado", status: :retired})

      assert [status: :draft] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Borrador"]
      assert Catalog.count_admin_games(status: :draft) == 1
      assert [status: :published] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Publicado"]
      assert [status: :retired] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Retirado"]
    end

    test ":q searches by name, case-insensitively" do
      game_fixture(%{name: "Catán"})
      game_fixture(%{name: "Carcassonne"})

      assert [q: "cat"] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Catán"]
      assert [q: "CATÁN"] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Catán"]
    end

    test "T-01.8.1-23: a literal % or _ in :q is escaped, not treated as an ILIKE wildcard" do
      game_fixture(%{name: "100% Juego"})
      game_fixture(%{name: "Otro Juego"})

      assert [q: "100%"] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["100% Juego"]
    end

    test "results are ordered by name then id, with :limit/:offset paging over the full set" do
      game_fixture(%{name: "Zeta"})
      game_fixture(%{name: "Alfa"})
      game_fixture(%{name: "Medio"})

      assert Enum.map(Catalog.list_admin_games(), & &1.name) == ["Alfa", "Medio", "Zeta"]
      assert [limit: 2] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Alfa", "Medio"]
      assert [limit: 2, offset: 2] |> Catalog.list_admin_games() |> Enum.map(& &1.name) == ["Zeta"]
    end
  end

  describe "list_admin_games_by_status/1 (D-25, plan 01.8.2-14)" do
    test "returns a map with one key per status, every game in exactly one" do
      draft = game_fixture(%{name: "Borrador", status: :draft})
      published = game_fixture(%{name: "Publicado", status: :published})
      retired = game_fixture(%{name: "Retirado", status: :retired})

      groups = Catalog.list_admin_games_by_status()

      assert Enum.map(groups.draft, & &1.id) == [draft.id]
      assert Enum.map(groups.published, & &1.id) == [published.id]
      assert Enum.map(groups.retired, & &1.id) == [retired.id]
    end

    test "the partition sums to count_admin_games/1 — assert it, don't assume it" do
      for n <- 1..5, do: game_fixture(%{name: "D#{n}", status: :draft})
      for n <- 1..7, do: game_fixture(%{name: "P#{n}", status: :published})
      for n <- 1..3, do: game_fixture(%{name: "R#{n}", status: :retired})

      groups = Catalog.list_admin_games_by_status()
      total = length(groups.draft) + length(groups.published) + length(groups.retired)

      assert total == Catalog.count_admin_games()
      assert total == 15
    end

    test "an empty status is simply an empty list, not a missing key" do
      game_fixture(%{status: :published})

      groups = Catalog.list_admin_games_by_status()

      assert groups.draft == []
      assert groups.retired == []
    end

    test "each group is ordered by name then id, matching list_admin_games/1's tie-break" do
      game_fixture(%{name: "Zeta", status: :draft})
      game_fixture(%{name: "Alfa", status: :draft})

      groups = Catalog.list_admin_games_by_status()

      assert Enum.map(groups.draft, & &1.name) == ["Alfa", "Zeta"]
    end

    test ":q narrows every group by name, case-insensitively" do
      game_fixture(%{name: "Catán", status: :draft})
      game_fixture(%{name: "Carcassonne", status: :published})

      groups = Catalog.list_admin_games_by_status(q: "cat")

      assert Enum.map(groups.draft, & &1.name) == ["Catán"]
      assert groups.published == []
    end

    test "a :status opt is ignored — the grouping IS the status split" do
      game_fixture(%{name: "Borrador", status: :draft})
      game_fixture(%{name: "Publicado", status: :published})

      groups = Catalog.list_admin_games_by_status(status: :draft)

      assert length(groups.draft) == 1
      assert length(groups.published) == 1
    end
  end
end
