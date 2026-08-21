defmodule PukllayClubWeb.FilterDrawerTest do
  use PukllayClubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PukllayClubWeb.FilterDrawer

  @empty_facet_options %{mechanics: [], themes: [], weight_bands: [], editorial_tags: []}

  describe "filter_drawer/1 wrapper sizing" do
    # Regression guard for the 2026-08-18 sort-dropdown-overlap todo: daisyUI's
    # `.drawer` is `display: grid` with an `auto`-sized first track. `w-auto`
    # on the wrapper let that track collapse below the "Filtros" label's own
    # content width (measured 58-70px track vs 102px label), so the label
    # overflowed its grid cell and painted over the adjacent sort <select>.
    # `w-fit` keeps the grid track content-driven; `shrink-0` stops the flex
    # parent (`index.ex`'s toolbar row) from squeezing it back down.
    test "wrapper carries content-fitting, non-shrinking width utilities" do
      html = render_component(&FilterDrawer.filter_drawer/1, %{id: "filter-drawer", facet_options: @empty_facet_options})

      assert html =~ "w-fit"
      assert html =~ "shrink-0"
    end

    # Guards against reintroducing the collapsing width override this fix
    # removes — see the todo diagnosis above.
    test "wrapper no longer carries the collapsing w-auto override" do
      html = render_component(&FilterDrawer.filter_drawer/1, %{id: "filter-drawer", facet_options: @empty_facet_options})

      refute html =~ "w-auto"
    end

    test "trigger label still renders its hit-target floor and the Filtros text" do
      html = render_component(&FilterDrawer.filter_drawer/1, %{id: "filter-drawer", facet_options: @empty_facet_options})

      assert html =~ "min-h-11"
      assert html =~ "Filtros"
    end
  end
end
