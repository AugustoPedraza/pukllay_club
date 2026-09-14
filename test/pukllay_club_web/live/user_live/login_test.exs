defmodule PukllayClubWeb.UserLive.LoginTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar")

      assert html =~ "Ingresar al panel"
      assert html =~ "Enviarme el link"
    end
  end

  describe "user login - magic link" do
    test "sends magic link email when user exists", %{conn: conn} do
      user = owner_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/ingresar")

      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ "If your email is in our system"

      assert PukllayClub.Repo.get_by!(PukllayClub.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end

    test "does not disclose if user is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/ingresar")

      {:ok, _lv, html} =
        lv
        |> form("#login_form_magic", user: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ "If your email is in our system"
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
