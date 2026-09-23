defmodule PukllayClub.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.StatsEnricher

  require Logger

  @app :pukllay_club

  # Registered process names a live node must have for `enrich_bgg_stats/1`
  # to run safely (F1-F4, quick task 260922-veq): the app Repo (so writes
  # land) and Req's HTTP pool (so BGG requests can even be attempted). Both
  # are started by `PukllayClub.Application`'s supervision tree, which an
  # `eval` node never boots — only an `rpc` node does.
  @required_processes [PukllayClub.Repo, Req.Finch]

  def createdb do
    load_app()

    for repo <- repos() do
      case ensure_repo_created(repo) do
        :ok -> :ok
        {:error, term} -> raise "failed to create storage for #{inspect(repo)}: #{inspect(term)}"
      end
    end
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Creates the club owner account (D-32) from a release shell, over SSH:

      bin/pukllay_club eval 'PukllayClub.Release.create_owner("owner@example.com")'

  Delegates to `PukllayClub.Accounts.create_owner/1` inside
  `Ecto.Migrator.with_repo/2` (the same wrapper `migrate/0` already uses)
  since a release has no running application supervision tree by default.
  Prints a confirmation on success, or the changeset errors on failure, and
  returns the underlying `Accounts.create_owner/1` result.
  """
  def create_owner(email) do
    load_app()

    {:ok, result, _} =
      Ecto.Migrator.with_repo(PukllayClub.Repo, fn _repo ->
        PukllayClub.Accounts.create_owner(email)
      end)

    case result do
      {:ok, user} -> IO.puts("Owner creado: #{user.email}")
      {:error, changeset} -> IO.puts("No se pudo crear el owner: #{inspect(changeset.errors)}")
    end

    result
  end

  @doc false
  @spec required_processes() :: [atom()]
  def required_processes, do: @required_processes

  @doc false
  @spec ensure_live_node!([atom()]) :: :ok
  def ensure_live_node!(process_names \\ required_processes()) do
    missing = Enum.filter(process_names, &(Process.whereis(&1) == nil))

    if missing == [] do
      :ok
    else
      raise """
      Missing required process(es): #{Enum.map_join(missing, ", ", &inspect/1)}.

      This entry point must be invoked through the release's `rpc` command against \
      the running node (e.g. `bin/pukllay_club rpc '...'`), never through `eval`. An \
      `eval` node starts no supervision tree, so Req's HTTP pool (`Req.Finch`) does \
      not exist there and every BGG request would fail.
      """
    end
  end

  @doc """
  Re-fetches BGG stats/publishers/artists for every game with a `bgg_id`
  and repairs the `boardgameversion`-contaminated `publishers`/`artists`
  columns (quick task 260922-tum's xpath-scoping fix). Delegates entirely
  to `PukllayClub.Catalog.Seed.StatsEnricher.enrich_from_bgg/2` — no second
  implementation of the enrichment lives here.

      # dry run (no writes)
      bin/pukllay_club rpc 'PukllayClub.Release.enrich_bgg_stats(dry_run: true)'

      # live run
      bin/pukllay_club rpc 'PukllayClub.Release.enrich_bgg_stats()'

  Must be invoked via `rpc`, never `eval` — see `ensure_live_node!/1`. Takes
  ~60-90s for the full ~400-game catalog (about 20 batches of 20 at the
  enricher's 1500ms default spacing); there is no caller-side `rpc` timeout
  (`:erpc.call/4`'s 4-arity form defaults to `:infinity`), so the operator's
  session can safely stay in the foreground for the whole run.

  Deliberately carries no `:limit` batching, offset paging or resumability:
  the whole catalog fits in one ~90s pass, and the enricher's candidate
  query has no offset and orders by id, so a `:limit` "next batch" option
  would only re-process the same head rows every time.

  Accepts `:limit`, `:dry_run`, `:batch_size` and `:delay_ms` — passed
  through to `StatsEnricher.enrich_from_bgg/2` unchanged (any other key is
  dropped). Prints one JSON line to stdout (the release `rpc` command
  discards return values — see `ensure_live_node!/1`'s doc) and emits the
  same payload via `Logger.info` (so `kamal app logs` and Sentry hold a
  copy). Writes no file anywhere. Returns the raw summary map.
  """
  @spec enrich_bgg_stats(keyword()) :: map()
  def enrich_bgg_stats(opts \\ []) do
    :ok = ensure_live_node!()

    credentials = Credentials.fetch!()
    dry_run? = Keyword.get(opts, :dry_run, false)

    Logger.info("BGG stats enrichment starting: #{inspect(Credentials.redacted(credentials))}")

    enrich_opts = Keyword.take(opts, [:limit, :dry_run, :batch_size, :delay_ms])
    summary = StatsEnricher.enrich_from_bgg(credentials, enrich_opts)

    publish_enrichment_summary(summary, dry_run?)

    summary
  end

  defp publish_enrichment_summary(summary, dry_run?) do
    payload = %{
      run_at: DateTime.to_iso8601(DateTime.utc_now()),
      dry_run: dry_run?,
      candidates: summary.candidates,
      fetched: summary.fetched,
      updated: summary.updated,
      missing_from_bgg: summary.missing_from_bgg,
      unranked: summary.unranked,
      failed_batches: Enum.map(summary.failed_batches, &failed_batch_to_map/1)
    }

    json = Jason.encode!(payload)
    IO.puts(json)
    Logger.info(json)
    :ok
  end

  defp failed_batch_to_map({ids, reason}), do: %{ids: ids, reason: inspect(reason)}

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end

  defp ensure_repo_created(repo) do
    case repo.__adapter__().storage_up(repo.config()) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, term} -> {:error, term}
    end
  end
end
