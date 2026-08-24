defmodule PukllayClubWeb.FooterAttributionTest do
  # Guards the BGG attribution's VERTICAL ALIGNMENT and its VISUAL WEIGHT — two
  # defects that shared one culprit element, `.pk-bgg-note` (debug session
  # footer-desktop-imbalance).
  #
  # (A) ALIGNMENT. The anchor carried `inline-flex items-center gap-1`. An
  # inline-level flex container with no baseline-aligned item must SYNTHESIZE
  # its baseline from the first flex item's border box (CSS Flexbox §8.3), and
  # the first item was the logo. So the image's bottom edge became the link's
  # baseline: measured on the live app, the copyright text's baseline and the
  # image's bottom edge coincided at y=5488.69 exactly, throwing "Powered by
  # BGG" 5.00px above the "© 2026 Pukllay Club ·" beside it and inflating the
  # meta line box from 18px to 23px. This is a trap for ANY icon+text run that
  # lives inside a sentence, which is why the assertions below are about the
  # anchor never being a flex container again — not about a pixel offset.
  #
  # (B) WEIGHT. The same mark is an opaque 400x400 JPEG with a baked-in dark
  # background, and it was sized "~18px (roughly text line-height)"
  # (01.1-01-SUMMARY.md:49). Line-height is the wrong reference metric for an
  # inline mark: matching the line box means filling it edge to edge. On the
  # light theme it measured 100% ink at meanChroma 0.32 — 12.1x the social
  # row's per-pixel ink density, its 324px² carrying as much total ink mass
  # (248.08) as the entire four-icon social row (240.84) across 11.75x the
  # area. page-shell.md:69-75 had already required the opposite: the
  # attribution must be "de-emphasized ... not a bordered, backgrounded
  # 'badge' competing visually with the rest of the footer".
  #
  # Oracle type: derived (contract). The real proof is rendered geometry and
  # rendered pixels, neither of which ExUnit can observe; these assertions pin
  # the declarations that geometry depends on.
  #
  # RED-verification status, stated precisely rather than as a blanket claim.
  # Stashing the fix and re-running produced 5 failures out of 7. The five that
  # went red are true regression witnesses: they observed the real defect. The
  # other two are forward-looking guards that were green before the fix too, and
  # are labelled as such below —
  #   * "the stylesheet does not reintroduce a flex display on the link" — the
  #     bug arrived via a Tailwind utility in the markup, never via this rule.
  #     It guards the OTHER route to the same mechanism.
  #   * "the logo is square and declares intrinsic dimensions" — 18x18 was
  #     already square. It guards against a future non-uniform resize
  #     distorting a trademark.
  # Neither is padding: both close a path into the same failure mode. But they
  # are not evidence that this fix worked, and are not counted as such.
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias PukllayClubWeb.Layouts

  @css_path Path.expand("../../assets/css/app.css", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. A sibling footer test was once silently
  # satisfied by a selector merely being NAMED in a comment; strip up front.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  defp rule!(src, selector) do
    pattern = selector |> Regex.escape() |> then(&~r/(?m)^#{&1}\s*\{([^}]*)\}/)

    case Regex.run(pattern, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No `#{selector}` rule found in assets/css/app.css")
    end
  end

  defp footer_doc do
    html = render_component(&Layouts.app/1, %{flash: %{}, inner_block: []})
    LazyHTML.from_document(html)
  end

  defp attr!(doc, selector, name) do
    case doc |> LazyHTML.query(selector) |> LazyHTML.attribute(name) do
      [value | _] -> value
      [] -> flunk("`#{selector}` has no `#{name}` attribute")
    end
  end

  # `.pk-footer-meta`'s declared font-size, in px. The mark's size is asserted
  # against THIS rather than a literal, because "size the mark against the type
  # it annotates" is the actual invariant — a hard-coded 14 would pass even if
  # the small print were later rescaled underneath it.
  defp meta_font_px(src) do
    [_, rem] = Regex.run(~r/font-size:\s*([\d.]+)rem/, rule!(src, ".pk-footer-meta"))
    String.to_float(if String.contains?(rem, "."), do: rem, else: rem <> ".0") * 16
  end

  describe "the attribution shares one baseline with the copyright text" do
    test "the link is never an inline-level flex container" do
      doc = footer_doc()
      classes = attr!(doc, ".pk-bgg-note", "class")

      refute classes =~ ~r/\b(inline-)?flex\b/,
             "`.pk-bgg-note` carries a flex utility (`#{classes}`). This link sits INSIDE a " <>
               "sentence — it follows \"© {year} Pukllay Club · \" in the same text run. Making " <>
               "it a flex container removes every baseline-aligned item, so CSS Flexbox §8.3 " <>
               "forces the browser to synthesize the link's baseline from its first flex item's " <>
               "border box — the logo — and the image's BOTTOM edge lands on the copyright's " <>
               "baseline. That is the exact 5px offset this fix removed."
    end

    test "the stylesheet does not reintroduce a flex display on the link" do
      body = rule!(source(), ".pk-bgg-note")

      refute body =~ ~r/display:\s*(inline-)?flex/,
             "`.pk-bgg-note` declares a flex display in CSS. Same mechanism as the utility-class " <>
               "route above, just moved into the stylesheet — the baseline would be synthesized " <>
               "from the logo again."
    end

    test "the logo is an inline-level box aligned against the type, not the line box" do
      body = rule!(source(), ".pk-bgg-note img")

      assert body =~ "display: inline-block",
             "`.pk-bgg-note img` must restore an inline-level display. Tailwind's preflight sets " <>
               "`img { display: block }`, and a block box inside this now-plain-inline anchor " <>
               "would split its inline flow instead of sitting in the sentence."

      assert body =~ "vertical-align: middle",
             "`.pk-bgg-note img` must declare `vertical-align: middle`. It centres the mark on " <>
               "the parent's x-height and self-adjusts to the type — the point is that there is " <>
               "no magic pixel offset to drift out of sync when the font-size or logo size changes."
    end

    test "the underline decorates the words, not the logo tile" do
      doc = footer_doc()
      src = source()

      assert doc |> LazyHTML.query(".pk-bgg-note span") |> Enum.count() == 1,
             "The attribution words must be wrapped in their own <span>. The anchor is plain " <>
               "inline now, so an anchor-level underline is drawn straight across the logo tile."

      refute rule!(src, ".pk-bgg-note") =~ "text-decoration: underline",
             "The underline is declared on `.pk-bgg-note` itself, which draws it through the " <>
               "logo. It belongs on `.pk-bgg-note span`."

      assert rule!(src, ".pk-bgg-note span") =~ "text-decoration: underline",
             "`.pk-bgg-note span` must carry the underline — page-shell.md specifies this " <>
               "attribution as underlined small print, and that must survive moving the " <>
               "decoration off the anchor."
    end
  end

  describe "the attribution mark stays de-emphasized" do
    test "the logo is square and declares intrinsic dimensions" do
      doc = footer_doc()

      width = doc |> attr!(".pk-bgg-note img", "width") |> String.to_integer()
      height = doc |> attr!(".pk-bgg-note img", "height") |> String.to_integer()

      assert width == height,
             "The BGG mark is a square 400x400 asset; #{width}x#{height} would distort a " <>
               "trademark. Intrinsic width/height must also stay present so the line does not " <>
               "reflow while the image loads."
    end

    test "the mark is sized against the type it annotates, not the line box it sits in" do
      doc = footer_doc()
      font_px = meta_font_px(source())
      size = doc |> attr!(".pk-bgg-note img", "width") |> String.to_integer()
      ratio = size / font_px

      # Boundary neighbour on the defect's own equivalence class. The bug was
      # 18px against 12px type — ratio 1.5, chosen to match the 18px LINE-HEIGHT.
      # A bare `size < 18` would still admit 17px, which is the same defect one
      # pixel quieter, so the bound is expressed as a ratio to the font-size and
      # set below the defect ratio with real margin.
      assert ratio <= 1.25,
             "The BGG mark is #{size}px against #{trunc(font_px)}px type (#{Float.round(ratio, 2)}x). " <>
               "Above ~1.25x it stops annotating the small print and starts competing with it: at " <>
               "1.5x (18px, the old line-height-derived size) this opaque tile measured 100% ink " <>
               "and carried as much visual weight as the entire four-icon social row across " <>
               "11.75x less area. page-shell.md requires this attribution be de-emphasized, not a " <>
               "backgrounded badge."

      assert ratio >= 1.0,
             "The BGG mark is #{size}px against #{trunc(font_px)}px type (#{Float.round(ratio, 2)}x) — " <>
               "shrunk below the type it sits beside. The attribution is a compliance requirement " <>
               "(D-04) and has to stay legible; de-emphasizing it must not become hiding it."
    end

    test "no CSS box, border or shadow is added around the mark" do
      body = rule!(source(), ".pk-bgg-note img")

      for prop <- ["border", "box-shadow", "outline", "background"] do
        refute body =~ ~r/(?<![-\w])#{prop}[-\w]*:/,
               "`.pk-bgg-note img` declares `#{prop}`. BGG's terms forbid enclosing their " <>
                 "trademark in framing chrome, and page-shell.md independently requires no box " <>
                 "beyond what the asset itself already contains."
      end
    end
  end
end
