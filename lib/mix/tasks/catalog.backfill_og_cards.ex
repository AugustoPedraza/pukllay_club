defmodule Mix.Tasks.Catalog.BackfillOgCards do
  @shortdoc "Letterboxes every game's stored cover into a 1200x630 og-card.webp and uploads it to R2"
  @moduledoc """
  Letterboxes every game's already-stored cover onto a 1200x630
  brand-coloured canvas (D-06/D-07/D-08, phase 01.8) and uploads it to R2 as
  `<key>/og-card.webp`, alongside the existing cover variants.

      mix catalog.backfill_og_cards [--dry-run]

  `--dry-run` scans and reports without fetching, transforming, or
  uploading anything.

  Unlike `catalog.backfill_gallery`, this task DOES perform network I/O
  (real requests) on every candidate row — see
  `PukllayClub.Catalog.Seed.OGCardBackfill`'s moduledoc for the full
  re-run/idempotency contract (a re-run is cheap, but it never replaces an
  already-written object's content).
  """
  use Mix.Task

  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.OGCardBackfill

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [dry_run: :boolean])

    Mix.Task.run("app.start")

    dry_run? = Keyword.get(opts, :dry_run, false)
    credentials = if dry_run?, do: nil, else: Credentials.fetch!()

    summary = OGCardBackfill.run(dry_run: dry_run?, credentials: credentials)

    Mix.shell().info(
      "#{dry_run_prefix(dry_run?)}OG card backfill complete: #{summary.updated}/#{summary.scanned} scanned."
    )
  end

  defp dry_run_prefix(true), do: "[DRY RUN] "
  defp dry_run_prefix(false), do: ""
end
