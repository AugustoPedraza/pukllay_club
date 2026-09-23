defmodule PukllayClubWeb.Admin.DashboardLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.AccountsFixtures
  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Accounts
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Repo

  # Reads a box's own number/meter/pending-pill via its stable id
  # (`dash-box-{juegos,estantes,web,niveles,staff}`, dashboard_live.ex),
  # scoped so an assertion can never accidentally match a substring
  # elsewhere on the page (the tab bar's own "Web" tab label, in
  # particular — see the D-00a rename test below).
  defp box_number(html, box_id) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("##{box_id} .pk-admin-dash-box__number")
    |> LazyHTML.text()
  end

  defp box_has_meter?(html, box_id) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query("##{box_id} .pk-admin-dash-box__meter")
    |> Enum.any?()
  end

  defp box_href(html, box_id) do
    [href] =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query("##{box_id}")
      |> LazyHTML.attribute("href")

    href
  end

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
      # 01.8.2-11 (D-00a): the page title renames Panel -> Admin.
      assert html_response(conn, 200) =~ "Admin"
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

  describe "060-B boxes: every box shows a real numeric count, never blank" do
    setup :register_and_log_in_staff

    test "the four non-owner boxes each render a numeric count element", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      for box_id <- ~w(dash-box-juegos dash-box-estantes dash-box-web dash-box-niveles) do
        number = box_number(html, box_id)
        assert number =~ ~r/^\d/, "#{box_id}'s number (#{inspect(number)}) is not numeric"
      end
    end

    test "no font-display, no btn- class, no badge- class in this page's own <main> content", %{
      conn: conn
    } do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      # Scoped to <main> — the shared header/drawer/tab-bar chrome around it
      # is Scope B/pre-existing (e.g. the header brand wordmark's own
      # `font-display`) and out of this plan's file scope; the plan's own
      # <verify> greps `dashboard_live.ex`'s SOURCE directly for this, this
      # test is the rendered-output counterpart of that same guard.
      main_html = html |> LazyHTML.from_document() |> LazyHTML.query("main") |> LazyHTML.to_html()

      refute main_html =~ "font-display"
      refute main_html =~ "btn-"
      refute main_html =~ "badge-"
    end
  end

  describe "Juegos box (D-35, D-09 Task 2)" do
    setup :register_and_log_in_staff

    test "links to /admin/juegos, shows the total game count, and a pending pill when drafts exist",
         %{conn: conn} do
      game_fixture(%{status: :draft})
      game_fixture(%{status: :draft})
      game_fixture(%{status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_href(html, "dash-box-juegos") == "/admin/juegos"
      assert box_number(html, "dash-box-juegos") == "3"
      assert html =~ "2 borradores"
    end

    test "omits the pending pill when there are no drafts", %{conn: conn} do
      game_fixture(%{status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_number(html, "dash-box-juegos") == "1"
      refute html =~ "borradores"
      refute html =~ "pk-admin-pending-pill"
    end
  end

  describe "Estantes box (D-35, plan 01.8.2-11 copy-level rewrite)" do
    setup :register_and_log_in_staff

    test "the pending count equals length(Shelves.unplaced_copies/0), and a meter renders", %{
      conn: conn
    } do
      shelf = shelf_fixture()
      placed_game = game_fixture()
      placed_copy = copy_fixture(%{game_id: placed_game.id})
      {:ok, _} = Shelves.place_copy(placed_copy.id, shelf.id, 0)

      unplaced_game = game_fixture()
      _unplaced_copy = copy_fixture(%{game_id: unplaced_game.id})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      expected_unplaced = length(Shelves.unplaced_copies())
      assert expected_unplaced == 1
      assert html =~ "#{expected_unplaced} sin ubicar"
      assert box_has_meter?(html, "dash-box-estantes")
      # 1 placed of 2 total copies -> 50%
      assert box_number(html, "dash-box-estantes") == "50%"
    end

    test "omits the pending pill once every copy is placed", %{conn: conn} do
      shelf = shelf_fixture()
      game = game_fixture()
      copy = copy_fixture(%{game_id: game.id})
      {:ok, _} = Shelves.place_copy(copy.id, shelf.id, 0)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_number(html, "dash-box-estantes") == "100%"
      refute html =~ "sin ubicar"
      refute html =~ "pk-admin-pending-pill"
    end

    test "renders a 0% meter and no pending pill with zero copies in the club", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_number(html, "dash-box-estantes") == "0%"
      assert box_has_meter?(html, "dash-box-estantes")
      refute html =~ "pk-admin-pending-pill"
    end
  end

  describe "Web box (D-00a rename from Secciones; 01.8.1-12)" do
    setup :register_and_log_in_staff

    test "renders the Web label, links to /admin/secciones, and shows a real section count", %{
      conn: conn
    } do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_href(html, "dash-box-web") == "/admin/secciones"
      assert box_number(html, "dash-box-web") =~ ~r/^\d+$/

      # Scoped to the dashboard's own card grid — the shared tab bar's
      # unrelated `aria-label="Secciones de Admin"` (a nav landmark
      # description, not this box's label) lives outside #admin-cards.
      cards_html =
        html |> LazyHTML.from_document() |> LazyHTML.query("#admin-cards") |> LazyHTML.to_html()

      refute cards_html =~ "Secciones"
    end

    test "renders third, between Estantes and Staff (D-35 fixed card order)", %{conn: conn} do
      conn = log_in_user(conn, "owner@example.com" |> Accounts.create_owner() |> elem(1))
      {:ok, _lv, html} = live(conn, ~p"/admin")

      juegos_at = html |> :binary.match(~s(id="dash-box-juegos")) |> elem(0)
      estantes_at = html |> :binary.match(~s(id="dash-box-estantes")) |> elem(0)
      web_at = html |> :binary.match(~s(id="dash-box-web")) |> elem(0)
      staff_at = html |> :binary.match(~s(id="dash-box-staff")) |> elem(0)

      assert juegos_at < estantes_at
      assert estantes_at < web_at
      assert web_at < staff_at
    end
  end

  describe "Revisar niveles box (D-35, 01.8.1-13)" do
    setup :register_and_log_in_staff

    test "shows the mismatch count as its number and a pending pill when count > 0", %{
      conn: conn
    } do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 3.8})
      game_fixture(%{weight_band: "descubre_el_hobby", bgg_weight: 4.0})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_href(html, "dash-box-niveles") == "/admin/niveles"
      assert box_number(html, "dash-box-niveles") == "2"
      assert html =~ "no coinciden con BGG"
    end

    test "omits the pending pill when there are no mismatches", %{conn: conn} do
      game_fixture(%{weight_band: "ingenio_estratega", bgg_weight: 2.3})

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_number(html, "dash-box-niveles") == "0"
      refute html =~ "no coinciden con BGG"
      refute html =~ "pk-admin-pending-pill"
    end

    test "renders fourth, between Web and Staff (D-35 fixed card order)", %{conn: conn} do
      conn = log_in_user(conn, "owner@example.com" |> Accounts.create_owner() |> elem(1))
      {:ok, _lv, html} = live(conn, ~p"/admin")

      web_at = html |> :binary.match(~s(id="dash-box-web")) |> elem(0)
      niveles_at = html |> :binary.match(~s(id="dash-box-niveles")) |> elem(0)
      staff_at = html |> :binary.match(~s(id="dash-box-staff")) |> elem(0)

      assert web_at < niveles_at
      assert niveles_at < staff_at
    end

    test "a staff member sees the first four cards (no owner-only Staff card)" do
      staff = staff_fixture()
      conn = log_in_user(build_conn(), staff)
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ ~s(id="dash-box-juegos")
      assert html =~ ~s(id="dash-box-estantes")
      assert html =~ ~s(id="dash-box-web")
      assert html =~ ~s(id="dash-box-niveles")
      refute html =~ "/admin/staff"
    end
  end

  describe "Staff box (D-35, T-01.8.1-07 Task 2, plan 01.8.2-11)" do
    test "renders for the owner with a real staff count and a pending-invite pill", %{conn: conn} do
      owner = "owner@example.com" |> Accounts.create_owner() |> elem(1)
      conn = log_in_user(conn, owner)
      staff_fixture()
      invited = staff_fixture()
      invited |> Ecto.Changeset.change(confirmed_at: nil) |> Repo.update!()

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert box_href(html, "dash-box-staff") == "/admin/staff"
      assert box_number(html, "dash-box-staff") == "3"
      assert html =~ "1 invitación pendiente"
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

  # Task 3, plan 01.8.2-09 (D-00b): the footer never renders on /admin — the
  # positive counterpart (a public page still renders it) lives in
  # layouts_test.exs, since this file only ever reaches admin routes.
  describe "no footer on /admin (01.8.2-09 Task 3, D-00b)" do
    test "GET /admin as staff renders no footer markup" do
      staff = staff_fixture()
      conn = log_in_user(build_conn(), staff)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      refute html =~ "<footer"
      refute html =~ "pk-footer"
    end

    test "GET /admin/ingresar (the admin login page) also renders no footer markup" do
      {:ok, _lv, html} = live(build_conn(), ~p"/admin/ingresar")

      refute html =~ "<footer"
      refute html =~ "pk-footer"
    end
  end

  # Task 3 (D-00b): Salir moved into the drawer's account section
  # (layouts_test.exs covers the drawer side); the loose page-level link
  # this dashboard used to render is gone.
  describe "the loose Salir link is gone from the dashboard page (01.8.2-09 Task 3, D-00b)" do
    test "GET /admin as staff renders no standalone Salir link outside the drawer" do
      staff = staff_fixture()
      conn = log_in_user(build_conn(), staff)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      doc = LazyHTML.from_document(html)

      # Scoped to OUTSIDE the drawer component: the drawer itself legitimately
      # renders a "Salir" link (D-00b's new home for it) — this guard is
      # against a SECOND, loose copy on the dashboard body itself, the exact
      # markup Task 3 deleted from dashboard_live.ex.
      body_without_drawer_html =
        doc
        |> LazyHTML.query("main")
        |> LazyHTML.to_html()

      refute body_without_drawer_html =~ ~s(href="/admin/salir")
      refute body_without_drawer_html =~ "Salir"

      # The drawer itself still carries exactly one Salir link.
      drawer_html = doc |> LazyHTML.query("#pk-nav-drawer") |> LazyHTML.to_html()
      assert drawer_html =~ ~s(href="/admin/salir")
    end
  end
end
