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
      # 01.8.2-11 (D-00a): the page title renames Panel -> Admin.
      assert html_response(invitee_conn, 200) =~ "Admin"
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

  describe "the row, the options sheet and the centred Quitar dialog (D-18, D-19e, D-19f)" do
    test "a staff row has no chevron and opens an options sheet with no Cancelar row", %{
      conn: conn
    } do
      staff = staff_fixture()
      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, html} = live(conn, ~p"/admin/staff")

      doc = LazyHTML.from_document(html)
      row_html = doc |> LazyHTML.query("#staff-#{staff.id}") |> LazyHTML.to_html()
      refute row_html =~ "pk-admin-row__chevron"
      refute row_html =~ "›"

      html = lv |> element("#staff-#{staff.id}") |> render_click()

      assert html =~ "pk-admin-overlay--open"
      assert html =~ staff.email
      assert html =~ "Quitar del staff"

      sheet_doc = LazyHTML.from_document(html)
      sheet_html = sheet_doc |> LazyHTML.query("#staff-options-sheet") |> LazyHTML.to_html()
      refute sheet_html =~ "Cancelar"
    end

    test "the owner's own row is not tappable (no removal option exists for the owner)", %{
      conn: conn
    } do
      owner = owner_fixture()
      conn = log_in_user(conn, owner)
      {:ok, _lv, html} = live(conn, ~p"/admin/staff")

      doc = LazyHTML.from_document(html)

      assert doc |> LazyHTML.query("#staff-#{owner.id}") |> LazyHTML.attribute("phx-click") == []
    end

    test "Quitar del staff in the sheet opens the centred dialog, not another sheet", %{
      conn: conn
    } do
      staff = staff_fixture()
      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      lv |> element("#staff-#{staff.id}") |> render_click()
      html = lv |> element("button", "Quitar del staff") |> render_click()

      assert html =~ "¿Quitar a #{staff.email} del staff?"
      assert html =~ "Va a perder acceso al panel de inmediato."

      doc = LazyHTML.from_document(html)
      # The dialog is open; the options sheet closed when the dialog opened
      # (T-01.8.2-30's "never nested" mitigation holds structurally too —
      # AdminComponentsTest asserts that directly at the component level).
      assert LazyHTML.query(doc, "#confirm-remove-dialog.pk-admin-overlay--open") != []
      sheet = LazyHTML.query(doc, "#staff-options-sheet")

      refute sheet |> LazyHTML.attribute("class") |> List.first() |> to_string() =~
               "pk-admin-overlay--open"
    end

    test "Cancelar in the dialog carries initial focus and closes it without deleting", %{
      conn: conn
    } do
      staff = staff_fixture()
      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      lv |> element("#staff-#{staff.id}") |> render_click()
      html = lv |> element("button", "Quitar del staff") |> render_click()

      doc = LazyHTML.from_document(html)

      cancel_html =
        doc |> LazyHTML.query("#confirm-remove-dialog") |> LazyHTML.to_html()

      cancel_button = cancel_html |> String.split("Cancelar") |> List.first()
      assert cancel_button =~ "autofocus"

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

      lv |> element("#staff-#{staff.id}") |> render_click()
      lv |> element("button", "Quitar del staff") |> render_click()
      html = lv |> element("#confirm-remove-dialog button", "Quitar") |> render_click()

      assert html =~ "Quitaste a #{staff.email} del staff."
      refute Accounts.get_user_by_email(staff.email)

      conn2 = get(staff_conn, ~p"/admin")
      assert redirected_to(conn2) == ~p"/admin/ingresar"
    end

    test "a simulated invite-delivery failure surfaces in the snackbar (D-19b/D-19c)", %{
      conn: conn
    } do
      conn = log_in_user(conn, owner_fixture())
      {:ok, lv, _html} = live(conn, ~p"/admin/staff")

      Application.put_env(:pukllay_club, :accounts_notifier, FailingNotifier)
      on_exit(fn -> Application.delete_env(:pukllay_club, :accounts_notifier) end)

      html =
        lv
        |> form("#invite-staff-form", %{email: unique_user_email()})
        |> render_submit()

      assert html =~ "pk-admin-snackbar"
      assert html =~ "No pudimos enviarte el email de invitación. Probá de nuevo en unos minutos."
    end
  end

  describe "D-18 composition — no hand-rolled chrome" do
    test "the page contains no modal-open/modal-action/btn- markup", %{conn: conn} do
      conn = log_in_user(conn, owner_fixture())
      staff = staff_fixture()
      {:ok, lv, html} = live(conn, ~p"/admin/staff")

      refute html =~ "modal-open"
      refute html =~ "modal-action"
      refute html =~ "btn-error"
      refute html =~ "btn-ghost"
      refute html =~ "btn-primary"
      refute html =~ "btn-outline"

      html = lv |> element("#staff-#{staff.id}") |> render_click()
      refute html =~ "modal-open"
      refute html =~ "modal-action"
    end
  end
end
