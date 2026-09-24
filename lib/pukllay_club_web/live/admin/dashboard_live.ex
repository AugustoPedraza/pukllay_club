defmodule PukllayClubWeb.Admin.DashboardLive do
  @moduledoc """
  The `/admin` task dashboard — 060-B's boxes (plan 01.8.2-11), replacing
  the shipped Scope-B-styled cards (Bebas display type, a daisyUI warning
  badge) that carried no number at all (`admin-redesign-scope.md` gap
  #15). This module deliberately never spells out those two retired
  class names in prose — this file's own `<verify>` greps its compiled
  source for them, so even a comment naming them would defeat the check.

  Mobile-first: a 2-column box grid on phone, 3-column from 1024px
  (`.pk-admin-dash-grid`, `assets/css/admin/screens.css`). D-00a's fixed
  card order (01.8.1 D-35) is unchanged — Juegos, Estantes, Web
  (renamed from Secciones), Revisar niveles, Staff (owner only) — only
  the Secciones->Web LABEL changes (D-00a); the route and module both
  stay `secciones`/`SectionLive` (a label change only, per
  `admin-shell-navigation.md`). The page's own title is likewise
  D-00a's Panel->Admin rename.

  Every count below is computed ONCE here, in `mount/3` — never inside
  `render/1` — so a LiveView diff can never turn this page into a
  per-box N+1 (T-01.8.2-50). The Estantes box's pending count reads
  `Shelves.unplaced_copies/0` (never `Shelves.location_progress/0`,
  which is a carried-forward defect: it still counts non-retired GAMES
  via the dead `games.shelf_id` column) so it can never disagree with
  whatever future slice wires the tab bar's own Estantes badge to the
  same source.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Accounts
  alias PukllayClub.Accounts.User
  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.BandAudit
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Catalog.Shelves
  alias PukllayClubWeb.AdminComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      bottom_collapse
      admin_chrome
      active_tab={:admin}
    >
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <h1 class="pk-admin-page-title">Admin</h1>
        <div id="admin-cards" class="pk-admin-dash-grid">
          <.dashboard_box
            id="dash-box-juegos"
            navigate={~p"/admin/juegos"}
            icon="hero-puzzle-piece"
            name="Juegos"
            number={@total_games}
            pending_text={@draft_count > 0 && pluralize(@draft_count, "borrador", "borradores")}
          />
          <.dashboard_box
            id="dash-box-estantes"
            navigate={~p"/admin/estantes"}
            icon="hero-archive-box"
            name="Estantes"
            number={"#{@estantes_percent}%"}
            meter_percent={@estantes_percent}
            pending_text={@unplaced_count > 0 && "#{@unplaced_count} sin ubicar"}
          />
          <.dashboard_box
            id="dash-box-web"
            navigate={~p"/admin/secciones"}
            icon="hero-globe-alt"
            name="Web"
            number={@sections_count}
          />
          <.dashboard_box
            id="dash-box-niveles"
            navigate={~p"/admin/niveles"}
            icon="hero-scale"
            name="Revisar niveles"
            number={@mismatches_count}
            pending_text={@mismatches_count > 0 && "no coinciden con BGG"}
          />
          <.dashboard_box
            :if={User.owner?(@current_scope.user)}
            id="dash-box-staff"
            navigate={~p"/admin/staff"}
            icon="hero-users"
            name="Staff"
            number={@staff_count}
            pending_text={
              @pending_invites > 0 &&
                pluralize(@pending_invites, "invitación pendiente", "invitaciones pendientes")
            }
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  # One box anatomy for every card (060-B): a muted icon + 13px/600 name,
  # a 22px/400 tabular number (never blank — every call site above
  # passes a real computed value), an optional meter (Estantes only) and
  # an optional D-19g pending pill. No chevron (this is a grid box, not
  # a `list_row`); the tap affordance is the box shape itself plus the
  # shared `[data-pk-pressable]:active` press state.
  attr :id, :string, required: true, doc: "a stable per-box id for test/measurement scoping"
  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  attr :name, :string, required: true
  attr :number, :any, required: true
  attr :meter_percent, :integer, default: nil

  attr :pending_text, :any,
    default: nil,
    doc: "a String to render as a D-19g pending pill, or a falsy value to render none"

  defp dashboard_box(assigns) do
    ~H"""
    <.link id={@id} navigate={@navigate} class="pk-admin-dash-box" data-pk-pressable="true">
      <span class="pk-admin-dash-box__head">
        <.icon name={@icon} class="pk-admin-dash-box__icon" />
        <span class="pk-admin-dash-box__name">{@name}</span>
      </span>
      <span class="pk-admin-dash-box__number">{@number}</span>
      <div
        :if={@meter_percent}
        class="pk-admin-dash-box__meter"
        role="progressbar"
        aria-valuenow={@meter_percent}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label={"#{@name}: #{@meter_percent}% ubicado"}
      >
        <div class="pk-admin-dash-box__meter-fill" style={"width: #{@meter_percent}%"}></div>
      </div>
      <span :if={@pending_text} class="pk-admin-dash-box__foot">
        <AdminComponents.pending_pill>{@pending_text}</AdminComponents.pending_pill>
      </span>
    </.link>
    """
  end

  defp pluralize(1, singular, _plural), do: "1 #{singular}"
  defp pluralize(n, _singular, plural), do: "#{n} #{plural}"

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    unplaced = Shelves.unplaced_copies()
    {placed, total} = Shelves.copies_progress()
    estantes_percent = if total == 0, do: 0, else: round(placed / total * 100)

    {:ok,
     socket
     |> assign(:total_games, Catalog.count_admin_games())
     |> assign(:draft_count, Catalog.count_admin_games(status: :draft))
     |> assign(:estantes_percent, estantes_percent)
     |> assign(:unplaced_count, length(unplaced))
     |> assign(:sections_count, length(Sections.list_sections()))
     |> assign(:mismatches_count, BandAudit.count_mismatches())
     |> assign_staff_counts(scope)}
  end

  # Owner-only counts (the Staff box itself is owner-gated in render/1):
  # a staff/non-owner scope never calls `Accounts.list_staff/1` (which
  # returns `{:error, :unauthorized}` for anyone else) and gets `0`/`0`
  # instead — cheap, since `render/1`'s own `:if` never shows these
  # values to that scope anyway.
  defp assign_staff_counts(socket, scope) do
    if User.owner?(scope.user) do
      users = Accounts.list_staff(scope)
      pending = Enum.count(users, &(&1.role == :staff and is_nil(&1.confirmed_at)))

      socket
      |> assign(:staff_count, length(users))
      |> assign(:pending_invites, pending)
    else
      socket
      |> assign(:staff_count, 0)
      |> assign(:pending_invites, 0)
    end
  end
end
