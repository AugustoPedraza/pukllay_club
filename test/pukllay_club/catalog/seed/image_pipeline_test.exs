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

  describe "select_cover/1" do
    test "prefers a version whose language link is Spanish, even when it isn't the first version" do
      item = %{
        image: "https://cf.geekdo-images.com/primary.jpg",
        versions: [
          %{image: "https://cf.geekdo-images.com/english.jpg", languages: ["English"]},
          %{image: "https://cf.geekdo-images.com/spanish.jpg", languages: ["Spanish"]}
        ]
      }

      assert {:ok, "https://cf.geekdo-images.com/spanish.jpg", :spanish_edition} = ImagePipeline.select_cover(item)
    end

    test "falls back to the item's primary image and reports :primary when no Spanish version exists" do
      item = %{
        image: "https://cf.geekdo-images.com/primary.jpg",
        versions: [%{image: "https://cf.geekdo-images.com/english.jpg", languages: ["English"]}]
      }

      assert {:ok, "https://cf.geekdo-images.com/primary.jpg", :primary} = ImagePipeline.select_cover(item)
    end

    test "returns {:error, :no_image} when neither a Spanish version nor a primary image exists" do
      assert {:error, :no_image} = ImagePipeline.select_cover(%{image: "", versions: []})
    end
  end

  describe "process_gallery/3" do
    test "returns an empty gallery because other-edition version images are not photos of the game", %{
      credentials: credentials
    } do
      item = %{
        image: "https://cf.geekdo-images.com/primary.jpg",
        versions: [
          %{image: "https://cf.geekdo-images.com/primary.jpg", languages: []},
          %{image: "https://cf.geekdo-images.com/v2.jpg", languages: []},
          %{image: "https://cf.geekdo-images.com/v3.jpg", languages: []},
          %{image: "https://cf.geekdo-images.com/v4.jpg", languages: []},
          %{image: "https://cf.geekdo-images.com/v4.jpg", languages: []}
        ]
      }

      assert {:ok, []} = ImagePipeline.process_gallery(item, "games/1", credentials)
    end

    test "returns an empty gallery (not padded placeholders) when there are no extra version images", %{
      credentials: credentials
    } do
      item = %{image: "https://cf.geekdo-images.com/primary.jpg", versions: []}

      assert {:ok, []} = ImagePipeline.process_gallery(item, "games/1", credentials)
    end
  end
end
