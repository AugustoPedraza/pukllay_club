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
  """
  def game_fixture(attrs \\ %{}) do
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
      tags: ["#CreaConexiones"],
      mechanics: ["Comercio", "Colocación de dados"],
      themes: ["Estrategia"],
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
    |> Repo.insert!()
  end
end
