defmodule PukllayClubWeb.Admin.BandAuditLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game

  describe "the tracer: a mis-banded game appears at /admin/niveles and Corregir fixes it" do
    setup :register_and_log_in_staff

    test "shows the game name, current band, BGG weight, and implied band", %{conn: conn} do
      game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, _lv, html} = live(conn, ~p"/admin/niveles")

      assert html =~ "Revisar niveles"
      assert html =~ "Terra Mystica"
      assert html =~ "Ingenio estratega"
      assert html =~ "3.80"
      assert html =~ "Nivel experto"
      assert html =~ "badge-warning"
    end

    test "pressing Corregir removes the row and flashes Nivel corregido.", %{conn: conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, _html} = live(conn, ~p"/admin/niveles")

      html =
        lv
        |> element("button[phx-value-game-id='#{game.id}']", "Corregir")
        |> render_click()

      assert html =~ "Nivel corregido."
      refute html =~ "Terra Mystica"

      updated = PukllayClub.Repo.get!(Game, game.id)
      assert updated.weight_band == "nivel_experto"
    end

    test "a non-integer game-id in the correct event is ignored", %{conn: conn} do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, _html} = live(conn, ~p"/admin/niveles")

      html = render_click(lv, "correct", %{"game-id" => "not-an-id"})

      refute html =~ "Nivel corregido."
    end
  end

  describe "Mantener stores a drift-aware override (D-30)" do
    setup :register_and_log_in_staff

    test "pressing Mantener removes the row and flashes Nivel mantenido.", %{conn: conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, _html} = live(conn, ~p"/admin/niveles")

      html =
        lv
        |> element("button[phx-value-game-id='#{game.id}']", "Mantener")
        |> render_click()

      assert html =~ "Nivel mantenido."
      refute html =~ "Terra Mystica"

      updated = PukllayClub.Repo.get!(Game, game.id)
      assert updated.weight_band == "ingenio_estratega"
      assert updated.band_reviewed_band == "nivel_experto"
    end
  end

  describe "positive empty state (E8 empty)" do
    setup :register_and_log_in_staff

    test "with no mismatches shows Todo en orden and no table or action buttons", %{conn: conn} do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 2.3})

      {:ok, _lv, html} = live(conn, ~p"/admin/niveles")

      assert html =~ "Todo en orden — no hay discrepancias de nivel."
      refute html =~ "Corregir"
      refute html =~ "Mantener"
      refute html =~ "<table"
    end
  end

  describe "role gate" do
    test "GET /admin/niveles with no session redirects to /admin/ingresar", %{conn: conn} do
      conn = get(conn, ~p"/admin/niveles")
      assert redirected_to(conn) == ~p"/admin/ingresar"
    end
  end
end
