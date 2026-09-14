defmodule PukllayClubWeb.Admin.GameLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog

  describe "GameLive.Form — edit screen (D-07, T-01.8.1-21)" do
    setup :register_and_log_in_staff

    test "shows the game's name in the form and its BGG mechanics read-only", %{conn: conn} do
      game = game_fixture(%{name: "Catán", mechanics: ["Dice Rolling", "Hand Management"]})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Catán"
      assert html =~ "Tira dados"
      assert html =~ "Gestión de mano"
    end

    test "submitting a new name and units saves and the public page renders the new name", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Catán Viejo", units: 1})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      lv
      |> form("#game-form", game: %{name: "Catán Nuevo", units: "3"})
      |> render_submit()

      updated = Catalog.get_game!(game.id)
      assert updated.name == "Catán Nuevo"
      assert updated.units == 3

      conn = get(conn, ~p"/juegos/#{updated}")
      assert html_response(conn, 200) =~ "Catán Nuevo"
    end

    test "submitting a blank name re-renders with a field error and does not save", %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html =
        lv
        |> form("#game-form", game: %{name: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert Catalog.get_game!(game.id).name == "Catán"
    end

    test "attempting to submit bgg_weight or mechanics leaves those columns unchanged", %{
      conn: conn
    } do
      game = game_fixture(%{bgg_weight: 2.3, mechanics: ["Dice Rolling"]})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      # A raw "save" push (not the form/3 helper, which validates params
      # against the form's own rendered fields and would refuse a
      # "mechanics" field that doesn't exist on the form) — this is the
      # attacker-controlled-params scenario T-01.8.1-21 exists to cover.
      render_submit(lv, "save", %{
        "game" => %{
          "name" => game.name,
          "bgg_weight" => "4.9",
          "mechanics" => ["Trading"]
        }
      })

      updated = Catalog.get_game!(game.id)
      assert updated.bgg_weight == 2.3
      assert updated.mechanics == ["Dice Rolling"]
    end

    test "a draft game opens in the editor even though its public URL 404s", %{conn: conn} do
      game = game_fixture(%{status: :draft})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      assert html =~ game.name

      assert_raise Ecto.NoResultsError, fn ->
        Catalog.get_published_game!(to_string(game.id))
      end
    end
  end

  describe "GameLive.Form — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      game = game_fixture()

      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} =
               live(conn, ~p"/admin/juegos/#{game.id}/editar")
    end
  end
end
