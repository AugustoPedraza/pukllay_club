defmodule PukllayClubWeb.Admin.SectionLiveTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.SectionsFixtures

  describe "SectionLive.Index — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} = live(conn, ~p"/admin/secciones")
    end
  end

  describe "SectionLive.Index — list (D-17, D-18, UI-SPEC E6)" do
    setup :register_and_log_in_staff

    test "shows every section with a kind hint, and Oculta/Destacada badges", %{conn: conn} do
      # The migration's own D-22 backfill already seeds a featured
      # section ("Destacados del club") and 3 weight_band + 1 recent
      # section — the partial unique index allows only one featured
      # section, so this test creates only a hidden manual section of
      # its own and asserts against the pre-seeded rows for the rest.
      section_fixture(%{name: "Vieja sección propia", hidden: true})

      {:ok, _lv, html} = live(conn, ~p"/admin/secciones")

      assert html =~ "Destacados del club"
      assert html =~ "Destacada"
      assert html =~ "Vieja sección propia"
      assert html =~ "Oculta"
      assert html =~ "Elegida a mano"
      assert html =~ "Por nivel"
      assert html =~ "Recientes"
    end
  end

  describe "SectionLive.Edit — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      section = section_fixture()

      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} =
               live(conn, ~p"/admin/secciones/#{section.id}")
    end
  end

  describe "SectionLive.Edit — rename and hide (D-17, UI-SPEC E6)" do
    setup :register_and_log_in_staff

    test "renaming a section makes the public home page render the new title", %{conn: conn} do
      section = section_fixture(%{name: "Vieja"})
      add_game_to_section(section, game_fixture(%{name: "Un juego"}))

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      html = lv |> form("#section-form", section: %{name: "Para arrancar"}) |> render_submit()
      assert html =~ "Sección guardada."

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      assert home_html =~ "Para arrancar"
      refute home_html =~ "Vieja"
    end

    test "hiding a section removes it from the public home page", %{conn: conn} do
      section = section_fixture(%{name: "Se oculta"})
      add_game_to_section(section, game_fixture(%{name: "Otro juego"}))

      {:ok, _home_lv, home_html_before} = live(build_conn(), ~p"/")
      assert home_html_before =~ "Se oculta"

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")
      lv |> form("#section-form", section: %{hidden: "true"}) |> render_submit()

      {:ok, _home_lv, home_html} = live(build_conn(), ~p"/")
      refute home_html =~ "Se oculta"
    end

    test "a 41-character name shows a validation error and does not save", %{conn: conn} do
      section = section_fixture(%{name: "Vieja"})
      too_long = String.duplicate("a", 41)

      {:ok, lv, _html} = live(conn, ~p"/admin/secciones/#{section.id}")

      html = lv |> form("#section-form", section: %{name: too_long}) |> render_submit()

      assert html =~ "should be at most 40 character(s)"
    end

    test "a non-integer :id 404s", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/admin/secciones/not-an-id")
      end
    end
  end
end
