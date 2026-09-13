defmodule PukllayClub.Catalog.SlugTest do
  @moduledoc """
  Pure `slugify/1` + `Phoenix.Param` edge-case coverage — no DB (quick task
  260913-2x6). `Phoenix.Param.to_param/1` is asserted here too since it is
  a one-line wrapper around `slugify/1` with no DB-touching behavior of its
  own.
  """

  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Slug

  describe "slugify/1 — transliteration" do
    test "transliterates accented vowels and ñ" do
      assert Slug.slugify("Catán") == "catan"
      assert Slug.slugify("Búsqueda ñandú") == "busqueda-nandu"
    end
  end

  describe "slugify/1 — punctuation handling" do
    test "keeps parenthesised noise, punctuation collapses to a dash" do
      assert Slug.slugify("Everdell Spirecrest(expa)") == "everdell-spirecrest-expa"
    end

    test "apostrophes are dropped, not treated as a word boundary — both ASCII and typographic" do
      assert Slug.slugify("Wonderland's War (2022)") == "wonderlands-war-2022"
      assert Slug.slugify("Wonderland’s War (2022)") == "wonderlands-war-2022"
    end

    test "runs of punctuation/spaces collapse to a single dash, no leading/trailing dash" do
      assert Slug.slugify("undaunted: north africa") == "undaunted-north-africa"
    end
  end

  describe "slugify/1 — length cap" do
    test "caps at 60 characters and trims a trailing dash left by a cut landing exactly on one" do
      # 11 five-letter words joined by single spaces -> slug is 65 chars
      # ("aaaaa-aaaaa-...-aaaaa", 11 words / 10 dashes). The dash after the
      # 10th word falls exactly at character 60 (each "aaaaa-" unit is 6
      # chars), so slicing to 60 keeps that trailing dash — trimming AFTER
      # the cut is what removes it.
      name = List.duplicate("aaaaa", 11) |> Enum.join(" ")
      expected = List.duplicate("aaaaa", 10) |> Enum.join("-")

      slug = Slug.slugify(name)

      assert slug == expected
      assert String.length(slug) == 59
      refute String.ends_with?(slug, "-")
    end
  end

  describe "slugify/1 — empty results" do
    test "punctuation-only, empty, and nil input all slugify to an empty string" do
      assert Slug.slugify("!!!") == ""
      assert Slug.slugify("") == ""
      assert Slug.slugify(nil) == ""
    end
  end

  describe "Phoenix.Param for PukllayClub.Catalog.Game" do
    test "returns \"<id>-<slug>\" for a named game" do
      assert Phoenix.Param.to_param(%Game{id: 137, name: "Catán"}) == "137-catan"
    end

    test "returns the bare id, with no trailing dash, when the slug is empty" do
      assert Phoenix.Param.to_param(%Game{id: 137, name: "!!!"}) == "137"
    end

    test "raises ArgumentError for a nil id" do
      assert_raise ArgumentError, fn ->
        Phoenix.Param.to_param(%Game{id: nil, name: "Catán"})
      end
    end
  end
end
