defmodule PukllayClubWeb.GameText do
  @moduledoc """
  The single generator for the D-10 catalog-cover accessible name — game
  name plus editorial — shared by every cover-rendering branch in
  `PukllayClubWeb.GameCard` and `PukllayClubWeb.GamePreview` (SEO-02). A
  plain module of pure functions, not a `Phoenix.Component`: nothing here
  renders HEEx, so both `<img alt>` attributes and `aria-label` placeholder
  `<div>`s can consume the identical string while HEEx performs the actual
  attribute escaping at render time (T-01.8-06) — this module never escapes
  its own output, since pre-escaping here would double-escape an ampersand
  or accented character already present in a game's `name`/`publishers`.

  `publishers` is `{:array, :string}`, `default: []`
  (`PukllayClub.Catalog.Game`), so `editorial_text/1` is an independent
  nil-or-value function mirroring `GamePreview.players_text/1`'s idiom —
  never a blind interpolation of the raw array, which would render Elixir's
  list-inspect syntax straight into the DOM.
  """

  alias PukllayClub.Catalog.Game

  @doc """
  The D-10 accessible name for `game`'s cover art: `"Portada de [Juego]"`
  alone when there is no publisher, or
  `"Portada de [Juego], editado por [Editorial]"` when there is at least
  one. Composes from `editorial_text/1` rather than building the whole
  sentence with a single interpolation containing an optional hole, so the
  empty-publishers case can never leave a dangling connector or trailing
  punctuation.

  Multiple publishers are joined with `", "` (e.g.
  `"editado por Devir, Asmodee"`) — this catalog's own publisher lists are
  short, so a plain comma join reads naturally without needing a
  `"y"`-conjunction special case for the final entry.
  """
  @spec cover_alt(Game.t()) :: String.t()
  def cover_alt(%Game{name: name} = game) do
    case editorial_text(game) do
      nil -> "Portada de #{name}"
      editorial -> "Portada de #{name}, #{editorial}"
    end
  end

  @doc """
  The publisher clause of `cover_alt/1`, independent so a caller composes
  rather than trims: `nil` for a game with `publishers: []` (the schema
  default — a real production path, not a theoretical one, per this
  catalog's precedent for sparse per-column coverage) or `publishers: nil`
  (the column has no `NOT NULL` constraint, so a row written outside the
  seed changeset's `validate_required/2` — e.g. a raw `Repo.insert_all`
  backfill — can legally carry a null array), otherwise `"editado por "`
  followed by every publisher joined with `", "`.
  """
  @spec editorial_text(Game.t()) :: String.t() | nil
  def editorial_text(%Game{publishers: publishers}) when publishers in [nil, []], do: nil

  def editorial_text(%Game{publishers: publishers}) do
    "editado por #{Enum.join(publishers, ", ")}"
  end
end
