defmodule PukllayClub.Catalog.Enrichment do
  @moduledoc """
  Pure BGG-item-to-attrs mapping (`attrs_from_bgg_item/1`) and the per-game
  background enrichment pipeline (`enrich/2`) a staff-added draft goes
  through (D-01, D-02, 01.8.1-06).

  Reuses the existing seed pipeline modules — `BggClient.fetch_batch/2` and
  `DescriptionNormalizer.clean/1` — rather than re-implementing BGG
  fetching or description cleanup. Images, the OG card, and Spanish
  translation are added on top of this in a later plan.

  Enforces D-07's club-owned-value rules so re-running enrichment (a retry,
  or a future manual re-enrich) never overwrites staff edits: the BGG name
  only replaces the `Juego #<bgg_id>` placeholder, and the description is
  only filled when the current value is nil/blank.
  """

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.DescriptionNormalizer
  alias PukllayClub.Repo

  @placeholder_prefix "Juego #"

  @doc """
  Maps a single `BggClient.fetch_batch/2` item map to
  `Game.enrichment_changeset/2`'s BGG-derived attrs. `categories` become
  `themes`; `average_weight`/`average_rating`/`rank` become
  `bgg_weight`/`bgg_rating`/`bgg_rank`; `description` is decoded via
  `DescriptionNormalizer.clean/1`. The raw item is stored verbatim as
  `bgg_payload`, same convention as `StatsEnricher.update_game_stats/2`.
  Never includes `:name` — the caller (`enrich/2`) adds it only when the
  club-owned-value rules allow it.
  """
  @spec attrs_from_bgg_item(map()) :: map()
  def attrs_from_bgg_item(item) do
    %{
      year_published: item.year_published,
      min_players: item.min_players,
      max_players: item.max_players,
      min_playtime: item.min_playtime,
      max_playtime: item.max_playtime,
      playing_time: item.playing_time,
      min_age: item.min_age,
      description: DescriptionNormalizer.clean(item.description),
      bgg_weight: item.average_weight,
      bgg_rating: item.average_rating,
      bgg_rank: item.rank,
      mechanics: item.mechanics,
      themes: item.categories,
      designers: item.designers,
      artists: item.artists,
      publishers: item.publishers,
      bgg_payload: item
    }
  end

  @doc """
  Runs one game's enrichment: fetches its BGG facts, applies the D-07
  club-owned-value rules, and persists through
  `Game.enrichment_changeset/2`.

  Returns `{:ok, game}` on success, `{:error, :bgg_missing}` when BGG
  returns no item for this `bgg_id` (an empty `fetch_batch/2` result), or
  `{:error, reason}` for any other fetch or update failure.
  """
  @spec enrich(Game.t(), Credentials.t()) :: {:ok, Game.t()} | {:error, term()}
  def enrich(%Game{bgg_id: bgg_id} = game, %Credentials{} = credentials) do
    with {:ok, [item]} <- fetch_one(bgg_id, credentials) do
      attrs =
        item
        |> attrs_from_bgg_item()
        |> apply_club_owned_value_rules(game, item)
        |> Map.put(:enrichment_status, "enriched")

      game
      |> Game.enrichment_changeset(attrs)
      |> Repo.update()
    end
  end

  defp fetch_one(bgg_id, credentials) do
    case BggClient.fetch_batch([bgg_id], credentials) do
      {:ok, []} -> {:error, :bgg_missing}
      {:ok, [_item]} = ok -> ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp apply_club_owned_value_rules(attrs, game, item) do
    attrs
    |> maybe_put_name(game, item)
    |> maybe_keep_description(game)
  end

  # D-07: the BGG name only replaces the `Juego #<bgg_id>` placeholder — a
  # staff-renamed game keeps its name across re-enrichment.
  defp maybe_put_name(attrs, %Game{bgg_id: bgg_id, name: name}, item) do
    if name == placeholder_name(bgg_id) do
      Map.put(attrs, :name, item.name)
    else
      attrs
    end
  end

  # D-07: the description only fills a blank/nil value — a staff-edited or
  # already-enriched description is never overwritten by a retry.
  defp maybe_keep_description(attrs, %Game{description: description}) do
    if blank?(description) do
      attrs
    else
      Map.delete(attrs, :description)
    end
  end

  defp placeholder_name(bgg_id), do: "#{@placeholder_prefix}#{bgg_id}"

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
end
