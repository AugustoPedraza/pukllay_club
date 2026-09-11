defmodule PukllayClubWeb.CatalogFiltersTest do
  use ExUnit.Case, async: true

  alias Plug.Conn.Query
  alias PukllayClubWeb.CatalogFilters

  describe "catalog_path/1 — hostile-input rejection contract (T-01.2-01)" do
    # Table-driven so a future hostile shape added to this list can never be
    # silently forgotten — each entry is independently asserted, not folded
    # into one combined query string.
    @hostile_values [
      {"absolute https URL", "https://evil.example"},
      {"protocol-relative URL", "//evil.example"},
      {"javascript: URI", "javascript:alert(1)"},
      {"unknown key", "totally_unknown_key=1"},
      {"unknown facet value", "mechanics=NoExisteEnLaVocabulary"},
      {"5000-character junk string", String.duplicate("a", 5000)},
      # A truncated multi-byte UTF-8 percent escape — `Plug.Conn.Query.decode/1`
      # raises `Plug.Conn.InvalidQueryError` on this (invalid UTF-8), which
      # `catalog_path/1`'s rescue clause must catch rather than propagate.
      {"malformed percent escape", "q=%C3"},
      {"empty string", ""}
    ]

    for {label, value} <- @hostile_values do
      test "#{label} resolves to the bare catalog root" do
        assert CatalogFilters.catalog_path(unquote(value)) == "/"
      end
    end

    test "nil resolves to the bare catalog root" do
      assert CatalogFilters.catalog_path(nil) == "/"
    end

    test "a non-binary value resolves to the bare catalog root" do
      assert CatalogFilters.catalog_path(%{not: "a string"}) == "/"
      assert CatalogFilters.catalog_path(123) == "/"
      assert CatalogFilters.catalog_path([:a, :list]) == "/"
    end
  end

  describe "catalog_path/1 — preserves whitelisted state" do
    test "a real mechanic label plus players round-trips to the same pairs" do
      path = CatalogFilters.catalog_path("mechanics=Tira+dados&players=4")

      assert "/?" <> query = path
      decoded = Query.decode(query)

      assert decoded["mechanics"] in ["Tira dados", ["Tira dados"]]
      assert decoded["players"] == "4"
    end
  end

  describe "to_query/1" do
    test "a fully-default filter map encodes to the empty string" do
      defaults = %{
        q: "",
        mechanics: [],
        themes: [],
        weight_bands: [],
        tags: [],
        players: nil,
        max_playtime: nil,
        min_age: nil,
        sort: :name_asc
      }

      assert CatalogFilters.to_query(defaults) == ""
    end
  end

  describe "from_params/1 — bounds" do
    test "caps a q longer than 100 characters at 100" do
      long_q = String.duplicate("a", 250)

      filters = CatalogFilters.from_params(%{"q" => long_q})

      assert String.length(filters.q) == 100
    end

    test "caps a list facet at 20 members before membership filtering" do
      long_list = Enum.map(1..50, &"Fake#{&1}")

      filters = CatalogFilters.from_params(%{"mechanics" => long_list})

      assert filters.mechanics == []
    end
  end

  describe "to_query/1 and from_params/1 — idempotence" do
    test "re-feeding to_query/1's output through decode + from_params produces the same map" do
      filters = %{
        q: "Catán",
        mechanics: ["Tira dados"],
        themes: [],
        weight_bands: ["nivel_experto"],
        tags: [],
        players: 4,
        max_playtime: nil,
        min_age: nil,
        sort: :year_desc
      }

      round_tripped =
        filters
        |> CatalogFilters.to_query()
        |> Query.decode()
        |> CatalogFilters.from_params()

      assert round_tripped == filters
    end
  end
end
