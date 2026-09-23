defmodule PukllayClubWeb.Admin.GameLive.Form do
  @moduledoc """
  Edit screen for a single game's club-owned fields, at
  `/admin/juegos/:id/editar` (D-07, UI-SPEC E3), plus the D-04/D-08
  status transitions (Publicar / Retirar / Restaurar).

  `mount/3` loads via `Catalog.get_game!/1` — the unfiltered ADMIN read —
  so a `:draft` or `:retired` game opens here exactly as readily as a
  `:published` one, even though its public `/juegos/:id` 404s (D-04,
  D-08). Only `Catalog.change_game_admin/2`/`update_game_admin/2` ever
  touch this form's data, and those route through
  `Game.admin_changeset/2`'s cast allowlist (D-31: four club-owned
  fields plus `:shelf_id`, the old count field dropped outright) — a BGG-derived
  fact submitted in the form params (`bgg_weight`, `mechanics`, ...) is
  silently dropped, never persisted (T-01.8.1-21).

  Every BGG-derived fact is rendered read-only via `CoreComponents.list/1`
  below the form — values only, no inputs, no changeset field for any of
  them.

  A failed draft (D-03 — `enrichment_status == "failed"`, from an
  exhausted BGG retry, a missing BGG item, or missing credentials) shows
  the `Error al traer datos de BGG.` alert at the top with a `Reintentar`
  button that calls `Catalog.retry_enrichment/1`, putting the game back
  into `"pending"` and re-enqueuing its `EnrichGameWorker` job.

  Status actions (D-04, D-08): a draft's primary action is `Publicar`,
  which is a second `type="submit"` button on the SAME form carrying
  `name="_action" value="publish"` — the browser includes the activated
  submitter's name/value pair in the serialized form data, so
  `handle_event("save", ...)` sees `_action` alongside the normal `game`
  params and saves-then-publishes in one round trip, exactly as the
  plan's action text specifies ("saves pending form changes, then
  `Catalog.publish_game/1`"). Retirar opens a server-rendered confirmation
  (`@confirm_retire`, a daisyUI `modal`) rather than retiring immediately
  — no undo toast, per `ux-patterns` B11 ("warn before the action
  commits"). Restaurar has no confirmation (reversible, routine — UI-SPEC
  Color contract).

  A `Secciones` fieldset (D-07) lists every hand-picked (`:manual`)
  section as a checkbox — the featured section included, since it is
  still `:manual`. Section membership isn't a `Game` schema field, so it
  travels as a plain `game[section_ids][]` checkbox list outside
  `Game.admin_changeset/2`'s cast allowlist, and is applied via
  `Sections.set_game_sections/2` right after the game itself saves. A
  `{:error, :featured_full}` from that call surfaces as a flash error —
  the game's own field changes are already saved by that point, so this
  never blocks or reverts them.
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Catalog
  alias PukllayClub.Catalog.Sections
  alias PukllayClub.Catalog.Shelves
  alias PukllayClub.Catalog.Vocabulary

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    game = Catalog.get_game!(id)

    {:ok,
     socket
     |> assign(:page_title, game.name)
     |> assign(:game, game)
     |> assign(:confirm_retire, false)
     |> assign(:shelves, Shelves.list_shelves())
     |> assign(:manual_sections, manual_sections())
     |> assign(:selected_section_ids, MapSet.new(Sections.member_section_ids(game.id)))
     |> assign(:form, to_form(Catalog.change_game_admin(game)))}
  end

  defp manual_sections, do: Enum.filter(Sections.list_sections(), &(&1.kind == :manual))

  @impl true
  def handle_event("validate", %{"game" => params}, socket) do
    changeset =
      socket.assigns.game
      |> Catalog.change_game_admin(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"game" => params} = full_params, socket) do
    case Catalog.update_game_admin(socket.assigns.game, params) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:page_title, game.name)
         |> assign(:form, to_form(Catalog.change_game_admin(game)))
         |> after_save(Map.get(full_params, "_action"))
         |> apply_section_ids(game, params)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("retire", _params, socket) do
    {:noreply, assign(socket, :confirm_retire, true)}
  end

  @impl true
  def handle_event("cancel-retire", _params, socket) do
    {:noreply, assign(socket, :confirm_retire, false)}
  end

  @impl true
  def handle_event("confirm-retire", _params, socket) do
    case Catalog.retire_game(socket.assigns.game) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:confirm_retire, false)
         |> put_flash(:info, "Juego retirado.")}

      {:error, _changeset} ->
        {:noreply, assign(socket, :confirm_retire, false)}
    end
  end

  @impl true
  def handle_event("restore", _params, socket) do
    case Catalog.restore_game(socket.assigns.game) do
      {:ok, game} ->
        {:noreply,
         socket
         |> assign(:game, game)
         |> put_flash(:info, "Juego restaurado.")}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  # D-03: `game-id` (never the reserved `value` key — project memory rule)
  # is parsed defensively even though this screen only ever renders one
  # game's own id.
  @impl true
  def handle_event("retry-enrichment", %{"game-id" => game_id}, socket) do
    case Integer.parse(game_id) do
      {int_id, ""} ->
        case int_id |> Catalog.get_game!() |> Catalog.retry_enrichment() do
          {:ok, updated} ->
            {:noreply,
             socket
             |> assign(:game, updated)
             |> assign(:form, to_form(Catalog.change_game_admin(updated)))}

          {:error, :not_failed} ->
            {:noreply, socket}
        end

      _not_an_integer ->
        {:noreply, socket}
    end
  end

  # "publish" is the "_action" value the Publicar submitter carries;
  # anything else (the plain "Guardar cambios" submit, or no submitter
  # name at all) is the ordinary save flash.
  defp after_save(socket, "publish") do
    case Catalog.publish_game(socket.assigns.game) do
      {:ok, game} ->
        socket
        |> assign(:game, game)
        |> put_flash(:info, "Juego publicado.")

      {:error, _changeset} ->
        put_flash(socket, :info, "Cambios guardados.")
    end
  end

  defp after_save(socket, _action), do: put_flash(socket, :info, "Cambios guardados.")

  # D-07: `section_ids` isn't a `Game` schema field (never cast by
  # `Game.admin_changeset/2`), so it's applied separately, after the game
  # itself is already saved — `set_game_sections/2` owns its own
  # transaction and the featured cap check (D-26).
  defp apply_section_ids(socket, game, params) do
    section_ids = params |> Map.get("section_ids", []) |> Enum.flat_map(&parse_id/1)

    case Sections.set_game_sections(game.id, section_ids) do
      {:ok, _section_ids} ->
        assign(socket, :selected_section_ids, MapSet.new(section_ids))

      {:error, :featured_full} ->
        socket
        |> put_flash(:error, "La sección destacada ya tiene 20 juegos.")
        |> assign(:selected_section_ids, MapSet.new(Sections.member_section_ids(game.id)))
    end
  end

  defp parse_id(value) do
    case Integer.parse(value) do
      {int_id, ""} -> [int_id]
      _not_an_integer -> []
    end
  end

  defp weight_band_options do
    Enum.map(Vocabulary.weight_bands(), &{&1.label, &1.value})
  end

  defp shelf_options(shelves) do
    Enum.map(shelves, &{&1.name, &1.id})
  end

  defp status_badge_class(:draft), do: "badge badge-warning"
  defp status_badge_class(:published), do: "badge badge-success"
  defp status_badge_class(:retired), do: "badge badge-neutral"

  defp status_badge_label(:draft), do: "Borrador"
  defp status_badge_label(:published), do: "Publicado"
  defp status_badge_label(:retired), do: "Retirado"

  defp failed?(game), do: game.enrichment_status == "failed"

  defp players_text(%{min_players: nil, max_players: nil}), do: "—"
  defp players_text(%{min_players: min, max_players: max}) when min == max, do: to_string(min || max)
  defp players_text(%{min_players: min, max_players: max}), do: "#{min || "?"}–#{max || "?"}"

  defp playtime_text(%{playing_time: t}) when is_integer(t), do: "#{t} min"

  defp playtime_text(%{min_playtime: nil, max_playtime: nil}), do: "—"

  defp playtime_text(%{min_playtime: min, max_playtime: max}) when min == max, do: "#{min || max} min"

  defp playtime_text(%{min_playtime: min, max_playtime: max}), do: "#{min || "?"}–#{max || "?"} min"

  defp mechanics_text(%{mechanics: mechanics}), do: join_or_dash(Vocabulary.covered_mechanics(mechanics))
  defp themes_text(%{themes: themes}), do: join_or_dash(Vocabulary.covered_themes(themes))

  defp join_names(names), do: join_or_dash(names)

  defp join_or_dash([]), do: "—"
  defp join_or_dash(values), do: Enum.join(values, ", ")

  defp value_or_dash(nil), do: "—"
  defp value_or_dash(value), do: value

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>
          {@game.name}
          <:subtitle>
            <span class={status_badge_class(@game.status)}>{status_badge_label(@game.status)}</span>
          </:subtitle>
          <:actions>
            <.link navigate={~p"/admin/juegos"} class="text-sm text-neutral">
              ← Volver
            </.link>
          </:actions>
        </.header>

        <div :if={failed?(@game)} class="alert alert-error">
          <span>Error al traer datos de BGG.</span>
          <.button variant="secondary" phx-click="retry-enrichment" phx-value-game-id={@game.id}>
            Reintentar
          </.button>
        </div>

        <.form for={@form} id="game-form" phx-change="validate" phx-submit="save" class="space-y-2">
          <.input field={@form[:name]} type="text" label="Nombre" />
          <.input
            field={@form[:weight_band]}
            type="select"
            label="Nivel"
            prompt="Sin nivel"
            options={weight_band_options()}
          />
          <.input field={@form[:is_expansion]} type="checkbox" label="Es expansión" />
          <.input
            field={@form[:shelf_id]}
            type="select"
            label="Estante"
            prompt="Sin ubicar"
            options={shelf_options(@shelves)}
          />
          <.input field={@form[:description]} type="textarea" label="Descripción en español" />

          <fieldset :if={@manual_sections != []} class="fieldset mb-2">
            <legend class="label mb-1">Secciones</legend>
            <label :for={section <- @manual_sections} class="flex items-center gap-2 min-h-11">
              <input
                type="checkbox"
                name="game[section_ids][]"
                value={section.id}
                checked={section.id in @selected_section_ids}
                class="checkbox checkbox-sm"
              />
              {section.name}
            </label>
          </fieldset>

          <div class="flex flex-wrap gap-2 pt-2">
            <%!-- D-04/D-08: exactly one primary action per lifecycle state.
            Draft: Publicar (name="_action" value="publish" — the browser
            includes the activated submitter in the form's own submit
            payload, see moduledoc) is primary, Guardar cambios demotes to
            secondary. Published/Retired: Guardar cambios is primary, the
            lifecycle transition (Retirar/Restaurar) is a secondary,
            type="button" action outside this form's own submit. --%>
            <.button :if={@game.status == :draft} name="_action" value="publish" variant="primary">
              Publicar
            </.button>
            <.button
              variant={if @game.status == :draft, do: "secondary", else: "primary"}
              name="_action"
              value="save"
            >
              Guardar cambios
            </.button>
          </div>
        </.form>

        <div :if={@game.status == :published} class="flex">
          <.button phx-click="retire" variant="secondary">Retirar</.button>
        </div>

        <div :if={@game.status == :retired} class="flex">
          <.button phx-click="restore" variant="secondary">Restaurar</.button>
        </div>

        <div class="bg-base-200 rounded-box p-4">
          <.list>
            <:item title="Jugadores">{players_text(@game)}</:item>
            <:item title="Duración">{playtime_text(@game)}</:item>
            <:item title="Edad mínima">{value_or_dash(@game.min_age)}</:item>
            <:item title="Mecánicas">{mechanics_text(@game)}</:item>
            <:item title="Temáticas">{themes_text(@game)}</:item>
            <:item title="Diseñadores">{join_names(@game.designers)}</:item>
            <:item title="Ilustradores">{join_names(@game.artists)}</:item>
            <:item title="Editorial">{join_names(@game.publishers)}</:item>
            <:item title="Valoración BGG">{value_or_dash(@game.bgg_rating)}</:item>
            <:item title="Ranking BGG">{value_or_dash(@game.bgg_rank)}</:item>
            <:item title="Peso BGG">{value_or_dash(@game.bgg_weight)}</:item>
          </.list>
        </div>
      </div>

      <%!-- D-08, ux-patterns B11: a server-rendered confirm modal, never a
      toast — the destructive action must be warned-about BEFORE it
      commits, not undone after. --%>
      <div :if={@confirm_retire} class="modal modal-open" role="dialog" aria-modal="true">
        <div class="modal-box">
          <h3 class="font-display text-xl">¿Retirar {@game.name}?</h3>
          <p class="py-4 text-neutral text-sm">
            Vas a poder restaurarlo después. No va a aparecer más en la ludoteca pública.
          </p>
          <div class="modal-action">
            <.button phx-click="cancel-retire" variant="secondary">Cancelar</.button>
            <button type="button" phx-click="confirm-retire" class="btn btn-error">Retirar</button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
