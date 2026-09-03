defmodule PukllayClubWeb.AboutBandWidthTest do
  # Pins the `.pk-band-inner` shared-class width contract (sketch 048, 01.4-01):
  # every content band on the About page (Qué hacemos/Historia, FAQ, Juntadas/
  # Contacto, closing CTA) must cap at 80rem — the same content edge already
  # shared by the header, footer and hero (`max-w-7xl`) — not the narrower
  # 64rem the page shipped with. This is a single shared CSS declaration, so
  # fixing it fixes every band at once; this test guards against a future
  # per-band override re-introducing drift.
  use ExUnit.Case, async: true

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. A selector name mentioned in a comment
  # must never satisfy this assertion — strip before matching.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  defp pk_band_inner_block(src) do
    case Regex.run(~r/(?m)^\.pk-band-inner\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level `.pk-band-inner` rule found in assets/css/app.css")
    end
  end

  test "the .pk-band-inner rule declares max-width: 80rem" do
    block = pk_band_inner_block(source())

    assert block =~ ~r/max-width:\s*80rem/
  end

  test "the .pk-band-inner rule no longer declares a 64rem cap" do
    block = pk_band_inner_block(source())

    refute block =~ "64rem"
  end

  test "assets/css/app.css declares exactly one .pk-band-inner selector block" do
    matches = Regex.scan(~r/(?m)^\.pk-band-inner\s*\{/, strip_comments(source()))

    assert length(matches) == 1
  end
end
