defmodule PukllayClubWeb.GamePreviewTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PukllayClub.Catalog.Game
  alias PukllayClubWeb.GamePreview

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

    test "the CTA is an outlined link to the game's detail page and carries no filled-button class" do
      html = render_component(&GamePreview.preview_body/1, game: @nivel_experto)

      assert html =~ ~s(href="/juegos/1")
      assert html =~ "btn-outline"
      refute html =~ "btn btn-primary btn-sm"
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
end
