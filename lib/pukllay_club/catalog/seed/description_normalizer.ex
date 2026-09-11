defmodule PukllayClub.Catalog.Seed.DescriptionNormalizer do
  @moduledoc """
  Decodes the named HTML character-reference escapes actually found in this
  project's stored `games.description` data (D-02), at seed time — following
  `hashtag_normalizer.ex`'s plain-module, no-struct-no-process convention.

  `01.3-RESEARCH.md` Common Pitfall 1 found, via a direct query against
  `pukllay_club_dev` on 2026-08-29, that `01.3-CONTEXT.md`'s originally
  assumed noise pattern — literal line-break entities and `[b]`/`[i]`
  BBCode-style tags — is entirely absent from all 385 stored descriptions.
  The real noise is 30 distinct named HTML entities (`&mdash;`, `&rsquo;`,
  `&eacute;`, `&ntilde;`, ...) across 261/385 (68%) of them. Both
  originally-assumed patterns are therefore deliberately NOT handled here.

  Decoding is a single regex pass over the whole matched set, not a chain
  of sequential `String.replace/3` calls. A single pass matters for
  correctness, not tidiness: sequential replacement makes the ampersand
  case order-dependent and can double-decode (an already-decoded `&`
  re-entering a second round of entity matching), while one pass over a
  pattern matching `&`, one-or-more ASCII letters, and `;` cannot.
  """

  # Confirmed present in this project's own data (30 names, verified by
  # direct query against pukllay_club_dev, 2026-08-29) plus `amp`. `amp` is
  # absent from the current data but would arrive on any future re-seed —
  # the single-pass design makes it safe to include as a 31st entry.
  @entities %{
    "aacute" => "á",
    "Aacute" => "Á",
    "agrave" => "à",
    "auml" => "ä",
    "bull" => "•",
    "eacute" => "é",
    "egrave" => "è",
    "hellip" => "…",
    "iacute" => "í",
    "iexcl" => "¡",
    "iquest" => "¿",
    "iuml" => "ï",
    "ldquo" => "“",
    "mdash" => "—",
    # Non-breaking space -> ordinary space: a non-breaking space in stored
    # prose serves no purpose here and complicates search indexing.
    "nbsp" => " ",
    "ndash" => "–",
    "ntilde" => "ñ",
    "oacute" => "ó",
    "ocirc" => "ô",
    "ouml" => "ö",
    "pound" => "£",
    "rdquo" => "”",
    "rsquo" => "’",
    # Soft hyphen -> empty string: an invisible line-break hint that only
    # produces stray characters when the text is re-wrapped by CSS.
    "shy" => "",
    "szlig" => "ß",
    # Thin space -> ordinary space, same rationale as nbsp above.
    "thinsp" => " ",
    "times" => "×",
    "uacute" => "ú",
    "ucirc" => "û",
    "uuml" => "ü",
    "amp" => "&"
  }

  @escape_pattern ~r/&([a-zA-Z]+);/

  @doc """
  Decodes every confirmed named HTML entity in `text` in a single regex
  pass, leaving any unrecognized `&name;`-shaped sequence untouched. `nil`
  in, `nil` out; a string with no matching escapes is returned unchanged.
  """
  @spec clean(String.t() | nil) :: String.t() | nil
  def clean(nil), do: nil

  def clean(text) when is_binary(text) do
    Regex.replace(@escape_pattern, text, fn full, name -> Map.get(@entities, name, full) end)
  end

  @doc """
  Returns every `&name;`-shaped sequence found in `text` whose name is not
  covered by the mapping `clean/1` decodes — the mechanism by which a
  future BGG change surfaces as a report line instead of a silent
  mangling. `nil` and escape-free text both return `[]`.
  """
  @spec unknown_escapes(String.t() | nil) :: [String.t()]
  def unknown_escapes(text) do
    (text || "")
    |> then(&Regex.scan(@escape_pattern, &1))
    |> Enum.map(fn [_full, name] -> name end)
    |> Enum.reject(&Map.has_key?(@entities, &1))
    |> Enum.uniq()
  end

  @doc """
  The raw entity-name -> character mapping this module decodes, exposed so
  callers (and this module's own test suite) can build coverage
  assertions directly from the mapping — mirroring `hashtag_normalizer.ex`'s
  `weight_columns/0` accessor pattern — rather than duplicating the 30-name
  list by hand.
  """
  @spec known_entities() :: %{String.t() => String.t()}
  def known_entities, do: @entities
end
