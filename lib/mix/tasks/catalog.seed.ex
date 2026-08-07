defmodule Mix.Tasks.Catalog.Seed do
  @shortdoc "One-time BGG-enrichment + image-resize + R2-upload catalog seed (D-02)"
  @moduledoc """
  Streams the club's `ludoteca.csv` export, enriches each row with a
  batched call to the BGG XML API, downloads/resizes/uploads the cover
  image to R2, and upserts one `games` row per CSV row.

      mix catalog.seed [--limit N] [--dry-run]

  `--limit N` processes only the first N CSV data rows (after the CSV
  parser's own blank-`Nombre` skip). `--dry-run` runs the full CSV parse
  and BGG fetch but skips the database write and the R2 upload — useful
  for verifying the BGG XML field mapping (01-RESEARCH.md Assumption A1)
  without touching the database or R2.

  This is a one-time, manually-run task (D-02) — not an Oban job, and not
  meant to run on the 1GB-RAM production host (Pitfall 6).
  """
  use Mix.Task

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.CsvImport
  alias PukllayClub.Catalog.Seed.ImagePipeline

  @batch_size 20
  @inter_batch_delay_ms 1500

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args, strict: [limit: :integer, dry_run: :boolean])

    Mix.Task.run("app.start")

    credentials = Credentials.fetch!()
    Mix.shell().info("Seed credentials: #{inspect(Credentials.redacted(credentials))}")

    dry_run? = Keyword.get(opts, :dry_run, false)

    rows =
      CsvImport.stream_rows()
      |> Stream.map(&to_row/1)
      |> maybe_limit(opts[:limit])
      |> Enum.to_list()

    items_by_bgg_id = fetch_all(rows, credentials)

    Enum.each(rows, &process_row(&1, items_by_bgg_id, credentials, dry_run?))

    Mix.shell().info("Seed complete: #{length(rows)} row(s) processed.")
  end

  defp maybe_limit(stream, nil), do: stream
  defp maybe_limit(stream, limit), do: Stream.take(stream, limit)

  defp to_row({row_number, %{"Nombre" => name} = fields}) do
    %{
      row_number: row_number,
      name: name,
      bgg_id: parse_int(Map.get(fields, "BGG_ID")),
      units: parse_int(Map.get(fields, "Unidades"))
    }
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

  defp process_row(%{bgg_id: nil} = row, _items_by_bgg_id, _credentials, dry_run?) do
    upsert_or_log(base_attrs(row, "no_bgg_id"), dry_run?)
  end

  defp process_row(row, items_by_bgg_id, credentials, dry_run?) do
    case Map.fetch(items_by_bgg_id, row.bgg_id) do
      :error ->
        upsert_or_log(base_attrs(row, "bgg_missing"), dry_run?)

      {:ok, item} ->
        process_enriched_row(row, item, credentials, dry_run?)
    end
  end

  defp process_enriched_row(row, item, _credentials, true = _dry_run?) do
    Mix.shell().info(inspect(item, pretty: true, limit: :infinity))
    Mix.shell().info("[dry-run] would upsert csv_row=#{row.row_number} bgg_id=#{row.bgg_id}")
  end

  defp process_enriched_row(row, item, credentials, false = _dry_run?) do
    attrs =
      row
      |> base_attrs("enriched")
      |> enrich_attrs(item)
      |> Map.merge(image_urls(item, row.bgg_id, credentials))

    Catalog.upsert_game!(attrs)
  end

  defp base_attrs(row, status) do
    %{
      name: row.name,
      csv_row: row.row_number,
      bgg_id: row.bgg_id,
      units: row.units,
      enrichment_status: status
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

  defp image_urls(%{image: image_url}, bgg_id, credentials) when is_binary(image_url) and image_url != "" do
    case ImagePipeline.process(image_url, "games/#{bgg_id}", credentials) do
      {:ok, urls} ->
        urls

      {:error, reason} ->
        Mix.shell().error("Image pipeline failed for BGG id #{bgg_id}: #{inspect(reason)}")
        %{}
    end
  end

  defp image_urls(_item, _bgg_id, _credentials), do: %{}

  defp upsert_or_log(attrs, true), do: Mix.shell().info("[dry-run] #{inspect(attrs)}")
  defp upsert_or_log(attrs, false), do: Catalog.upsert_game!(attrs)
end
