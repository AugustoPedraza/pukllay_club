defmodule PukllayClub.Catalog.Seed.OGCardBackfillTest do
  use PukllayClub.DataCase, async: false

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.OgCard
  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.ImagePipeline
  alias PukllayClub.Catalog.Seed.OGCardBackfill

  # `--pk-ramp-600` (D-07), read verbatim from assets/css/app.css. Rotated
  # to sketch 058's H300 (#7B2DCE) by quick task 260912-waa.
  @brand_hex_rgb [0x7B, 0x2D, 0xCE]

  defmodule FakeStorage do
    @moduledoc false
    @behaviour PukllayClub.Catalog.Seed.Storage

    @impl true
    def put(_credentials, key, binary, _opts) do
      Process.put({:fake_storage_put, key}, byte_size(binary))
      {:ok, "https://images.test.invalid/#{key}"}
    end

    @impl true
    def list_keys(_credentials, _prefix), do: {:ok, []}
  end

  setup do
    {:ok, credentials} = Credentials.fetch()
    previous_storage = Application.get_env(:pukllay_club, :catalog_storage)
    Application.put_env(:pukllay_club, :catalog_storage, FakeStorage)

    on_exit(fn ->
      if previous_storage do
        Application.put_env(:pukllay_club, :catalog_storage, previous_storage)
      else
        Application.delete_env(:pukllay_club, :catalog_storage)
      end
    end)

    %{credentials: credentials}
  end

  defp stub_cover_fetch(png_binary) do
    Req.Test.stub(ImagePipeline, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("image/png")
      |> Plug.Conn.send_resp(200, png_binary)
    end)
  end

  defp solid_png(width, height, color) do
    width
    |> Image.new!(height, color: color)
    |> Image.write!(:memory, suffix: ".png")
  end

  describe "ImagePipeline.og_card/1 — the 1200x630 letterbox transform" do
    test "a source wider than it is tall becomes exactly 1200x630" do
      stub_cover_fetch(solid_png(1000, 400, @brand_hex_rgb))

      assert {:ok, binary} = ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
      assert {:ok, vimage} = Image.open(binary)
      assert Image.width(vimage) == 1200
      assert Image.height(vimage) == 630
    end

    test "a near-square source is scaled to fit inside 1200x630, not cropped" do
      stub_cover_fetch(solid_png(800, 780, [10, 20, 30]))

      assert {:ok, binary} = ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
      assert {:ok, vimage} = Image.open(binary)
      assert Image.width(vimage) == 1200
      assert Image.height(vimage) == 630
    end

    test "a source taller than 630px still returns exactly 1200x630 — fit shrinks before pad" do
      stub_cover_fetch(solid_png(800, 900, [200, 200, 200]))

      assert {:ok, binary} = ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
      assert {:ok, vimage} = Image.open(binary)
      assert Image.width(vimage) == 1200
      assert Image.height(vimage) == 630
    end

    test "the padded region carries the brand colour, not transparency or white" do
      # A tall, narrow source guarantees left/right letterbox bars once fit
      # to 1200x630 — sample a corner pixel, far from the scaled source.
      stub_cover_fetch(solid_png(200, 630, [0, 0, 0]))

      assert {:ok, binary} = ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
      assert {:ok, vimage} = Image.open(binary)

      # Lossy WebP quantizes slightly — assert within tolerance rather than
      # exact equality, the same way a lossy-codec pixel value is compared
      # anywhere else in this codebase.
      [r, g, b] = Image.get_pixel!(vimage, 0, 0)
      [er, eg, eb] = @brand_hex_rgb
      assert_in_delta r, er, 5
      assert_in_delta g, eg, 5
      assert_in_delta b, eb, 5
    end

    test "the returned binary decodes as WebP" do
      stub_cover_fetch(solid_png(1000, 500, [1, 2, 3]))

      assert {:ok, binary} = ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
      assert <<"RIFF", _::size(32), "WEBP", _::binary>> = binary
    end

    test "rejects a source URL whose host is outside the configured image origin (SSRF guard, T-01.8-14)" do
      assert {:error, {:disallowed_url, _url}} =
               ImagePipeline.og_card("https://evil.example.com/games/1/cover-large.webp")
    end

    test "rejects a non-https source URL" do
      assert {:error, {:disallowed_url, _url}} =
               ImagePipeline.og_card("http://images.test.invalid/games/1/cover-large.webp")
    end

    test "still enforces the 15 MB download cap (T-01.8-13) on the og-card fetch path" do
      Req.Test.stub(ImagePipeline, fn conn ->
        chunk = :binary.copy(<<0>>, 1024 * 1024)

        conn =
          conn
          |> Plug.Conn.put_resp_content_type("image/png")
          |> Plug.Conn.send_chunked(200)

        Enum.reduce(1..16, conn, fn _i, conn ->
          {:ok, conn} = Plug.Conn.chunk(conn, chunk)
          conn
        end)
      end)

      assert {:error, :download_too_large} =
               ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
    end

    test "still rejects a non-image content-type response before decoding" do
      Req.Test.stub(ImagePipeline, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/html")
        |> Plug.Conn.send_resp(200, "<html>not an image</html>")
      end)

      assert {:error, {:unexpected_content_type, "text/html" <> _}} =
               ImagePipeline.og_card("https://images.test.invalid/games/1/cover-large.webp")
    end
  end

  describe "OgCard.object_key_for/1" do
    test "returns a key ending in the og-card object name for a game with a stored cover" do
      game = %Game{cover_url: "https://images.test.invalid/games/184267/cover-large.webp"}

      assert OgCard.object_key_for(game) == "games/184267/og-card.webp"
    end

    test "returns nil for a game with no stored cover" do
      assert OgCard.object_key_for(%Game{cover_url: nil}) == nil
    end

    test "returns nil for a cover_url that does not end in the expected segment" do
      game = %Game{cover_url: "https://images.test.invalid/games/184267/cover-thumb.webp"}

      assert OgCard.object_key_for(game) == nil
    end

    test "returns nil for a cover_url outside the configured image origin" do
      game = %Game{cover_url: "https://other-host.invalid/games/184267/cover-large.webp"}

      assert OgCard.object_key_for(game) == nil
    end
  end

  describe "OGCardBackfill.run/1" do
    test "iterates every game with a stored cover, uploads its og-card, and reports scanned/updated", %{
      credentials: credentials
    } do
      stub_cover_fetch(solid_png(900, 500, [5, 5, 5]))
      game = game_fixture()

      assert %{scanned: scanned, updated: updated} = OGCardBackfill.run(credentials: credentials)

      assert scanned >= 1
      assert updated >= 1
      assert Process.get({:fake_storage_put, OgCard.object_key_for(game)}) > 0
    end

    test "dry_run: true reports the same scanned count and drives zero calls on the storage double" do
      game_fixture()

      Req.Test.stub(ImagePipeline, fn _conn ->
        flunk("dry_run issued a network request — it must not fetch, transform, or upload anything")
      end)

      assert %{scanned: scanned, updated: 0} = OGCardBackfill.run(dry_run: true)
      assert scanned >= 1
    end

    test "a game with no stored cover is skipped and counted as scanned but not updated, and the run does not raise" do
      game_fixture(%{cover_url: nil, thumbnail_url: nil})

      assert %{scanned: scanned, updated: updated} = OGCardBackfill.run(dry_run: true)
      assert scanned >= 1
      assert updated == 0
    end

    test "a per-game failure is reported and the batch continues to the next game rather than aborting", %{
      credentials: credentials
    } do
      failing = game_fixture(%{cover_url: "https://images.test.invalid/games/900/cover-large.webp"})
      surviving = game_fixture(%{cover_url: "https://images.test.invalid/games/901/cover-large.webp"})

      Req.Test.stub(ImagePipeline, fn conn ->
        case conn.request_path do
          "/games/900/cover-large.webp" ->
            Plug.Conn.send_resp(conn, 500, "boom")

          _other ->
            conn
            |> Plug.Conn.put_resp_content_type("image/png")
            |> Plug.Conn.send_resp(200, solid_png(900, 500, [7, 7, 7]))
        end
      end)

      assert %{scanned: scanned, updated: updated} = OGCardBackfill.run(credentials: credentials)

      assert scanned >= 2
      assert updated >= 1
      assert Process.get({:fake_storage_put, OgCard.object_key_for(failing)}) == nil
      assert Process.get({:fake_storage_put, OgCard.object_key_for(surviving)}) > 0
    end

    test "re-running against an already-backfilled catalog completes without error and reports the same scanned count", %{
      credentials: credentials
    } do
      stub_cover_fetch(solid_png(900, 500, [9, 9, 9]))
      game_fixture()

      assert %{scanned: first_scanned} = OGCardBackfill.run(credentials: credentials)
      assert %{scanned: second_scanned} = OGCardBackfill.run(credentials: credentials)

      assert first_scanned == second_scanned
    end
  end
end
