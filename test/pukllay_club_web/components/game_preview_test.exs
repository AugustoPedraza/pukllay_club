defmodule PukllayClubWeb.GamePreviewTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PukllayClub.Catalog.Game
  alias PukllayClubWeb.GamePreview
  alias PukllayClubWeb.GameText

  @nivel_experto %Game{
    id: 1,
    name: "Juego Experto",
    description: "Una partida larga y profunda.",
    min_players: 2,
    max_players: 4,
    min_playtime: 60,
    max_playtime: 90,
    min_age: 10,
    weight_band: "nivel_experto",
    tags: ["#CreaConexiones"]
  }

  @descubre_el_hobby %{@nivel_experto | weight_band: "descubre_el_hobby"}

  describe "preview_body/1 — facts row" do
    test "renders one pk-facts-row with the players text, tiempo text, and difficulty dots for the resolved band" do
      html = render_component(&GamePreview.preview_body/1, game: @nivel_experto)

      assert ~r/pk-facts-row/ |> Regex.scan(html) |> length() == 1
      assert html =~ "2-4"
      assert html =~ "60-90 min"
    end

    test "a nivel_experto game renders exactly three filled difficulty dots" do
      html = render_component(&GamePreview.preview_body/1, game: @nivel_experto)

      dots = Regex.scan(~r/pk-difficulty-dot(?: is-filled)?/, html)
      filled = Enum.count(dots, fn [match] -> match =~ "is-filled" end)

      assert length(dots) == 3
      assert filled == 3
    end

    test "a descubre_el_hobby game renders exactly one filled difficulty dot" do
      html = render_component(&GamePreview.preview_body/1, game: @descubre_el_hobby)

      dots = Regex.scan(~r/pk-difficulty-dot(?: is-filled)?/, html)
      filled = Enum.count(dots, fn [match] -> match =~ "is-filled" end)

      assert length(dots) == 3
      assert filled == 1
    end

    test "renders the plain-Spanish band label and never a raw minimum-age number" do
      html = render_component(&GamePreview.preview_body/1, game: @nivel_experto)

      assert html =~ "Nivel experto"
      refute html =~ ">10<"
      refute html =~ "10 años"
    end

    test "the editorial tag span carries data-sheet-only when the game has tags" do
      html = render_component(&GamePreview.preview_body/1, game: @nivel_experto)

      assert html =~ ~s(data-sheet-only)
      assert html =~ "#CreaConexiones"
    end

    test "a game with no editorial tags emits no tag span" do
      game = %{@nivel_experto | tags: []}
      html = render_component(&GamePreview.preview_body/1, game: game)

      refute html =~ "data-sheet-only"
    end

    test "a game with no resolved weight band emits a facts row with two facts and no difficulty indicator" do
      game = %{@nivel_experto | weight_band: nil}
      html = render_component(&GamePreview.preview_body/1, game: game)

      refute html =~ "pk-difficulty"
      assert html =~ "2-4"
      assert html =~ "60-90 min"
    end

    test "a game with min_playtime: nil and a non-nil, non-equal max_playtime renders without crashing (CR-01 regression)" do
      game = %{@nivel_experto | min_playtime: nil, max_playtime: 45}

      html = render_component(&GamePreview.preview_body/1, game: game)

      assert html =~ "45 min"
    end

    test "the CTA is an outlined link to the game's detail page and carries no filled-button class" do
      html = render_component(&GamePreview.preview_body/1, game: @nivel_experto)

      assert html =~ ~s(href="/juegos/1-juego-experto")
      assert html =~ "btn-outline"
      refute html =~ "btn btn-primary btn-sm"
    end
  end

  describe "facts_row/1 — dificultad link (G-01.2-20)" do
    test "renders no link for any fact when linked is false (default) — the browse-card hover preview is unchanged" do
      html = render_component(&GamePreview.facts_row/1, game: @nivel_experto)

      refute html =~ "<a "
      assert html =~ "Nivel experto"
    end

    test "renders the dificultad pill as a link into the weight-band filter when linked is true" do
      html = render_component(&GamePreview.facts_row/1, game: @nivel_experto, linked: true)

      assert html =~ ~s(href="/?weight_bands=nivel_experto")
    end

    test "renders no dificultad link, and no bare band label change, when linked is true but the game has no resolved weight band" do
      game = %{@nivel_experto | weight_band: nil}
      html = render_component(&GamePreview.facts_row/1, game: game, linked: true)

      refute html =~ "weight_bands="
      refute html =~ "pk-difficulty"
    end
  end

  describe "preview_body/1 — cover accessible name (SEO-02, D-10)" do
    defp poster_figure(html) do
      [_, figure_body] =
        Regex.run(~r/<figure[^>]*class="pk-preview-poster[^>]*>(.*?)<\/figure>/s, html)

      figure_body
    end

    test "with a cover_url, the <img> alt equals GameText.cover_alt/1 for the game and is not empty" do
      game = %{@nivel_experto | cover_url: "https://images.test.invalid/games/1/cover-large.webp", publishers: ["Devir"]}
      expected = GameText.cover_alt(game)

      html = render_component(&GamePreview.preview_body/1, game: game)
      figure = poster_figure(html)

      [img] = Regex.run(~r/<img[^>]*>/, figure)
      assert expected != ""
      assert img =~ ~s(alt="#{expected}")
      refute img =~ ~s(alt="")
    end

    test "the hidden broken-image placeholder carries an image role and the same accessible name" do
      game = %{@nivel_experto | cover_url: "https://images.test.invalid/games/1/cover-large.webp", publishers: ["Devir"]}
      expected = GameText.cover_alt(game)

      html = render_component(&GamePreview.preview_body/1, game: game)
      figure = poster_figure(html)

      [placeholder] = Regex.run(~r/<div[^>]*class="hidden[^"]*"[^>]*>/, figure)
      assert placeholder =~ ~s(role="img")
      assert placeholder =~ ~s(aria-label="#{expected}")
    end

    test "with no cover_url or thumbnail_url, renders no <img> and a visible placeholder carrying an image role and the accessible name" do
      game = %{@nivel_experto | cover_url: nil, publishers: []}
      expected = GameText.cover_alt(game)

      html = render_component(&GamePreview.preview_body/1, game: game)
      figure = poster_figure(html)

      refute figure =~ "<img"

      [placeholder] = Regex.run(~r/<div[^>]*class="flex[^"]*"[^>]*>/, figure)
      assert placeholder =~ ~s(role="img")
      assert placeholder =~ ~s(aria-label="#{expected}")
    end

    test "a game with publishers: [] renders the name-only accessible name form in all three branches" do
      game = %{@nivel_experto | cover_url: nil, publishers: []}

      html = render_component(&GamePreview.preview_body/1, game: game)

      assert html =~ "Portada de #{game.name}"
      refute html =~ "editado por"
    end

    test "a game name containing & renders escaped in the alt attribute and the component renders without raising" do
      game = %{@nivel_experto | name: "Ticket to Ride & Friends", cover_url: nil, publishers: []}

      html = render_component(&GamePreview.preview_body/1, game: game)

      assert html =~ "Ticket to Ride &amp; Friends"
    end
  end

  describe "preview_host/1" do
    test "emits both phx-update=\"ignore\" clone targets plus the sheet's dialog attributes" do
      html = render_component(&GamePreview.preview_host/1, %{})

      assert ~r/phx-update="ignore"/ |> Regex.scan(html) |> length() == 2
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="game-preview-sheet-title")
    end
  end

  # quick 260913-1s5: daisyUI's `.btn-circle` sets `width: var(--size);
  # height: var(--size)`, and `.btn-sm` pins `--size` to 32px — while the
  # `min-h-11` Tailwind utility stretched only the HEIGHT to 44px, leaving a
  # 32x44 oval instead of a circle. Fix: drop `btn-sm`, add `min-w-11`
  # alongside the existing `min-h-11`, matching the filter modal's and the
  # lightbox's own close-button convention (equal-axis 44px floors).
  describe "mobile sheet close button is a true circle (quick 260913-1s5)" do
    test "the sheet close button carries equal-axis 44px circle tokens and no btn-sm" do
      html = render_component(&GamePreview.preview_host/1, %{})

      doc = LazyHTML.from_document(html)

      class_list =
        doc
        |> LazyHTML.query("#game-preview-sheet button[data-sheet-close]")
        |> LazyHTML.attribute("class")
        |> List.first()

      refute is_nil(class_list), "expected #game-preview-sheet button[data-sheet-close] to exist"

      tokens = String.split(class_list)

      assert "pk-sheet-close" in tokens
      assert "btn" in tokens
      assert "btn-circle" in tokens
      assert "min-h-11" in tokens
      assert "min-w-11" in tokens

      refute "btn-sm" in tokens,
             "btn-sm pins --size to 32px, which btn-circle uses for BOTH axes — keeping it " <>
               "alongside min-h-11 is exactly what produced the 32x44 oval this task fixes."
    end

    test "the sheet close icon carries size-5, matching the filter modal / lightbox close convention" do
      html = render_component(&GamePreview.preview_host/1, %{})

      doc = LazyHTML.from_document(html)

      icon_class =
        doc
        |> LazyHTML.query("#game-preview-sheet button[data-sheet-close] span")
        |> LazyHTML.attribute("class")
        |> List.first()

      assert icon_class =~ "size-5"
    end
  end
end
