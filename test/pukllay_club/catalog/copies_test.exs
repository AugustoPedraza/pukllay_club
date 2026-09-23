defmodule PukllayClub.Catalog.CopiesTest do
  @moduledoc """
  Proves the `copies` table + `Copy` schema (D-01, D-02, D-03, D-05,
  01.8.2-01 — the phase tracer): both unique indexes surface as changeset
  errors, the two `on_delete` behaviors hold, and
  `priv/repo/migrations/20260923120000_create_copies.exs`'s own
  `backfill_statements/0` produces exactly the copy rows D-05 describes
  when replayed against fixture data. `async: false` (DataCase): the
  backfill-replay tests delete every `copies` row before replaying,
  which would race any concurrently-running async test creating copies.
  """
  use PukllayClub.DataCase, async: false

  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Repo

  @migration_path Path.join([File.cwd!(), "priv/repo/migrations/20260923120000_create_copies.exs"])

  describe "changeset/2" do
    test "requires game_id and number" do
      changeset = Copy.changeset(%Copy{}, %{})

      refute changeset.valid?
      assert %{game_id: ["can't be blank"], number: ["can't be blank"]} = errors_on(changeset)
    end

    test "two copies of the same game cannot share a number" do
      game = game_fixture()
      copy_fixture(%{game_id: game.id, number: 1})

      assert {:error, changeset} =
               %Copy{} |> Copy.changeset(%{game_id: game.id, number: 1}) |> Repo.insert()

      assert %{game_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "two copies on the same estante cannot share a position" do
      shelf = shelf_fixture()
      game_a = game_fixture(%{name: "Copia A"})
      game_b = game_fixture(%{name: "Copia B"})
      copy_fixture(%{game_id: game_a.id, shelf_id: shelf.id, position: 0})

      assert {:error, changeset} =
               %Copy{}
               |> Copy.changeset(%{game_id: game_b.id, number: 1, shelf_id: shelf.id, position: 0})
               |> Repo.insert()

      assert %{shelf_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "two unplaced copies (shelf_id nil) never collide, even with the same nil position" do
      game_a = game_fixture(%{name: "Copia A"})
      game_b = game_fixture(%{name: "Copia B"})

      assert %Copy{} = copy_fixture(%{game_id: game_a.id})
      assert %Copy{} = copy_fixture(%{game_id: game_b.id})
    end
  end

  describe "deletion cascades (D-01)" do
    test "deleting a game deletes its copies" do
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id})

      Repo.delete!(game)

      refute Repo.get(Copy, copy.id)
    end

    test "deleting an estante leaves its copies without a shelf" do
      shelf = shelf_fixture()
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id, shelf_id: shelf.id, position: 0})

      Repo.delete!(shelf)

      reloaded = Repo.get!(Copy, copy.id)
      assert reloaded.shelf_id == nil
    end
  end

  describe "replaying backfill_statements/0 against fixture data (D-01, D-02, D-03, D-05)" do
    setup do
      Code.require_file(@migration_path)
      Repo.delete_all(Copy)
      :ok
    end

    test "a game with units = 3 backfills to exactly 3 unplaced copies numbered 1, 2, 3" do
      game = game_fixture(%{units: 3})
      other = game_fixture(%{name: "Otro juego", units: 1})

      run_backfill()

      copies = game.id |> copies_for_game() |> Enum.sort_by(& &1.number)
      assert Enum.map(copies, & &1.number) == [1, 2, 3]
      assert Enum.all?(copies, &(is_nil(&1.shelf_id) and is_nil(&1.position)))

      assert [other_copy] = copies_for_game(other.id)
      assert other_copy.number == 1
    end

    test "a game with units = NULL backfills to exactly 1 unplaced copy numbered 1" do
      game = game_fixture(%{units: nil})

      run_backfill()

      assert [copy] = copies_for_game(game.id)
      assert copy.number == 1
      assert is_nil(copy.shelf_id)
      assert is_nil(copy.position)
    end

    test "backfill never places a copy, regardless of the game's own games.shelf_id" do
      shelf = shelf_fixture()
      game = game_fixture(%{units: 2})
      game |> Ecto.Changeset.change(shelf_id: shelf.id) |> Repo.update!()

      run_backfill()

      copies = copies_for_game(game.id)
      assert length(copies) == 2
      assert Enum.all?(copies, &(is_nil(&1.shelf_id) and is_nil(&1.position)))
    end
  end

  defp run_backfill do
    migration = Module.concat(PukllayClub.Repo.Migrations, CreateCopies)

    for sql <- migration.backfill_statements() do
      Repo.query!(sql)
    end
  end

  defp copies_for_game(game_id) do
    Repo.all(from(c in Copy, where: c.game_id == ^game_id))
  end
end
