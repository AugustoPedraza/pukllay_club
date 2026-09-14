defmodule PukllayClubWeb.UserSessionControllerTest do
  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.AccountsFixtures

  alias PukllayClub.Accounts

  setup do
    %{unconfirmed_owner: unconfirmed_owner_fixture(), user: owner_fixture()}
  end

  describe "POST /admin/ingresar - magic link" do
    test "logs the user in", %{conn: conn, user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn =
        post(conn, ~p"/admin/ingresar", %{
          "user" => %{"token" => token}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/admin"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Sesión iniciada."
    end

    test "confirms unconfirmed user", %{conn: conn, unconfirmed_owner: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)
      refute user.confirmed_at

      conn =
        post(conn, ~p"/admin/ingresar", %{
          "user" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/admin"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User confirmed successfully."

      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "redirects to login page when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/ingresar", %{
          "user" => %{"token" => "invalid"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "The link is invalid or it has expired."

      assert redirected_to(conn) == ~p"/admin/ingresar"
    end

    test "creates no session for an email+password submit (T-01.8.1-03)", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, ~p"/admin/ingresar", %{
          "user" => %{"email" => user.email, "password" => "whatever"}
        })

      refute get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/admin/ingresar"
    end
  end

  describe "DELETE /admin/salir" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/admin/salir")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/admin/salir")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
    end
  end
end
