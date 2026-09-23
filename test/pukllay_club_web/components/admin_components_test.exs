defmodule PukllayClubWeb.AdminComponentsTest do
  @moduledoc """
  D-18's admin component module — the atoms every `/admin` screen composes
  from. Grows across plans 01.8.2-07 (Task 1: `action/1`) and its own later
  tasks (`field/1`, `section_panel/1`, `form_label/1`, `list_section_label/1`,
  `list_row/1`, `editable_row/1`, `status_dot/1`, `kind_tag/1`,
  `count_pill/1`). Ports the A-series checks from
  `.planning/sketches/064-admin-button-system/audit-admin.js` that are
  expressible against rendered markup (no headless browser here); the
  geometry-only checks that need a real computed style go to plan
  01.8.2-12's CDP harness instead.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias PukllayClubWeb.AdminComponents

  @components_css_path Path.expand("../../../assets/css/admin/components.css", __DIR__)

  defp components_css, do: File.read!(@components_css_path)

  describe "action/1 — A1 outlined" do
    test "renders the a1 anatomy and principal role classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a1" role="principal">Guardar</AdminComponents.action>
        """)

      assert html =~ "pk-admin-action--a1"
      assert html =~ "pk-admin-action--principal"
      assert html =~ "Guardar"
    end

    test "renders the secundaria role on a1" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a1" role="secundaria">Ordenar</AdminComponents.action>
        """)

      assert html =~ "pk-admin-action--a1"
      assert html =~ "pk-admin-action--secundaria"
    end
  end

  describe "action/1 — A2 text" do
    test "renders the a2 anatomy with the terciaria role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a2" role="terciaria">Nuevo estante</AdminComponents.action>
        """)

      assert html =~ "pk-admin-action--a2"
      assert html =~ "pk-admin-action--terciaria"
    end

    test "renders the a2 anatomy with the peligro role" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a2" role="peligro">Retirar de la web</AdminComponents.action>
        """)

      assert html =~ "pk-admin-action--a2"
      assert html =~ "pk-admin-action--peligro"
    end
  end

  describe "action/1 — A3 icon" do
    test "renders the a3 anatomy when an aria-label is supplied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a3" role="terciaria" aria-label="Opciones">
          x
        </AdminComponents.action>
        """)

      assert html =~ "pk-admin-action--a3"
      assert html =~ ~s(aria-label="Opciones")
    end

    test "raises without an aria-label — an icon-only control cannot ship unlabelled" do
      assigns = %{}

      assert_raise ArgumentError, ~r/aria-label/, fn ->
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a3" role="terciaria">x</AdminComponents.action>
        """)
      end
    end
  end

  describe "action/1 — A4 sheet row" do
    test "renders the a4 anatomy" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a4" role="principal">Guardar</AdminComponents.action>
        """)

      assert html =~ "pk-admin-action--a4"
    end
  end

  describe "action/1 — element choice" do
    test "renders a <.link> when navigate is passed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a1" role="secundaria" navigate="/admin/juegos">
          Ver juegos
        </AdminComponents.action>
        """)

      assert html =~ "<a "
      assert html =~ ~s(href="/admin/juegos")
    end

    test "renders a <button type=\"button\"> when no href/navigate/patch is passed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a1" role="principal">Guardar</AdminComponents.action>
        """)

      assert html =~ ~s(type="button")
      refute html =~ "<a "
    end
  end

  describe "action/1 — disabled (D-24)" do
    test "raises when disabled is passed without commit, naming D-24" do
      assigns = %{}

      assert_raise ArgumentError, ~r/D-24/, fn ->
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a1" role="principal" disabled>Guardar</AdminComponents.action>
        """)
      end
    end

    test "renders disabled when commit is true, with the muted disabled class and no inline opacity" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.action anatomy="a1" role="principal" commit disabled>
          Guardar
        </AdminComponents.action>
        """)

      assert html =~ "disabled"
      assert html =~ "pk-admin-action--disabled"
      refute html =~ "opacity"
    end
  end

  describe "action/1 — press state" do
    test "every anatomy carries data-pk-pressable" do
      for anatomy <- ~w(a1 a2 a3 a4) do
        role = if anatomy == "a1", do: "principal", else: "terciaria"
        assigns = %{anatomy: anatomy, role: role}

        html =
          rendered_to_string(~H"""
          <AdminComponents.action anatomy={@anatomy} role={@role} aria-label="x">
            x
          </AdminComponents.action>
          """)

        assert html =~ "data-pk-pressable", "anatomy=#{anatomy} is missing data-pk-pressable"
      end
    end
  end

  describe "prohibitions — no daisyUI filled/ghost classes, no opacity on disabled" do
    test "components.css never declares a bare opacity property" do
      refute components_css() =~ ~r/(?<![-\w])opacity\s*:/
    end

    test "components.css never references a daisyUI filled/ghost/modal-action class" do
      refute components_css() =~ ~r/btn-primary|btn-outline|btn-ghost|btn-error|modal-action/
    end
  end
end
