defmodule PukllayClub.Catalog.Seed.ExpansionClassifier do
  @moduledoc """
  Classifies a CSV row as an expansion/promo, not a base game (G-01-5).

  The club's `ludoteca.csv` export carries no dedicated expansion column —
  the only signal is a free-text marker inside the `Nombre` field, and even
  that marker is missing on 4 of the 26 confirmed expansion/promo rows. This
  module is therefore two things layered together, neither sufficient alone:

  1. A marker list of plain, lowercase substrings checked against the
     downcased name via `String.contains?/2` — deliberately NOT a regex.
     The `add_games_is_expansion` migration has to express the identical
     rule in raw SQL as a one-time backfill for existing rows (dev AND
     production, so the fix lands on the next Kamal deploy without
     re-running the BGG/R2 seed pipeline). Substring matching on a
     downcased string maps exactly onto Postgres `ILIKE '%marker%'`; a
     regex would need Postgres word-boundary syntax and Elixir
     backslash-escaping to independently agree, which is two ways for the
     Elixir and SQL rules to silently drift apart. Substring matching also
     has no backtracking/ReDoS surface (T-01-61).

  2. A reviewed-override list of 4 `csv_row` values — 414, 415, 417, 421 —
     that carry NO text marker at all. The club reviewed every zero-hashtag
     row individually in `01-UAT.md` Test 5 and confirmed these 4 (the two
     "Viajes por la Tierra Media" Lord of the Rings sub-sets, "abyss
     leviatan", and "viniculture tuscany") are expansions/promos despite
     having no marker in `Nombre`. `csv_row` is safe to key on here because
     it is the seed pipeline's stable natural key and
     `Catalog.upsert_game!/1`'s upsert conflict target (D-02/D-19) — it
     never changes across re-seeds.

  **This module and the SQL backfill in the `add_games_is_expansion`
  migration are mirrors of each other and MUST be changed together.** If
  the marker list or the override list ever changes here, the migration's
  `UPDATE ... WHERE` clause (or a follow-up migration) must change to
  match, or newly-added rows and the historical backfill will disagree.

  Origin: G-01-5 (major) — the "Recientemente añadidos" carousel row was
  showing almost exclusively expansions/promos because the club's source
  export happens to cluster every expansion/promo entry at the tail of the
  sheet (`csv_row` 410-435 of 434), and the row applied no filter at all.
  """

  # Plain lowercase substrings, matched via `String.contains?/2` against the
  # downcased `Nombre`. Kept in one attribute so this list is greppable and
  # maps one-for-one onto the migration's `ILIKE '%marker%'` literal list.
  #
  #   "(expa"   — the open-paren expansion marker, e.g. "(expa)", "(Expa)",
  #               "(expa 1)", "(expa Arquitectos)"
  #   "expansi" — the spelled-out expansion stem, deliberately truncated
  #               before the accented/unaccented divergence point so a
  #               single substring matches both "Expansion" and
  #               "Expansión" (and "Expanción", the one club typo)
  #   "promo"   — the promo marker, e.g. "Promo Miniaturas"
  @markers ["(expa", "expansi", "promo"]

  # The 4 csv_row values confirmed as expansions/promos by the club during
  # 01-UAT.md Test 5 despite carrying no text marker in `Nombre` at all:
  # the two "Viajes por la Tierra Media" Lord of the Rings sub-sets (414,
  # 415), "abyss leviatan" (417), and "viniculture tuscany" (421). csv_row
  # is the seed pipeline's stable natural key, so it is safe to hardcode.
  @reviewed_overrides [414, 415, 417, 421]

  @doc """
  Returns `true` if `name` (at `csv_row`) should be classified as an
  expansion/promo rather than a base game. Never raises on a `nil` name.
  """
  @spec expansion?(String.t() | nil, integer()) :: boolean()
  def expansion?(nil, csv_row), do: csv_row in @reviewed_overrides

  def expansion?(name, csv_row) do
    downcased = String.downcase(name)
    Enum.any?(@markers, &String.contains?(downcased, &1)) or csv_row in @reviewed_overrides
  end
end
