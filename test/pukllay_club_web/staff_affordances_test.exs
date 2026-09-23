defmodule PukllayClubWeb.StaffAffordancesTest do
  @moduledoc """
  Visitor vs. staff public-header and detail-page affordance coverage
  (D-34) — every `<Layouts.app` call site now carries `current_scope`, and
  `Layouts.header_inner/1`/`nav_drawer/1` render the Admin link/row, and
  `CatalogLive.Show` its Editar button, only for a staff session.
  """
  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

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

  describe "D-14 tab bar suppression (01.8.2-10 Task 3): the game detail page already owns the screen's bottom" do
    setup :register_and_log_in_staff

    test "a signed-in staff member sees no tab bar on the game detail page, and the reserve CTA is unobscured",
         %{conn: conn} do
      game = game_fixture()

      html = conn |> get(~p"/juegos/#{game}") |> html_response(200)

      refute html =~ "pk-admin-tab-bar"
      # the reserve CTA itself renders untouched — nothing in this plan
      # gates it, and its presence here proves the page still renders its
      # own bottom-fixed surface unmodified.
      assert html =~ "detail-cta-bar"
      assert html =~ "pk-mobile-cta-bar"
    end

    test "the same staff member still sees the tab bar on /admin (suppression is call-site-scoped, not global)",
         %{conn: conn} do
      html = conn |> get(~p"/admin") |> html_response(200)

      assert html =~ "pk-admin-tab-bar"
    end
  end

  describe "D-15 regression guard (01.8.2-10 Task 3): shelf/copy location stays inside /admin" do
    setup :register_and_log_in_staff

    test "a staff-authenticated request to a public game page renders no estante name, position, or copy count",
         %{conn: conn} do
      game = game_fixture()
      shelf = shelf_fixture(%{name: "D15-marker-#{System.unique_integer([:positive])}"})
      _copy = copy_fixture(%{game_id: game.id, shelf_id: shelf.id, position: 3})

      html = conn |> get(~p"/juegos/#{game}") |> html_response(200)

      # The shelf's own name is the sharpest possible leak signal — if it
      # appears anywhere in this page's markup, location data crossed the
      # D-15 boundary onto a public surface.
      refute html =~ shelf.name
      refute html =~ "Sin lugar"
      refute html =~ "copia 1 de"
      refute html =~ "caja "
    end
  end

  describe "an anonymous visitor's public markup is unaffected by the D-14 tab-bar-suppress work (01.8.2-10 Task 3)" do
    test "/juegos/:id contains none of the tab bar's identifying markup, with or without a bottom-owning surface on the page",
         %{conn: conn} do
      game = game_fixture()

      html = conn |> get(~p"/juegos/#{game}") |> html_response(200)

      refute html =~ "pk-admin-tab-bar"
      refute html =~ "pk-admin-tab-badge"
    end
  end
end
