defmodule PukllayClub.Catalog.Seed.GalleryBackfill do
  @moduledoc """
  Offline write path that clears `games.gallery_urls` across every
  already-seeded game whose gallery still holds stale entries (D-07,
  phase 01.3.1).

  A sibling of `PukllayClub.Catalog.Seed.StatsEnricher`, not a function
  added to it: `StatsEnricher`'s own `@moduledoc` states in writing that
  neither of its functions touches `gallery_urls`, and
  `stats_enricher_test.exs` asserts that invariant directly — adding a
  gallery writer there would make the module lie about itself.

  This job performs no network I/O and no R2 write, and is safe to re-run:
  a game whose `gallery_urls` is already `[]` is never selected as a
  candidate, so a second run against an already-corrected catalog reports
  zero scanned and zero updated. It cannot collide with the R2
  head-check-and-skip plus one-year immutable `Cache-Control` behaviour
  that would otherwise silently defeat a job trying to replace an existing
  gallery object's content, because it never talks to R2 at all —
  `games.bgg_payload["versions"]` retains every source URL the old gallery
  was built from, so the column is fully recomputable without a BGG
  refetch if a future phase needs it.
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  @doc """
  Clears `gallery_urls` for every `Game` row that still carries a non-empty
  gallery.

  Options:
    * `:dry_run` — scan and report without writing (default `false`)

  Returns a summary map with `:scanned` and `:updated`.
  """
  @spec run(keyword()) :: map()
  def run(opts \\ []) do
    dry_run? = Keyword.get(opts, :dry_run, false)

    games =
      Repo.all(
        from g in Game,
          where: fragment("cardinality(?) > 0", g.gallery_urls),
          order_by: g.id
      )

    Enum.reduce(games, %{scanned: 0, updated: 0}, fn game, acc ->
      apply_gallery_backfill(game, dry_run?, acc)
    end)
  end

  defp apply_gallery_backfill(game, dry_run?, acc) do
    if !dry_run? do
      game
      |> Ecto.Changeset.cast(%{gallery_urls: []}, [:gallery_urls])
      |> Repo.update()
    end

    %{acc | scanned: acc.scanned + 1, updated: acc.updated + 1}
  end
end
