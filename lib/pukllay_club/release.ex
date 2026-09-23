defmodule PukllayClub.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.StatsAudit
  alias PukllayClub.Catalog.Seed.StatsEnricher

  require Logger

  @app :pukllay_club

  # Registered process names a live node must have for `enrich_bgg_stats/1`
  # to run safely (F1-F4, quick task 260922-veq): the app Repo (so writes
  # land) and Req's HTTP pool (so BGG requests can even be attempted).
  # `PukllayClub.Repo` is started either by `PukllayClub.Application`'s
  # supervision tree on a booted node, or by an explicit
  # `PukllayClub.Repo.start_link()` under `eval` (see
  # `docs/runbooks/production-bgg-reenrichment.md`). `Req.Finch` is NOT in
  # this app's children list at all — it is the default Finch pool started
  # by the `:req` application itself, via
  # `Application.ensure_all_started(:req)`. This guard inspects registered
  # process names only, so it cannot detect the invocation mode: an `eval`
  # that starts these processes itself satisfies it legitimately, and a
  # bare `eval` that started nothing still gets a clean refusal instead of
  # a half-run.
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

      Start the required processes first, in the same `eval` expression, in \
      this order:

          {:ok, _} = Application.ensure_all_started(:req)
          {:ok, _} = Application.ensure_all_started(:ecto_sql)
          {:ok, _} = PukllayClub.Repo.start_link()

      The `:ecto_sql` step is not optional: without it, \
      `PukllayClub.Repo.start_link()` fails on a missing `DBConnection.Watcher` \
      process, because `:db_connection`'s supervision tree is not running. See \
      `docs/runbooks/production-bgg-reenrichment.md` for the full, verified \
      production invocation.
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
      bin/pukllay_club eval '
      {:ok, _} = Application.ensure_all_started(:req)
      {:ok, _} = Application.ensure_all_started(:ecto_sql)
      {:ok, _} = PukllayClub.Repo.start_link()
      PukllayClub.Release.enrich_bgg_stats(dry_run: true)
      '

      # live run
      bin/pukllay_club eval '
      {:ok, _} = Application.ensure_all_started(:req)
      {:ok, _} = Application.ensure_all_started(:ecto_sql)
      {:ok, _} = PukllayClub.Repo.start_link()
      PukllayClub.Release.enrich_bgg_stats()
      '

  Must be invoked with the required processes running — see
  `ensure_live_node!/1` and `docs/runbooks/production-bgg-reenrichment.md`
  for the verified production invocation. Takes ~60-90s for the full
  ~400-game catalog (about 20 batches of 20 at the enricher's 1500ms default
  spacing) and runs to completion in the invoking node's own foreground, so
  the operator's session stays attached for the whole run.

  Deliberately carries no `:limit` batching, offset paging or resumability:
  the whole catalog fits in one ~90s pass, and the enricher's candidate
  query has no offset and orders by id, so a `:limit` "next batch" option
  would only re-process the same head rows every time.

  Accepts `:limit`, `:dry_run`, `:batch_size` and `:delay_ms` — passed
  through to `StatsEnricher.enrich_from_bgg/2` unchanged (any other key is
  dropped). Prints one JSON line to stdout — the operator reads the payload
  from there — and emits the same payload via `Logger.info`, so
  `kamal app logs` and Sentry hold a copy. Writes no file anywhere. Returns
  the raw summary map.
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

  @doc """
  Read-only before/after measurement for `enrich_bgg_stats/1` — delegates
  entirely to `PukllayClub.Catalog.Seed.StatsAudit.report/0` and performs
  no write of any kind.

      bin/pukllay_club eval '
      {:ok, _} = Application.ensure_all_started(:req)
      {:ok, _} = Application.ensure_all_started(:ecto_sql)
      {:ok, _} = PukllayClub.Repo.start_link()
      PukllayClub.Release.bgg_stats_report()
      '

  Requires only the app `Repo` to be running — narrower than
  `enrich_bgg_stats/1`'s guard, which also requires `Req.Finch`. The
  runbook's preamble starts both regardless, so the `:req` expression above
  is a harmless superset for this function; the `:ecto_sql` expression is
  still required, since `PukllayClub.Repo.start_link()` fails on a missing
  `DBConnection.Watcher` process without it.

  Prints one JSON line to stdout and emits the same payload via
  `Logger.info`, then returns the report map.
  """
  @spec bgg_stats_report() :: map()
  def bgg_stats_report do
    :ok = ensure_live_node!([PukllayClub.Repo])

    report = StatsAudit.report()

    json = Jason.encode!(report)
    IO.puts(json)
    Logger.info(json)

    report
  end

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
