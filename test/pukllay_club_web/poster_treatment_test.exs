defmodule PukllayClubWeb.PosterTreatmentTest do
  # Guards the LETTERBOX TREATMENT (D-04/D-05/D-06, 01.3.1-02-PLAN.md): the single
  # `.pk-poster-img` class that every artwork-rendering surface must reference
  # verbatim, so the crop-to-fill regression this phase fixes cannot silently
  # creep back in on a fourth surface, or on a container that quietly loses the
  # `bg-base-300` token the letterbox fill depends on.
  #
  # Oracle type: derived (contract). The real proof is rendered geometry (does a
  # tall cover actually show in full with neutral bars), which ExUnit cannot
  # observe — these assertions instead pin the CSS declarations and template
  # class lists that geometry depends on, plus rendered-markup coverage for the
  # class references themselves.
  #
  # Every assertion runs against COMMENT-STRIPPED source. This is load-bearing,
  # not fastidious: this plan's own explanatory comments in app.css and in the
  # templates quote the class names and property values at length, so a naive
  # substring search would happily pass against prose while the real declaration
  # was gone — footer_rhythm_test.exs's own sibling was silently satisfied by a
  # comment once.
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias PukllayClub.Catalog.Game
  alias PukllayClubWeb.GameCard

  @css_path Path.expand("../../assets/css/app.css", __DIR__)
  @built_css_path Path.expand("../../priv/static/assets/css/app.css", __DIR__)
  @game_card_path Path.expand("../../lib/pukllay_club_web/components/game_card.ex", __DIR__)

  defp source, do: File.read!(@css_path)

  # Comments are prose, not cascade. Matching selector/property names inside a
  # comment is a false pass.
  defp strip_comments(src), do: String.replace(src, ~r|/\*.*?\*/|s, "")

  # .ex/.heex sibling of strip_comments/1: strips HEEx `<%!-- ... --%>` spans
  # and any line whose first non-whitespace character is `#`, so an Elixir
  # module-doc or code comment naming a class cannot satisfy a template check.
  defp strip_ex_comments(src) do
    src
    |> String.replace(~r|<%!--.*?--%>|s, "")
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.trim() |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp poster_img_block(src) do
    case Regex.run(~r/\.pk-poster-img\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No `.pk-poster-img` rule found in assets/css/app.css")
    end
  end

  defp card_poster_block(src) do
    case Regex.run(~r/(?m)^\.pk-card-poster\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level `.pk-card-poster` rule found in assets/css/app.css")
    end
  end

  describe "the .pk-poster-img rule (D-04/D-05)" do
    test "declares exactly one .pk-poster-img rule, with object-fit: contain" do
      src = strip_comments(source())

      count = ~r/\.pk-poster-img\s*\{/ |> Regex.scan(src) |> length()

      assert count == 1,
             "Expected exactly one `.pk-poster-img` rule in assets/css/app.css, found #{count}. " <>
               "D-06 requires ONE shared mechanism — a second declaration reopens the drift bug " <>
               "the sketch findings document."

      body = poster_img_block(source())

      assert body =~ ~r/object-fit:\s*contain/,
             "`.pk-poster-img` must declare `object-fit: contain` — that is the entire letterbox " <>
               "mechanism (D-04). Without it, box art keeps being cropped to fill its container."
    end

    test "declares no background — the fill is the container's bg-base-300, not a second declaration" do
      body = poster_img_block(source())

      refute body =~ ~r/background/,
             "`.pk-poster-img` declares a `background` property. D-05's fill comes from the " <>
               "container's own `bg-base-300` token showing through the image's transparent " <>
               "negative space — a background here is exactly the competing-declaration pattern " <>
               "this file's own \"one field, one declaration\" rule (app.css:33-36) warns against."
    end
  end

  describe "container shapes are unchanged (Pitfall 3)" do
    test ".pk-card-poster still declares aspect-ratio: 1 / 1.05" do
      body = card_poster_block(source())

      assert body =~ ~r/aspect-ratio:\s*1\s*\/\s*1\.05/,
             "`.pk-card-poster`'s `aspect-ratio` changed from `1 / 1.05`. This plan changes how " <>
               "the image fits its box, never the box — the resting card and the expanded preview " <>
               "are deliberately different UI moments (01.3.1-RESEARCH.md Pitfall 3)."
    end
  end

  describe "game_card.ex renders through the shared class" do
    test "the cover <img> carries pk-poster-img, and the surrounding markup still carries bg-base-300" do
      game = %Game{
        id: 1,
        name: "Endless Winter: Paleoamericans",
        thumbnail_url: "https://cf.geekdo-images.com/example-thumb.webp"
      }

      html = render_component(&GameCard.game_card/1, id: "game-card-1", game: game)

      # Scoped to the resting card's own <figure>: game_card.ex also embeds
      # GamePreview.preview_template/1 (an inert <template> clone target for
      # the hover portal/sheet), which renders its own <img> — an unscoped
      # search over the whole component would see both.
      [_, figure_body] = Regex.run(~r/<figure[^>]*class="pk-card-poster[^>]*>(.*?)<\/figure>/s, html)
      imgs = Regex.scan(~r/<img[^>]*>/, figure_body)
      assert length(imgs) == 1, "Expected exactly one <img> inside the resting card's poster figure."

      [[img]] = imgs
      assert img =~ "pk-poster-img"

      assert html =~ "bg-base-300",
             "The rendered card markup no longer carries `bg-base-300` — that token is what " <>
               "fills the letterbox bars around a contained image (D-05)."
    end
  end

  describe "the rule survives the asset build (D-04)" do
    test "the built stylesheet contains .pk-poster-img with object-fit: contain" do
      if File.exists?(@built_css_path) do
        css = File.read!(@built_css_path)

        assert css =~ ~r/\.pk-poster-img\s*\{[^}]*object-fit:\s*contain/,
               "priv/static/assets/css/app.css has no `.pk-poster-img` rule declaring " <>
                 "`object-fit: contain`. Run `mix assets.build` and confirm the rule reaches the " <>
                 "built stylesheet."
      end
    end
  end

  describe "template comment-stripping helper (self-guard)" do
    test "strip_ex_comments/1 removes HEEx comments and # lines without mangling code" do
      src = File.read!(@game_card_path)
      stripped = strip_ex_comments(src)

      refute stripped =~ "js-cover-fallback class, not an inline",
             "strip_ex_comments/1 failed to remove the module doc's prose — a coverage check " <>
               "against this output could be silently satisfied by a comment instead of real code."

      assert stripped =~ "pk-poster-img",
             "strip_ex_comments/1 stripped real code along with comments — the actual class " <>
               "reference on the <img> element must survive stripping."
    end
  end
end
