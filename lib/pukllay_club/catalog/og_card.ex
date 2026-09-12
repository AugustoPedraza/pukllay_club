defmodule PukllayClub.Catalog.OgCard do
  @moduledoc """
  Names the 1200x630 og-card object every game's cover art produces, and
  derives its URL from that game's own stored `cover_url`.

  Created in phase 01.8 plan 01 (the SEO/JSON-LD reader) rather than
  alongside the batch backfill that will actually produce these objects
  (a later plan in this phase) so both the reader here and that plan's
  writer name the same object through this one module — the same
  one-source-per-fact rule `PukllayClub.Catalog.Seed.Credentials.r2_object_url/2`
  already enforces for every other stored image URL. Neither side may type
  a second `"og-card.webp"` literal.
  """

  alias PukllayClub.Catalog.Game

  @object_name "og-card.webp"
  @cover_large_suffix "cover-large.webp"

  @doc "The literal object filename every game's og-card variant is stored under."
  @spec object_name() :: String.t()
  def object_name, do: @object_name

  @doc """
  Derives `game`'s og-card URL from its stored `cover_url`, by replacing
  that URL's final `cover-large.webp` path segment with `#{@object_name}`.

  Returns `nil` when `cover_url` is `nil` or does not end in the expected
  segment — this function never guesses or fabricates a URL, since a wrong
  guess would silently produce a broken social preview that nothing else
  would detect.
  """
  @spec url_for(Game.t()) :: String.t() | nil
  def url_for(%Game{cover_url: nil}), do: nil

  def url_for(%Game{cover_url: cover_url}) do
    if String.ends_with?(cover_url, @cover_large_suffix) do
      String.replace_suffix(cover_url, @cover_large_suffix, @object_name)
    end
  end

  @doc """
  Derives the R2 object key for `game`'s og-card — the exact inverse of
  `PukllayClub.Catalog.Seed.Credentials.r2_object_url/2` — by stripping the
  configured `:pukllay_club, :image_origin` base URL prefix from the stored
  `cover_url` and replacing its final `cover-large.webp` segment with
  `#{@object_name}`.

  Returns `nil` for a game with no stored cover, or when `cover_url` does
  not start with the configured origin or end in the expected segment —
  this function never guesses at a key, since a wrong guess would silently
  write (or read) the wrong R2 object (T-01.8-15).
  """
  @spec object_key_for(Game.t()) :: String.t() | nil
  def object_key_for(%Game{cover_url: nil}), do: nil

  def object_key_for(%Game{cover_url: cover_url}) do
    with origin when is_binary(origin) and origin != "" <-
           Application.get_env(:pukllay_club, :image_origin),
         prefix = String.trim_trailing(origin, "/") <> "/",
         true <- String.starts_with?(cover_url, prefix),
         true <- String.ends_with?(cover_url, @cover_large_suffix) do
      cover_url
      |> String.replace_prefix(prefix, "")
      |> String.replace_suffix(@cover_large_suffix, @object_name)
    else
      _ -> nil
    end
  end
end
