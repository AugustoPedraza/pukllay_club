defmodule PukllayClubWeb.SitemapControllerTest do
  use PukllayClubWeb.ConnCase, async: true

  import PukllayClub.CatalogFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Repo

  describe "GET /sitemap.xml" do
    test "returns 200 with an XML content type and the sitemap-protocol namespace", %{conn: conn} do
      conn = get(conn, ~p"/sitemap.xml")

      assert response_content_type(conn, :xml)
      body = response(conn, 200)
      assert body =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
    end

    test "entry count equals the games row count plus one (the catalog index)", %{conn: conn} do
      game_fixture(%{name: "Uno"})
      game_fixture(%{name: "Dos"})
      game_fixture(%{name: "Tres"})

      body = conn |> get(~p"/sitemap.xml") |> response(200)

      expected = Catalog.count_games() + 1
      assert count_locs(body) == expected
    end

    test "every game's absolute detail URL is the id-slug form, appears exactly once, with a lastmod date",
         %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      body = conn |> get(~p"/sitemap.xml") |> response(200)

      # Literal expectation (quick task 260913-2x6), not derived via
      # `~p"/juegos/#{game}"` — asserts the actual id-slug bytes the
      # sitemap is supposed to emit, not whatever the same `Phoenix.Param`
      # impl under test happens to produce.
      detail_url = PukllayClubWeb.Endpoint.url() <> "/juegos/#{game.id}-catan"
      assert occurrences(body, detail_url) == 1

      lastmod = Date.to_iso8601(NaiveDateTime.to_date(game.updated_at))
      assert body =~ "<loc>#{detail_url}</loc><lastmod>#{lastmod}</lastmod>"
    end

    test "the catalog index URL is present", %{conn: conn} do
      body = conn |> get(~p"/sitemap.xml") |> response(200)

      assert body =~ "<loc>#{url(~p"/")}</loc>"
    end

    test "draft and retired games are excluded from both the entry count and the loc list (D-04, D-08)",
         %{conn: conn} do
      published = game_fixture(%{name: "Publicado", status: :published})
      draft = game_fixture(%{name: "Borrador", status: :draft})
      retired = game_fixture(%{name: "Retirado", status: :retired})

      body = conn |> get(~p"/sitemap.xml") |> response(200)

      expected = Catalog.count_games() + 1
      assert count_locs(body) == expected

      assert body =~ url(~p"/juegos/#{published}")
      refute body =~ url(~p"/juegos/#{draft}")
      refute body =~ url(~p"/juegos/#{retired}")
    end

    test "no entry carries a priority or changefreq element", %{conn: conn} do
      game_fixture()

      body = conn |> get(~p"/sitemap.xml") |> response(200)

      refute body =~ "<priority>"
      refute body =~ "<changefreq>"
    end

    test "two games sharing an identical updated_at both appear as separate entries", %{conn: conn} do
      game_a = game_fixture(%{name: "A"})
      game_b = game_fixture(%{name: "B"})

      # Same-second inserts naturally share the date-granularity lastmod
      # this sitemap emits — asserting the shared value directly rather
      # than assuming it, so this test fails loudly if that ever changes.
      assert NaiveDateTime.to_date(game_a.updated_at) == NaiveDateTime.to_date(game_b.updated_at)

      body = conn |> get(~p"/sitemap.xml") |> response(200)

      assert occurrences(body, url(~p"/juegos/#{game_a}")) == 1
      assert occurrences(body, url(~p"/juegos/#{game_b}")) == 1
    end

    test "with zero games the response is still 200 and still lists the catalog index", %{conn: conn} do
      # This test DB carries pre-existing, undocumented cross-test pollution
      # (see 01.8-01-SUMMARY.md's "Issues Encountered" — a known, out-of-scope
      # async-DB-pollution flake). Deleting every row inside this test's own
      # sandboxed transaction (rolled back on exit, never touching other
      # tests or real data) is the only way to genuinely exercise the
      # zero-games edge case this must-have requires.
      Repo.delete_all(Game)

      conn = get(conn, ~p"/sitemap.xml")

      body = response(conn, 200)
      assert count_locs(body) == 1
      assert body =~ "<loc>#{url(~p"/")}</loc>"
    end

    test "two successive requests over unchanged data return byte-identical bodies", %{conn: conn} do
      game_fixture()

      first = conn |> get(~p"/sitemap.xml") |> response(200)
      second = conn |> get(~p"/sitemap.xml") |> response(200)

      assert first == second
    end

    test "a game inserted between two requests appears only in the second response", %{conn: conn} do
      first = conn |> get(~p"/sitemap.xml") |> response(200)
      new_game = game_fixture(%{name: "Recién llegado"})
      second = conn |> get(~p"/sitemap.xml") |> response(200)

      detail_url = url(~p"/juegos/#{new_game}")
      refute first =~ detail_url
      assert second =~ detail_url
    end
  end

  defp count_locs(body), do: body |> String.split("<loc>") |> length() |> Kernel.-(1)

  defp occurrences(body, substring) do
    body
    |> String.split(substring)
    |> length()
    |> Kernel.-(1)
  end
end
