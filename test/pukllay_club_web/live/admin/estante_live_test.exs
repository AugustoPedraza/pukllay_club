defmodule PukllayClubWeb.Admin.EstanteLiveTest do
  @moduledoc """
  Proves the phase tracer end to end (01.8.2-01, D-01..D-04, D-08): a
  copy placed at a chosen position renders at that position on
  `/admin/estantes`, staff-only gating holds, and the superseded Asignar
  screen no longer routes.
  """
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog.Shelves

  describe "GET /admin/estantes — signed-out visitor (T-01.8.2-03)" do
    test "is redirected to the login path", %{conn: conn} do
      conn = get(conn, ~p"/admin/estantes")
      assert redirected_to(conn) == ~p"/admin/ingresar"
    end
  end

  describe "GET /admin/estantes — staff (T-01.8.2-03)" do
    setup :register_and_log_in_staff

    test "a staff user can reach the page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")
      assert html =~ "Estantes"
    end
  end

  describe "the rail renders copies in position order (D-04/D-08)" do
    setup :register_and_log_in_staff

    test "covers render in position order and the third cover's accessible name contains 'caja 3 de'",
         %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})

      c0 = copy_fixture(%{game_id: game_fixture(%{name: "Primero"}).id})
      c1 = copy_fixture(%{game_id: game_fixture(%{name: "Segundo"}).id})
      c2 = copy_fixture(%{game_id: game_fixture(%{name: "Tercero"}).id})

      {:ok, _} = Shelves.place_copy(c0.id, shelf.id, 0)
      {:ok, _} = Shelves.place_copy(c1.id, shelf.id, 1)
      {:ok, _} = Shelves.place_copy(c2.id, shelf.id, 2)

      {:ok, _lv, html} = live(conn, ~p"/admin/estantes?estante=#{shelf.id}")

      assert html =~ "Estante Norte"
      assert html =~ ~s(id="estante-copy-#{c0.id}")
      assert html =~ ~s(id="estante-copy-#{c1.id}")
      assert html =~ ~s(id="estante-copy-#{c2.id}")

      # DOM order proves position order: c0's markup precedes c1's, which
      # precedes c2's.
      i0 = html |> :binary.match("estante-copy-#{c0.id}") |> elem(0)
      i1 = html |> :binary.match("estante-copy-#{c1.id}") |> elem(0)
      i2 = html |> :binary.match("estante-copy-#{c2.id}") |> elem(0)
      assert i0 < i1
      assert i1 < i2

      assert html =~ "Tercero, caja 3 de 3"
    end

    test "selects the first estante by default and re-selects it on ?estante=", %{conn: conn} do
      _norte = shelf_fixture(%{name: "Estante Norte"})
      sur = shelf_fixture(%{name: "Estante Sur"})

      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")
      assert html =~ ">Estante Norte<"
      refute html =~ ">Estante Sur<"

      {:ok, _lv, html} = live(conn, ~p"/admin/estantes?estante=#{sur.id}")
      assert html =~ ">Estante Sur<"
      refute html =~ ">Estante Norte<"
    end

    test "an empty estante shows the empty-shelf message", %{conn: conn} do
      shelf_fixture(%{name: "Estante Norte"})
      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")
      assert html =~ "Este estante todavía no tiene juegos."
    end

    test "no estantes at all shows the empty-catalog message", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/estantes")
      assert html =~ "Todavía no hay estantes"
    end

    test "a nonsense ?estante= value falls back to the first estante rather than crashing",
         %{conn: conn} do
      shelf_fixture(%{name: "Estante Norte"})
      {:ok, _lv, html} = live(conn, ~p"/admin/estantes?estante=not-an-id")
      assert html =~ ">Estante Norte<"
    end

    test "live re-reads the rail on an {:estante_updated, _} broadcast", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Norte"})
      copy = copy_fixture(%{game_id: game_fixture(%{name: "Recien llegado"}).id})

      {:ok, lv, html} = live(conn, ~p"/admin/estantes?estante=#{shelf.id}")
      assert html =~ "Este estante todavía no tiene juegos."

      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      assert render(lv) =~ ~s(id="estante-copy-#{copy.id}")
    end
  end

  describe "the superseded Asignar screen is gone (D-08)" do
    # This app's router raises Phoenix.Router.NoRouteError for an unmatched
    # path, which its own custom ErrorHTML (01.1-07's branded 404 template)
    # renders as a normal 404 response rather than surfacing as an
    # `assert_error_sent`/`assert_raise`-visible exception — asserting on
    # `conn.status` directly is the correct check here (mirrors
    # `admin_routes_test.exs`'s own convention).
    test "GET /admin/estantes/1/asignar returns 404", %{conn: conn} do
      assert %{status: 404} = get(conn, "/admin/estantes/1/asignar")
    end
  end
end
