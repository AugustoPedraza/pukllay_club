defmodule PukllayClubWeb.HealthController do
  use PukllayClubWeb, :controller

  @doc """
  Unauthenticated health check for Kamal's proxy health probe.

  Deliberately outside the `:browser` pipeline: no session, no CSRF token,
  no auth. Must stay a trivial, fast, side-effect-free check.
  """
  def up(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "OK")
  end
end
