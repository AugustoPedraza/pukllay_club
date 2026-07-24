defmodule PukllayClubWeb.PageController do
  use PukllayClubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
