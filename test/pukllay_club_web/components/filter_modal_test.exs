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

    test "renders the live match count via CatalogLive.Index.result_count_text/1" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 1
        })

      assert html =~ "1 juego encontrado"

      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          total: 12
        })

      assert html =~ "12 juegos encontrados"
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

    test "facet pills dispatch toggle-facet with the value/facet pair, selected state reflected in aria-pressed" do
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

      assert html =~ ~s(phx-click="toggle-facet")
      assert html =~ ~s(phx-value-facet="mechanics")
      assert html =~ ~s(phx-value-value="Tira dados")
      # HEEx renders a Boolean assign on a recognized aria-* attribute as a
      # bare present/absent attribute, not a "true"/"false" string — same
      # behavior the retired FilterDrawer's identical `aria-pressed={@selected}`
      # already relied on; badge-primary is this pill's own selected-state signal.
      assert html =~ "aria-pressed"
      assert html =~ "badge-primary"
    end

    test "scalar inputs live in one set-scalar form" do
      html =
        render_component(&FilterModal.filter_modal/1, %{
          id: "filter-modal",
          facet_options: @empty_facet_options,
          players: 4
        })

      assert html =~ ~s(phx-change="set-scalar")
      assert html =~ ~s(name="players")
      assert html =~ ~s(name="max_playtime")
      assert html =~ ~s(name="min_age")
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
  end
end
