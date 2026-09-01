defmodule PukllayClub.Catalog.Seed.GalleryBackfillTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.GalleryBackfill
  alias PukllayClub.Repo

  @stale_gallery [
    "https://images.test.invalid/games/1/gallery-1.webp",
    "https://images.test.invalid/games/1/gallery-2.webp"
  ]

  test "clears gallery_urls for a game with stale entries" do
    game = game_fixture(%{gallery_urls: @stale_gallery})

    GalleryBackfill.run([])

    reloaded = Repo.get!(Game, game.id)
    assert reloaded.gallery_urls == []
  end

  test "leaves cover_url, thumbnail_url, name, description and bgg_payload byte-identical" do
    game =
      game_fixture(%{
        gallery_urls: @stale_gallery,
        cover_url: "https://images.test.invalid/games/1/cover-large.webp",
        thumbnail_url: "https://images.test.invalid/games/1/cover-thumb.webp",
        name: "Endless Winter: Paleoamericans",
        description: "Descripción sin tocar.",
        bgg_payload: %{"versions" => []}
      })

    GalleryBackfill.run([])

    reloaded = Repo.get!(Game, game.id)
    assert reloaded.cover_url == game.cover_url
    assert reloaded.thumbnail_url == game.thumbnail_url
    assert reloaded.name == game.name
    assert reloaded.description == game.description
    assert reloaded.bgg_payload == game.bgg_payload
  end

  test "dry_run: true reports scanned/updated but writes nothing" do
    game = game_fixture(%{gallery_urls: @stale_gallery})

    summary = GalleryBackfill.run(dry_run: true)

    assert summary.scanned == 1
    assert summary.updated == 1

    reloaded = Repo.get!(Game, game.id)
    assert reloaded.gallery_urls == @stale_gallery
  end

  test "running twice in a row is a no-op the second time" do
    game_fixture(%{gallery_urls: @stale_gallery})

    assert %{scanned: 1, updated: 1} = GalleryBackfill.run([])
    assert %{scanned: 0, updated: 0} = GalleryBackfill.run([])
  end

  test "a game that already has gallery_urls == [] is never scanned" do
    game = game_fixture(%{gallery_urls: []})

    assert %{scanned: 0, updated: 0} = GalleryBackfill.run([])

    reloaded = Repo.get!(Game, game.id)
    assert reloaded.gallery_urls == []
  end
end
