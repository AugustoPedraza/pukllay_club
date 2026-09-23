defmodule PukllayClubWeb.Admin.AdminCompositionTest do
  @moduledoc """
  Holds every rebuilt admin LiveView to D-18: "neither screen hand-rolls
  a button, a row, a sheet or a dialog — every one comes from
  `PukllayClubWeb.AdminComponents`." Plan 01.8.2-11 (Task 3) is the
  first to write this guard, seeded with the two screens that same plan
  rebuilt (`dashboard_live.ex`, `staff_live/index.ex`, D-18/D-19h/D-19i).

  Two independent checks run against every file in `@files`:

    1. **Negative** — none of `@retired_patterns` (the eleven daisyUI/
       hand-rolled chrome class names 065/D-19h/D-19j/`admin-redesign-
       scope.md`'s gap table replace) may appear in the file's SOURCE,
       comment lines (`#...`) excluded — a `#` comment explaining what
       was removed cannot fail its own guard, but a `@moduledoc`/`@doc`
       string literal is NOT exempt (mirrors this plan's own per-task
       `<verify>` greps, which use the identical `^\s*#` filter).
    2. **Positive** — the same file must reference `AdminComponents`
       (fully qualified, or an imported unqualified call to one of its
       component names) — so a file that simply stopped using daisyUI
       WITHOUT adopting the module cannot pass by being empty of both
       (`admin-redesign-scope.md` gap #10: "Touches all 9 files").

  **Contract for later plans (`mix test test/pukllay_club_web/live/admin/`
  runs this on every `mix test`):** appending a rebuilt screen here is a
  ONE-LINE change to `@files` below — add the new LiveView's path, run
  the suite, and both checks apply to it automatically. The plans that
  are expected to do this, in order: 01.8.2-13, 01.8.2-14, 01.8.2-15,
  01.8.2-18, 01.8.2-19, 01.8.2-20.
  """
  use ExUnit.Case, async: true

  # Plan 01.8.2-11's own two rebuilt screens. Append future screens here,
  # one path per line — see the moduledoc's "Contract for later plans".
  @files [
    "lib/pukllay_club_web/live/admin/dashboard_live.ex",
    "lib/pukllay_club_web/live/admin/staff_live/index.ex",
    "lib/pukllay_club_web/live/admin/estante_live/index.ex",
    "lib/pukllay_club_web/live/admin/game_live/index.ex",
    "lib/pukllay_club_web/live/admin/section_live/index.ex",
    "lib/pukllay_club_web/live/admin/section_live/edit.ex",
    "lib/pukllay_club_web/live/admin/band_audit_live.ex"
  ]

  # The eleven retired patterns this guard exists to catch — the exact
  # set named across 065/D-19h/D-19j and `admin-redesign-scope.md`'s gap
  # table (daisyUI filled/ghost buttons, the ad-hoc confirmation modal,
  # the three status badge colours, and the Bebas-display page title).
  @retired_patterns ~w(
    btn-primary
    btn-outline
    btn-ghost
    btn-error
    btn-square
    modal-open
    modal-action
    badge-warning
    badge-success
    badge-neutral
    font-display
  )

  # Any of AdminComponents' own component names, for the positive check's
  # unqualified-call fallback (a file that `import`s the module and calls
  # `<.action>` rather than `<AdminComponents.action>`).
  @component_names ~w(
    action field section_panel form_label list_section_label list_row
    editable_row status_dot kind_tag count_pill pending_pill sheet dialog
    snackbar save_bar back_row page_bar
  )

  describe "D-18 composition guard" do
    test "no listed admin screen contains a retired chrome pattern (comment lines excluded)" do
      for file <- @files do
        source = source_without_comments!(file)

        for pattern <- @retired_patterns do
          refute source =~ pattern,
                 "#{file} still contains the retired pattern #{inspect(pattern)} — " <>
                   "D-18 requires this to come from AdminComponents instead"
        end
      end
    end

    test "every listed admin screen references AdminComponents (or one of its component names)" do
      component_call_pattern =
        ~r/<\.(#{Enum.join(@component_names, "|")})\b/

      for file <- @files do
        source = File.read!(file)

        assert source =~ "AdminComponents" or source =~ component_call_pattern,
               "#{file} references neither AdminComponents nor any of its imported " <>
                 "component names — a file that only stopped using daisyUI without " <>
                 "adopting the module must not pass this guard"
      end
    end
  end

  defp source_without_comments!(file) do
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.trim_leading() |> String.starts_with?("#")))
    |> Enum.join("\n")
  end
end
