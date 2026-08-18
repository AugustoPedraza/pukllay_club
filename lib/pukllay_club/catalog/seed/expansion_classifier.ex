defmodule PukllayClub.Catalog.Seed.ExpansionClassifier do
  @moduledoc """
  Classifies a CSV row as an expansion/promo, not a base game (G-01-5).

  RED stub — real implementation lands in the immediately-following commit.
  """

  @doc """
  Returns `true` if `name` (at `csv_row`) should be classified as an
  expansion/promo rather than a base game.
  """
  @spec expansion?(String.t() | nil, integer()) :: boolean()
  def expansion?(_name, _csv_row), do: false
end
