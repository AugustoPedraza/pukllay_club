defmodule PukllayClub.Catalog.SectionsBackfillTest do
  @moduledoc """
  Replays `priv/repo/migrations/20260914150000_create_sections.exs`'s
  own `backfill_statements/0` against fixture data (D-22, 01.8.1-10) —
  proof that the migration's raw SQL, not just the read path built on
  top of it, does the right data transform. `async: false` (DataCase):
  this test deletes every `sections`/`section_games` row before
  replaying the backfill, which would race any concurrently-running
  async test that reads the migration-inserted rows.
  """
  use PukllayClub.DataCase, async: false

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Repo

  @migration_path Path.join([File.cwd!(), "priv/repo/migrations/20260914150000_create_sections.exs"])

  setup do
    Code.require_file(@migration_path)
    Repo.delete_all("section_games")
    Repo.delete_all("sections")
    :ok
  end

  test "replaying backfill_statements/0 recreates the eight sections and migrates tagged games ordered by name (D-22)" do
    zeta = game_fixture(%{name: "Zeta", tags: ["#CreaConexiones"], weight_band: nil})
    alfa = game_fixture(%{name: "Alfa", tags: ["#CreaConexiones"], weight_band: nil})
    duelos_game = game_fixture(%{name: "Duelos Game", tags: ["#DuelosMemorables"], weight_band: nil})
    untagged = game_fixture(%{name: "Untagged Game", tags: [], weight_band: nil})

    # A literal qualified call (`Migration.backfill_statements()`) would
    # warn "function is undefined" at compile time — this module is only
    # loaded at runtime via `Code.require_file/1` above, not compiled as
    # part of `lib/`. `Module.concat/2` builds the module atom dynamically
    # so the compiler cannot resolve it ahead of time — the same runtime
    # dispatch `apply/3` would give, without tripping Credo's
    # Refactor.Apply check for a call whose arity is already known.
    migration = Module.concat(PukllayClub.Repo.Migrations, CreateSections)

    for sql <- migration.backfill_statements() do
      Repo.query!(sql)
    end

    sections =
      Repo.all(from(s in "sections", select: %{id: s.id, name: s.name, position: s.position}))

    assert length(sections) == 8

    assert Enum.map(Enum.sort_by(sections, & &1.position), & &1.name) == [
             "Destacados del club",
             "Crea conexiones",
             "Equipo ganador",
             "Duelos memorables",
             "Descubre el hobby",
             "Ingenio estratega",
             "Nivel experto",
             "Recientemente añadidos"
           ]

    crea = Enum.find(sections, &(&1.name == "Crea conexiones"))

    crea_memberships =
      Repo.all(
        from(sg in "section_games",
          where: sg.section_id == ^crea.id,
          order_by: sg.position,
          select: %{game_id: sg.game_id, position: sg.position}
        )
      )

    assert Enum.map(crea_memberships, & &1.game_id) == [alfa.id, zeta.id]
    assert Enum.map(crea_memberships, & &1.position) == [1, 2]

    duelos = Enum.find(sections, &(&1.name == "Duelos memorables"))

    duelos_memberships =
      Repo.all(from(sg in "section_games", where: sg.section_id == ^duelos.id, select: sg.game_id))

    assert duelos_memberships == [duelos_game.id]

    untagged_memberships =
      Repo.all(from(sg in "section_games", where: sg.game_id == ^untagged.id, select: sg.id))

    assert untagged_memberships == []
  end
end
