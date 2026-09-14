defmodule PukllayClub.Workers.EnrichGameWorker do
  @moduledoc """
  Oban worker orchestrating BGG fetch, images, the OG card, and Spanish
  translation for one staff-added draft game (D-01, D-02, D-03,
  01.8.1-06/08).

  Runs on the `:enrichment` queue (concurrency 1, `config/config.exs` —
  bounds libvips image-processing memory on the 1 GB production host).
  `unique` on the `game_id` args key across incomplete job states so
  `Catalog.add_game_from_bgg/1`/`Catalog.retry_enrichment/1` can never
  enqueue two enrichment jobs for the same game while one is already
  pending/scheduled/executing.

  `backoff/1` grows linearly (`attempt * 30` seconds) rather than Oban's
  default exponential backoff, so a genuinely broken record exhausts its
  `max_attempts` (3) within minutes, not hours — staff need to see the
  `Reintentar` state promptly, not the next morning (D-03).

  A non-transient failure — BGG has no matching item, or credentials are
  missing — marks the game `"failed"` and returns `{:cancel, reason}`
  immediately: retrying cannot help either case, so Oban stops attempting
  the job right away instead of burning through `max_attempts`. Any other
  error (a transient BGG/image/translation failure) only marks the game
  `"failed"` once the CURRENT attempt is the last one allowed
  (`job.attempt >= job.max_attempts`) — an earlier attempt returns
  `{:error, reason}` and Oban retries on its own schedule, leaving the
  draft's `enrichment_status` untouched (E2 partial: the whole record
  retries, never a partial-field write).

  Broadcasts `{:game_enriched, game_id}` on the `"admin:games"` PubSub
  topic both after a successful enrichment and after marking a game
  `"failed"`, so `Admin.GameLive.Index` can re-fetch and re-render that
  game's row live without a page reload — the row moves from its loading
  skeleton straight to the `Reintentar` error state with no manual
  refresh.
  """

  use Oban.Worker,
    queue: :enrichment,
    max_attempts: 3,
    unique: [fields: [:args], keys: [:game_id], states: Oban.Job.states() -- [:completed, :discarded, :cancelled]]

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Enrichment
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Repo

  require Logger

  # D-03: linear, not exponential — exhausts max_attempts (3) within
  # minutes (30s, 60s) rather than hours, so a Reintentar-worthy failure
  # surfaces to staff promptly.
  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}), do: attempt * 30

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"game_id" => game_id}, attempt: attempt, max_attempts: max_attempts}) do
    game = Catalog.get_game!(game_id)

    case Credentials.fetch() do
      {:ok, credentials} ->
        handle_enrichment(game, credentials, attempt, max_attempts)

      {:error, missing_env_vars} ->
        reason = {:missing_credentials, missing_env_vars}
        mark_failed_and_broadcast(game, reason)
        {:cancel, reason}
    end
  end

  defp handle_enrichment(game, credentials, attempt, max_attempts) do
    case Enrichment.enrich(game, credentials) do
      {:ok, _updated_game} ->
        broadcast(game_id_of(game))
        :ok

      {:error, :bgg_missing} = _error ->
        mark_failed_and_broadcast(game, :bgg_missing)
        {:cancel, :bgg_missing}

      {:error, reason} ->
        if attempt >= max_attempts do
          mark_failed_and_broadcast(game, reason)
        end

        {:error, reason}
    end
  end

  defp game_id_of(%Game{id: id}), do: id

  defp mark_failed_and_broadcast(game, reason) do
    Logger.warning("EnrichGameWorker: marking game #{game.id} failed: #{inspect(reason)}")

    case game
         |> Game.enrichment_changeset(%{enrichment_status: "failed"})
         |> Repo.update() do
      {:ok, _updated} -> broadcast(game.id)
      {:error, _changeset} -> :ok
    end
  end

  defp broadcast(game_id) do
    Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game_id})
  end
end
