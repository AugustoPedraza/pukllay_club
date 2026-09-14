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

      {:ok, _lv, html} =
        conn
        |> live(~p"/admin/ingresar/#{token}")
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ "Magic link is invalid or it has expired"
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

      {:ok, _lv, html} =
        conn
        |> live(~p"/admin/ingresar/#{token}")
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ "Magic link is invalid or it has expired"
    end

    test "raises error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> live(~p"/admin/ingresar/invalid-token")
        |> follow_redirect(conn, ~p"/admin/ingresar")

      assert html =~ "Magic link is invalid or it has expired"
    end
  end
end
