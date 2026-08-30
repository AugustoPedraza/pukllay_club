defmodule Mix.Tasks.Catalog.BackfillArtists do
  @shortdoc "Fills games.artists from already-stored bgg_payload — no network I/O, safe to re-run"
  @moduledoc """
  Fills `games.artists` from the `"artists"` entry already stored in each
  game's `bgg_payload`, deduplicated via
  `PukllayClub.Catalog.Seed.BggClient.dedup_artists/1` — the same rule the
  extraction layer applies, never a local reimplementation.

  This task performs no network I/O whatsoever and is safe to re-run:
  re-running against an already-deduplicated payload writes the identical
  `artists` value.

      mix catalog.backfill_artists [--dry-run]

  `--dry-run` scans and reports without writing to the database.
  """
  use Mix.Task

  alias PukllayClub.Catalog.Seed.StatsEnricher

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [dry_run: :boolean])

    Mix.Task.run("app.start")

    summary = StatsEnricher.backfill_artists_from_payload(dry_run: Keyword.get(opts, :dry_run, false))

    Mix.shell().info(
      "Artists backfill complete: #{summary.updated}/#{summary.scanned} scanned, " <>
        "#{summary.deduplicated} row(s) had duplicated entries."
    )
  end
end
