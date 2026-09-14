defmodule PukllayClub.Workers.EnrichGameWorker do
  @moduledoc """
  Oban worker orchestrating BGG fetch, images, the OG card, and Spanish
  translation for one staff-added draft game (D-01, D-02, 01.8.1-06).

  Runs on the `:enrichment` queue (concurrency 1, `config/config.exs` —
  bounds libvips image-processing memory on the 1 GB production host).
  `unique` on the `game_id` args key across incomplete job states so
  `Catalog.add_game_from_bgg/1` can never enqueue two enrichment jobs for
  the same game while one is already pending/scheduled/executing.

  Broadcasts `{:game_enriched, game_id}` on the `"admin:games"` PubSub
  topic after a successful enrichment, so `Admin.GameLive.Index` can
  re-fetch and re-render that game's row live without a page reload.
  """

  use Oban.Worker,
    queue: :enrichment,
    max_attempts: 3,
    unique: [fields: [:args], keys: [:game_id], states: Oban.Job.states() -- [:completed, :discarded, :cancelled]]

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Enrichment
  alias PukllayClub.Catalog.Seed.Credentials

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"game_id" => game_id}}) do
    game = Catalog.get_game!(game_id)

    case Credentials.fetch() do
      {:ok, credentials} ->
        case Enrichment.enrich(game, credentials) do
          {:ok, _updated_game} ->
            Phoenix.PubSub.broadcast(PukllayClub.PubSub, "admin:games", {:game_enriched, game_id})
            :ok

          {:error, reason} ->
            {:error, reason}
        end

      {:error, missing_env_vars} ->
        {:error, {:missing_credentials, missing_env_vars}}
    end
  end
end
