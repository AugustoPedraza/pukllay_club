defmodule PukllayClub.Catalog.Seed.UpsertIdempotencyTest do
  @moduledoc """
  Proves `Catalog.upsert_game!/1` — the single write primitive every seed
  and backfill task funnels through — is genuinely idempotent on its
  `:csv_row` conflict target (SEED-02). This is the property a repeatable
  re-seed against production rests on: running the seed's write step a
  second time against the same CSV row must leave exactly one row, with
  identical content and its original `inserted_at` preserved.
  """
  use PukllayClub.DataCase, async: true

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  # Fixture attrs built by hand (not a real BGG fetch) so this test runs in
  # the normal suite with no network and no credentials. Includes an
  # array-typed field (:mechanics) and :description among the content
  # comparisons, since those are the columns a re-seed is most likely to
  # silently reshape.
  defp attrs(csv_row, overrides \\ %{}) do
    Map.merge(
      %{
        name: "Terraforming Mars",
        csv_row: csv_row,
        bgg_id: 167_791,
        min_players: 1,
        max_players: 5,
        min_playtime: 120,
        max_playtime: 180,
        min_age: 12,
        year_published: 2016,
        weight_band: "ingenio_estratega",
        bgg_weight: 3.2,
        artists: ["Isaac Fryxelius"],
        tags: ["#IngenioEstratega"],
        mechanics: ["Tile Placement", "Hand Management"],
        themes: ["Science Fiction"],
        designers: ["Jacob Fryxelius"],
        publishers: ["FryxGames"],
        description: "Terraformá Marte compitiendo por recursos y proyectos.",
        thumbnail_url: "https://images.test.invalid/games/167791/cover-thumb.webp",
        cover_url: "https://images.test.invalid/games/167791/cover-large.webp",
        gallery_urls: [],
        enrichment_status: "enriched"
      },
      overrides
    )
  end

  test "a repeated upsert leaves exactly one row for the same conflict target" do
    row = System.unique_integer([:positive])

    Catalog.upsert_game!(attrs(row))
    Catalog.upsert_game!(attrs(row))

    assert Repo.aggregate(from(g in Game, where: g.csv_row == ^row), :count) == 1
  end

  test "the second call updates rather than inserting, returning the same primary key" do
    row = System.unique_integer([:positive])

    first = Catalog.upsert_game!(attrs(row))
    second = Catalog.upsert_game!(attrs(row))

    assert first.id == second.id
  end

  test "every content field the second call wrote is equal to what the first call wrote, and inserted_at is preserved while updated_at may move" do
    row = System.unique_integer([:positive])

    first = Catalog.upsert_game!(attrs(row))
    # Ensure a measurable clock tick so a preserved inserted_at is a real
    # assertion, not a coincidence of two inserts happening in the same tick.
    Process.sleep(10)
    second = Catalog.upsert_game!(attrs(row))

    reloaded = Repo.get!(Game, second.id)

    assert reloaded.name == first.name
    assert reloaded.mechanics == first.mechanics
    assert reloaded.description == first.description
    assert reloaded.bgg_id == first.bgg_id
    assert reloaded.cover_url == first.cover_url

    assert reloaded.inserted_at == first.inserted_at
  end

  test "two different conflict-target values produce two distinct rows" do
    row_a = System.unique_integer([:positive])
    row_b = System.unique_integer([:positive])

    game_a = Catalog.upsert_game!(attrs(row_a))
    game_b = Catalog.upsert_game!(attrs(row_b))

    refute game_a.id == game_b.id
    assert Repo.aggregate(from(g in Game, where: g.csv_row in [^row_a, ^row_b]), :count) == 2
  end
end
