defmodule Mix.Tasks.Catalog.EnrichBggStats do
  @shortdoc "One-time BGG weight/rating/rank/artists re-enrichment (D-06) — never touches images"
  @moduledoc """
  Re-fetches `bgg_weight`, `bgg_rating`, `bgg_rank`, `artists` and
  `bgg_payload` from BGG's live API for every `games` row with a non-nil
  `bgg_id`, via `PukllayClub.Catalog.Seed.StatsEnricher.enrich_from_bgg/2`.

  This is a one-time, manually-run, developer-machine task — deliberately
  narrower than `mix catalog.seed`, which unconditionally drives the R2
  image pipeline for every row (01.3-RESEARCH.md, Alternatives Considered):
  this task never re-downloads, resizes or re-uploads a cover image, and
  touches no column outside its narrow allowlist.

      mix catalog.enrich_bgg_stats [--limit N] [--dry-run]

  `--limit N` processes only the first N candidate games (ordered by id).
  `--dry-run` performs the BGG fetch but writes nothing to the database —
  useful for previewing the run's summary counters before committing to a
  live re-enrichment pass against BGG's rate limit.

  Writes a Markdown run record to
  `priv/repo/seed_data/bgg_stats_enrichment_report.md` holding the run
  timestamp, every summary counter, and the full list of failed batches and
  unranked games, so a partial or rate-limited run leaves a reviewable
  record rather than only scrollback.
  """
  use Mix.Task

  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.StatsEnricher

  @report_relative_path "priv/repo/seed_data/bgg_stats_enrichment_report.md"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [limit: :integer, dry_run: :boolean])

    Mix.Task.run("app.start")

    credentials = Credentials.fetch!()
    Mix.shell().info("Enrichment credentials: #{inspect(Credentials.redacted(credentials))}")

    dry_run? = Keyword.get(opts, :dry_run, false)

    summary =
      StatsEnricher.enrich_from_bgg(credentials,
        limit: opts[:limit],
        dry_run: dry_run?
      )

    Mix.shell().info(
      "#{dry_run_prefix(dry_run?)}BGG stats enrichment complete: #{summary.updated}/#{summary.candidates} updated, " <>
        "#{length(summary.missing_from_bgg)} missing from BGG, #{length(summary.unranked)} unranked, " <>
        "#{length(summary.failed_batches)} failed batch(es)."
    )

    write_report!(summary, dry_run?)
  end

  # WR-01 (01.3 code review): mirrors catalog.seed.ex's existing
  # "[dry-run] ..." convention so a dry-run's console output and persisted
  # report can never be mistaken for a real run's — the counters themselves
  # are unchanged (still preview counts), only the label is added.
  defp dry_run_prefix(true), do: "[DRY RUN] "
  defp dry_run_prefix(false), do: ""

  defp write_report!(summary, dry_run?) do
    report_path = Path.join(File.cwd!(), @report_relative_path)
    File.mkdir_p!(Path.dirname(report_path))
    File.write!(report_path, report_content(summary, dry_run?))
    Mix.shell().info("Report written to #{report_path}")
  end

  defp report_content(summary, dry_run?) do
    """
    # BGG Stats Enrichment Report
    #{if dry_run?, do: "\n**[DRY RUN]** — no database writes were performed; all counts below are a preview.\n"}
    Run at: #{DateTime.to_iso8601(DateTime.utc_now())}

    - Candidates: #{summary.candidates}
    - Fetched: #{summary.fetched}
    - Updated: #{summary.updated}
    - Missing from BGG: #{length(summary.missing_from_bgg)}
    - Unranked: #{length(summary.unranked)}
    - Failed batches: #{length(summary.failed_batches)}

    ## Missing from BGG

    #{format_id_list(summary.missing_from_bgg)}

    ## Unranked

    #{format_id_list(summary.unranked)}

    ## Failed batches

    #{format_failed_batches(summary.failed_batches)}
    """
  end

  defp format_id_list([]), do: "None."
  defp format_id_list(ids), do: Enum.map_join(ids, "\n", &"- #{&1}")

  defp format_failed_batches([]), do: "None."

  defp format_failed_batches(batches),
    do: Enum.map_join(batches, "\n", fn {ids, reason} -> "- #{inspect(ids)}: #{inspect(reason)}" end)
end
