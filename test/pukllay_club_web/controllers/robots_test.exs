defmodule PukllayClubWeb.RobotsTest do
  use PukllayClubWeb.ConnCase, async: true

  describe "GET /robots.txt" do
    test "returns 200 with a wildcard user-agent section that permits crawling", %{conn: conn} do
      body = conn |> get(~p"/robots.txt") |> response(200)

      assert body =~ "User-agent: *"
      assert body =~ "Allow: /"
    end

    test "carries no ban directive on any non-comment line", %{conn: conn} do
      body = conn |> get(~p"/robots.txt") |> response(200)

      refute body |> non_comment_lines() |> Enum.any?(&String.starts_with?(&1, "Disallow"))
    end

    test "carries exactly one absolute Sitemap directive naming the router's own sitemap route", %{
      conn: conn
    } do
      body = conn |> get(~p"/robots.txt") |> response(200)

      sitemap_lines = body |> non_comment_lines() |> Enum.filter(&String.starts_with?(&1, "Sitemap:"))
      assert length(sitemap_lines) == 1

      [sitemap_line] = sitemap_lines
      url = sitemap_line |> String.trim_leading("Sitemap:") |> String.trim()

      assert String.starts_with?(url, "https://")
      assert URI.parse(url).path == ~p"/sitemap.xml"
    end

    test "the served body contains no comment lines", %{conn: conn} do
      body = conn |> get(~p"/robots.txt") |> response(200)

      refute body |> String.split("\n") |> Enum.any?(&String.starts_with?(&1, "#"))
    end
  end

  test "priv/static/robots.txt contains no line beginning with #" do
    contents = File.read!(Path.join([File.cwd!(), "priv", "static", "robots.txt"]))

    refute contents |> String.split("\n") |> Enum.any?(&String.starts_with?(&1, "#"))
  end

  defp non_comment_lines(body) do
    body
    |> String.split("\n")
    |> Enum.reject(&String.starts_with?(&1, "#"))
  end
end
