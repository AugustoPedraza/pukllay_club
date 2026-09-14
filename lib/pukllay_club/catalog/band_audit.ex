defmodule PukllayClub.Catalog.BandAudit do
  @moduledoc """
  Staff band-review audit (D-29, D-30, 01.8.1-13, SC-5) — surfaces every
  non-retired game whose club `weight_band` disagrees with the band
  implied by its `bgg_weight`, using the single reviewed threshold
  function `PukllayClub.Catalog.Vocabulary.implied_weight_band/1`. The
  mismatch computation happens entirely in Elixir (never a second copy of
  the thresholds in SQL) — a narrow `select` pulls only the columns needed
  to compute it, then `Enum.filter/2` applies the comparison.

  A game with a `band_reviewed_band` snapshot equal to its *current*
  implied band was knowingly kept and stays out of the audit; if its
  `bgg_weight` later changes such that the implied band no longer matches
  the snapshot, it re-surfaces (D-30 drift detection).
  """

  import Ecto.Query

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClub.Repo

  @type mismatch :: %{
          id: integer(),
          name: String.t(),
          weight_band: String.t() | nil,
          bgg_weight: float(),
          band_reviewed_band: String.t() | nil
        }

  @doc """
  Every non-retired game whose `weight_band` differs from its BGG-implied
  band and was not knowingly kept at that same implied band. Excludes
  games with a `nil` `bgg_weight` (nothing to imply a band from). Returns
  narrow maps (`id`, `name`, `weight_band`, `bgg_weight`,
  `band_reviewed_band`), not full `Game` structs — that's all the audit
  screen needs to render.
  """
  @spec mismatches() :: [mismatch()]
  def mismatches do
    Game
    |> where([g], g.status != :retired)
    |> where([g], not is_nil(g.bgg_weight))
    |> select([g], %{
      id: g.id,
      name: g.name,
      weight_band: g.weight_band,
      bgg_weight: g.bgg_weight,
      band_reviewed_band: g.band_reviewed_band
    })
    |> Repo.all()
    |> Enum.filter(&mismatch?/1)
  end

  defp mismatch?(%{weight_band: band, bgg_weight: weight, band_reviewed_band: reviewed}) do
    implied = Vocabulary.implied_weight_band(weight)
    band != implied and reviewed != implied
  end

  @doc "Count of `mismatches/0` — drives the dashboard's Revisar niveles badge."
  @spec count_mismatches() :: non_neg_integer()
  def count_mismatches, do: length(mismatches())

  @doc """
  Sets `game_id`'s `weight_band` to its BGG-implied band and clears any
  prior review snapshot — the game leaves the audit because it now
  matches. Returns `{:ok, game}` / `{:error, changeset}`.
  """
  @spec correct_band(integer()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def correct_band(game_id) do
    game = Repo.get!(Game, game_id)
    implied = Vocabulary.implied_weight_band(game.bgg_weight)

    game
    |> Game.band_review_changeset(%{
      weight_band: implied,
      band_reviewed_band: nil,
      band_reviewed_at: nil
    })
    |> Repo.update()
  end

  @doc """
  Knowingly keeps `game_id`'s current `weight_band` — stores its
  BGG-implied band at review time plus a timestamp, leaving `weight_band`
  itself untouched. `mismatches/0` re-surfaces the game only if
  `bgg_weight` later implies a different band than this snapshot (D-30).
  Returns `{:ok, game}` / `{:error, changeset}`.
  """
  @spec keep_band(integer()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def keep_band(game_id) do
    game = Repo.get!(Game, game_id)
    implied = Vocabulary.implied_weight_band(game.bgg_weight)

    game
    |> Game.band_review_changeset(%{
      band_reviewed_band: implied,
      band_reviewed_at: DateTime.utc_now(:second)
    })
    |> Repo.update()
  end
end
