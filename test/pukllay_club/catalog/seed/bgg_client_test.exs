defmodule PukllayClub.Catalog.Seed.BggClientTest do
  use ExUnit.Case, async: true

  alias PukllayClub.Catalog.Seed.BggClient
  alias PukllayClub.Catalog.Seed.Credentials

  @fixture File.read!("test/support/fixtures/bgg_thing_on_mars.xml")
  @unranked_fixture File.read!("test/support/fixtures/bgg_unranked_item.xml")

  setup do
    {:ok, credentials} = Credentials.fetch()
    %{credentials: credentials}
  end

  describe "fetch_batch/2" do
    test "parses every INTEGRATE field from a real captured authenticated BGG response", %{
      credentials: credentials
    } do
      Req.Test.stub(BggClient, fn conn ->
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-token"]

        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @fixture)
      end)

      assert {:ok, [item]} = BggClient.fetch_batch([184_267], credentials)

      assert item.bgg_id == 184_267
      assert item.name == "On Mars"
      assert item.year_published == 2020
      assert item.min_players == 1
      assert item.max_players == 4
      assert item.min_playtime == 90
      assert item.min_age == 14
      assert is_float(item.average_weight)
      assert item.average_weight > 0
      assert is_binary(item.image)
      assert String.starts_with?(item.image, "https://")
      assert is_binary(item.thumbnail)
      assert is_binary(item.description)
      assert length(item.mechanics) >= 5
      assert "Contracts" in item.mechanics
      assert item.categories != []
      assert item.designers != []
      assert is_float(item.average_rating)
      assert item.average_rating > 7.0
      assert item.rank == 58
    end

    test "an unranked, unrated item normalizes rank/rating/weight to nil and dedupes artists", %{
      credentials: credentials
    } do
      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, @unranked_fixture)
      end)

      assert {:ok, [item]} = BggClient.fetch_batch([999_999], credentials)

      # Test 2: BGG's non-numeric unranked marker soft-casts to nil.
      assert item.rank == nil

      # Test 3: a numeric zero rating/weight is absence of data, not a
      # measurement — both normalize to nil.
      assert item.average_rating == nil
      assert item.average_weight == nil

      # Test 4: the source document repeats one artist name three times;
      # the extraction layer dedupes it to a single entry.
      assert item.artists == ["Duplicated Artist"]
    end

    test "never raises on a hostile response — DTD processing is disabled", %{
      credentials: credentials
    } do
      malicious =
        ~s(<?xml version="1.0"?><!DOCTYPE items [<!ENTITY x SYSTEM "file:///etc/passwd">]>) <>
          ~s(<items><item id="1"><name type="primary" value="&x;" /></item></items>)

      Req.Test.stub(BggClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, malicious)
      end)

      # `dtd: :none` makes external entity expansion a hard failure rather
      # than a silent read — the important property under test is that this
      # comes back as an ordinary error tuple, not a process crash that
      # would take down the whole `mix catalog.seed` run.
      assert {:error, {:xml_parse_failed, _reason}} = BggClient.fetch_batch([1], credentials)
    end

    test "returns an error tuple (never raises) on a non-retryable HTTP status", %{
      credentials: credentials
    } do
      Req.Test.stub(BggClient, fn conn ->
        Plug.Conn.send_resp(conn, 401, "unauthorized")
      end)

      assert {:error, {:http, 401}} = BggClient.fetch_batch([184_267], credentials)
    end

    test "returns {:ok, []} for an empty id list without making an HTTP request (WINDOWS #15)",
         %{credentials: credentials} do
      # WINDOWS.md entry 15: `[]` passed the `length(bgg_ids) <= 20` guard and
      # built an `id=""` request, crashing on `:erlang.binary_to_integer("")`.
      test_pid = self()

      Req.Test.stub(BggClient, fn conn ->
        send(test_pid, {:bgg_request_made, conn.query_string})

        conn
        |> Plug.Conn.put_resp_content_type("text/xml")
        |> Plug.Conn.send_resp(200, "<items></items>")
      end)

      assert {:ok, []} = BggClient.fetch_batch([], credentials)
      refute_received {:bgg_request_made, _}
    end

    test "retries a 429 response and succeeds on the next attempt", %{credentials: credentials} do
      Req.Test.stub(BggClient, fn conn ->
        count = Process.get(:bgg_client_test_attempts, 0)
        Process.put(:bgg_client_test_attempts, count + 1)

        if count == 0 do
          Plug.Conn.send_resp(conn, 429, "rate limited")
        else
          conn
          |> Plug.Conn.put_resp_content_type("text/xml")
          |> Plug.Conn.send_resp(200, @fixture)
        end
      end)

      assert {:ok, [item]} = BggClient.fetch_batch([184_267], credentials)
      assert item.bgg_id == 184_267
      assert Process.get(:bgg_client_test_attempts) == 2
    end
  end

  describe "req_options/0" do
    test "reads the :bgg_req_options application config" do
      assert BggClient.req_options() == [plug: {Req.Test, BggClient}]
    end
  end
end
