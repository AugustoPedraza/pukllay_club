defmodule PukllayClubWeb.HealthControllerTest do
  use PukllayClubWeb.ConnCase, async: true

  test "GET /up returns 200 with a plain-text OK body", %{conn: conn} do
    conn = get(conn, ~p"/up")

    assert response(conn, 200) == "OK"
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
  end

  test "GET /up sets no session cookie", %{conn: conn} do
    conn = get(conn, ~p"/up")

    refute conn.resp_cookies["_pukllay_club_key"]
  end
end
