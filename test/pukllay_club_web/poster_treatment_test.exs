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
  alias PukllayClubWeb.GamePreview

  @css_path Path.expand("../../assets/css/app.css", __DIR__)
  @built_css_path Path.expand("../../priv/static/assets/css/app.css", __DIR__)
  @game_card_path Path.expand("../../lib/pukllay_club_web/components/game_card.ex", __DIR__)
  @game_preview_path Path.expand("../../lib/pukllay_club_web/components/game_preview.ex", __DIR__)
  @show_path Path.expand("../../lib/pukllay_club_web/live/catalog_live/show.ex", __DIR__)

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

  defp preview_poster_block(src) do
    case Regex.run(~r/(?m)^\.pk-preview-poster\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No top-level `.pk-preview-poster` rule found in assets/css/app.css")
    end
  end

  defp lightbox_img_block(src) do
    case Regex.run(~r/\.pk-lightbox-img\s*\{([^}]*)\}/, strip_comments(src)) do
      [_, body] -> body
      nil -> flunk("No `.pk-lightbox-img` rule found in assets/css/app.css")
    end
  end

  # Counts occurrences of `needle` in a comment-stripped .ex source file.
  defp ex_occurrences(path, needle) do
    path
    |> File.read!()
    |> strip_ex_comments()
    |> then(&Regex.scan(Regex.compile!(Regex.escape(needle)), &1))
    |> length()
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

  describe "coverage: every artwork surface points at the shared class exactly once" do
    test "game_card.ex, game_preview.ex and show.ex each reference pk-poster-img exactly once" do
      for {path, label} <- [
            {@game_card_path, "game_card.ex"},
            {@game_preview_path, "game_preview.ex"},
            {@show_path, "catalog_live/show.ex"}
          ] do
        count = ex_occurrences(path, "pk-poster-img")

        assert count == 1,
               "#{label} references `pk-poster-img` #{count} time(s), expected exactly 1. A " <>
                 "second reference means a surface was pointed at the class by copy-paste rather " <>
                 "than by replacing its own object-cover treatment (D-06)."
      end
    end
  end

  describe "exclusivity: the crop-to-fill utility is gone everywhere except the one permitted chip" do
    test "game_card.ex and game_preview.ex carry zero object-cover occurrences; show.ex carries exactly one" do
      card_count = ex_occurrences(@game_card_path, "object-cover")
      preview_count = ex_occurrences(@game_preview_path, "object-cover")
      show_count = ex_occurrences(@show_path, "object-cover")

      assert card_count == 0,
             "game_card.ex still has #{card_count} `object-cover` occurrence(s) — it must be " <>
               "fully replaced by `pk-poster-img` (D-06)."

      assert preview_count == 0,
             "game_preview.ex still has #{preview_count} `object-cover` occurrence(s) — it must " <>
               "be fully replaced by `pk-poster-img` (D-06)."

      assert show_count == 1,
             "show.ex has #{show_count} `object-cover` occurrence(s), expected exactly 1. The " <>
               "single permitted occurrence is the 64x64 gallery selector chip (show.ex:471), " <>
               "deliberately excluded from the letterbox treatment — a different count means " <>
               "either the detail cover was missed or the chip itself drifted."
    end
  end

  describe "fill guard (D-05): every poster container still carries bg-base-300" do
    test "every line mentioning pk-card-poster or pk-preview-poster also mentions bg-base-300" do
      for {path, label} <- [
            {@game_card_path, "game_card.ex"},
            {@game_preview_path, "game_preview.ex"},
            {@show_path, "catalog_live/show.ex"}
          ] do
        offenders =
          path
          |> File.read!()
          |> strip_ex_comments()
          |> String.split("\n")
          |> Enum.filter(&(&1 =~ "pk-card-poster" or &1 =~ "pk-preview-poster"))
          |> Enum.reject(&(&1 =~ "bg-base-300"))

        assert offenders == [],
               "#{label} has a `pk-card-poster`/`pk-preview-poster` line missing `bg-base-300`: " <>
                 inspect(offenders) <>
                 ". Removing that token from a container silently removes the letterbox fill " <>
                 "(D-05) without touching any rule the CSS-contract tests check."
      end
    end
  end

  describe "shape guard (Pitfall 3): .pk-preview-poster's ratio is unchanged" do
    test ".pk-preview-poster still declares aspect-ratio: 16 / 9" do
      body = preview_poster_block(source())

      assert body =~ ~r/aspect-ratio:\s*16\s*\/\s*9/,
             "`.pk-preview-poster`'s `aspect-ratio` changed from `16 / 9`. Task 1 pinned " <>
               "`.pk-card-poster`'s ratio; this completes the pair — the resting card and the " <>
               "expanded preview are deliberately different UI moments, not a shape to unify."
    end
  end

  describe "the lightbox is untouched — its differing dark stage is intentional, not drift" do
    test ".pk-lightbox-img still declares object-fit: contain and background: var(--pk-shadow-color)" do
      body = lightbox_img_block(source())

      assert body =~ ~r/object-fit:\s*contain/,
             "`.pk-lightbox-img` no longer declares `object-fit: contain`. It already implemented " <>
               "the letterbox treatment before this phase (a Phase 01.2 rebuild) — it must not " <>
               "regress."

      assert body =~ ~r/background:\s*var\(--pk-shadow-color\)/,
             "`.pk-lightbox-img` no longer declares `background: var(--pk-shadow-color)`. This " <>
               "dark photography-stage background is an intentional, approved design choice for " <>
               "the full-screen context — DO NOT \"fix\" it toward the card surfaces' neutral " <>
               "`bg-base-300` token; that would be a visual regression, not a correction."
    end
  end

  describe "game_preview.ex renders through the shared class" do
    test "preview_body/1 with a cover_url emits an <img> whose class carries pk-poster-img" do
      game = %Game{
        id: 1,
        name: "Endless Winter: Paleoamericans",
        description: "Un juego de estrategia.",
        cover_url: "https://cf.geekdo-images.com/example-cover.webp",
        min_players: 2,
        max_players: 4,
        tags: []
      }

      html = render_component(&GamePreview.preview_body/1, game: game)

      [_, figure_body] =
        Regex.run(~r/<figure[^>]*class="pk-preview-poster[^>]*>(.*?)<\/figure>/s, html)

      imgs = Regex.scan(~r/<img[^>]*>/, figure_body)
      assert length(imgs) == 1, "Expected exactly one <img> inside the preview's poster figure."

      [[img]] = imgs
      assert img =~ "pk-poster-img"
    end
  end
end
