defmodule PukllayClubWeb.AdminRoutesTest do
  @moduledoc """
  Negative-route coverage proving no public registration/password/settings
  path exists (D-31, D-32, T-01.8.1-03) — see also the affirmative admin
  route coverage in `PukllayClubWeb.Admin.DashboardLiveTest`.
  """
  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.AccountsFixtures

  describe "no public registration/password/settings path exists" do
    # This app's router raises Phoenix.Router.NoRouteError for an unmatched
    # path, which its own custom ErrorHTML (01.1-07's branded 404 template)
    # renders as a normal 404 response rather than surfacing as an
    # `assert_error_sent`-visible exception — asserting on `conn.status`
    # directly is the correct check here, not `assert_error_sent`.
    test "GET /users/register returns 404", %{conn: conn} do
      assert %{status: 404} = get(conn, "/users/register")
    end

    test "GET /users/log-in returns 404", %{conn: conn} do
      assert %{status: 404} = get(conn, "/users/log-in")
    end

    test "GET /users/settings returns 404", %{conn: conn} do
      assert %{status: 404} = get(conn, "/users/settings")
    end

    test "an email+password POST to /admin/ingresar never creates a session", %{conn: conn} do
      user = owner_fixture()

      conn =
        post(conn, ~p"/admin/ingresar", %{
          "user" => %{"email" => user.email, "password" => "whatever"}
        })

      refute get_session(conn, :user_token)

      conn = get(recycle(conn), ~p"/")
      refute get_session(conn, :user_token)
    end
  end
end
