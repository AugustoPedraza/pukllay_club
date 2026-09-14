defmodule PukllayClubWeb.Admin.BandAuditLive do
  @moduledoc """
  Revisar niveles at `/admin/niveles` (D-29, D-30, SC-5, UI-SPEC E8): lists
  every non-retired game whose club `weight_band` disagrees with the band
  implied by its `bgg_weight` (`Catalog.BandAudit.mismatches/0`), side by
  side with the evidence (current band, BGG weight, implied band), so
  staff can fix a mis-banded game in one tap (Corregir).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog.BandAudit
  alias PukllayClub.Catalog.Vocabulary

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Revisar niveles")
     |> assign(:mismatches, BandAudit.mismatches())}
  end

  @impl true
  def handle_event("correct", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} ->
        {:ok, _game} = BandAudit.correct_band(int_id)

        {:noreply,
         socket
         |> put_flash(:info, "Nivel corregido.")
         |> assign(:mismatches, BandAudit.mismatches())}

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  defp band_label(nil), do: "Sin nivel"

  defp band_label(value) do
    case Vocabulary.weight_band(value) do
      %{label: label} -> label
      nil -> "Sin nivel"
    end
  end

  defp format_weight(weight), do: :erlang.float_to_binary(weight, decimals: 2)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-4xl space-y-6">
        <.header>
          Revisar niveles
          <:subtitle>Juegos cuyo nivel no coincide con su peso en BGG.</:subtitle>
        </.header>

        <.table id="band-mismatches" rows={@mismatches}>
          <:col :let={game} label="Juego">
            <div class="flex items-center gap-2">
              <span class="badge badge-warning shrink-0">Revisar</span>
              <span class="min-w-0 break-words">{game.name}</span>
            </div>
          </:col>
          <:col :let={game} label="Nivel actual">{band_label(game.weight_band)}</:col>
          <:col :let={game} label="Peso BGG">
            <span class="block text-right">{format_weight(game.bgg_weight)}</span>
          </:col>
          <:col :let={game} label="Nivel según BGG">
            {band_label(Vocabulary.implied_weight_band(game.bgg_weight))}
          </:col>
          <:action :let={game}>
            <.button variant="secondary" phx-click="correct" phx-value-game-id={game.id}>
              Corregir
            </.button>
          </:action>
        </.table>
      </div>
    </Layouts.app>
    """
  end
end
