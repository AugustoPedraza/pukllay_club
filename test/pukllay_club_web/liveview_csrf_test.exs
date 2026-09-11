defmodule PukllayClubWeb.LiveViewCSRFTest do
  @moduledoc """
  Confirms CSRF protection genuinely covers LiveView's websocket connect flow,
  not just plain form posts (SEC-04, plan 01.7-03). This is a confirm-the-wiring
  gate, not new-code coverage — RESEARCH.md read all three pieces directly and
  found them already correctly in place:

    1. `root.html.heex` emits a `<meta name="csrf-token">` tag in every page's
       `<head>`, served by the shared root layout rather than by one page.
    2. `assets/js/app.js` reads that meta tag's value and sends it as a
       LiveSocket connect parameter (`_csrf_token`), which is what makes the
       websocket connect itself CSRF-checked.
    3. `endpoint.ex` hands `connect_info: [session: @session_options]` to both
       the `websocket:` and `longpoll:` transport options, so the socket has a
       session to validate that token against.

  This file pins fact 1 at the ExUnit level (a non-empty, non-placeholder
  token rendered by two independent routes, proving the shared-layout origin).
  Facts 2 and 3 are pinned by grep-based gates in 01.7-03-PLAN.md's `<verify>`
  block instead, since they are static source facts, not response bodies.

  The live-browser websocket reconnect behaviour itself — the transport-level
  path `Phoenix.LiveViewTest` does not exercise (RESEARCH.md Assumption A3) —
  is recorded in 01.7-CSP-AUDIT.md's CSRF section as a `<human-check>`
  backstop truth, not something this file attempts to simulate.
  """

  use PukllayClubWeb.ConnCase, async: true

  defp csrf_token_content(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(~s(meta[name="csrf-token"]))
    |> LazyHTML.attribute("content")
    |> List.first()
  end

  describe "the root layout serves a non-empty CSRF token (SEC-04)" do
    test "GET / returns HTML whose head carries a non-empty, non-placeholder csrf-token meta value",
         %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      token = csrf_token_content(html)

      refute is_nil(token), "Expected a <meta name=\"csrf-token\"> tag in the response head."
      refute token == "", "Expected the csrf-token meta content to be non-empty."

      refute token in ["csrf-token", "token", "CSRF_TOKEN", "REPLACE_ME"],
             "Expected a real generated token, not a literal placeholder string."
    end

    test "GET /club (a second, distinct route) also carries a non-empty csrf-token — served by " <>
           "the shared root layout, not one page",
         %{conn: conn} do
      conn = get(conn, ~p"/club")
      html = html_response(conn, 200)

      token = csrf_token_content(html)

      refute is_nil(token), "Expected a <meta name=\"csrf-token\"> tag on /club too."
      refute token == "", "Expected the csrf-token meta content on /club to be non-empty."
    end
  end
end
