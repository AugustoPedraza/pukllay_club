defmodule PukllayClub.Catalog.Seed.BggClient do
  @moduledoc """
  Batched, authenticated BGG `/xmlapi2/thing` client (D-01/D-17, Pitfall 1/2).

  Fetches up to #{20} ids per request (BGG's practical ~2 req/sec rate
  limit is the reason for batching, not a single-id-per-request loop), and
  retries `429`/`5xx` responses with exponential backoff. On any other
  non-200, returns `{:error, reason}` — this client never raises mid-seed,
  so one bad batch does not crash the whole `mix catalog.seed` run.

  Parses with SweetXml's `dtd: :none` option (T-01-08): the response body is
  untrusted external XML, so DTD-driven entity expansion is disabled before
  any XPath extraction runs.
  """

  import SweetXml

  alias PukllayClub.Catalog.Seed.Credentials

  @endpoint "https://boardgamegeek.com/xmlapi2/thing"
  @max_batch_size 20
  @max_attempts 3
  @base_backoff_ms 1000

  @doc """
  Fetches up to #{@max_batch_size} BGG ids in a single batched request.

  Returns `{:ok, [item_map]}` — one map per `<item>` in the response, with
  every field from 01-COVERAGE.md section 1a's INTEGRATE list — or
  `{:error, reason}` on a non-retryable failure or exhausted retries.
  """
  @spec fetch_batch([integer()], Credentials.t()) :: {:ok, [map()]} | {:error, term()}
  def fetch_batch(bgg_ids, %Credentials{} = credentials) when length(bgg_ids) <= @max_batch_size do
    ids = Enum.map_join(bgg_ids, ",", &to_string/1)
    do_request(ids, credentials, @max_attempts)
  end

  @doc """
  Req options merged into every request this client makes. Lets tests plug
  in `Req.Test` via `config :pukllay_club, :bgg_req_options, plug: {Req.Test, __MODULE__}`
  without that configuration ever reaching production.
  """
  @spec req_options() :: keyword()
  def req_options do
    Application.get_env(:pukllay_club, :bgg_req_options, [])
  end

  defp do_request(ids, credentials, attempts_left) do
    request_opts =
      Keyword.merge(
        [
          params: [id: ids, type: "boardgame", stats: 1, versions: 1],
          headers: [{"authorization", "Bearer #{credentials.bgg_api_token}"}]
        ],
        req_options()
      )

    @endpoint
    |> Req.get(request_opts)
    |> handle_response(ids, credentials, attempts_left)
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}, _ids, _credentials, _attempts_left) do
    # `dtd: :none` makes xmerl_scan `exit` (not raise) on a document that
    # attempts entity expansion (see `parse_items/1`) — this is the correct,
    # secure failure mode for T-01-08, but it still must not crash the mix
    # task mid-seed, so it is converted to an ordinary error tuple here.
    {:ok, parse_items(body)}
  catch
    :exit, reason -> {:error, {:xml_parse_failed, reason}}
  end

  defp handle_response({:ok, %Req.Response{status: status}}, ids, credentials, attempts_left)
       when status == 429 or status >= 500 do
    retry_or_give_up(ids, credentials, attempts_left, {:http, status})
  end

  defp handle_response({:ok, %Req.Response{status: status}}, _ids, _credentials, _attempts_left) do
    {:error, {:http, status}}
  end

  defp handle_response({:error, reason}, ids, credentials, attempts_left) do
    retry_or_give_up(ids, credentials, attempts_left, {:transport, reason})
  end

  defp retry_or_give_up(_ids, _credentials, 1, reason), do: {:error, reason}

  defp retry_or_give_up(ids, credentials, attempts_left, _reason) do
    backoff_ms = @base_backoff_ms * (@max_attempts - attempts_left + 1)
    Process.sleep(backoff_ms)
    do_request(ids, credentials, attempts_left - 1)
  end

  defp parse_items(xml) do
    xml
    |> parse(dtd: :none)
    |> xpath(
      # Direct children of the document root's `<items>`, not `//item` —
      # since `versions=1` was added, the response also carries nested
      # `<item type="boardgameversion">` elements inside each top-level
      # item's `<versions>`, which an unscoped `//item` search would
      # wrongly match as additional top-level games.
      ~x"/items/item"l,
      bgg_id: ~x"./@id"i,
      name: ~x".//name[@type='primary']/@value"so,
      year_published: ~x"./yearpublished/@value"io,
      min_players: ~x"./minplayers/@value"io,
      max_players: ~x"./maxplayers/@value"io,
      min_playtime: ~x"./minplaytime/@value"io,
      max_playtime: ~x"./maxplaytime/@value"io,
      playing_time: ~x"./playingtime/@value"io,
      min_age: ~x"./minage/@value"io,
      description: ~x"./description/text()"so,
      image: ~x"./image/text()"so,
      thumbnail: ~x"./thumbnail/text()"so,
      average_weight: ~x".//statistics/ratings/averageweight/@value"fo,
      average_rating: ~x".//statistics/ratings/average/@value"fo,
      rank: ~x".//statistics/ratings/ranks/rank[@name='boardgame']/@value"Io,
      mechanics: ~x".//link[@type='boardgamemechanic']/@value"sl,
      categories: ~x".//link[@type='boardgamecategory']/@value"sl,
      designers: ~x".//link[@type='boardgamedesigner']/@value"sl,
      publishers: ~x".//link[@type='boardgamepublisher']/@value"sl,
      families: ~x".//link[@type='boardgamefamily']/@value"sl,
      artists: ~x".//link[@type='boardgameartist']/@value"sl,
      versions: [
        ~x".//versions/item[@type='boardgameversion']"l,
        name: ~x"./name[@type='primary']/@value"so,
        image: ~x"./image/text()"so,
        thumbnail: ~x"./thumbnail/text()"so,
        languages: ~x"./link[@type='language']/@value"sl
      ]
    )
    |> Enum.map(&normalize_item/1)
  end

  # Single extraction-layer normalization point (D-05/D-06, 01.3-RESEARCH.md
  # Pitfall 2) — every consumer of `parse_items/1`, including the
  # already-shipped `mix catalog.seed`, inherits clean data from here rather
  # than each caller re-deriving its own rule.
  defp normalize_item(item) do
    item
    |> Map.update!(:artists, &dedup_artists/1)
    |> Map.update!(:average_weight, &zero_to_nil/1)
    |> Map.update!(:average_rating, &zero_to_nil/1)
  end

  @doc """
  Deduplicates a list of BGG artist link values, preserving first-appearance
  order.

  Public on purpose: `Mix.Tasks.Catalog.BackfillArtists` must apply this
  byte-identical rule to `artists` values already sitting in stored
  `bgg_payload` rows, so both call sites can never drift apart. 368 of the
  377 enriched games in the dev database carry duplicated artist entries
  (worst observed: 367 raw entries for 15 real names), while the sibling
  `designers` extraction — using the exact same xpath shape — has zero
  duplicates. This is a property of BGG's artist link data, not an
  xpath-scoping bug.
  """
  @spec dedup_artists(list()) :: [String.t()]
  def dedup_artists(artists) do
    artists
    |> List.wrap()
    |> Enum.uniq()
  end

  # BGG emits a numeric zero rather than omitting the element entirely when
  # it has no rating or weight recorded for a game. Elixir treats `0.0` as
  # truthy, and the detail page's render guards (`show.ex`) are plain
  # truthiness checks, so an un-normalized zero would print as a
  # fabricated-looking score ("0.0/5"). Two games already in the dev
  # database hold `bgg_weight = 0` for exactly this reason (measured
  # 2026-08-29) — a zero score is absence of data, never a measurement.
  defp zero_to_nil(+0.0), do: nil
  defp zero_to_nil(other), do: other
end
