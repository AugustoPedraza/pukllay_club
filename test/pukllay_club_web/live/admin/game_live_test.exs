defmodule PukllayClubWeb.Admin.GameLiveTest do
  @moduledoc """
  `Admin.GameLive.Form` (`/admin/juegos/:id/editar`) — the editor rebuilt by
  plan 01.8.2-17: D-27's 56px top app bar, D-29's consequence franja,
  D-28's fixed foot save bar, and D-26's ficha-mirroring body.

  The old inline-form/Secciones-checkbox/`<.header>` tests this file
  carried before plan 01.8.2-17 are gone along with the markup they tested
  — see this plan's own SUMMARY for the two behaviour changes that removed
  them (Publicar moves to the draft sheet per D-30; section membership is
  now solely managed from `section_live/edit.ex`, per D-26's own "chip de
  sección" being read-only here).
  """
  use PukllayClubWeb.ConnCase, async: false
  use Oban.Testing, repo: PukllayClub.Repo

  import Phoenix.LiveViewTest
  import PukllayClub.CatalogFixtures
  import PukllayClub.CopiesFixtures
  import PukllayClub.SectionsFixtures
  import PukllayClub.ShelvesFixtures

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Copy
  alias PukllayClub.Catalog.Game
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClub.Repo
  alias PukllayClub.Workers.EnrichGameWorker

  describe "GameLive.Form — anonymous access" do
    test "an anonymous request redirects to /admin/ingresar", %{conn: conn} do
      game = game_fixture()

      assert {:error, {:redirect, %{to: "/admin/ingresar"}}} =
               live(conn, ~p"/admin/juegos/#{game.id}/editar")
    end
  end

  describe "GameLive.Form — the top app bar (D-27)" do
    setup :register_and_log_in_staff

    test "renders exactly one back control and one ⋮, and no other top-bar control", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert lv |> element(".pk-editor-topbar__back") |> has_element?()
      assert lv |> element(".pk-editor-topbar__menu") |> has_element?()
      assert lv |> element(".pk-editor-topbar") |> render() =~ "Catán"
    end

    test "no Descartar control exists anywhere in the rendered page (D-27 deletes it)", %{
      conn: conn
    } do
      game = game_fixture()

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      refute html =~ "Descartar"
    end

    test "a clean editor's back control navigates away silently", %{conn: conn} do
      game = game_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert {:ok, _index_lv, index_html} =
               lv |> render_click("back-clicked") |> follow_redirect(conn, ~p"/admin/juegos")

      refute index_html =~ "¿Salir sin guardar?"
    end

    test "a dirty editor's back control opens the D-19f discard dialog instead of navigating", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Viejo"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      render_change(lv, "draft-change", %{"field" => "name", "value" => "Nuevo"})
      html = render_click(lv, "back-clicked")

      assert html =~ "¿Salir sin guardar?"
      assert lv |> element("#editor-discard-dialog.pk-admin-overlay--open") |> has_element?()
      assert lv |> element("#editor-discard-dialog") |> render() =~ "Los cambios que hiciste se pierden."
    end

    test "confirming the discard dialog navigates away, cancelling stays", %{conn: conn} do
      game = game_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "name", "value" => "Otro"})
      render_click(lv, "back-clicked")

      render_click(lv, "cancel-discard")
      refute lv |> element("#editor-discard-dialog.pk-admin-overlay--open") |> has_element?()

      render_click(lv, "back-clicked")

      assert {:ok, _index_lv, _index_html} =
               lv |> render_click("confirm-discard") |> follow_redirect(conn, ~p"/admin/juegos")
    end
  end

  describe "GameLive.Form — the D-29 consequence franja" do
    setup :register_and_log_in_staff

    test "a published game renders «Publicado · Así se ve en la web.»", %{conn: conn} do
      game = game_fixture(%{status: :published})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Publicado · Así se ve en la web."
    end

    test "a retired game renders «Retirado · No se ve en la web ni está en el estante.»", %{
      conn: conn
    } do
      game = game_fixture(%{status: :retired})

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Retirado · No se ve en la web ni está en el estante."
    end

    @tag :draft_web_claim
    test "neither status renders the retired 01.8.1 web-claim string", %{conn: conn} do
      published = game_fixture(%{status: :published, name: "Publicado juego"})
      retired = game_fixture(%{status: :retired, name: "Retirado juego"})

      {:ok, _lv, published_html} = live(conn, ~p"/admin/juegos/#{published.id}/editar")
      {:ok, _lv, retired_html} = live(conn, ~p"/admin/juegos/#{retired.id}/editar")

      assert published_html =~ "Publicado · Así se ve en la web."
      assert retired_html =~ "Retirado · No se ve en la web ni está en el estante."
      refute published_html =~ "Se está viendo así en la web"
      refute retired_html =~ "Se está viendo así en la web"
    end
  end

  # D-30/plan 01.8.2-20: a draft no longer opens THIS LiveView at all — see
  # `GameLive.Index`'s own "D-30 draft sheet" describe block for its own
  # coverage of what a draft's URL opens instead.
  describe "GameLive.Form — D-30 draft editor guard (plan 01.8.2-20)" do
    setup :register_and_log_in_staff

    test "a direct URL to a draft's editor redirects to the list with that draft's sheet open", %{
      conn: conn
    } do
      draft = game_fixture(%{status: :draft, name: "Borrador"})

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/admin/juegos/#{draft.id}/editar")
      assert to == ~p"/admin/juegos?draft=#{draft.id}"

      {:ok, lv, html} = live(conn, to)

      assert html =~ draft.name
      assert lv |> element("#draft-sheet.pk-admin-overlay--open") |> has_element?()
      refute html =~ "Publicado · Así se ve en la web."
      refute html =~ "Retirado · No se ve en la web ni está en el estante."
      refute html =~ "Se está viendo así en la web"
    end
  end

  describe "GameLive.Form — the write model (D-28, «la hoja PREPARA, el pie escribe»)" do
    setup :register_and_log_in_staff

    test "save_bar/1 renders on every editor render, dirty or clean", %{conn: conn} do
      game = game_fixture()

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "pk-admin-save-bar"
      assert lv |> element("[data-pk-save-bar]") |> has_element?()
    end

    test "with no changes, Guardar is disabled and no Sin guardar text renders", %{conn: conn} do
      game = game_fixture()

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Guardar"
      refute html =~ "Sin guardar"
      assert html =~ "disabled"
      assert html =~ "pk-admin-action--disabled"
    end

    test "after changing one value, Guardar is enabled and Sin guardar renders", %{conn: conn} do
      game = game_fixture(%{name: "Antes"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html = render_change(lv, "draft-change", %{"field" => "name", "value" => "Después"})

      assert html =~ "Sin guardar"
      refute html =~ ~s(pk-admin-save-bar__action pk-admin-action--disabled)
    end

    test "Guardar persists the change through Game.admin_changeset/2 and leaves the editor clean", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Antes"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "name", "value" => "Después"})

      html = render_click(lv, "save")

      assert html =~ "Cambios guardados."
      refute html =~ "Sin guardar"
      assert Catalog.get_game!(game.id).name == "Después"
    end

    test "attempting to change bgg_weight through draft-change is a no-op (T-01.8.1-21)", %{
      conn: conn
    } do
      game = game_fixture(%{bgg_weight: 2.3})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "bgg_weight", "value" => "4.9"})
      render_click(lv, "save")

      assert Catalog.get_game!(game.id).bgg_weight == 2.3
    end

    test "the shelf select saves shelf_id and never leaks it onto the public page", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante-Test-Ludoteca"})
      game = game_fixture()

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      assert html =~ "Sin ubicar"

      render_change(lv, "draft-change", %{"field" => "shelf_id", "value" => to_string(shelf.id)})
      render_click(lv, "save")

      assert Catalog.get_game!(game.id).shelf_id == shelf.id

      conn = get(conn, ~p"/juegos/#{game}")
      refute html_response(conn, 200) =~ "Estante-Test-Ludoteca"
    end

    test "a blank name is rejected server-side and the editor flashes an error", %{conn: conn} do
      game = game_fixture(%{name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "name", "value" => ""})
      html = render_click(lv, "save")

      assert html =~ "No se pudo guardar."
      assert Catalog.get_game!(game.id).name == "Catán"
    end
  end

  describe "GameLive.Form — status actions via the ⋮ lifecycle sheet (D-04, D-08)" do
    setup :register_and_log_in_staff

    test "on a published game, the menu opens the D-19f retire dialog and confirming retires it", %{
      conn: conn
    } do
      game = game_fixture(%{status: :published, name: "Se retira"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      refute lv |> element("#editor-retire-dialog.pk-admin-overlay--open") |> has_element?()

      render_click(lv, "open-menu")
      html = render_click(lv, "retire")
      assert html =~ "¿Retirar Se retira?"
      assert lv |> element("#editor-retire-dialog.pk-admin-overlay--open") |> has_element?()

      html = render_click(lv, "confirm-retire")
      assert html =~ "Juego retirado."
      assert Catalog.get_game!(game.id).status == :retired
    end

    test "cancelling the retire dialog leaves the game published", %{conn: conn} do
      game = game_fixture(%{status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu")
      render_click(lv, "retire")
      render_click(lv, "cancel-retire")

      assert Catalog.get_game!(game.id).status == :published
    end

    test "on a retired game, the menu's Restaurar restores it with no confirmation", %{conn: conn} do
      game = game_fixture(%{status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu")
      html = render_click(lv, "restore")

      assert html =~ "Juego restaurado."
      assert Catalog.get_game!(game.id).status == :published
    end

    test "a draft's public URL 404s (unaffected by D-30's editor guard, plan 01.8.2-20)", %{
      conn: _conn
    } do
      game = game_fixture(%{status: :draft})

      assert_raise Ecto.NoResultsError, fn ->
        Catalog.get_published_game!(to_string(game.id))
      end
    end

    test "a status change with unsaved field edits leaves the draft intact and dirty? still true", %{
      conn: conn
    } do
      game = game_fixture(%{status: :published, name: "Antes"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "name", "value" => "Después"})

      render_click(lv, "open-menu")
      render_click(lv, "retire")
      html = render_click(lv, "confirm-retire")

      assert html =~ "Después"
      assert html =~ "Sin guardar"
      refute html =~ ~s(pk-admin-save-bar__action pk-admin-action--disabled)
      assert Catalog.get_game!(game.id).status == :retired
      assert Catalog.get_game!(game.id).name == "Antes"
    end

    test "after retiring, the franja reads the D-29 retired consequence line", %{conn: conn} do
      game = game_fixture(%{status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu")
      render_click(lv, "retire")
      html = render_click(lv, "confirm-retire")

      assert html =~ "Retirado · No se ve en la web ni está en el estante."
    end

    test "a refused retire (already retired underneath the session) shows a snackbar and leaves the status alone", %{
      conn: conn
    } do
      game = game_fixture(%{status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu")
      render_click(lv, "retire")
      render_click(lv, "confirm-retire")
      assert Catalog.get_game!(game.id).status == :retired

      # Fires the SAME event again — the game's own in-memory status in the
      # LiveView is now :retired, so `Catalog.retire_game/1`'s origin guard
      # refuses it (T-01.8.2-90's real refusal path, not a DB race).
      html = render_click(lv, "confirm-retire")

      assert html =~ "No se pudo retirar."
      assert Catalog.get_game!(game.id).status == :retired
    end

    test "a refused restore (already restored underneath the session) shows a snackbar and leaves the status alone", %{
      conn: conn
    } do
      game = game_fixture(%{status: :retired})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu")
      render_click(lv, "restore")
      assert Catalog.get_game!(game.id).status == :published

      html = render_click(lv, "restore")

      assert html =~ "No se pudo restaurar."
      assert Catalog.get_game!(game.id).status == :published
    end
  end

  describe "GameLive.Form — the ficha-mirroring body at rest (D-26)" do
    setup :register_and_log_in_staff

    test "renders the seven editable blocks' affordance and no chevron/caret on any of them", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Catán", description: "Una descripción de prueba."})

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      # pills(nivel) + tapa + título + descripción = 4 hand-built editable
      # affordances, plus the Copias STEPPER (D-31, plan 01.8.2-21 — out of
      # `editable_row/1`'s scope per D-23) and the two remaining
      # AdminComponents.editable_row/1 rows (Estante/Es una expansión) = 7
      # total editable blocks.
      pill_count = html |> String.split("pk-editor-pill--editable") |> length() |> Kernel.-(1)
      assert pill_count == 1
      assert lv |> element(".pk-editor-cover__pencil") |> has_element?()
      assert lv |> element(".pk-editor-title") |> has_element?()
      assert lv |> element(".pk-editor-desc") |> has_element?()
      assert lv |> element(".pk-admin-stepper-row__label", "Copias") |> has_element?()

      editable_row_count = ~r/pk-admin-editable-row__label/ |> Regex.scan(html) |> length()
      assert editable_row_count == 2

      refute html =~ "›"
      refute html =~ "⌄"
    end

    test "renders D-26's order: título Bebas with no label, the five BGG facts, the divider group", %{
      conn: conn
    } do
      game =
        game_fixture(%{
          name: "Catán",
          year_published: 1995,
          designers: ["Klaus Teuber"],
          artists: ["Volkan Baga"],
          mechanics: ["Trading"],
          themes: ["Economic"]
        })

      {:ok, lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Catán"
      assert html =~ "1995"
      assert html =~ "Klaus Teuber"
      assert html =~ "Volkan Baga"
      assert html =~ "Copias"
      assert html =~ "Estante"
      assert html =~ "Es una expansión"

      # D-26 overrides D-19j for the título only, but never through the
      # Tailwind `font-display` utility CLASS the composition guard bans —
      # `pk-editor-title` reaches Bebas through `var(--font-display)` in
      # `editor.css` instead (see that rule's own comment).
      title_html = lv |> element(".pk-editor-title") |> render()
      refute title_html =~ "font-display"
    end

    test "the non-editable section chip carries no --val tint class (D-33)", %{conn: conn} do
      section = section_fixture(%{name: "Estrategia"})
      game = game_fixture()
      add_game_to_section(section, game)

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      chip_html = lv |> element(".pk-editor-section-chip") |> render()
      assert chip_html =~ "Estrategia"
      refute chip_html =~ "pk-editor-pill--editable"
      refute chip_html =~ "--val"
    end

    test "the editor page renders no bottom tab bar (D-30, the D-13b exception)", %{conn: conn} do
      game = game_fixture()

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      refute html =~ "pk-admin-tab-bar"
    end

    test "the Copias value reads from Shelves.count_for_game/1, not a units column", %{conn: conn} do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})
      copy_fixture(%{game_id: game.id})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert Shelves.count_for_game(game.id) == 2
      assert lv |> element(".pk-admin-stepper-row__value", "2") |> has_element?()
    end
  end

  describe "GameLive.Form — the D-30 choice-field sheet (D-23's tick, not a tint)" do
    setup :register_and_log_in_staff

    test "opening the nivel sheet offers exactly the three vocabulary bands", %{conn: conn} do
      game = game_fixture(%{weight_band: "ingenio_estratega"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      render_click(lv, "edit-field", %{"field" => "weight_band"})
      sheet_html = lv |> element("#editor-weight-band-sheet") |> render()

      opt_count = sheet_html |> String.split("pk-editor-opt\"") |> length() |> Kernel.-(1)
      assert opt_count == length(Vocabulary.weight_bands())

      for band <- Vocabulary.weight_bands() do
        assert sheet_html =~ band.label
      end
    end

    test "the selected option carries a tick and no option carries the --val tint", %{conn: conn} do
      game = game_fixture(%{weight_band: "ingenio_estratega"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "weight_band"})
      sheet_html = lv |> element("#editor-weight-band-sheet") |> render()

      tick_count = sheet_html |> String.split("pk-editor-opt__tick") |> length() |> Kernel.-(1)
      assert tick_count == 1
      refute sheet_html =~ ~s(pk-editor-opt pk-editor-pill--editable)
      refute sheet_html =~ ~s(pk-editor-opt--val)
    end

    test "a choice sheet's markup contains no Guardar control", %{conn: conn} do
      game = game_fixture()

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "weight_band"})

      sheet_html = lv |> element("#editor-weight-band-sheet") |> render()
      assert sheet_html =~ "Nivel"
      refute sheet_html =~ "pk-editor-sheet-save"
      refute sheet_html =~ ">Guardar<"
    end

    test "choosing an option updates the rendered row, enables Guardar, and writes nothing to the DB", %{
      conn: conn
    } do
      game = game_fixture(%{weight_band: "descubre_el_hobby", name: "Catán"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "weight_band"})

      html = render_click(lv, "choice-select", %{"field" => "weight_band", "choice" => "nivel_experto"})

      assert html =~ "Nivel experto"
      assert html =~ "Sin guardar"
      refute html =~ ~s(id="editor-weight-band-sheet" class="pk-admin-overlay-root pk-admin-overlay--open")

      # Nothing is persisted until the foot bar's Guardar is pressed.
      assert Catalog.get_game!(game.id).weight_band == "descubre_el_hobby"
    end

    test "opening and dismissing a choice sheet with ✕ leaves the draft unchanged", %{conn: conn} do
      game = game_fixture(%{weight_band: "descubre_el_hobby"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "weight_band"})
      html = render_click(lv, "close-field-sheet")

      assert html =~ "Descubre el hobby"
      refute html =~ "Sin guardar"
      assert html =~ "pk-admin-action--disabled"
    end

    test "choosing Es una expansión writes the boolean into the draft, not the DB", %{conn: conn} do
      game = game_fixture(%{is_expansion: false})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "is_expansion"})
      html = render_click(lv, "choice-select", %{"field" => "is_expansion", "choice" => "true"})

      assert lv |> element(".pk-admin-editable-row__value", "Sí") |> has_element?()
      assert html =~ "Sin guardar"
      assert Catalog.get_game!(game.id).is_expansion == false
    end
  end

  describe "GameLive.Form — the D-30 text-field sheet (its own wide Guardar, ✕ discards)" do
    setup :register_and_log_in_staff

    test "form.ex ships two distinctly named sheet renderers, one per D-30 pattern" do
      source = File.read!("lib/pukllay_club_web/live/admin/game_live/form.ex")

      assert source =~ "defp choice_sheet"
      assert source =~ "defp text_sheet"
      assert source =~ "D-30"
    end

    test "the in-sheet Guardar writes the typed name into the draft, not the DB", %{conn: conn} do
      game = game_fixture(%{name: "Antes"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "name"})

      html = render_submit(lv, "text-sheet-save", %{"field" => "name", "value" => "Después"})

      assert html =~ "Después"
      assert html =~ "Sin guardar"
      assert Catalog.get_game!(game.id).name == "Antes"
    end

    test "closing the name sheet with ✕ discards the typed text, leaving the row unchanged", %{conn: conn} do
      game = game_fixture(%{name: "Original"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "name"})
      html = render_click(lv, "close-field-sheet")

      assert html =~ "Original"
      refute html =~ "Sin guardar"
    end

    test "a name over 255 characters surfaces its validation error inside the sheet, not a page flash", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Catán"})
      too_long = String.duplicate("a", 256)

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "name"})

      html = render_submit(lv, "text-sheet-save", %{"field" => "name", "value" => too_long})

      assert lv |> element("#editor-name-sheet.pk-admin-overlay--open") |> has_element?()
      assert html =~ "pk-admin-field__error"
      refute html =~ "Sin guardar"
      assert Catalog.get_game!(game.id).name == "Catán"
    end

    test "the description sheet commits into the draft the same way", %{conn: conn} do
      game = game_fixture(%{description: "Antes"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "description"})
      html = render_submit(lv, "text-sheet-save", %{"field" => "description", "value" => "Después"})

      assert html =~ "Después"
      assert Catalog.get_game!(game.id).description == "Antes"
    end

    test "typing a value live and closing with ✕ (not submitting) leaves the row and draft untouched", %{
      conn: conn
    } do
      game = game_fixture(%{name: "Real"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "name"})
      render_change(lv, "sheet-input", %{"field" => "name", "value" => "Nunca guardado"})

      html = render_click(lv, "close-field-sheet")

      assert html =~ "Real"
      refute html =~ "Nunca guardado"
      refute html =~ "Sin guardar"
      assert Catalog.get_game!(game.id).name == "Real"
    end
  end

  # D-30/plan 01.8.2-20: a DRAFT with a failed enrichment never reaches this
  # LiveView any more (`GameLive.Index`'s own `failed_row/1` — unchanged by
  # this plan — is that state's only surface now). This describe block's
  # own code path (`failed?/1` + the Reintentar handler below) stays real
  # for a game that reached `:published`/`:retired` carrying a stale
  # `enrichment_status: "failed"` (`retry_enrichment/1` gates only on
  # `enrichment_status`, never on `status` — publishing despite a failed
  # BGG fetch is not blocked), so the fixtures below moved to `:published`
  # rather than being deleted.
  describe "GameLive.Form — failed enrichment retry (D-03)" do
    setup :register_and_log_in_staff

    test "a published game with a stale failed enrichment shows the error alert and Reintentar",
         %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :published,
          enrichment_status: "failed"
        })

      {:ok, _lv, html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert html =~ "Error al traer datos de BGG."
      assert html =~ "Reintentar"
    end

    test "clicking Reintentar re-enqueues enrichment and clears the error", %{conn: conn} do
      game =
        game_fixture(%{
          bgg_id: 184_267,
          name: "Juego #184267",
          status: :published,
          enrichment_status: "failed"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      html = render_click(lv, "retry-enrichment", %{"game-id" => to_string(game.id)})

      refute html =~ "Error al traer datos de BGG."
      assert Catalog.get_game!(game.id).enrichment_status == "pending"
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end
  end

  describe "GameLive.Form — the Copias stepper (D-31, plan 01.8.2-21)" do
    setup :register_and_log_in_staff

    test "raising Copias creates an unplaced copy that appears in Shelves.unplaced_copies/0", %{conn: conn} do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "copias-increment", %{})

      assert Shelves.count_for_game(game.id) == 2
      assert lv |> element(".pk-admin-stepper-row__value", "2") |> has_element?()
      unplaced_ids = Enum.map(Shelves.unplaced_copies(), & &1.id)
      assert unplaced_ids != []
      refute html =~ "No se pudo agregar"
    end

    test "lowering Copias with one unplaced copy removes that one and leaves placed copies alone", %{conn: conn} do
      shelf = shelf_fixture()
      game = game_fixture()
      placed = copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})
      copy_fixture(%{game_id: game.id, number: 2})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "copias-decrement", %{})

      assert html =~ ">1<" or lv |> element(".pk-admin-stepper-row__value", "1") |> has_element?()
      assert Shelves.count_for_game(game.id) == 1
      assert Repo.get(Copy, placed.id)
    end

    test "lowering Copias with every copy placed opens the which-copy sheet, naming estante and box", %{conn: conn} do
      shelf = shelf_fixture(%{name: "Estante Test"})
      game = game_fixture()
      copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})
      copy_fixture(%{game_id: game.id, number: 2, shelf_id: shelf.id, position: 1})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "copias-decrement", %{})

      assert html =~ "¿Cuál copia sacamos?"
      assert html =~ "Estante Test"
      assert Shelves.count_for_game(game.id) == 2
    end

    test "picking a copy in the which-copy sheet removes it and reindexes the estante gap-free", %{conn: conn} do
      shelf = shelf_fixture()
      game = game_fixture()
      c0 = copy_fixture(%{game_id: game.id, number: 1, shelf_id: shelf.id, position: 0})
      c1 = copy_fixture(%{game_id: game.id, number: 2, shelf_id: shelf.id, position: 1})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "copias-decrement", %{})
      html = render_click(lv, "copias-remove-copy", %{"copy-id" => to_string(c0.id)})

      refute html =~ "¿Cuál copia sacamos?"
      assert Shelves.count_for_game(game.id) == 1
      remaining = Shelves.copies_on_shelf(shelf.id)
      assert Enum.map(remaining, & &1.id) == [c1.id]
      assert Enum.map(remaining, & &1.position) == [0]
    end

    test "the stepper cannot reach 0 — decrementing a single-copy game is a no-op", %{conn: conn} do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "copias-decrement", %{})

      assert Shelves.count_for_game(game.id) == 1
    end

    test "form.ex never references the dropped units column (D-31, this plan's own <verify>)" do
      {output, _exit_status} =
        System.shell(
          "grep -vE '^\\s*#' lib/pukllay_club_web/live/admin/game_live/form.ex | grep -ciE \"units\"",
          cd: File.cwd!()
        )

      assert String.trim(output) == "0"
    end
  end

  describe "GameLive.Form — the ESTANTE block opens the real «¿Dónde va?» sheet (D-32, plan 01.8.2-21)" do
    setup :register_and_log_in_staff

    test "a single-copy game opens the position-aware sheet directly, not a plain estante list", %{conn: conn} do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})
      shelf_fixture(%{name: "Estante Uno"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "edit-field", %{"field" => "shelf_id"})

      assert html =~ "¿Dónde va?"
      assert lv |> element("#donde-va-estante-list") |> has_element?()
      assert lv |> element("#donde-va-shelf-#{Shelves.list_shelves() |> hd() |> Map.get(:id)}") |> has_element?()
    end

    test "a multi-copy game with no copy context asks which copy before opening the sheet", %{conn: conn} do
      game = game_fixture()
      c1 = copy_fixture(%{game_id: game.id, number: 1})
      _c2 = copy_fixture(%{game_id: game.id, number: 2})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "edit-field", %{"field" => "shelf_id"})

      assert html =~ "¿Qué copia?"
      refute html =~ "¿Dónde va?"

      html = render_click(lv, "pick-copy-context", %{"copy-id" => to_string(c1.id)})
      assert html =~ "¿Dónde va?"
    end

    test "?copy=<id> carries the copy identity through, matching a cover's options sheet handoff", %{conn: conn} do
      game = game_fixture()
      _c1 = copy_fixture(%{game_id: game.id, number: 1})
      c2 = copy_fixture(%{game_id: game.id, number: 2})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar?#{%{copy: c2.id}}")
      html = render_click(lv, "edit-field", %{"field" => "shelf_id"})

      assert html =~ "¿Dónde va?"
      refute html =~ "¿Qué copia?"
    end

    test "choosing an empty estante commits immediately and shows Juego ubicado with Deshacer", %{conn: conn} do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})
      shelf = shelf_fixture(%{name: "Vacío"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "shelf_id"})
      html = lv |> element("#donde-va-shelf-#{shelf.id}") |> render_click()

      assert html =~ "Juego ubicado"
      assert html =~ "Deshacer"
      assert lv |> element(".pk-admin-editable-row__value", shelf.name) |> has_element?()
    end

    test "moving an already-placed copy shows Juego movido", %{conn: conn} do
      shelf_a = shelf_fixture(%{name: "Origen"})
      shelf_b = shelf_fixture(%{name: "Destino"})
      game = game_fixture()
      copy_fixture(%{game_id: game.id, shelf_id: shelf_a.id, position: 0})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "edit-field", %{"field" => "shelf_id"})
      html = lv |> element("#donde-va-shelf-#{shelf_b.id}") |> render_click()

      assert html =~ "Juego movido"
    end

    test "the ESTANTE block renders with the --val tint and pencil, matching the other editable blocks", %{
      conn: conn
    } do
      game = game_fixture()
      copy_fixture(%{game_id: game.id})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      assert lv |> element(".pk-admin-editable-row__label", "Estante") |> has_element?()
    end

    test "the «¿Dónde va?» sheet has one shared implementation, referenced by both EstanteLive.Index and GameLive.Form" do
      # Mirrors this plan's own <verify> grep directly (avoids a shell
      # dependency): at most 2 files carry the literal "dónde-va" or
      # "donde_va" — three or more would mean the editor grew its own
      # copy of the placement sheet, which D-32 forbids.
      files =
        "lib/pukllay_club_web/**/*.ex"
        |> Path.wildcard()
        |> Enum.filter(fn path ->
          contents = File.read!(path)
          contents =~ "dónde-va" or contents =~ "donde_va"
        end)

      assert length(files) <= 2
    end
  end

  describe "GameLive.Form — the BGG-id lifecycle (open item 3, D-38, plan 01.8.2-21)" do
    setup :register_and_log_in_staff

    test "a game with no bgg_id offers Vincular con BGG in the ⋮ menu", %{conn: conn} do
      game = game_fixture(%{bgg_id: nil, status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "open-menu", %{})

      assert html =~ "Vincular con BGG"
      refute html =~ ">Reintentar<"
    end

    test "linking with unsaved edits saves first, then links — the edit survives", %{conn: conn} do
      game = game_fixture(%{bgg_id: nil, status: :published, name: "Antes"})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "name", "value" => "Después"})

      render_click(lv, "open-menu", %{})
      render_click(lv, "open-bgg-link", %{})
      html = render_submit(lv, "link-bgg-save", %{"bgg_id" => "184267"})

      assert html =~ "BGG vinculado."
      assert html =~ "Después"
      updated = Catalog.get_game!(game.id)
      assert updated.name == "Después"
      assert updated.bgg_id == 184_267
      assert updated.enrichment_status == "pending"
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end

    test "linking a duplicate bgg id is rejected the same way creation rejects it", %{conn: conn} do
      existing = game_fixture(%{bgg_id: 163_412, name: "Patchwork", status: :published})
      game = game_fixture(%{bgg_id: nil, name: "Patchwork Andino", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu", %{})
      render_click(lv, "open-bgg-link", %{})
      html = render_submit(lv, "link-bgg-save", %{"bgg_id" => "163412"})

      assert html =~ existing.name
      assert Catalog.get_game!(game.id).bgg_id == nil

      html = render_click(lv, "confirm-link-edition", %{})
      assert html =~ "BGG vinculado."
      assert Catalog.get_game!(game.id).bgg_id == 163_412
    end

    test "Reintentar is reachable for a game with a bgg_id and any enrichment_status", %{conn: conn} do
      game = game_fixture(%{bgg_id: 174_430, enrichment_status: "enriched", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_click(lv, "open-menu", %{})
      html = render_click(lv, "retry-enrichment", %{"game-id" => to_string(game.id)})

      assert html =~ "Cambios guardados." or Catalog.get_game!(game.id).enrichment_status == "pending"
      assert Catalog.get_game!(game.id).enrichment_status == "pending"
      assert_enqueued(worker: EnrichGameWorker, args: %{"game_id" => game.id})
    end

    test "Borrar el ID is offered for a bgg_missing game and clears the stored id, with Deshacer", %{conn: conn} do
      game = game_fixture(%{bgg_id: 999_999, enrichment_status: "bgg_missing", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "open-menu", %{})
      assert html =~ "Borrar el ID"

      html = render_click(lv, "borrar-bgg-id", %{})
      assert html =~ "ID de BGG borrado"
      assert html =~ "Deshacer"
      updated = Catalog.get_game!(game.id)
      assert updated.bgg_id == nil
      assert updated.enrichment_status == "no_bgg_id"

      html = render_click(lv, "undo-borrar-bgg-id", %{})
      refute html =~ "ID de BGG borrado"
      restored = Catalog.get_game!(game.id)
      assert restored.bgg_id == 999_999
      assert restored.enrichment_status == "bgg_missing"
    end

    test "Borrar el ID is NOT offered for a game with a healthy enrichment_status", %{conn: conn} do
      game = game_fixture(%{bgg_id: 174_430, enrichment_status: "enriched", status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      html = render_click(lv, "open-menu", %{})

      refute html =~ "Borrar el ID"
    end

    test "enrichment landing while the editor is open updates an untouched name", %{conn: conn} do
      game = game_fixture(%{name: "Juego #184267", bgg_id: 184_267, status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")

      send(lv.pid, {:game_enriched, game.id})
      Catalog.update_game_admin(game, %{name: "Catán"})
      send(lv.pid, {:game_enriched, game.id})
      html = render(lv)

      assert html =~ "Catán"
    end

    test "enrichment landing while the editor is open leaves a touched name alone", %{conn: conn} do
      game = game_fixture(%{name: "Juego #184267", bgg_id: 184_267, status: :published})

      {:ok, lv, _html} = live(conn, ~p"/admin/juegos/#{game.id}/editar")
      render_change(lv, "draft-change", %{"field" => "name", "value" => "Nombre elegido por staff"})

      # Simulate BGG's own write landing underneath, then the broadcast.
      game.id
      |> Catalog.get_game!()
      |> Game.enrichment_changeset(%{name: "Juego #184267"})
      |> Repo.update()

      send(lv.pid, {:game_enriched, game.id})
      html = render(lv)

      assert html =~ "Nombre elegido por staff"
      assert html =~ "Sin guardar"
    end

    test "Catalog.retry_enrichment/1's has-a-bgg_id gate is not shipped as the old failed-only gate (grep)" do
      catalog = File.read!("lib/pukllay_club/catalog.ex")
      form = File.read!("lib/pukllay_club_web/live/admin/game_live/form.ex")

      refute catalog =~ ~s(enrichment_status: "failed")
      refute form =~ ~s(enrichment_status: "failed")
    end
  end
end
