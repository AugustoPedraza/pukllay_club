defmodule PukllayClubWeb.UserLive.ConfirmationTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.AccountsFixtures

  alias PukllayClub.Accounts

  setup do
    %{unconfirmed_owner: unconfirmed_owner_fixture(), confirmed_owner: owner_fixture()}
  end

  describe "Confirm user" do
    test "renders confirmation page for unconfirmed user", %{
      conn: conn,
      unconfirmed_owner: user
    } do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar/#{token}")
      assert html =~ "Entrar"
    end

    test "renders login page for confirmed user", %{conn: conn, confirmed_owner: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar/#{token}")
      assert html =~ "Entrar"
    end

    test "confirms the given token once and lands the owner on /admin", %{
      conn: conn,
      unconfirmed_owner: user
    } do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/admin/ingresar/#{token}")

      form = form(lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Sesión iniciada."

      assert Accounts.get_user!(user.id).confirmed_at
      # we are logged in now
      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/admin"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar/#{token}")

      assert html =~ "El link venció o ya se usó. Pedí uno nuevo."
      assert html =~ "Enviarme otro link"
    end

    test "logs confirmed user in without changing confirmed_at", %{
      conn: conn,
      confirmed_owner: user
    } do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/admin/ingresar/#{token}")

      form = form(lv, "#login_form", %{"user" => %{"token" => token}})
      render_submit(form)

      conn = follow_trigger_action(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Sesión iniciada."

      assert Accounts.get_user!(user.id).confirmed_at == user.confirmed_at
      assert redirected_to(conn) == ~p"/admin"

      # log out, new conn
      conn = build_conn()

      {:ok, _lv, html} = live(conn, ~p"/admin/ingresar/#{token}")

      assert html =~ "El link venció o ya se usó. Pedí uno nuevo."
      assert html =~ "Enviarme otro link"
    end

    test "renders the expired-link state for an invalid token (UI-SPEC E11)", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/ingresar/invalid-token")

      assert html =~ "El link venció o ya se usó. Pedí uno nuevo."

      {:ok, _login_lv, login_html} =
        lv
        |> element("a", "Enviarme otro link")
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert login_html =~ "Ingresar al panel"
    end
  end
end
