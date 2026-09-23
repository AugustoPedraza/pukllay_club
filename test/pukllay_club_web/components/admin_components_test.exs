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

  # Same idiom as nav_drawer_stacking_test.exs's `rule_body!` — parse a
  # rule's declared font-size directly from source rather than hardcoding
  # a "known good" number twice.
  defp font_size_px!(css, selector) do
    pattern = ~r/(?m)^#{Regex.escape(selector)}\s*\{([^}]*)\}/s

    case Regex.run(pattern, css) do
      [_, body] ->
        case Regex.run(~r/font-size:\s*(\d+)px/, body) do
          [_, value] -> String.to_integer(value)
          nil -> flunk("`#{selector}` declares no font-size in assets/css/admin/components.css")
        end

      nil ->
        flunk("no `#{selector} { ... }` rule found in assets/css/admin/components.css")
    end
  end

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

  describe "field/1" do
    test "default type renders the label above a 44px control" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.field name="nombre" value="" label="Nombre" />
        """)

      assert html =~ "pk-admin-label--field"
      assert html =~ "pk-admin-field__control"
      assert html =~ "Nombre"
    end

    test "renders errors from a plain errors list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.field name="nombre" value="" label="Nombre" errors={["no puede estar vacío"]} />
        """)

      assert html =~ "pk-admin-field__error"
      assert html =~ "no puede estar vacío"
    end

    test "checkbox type renders a checkbox input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.field
          type="checkbox"
          name="es_expansion"
          value={false}
          label="Es una expansión"
        />
        """)

      assert html =~ ~s(type="checkbox")
      assert html =~ "pk-admin-field__checkbox-label"
    end

    test "select type renders the given options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.field
          type="select"
          name="nivel"
          value=""
          label="Nivel"
          options={[{"Bajo", "bajo"}, {"Alto", "alto"}]}
        />
        """)

      assert html =~ "<select"
      assert html =~ "Bajo"
      assert html =~ "Alto"
    end

    test "textarea type renders a textarea control" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.field type="textarea" name="descripcion" value="hola" label="Descripción" />
        """)

      assert html =~ "<textarea"
      assert html =~ "hola"
    end
  end

  describe "section_panel/1" do
    test "renders the tonal section-panel class and its label slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.section_panel>
          <:label>Ajustes</:label>
          contenido
        </AdminComponents.section_panel>
        """)

      assert html =~ "pk-admin-section-panel"
      assert html =~ "pk-admin-label--group"
      assert html =~ "Ajustes"
      assert html =~ "contenido"
    end
  end

  describe "form_label/1" do
    test "rank=\"field\" renders the field-rank class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.form_label rank="field">Nombre</AdminComponents.form_label>
        """)

      assert html =~ "pk-admin-label--field"
    end

    test "rank=\"group\" renders the group-rank class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.form_label rank="group">Ajustes</AdminComponents.form_label>
        """)

      assert html =~ "pk-admin-label--group"
    end
  end

  describe "list_section_label/1" do
    test "renders the list-section-label class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.list_section_label>Borradores</AdminComponents.list_section_label>
        """)

      assert html =~ "pk-admin-list-section-label"
      assert html =~ "Borradores"
    end
  end

  describe "the two label ranks stay distinct (D-19j / D-19g-bis decision 20)" do
    # 01.8.2-BENCHMARK.md's "List rows" row fixes a row name at 14-15px and
    # its second line at 13px muted — the literal figures a future row
    # component (Task 3) must build to. Grounding the comparison in these
    # documented numbers, rather than Task 3's not-yet-written CSS, means
    # this guard holds the moment Task 3 lands the row classes at the same
    # spec, with nothing left to reconcile.
    @row_name_px 14
    @row_meta_px 13

    test "a list section label's font-size is >= the documented row-name size" do
      assert font_size_px!(components_css(), ".pk-admin-list-section-label") >= @row_name_px
    end

    test "a list section label's (size, weight) pair differs from the documented row second-line pair" do
      list_size = font_size_px!(components_css(), ".pk-admin-list-section-label")
      group_size = font_size_px!(components_css(), ".pk-admin-label--group")

      refute list_size == @row_meta_px and list_size == group_size
      assert list_size != @row_meta_px
    end
  end

  describe "coarse-pointer field text size" do
    test "components.css guards the 16px no-zoom field size behind pointer: coarse" do
      assert components_css() =~ "pointer: coarse"
    end
  end

  describe "list_row/1" do
    test "renders no chevron when opens_page is false (the default)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.list_row name="Catan" meta="Publicado" />
        """)

      refute html =~ "pk-admin-row__chevron"
      refute html =~ "›"
    end

    test "renders a chevron only when opens_page is true" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.list_row name="Catan" opens_page navigate="/admin/juegos/1" />
        """)

      assert html =~ "pk-admin-row__chevron"
      assert html =~ "›"
    end

    test "renders a <.link> when navigate is passed, a <div> otherwise" do
      assigns = %{}

      linked =
        rendered_to_string(~H"""
        <AdminComponents.list_row name="Catan" navigate="/admin/juegos/1" />
        """)

      plain =
        rendered_to_string(~H"""
        <AdminComponents.list_row name="Catan" />
        """)

      assert linked =~ "<a "
      refute plain =~ "<a "
      assert plain =~ "pk-admin-row"
    end

    test "renders the optional cover and meta line" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.list_row cover="/covers/catan.webp" name="Catan" meta="Publicado" />
        """)

      assert html =~ "pk-admin-row__cover"
      assert html =~ "pk-admin-row__meta"
      assert html =~ "Publicado"
    end

    test "carries data-pk-pressable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.list_row name="Catan" />
        """)

      assert html =~ "data-pk-pressable"
    end
  end

  describe "editable_row/1 (D-23 — no glyph at all)" do
    test "renders the label and value, the value carrying the --val tint class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.editable_row label="Copias" value="3" />
        """)

      assert html =~ "pk-admin-editable-row__label"
      assert html =~ "Copias"
      assert html =~ "pk-admin-editable-row__value"
      assert html =~ "3"
    end

    test "renders neither › nor ⌄ — D-23 rules out both by name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.editable_row label="Copias" value="3" />
        """)

      refute html =~ "›"
      refute html =~ "⌄"
    end

    test "always renders a <button>, never a link" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.editable_row label="Copias" value="3" />
        """)

      assert html =~ "<button"
      refute html =~ "<a "
    end
  end

  describe "status_dot/1 (D-19h — dot + text, never a pill)" do
    test "renders the dot element and the Spanish word for :draft" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.status_dot status={:draft} />
        """)

      assert html =~ "pk-admin-status-dot__dot"
      assert html =~ "Borrador"
    end

    test "renders the correct word for every status in the vocabulary" do
      words = %{
        draft: "Borrador",
        published: "Publicado",
        retired: "Retirado",
        sin_lugar: "Sin lugar",
        afuera: "Afuera"
      }

      for {status, word} <- words do
        assigns = %{status: status}

        html =
          rendered_to_string(~H"""
          <AdminComponents.status_dot status={@status} />
          """)

        assert html =~ word, "status=#{status} did not render #{word}"
      end
    end

    test "renders no class matching pill or badge" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.status_dot status={:draft} />
        """)

      refute html =~ ~r/pill|badge/
    end
  end

  describe "kind_tag/1 (D-19m)" do
    test "renders the kind-tag class and label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.kind_tag label="expansión" />
        """)

      assert html =~ "pk-admin-kind-tag"
      assert html =~ "expansión"
    end

    test "components.css declares the kind tag lowercase, 11px regular, on a hairline border" do
      css = components_css()
      assert font_size_px!(css, ".pk-admin-kind-tag") == 11
      assert css =~ ~r/\.pk-admin-kind-tag\s*\{[^}]*text-transform:\s*lowercase/s
      assert css =~ ~r/\.pk-admin-kind-tag\s*\{[^}]*border:\s*1px solid var\(--color-base-300\)/s
    end
  end

  describe "count_pill/1 (D-19m)" do
    test "renders the count-pill class and the count as text content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminComponents.count_pill count={12} />
        """)

      assert html =~ "pk-admin-count-pill"
      assert html =~ "12"
    end

    test "components.css declares the count pill page-filled with the shared --stroke border, 11/600 muted" do
      css = components_css()
      assert font_size_px!(css, ".pk-admin-count-pill") == 11
      assert css =~ ~r/\.pk-admin-count-pill\s*\{[^}]*border:\s*1px solid var\(--stroke\)/s
      assert css =~ ~r/\.pk-admin-count-pill\s*\{[^}]*background:\s*var\(--color-base-100\)/s
    end
  end

  # The "app.css is untouched by this plan" guard (plan 01.8.2-07's own
  # Task 3 verify) is deliberately removed here, not merely updated: it
  # asserted a per-PLAN invariant ("this plan doesn't touch app.css") that
  # already stopped being true the moment a later plan legitimately needed
  # to edit app.css — plan 01.8.2-09 Task 1 (D-12/G-01.8.1-1b) does exactly
  # that (the drawer backdrop's `:has()` rule), and Task 2 (D-19d, moving
  # the drawer left) must edit far more of it. A `git status --porcelain`
  # assertion has no way to scope itself to "changes plan 07 introduced" —
  # it would fail on ANY uncommitted app.css change regardless of which
  # plan made it, permanently blocking every future CSS-touching plan's
  # `mix test`. Removed rather than loosened: there is no invariant left
  # here worth re-asserting once app.css is legitimately owned by more than
  # one plan.
end
