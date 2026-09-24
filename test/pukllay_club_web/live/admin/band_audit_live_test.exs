defmodule PukllayClubWeb.Admin.BandAuditLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.BandAudit
  alias PukllayClub.Catalog.Game

  # Same idiom as `dashboard_live_test.exs`'s own `box_number/2` — a
  # scoped read of the dashboard box's own number, not a loose full-page
  # text search.
  defp box_number(html, box_id) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("##{box_id} .pk-admin-dash-box__number")
    |> LazyHTML.text()
  end

  describe "the tracer: a mis-banded game appears at /admin/niveles and Pasar a fixes it" do
    setup :register_and_log_in_staff

    test "shows the game name, current band, BGG weight, and implied band; no chevron", %{conn: conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, html} = live(conn, ~p"/admin/niveles")

      assert html =~ "Revisar niveles"
      assert html =~ "Terra Mystica"
      assert html =~ "Ingenio estratega"
      assert html =~ "3.80"
      assert html =~ "Nivel experto"

      refute has_element?(lv, "#mismatch-#{game.id} .pk-admin-row__chevron")
    end

    test "opening the sheet shows Pasar a {nivel} with the target level's meaning, not a bare verb",
         %{conn: conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, _html} = live(conn, ~p"/admin/niveles")

      sheet_html =
        lv
        |> element("#mismatch-#{game.id}")
        |> render_click()

      assert sheet_html =~ "Pasar a Nivel experto"
      assert sheet_html =~ "Reglas largas y decisiones profundas. Para mesas con experiencia."
      assert sheet_html =~ "Mantener Ingenio estratega"
    end

    test "tapping Pasar a removes the row and flashes Nivel corregido.", %{conn: conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, _html} = live(conn, ~p"/admin/niveles")
      lv |> element("#mismatch-#{game.id}") |> render_click()

      html =
        lv
        |> element("button[phx-click='correct'][phx-value-game-id='#{game.id}']")
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

    test "tapping Mantener removes the row and flashes Nivel mantenido., snapshotting a band + timestamp",
         %{conn: conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})

      {:ok, lv, _html} = live(conn, ~p"/admin/niveles")
      lv |> element("#mismatch-#{game.id}") |> render_click()

      html =
        lv
        |> element("button[phx-click='keep'][phx-value-game-id='#{game.id}']")
        |> render_click()

      assert html =~ "Nivel mantenido."
      refute html =~ "Terra Mystica"

      updated = PukllayClub.Repo.get!(Game, game.id)
      assert updated.weight_band == "ingenio_estratega"
      assert updated.band_reviewed_band == "nivel_experto"
      assert %DateTime{} = updated.band_reviewed_at
    end

    test "keep_band/1's snapshot re-surfaces the game once a later bgg_weight implies a new band",
         %{conn: _conn} do
      game = game_fixture(%{name: "Terra Mystica", weight_band: "ingenio_estratega", bgg_weight: 3.8})
      {:ok, _game} = BandAudit.keep_band(game.id)

      assert BandAudit.mismatches() == []

      {:ok, _game} =
        game
        |> Ecto.Changeset.change(bgg_weight: 1.2)
        |> PukllayClub.Repo.update()

      assert [%{id: id}] = BandAudit.mismatches()
      assert id == game.id
    end
  end

  describe "the screen's mismatch count matches the dashboard's Revisar niveles count (no drift)" do
    setup :register_and_log_in_staff

    test "both read BandAudit.mismatches/0's own length — never a second, independent count", %{conn: conn} do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})
      game_fixture(%{weight_band: "descubre_el_hobby", bgg_weight: 3.8})

      {:ok, _lv, niveles_html} = live(conn, ~p"/admin/niveles")
      {:ok, _lv, dashboard_html} = live(conn, ~p"/admin")

      count = BandAudit.count_mismatches()
      assert count == length(BandAudit.mismatches())
      assert niveles_html =~ "#{count} juegos"
      assert box_number(dashboard_html, "dash-box-niveles") == "#{count}"
    end
  end

  describe "positive empty state (E8 empty)" do
    setup :register_and_log_in_staff

    test "with no mismatches shows Todo en orden and no row list", %{conn: conn} do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 2.3})

      {:ok, _lv, html} = live(conn, ~p"/admin/niveles")

      assert html =~ "Todo en orden — no hay discrepancias de nivel."
      refute html =~ "Pasar a"
      refute html =~ "id=\"band-mismatches\""
    end
  end

  describe "role gate" do
    test "GET /admin/niveles with no session redirects to /admin/ingresar", %{conn: conn} do
      conn = get(conn, ~p"/admin/niveles")
      assert redirected_to(conn) == ~p"/admin/ingresar"
    end
  end
end
