defmodule PukllayClub.CatalogFixtures do
  @moduledoc """
  Test helpers for creating `PukllayClub.Catalog.Game` fixtures with sane
  Spanish defaults. Later plans (01-04 full seed, 01-05 browse, 01-06
  complexity-teaching UX) extend `game_fixture/1` with weight bands and
  hashtags — keep the `attrs \\ %{}` signature stable so those plans only
  add keys, never change the shape.
  """

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  @doc """
  Inserts a `Game` row with sane Spanish defaults, overridable via `attrs`.

  Accepts an optional `:status` attr (default `:published`, D-04/D-08) —
  applied separately from `seed_changeset/2` (which never casts `:status`,
  see `Game.seed_changeset/2`) via `Ecto.Changeset.put_change/3`, so most
  callers never need to think about it while a test that needs a draft or
  retired game can pass `status: :draft`/`status: :retired`.
  """
  def game_fixture(attrs \\ %{}) do
    {status, attrs} = Map.pop(attrs, :status, :published)

    default_attrs = %{
      name: "Catán",
      csv_row: System.unique_integer([:positive]),
      bgg_id: 13,
      min_players: 3,
      max_players: 4,
      min_playtime: 60,
      max_playtime: 90,
      min_age: 10,
      year_published: 1995,
      weight_band: "ingenio_estratega",
      bgg_weight: 2.3,
      # `tags` has no default (01.8.1-11, D-17/D-22): `games.tags` is
      # frozen history under the D-22 option-A decision — public chips now
      # come from section membership (`PukllayClub.SectionsFixtures`), not
      # this field, so a default value here would be misleading. Pass
      # `tags:` explicitly only for a test that specifically exercises the
      # historical column itself.
      # Raw BGG mechanic/category values (Vocabulary-covered where possible)
      # rather than pre-translated Spanish, so 01-05's facet/glossary tests
      # exercise the same translation path production data goes through.
      mechanics: ["Dice Rolling", "Hand Management"],
      themes: ["Economic"],
      designers: ["Klaus Teuber"],
      publishers: ["Devir"],
      description: "Compite por colonizar la isla de Catán.",
      thumbnail_url: "https://images.test.invalid/games/13/cover-thumb.webp",
      cover_url: "https://images.test.invalid/games/13/cover-large.webp",
      gallery_urls: [],
      enrichment_status: "enriched"
    }

    %Game{}
    |> Game.seed_changeset(Map.merge(default_attrs, attrs))
    |> Ecto.Changeset.put_change(:status, status)
    |> Repo.insert!()
  end
end
