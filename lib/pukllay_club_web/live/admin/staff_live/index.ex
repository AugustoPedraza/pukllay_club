defmodule PukllayClubWeb.Admin.StaffLive.Index do
  @moduledoc """
  Owner-only staff roster at `/admin/staff` (D-32, D-33, UI-SPEC E9).

  The owner invites a staff member by email; the generator's unconfirmed-
  user + magic-link flow already IS the invite (`Accounts.invite_staff/2`
  followed by `Accounts.deliver_login_instructions/2`) — no separate
  invite-token concept exists. `mount/3` is defense in depth on top of
  `Accounts.invite_staff/2`'s own owner check: a non-owner staff member who
  somehow lands here is `push_navigate`d straight back to `/admin`,
  learning nothing about the roster (T-01.8.1-32).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Accounts
  alias PukllayClub.Accounts.User
  alias PukllayClubWeb.UserAuth

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    if User.owner?(scope.user) do
      users = Accounts.list_staff(scope)

      {:ok,
       socket
       |> assign(:page_title, "Staff")
       |> assign(:email_input, "")
       |> assign(:email_error, nil)
       |> assign(:confirm_remove, nil)
       |> assign(:other_count, length(users) - 1)
       |> stream(:staff, users)}
    else
      {:ok, push_navigate(socket, to: ~p"/admin")}
    end
  end

  @impl true
  def handle_event("invite", %{"email" => email}, socket) do
    case Accounts.invite_staff(socket.assigns.current_scope, email) do
      {:ok, user} ->
        deliver_and_finish_invite(socket, user)

      {:error, :staff_limit_reached} ->
        {:noreply, put_flash(socket, :error, "Ya hay 3 personas en el staff. Quitá a alguien para invitar a otra.")}

      {:error, :unauthorized} ->
        {:noreply, push_navigate(socket, to: ~p"/admin")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:email_input, email)
         |> assign(:email_error, first_error(changeset, :email))}
    end
  end

  @impl true
  def handle_event("ask-remove", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_remove, Accounts.get_user!(id))}
  end

  @impl true
  def handle_event("cancel-remove", _params, socket) do
    {:noreply, assign(socket, :confirm_remove, nil)}
  end

  @impl true
  def handle_event("confirm-remove", _params, socket) do
    target = socket.assigns.confirm_remove

    case Accounts.remove_staff(socket.assigns.current_scope, target.id) do
      {:ok, tokens} ->
        UserAuth.disconnect_sessions(tokens)

        {:noreply,
         socket
         |> stream_delete(:staff, target)
         |> assign(:confirm_remove, nil)
         |> assign(:other_count, socket.assigns.other_count - 1)
         |> put_flash(:info, "Quitaste a #{target.email} del staff.")}

      {:error, _reason} ->
        {:noreply, assign(socket, :confirm_remove, nil)}
    end
  end

  defp deliver_and_finish_invite(socket, user) do
    case Accounts.deliver_login_instructions(user, &url(~p"/admin/ingresar/#{&1}")) do
      {:ok, _email} ->
        {:noreply,
         socket
         |> stream_insert(:staff, user)
         |> assign(:email_input, "")
         |> assign(:email_error, nil)
         |> assign(:other_count, socket.assigns.other_count + 1)
         |> put_flash(:info, "Invitación enviada.")}

      {:error, _reason} ->
        Accounts.delete_invited_user(user)

        {:noreply,
         socket
         |> assign(:email_input, user.email)
         |> put_flash(
           :error,
           "No pudimos enviarte el email de invitación. Probá de nuevo en unos minutos."
         )}
    end
  end

  defp first_error(changeset, field) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Map.get(field, [])
    |> List.first()
  end

  defp estado_label(%{role: :owner}), do: "Dueño"
  defp estado_label(%{role: :staff, confirmed_at: nil}), do: "Invitación pendiente"
  defp estado_label(%{role: :staff}), do: "Activo"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse admin_chrome>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <.header>
          Staff
          <:actions>
            <.link navigate={~p"/admin"} class="text-sm text-neutral">← Volver</.link>
          </:actions>
        </.header>

        <p :if={@other_count == 0} class="text-neutral text-sm">
          Todavía no invitaste a nadie más.
        </p>

        <form
          id="invite-staff-form"
          phx-submit="invite"
          class="rounded-box border border-base-300 bg-base-200 p-4 flex flex-wrap items-end gap-3"
        >
          <div class="flex-1 min-w-48">
            <.input
              type="email"
              id="invite-staff-email"
              name="email"
              value={@email_input}
              label="Email"
              errors={if @email_error, do: [@email_error], else: []}
            />
          </div>
          <.button variant="primary">Invitar</.button>
        </form>

        <.table id="staff-roster" rows={@streams.staff}>
          <:col :let={{_id, user}} label="Email">
            <span class="break-all">{user.email}</span>
          </:col>
          <:col :let={{_id, user}} label="Estado">
            {estado_label(user)}
          </:col>
          <:action :let={{_id, user}}>
            <.button
              :if={user.role == :staff}
              phx-click="ask-remove"
              phx-value-id={user.id}
              variant="secondary"
            >
              Quitar
            </.button>
          </:action>
        </.table>
      </div>

      <%!-- ux-patterns B11: warn before a destructive action commits — a
      server-rendered confirm modal, mirroring GameLive.Form's Retirar flow. --%>
      <div :if={@confirm_remove} class="modal modal-open" role="dialog" aria-modal="true">
        <div class="modal-box">
          <h3 class="font-display text-xl">¿Quitar a {@confirm_remove.email} del staff?</h3>
          <p class="py-4 text-neutral text-sm">
            Va a perder acceso al panel de inmediato.
          </p>
          <div class="modal-action">
            <.button phx-click="cancel-remove" variant="secondary">Cancelar</.button>
            <button
              id="confirm-remove-btn"
              type="button"
              phx-click="confirm-remove"
              class="btn btn-error"
            >
              Quitar
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
