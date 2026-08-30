defmodule PukllayClub.Catalog.Seed.DescriptionNormalizerTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Seed.DescriptionNormalizer

  describe "clean/1" do
    test "decodes the mdash escape into an em dash character" do
      assert DescriptionNormalizer.clean("a loyal friend &mdash; your llama") ==
               "a loyal friend — your llama"

      refute DescriptionNormalizer.clean("a loyal friend &mdash; your llama") =~ "&mdash;"
    end

    test "decodes the eacute escape into an accented e" do
      assert DescriptionNormalizer.clean("caf&eacute; culture") == "café culture"
    end

    test "decodes every one of the confirmed escape names in a single input with zero escapes left" do
      input =
        DescriptionNormalizer.known_entities()
        |> Map.keys()
        |> Enum.map(&"&#{&1};")
        |> Enum.join(" ")

      cleaned = DescriptionNormalizer.clean(input)

      refute cleaned =~ ~r/&[a-zA-Z]+;/
    end

    test "leaves an unrecognized escape name untouched and reports it via unknown_escapes/1" do
      input = "some &unknownname; text"

      assert DescriptionNormalizer.clean(input) == input
      assert DescriptionNormalizer.unknown_escapes(input) == ["unknownname"]
    end

    test "nil in, nil out; a string with no escapes is returned unchanged" do
      assert DescriptionNormalizer.clean(nil) == nil

      plain = "No escapes here at all."
      assert DescriptionNormalizer.clean(plain) == plain
    end

    test "decodes an escaped ampersand followed by other escapes in a single pass, without double-decoding" do
      input = "&amp;mdash; and &eacute;"

      assert DescriptionNormalizer.clean(input) == "&mdash; and é"
    end
  end

  describe "unknown_escapes/1" do
    test "returns an empty list for nil and for text with no escapes" do
      assert DescriptionNormalizer.unknown_escapes(nil) == []
      assert DescriptionNormalizer.unknown_escapes("plain text") == []
    end

    test "returns an empty list when every escape in the text is recognized" do
      assert DescriptionNormalizer.unknown_escapes("a &mdash; b &eacute; c") == []
    end
  end
end
