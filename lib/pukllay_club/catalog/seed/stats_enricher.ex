defmodule PukllayClub.Catalog.Seed.StatsEnricher do
  @moduledoc """
  Offline write path for D-05/D-06's BGG stats/artists re-enrichment
  (01.3-01 Task 2).

  Two public entry points:

    * `enrich_from_bgg/2` re-fetches `bgg_weight`/`bgg_rating`/`bgg_rank`/
      `artists`/`bgg_payload` from BGG's live API for every game with a
      `bgg_id`, batched through `BggClient.fetch_batch/2` (which already
      retries `429`/`5xx` responses with backoff — this module adds no new
      retry logic).
    * `backfill_artists_from_payload/1` fills `artists` from data already
      sitting in each game's stored `bgg_payload`, with no BGG network call
      at all.

  Both write through a narrow `Ecto.Changeset.cast/3` allowlist and
  `Repo.update/1` directly — never the full-row-upsert helper in
  `PukllayClub.Catalog`, which expects and overwrites the entire row shape.
  Neither function touches `cover_url`, `thumbnail_url`, `gallery_urls`,
  `description`, `name` or `csv_row` — this module is deliberately narrower
  than `mix catalog.seed`, which unconditionally drives the R2 image
  pipeline for every row (01.3-RESEARCH.md, Alternatives Considered).
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Repo

  @default_batch_size 20
  @default_delay_ms 1500

  @doc """
  Re-fetches BGG stats for every `Game` with a non-nil `bgg_id`.

  Options:
    * `:limit` — cap the number of candidate games, ordered by `id` for a
      stable resumable order (integer, default `nil` = all candidates)
    * `:dry_run` — perform the fetch but write nothing (default `false`)
    * `:batch_size` — games per BGG batch request (default `#{@default_batch_size}`)
    * `:delay_ms` — sleep between batches, in ms (default `#{@default_delay_ms}`)

  Returns a summary map with `:candidates`, `:fetched`, `:updated`,
  `:missing_from_bgg` (bgg_ids requested but absent from the response),
  `:unranked` (bgg_ids whose rank came back nil) and `:failed_batches`
  (a list of `{ids, reason}`). A failed batch is recorded here and
  processing continues — a single bad batch never aborts the run.
  """
  @spec enrich_from_bgg(Credentials.t(), keyword()) :: map()
  def enrich_from_bgg(%Credentials{} = credentials, opts \\ []) do
    limit = Keyword.get(opts, :limit)
    dry_run? = Keyword.get(opts, :dry_run, false)
    batch_size = Keyword.get(opts, :batch_size, @default_batch_size)
    delay_ms = Keyword.get(opts, :delay_ms, @default_delay_ms)

    games = candidate_games(limit)

    summary = %{
      candidates: length(games),
      fetched: 0,
      updated: 0,
      missing_from_bgg: [],
      unranked: [],
      failed_batches: []
    }

    games
    |> Enum.chunk_every(batch_size)
    |> Enum.with_index()
    |> Enum.reduce(summary, fn {batch, index}, acc ->
      if index > 0, do: Process.sleep(delay_ms)
      process_batch(batch, credentials, dry_run?, acc)
    end)
  end

  @doc """
  Fills `artists` from the `"artists"` entry already stored in each game's
  `bgg_payload` (string-keyed — the column is jsonb), deduplicated via
  `BggClient.dedup_artists/1` — the same rule the extraction layer applies,
  never a local reimplementation. Makes no HTTP call whatsoever; this is
  what makes the artists column correct even for a game a later BGG
  re-enrichment run fails on.

  Options:
    * `:dry_run` — scan and report without writing (default `false`)

  Returns a summary map with `:scanned`, `:updated` and `:deduplicated`
  (rows whose raw entry count exceeded its unique count).
  """
  @spec backfill_artists_from_payload(keyword()) :: map()
  def backfill_artists_from_payload(opts \\ []) do
    dry_run? = Keyword.get(opts, :dry_run, false)

    games = Repo.all(from g in Game, where: not is_nil(g.bgg_payload), order_by: g.id)

    Enum.reduce(games, %{scanned: 0, updated: 0, deduplicated: 0}, fn game, acc ->
      apply_artists_backfill(game, dry_run?, acc)
    end)
  end

  defp candidate_games(limit) do
    query = from g in Game, where: not is_nil(g.bgg_id), order_by: g.id
    query = if limit, do: limit(query, ^limit), else: query
    Repo.all(query)
  end

  defp process_batch(games, credentials, dry_run?, acc) do
    ids = Enum.map(games, & &1.bgg_id)

    case BggClient.fetch_batch(ids, credentials) do
      {:ok, items} ->
        items_by_bgg_id = Map.new(items, &{&1.bgg_id, &1})
        acc = %{acc | fetched: acc.fetched + length(items)}
        Enum.reduce(games, acc, &apply_item(&1, items_by_bgg_id, dry_run?, &2))

      {:error, reason} ->
        %{acc | failed_batches: acc.failed_batches ++ [{ids, reason}]}
    end
  end

  defp apply_item(game, items_by_bgg_id, dry_run?, acc) do
    case Map.fetch(items_by_bgg_id, game.bgg_id) do
      :error ->
        %{acc | missing_from_bgg: acc.missing_from_bgg ++ [game.bgg_id]}

      {:ok, item} ->
        if !dry_run?, do: update_game_stats(game, item)

        acc = %{acc | updated: acc.updated + 1}
        if is_nil(item.rank), do: %{acc | unranked: acc.unranked ++ [game.bgg_id]}, else: acc
    end
  end

  defp update_game_stats(game, item) do
    attrs = %{
      bgg_weight: item.average_weight,
      bgg_rating: item.average_rating,
      bgg_rank: item.rank,
      artists: item.artists,
      bgg_payload: item
    }

    game
    |> Ecto.Changeset.cast(attrs, [:bgg_weight, :bgg_rating, :bgg_rank, :artists, :bgg_payload])
    |> Repo.update()
  end

  defp apply_artists_backfill(game, dry_run?, acc) do
    raw = List.wrap(Map.get(game.bgg_payload || %{}, "artists"))
    deduped = BggClient.dedup_artists(raw)

    if !dry_run? do
      game
      |> Ecto.Changeset.cast(%{artists: deduped}, [:artists])
      |> Repo.update()
    end

    %{
      acc
      | scanned: acc.scanned + 1,
        updated: acc.updated + 1,
        deduplicated: acc.deduplicated + if(length(raw) > length(deduped), do: 1, else: 0)
    }
  end
end
