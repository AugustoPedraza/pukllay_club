defmodule PukllayClub.Catalog.Slug do
  @moduledoc """
  Derives a URL slug from a `PukllayClub.Catalog.Game`'s `name`, at render
  time — never stored on the schema (`.planning/notes/game-url-slug-format.md`:
  id-prefix chosen over a bare stored slug specifically so a later rename
  self-heals via a 301, with no slug-history table to maintain).

  Stdlib only, no new dependency: NFD-decomposes the string (splitting an
  accented letter into its base letter plus a combining mark), strips every
  Unicode combining mark, drops apostrophes (both ASCII `'` and the
  typographic `’`) rather than treating them as a word boundary — so
  "Wonderland's" becomes "wonderlands", not "wonderland-s" — downcases, then
  collapses every run of characters outside `[a-z0-9]` into a single dash
  and caps the result at 60 characters (this cap is applied BEFORE
  trimming, so a cut landing exactly on a dash never leaves a trailing one
  — see `slugify/1`).

  A character with no NFD decomposition (e.g. `ß`, `Æ`) simply falls outside
  `[a-z0-9]` and becomes a separator like any other punctuation — that is an
  accepted, documented limitation, not a bug to special-case.
  """

  @max_length 60
  @combining_marks ~r/\p{Mn}/u
  @non_slug_run ~r/[^a-z0-9]+/
  @apostrophes ["'", "’"]

  @doc """
  Converts `name` to a URL-safe slug. Returns `""` for `nil`, an empty
  string, or a name with no letters/digits (e.g. `"!!!"`).
  """
  @spec slugify(String.t() | nil) :: String.t()
  def slugify(nil), do: ""

  def slugify(name) when is_binary(name) do
    slug =
      name
      |> :unicode.characters_to_nfd_binary()
      |> strip_combining_marks()
      |> strip_apostrophes()
      |> String.downcase()
      |> collapse_non_slug_runs()
      # Cap BEFORE trimming: cutting a 60+-char slug can land exactly on a
      # dash (the separator between two words), and trimming only after the
      # cut is what guarantees the result never ends in a dash.
      |> String.slice(0, @max_length)

    String.trim(slug, "-")
  end

  defp strip_combining_marks(string), do: Regex.replace(@combining_marks, string, "")

  defp strip_apostrophes(string) do
    Enum.reduce(@apostrophes, string, fn apostrophe, acc -> String.replace(acc, apostrophe, "") end)
  end

  defp collapse_non_slug_runs(string), do: Regex.replace(@non_slug_run, string, "-")
end
