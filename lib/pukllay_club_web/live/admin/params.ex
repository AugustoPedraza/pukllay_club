defmodule PukllayClubWeb.Admin.Params do
  @moduledoc """
  The shared, range-checked guard for untrusted integer params on the
  admin LiveViews (01.8.4, CTX-04). The ROADMAP makes this the pattern
  every later phase's new events follow: a `phx-value-*` string or a
  `JS.push(..., value: ...)` number is parsed here with an explicit range
  before it is allowed anywhere near a query.

  It exists to prevent two crash modes, both reproduced by running them:

    * an id above Postgres' bigint maximum reaching Postgrex, which raises
      `DBConnection.EncodeError` and kills the LiveView process; and
    * an unknown but in-range id reaching a foreign-key constraint, which
      raises `Ecto.ConstraintError`.

  The first is closed here (`bigint_range/0`); the second is closed by the
  context's own existence check.

  Unlike `PukllayClubWeb.CatalogFilters.parse_int/1`, a binary is accepted
  only as a strict `{int, ""}` parse: no trailing junk (`"1abc"`), no
  exponent (`"1e3"`), no fraction (`"1.0"`), no leading whitespace.
  """

  @max_bigint 9_223_372_036_854_775_807

  @doc """
  Parses `raw` as an integer inside `range`.

  Accepts an already-decoded integer (LiveView's `JS.push(..., value: ...)`
  delivers JSON numbers) or a binary. Returns `{:ok, integer}`, or `:error`
  for anything else — `nil`, `""`, a list, a map, a float — and for any
  value outside `range`.
  """
  @spec parse_int(term(), Range.t()) :: {:ok, integer()} | :error
  def parse_int(raw, range) when is_integer(raw), do: check_range(raw, range)

  def parse_int(raw, range) when is_binary(raw) do
    case Integer.parse(raw) do
      {int, ""} -> check_range(int, range)
      _not_a_strict_integer -> :error
    end
  end

  def parse_int(_raw, _range), do: :error

  @doc "Postgres' positive bigint range — the range a game id must fall inside."
  @spec bigint_range() :: Range.t()
  def bigint_range, do: 1..@max_bigint

  defp check_range(int, range) do
    if int in range, do: {:ok, int}, else: :error
  end
end
