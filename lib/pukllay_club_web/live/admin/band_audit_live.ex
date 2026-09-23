defmodule PukllayClubWeb.Admin.BandAuditLive do
  @moduledoc """
  Revisar niveles at `/admin/niveles` (D-29, D-30, D-19h, D-19i, D-19j,
  SC-5, R1 #10) — lists every non-retired game whose club `weight_band`
  disagrees with the band implied by its `bgg_weight`
  (`Catalog.BandAudit.mismatches/0`). Each mismatch is a `list_row/1`
  (no chevron, D-19i — it opens a sheet, not a page) naming the game and
  its current vs. BGG-implied level; tapping it opens a sheet whose
  secondary action reads **«Pasar a {nivel}»** carrying the target
  level's own *meaning* (`Vocabulary.weight_bands/0`'s descriptor), not a
  bare `Corregir` — R1 #10's own shape. Keeping the current level calls
  `BandAudit.keep_band/1` unchanged: it snapshots the current implied
  band plus a timestamp (01.8.1-13, D-30), so a later `bgg_weight` drift
  re-surfaces the game.

  This screen's own mismatch count (`length(@mismatches)`) and the
  dashboard's `Revisar niveles` box both read `BandAudit`'s functions —
  `count_mismatches/0` is itself `length(mismatches/0)` — so the two can
  never disagree by construction; there is no second, independently
  maintained count anywhere.

  With no mismatches, shows a positive/celebratory empty state (E8 empty)
  — no CTA needed.
  """
  use PukllayClubWeb, :live_view

  alias Phoenix.LiveView.JS
  alias PukllayClub.Catalog.BandAudit
  alias PukllayClub.Catalog.Vocabulary
  alias PukllayClubWeb.AdminComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Revisar niveles")
     |> assign(:loading, not connected?(socket))
     |> assign(:selected, nil)
     |> load_mismatches()}
  end

  defp load_mismatches(socket) do
    if socket.assigns.loading do
      socket
    else
      assign(socket, :mismatches, BandAudit.mismatches())
    end
  end

  @impl true
  def handle_event("open-mismatch", %{"game-id" => id}, socket) do
    with_parsed_game_id(id, socket, fn int_id ->
      game = Enum.find(socket.assigns.mismatches, &(&1.id == int_id))
      assign(socket, :selected, game)
    end)
  end

  @impl true
  def handle_event("close-mismatch", _params, socket) do
    {:noreply, assign(socket, :selected, nil)}
  end

  @impl true
  def handle_event("correct", %{"game-id" => game_id}, socket) do
    with_parsed_game_id(game_id, socket, fn int_id ->
      {:ok, _game} = BandAudit.correct_band(int_id)

      socket
      |> assign(:selected, nil)
      |> put_flash(:info, "Nivel corregido.")
      |> load_mismatches()
    end)
  end

  @impl true
  def handle_event("keep", %{"game-id" => game_id}, socket) do
    with_parsed_game_id(game_id, socket, fn int_id ->
      {:ok, _game} = BandAudit.keep_band(int_id)

      socket
      |> assign(:selected, nil)
      |> put_flash(:info, "Nivel mantenido.")
      |> load_mismatches()
    end)
  end

  defp with_parsed_game_id(game_id, socket, fun) do
    case Integer.parse(game_id) do
      {int_id, ""} -> {:noreply, fun.(int_id)}
      _not_an_integer -> {:noreply, socket}
    end
  end

  defp band_label(nil), do: "Sin nivel"

  defp band_label(value) do
    case Vocabulary.weight_band(value) do
      %{label: label} -> label
      nil -> "Sin nivel"
    end
  end

  # R1 #10: the level's own MEANING, not just its name — sourced from
  # `vocabulary.ex`'s three real bands, never a fourth invented one and
  # never the bare label.
  defp band_meaning(nil), do: nil

  defp band_meaning(value) do
    case Vocabulary.weight_band(value) do
      %{descriptor: descriptor} -> descriptor
      nil -> nil
    end
  end

  defp format_weight(weight), do: :erlang.float_to_binary(weight, decimals: 2)

  defp mismatch_meta(game) do
    implied = Vocabulary.implied_weight_band(game.bgg_weight)
    "#{band_label(game.weight_band)} · BGG sugiere #{band_label(implied)} (#{format_weight(game.bgg_weight)})"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse admin_chrome>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <AdminComponents.back_row to={~p"/admin"} />
        <h1 class="pk-admin-page-title">Revisar niveles</h1>
        <p :if={!@loading} class="pk-admin-niveles-subtitle">
          {length(@mismatches)} juego{if length(@mismatches) == 1, do: "", else: "s"} cuyo nivel no coincide con su peso en BGG.
        </p>

        <div :if={@loading} class="space-y-2">
          <div :for={_n <- 1..4} class="skeleton h-10 w-full"></div>
        </div>

        <div :if={!@loading and @mismatches == []} class="pk-admin-niveles-empty">
          <h2 class="pk-admin-page-title">Todo en orden — no hay discrepancias de nivel.</h2>
        </div>

        <div :if={!@loading and @mismatches != []} id="band-mismatches">
          <AdminComponents.list_row
            :for={game <- @mismatches}
            id={"mismatch-#{game.id}"}
            name={game.name}
            meta={mismatch_meta(game)}
            phx-click="open-mismatch"
            phx-value-game-id={game.id}
          />
        </div>
      </div>

      <AdminComponents.sheet
        :if={@selected}
        id="niveles-sheet"
        title={@selected.name}
        subtitle={"Nivel actual: #{band_label(@selected.weight_band)}"}
        open
        on_close={JS.push("close-mismatch")}
      >
        <.niveles_row
          title={"Pasar a #{band_label(Vocabulary.implied_weight_band(@selected.bgg_weight))}"}
          hint={band_meaning(Vocabulary.implied_weight_band(@selected.bgg_weight))}
          phx-click="correct"
          phx-value-game-id={@selected.id}
        />
        <.niveles_row
          title={"Mantener #{band_label(@selected.weight_band)}"}
          hint="Vas a seguir viéndolo acá si su peso en BGG cambia de nivel más adelante."
          phx-click="keep"
          phx-value-game-id={@selected.id}
        />
      </AdminComponents.sheet>
    </Layouts.app>
    """
  end

  # D-19f's two-line row anatomy (short verb + one 13px grey line saying
  # what happens) composed directly against `pk-admin-action`/`--a4`'s own
  # CSS shape (D-18: extend the module's atoms over forking them into the
  # screen) — R1 #10's own row: a "Pasar a {nivel}" verb naming the
  # target level's meaning, never a bare `Corregir`/`Mantener` pair.
  attr :title, :string, required: true
  attr :hint, :string, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-game-id)

  defp niveles_row(assigns) do
    ~H"""
    <button
      type="button"
      class="pk-admin-action pk-admin-action--a4 pk-admin-niveles-row"
      data-pk-pressable="true"
      {@rest}
    >
      <span class="pk-admin-niveles-row__title">{@title}</span>
      <span :if={@hint} class="pk-admin-niveles-row__hint">{@hint}</span>
    </button>
    """
  end
end
