defmodule PukllayClub.Catalog.Enrichment do
  @moduledoc """
  Pure BGG-item-to-attrs mapping (`attrs_from_bgg_item/1`) and the per-game
  background enrichment pipeline (`enrich/2`) a staff-added draft goes
  through (D-01, D-02, D-05, D-06, 01.8.1-06).

  Reuses the existing seed pipeline modules unchanged — `BggClient.fetch_batch/2`,
  `DescriptionNormalizer.clean/1`, `ImagePipeline.select_cover/1` + `process/3`
  + `process_gallery/3` + `og_card/1`, `Storage.impl().put/4`, and
  `DescriptionTranslator.translate/3` — rather than re-implementing any of
  them.

  Enforces D-07's club-owned-value rules so re-running enrichment (a retry,
  or a future manual re-enrich) never overwrites staff edits: the BGG name
  only replaces the `Juego #<bgg_id>` placeholder, and the description is
  only filled when the current value is nil/blank (translated to Spanish
  when possible, the cleaned English text otherwise).

  An image-processing failure returns an error BEFORE anything is written —
  the whole record retries on the next Oban attempt, never a partial-field
  write (UI-SPEC E2 partial). The OG card is generated and uploaded only
  AFTER the row update succeeds with a cover — a failure there also returns
  an error so the job retries, since `Storage.impl().put/4` is idempotent
  (head-checks the target key first) and a re-run of the whole pipeline is
  cheap and safe.
  """

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.OgCard
  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.DescriptionNormalizer
  alias PukllayClub.Catalog.Seed.DescriptionTranslator
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.Storage
  alias PukllayClub.Repo

  require Logger

  @placeholder_prefix "Juego #"

  @doc """
  Maps a single `BggClient.fetch_batch/2` item map to
  `Game.enrichment_changeset/2`'s BGG-derived attrs. `categories` become
  `themes`; `average_weight`/`average_rating`/`rank` become
  `bgg_weight`/`bgg_rating`/`bgg_rank`; `description` is decoded via
  `DescriptionNormalizer.clean/1`. The raw item is stored verbatim as
  `bgg_payload`, same convention as `StatsEnricher.update_game_stats/2`.
  Never includes `:name`, `:thumbnail_url`, `:cover_url`, or `:gallery_urls`
  — the caller (`enrich/2`) adds those only when the club-owned-value rules
  and the image pipeline result allow it.
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
  Runs one game's enrichment: fetches its BGG facts, downloads/uploads its
  cover images, applies the D-07 club-owned-value rules (translating the
  description to Spanish when it is being filled), persists through
  `Game.enrichment_changeset/2`, and — only once the row carries a cover —
  generates and uploads the 1200x630 OG card.

  Returns `{:ok, game}` on success, `{:error, :bgg_missing}` when BGG
  returns no item for this `bgg_id`, `{:error, {:image, reason}}` when
  cover download/upload fails, or `{:error, reason}` for any other fetch,
  update, or OG card failure.
  """
  @spec enrich(Game.t(), Credentials.t()) :: {:ok, Game.t()} | {:error, term()}
  def enrich(%Game{bgg_id: bgg_id} = game, %Credentials{} = credentials) do
    with {:ok, [item]} <- fetch_one(bgg_id, credentials),
         {:ok, attrs} <- build_attrs(item, game, bgg_id, credentials),
         {:ok, updated_game} <- persist(game, attrs) do
      maybe_generate_og_card(updated_game, credentials)
    end
  end

  defp fetch_one(bgg_id, credentials) do
    case BggClient.fetch_batch([bgg_id], credentials) do
      {:ok, []} -> {:error, :bgg_missing}
      {:ok, [_item]} = ok -> ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_attrs(item, game, bgg_id, credentials) do
    with {:ok, image_attrs} <- image_attrs(item, bgg_id, credentials) do
      attrs =
        item
        |> attrs_from_bgg_item()
        |> Map.merge(image_attrs)
        |> maybe_put_name(game, item)
        |> maybe_put_is_expansion(game, item)
        |> maybe_translate_description(game, credentials)
        |> Map.put(:enrichment_status, "enriched")

      {:ok, attrs}
    end
  end

  # D-02/D-05: images, OG card and translation reuse the seed pipeline
  # unchanged. `select_cover/1` prefers the Spanish-edition version image,
  # falling back to the item's own primary image (ImagePipeline's own
  # doc). No BGG image at all is not an error — it merges an empty
  # gallery and leaves thumbnail/cover unset.
  defp image_attrs(item, bgg_id, credentials) do
    case ImagePipeline.select_cover(item) do
      {:ok, url, _source} ->
        with {:ok, %{thumbnail_url: thumbnail_url, cover_url: cover_url}} <-
               ImagePipeline.process(url, "games/#{bgg_id}", credentials),
             {:ok, gallery_urls} <- ImagePipeline.process_gallery(item, "games/#{bgg_id}", credentials) do
          {:ok, %{thumbnail_url: thumbnail_url, cover_url: cover_url, gallery_urls: gallery_urls}}
        else
          {:error, reason} -> {:error, {:image, reason}}
        end

      {:error, :no_image} ->
        {:ok, %{gallery_urls: []}}
    end
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

  # D-01/D-07, 01.8.1-08: `is_expansion` only ever comes from BGG on that
  # SAME still-placeholder first enrichment that also accepts the BGG
  # name — a game staff has already touched (renamed, or a later
  # re-enrichment) never has this club-owned field overwritten.
  defp maybe_put_is_expansion(attrs, %Game{bgg_id: bgg_id, name: name}, item) do
    if name == placeholder_name(bgg_id) do
      Map.put(attrs, :is_expansion, item.type == "boardgameexpansion")
    else
      attrs
    end
  end

  # D-06/D-07: the description only fills a blank/nil value — a
  # staff-edited or already-enriched description is never overwritten by a
  # retry. When it IS being filled, translate the cleaned English text to
  # Spanish (D-06); a translation failure or missing Gemini key keeps the
  # cleaned English text rather than failing the whole enrichment.
  defp maybe_translate_description(attrs, %Game{description: description}, credentials) do
    if blank?(description) do
      case Map.get(attrs, :description) do
        english_text when is_binary(english_text) -> maybe_replace_with_translation(attrs, english_text, credentials)
        _no_english_text -> attrs
      end
    else
      Map.delete(attrs, :description)
    end
  end

  defp maybe_replace_with_translation(attrs, _english_text, %Credentials{gemini_api_key: nil}) do
    Logger.warning("Enrichment: skipping description translation, GEMINI_API_KEY is not configured")
    attrs
  end

  defp maybe_replace_with_translation(attrs, english_text, %Credentials{} = credentials) do
    case DescriptionTranslator.translate(english_text, credentials, call: translate_call()) do
      {:ok, spanish_text} ->
        Map.put(attrs, :description, spanish_text)

      {:error, reason} ->
        Logger.warning("Enrichment: description translation failed, keeping English text: #{inspect(reason)}")
        attrs
    end
  end

  # Test seam (Task 2's read_first: description_translator_test.exs's `:call`
  # injection pattern) — defaults to the real Gemini call.
  defp translate_call do
    Application.get_env(:pukllay_club, :enrichment_translate_call, &InstructorLite.instruct/2)
  end

  defp persist(game, attrs) do
    game
    |> Game.enrichment_changeset(attrs)
    |> Repo.update()
  end

  # D-05/D-08: exactly the same call sequence as `OGCardBackfill.generate_and_upload/3`
  # — letterbox the just-stored cover, upload it to the derived object key.
  # A game with no cover (BGG had none) skips this step entirely; `OgCard`
  # never guesses a key.
  defp maybe_generate_og_card(%Game{cover_url: nil} = game, _credentials), do: {:ok, game}

  defp maybe_generate_og_card(%Game{} = game, credentials) do
    case OgCard.object_key_for(game) do
      nil ->
        {:ok, game}

      key ->
        with {:ok, binary} <- ImagePipeline.og_card(game.cover_url),
             {:ok, _url} <- Storage.impl().put(credentials, key, binary, content_type: "image/webp") do
          {:ok, game}
        end
    end
  end

  defp placeholder_name(bgg_id), do: "#{@placeholder_prefix}#{bgg_id}"

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
end
