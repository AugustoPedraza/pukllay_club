defmodule PukllayClubWeb.UserLive.LoginTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.AccountsFixtures
  import Swoosh.TestAssertions

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar")

      assert html =~ "Ingresar al panel"
      assert html =~ "Enviarme el link"
    end
  end

  @neutral_copy "Si el email es del staff, te llegó un link para entrar. Revisá tu casilla."

  describe "user login - magic link (D-31, T-01.8.1-04)" do
    test "sends exactly one magic link email for a staff address and shows neutral copy", %{
      conn: conn
    } do
      user = owner_fixture()
      # `owner_fixture/1` itself sends one invite email as part of confirming
      # the owner via the real magic-link round trip — drain it so the
      # assertion below only sees the email this test's own action sends.
      flush_emails()

      {:ok, lv, _html} = live(conn, ~p"/admin/ingresar")

      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ @neutral_copy

      assert_email_sent(subject: "Tu link para entrar a Pukllay Club")

      assert PukllayClub.Repo.get_by!(PukllayClub.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end

    test "sends no email and shows the identical neutral copy for an unknown address", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/ingresar")

      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", user: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ @neutral_copy
      assert_no_email_sent()
    end
  end

  defp flush_emails do
    receive do
      {:email, _} -> flush_emails()
    after
      0 -> :ok
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = owner_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with email filled in", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar")

      assert html =~ "Ingresar al panel"

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_magic_email" value="#{user.email}")
    end
  end
end
