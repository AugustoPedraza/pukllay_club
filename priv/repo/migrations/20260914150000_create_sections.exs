defmodule PukllayClub.Repo.Migrations.CreateSections do
  use Ecto.Migration

  @moduledoc """
  `sections` + `section_games` (D-17..D-28, 01.8.1-10): the home page's
  rows are now staff-owned database rows, not the hardcoded 8-row dispatch
  that used to live in `Catalog.carousel_row_specs/0`/`row_query/1`. A
  section's membership is either `manual` (hand-picked via
  `section_games`, ordered by `position` or by `name`), `weight_band`
  (automatic — every game whose `weight_band` column equals `rule_value`,
  D-20), or `recent` (automatic — every non-expansion game, D-21). At most
  one section is `featured` (enforced by the partial unique index below)
  and always renders first as the home page's hero row (D-18); `hidden` is
  a staff toggle, independent of `Catalog.list_home_sections/0`'s own "no
  published members" hide rule (D-24).

  **The backfill below is why this runs as a real data migration in the
  deploy migration itself** — mirroring
  `priv/repo/migrations/20260818222551_add_games_is_expansion.exs`'s own
  precedent — rather than a one-time offline script: Kamal's entrypoint
  runs migrations before the new container becomes healthy, so
  production's three existing hashtag tags (`#CreaConexiones`,
  `#EquipoGanador`, `#DuelosMemorables` on `games.tags`) become sections
  with their current members the moment this deploy lands, sorted by name
  exactly as today (D-22). The home page looks the same on day one, except
  the newly-created `featured` section being hidden because it starts with
  zero members (D-24). D-23: today's automatic "Destacados del club" rule
  (the union of the 3 hashtags) is dropped entirely — the new featured
  section is purely hand-picked from here on.

  `games.tags` is never dropped by this migration, under any of the D-22
  checkpoint's options — see `01.8.1-10-SUMMARY.md` for which option this
  plan recorded. A later plan drops the column only under the explicit
  option that calls for it, once public chips stop reading it.

  `backfill_statements/0` is public so
  `test/pukllay_club/catalog/sections_backfill_test.exs` can replay the
  exact same SQL against fixture data (D-22 verification) without
  re-running this migration.
  """

  def change do
    create table(:sections) do
      add :name, :string, size: 40, null: false
      add :subtitle, :string, size: 160
      add :position, :integer, null: false
      add :featured, :boolean, null: false, default: false
      add :hidden, :boolean, null: false, default: false
      add :kind, :string, null: false
      add :rule_value, :string
      add :sort, :string, null: false, default: "name"

      timestamps()
    end

    create constraint(:sections, :sections_kind_known,
             check: "kind IN ('manual', 'weight_band', 'recent')"
           )

    create constraint(:sections, :sections_sort_known,
             check: "sort IN ('manual', 'name', 'bgg_weight', 'bgg_rating', 'recent')"
           )

    create constraint(:sections, :sections_weight_band_rule,
             check:
               "kind <> 'weight_band' OR rule_value IN ('descubre_el_hobby', 'ingenio_estratega', 'nivel_experto')"
           )

    create unique_index(:sections, [:featured],
             where: "featured",
             name: :sections_one_featured_index
           )

    create table(:section_games) do
      add :section_id, references(:sections, on_delete: :delete_all), null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :position, :integer, null: false

      timestamps()
    end

    create unique_index(:section_games, [:section_id, :game_id])
    create index(:section_games, [:section_id, :position])

    [sections_sql, crea_conexiones_sql, equipo_ganador_sql, duelos_memorables_sql] =
      backfill_statements()

    execute(sections_sql, "DELETE FROM sections")
    execute(crea_conexiones_sql, "DELETE FROM section_games")
    execute(equipo_ganador_sql, "DELETE FROM section_games")
    execute(duelos_memorables_sql, "DELETE FROM section_games")
  end

  @doc """
  The up-direction SQL statements this migration's backfill runs, in
  order — public so `sections_backfill_test.exs` can replay them verbatim
  against fixture data. Subtitles are written as literal strings (copied
  from `Catalog.Vocabulary`'s current values), not module calls — a
  migration must never depend on future application code.
  """
  def backfill_statements do
    [
      """
      INSERT INTO sections
        (name, subtitle, position, featured, hidden, kind, rule_value, sort, inserted_at, updated_at)
      VALUES
        ('Destacados del club', 'La selección del club — los juegos que más recomendamos ahora mismo.', 0, true, false, 'manual', NULL, 'manual', now(), now()),
        ('Crea conexiones', 'Reglas simples, familiar / diversión garantizada', 1, false, false, 'manual', NULL, 'name', now(), now()),
        ('Equipo ganador', 'Cooperativo', 2, false, false, 'manual', NULL, 'name', now(), now()),
        ('Duelos memorables', 'Solo 2 jugadores', 3, false, false, 'manual', NULL, 'name', now(), now()),
        ('Descubre el hobby', 'Reglas cortas que se explican en 5-10 minutos. Ideal si es tu primera vez.', 4, false, false, 'weight_band', 'descubre_el_hobby', 'name', now(), now()),
        ('Ingenio estratega', 'Reglas de 15-20 minutos y decisiones pensando un par de jugadas por delante.', 5, false, false, 'weight_band', 'ingenio_estratega', 'name', now(), now()),
        ('Nivel experto', 'Reglas largas y decisiones profundas. Para mesas con experiencia.', 6, false, false, 'weight_band', 'nivel_experto', 'name', now(), now()),
        ('Recientemente añadidos', 'Las incorporaciones más nuevas a la ludoteca.', 7, false, false, 'recent', NULL, 'recent', now(), now())
      """,
      section_membership_sql("Crea conexiones", "#CreaConexiones"),
      section_membership_sql("Equipo ganador", "#EquipoGanador"),
      section_membership_sql("Duelos memorables", "#DuelosMemorables")
    ]
  end

  defp section_membership_sql(section_name, tag) do
    """
    INSERT INTO section_games (section_id, game_id, position, inserted_at, updated_at)
    SELECT s.id, g.id, row_number() OVER (ORDER BY g.name, g.id), now(), now()
    FROM games g, sections s
    WHERE s.name = '#{section_name}' AND g.tags @> ARRAY['#{tag}']::varchar[]
    """
  end
end
