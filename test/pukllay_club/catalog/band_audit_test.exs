defmodule PukllayClub.Catalog.BandAuditTest do
  use PukllayClub.DataCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.BandAudit
  alias PukllayClub.Repo

  describe "mismatches/0 (D-29)" do
    test "includes a non-retired game whose weight_band disagrees with its BGG-implied band" do
      game = game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})

      assert [%{id: id}] = BandAudit.mismatches()
      assert id == game.id
    end

    test "excludes a game whose weight_band matches its BGG-implied band" do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 2.3})

      assert BandAudit.mismatches() == []
    end

    test "excludes a game with no bgg_weight" do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: nil})

      assert BandAudit.mismatches() == []
    end

    test "excludes a retired mismatched game" do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8, status: :retired})

      assert BandAudit.mismatches() == []
    end

    test "a nil weight_band with a non-nil bgg_weight is a mismatch" do
      game = game_fixture(%{weight_band: nil, bgg_weight: 3.8})

      assert [%{id: id}] = BandAudit.mismatches()
      assert id == game.id
    end

    test "returns narrow maps with id, name, weight_band, bgg_weight, band_reviewed_band" do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8, name: "Mísbanded"})

      assert [
               %{
                 id: _id,
                 name: "Mísbanded",
                 weight_band: "ingenio_estratega",
                 bgg_weight: 3.8,
                 band_reviewed_band: nil
               }
             ] = BandAudit.mismatches()
    end
  end

  describe "count_mismatches/0" do
    test "returns the count of mismatches/0" do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 2.3})

      assert BandAudit.count_mismatches() == 1
    end
  end

  describe "correct_band/1 (D-30)" do
    test "sets the game's weight_band to its BGG-implied band, removing it from mismatches/0" do
      game = game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})

      assert {:ok, updated} = BandAudit.correct_band(game.id)
      assert updated.weight_band == "nivel_experto"
      assert BandAudit.mismatches() == []
    end

    test "clears any prior review snapshot" do
      game = game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})

      game
      |> Ecto.Changeset.change(band_reviewed_band: "nivel_experto", band_reviewed_at: DateTime.utc_now(:second))
      |> PukllayClub.Repo.update!()

      {:ok, corrected} = BandAudit.correct_band(game.id)

      assert corrected.band_reviewed_band == nil
      assert corrected.band_reviewed_at == nil
    end
  end

  describe "keep_band/1 (D-30)" do
    test "stores the game's current implied band and a timestamp, leaving weight_band untouched" do
      game = game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})

      assert {:ok, kept} = BandAudit.keep_band(game.id)
      assert kept.weight_band == "ingenio_estratega"
      assert kept.band_reviewed_band == "nivel_experto"
      assert %DateTime{} = kept.band_reviewed_at
      assert BandAudit.mismatches() == []
    end

    test "re-surfaces the game once bgg_weight drifts to imply a different band than the snapshot" do
      game = game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})
      {:ok, _kept} = BandAudit.keep_band(game.id)

      assert BandAudit.mismatches() == []

      # Implied band unchanged (still nivel_experto) -> stays hidden.
      game |> Ecto.Changeset.change(bgg_weight: 3.9) |> Repo.update!()
      assert BandAudit.mismatches() == []

      # Implied band now descubre_el_hobby, different from the "nivel_experto"
      # snapshot -> re-surfaces.
      game |> Ecto.Changeset.change(bgg_weight: 1.2) |> Repo.update!()
      assert [%{id: id}] = BandAudit.mismatches()
      assert id == game.id
    end

    test "a bgg_weight change back to matching the club weight_band also stays hidden" do
      game = game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})
      {:ok, _kept} = BandAudit.keep_band(game.id)

      game |> Ecto.Changeset.change(bgg_weight: 2.0) |> Repo.update!()

      assert BandAudit.mismatches() == []
    end
  end
end
