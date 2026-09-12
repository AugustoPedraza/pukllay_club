defmodule PukllayClubWeb.ErrorHTMLTest do
  use PukllayClubWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(PukllayClubWeb.ErrorHTML, "404", "html", [])

    assert html =~ "Juego no encontrado"
    assert html =~ "Este juego no existe o fue removido de la ludoteca."
    assert html =~ "Volver a la ludoteca"
    refute html == "Not Found"
    refute html =~ "Exception"
    refute html =~ "stacktrace"
    refute html =~ "Ecto"
  end

  test "renders 500.html" do
    assert render_to_string(PukllayClubWeb.ErrorHTML, "500", "html", []) ==
             "Internal Server Error"
  end
end
