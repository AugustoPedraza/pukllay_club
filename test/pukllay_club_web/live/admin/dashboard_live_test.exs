defmodule PukllayClubWeb.Admin.DashboardLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.AccountsFixtures
  import PukllayClub.CatalogFixtures

  alias PukllayClub.Accounts
  alias PukllayClub.Catalog.Shelves

  describe "the tracer: /admin/ingresar magic link to a staff-gated /admin (T-01.8.1-01)" do
    test "an owner requests a magic link, confirms it, and lands on /admin", %{conn: conn} do
      user = "owner@example.com" |> Accounts.create_owner() |> elem(1)

      {:ok, login_lv, _html} = live(conn, ~p"/admin/ingresar")

      {:ok, _login_lv, _html} =
        login_lv
        |> form("#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/ingresar")

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, confirm_lv, _html} = live(conn, ~p"/admin/ingresar/#{token}")

      form = form(confirm_lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/admin"

      conn = get(recycle(conn), ~p"/admin")
      assert html_response(conn, 200) =~ "Panel"
    end

    test "GET /admin with no session redirects to /admin/ingresar", %{conn: conn} do
      conn = get(conn, ~p"/admin")
      assert redirected_to(conn) == ~p"/admin/ingresar"
    end
  end

  describe "role gate (D-33, T-01.8.1-02)" do
    test "a signed-in non-staff scope is rejected by the :require_staff_user plug", %{
      conn: conn
    } do
      non_staff = %Accounts.User{id: -1, role: nil}

      conn =
        conn
        |> init_test_session(%{})
        |> Plug.Conn.assign(:current_scope, Accounts.Scope.for_user(non_staff))
        |> PukllayClubWeb.UserAuth.require_staff_user([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "a signed-in non-staff scope is rejected by the :require_staff on_mount hook" do
      non_staff = %Accounts.User{id: -1, role: nil}

      socket = %Phoenix.LiveView.Socket{
        endpoint: PukllayClubWeb.Endpoint,
        assigns: %{
          __changed__: %{},
          flash: %{},
          current_scope: Accounts.Scope.for_user(non_staff)
        }
      }

      assert {:halt, _socket} =
               PukllayClubWeb.UserAuth.on_mount(:require_staff, %{}, %{}, socket)
    end
  end

  describe "Juegos card (D-35, D-09 Task 2)" do
    setup :register_and_log_in_staff

    test "links to /admin/juegos and shows a borradores badge when N > 0", %{conn: conn} do
      game_fixture(%{status: :draft})
      game_fixture(%{status: :draft})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Juegos"
      assert html =~ ~s(href="/admin/juegos")
      assert html =~ "2 borradores"
    end

    test "omits the badge when there are no drafts", %{conn: conn} do
      game_fixture(%{status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Juegos"
      refute html =~ "borradores"
    end
  end

  describe "Estantes card (D-35, 01.8.1-09)" do
    setup :register_and_log_in_staff

    test "shows a badge-warning N/total ubicados while games remain unplaced", %{conn: conn} do
      shelf = PukllayClub.ShelvesFixtures.shelf_fixture()
      placed = game_fixture()
      _unplaced = game_fixture()
      {:ok, _game, nil} = Shelves.assign_game(placed.id, shelf.id)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Estantes"
      assert html =~ ~s(href="/admin/estantes")
      assert html =~ "1/2 ubicados"
      assert html =~ "badge-warning"
    end

    test "omits the badge once every game is placed", %{conn: conn} do
      shelf = PukllayClub.ShelvesFixtures.shelf_fixture()
      game = game_fixture()
      {:ok, _game, nil} = Shelves.assign_game(game.id, shelf.id)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Estantes"
      refute html =~ "ubicados"
    end
  end

  describe "Secciones card (D-35, 01.8.1-12)" do
    setup :register_and_log_in_staff

    test "links to /admin/secciones with no pending badge", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Secciones"
      assert html =~ ~s(href="/admin/secciones")
    end

    test "renders third, between Estantes and Staff (D-35 fixed card order)", %{conn: conn} do
      conn = log_in_user(conn, "owner@example.com" |> Accounts.create_owner() |> elem(1))
      {:ok, _lv, html} = live(conn, ~p"/admin")

      juegos_at = html |> :binary.match("Juegos") |> elem(0)
      estantes_at = html |> :binary.match("Estantes") |> elem(0)
      secciones_at = html |> :binary.match("Secciones") |> elem(0)
      staff_at = html |> :binary.match("Staff") |> elem(0)

      assert juegos_at < estantes_at
      assert estantes_at < secciones_at
      assert secciones_at < staff_at
    end
  end

  describe "Staff card (D-35, T-01.8.1-07 Task 2)" do
    test "renders for the owner", %{conn: conn} do
      conn = log_in_user(conn, "owner@example.com" |> Accounts.create_owner() |> elem(1))
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Staff"
      assert html =~ ~s(href="/admin/staff")
    end

    test "does not render for a staff member" do
      staff = staff_fixture()
      conn = log_in_user(build_conn(), staff)
      {:ok, _lv, html} = live(conn, ~p"/admin")

      refute html =~ "/admin/staff"
    end
  end

  describe "User.staff?/1 (T-01.8.1-02)" do
    test "true for :owner and :staff, false for nil" do
      assert Accounts.User.staff?(%Accounts.User{role: :owner})
      assert Accounts.User.staff?(%Accounts.User{role: :staff})
      refute Accounts.User.staff?(%Accounts.User{role: nil})
      refute Accounts.User.staff?(nil)
    end
  end
end
