defmodule Mix.Tasks.Catalog.BackfillGallery do
  @shortdoc "Clears games.gallery_urls across the catalog — no network I/O, safe to re-run"
  @moduledoc """
  Clears `games.gallery_urls` for every game that still carries a stale
  gallery entry (D-07, phase 01.3.1's fix for other-edition, other-language
  box covers being surfaced as extra photos of the game).

  This task performs no network I/O and no R2 write, and is safe to re-run:
  once a game's `gallery_urls` is `[]`, it is no longer selected as a
  candidate, so re-running against an already-corrected catalog reports
  zero scanned and zero updated.

      mix catalog.backfill_gallery [--dry-run]

  `--dry-run` scans and reports without writing to the database.
  """
  use Mix.Task

  alias PukllayClub.Catalog.Seed.GalleryBackfill

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [dry_run: :boolean])

    Mix.Task.run("app.start")

    dry_run? = Keyword.get(opts, :dry_run, false)
    summary = GalleryBackfill.run(dry_run: dry_run?)

    Mix.shell().info(
      "#{dry_run_prefix(dry_run?)}Gallery backfill complete: #{summary.updated}/#{summary.scanned} scanned."
    )
  end

  defp dry_run_prefix(true), do: "[DRY RUN] "
  defp dry_run_prefix(false), do: ""
end
