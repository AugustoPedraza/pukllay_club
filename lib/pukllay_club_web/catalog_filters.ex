defmodule PukllayClubWeb.CatalogFilters do
  @moduledoc """
  The single authority for reading, validating and re-encoding catalog
  filter params (D-08). Shared by `PukllayClubWeb.CatalogLive.Index`
  (URL read path — `handle_params/3` calls `from_params/1` once per
  navigation) and `PukllayClubWeb.CatalogLive.Show` (breadcrumb target —
  `catalog_path/1` sanitises a `?from=` value carried across pages). The
  two consumers can never drift apart on which facet values are accepted
  because there is exactly one copy of each parsing rule.

  Of the eleven catalog filter keys (`q`, `mechanics`, `themes`,
  `weight_bands`, `sections`, `players`, `max_playtime`, `min_age`,
  `sort`, `designers`, `artists`), `mechanics`/`themes`/`weight_bands` are
  re-validated through `from_params/1`'s closed Vocabulary membership
  check. `designers`/`artists` (01.3-06) are open-text — BGG-sourced
  free-form names with no closed set to validate against — and are
  instead bounded by element count and per-element length
  (`parse_name_list_param/1`) before they can reach a query or a
  re-encoded path. `sections` (D-27) replaces the retired `tags` key: a
  section is a staff-managed database row, not a fixed vocabulary, so it
  has no membership set to validate against either — it is instead bound
  and parameterized like `designers`/`artists`, but to positive integers:
  `parse_id_list_param/1` keeps only strings that `Integer.parse/1` reads
  fully as a positive integer, dedupes, and caps at 20. An id that does
  not resolve to a visible, non-hidden `:manual` section simply matches no
  game — enforced at the query layer in `PukllayClub.Catalog`, not here.

  `catalog_path/1` is the security control for D-08's breadcrumb: it
  never echoes its input. It decodes the incoming value, re-validates
  every key/value through `from_params/1` (closed-Vocabulary whitelist for
  `mechanics`/`themes`/`weight_bands`, bound-and-parameterize for
  `designers`/`artists`/`sections`), then re-encodes from
  scratch — so the returned string is always a locally-rooted `/` path
  built from known-good pairs. An absolute URL, a protocol-relative
  `//host`, or a `javascript:` URI remains a structurally unreachable
  output, not merely a rejected input (T-01.2-01) — it now simply arrives
  as a bounded opaque string in a list value for the two open-text keys.
  """

  alias Plug.Conn.Query
  alias PukllayClub.Catalog.Vocabulary

  # 500-character bound on the incoming `?from=` value before it is ever
  # decoded (T-01.2-02) — a crafted arbitrarily-long value never reaches
  # `Plug.Conn.Query.decode/1` at full size.
  @max_from_length 500

  # Per-element length bound for the open-text `designers`/`artists`
  # values (01.3-06, T-01.3-06-02) — the bound-and-parameterize control
  # that replaces the closed-Vocabulary membership check for these two
  # keys, since BGG-sourced creator names have no closed set to validate
  # against.
  @max_name_length 120

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
  returns a map with exactly the eleven catalog filter keys.
  `mechanics`/`themes`/`weight_bands` are parsed and validated against the
  closed Vocabulary sets; `designers`/`artists` (01.3-06) are open-text and
  instead bounded by element count and per-element length; `sections`
  (D-27) is bounded to positive integers, deduped, capped at 20. Unknown
  keys are ignored; unknown/invalid values degrade to the field's default.
  """
  def from_params(params) do
    mechanic_set = Vocabulary.mechanic_options()
    theme_set = Vocabulary.theme_options()
    weight_band_set = Enum.map(Vocabulary.weight_bands(), & &1.value)

    %{
      q: q(params),
      mechanics: parse_list_param(params["mechanics"], mechanic_set),
      themes: parse_list_param(params["themes"], theme_set),
      weight_bands: parse_list_param(params["weight_bands"], weight_band_set),
      sections: parse_id_list_param(params["sections"]),
      designers: parse_name_list_param(params["designers"]),
      artists: parse_name_list_param(params["artists"]),
      players: parse_int(params["players"]),
      max_playtime: parse_int(params["max_playtime"]),
      min_age: parse_int(params["min_age"]),
      sort: parse_sort(params["sort"])
    }
  end

  @doc """
  The inverse of `from_params/1`. Takes the same eleven-key map shape
  `CatalogLive.Index`'s `filter_opts/1` already produces, drops every
  entry whose value is `nil`, `""` or `[]`, drops `:sort` when it equals
  the default `:name_asc` (so an unfiltered state encodes to the empty
  string, not a `sort=name_asc` suffix), and returns
  `Plug.Conn.Query.encode/1` of the remaining pairs. `designers`/
  `artists`/`sections` need no dedicated clause here — `drop?/2` already
  drops `[]` and `stringify/1` already passes a list through unchanged
  (`Query.encode/1` defaults to `&to_string/1` per element, so a list of
  integers round-trips exactly like a list of strings), which is what
  `Plug.Conn.Query.encode/1` needs for a repeated-key round-trip.
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
  # param), then every element must be a member of the closed Vocabulary whitelist
  # `allowed` or it is dropped silently, never assigned, never reaching a
  # query (T-01.1-23). This is still true of the three keys this function
  # serves (`mechanics`/`themes`/`weight_bands`) — `designers`/`artists`
  # (01.3-06) go through `parse_name_list_param/1` instead, and `sections`
  # (D-27) through `parse_id_list_param/1`, since neither has a closed set.
  defp parse_list_param(nil, _allowed), do: []

  defp parse_list_param(value, allowed) when is_list(value) do
    value |> Enum.take(20) |> Enum.filter(&(&1 in allowed))
  end

  defp parse_list_param(value, allowed) when is_binary(value) do
    value |> String.split(",", trim: true) |> Enum.take(20) |> Enum.filter(&(&1 in allowed))
  end

  defp parse_list_param(_other, _allowed), do: []

  # Open-text counterpart to `parse_list_param/2` for `designers`/
  # `artists` (01.3-06, T-01.3-06-02) — there is no closed set to
  # validate membership against, so the bounds below ARE the control,
  # applied in this order:
  #   1. `Enum.take(20)` BEFORE any per-element work, so a maliciously
  #      long repeated-key param bounds the work done, not just the
  #      final result (mirrors `parse_list_param/2`'s own ordering).
  #   2. `Enum.filter(&is_binary/1)` — a nested array (`?designers[][]=`)
  #      decodes to a list of lists; a non-binary element is dropped
  #      rather than passed to `String.slice/3`, which would raise.
  #   3. `Enum.map(&String.slice(&1, 0, @max_name_length))` — per-element
  #      length bound.
  #   4. `Enum.reject(&(&1 == ""))` — an empty value would otherwise
  #      match no row while still counting as an active filter and
  #      rendering an empty chip.
  defp parse_name_list_param(nil), do: []

  defp parse_name_list_param(value) when is_list(value) do
    value
    |> Enum.take(20)
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.slice(&1, 0, @max_name_length))
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_name_list_param(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.take(20)
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.slice(&1, 0, @max_name_length))
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_name_list_param(_other), do: []

  # D-27, T-01.8.1-50: bound-and-parameterize counterpart to
  # `parse_name_list_param/2`, for the `sections` key — there is no closed
  # Vocabulary to validate a section id against either (a section is a
  # staff-managed database row), so the bounds below ARE the control,
  # applied in the same order as `parse_name_list_param/2`: `Enum.take(20)`
  # BEFORE any per-element work bounds the work done, not just the final
  # result. `Integer.parse/1` must consume the WHOLE string (`{n, ""}`) —
  # a value like `"3x"` is rejected outright rather than silently
  # truncated to `3` — and only a positive result survives, so `"-1"`/`"0"`
  # are dropped exactly like a non-numeric value. `Enum.uniq/1` de-dupes
  # after parsing, since `"3"` and `"03"` both parse to the same integer.
  defp parse_id_list_param(nil), do: []

  defp parse_id_list_param(value) when is_list(value) do
    value
    |> Enum.take(20)
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&parse_positive_int/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp parse_id_list_param(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.take(20)
    |> Enum.map(&parse_positive_int/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp parse_id_list_param(_other), do: []

  defp parse_positive_int(value) do
    case Integer.parse(value) do
      {n, ""} when n > 0 -> n
      _invalid -> nil
    end
  end

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
