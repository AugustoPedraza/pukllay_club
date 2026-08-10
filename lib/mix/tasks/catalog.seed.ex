defmodule Mix.Tasks.Catalog.Seed do
  @shortdoc "One-time BGG-enrichment + image-resize + R2-upload catalog seed (D-02)"
  @moduledoc """
  Streams the club's `ludoteca.csv` export, resolves each row's weight band
  and editorial tags from the club's own hashtags (D-05/D-06/D-20), enriches
  each row with a batched call to the BGG XML API, downloads/resizes/uploads
  the cover image (Spanish-preferred, D-04) plus a small gallery to R2, and
  upserts one `games` row per CSV row. Every finding that can't be resolved
  without guessing is written to `priv/repo/seed_data/catalog_seed_report.md`
  for manual review (D-18/D-19/D-20/D-04).

      mix catalog.seed [--limit N] [--dry-run] [--report-only]

  `--limit N` processes only the first N CSV data rows (after the CSV
  parser's own blank-`Nombre` skip). `--dry-run` runs the full CSV parse
  and BGG fetch but skips the database write and the R2 upload — useful
  for verifying the BGG XML field mapping (01-RESEARCH.md Assumption A1)
  without touching the database or R2. `--report-only` parses and analyzes
  the CSV only — no BGG call, no image work, no database write — so the
  data-quality audit can be re-run in seconds without burning BGG rate
  limit.

  This is a one-time, manually-run task (D-02) — not an Oban job, and not
  meant to run on the 1GB-RAM production host (Pitfall 6).
  """
  use Mix.Task

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.CsvImport
  alias PukllayClub.Catalog.Seed.HashtagNormalizer
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.Report

  @batch_size 20
  @inter_batch_delay_ms 1500
  @report_relative_path "priv/repo/seed_data/catalog_seed_report.md"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args, strict: [limit: :integer, dry_run: :boolean, report_only: :boolean])

    Mix.Task.run("app.start")

    report_only? = Keyword.get(opts, :report_only, false)
    dry_run? = Keyword.get(opts, :dry_run, false)

    csv_rows =
      CsvImport.stream_rows()
      |> maybe_limit(opts[:limit])
      |> Enum.to_list()

    {rows, report} = build_rows_and_report(csv_rows)
    report = report |> Report.set_rows_analyzed(length(rows)) |> accumulate_duplicates(rows)

    if report_only? do
      Report.write!(report, report_path())
      Mix.shell().info("Report-only run complete: #{length(rows)} row(s) analyzed. Report at #{report_path()}")
    else
      run_full_seed(rows, report, dry_run?)
    end
  end

  defp run_full_seed(rows, report, dry_run?) do
    credentials = Credentials.fetch!()
    Mix.shell().info("Seed credentials: #{inspect(Credentials.redacted(credentials))}")

    items_by_bgg_id = fetch_all(rows, credentials)
    report = accumulate_bgg_missing(report, rows, items_by_bgg_id)

    report =
      Enum.reduce(rows, report, fn row, acc ->
        process_row(row, items_by_bgg_id, credentials, dry_run?, acc)
      end)

    Report.write!(report, report_path())
    Mix.shell().info("Seed complete: #{length(rows)} row(s) processed. Report at #{report_path()}")
  end

  defp report_path, do: Path.join(File.cwd!(), @report_relative_path)

  defp maybe_limit(stream, nil), do: stream
  defp maybe_limit(stream, limit), do: Stream.take(stream, limit)

  # Builds the row list (with weight_band/tags already resolved) alongside
  # the Report accumulator in a single pass, since resolving weight_band is
  # exactly where the D-20 unrecognized-cell and conflict/zero-hashtag
  # findings are discovered.
  defp build_rows_and_report(csv_rows) do
    Enum.map_reduce(csv_rows, Report.new(), fn {row_number, fields}, report ->
      name = Map.get(fields, "Nombre")
      bgg_id = parse_int(Map.get(fields, "BGG_ID"))
      units = parse_int(Map.get(fields, "Unidades"))

      {weight_band, report} = classify_weight(report, row_number, name, fields)
      report = accumulate_unrecognized(report, row_number, name, fields)
      report = if is_nil(bgg_id), do: Report.add(report, :no_bgg_id, %{row: row_number, name: name}), else: report

      row = %{
        row_number: row_number,
        name: name,
        bgg_id: bgg_id,
        units: units,
        weight_band: weight_band,
        tags: HashtagNormalizer.editorial_tags(fields)
      }

      {row, report}
    end)
  end

  defp classify_weight(report, row_number, name, fields) do
    resolution = HashtagNormalizer.resolve_weight_band(fields)
    true_count = weight_hashtag_true_count(fields)

    case {true_count, resolution} do
      {1, {:ok, band, :hashtag}} ->
        {band, report}

      {count, {:ok, band, :peso_tie_break}} when count >= 2 ->
        finding = %{row: row_number, name: name, resolution: "peso tie-break -> #{band}"}
        {band, Report.add(report, :weight_conflicts, finding)}

      {0, {:ok, band, :peso_tie_break}} ->
        {band, Report.add(report, :zero_hashtag_peso_resolved, %{row: row_number, name: name, band: band})}

      {count, {:unresolved, :conflict}} when count >= 2 ->
        finding = %{row: row_number, name: name, resolution: "unresolved (no usable Peso_BGG)"}
        {nil, Report.add(report, :weight_conflicts, finding)}

      {0, {:unresolved, :missing}} ->
        {nil, Report.add(report, :zero_hashtag_unresolved, %{row: row_number, name: name})}
    end
  end

  defp weight_hashtag_true_count(fields) do
    HashtagNormalizer.weight_columns()
    |> Map.keys()
    |> Enum.count(&(HashtagNormalizer.truthy?(Map.get(fields, &1)) == true))
  end

  defp accumulate_unrecognized(report, row_number, name, fields) do
    fields
    |> HashtagNormalizer.unrecognized_cells()
    |> Enum.reduce(report, fn {column, value}, acc ->
      Report.add(acc, :unrecognized_hashtags, %{row: row_number, name: name, column: column, value: value})
    end)
  end

  defp accumulate_duplicates(report, rows) do
    rows
    |> Enum.filter(& &1.bgg_id)
    |> Enum.group_by(& &1.bgg_id)
    |> Enum.filter(fn {_bgg_id, group} -> length(group) > 1 end)
    |> Enum.reduce(report, fn {bgg_id, group}, acc ->
      finding = %{bgg_id: bgg_id, rows: Enum.map(group, &%{row: &1.row_number, name: &1.name})}
      Report.add(acc, :duplicate_bgg_id, finding)
    end)
  end

  defp accumulate_bgg_missing(report, rows, items_by_bgg_id) do
    rows
    |> Enum.filter(&(&1.bgg_id && not Map.has_key?(items_by_bgg_id, &1.bgg_id)))
    |> Enum.reduce(report, fn row, acc ->
      Report.add(acc, :bgg_missing, %{row: row.row_number, name: row.name, bgg_id: row.bgg_id})
    end)
  end

  defp parse_int(nil), do: nil

  defp parse_int(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> String.to_integer(trimmed)
    end
  end

  defp fetch_all(rows, credentials) do
    rows
    |> Enum.map(& &1.bgg_id)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.chunk_every(@batch_size)
    |> Enum.with_index()
    |> Enum.reduce(%{}, &merge_batch(&1, &2, credentials))
  end

  defp merge_batch({batch, index}, acc, credentials) do
    if index > 0, do: Process.sleep(@inter_batch_delay_ms)

    case BggClient.fetch_batch(batch, credentials) do
      {:ok, items} ->
        Mix.shell().info("Fetched BGG batch #{index + 1}: #{length(items)} item(s)")
        merge_items(acc, items)

      {:error, reason} ->
        Mix.shell().error("BGG batch fetch failed: #{inspect(reason)}")
        acc
    end
  end

  defp merge_items(acc, items) do
    Enum.into(items, acc, fn item -> {item.bgg_id, item} end)
  end

  defp process_row(%{bgg_id: nil} = row, _items_by_bgg_id, _credentials, dry_run?, report) do
    upsert_or_log(base_attrs(row, "no_bgg_id"), dry_run?)
    report
  end

  defp process_row(row, items_by_bgg_id, credentials, dry_run?, report) do
    case Map.fetch(items_by_bgg_id, row.bgg_id) do
      :error ->
        upsert_or_log(base_attrs(row, "bgg_missing"), dry_run?)
        report

      {:ok, item} ->
        process_enriched_row(row, item, credentials, dry_run?, report)
    end
  end

  defp process_enriched_row(row, item, _credentials, true = _dry_run?, report) do
    Mix.shell().info(inspect(item, pretty: true, limit: :infinity))
    Mix.shell().info("[dry-run] would upsert csv_row=#{row.row_number} bgg_id=#{row.bgg_id}")
    accumulate_observed_terms(report, item)
  end

  defp process_enriched_row(row, item, credentials, false = _dry_run?, report) do
    {image_attrs, report} = image_urls(row, item, credentials, report)

    attrs =
      row
      |> base_attrs("enriched")
      |> enrich_attrs(item)
      |> Map.merge(image_attrs)

    Catalog.upsert_game!(attrs)
    accumulate_observed_terms(report, item)
  end

  defp base_attrs(row, status) do
    %{
      name: row.name,
      csv_row: row.row_number,
      bgg_id: row.bgg_id,
      units: row.units,
      enrichment_status: status,
      weight_band: row.weight_band,
      tags: row.tags
    }
  end

  defp enrich_attrs(base, item) do
    Map.merge(base, %{
      year_published: item.year_published,
      min_players: item.min_players,
      max_players: item.max_players,
      min_playtime: item.min_playtime,
      max_playtime: item.max_playtime,
      playing_time: item.playing_time,
      min_age: item.min_age,
      description: item.description,
      bgg_weight: item.average_weight,
      mechanics: item.mechanics,
      themes: item.categories,
      designers: item.designers,
      publishers: item.publishers,
      bgg_payload: item
    })
  end

  defp accumulate_observed_terms(report, item) do
    report
    |> add_all(:observed_mechanics, item.mechanics)
    |> add_all(:observed_categories, item.categories)
  end

  defp add_all(report, category, values), do: Enum.reduce(values, report, &Report.add(&2, category, &1))

  defp image_urls(row, item, credentials, report) do
    key_prefix = "games/#{row.bgg_id}"

    case ImagePipeline.select_cover(item) do
      {:ok, cover_source_url, source} ->
        report = maybe_flag_no_spanish_edition(report, source, %{row: row.row_number, name: row.name})
        {:ok, gallery_urls} = ImagePipeline.process_gallery(item, key_prefix, credentials)
        {upload_cover(cover_source_url, key_prefix, credentials, row.bgg_id, gallery_urls), report}

      {:error, :no_image} ->
        {%{gallery_urls: []}, report}
    end
  end

  defp upload_cover(cover_source_url, key_prefix, credentials, bgg_id, gallery_urls) do
    case ImagePipeline.process(cover_source_url, key_prefix, credentials) do
      {:ok, urls} ->
        Map.put(urls, :gallery_urls, gallery_urls)

      {:error, reason} ->
        Mix.shell().error("Image pipeline failed for BGG id #{bgg_id}: #{inspect(reason)}")
        %{gallery_urls: gallery_urls}
    end
  end

  defp maybe_flag_no_spanish_edition(report, :primary, finding), do: Report.add(report, :no_spanish_edition, finding)
  defp maybe_flag_no_spanish_edition(report, :spanish_edition, _finding), do: report

  defp upsert_or_log(attrs, true), do: Mix.shell().info("[dry-run] #{inspect(attrs)}")
  defp upsert_or_log(attrs, false), do: Catalog.upsert_game!(attrs)
end
