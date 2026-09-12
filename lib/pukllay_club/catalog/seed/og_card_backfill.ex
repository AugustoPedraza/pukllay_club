defmodule PukllayClub.Catalog.Seed.OGCardBackfill do
  @moduledoc """
  Offline write path that letterboxes every game's already-stored cover onto
  a 1200x630 brand-coloured canvas (D-06/D-07/D-08, phase 01.8 plan 04) and
  uploads it to R2 as `<key>/og-card.webp`, alongside the existing
  `cover-thumb.webp`/`cover-large.webp` variants.

  Structurally a sibling of `PukllayClub.Catalog.Seed.GalleryBackfill` — the
  `Repo.all` loop with an explicit `order_by`, the `:dry_run` option, the
  `%{scanned:, updated:}` summary contract are all copied from there. But do
  NOT copy `GalleryBackfill`'s no-network-I/O safety assumption: that
  module's own moduledoc states in writing that it never talks to R2, which
  is exactly why it's safe to re-run without a second thought. This module
  is the opposite — it fetches a game's own stored cover from the app's R2
  public origin and writes a brand-new object back to R2 on every real
  (non-dry-run) call — so its I/O half instead mirrors `ImagePipeline.process/3`'s
  `with`-chain and `Storage.impl().put/4` call.

  Re-running this task IS still cheap and idempotent, but for a narrower
  reason than `GalleryBackfill`'s: `R2Storage.put/4` head-checks the target
  key first and returns the existing object's URL unchanged when it is
  already present, and objects are written with a one-year immutable
  `Cache-Control`. A re-run therefore never re-does work it already did, but
  it also NEVER REPLACES an existing object's content — if the letterbox
  colour or the canvas size is ever revised, the existing objects must be
  explicitly deleted first, or this module will silently keep serving the
  old ones forever (T-01.8-17, accepted).

  `Credentials` is taken as an explicit argument built once by the caller
  (the `catalog.backfill_og_cards` Mix task), never resolved from
  application environment inside this module — the same T-01-11 contract
  every seed module in this codebase follows.

  A game whose `PukllayClub.Catalog.OgCard.object_key_for/1` returns `nil`
  (no stored cover at all, or a `cover_url` that doesn't match the expected
  shape) is counted as scanned but not updated, never as a failure —
  roughly 9% of this catalog's rows carry no BGG id and therefore no stored
  cover, and plan 01's SEO module already routes those pages to the branded
  fallback image, so their absence here is the designed outcome, not a gap.
  A per-game fetch/upload failure is logged through the same shell-error
  channel `catalog.seed.ex`'s `upload_cover/5` already uses, and the batch
  continues to the next game rather than aborting — one unreadable cover
  must not abort a ~400-row batch.
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.OgCard
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.Storage
  alias PukllayClub.Repo

  @doc """
  Iterates every game in the catalog (ordered by id, so a partial run is
  resumable in a predictable order), letterboxes each one's stored cover
  into an og-card, and uploads it to R2.

  Options:
    * `:dry_run` — scan and report without fetching, transforming, or
      uploading anything (default `false`)
    * `:credentials` — a `PukllayClub.Catalog.Seed.Credentials.t()`, required
      unless `:dry_run` is `true`

  Returns a summary map with `:scanned` and `:updated`.
  """
  @spec run(keyword()) :: %{scanned: non_neg_integer(), updated: non_neg_integer()}
  def run(opts \\ []) do
    dry_run? = Keyword.get(opts, :dry_run, false)
    credentials = Keyword.get(opts, :credentials)

    games = Repo.all(from g in Game, order_by: g.id)

    Enum.reduce(games, %{scanned: 0, updated: 0}, fn game, acc ->
      apply_backfill(game, dry_run?, credentials, acc)
    end)
  end

  defp apply_backfill(game, dry_run?, credentials, acc) do
    case OgCard.object_key_for(game) do
      nil ->
        %{acc | scanned: acc.scanned + 1}

      _key when dry_run? ->
        %{acc | scanned: acc.scanned + 1}

      key ->
        case generate_and_upload(game, key, credentials) do
          {:ok, _url} ->
            %{acc | scanned: acc.scanned + 1, updated: acc.updated + 1}

          {:error, reason} ->
            Mix.shell().error("OG card backfill failed for game #{game.id}: #{inspect(reason)}")
            %{acc | scanned: acc.scanned + 1}
        end
    end
  end

  defp generate_and_upload(game, key, %Credentials{} = credentials) do
    with {:ok, binary} <- ImagePipeline.og_card(game.cover_url) do
      Storage.impl().put(credentials, key, binary, content_type: "image/webp")
    end
  end
end
