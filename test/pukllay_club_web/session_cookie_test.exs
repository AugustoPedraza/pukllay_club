defmodule PukllayClubWeb.SessionCookieTest do
  # SEC-01 (T-01.7-04): the session cookie must carry the Secure attribute in
  # production without breaking local HTTP development. `@session_options` is a
  # module attribute evaluated once at compile time, so a bare `true` would make
  # Safari refuse the cookie over plain localhost HTTP (T-01.7-20). This gate
  # proves the whole contract from one file: the compiled test-env value is
  # `secure: false`, the rest of the session shape is unchanged, and the actual
  # test-env HTTP response is still usable over plain HTTP.
  #
  # The compiled-production value (`secure: true` under MIX_ENV=prod) cannot be
  # asserted from this test process — `Mix.env()` is fixed for the whole `mix
  # test` run — so that half of the contract is asserted separately via a real
  # `MIX_ENV=prod mix run` one-liner in 01.7-02-PLAN.md's second automated
  # `<verify>` step, not here.
  use PukllayClubWeb.ConnCase, async: true

  describe "session_options/0 accessor (SEC-01, T-01.7-04)" do
    test "the compiled test-env value carries secure: false" do
      opts = PukllayClubWeb.Endpoint.session_options()

      assert Keyword.fetch!(opts, :secure) == false
    end

    test "the compiled options are unmodified apart from adding :secure" do
      opts = PukllayClubWeb.Endpoint.session_options()

      assert Keyword.fetch!(opts, :store) == :cookie
      assert Keyword.fetch!(opts, :same_site) == "Lax"
      assert Keyword.fetch!(opts, :key) == "_pukllay_club_key"
    end
  end

  describe "test-env session cookie is usable over plain HTTP (SEC-01, T-01.7-20)" do
    test "the response's set-cookie for _pukllay_club_key carries no Secure attribute", %{
      conn: conn
    } do
      conn = get(conn, ~p"/")

      cookie_headers = get_resp_header(conn, "set-cookie")

      session_cookie = Enum.find(cookie_headers, &String.starts_with?(&1, "_pukllay_club_key="))

      assert session_cookie, "Expected a set-cookie header for _pukllay_club_key."

      attributes =
        session_cookie
        |> String.split(";")
        |> Enum.map(&String.trim/1)

      refute Enum.any?(attributes, &(String.downcase(&1) == "secure")),
             "The test-environment _pukllay_club_key cookie must not carry Secure — Safari " <>
               "does not exempt localhost from the Secure-requires-HTTPS rule, so an " <>
               "unconditional flag would break local dev sessions."
    end
  end
end
