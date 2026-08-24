defmodule PukllayClubWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.

  01.1-07: only 404 gets a real template (`404.html.heex`, the branded
  "Juego no encontrado" page). A 500 template is deliberately NOT added —
  an error page that depends on more application code (more components,
  more template compilation) is exactly the page most likely to fail when
  the application is already failing, so 500 (and every other status)
  keeps the plain-status-string fallback below, unconditionally reachable
  since `embed_templates` only ever defines a `render/2` clause for
  templates that exist on disk.
  """
  use PukllayClubWeb, :html

  embed_templates "error_html/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found". Kept as the fallback for every status without its own
  # template (500 and anything else) — this clause is only reached when
  # embed_templates/1 above defined no matching function.
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
