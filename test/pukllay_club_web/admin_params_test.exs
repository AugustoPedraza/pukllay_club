defmodule PukllayClubWeb.Admin.ParamsTest do
  use ExUnit.Case, async: true

  alias PukllayClubWeb.Admin.Params

  describe "parse_int/2 — accepts a clean integer inside the range" do
    test "an already-decoded integer (JS.push delivers JSON numbers)" do
      assert Params.parse_int(0, 0..3) == {:ok, 0}
      assert Params.parse_int(2, 0..3) == {:ok, 2}
    end

    test "a strict binary parse" do
      assert Params.parse_int("0", 0..3) == {:ok, 0}
      assert Params.parse_int("3", 0..3) == {:ok, 3}
    end
  end

  describe "parse_int/2 — range endpoints" do
    test "both endpoints are accepted" do
      assert Params.parse_int("0", 0..3) == {:ok, 0}
      assert Params.parse_int("3", 0..3) == {:ok, 3}
    end

    test "one step outside each endpoint is rejected" do
      assert Params.parse_int("-1", 0..3) == :error
      assert Params.parse_int("4", 0..3) == :error
      assert Params.parse_int(-1, 0..3) == :error
      assert Params.parse_int(4, 0..3) == :error
    end
  end

  describe "parse_int/2 — hostile input is :error, never a raise" do
    @hostile_values [
      {"exponent form", "1e3"},
      {"trailing junk", "1abc"},
      {"leading whitespace", " 1"},
      {"trailing whitespace", "1 "},
      {"fraction", "1.0"},
      {"empty string", ""},
      {"nil", nil},
      {"a list", ["1"]},
      {"a map", %{}},
      {"a float", 1.0},
      {"an atom", :one}
    ]

    for {label, value} <- @hostile_values do
      test "#{label} is rejected" do
        assert Params.parse_int(unquote(Macro.escape(value)), 0..3) == :error
      end
    end
  end

  describe "bigint_range/0" do
    test "is exactly 1..9_223_372_036_854_775_807" do
      assert Params.bigint_range() == 1..9_223_372_036_854_775_807
    end

    test "accepts the bigint maximum and rejects one above it" do
      assert Params.parse_int("9223372036854775807", Params.bigint_range()) ==
               {:ok, 9_223_372_036_854_775_807}

      assert Params.parse_int("9223372036854775808", Params.bigint_range()) == :error
    end

    test "rejects zero and negatives" do
      assert Params.parse_int("0", Params.bigint_range()) == :error
      assert Params.parse_int("-5", Params.bigint_range()) == :error
    end
  end
end
