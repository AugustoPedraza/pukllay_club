defmodule PukllayClubWeb.Admin.StaffLiveTest do
  # async: false (Rule 3, mirrors 01.8.1-06's EnrichGameWorker precedent): the
  # delivery-failure test below stubs the global, non-process-scoped
  # `:accounts_notifier` Application env key, which would otherwise race any
  # other async test in this file or module attribute reads elsewhere.
  use PukllayClubWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import PukllayClub.AccountsFixtures

  alias PukllayClub.Accounts

  defmodule FailingNotifier do
    @moduledoc false
    def deliver_login_instructions(_user, _url), do: {:error, :simulated_failure}
  end

  describe "the tracer: the owner invites an email and the invitee signs in through it (T-01.8.1-07)" do
    test "invite round trip: owner invites, invitee confirms via the emailed link, and reaches /admin", %{
      conn: conn
    } do
      owner = owner_fixture()
      conn = log_in_user(conn, owner)
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      email = unique_user_email()

      html =
        lv
        |> form("#invite-staff-form", %{email: email})
        |> render_submit()

      assert html =~ "Invitación enviada."
      assert html =~ "Invitación pendiente"

      invited = Accounts.get_user_by_email(email)
      assert invited.role == :staff
      refute invited.confirmed_at

      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(invited, url)
        end)

      invitee_conn = build_conn()
      {:ok, confirm_lv, _html} = live(invitee_conn, ~p"/admin/ingresar/#{token}")

      form = form(confirm_lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)
      invitee_conn = follow_trigger_action(form, invitee_conn)

      assert redirected_to(invitee_conn) == ~p"/admin"

      invitee_conn = get(recycle(invitee_conn), ~p"/admin")
      assert html_response(invitee_conn, 200) =~ "Panel"
    end

    test "a signed-in staff (non-owner) visiting /admin/staff is redirected to /admin", %{conn: conn} do
      conn = log_in_user(conn, staff_fixture())

      assert {:error, {:live_redirect, %{to: "/admin"}}} = live(conn, ~p"/admin/staff")
    end
  end

  describe "invite validation and edge cases (D-32, D-33, UI-SPEC E9)" do
    test "shows the empty state with only the owner in the roster", %{conn: conn} do
      conn = log_in_user(conn, owner_fixture())
      {:ok, _lv, html} = live(conn, ~p"/admin/staff")

      assert html =~ "Todavía no invitaste a nadie más."
      assert html =~ "Dueño"
    end

    test "shows the cap message once 3 staff already exist", %{conn: conn} do
      owner = owner_fixture()
      for _ <- 1..3, do: staff_fixture()
      conn = log_in_user(conn, owner)
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      html =
        lv
        |> form("#invite-staff-form", %{email: unique_user_email()})
        |> render_submit()

      assert html =~ "Ya hay 3 personas en el staff. Quitá a alguien para invitar a otra."
    end

    test "a delivery failure rolls back the invited user and shows the error copy", %{conn: conn} do
      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      Application.put_env(:pukllay_club, :accounts_notifier, FailingNotifier)
      on_exit(fn -> Application.delete_env(:pukllay_club, :accounts_notifier) end)

      email = unique_user_email()

      html =
        lv
        |> form("#invite-staff-form", %{email: email})
        |> render_submit()

      assert html =~ "No pudimos enviarte el email de invitación. Probá de nuevo en unos minutos."
      refute Accounts.get_user_by_email(email)
    end
  end

  describe "remove staff (D-33, T-01.8.1-07 Task 2)" do
    test "Quitar opens a confirmation and Cancelar closes it without deleting", %{conn: conn} do
      staff = staff_fixture()
      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      html = lv |> element("#staff-#{staff.id} button", "Quitar") |> render_click()
      assert html =~ "¿Quitar a #{staff.email} del staff?"
      assert html =~ "Va a perder acceso al panel de inmediato."

      html = lv |> element("button", "Cancelar") |> render_click()
      refute html =~ "¿Quitar"
      assert Accounts.get_user_by_email(staff.email)
    end

    test "confirming Quitar removes the staff member and their session is revoked immediately", %{
      conn: conn
    } do
      staff = staff_fixture()
      staff_conn = log_in_user(build_conn(), staff)

      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      lv |> element("#staff-#{staff.id} button", "Quitar") |> render_click()
      html = lv |> element("#confirm-remove-btn") |> render_click()

      assert html =~ "Quitaste a #{staff.email} del staff."
      refute Accounts.get_user_by_email(staff.email)

      conn2 = get(staff_conn, ~p"/admin")
      assert redirected_to(conn2) == ~p"/admin/ingresar"
    end
  end
end
