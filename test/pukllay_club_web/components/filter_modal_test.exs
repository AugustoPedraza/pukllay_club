defmodule PukllayClubWeb.FilterModalTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.FilterModal

  @empty_facet_options %{mechanics: [], themes: [], weight_bands: [], editorial_tags: []}

  describe "filter_modal/1 rendering" do
    test "closed by default: renders without the modal-open class" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      # data-modal-open="false" (the hook's own state attribute) legitimately
      # contains "modal-open" as a substring — check the daisyUI CLASS token
      # specifically, not a raw substring of the whole markup.
      refute html =~ "class=\"modal modal-open\""
      assert html =~ "class=\"modal "
      assert html =~ ~s(data-modal-open="false")
    end

    test "open: true renders the modal-open class" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          open: true
        })

      assert html =~ "modal-open"
    end

    test "renders the search input bound to the search event, debounced" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          q: "catan"
        })

      assert html =~ ~s(phx-change="search")
      assert html =~ ~s(phx-debounce="300")
      assert html =~ "catan"
    end

    test "renders the CTA label with the live total, singular and plural" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 1
        })

      assert html =~ "Ver 1 juego"

      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 12
        })

      assert html =~ "Ver 12 juegos"
    end

    test "the root element carries daisyUI's bottom-sheet/centered-dialog responsive modifiers" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html =~ "modal-bottom"
      assert html =~ "sm:modal-middle"
    end

    test "the clear-filters button is disabled when filters_active is unset/false, enabled when true, and carries no outline (sketch 019 ghost treatment)" do
      # Scoped to the "btn-ghost min-h-11" class combo, unique to this footer
      # button (the CTA is "btn btn-primary min-h-11" with no btn-ghost) —
      # HEEx does not preserve attribute-write order for global/rest attrs,
      # so a naive "attr-A ... attr-B" regex is fragile.
      clear_button_class = "btn-ghost min-h-11"

      html_inactive =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html_inactive =~
               ~r/<button[^>]*#{clear_button_class}[^>]*disabled[^>]*clear-filters/

      refute html_inactive =~ "btn-outline"

      html_active =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          filters_active: true
        })

      refute html_active =~
               ~r/<button[^>]*#{clear_button_class}[^>]*disabled[^>]*clear-filters/
    end

    test "close button and backdrop both dispatch close-filters, meet the 44px touch floor" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html =~ ~s(phx-click="close-filters")
      assert html =~ "min-h-11 min-w-11"
      assert html =~ ~s(aria-label="Cerrar filtros")
    end

    test "carries dialog accessibility attributes" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
    end

    test "facet pills dispatch toggle-facet with the choice/facet pair, selected state reflected in aria-pressed" do
      # weight_bands (Nivel), not mechanics — Task 3 moved mechanics/themes
      # off the badge-pill treatment into the checklist inside the
      # disclosure; weight_bands is still rendered via facet_pill/1.
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: [],
            themes: [],
            weight_bands: [%{value: "ingenio_estratega", label: "Ingenio estratega"}],
            editorial_tags: []
          },
          weight_bands: ["ingenio_estratega"]
        })

      assert html =~ ~s(phx-click="toggle-facet")
      assert html =~ ~s(phx-value-facet="weight_bands")
      # `choice`, not `value` — a `phx-value-value` binding on a <button> is
      # silently clobbered by the element's native `.value` DOM property in
      # LiveView's client-side extractMeta (see FilterModal's moduledoc).
      assert html =~ ~s(phx-value-choice="ingenio_estratega")
      refute html =~ "phx-value-value"
      # HEEx renders a Boolean assign on a recognized aria-* attribute as a
      # bare present/absent attribute, not a "true"/"false" string — same
      # behavior the retired FilterDrawer's identical `aria-pressed={@selected}`
      # already relied on; `pk-pill-selected` is this pill's own
      # selected-state signal (G-01.2-27 task 2 — was `badge-primary` before
      # the migration onto the shared pill base).
      assert html =~ "aria-pressed"
      assert html =~ "pk-pill-selected"
    end

    # G-01.2-27 task 2: pins the two states apart so they cannot collapse
    # into each other unnoticed — a selected chip must carry the selected
    # tone and never the outline tone, and vice versa.
    test "an unselected facet pill carries the outline tone, never the selected tone" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: [],
            themes: [],
            weight_bands: [%{value: "ingenio_estratega", label: "Ingenio estratega"}],
            editorial_tags: []
          }
        })

      doc = LazyHTML.from_document(html)

      chip_classes =
        doc
        |> LazyHTML.query(~s(button[phx-value-facet="weight_bands"]))
        |> LazyHTML.attribute("class")

      assert chip_classes != []

      for class_list <- chip_classes do
        tokens = String.split(class_list)

        assert "pk-pill" in tokens
        assert "pk-pill-outline" in tokens
        refute "pk-pill-selected" in tokens
      end
    end

    test "Jugadores and Duración máxima render as toggle-scalar chip clusters, not number inputs" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          players: 4,
          max_playtime: 60
        })

      assert html =~ ~s(phx-click="toggle-scalar")
      assert html =~ ~s(phx-value-scalar="players")
      assert html =~ ~s(phx-value-scalar="max_playtime")
      assert html =~ "60 min"
      refute html =~ "Hasta"
      refute html =~ ~s(type="number")
      refute html =~ ~s(phx-change="set-scalar")
    end

    test "renders the open-ended '6+' Jugadores chip riding the players scalar" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          players: 6
        })

      assert html =~ "6+"
      assert html =~ ~s(phx-value-scalar="players" phx-value-choice="6")
    end

    test "renders a clear-filters button" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html =~ ~s(phx-click="clear-filters")
      assert html =~ "Limpiar filtros"
    end

    test "renders the new title, subtitle, and search placeholder (sketch 019)" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html =~ "Encuentra tu juego"
      assert html =~ "Combina filtros para llegar a los juegos que te interesan."
      assert html =~ "¿Qué juego buscas?"
    end

    test "the editorial-hashtag group renders nowhere, even when editorial_tags is non-empty" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: [],
            themes: [],
            weight_bands: [],
            editorial_tags: [%{tag: "#CreaConexiones", meaning: "x"}]
          },
          tags: ["#CreaConexiones"]
        })

      refute html =~ "CreaConexiones"
      refute html =~ ~s(phx-value-facet="tags")
      refute html =~ "Destacados"
    end

    test "Jugadores, Duración máxima, Nivel, and the disclosure each sit inside a rounded, surface-tinted card" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html |> String.split("rounded-box") |> length() |> Kernel.-(1) >= 4
      assert html |> String.split("bg-base-200") |> length() |> Kernel.-(1) >= 4
    end
  end

  describe "mecánica/temática disclosure (quick-260824-b71)" do
    test "renders closed when mechanics and themes are both empty" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      refute html =~ ~r/<details[^>]*id="filter-modal-more"[^>]*\sopen/
    end

    test "renders open when a mechanic is already selected" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: ["Tira dados"],
            themes: [],
            weight_bands: [],
            editorial_tags: []
          },
          mechanics: ["Tira dados"]
        })

      assert html =~ ~r/<details[^>]*id="filter-modal-more"[^>]*\sopen/
    end

    test "renders open when a theme is already selected" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: [],
            themes: ["Fantasía"],
            weight_bands: [],
            editorial_tags: []
          },
          themes: ["Fantasía"]
        })

      assert html =~ ~r/<details[^>]*id="filter-modal-more"[^>]*\sopen/
    end

    test "a checklist row carries data-fc-row, toggle-facet and the matching phx-value-facet" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: ["Tira dados"],
            themes: [],
            weight_bands: [],
            editorial_tags: []
          }
        })

      assert html =~ ~s(data-fc-row="Tira dados")
      assert html =~ ~s(phx-click="toggle-facet")
      assert html =~ ~s(phx-value-facet="mechanics")
    end

    test "the count suffix renders (2) for two selected mechanics" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: %{
            mechanics: ["Tira dados", "Coloca trabajadores"],
            themes: [],
            weight_bands: [],
            editorial_tags: []
          },
          mechanics: ["Tira dados", "Coloca trabajadores"]
        })

      assert html =~ "(2)"
    end

    test "both checklists carry the max-h-40 list cap and a data-fc-input search box" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      assert html =~ ~s(data-fc-list="mechanics")
      assert html =~ ~s(data-fc-list="themes")
      assert html =~ ~s(data-fc-input="mechanics")
      assert html =~ ~s(data-fc-input="themes")
      assert html =~ "max-h-40"
    end

    test "there is no age filter control and no Edad mínima label" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options
        })

      refute html =~ "Edad mínima"
      refute html =~ "Edad del jugador"
      refute html =~ ~s(phx-value-scalar="min_age")
    end
  end

  describe "footer CTA geometry (Task 2, G-01.2-4 defect C)" do
    test "the primary action carries a Tailwind named min-width class and tabular-nums" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 1
        })

      assert html =~ ~r/<button[^>]*btn-primary[^>]*min-w-\d+[^>]*tabular-nums[^>]*>/
    end

    test "the label still changes as the count changes — liveness was not traded away for the fixed width" do
      html1 =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 1
        })

      html2 =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 42
        })

      assert html1 =~ "Ver 1 juego"
      assert html2 =~ "Ver 42 juegos"
    end
  end
end
