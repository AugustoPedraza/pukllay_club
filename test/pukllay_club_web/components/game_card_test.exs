defmodule PukllayClubWeb.GameCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PukllayClub.Catalog.Game
  alias PukllayClubWeb.GameCard
  alias PukllayClubWeb.GameText

  @with_thumbnail %Game{
    id: 1,
    name: "Catán",
    publishers: ["Devir"],
    thumbnail_url: "https://images.test.invalid/games/1/cover-thumb.webp"
  }

  @no_cover %Game{id: 2, name: "Terraforming Mars", publishers: []}

  defp figure_html(html) do
    [_, figure_body] = Regex.run(~r/<figure[^>]*class="pk-card-poster[^>]*>(.*?)<\/figure>/s, html)
    figure_body
  end

  describe "game_card/1 — cover with a thumbnail (SEO-02, D-10)" do
    setup do
      html = render_component(&GameCard.game_card/1, id: "game-card-1", game: @with_thumbnail)
      %{html: html, figure: figure_html(html)}
    end

    test "the <img> alt equals GameText.cover_alt/1 for the game, and is not empty", %{figure: figure} do
      expected = GameText.cover_alt(@with_thumbnail)

      [img] = Regex.run(~r/<img[^>]*>/, figure)

      assert expected != ""
      assert img =~ ~s(alt="#{expected}")
      refute img =~ ~s(alt="")
    end

    test "the hidden broken-image placeholder carries an image role and the same accessible name", %{figure: figure} do
      expected = GameText.cover_alt(@with_thumbnail)

      # Scoped to the hidden placeholder div (the one gated on @game.thumbnail_url
      # being truthy, distinct from the nil-cover branch below).
      [placeholder] = Regex.run(~r/<div[^>]*class="hidden[^"]*"[^>]*>/, figure)

      assert placeholder =~ ~s(role="img")
      assert placeholder =~ ~s(aria-label="#{expected}")
    end

    test "the js-cover-fallback hook class and hidden/flex visibility contract are unchanged", %{figure: figure} do
      assert figure =~ "js-cover-fallback"
      assert figure =~ ~r/<div[^>]*class="hidden/
    end
  end

  describe "game_card/1 — no cover URL at all (SEO-02, ROADMAP success criterion 5)" do
    test "renders no <img>, and a visible placeholder carrying an image role and the accessible name" do
      html = render_component(&GameCard.game_card/1, id: "game-card-2", game: @no_cover)
      figure = figure_html(html)
      expected = GameText.cover_alt(@no_cover)

      refute figure =~ "<img"

      [placeholder] = Regex.run(~r/<div[^>]*class="flex[^"]*"[^>]*>/, figure)
      assert placeholder =~ ~s(role="img")
      assert placeholder =~ ~s(aria-label="#{expected}")
    end

    test "a game with publishers: [] renders the name-only accessible name form" do
      html = render_component(&GameCard.game_card/1, id: "game-card-2", game: @no_cover)

      assert html =~ "Portada de Terraforming Mars"
      refute html =~ "editado por"
    end
  end

  describe "game_card/1 — escaping (T-01.8-06)" do
    test "a game name containing & renders escaped in the alt attribute and the component renders without raising" do
      game = %Game{id: 3, name: "Ticket to Ride & Friends", publishers: []}

      html = render_component(&GameCard.game_card/1, id: "game-card-3", game: game)

      assert html =~ "Ticket to Ride &amp; Friends"
      refute html =~ "Ticket to Ride & Friends\""
    end
  end

  describe "GameCard moduledoc (SEO-02 reversal record)" do
    test "no longer claims the empty alt attribute is the intended accessibility choice" do
      source = File.read!(Path.expand("../../../lib/pukllay_club_web/components/game_card.ex", __DIR__))

      refute source =~ "The image's `alt` is empty because"
      assert source =~ "SEO-02"
      assert source =~ "Reversal"
    end
  end
end
