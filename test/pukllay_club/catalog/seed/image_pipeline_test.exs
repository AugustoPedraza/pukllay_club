defmodule PukllayClub.Catalog.Seed.ImagePipelineTest do
  use ExUnit.Case, async: false

  alias PukllayClub.Catalog.Seed.Credentials
  alias PukllayClub.Catalog.Seed.ImagePipeline

  # 1x1 transparent PNG — small enough to resize instantly, real enough for
  # `Image.open/2` to decode via its PNG magic-byte match.
  @tiny_png Base.decode64!("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")

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

  describe "process/3" do
    test "downloads, resizes to two variants, and uploads through the Storage behaviour", %{
      credentials: credentials
    } do
      Req.Test.stub(ImagePipeline, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("image/png")
        |> Plug.Conn.send_resp(200, @tiny_png)
      end)

      assert {:ok, %{thumbnail_url: thumbnail_url, cover_url: cover_url}} =
               ImagePipeline.process(
                 "https://cf.geekdo-images.com/pic123.jpg",
                 "games/184267",
                 credentials
               )

      assert thumbnail_url == "https://images.test.invalid/games/184267/cover-thumb.webp"
      assert cover_url == "https://images.test.invalid/games/184267/cover-large.webp"

      assert Process.get({:fake_storage_put, "games/184267/cover-thumb.webp"}) > 0
      assert Process.get({:fake_storage_put, "games/184267/cover-large.webp"}) > 0
    end

    test "rejects a source URL whose host is not allowlisted (SSRF guard, T-01-09)", %{
      credentials: credentials
    } do
      assert {:error, {:disallowed_url, _url}} =
               ImagePipeline.process("https://evil.example.com/pic.jpg", "games/1", credentials)
    end

    test "rejects a source URL that is not https", %{credentials: credentials} do
      assert {:error, {:disallowed_url, _url}} =
               ImagePipeline.process(
                 "http://cf.geekdo-images.com/pic.jpg",
                 "games/1",
                 credentials
               )
    end

    test "rejects a non-image content-type response before decoding", %{credentials: credentials} do
      Req.Test.stub(ImagePipeline, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/html")
        |> Plug.Conn.send_resp(200, "<html>not an image</html>")
      end)

      assert {:error, {:unexpected_content_type, "text/html" <> _}} =
               ImagePipeline.process(
                 "https://cf.geekdo-images.com/pic123.jpg",
                 "games/1",
                 credentials
               )
    end
  end
end
