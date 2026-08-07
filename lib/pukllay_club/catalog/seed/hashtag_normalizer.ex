defmodule PukllayClub.Catalog.Seed.HashtagNormalizer do
  @moduledoc """
  Reads the club's already-applied hashtag columns from a raw `ludoteca.csv`
  row map and resolves the weight band + editorial tags the seed pipeline
  needs (D-05, D-06), while surfacing every real-data quirk the CSV audit
  found (D-16, D-17, D-20) instead of silently guessing.

  `resolve_weight_band/1` implements 01-RESEARCH.md Pitfall 3's exact
  three-branch order: a single unambiguous weight hashtag always wins over
  `Peso_BGG`, which is consulted only as a narrow tie-break for the 11
  conflict + 46 zero-hashtag rows (01-VOCABULARY.md section 2).
  """

  # Verbatim club hashtag column names -> DB `weight_band` values (D-05).
  @weight_columns %{
    "#DescubreElHobby" => "descubre_el_hobby",
    "#IngenioEstratega" => "ingenio_estratega",
    "#NivelExperto" => "nivel_experto"
  }

  # Verbatim club editorial hashtag column names, in display order (D-06).
  @editorial_columns ["#CreaConexiones", "#EquipoGanador", "#DuelosMemorables"]

  # The 4 extra CSV hashtag columns confirmed out-of-scope for Phase 1
  # (D-16) — listed explicitly so the exclusion is greppable, not an
  # omission: #InicioRápido, #GestionaTusRecursos, #DominaElTablero,
  # #ArteEnLaMesa are never read by this module.
  @ignored_columns ["#InicioRápido", "#GestionaTusRecursos", "#DominaElTablero", "#ArteEnLaMesa"]

  @doc """
  The 4 D-16 hashtag columns explicitly ignored by this module — exposed so
  callers (e.g. the seed report) can confirm the exclusion rather than
  re-deriving it.
  """
  @spec ignored_columns() :: [String.t()]
  def ignored_columns, do: @ignored_columns

  @doc """
  Trims and downcases `value`, treating `"si"`/`"sí"` as `true` and
  `nil`/`""`/`"no"` as `false`. Anything else (the observed typo cells `"n"`,
  `"s"`, `"di"`, etc.) also resolves as `false` but is returned as
  `{false, {:unrecognized, value}}` so callers can collect it for the
  manual-review report instead of silently coercing it (D-20).
  """
  @spec truthy?(String.t() | nil) :: true | false | {false, {:unrecognized, String.t()}}
  def truthy?(nil), do: false

  def truthy?(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> false
      normalized when normalized in ["si", "sí"] -> true
      "no" -> false
      _other -> {false, {:unrecognized, value}}
    end
  end

  @doc """
  Resolves the weight band for a raw CSV row map per 01-RESEARCH.md
  Pitfall 3's three-branch order:

    1. Exactly one weight hashtag true -> that band, `:hashtag` — `Peso_BGG`
       is not even read.
    2. Zero or two-or-more true -> parse `Peso_BGG` and apply the reviewed
       thresholds (01-VOCABULARY.md section 2), tagged `:peso_tie_break`.
    3. No usable `Peso_BGG` -> `{:unresolved, reason}`, `reason` distinguishing
       `:conflict` (2+ true) from `:missing` (0 true).
  """
  @spec resolve_weight_band(map()) ::
          {:ok, String.t(), :hashtag | :peso_tie_break} | {:unresolved, :conflict | :missing}
  def resolve_weight_band(row) do
    true_bands =
      for {column, band} <- @weight_columns, truthy?(Map.get(row, column)) == true, do: band

    case true_bands do
      [band] -> {:ok, band, :hashtag}
      other -> resolve_via_peso(row, other)
    end
  end

  @doc """
  Returns the true D-06 editorial hashtag strings verbatim (with the leading
  `#`), in the declaration order of the club's 3-tag vocabulary. Never
  returns any of the 4 D-16 out-of-scope hashtags, even when their cells are
  true.
  """
  @spec editorial_tags(map()) :: [String.t()]
  def editorial_tags(row) do
    for column <- @editorial_columns, truthy?(Map.get(row, column)) == true, do: column
  end

  @doc """
  Returns a `{column, value}` pair for every hashtag column — across both
  the weight and editorial sets — whose cell was non-empty and unrecognized
  (D-20). The 4 ignored D-16 columns are never inspected.
  """
  @spec unrecognized_cells(map()) :: [{String.t(), String.t()}]
  def unrecognized_cells(row) do
    columns = Map.keys(@weight_columns) ++ @editorial_columns

    for column <- columns,
        {false, {:unrecognized, value}} <- [truthy?(Map.get(row, column))] do
      {column, value}
    end
  end

  defp resolve_via_peso(row, true_bands) do
    case parse_peso(Map.get(row, "Peso_BGG")) do
      nil -> {:unresolved, unresolved_reason(true_bands)}
      peso -> {:ok, band_for_peso(peso), :peso_tie_break}
    end
  end

  defp unresolved_reason([]), do: :missing
  defp unresolved_reason(_two_or_more), do: :conflict

  # Reviewed thresholds (01-VOCABULARY.md section 2, empirically derived
  # from the 377 clean-hashtag rows' Peso_BGG distribution): below 1.9 is
  # the beginner band, 1.9 through 3.1 inclusive is the middle band, above
  # 3.1 is the expert band.
  defp band_for_peso(peso) when peso < 1.9, do: "descubre_el_hobby"
  defp band_for_peso(peso) when peso <= 3.1, do: "ingenio_estratega"
  defp band_for_peso(_peso), do: "nivel_experto"

  defp parse_peso(nil), do: nil

  defp parse_peso(value) do
    case value |> String.trim() |> String.replace(",", ".") do
      "" ->
        nil

      normalized ->
        case Float.parse(normalized) do
          {float, _rest} -> float
          :error -> nil
        end
    end
  end
end
