defmodule PukllayClubWeb.StaffAffordancesTest do
  @moduledoc """
  Visitor vs. staff public-header and detail-page affordance coverage
  (D-34) — every `<Layouts.app` call site now carries `current_scope`, and
  `Layouts.header_inner/1`/`nav_drawer/1` render the Admin link/row, and
  `CatalogLive.Show` its Editar button, only for a staff session.
  """
  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures

  describe "visitor (no session)" do
    test "/ contains no link to /admin and no Admin drawer row", %{conn: conn} do
      html = conn |> get(~p"/") |> html_response(200)

      refute html =~ ~s(href="/admin")
      refute html =~ "pk-nav-admin"
    end

    test "/juegos/:id contains no Editar link", %{conn: conn} do
      game = game_fixture()

      html = conn |> get(~p"/juegos/#{game}") |> html_response(200)

      refute html =~ "Editar"
      refute html =~ ~s(href="/admin")
    end

    test "/club renders for a visitor with no crash from a missing current_scope", %{conn: conn} do
      html = conn |> get(~p"/club") |> html_response(200)

      refute html =~ ~s(href="/admin")
    end
  end

  describe "staff session" do
    setup :register_and_log_in_staff

    test "/ renders a header Admin link and a drawer Admin row", %{conn: conn} do
      html = conn |> get(~p"/") |> html_response(200)

      assert html =~ ~s(href="/admin")
      assert html =~ "pk-nav-admin"
      assert html =~ ~s(aria-label="Admin")
      assert html =~ "Admin"
    end

    test "/juegos/:id renders an Editar link to the admin editor", %{conn: conn} do
      game = game_fixture()

      html = conn |> get(~p"/juegos/#{game}") |> html_response(200)

      assert html =~ "Editar"
      assert html =~ ~s(href="/admin/juegos/#{game.id}/editar")
    end
  end
end
