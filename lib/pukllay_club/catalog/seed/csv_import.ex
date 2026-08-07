NimbleCSV.define(PukllayClub.Catalog.Seed.CsvParser, separator: ",", escape: "\"")

defmodule PukllayClub.Catalog.Seed.CsvImport do
  @moduledoc """
  Streams the club's `ludoteca.csv` export as `{row_number, header_map}`
  tuples.

  Must use `NimbleCSV`'s streaming/quoted-aware parser, not a naive line
  split — the `Mecanicas` column contains embedded newlines inside quoted
  fields (D-16), so a naive split over-counts 434 real rows as 2817 lines.
  """

  alias PukllayClub.Catalog.Seed.CsvParser

  @default_relative_path "priv/repo/seed_data/ludoteca.csv"

  @doc """
  Returns a lazy stream of `{row_number, %{header => value}}` tuples,
  1-based over data rows (the header row itself is not emitted). Rows whose
  `Nombre` is blank are skipped (the file's one trailing artifact row). The
  7 empty trailing `Columna N` columns are trimmed from every returned map.
  """
  def stream_rows(path \\ default_path()) do
    header = header_row(path)

    path
    |> File.stream!()
    |> CsvParser.parse_stream(skip_headers: true)
    |> Stream.with_index(1)
    |> Stream.map(fn {row, row_number} -> {row_number, row_to_map(header, row)} end)
    |> Stream.reject(fn {_row_number, map} -> blank?(Map.get(map, "Nombre")) end)
  end

  @doc false
  def default_path do
    Application.app_dir(:pukllay_club, @default_relative_path)
  end

  defp header_row(path) do
    path
    |> File.stream!()
    |> CsvParser.parse_stream(skip_headers: false)
    |> Enum.take(1)
    |> List.first()
  end

  defp row_to_map(header, row) do
    header
    |> Enum.zip(row)
    |> Enum.reject(fn {key, _value} -> String.starts_with?(key, "Columna ") end)
    |> Map.new()
  end

  defp blank?(nil), do: true
  defp blank?(value), do: String.trim(value) == ""
end
