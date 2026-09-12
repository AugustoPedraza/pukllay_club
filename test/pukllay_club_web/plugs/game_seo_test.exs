defmodule PukllayClubWeb.Plugs.GameSEOTest do
  @moduledoc """
  Disconnected-response assertions for `PukllayClubWeb.Plugs.GameSEO` — a
  plain `get(conn, ...)`, never a rendered LiveView, since this plug's
  entire purpose is what a JS-free crawler sees on the very first HTTP
  response (PITFALLS Pitfall 1). First plug-specific test in this app;
  follows `PukllayClubWeb.HealthControllerTest`'s `use
  PukllayClubWeb.ConnCase` shape.
  """

  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures

  @json_ld_open ~r/<script type="application\/ld\+json"[^>]*nonce="([^"]*)"[^>]*>(.*?)<\/script>/s

  describe "Game JSON-LD (SEO-05, SEC-05)" do
    test "renders exactly one JSON-LD script element naming the game", %{conn: conn} do
      game = game_fixture(%{name: "Carcassonne"})

      conn = get(conn, ~p"/juegos/#{game.id}")
      body = html_response(conn, 200)

      assert count_occurrences(body, ~s(type="application/ld+json")) == 1

      [[_full, _nonce, payload]] = Regex.scan(@json_ld_open, body, capture: :all)
      decoded = Jason.decode!(payload)

      assert decoded["@type"] == "Game"
      assert decoded["name"] == "Carcassonne"
    end

    test "the script's nonce attribute is byte-equal to the nonce source in the response's own CSP header",
         %{conn: conn} do
      game = game_fixture()

      conn = get(conn, ~p"/juegos/#{game.id}")
      body = html_response(conn, 200)

      [policy] = get_resp_header(conn, "content-security-policy")
      [_, csp_nonce] = Regex.run(~r/'nonce-([^']+)'/, policy)

      [[_full, script_nonce, _payload]] = Regex.scan(@json_ld_open, body, capture: :all)

      assert script_nonce == csp_nonce
    end

    test "two successive requests to the same URL return two different nonce values", %{conn: conn} do
      game = game_fixture()

      conn1 = get(conn, ~p"/juegos/#{game.id}")
      [policy1] = get_resp_header(conn1, "content-security-policy")
      [_, nonce1] = Regex.run(~r/'nonce-([^']+)'/, policy1)

      conn2 = get(build_conn(), ~p"/juegos/#{game.id}")
      [policy2] = get_resp_header(conn2, "content-security-policy")
      [_, nonce2] = Regex.run(~r/'nonce-([^']+)'/, policy2)

      refute nonce1 == nonce2
    end

    test "a game with nil min/max players and nil description omits those JSON-LD keys", %{conn: conn} do
      game = game_fixture(%{min_players: nil, max_players: nil, description: nil, cover_url: nil})

      conn = get(conn, ~p"/juegos/#{game.id}")
      body = html_response(conn, 200)

      [[_full, _nonce, payload]] = Regex.scan(@json_ld_open, body, capture: :all)
      decoded = Jason.decode!(payload)

      refute Map.has_key?(decoded, "numberOfPlayers")
      refute Map.has_key?(decoded, "description")
      refute Map.has_key?(decoded, "image")
    end

    test "a game whose name carries an angle bracket and a script-closing sequence still yields " <>
           "exactly one script element and an escaped payload",
         %{conn: conn} do
      game = game_fixture(%{name: "Ataque</script><script>alert(1)</script> Total"})

      conn = get(conn, ~p"/juegos/#{game.id}")
      body = html_response(conn, 200)

      assert count_occurrences(body, ~s(type="application/ld+json")) == 1

      [[_full, _nonce, payload]] = Regex.scan(@json_ld_open, body, capture: :all)

      refute payload =~ "</"

      decoded = Jason.decode!(payload)
      assert decoded["name"] == "Ataque</script><script>alert(1)</script> Total"
    end

    test "two renders of the same game produce byte-identical JSON-LD payload bytes", %{conn: conn} do
      game = game_fixture()

      conn1 = get(conn, ~p"/juegos/#{game.id}")
      body1 = html_response(conn1, 200)
      [[_full1, _nonce1, payload1]] = Regex.scan(@json_ld_open, body1, capture: :all)

      conn2 = get(build_conn(), ~p"/juegos/#{game.id}")
      body2 = html_response(conn2, 200)
      [[_full2, _nonce2, payload2]] = Regex.scan(@json_ld_open, body2, capture: :all)

      assert payload1 == payload2
    end
  end

  defp count_occurrences(haystack, needle) do
    haystack
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
