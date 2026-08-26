defmodule PukllayClubWeb.CatalogFilters do
  @moduledoc """
  The single authority for reading, validating and re-encoding catalog
  filter params (D-08). Shared by `PukllayClubWeb.CatalogLive.Index`
  (URL read path — `handle_params/3` calls `from_params/1` once per
  navigation) and `PukllayClubWeb.CatalogLive.Show` (breadcrumb target —
  `catalog_path/1` sanitises a `?from=` value carried across pages). The
  two consumers can never drift apart on which facet values are accepted
  because there is exactly one copy of each parsing rule.

  `catalog_path/1` is the security control for D-08's breadcrumb: it
  never echoes its input. It decodes the incoming value, re-validates
  every key/value through `from_params/1`'s closed Vocabulary whitelist,
  then re-encodes from scratch — so the returned string is always a
  locally-rooted `/` path built from known-good pairs. An absolute URL,
  a protocol-relative `//host`, or a `javascript:` URI is a structurally
  unreachable output, not merely a rejected input (T-01.2-01).
  """

  alias Plug.Conn.Query
  alias PukllayClub.Catalog.Vocabulary

  # 500-character bound on the incoming `?from=` value before it is ever
  # decoded (T-01.2-02) — a crafted arbitrarily-long value never reaches
  # `Plug.Conn.Query.decode/1` at full size.
  @max_from_length 500

  # A ?q= URL param reaches a catalog-wide ILIKE (T-01.1-28) — bounded at
  # the entry point. Any non-binary value (missing param, an array from a
  # malformed query string) degrades to "" rather than crashing mount/3.
  @doc "Reads and bounds the `q` (free-text search) param. Non-binary/absent degrades to `\"\"`."
  def q(%{"q" => q}) when is_binary(q), do: String.slice(q, 0, 100)
  def q(_params), do: ""

  @doc """
  Parses a scalar integer query param. Returns `nil` for `nil`, `""`, a
  non-parseable binary, or any non-binary value (e.g. a crafted
  `?players[]=1&players[]=2`, which decodes to a list — `Integer.parse/1`
  would raise on that, T-01.1-22) rather than raising.
  """
  def parse_int(nil), do: nil
  def parse_int(""), do: nil

  def parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _rest} -> n
      :error -> nil
    end
  end

  def parse_int(_non_binary), do: nil

  @doc """
  Takes a decoded params map (string keys, as Plug/LiveView hands to
  `handle_params/3`, or as `Plug.Conn.Query.decode/1` produces) and
  returns a map with exactly the nine catalog filter keys, each parsed
  and validated against the closed Vocabulary sets. Unknown keys are
  ignored; unknown/invalid values degrade to the field's default.
  """
  def from_params(params) do
    mechanic_set = Vocabulary.mechanic_options()
    theme_set = Vocabulary.theme_options()
    weight_band_set = Enum.map(Vocabulary.weight_bands(), & &1.value)
    tag_set = Enum.map(Vocabulary.editorial_tags(), & &1.tag)

    %{
      q: q(params),
      mechanics: parse_list_param(params["mechanics"], mechanic_set),
      themes: parse_list_param(params["themes"], theme_set),
      weight_bands: parse_list_param(params["weight_bands"], weight_band_set),
      tags: parse_list_param(params["tags"], tag_set),
      players: parse_int(params["players"]),
      max_playtime: parse_int(params["max_playtime"]),
      min_age: parse_int(params["min_age"]),
      sort: parse_sort(params["sort"])
    }
  end

  @doc """
  The inverse of `from_params/1`. Takes the same nine-key map shape
  `CatalogLive.Index`'s `filter_opts/1` already produces, drops every
  entry whose value is `nil`, `""` or `[]`, drops `:sort` when it equals
  the default `:name_asc` (so an unfiltered state encodes to the empty
  string, not a `sort=name_asc` suffix), and returns
  `Plug.Conn.Query.encode/1` of the remaining pairs.
  """
  def to_query(filters) do
    filters
    |> Enum.reject(fn {key, value} -> drop?(key, value) end)
    |> Enum.map(fn {key, value} -> {Atom.to_string(key), stringify(value)} end)
    |> Query.encode()
  end

  @doc """
  Sanitises an incoming `?from=` value into a safe, locally-rooted
  catalog path. `nil`, a non-binary or `""` returns `"/"`. Otherwise the
  value is length-bounded, decoded as a query string, re-validated
  through `from_params/1`'s whitelist, and re-encoded — the returned
  path is always `"/"` or `"/?" <> encoded`, never an absolute URL, a
  protocol-relative URL, or a `javascript:` URI. A malformed percent
  escape (which `Plug.Conn.Query.decode/1` raises on) is rescued to `"/"`
  rather than 500-ing the detail page (T-01.2-03) — the same shape as
  `CatalogLive.Index`'s `safe_filter_games/1` and `CatalogLive.Show`'s
  `safe_similar_games/1`.
  """
  def catalog_path(value) when is_binary(value) and value != "" do
    encoded =
      value
      |> String.slice(0, @max_from_length)
      |> Query.decode()
      |> from_params()
      |> to_query()

    if encoded == "", do: "/", else: "/?" <> encoded
  rescue
    _error -> "/"
  end

  def catalog_path(_value), do: "/"

  # Accepts either a repeated-key list (`?mechanics[]=A&mechanics[]=B`,
  # which Plug decodes to a list) or a single comma-separated value
  # (`?mechanics=A,B`). Truncated to 20 elements BEFORE membership
  # validation (T-01.1-22 — bounds the work even for a maliciously long
  # param), then every element must be a member of the closed Vocabulary
  # set `allowed` or it is dropped silently, never assigned, never
  # reaching a query (T-01.1-23).
  defp parse_list_param(nil, _allowed), do: []

  defp parse_list_param(value, allowed) when is_list(value) do
    value |> Enum.take(20) |> Enum.filter(&(&1 in allowed))
  end

  defp parse_list_param(value, allowed) when is_binary(value) do
    value |> String.split(",", trim: true) |> Enum.take(20) |> Enum.filter(&(&1 in allowed))
  end

  defp parse_list_param(_other, _allowed), do: []

  defp parse_sort("name_asc"), do: :name_asc
  defp parse_sort("playtime_asc"), do: :playtime_asc
  defp parse_sort("playtime_desc"), do: :playtime_desc
  defp parse_sort("complexity_asc"), do: :complexity_asc
  defp parse_sort("complexity_desc"), do: :complexity_desc
  defp parse_sort("year_desc"), do: :year_desc
  defp parse_sort(_unrecognized), do: :name_asc

  defp drop?(_key, nil), do: true
  defp drop?(_key, ""), do: true
  defp drop?(_key, []), do: true
  defp drop?(:sort, :name_asc), do: true
  defp drop?(_key, _value), do: false

  defp stringify(value) when is_binary(value), do: value
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_integer(value), do: Integer.to_string(value)
  defp stringify(value) when is_list(value), do: value
end
