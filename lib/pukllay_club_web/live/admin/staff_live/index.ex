defmodule PukllayClubWeb.Admin.StaffLive.Index do
  @moduledoc """
  Owner-only staff roster at `/admin/staff` (D-32, D-33, UI-SPEC E9;
  presentation rebuilt by plan 01.8.2-11 — D-19f, D-19h).

  The owner invites a staff member by email; the generator's unconfirmed-
  user + magic-link flow already IS the invite (`Accounts.invite_staff/2`
  followed by `Accounts.deliver_login_instructions/2`) — no separate
  invite-token concept exists. `mount/3` is defense in depth on top of
  `Accounts.invite_staff/2`'s own owner check: a non-owner staff member who
  somehow lands here is `push_navigate`d straight back to `/admin`,
  learning nothing about the roster (T-01.8.1-32).

  **This plan changes presentation only.** `Accounts.remove_staff/2` and
  the invite path are called exactly as before — 01.8.1-07's token
  snapshot inside `Repo.transact/1` is load-bearing for session
  disconnection, and the test-only `Accounts.notifier/0` seam still
  simulates a delivery failure. A row taps open an options sheet
  (D-19e); its one destructive row, `Quitar del staff`, opens D-19f's
  centred dialog — never the shipped daisyUI confirmation dialog 064
  R7b outlawed (`admin-redesign-scope.md` gap #10; this file's own
  `<verify>` greps its compiled source for that retired class pair, so
  even a comment naming it would defeat the check).
  """
  use PukllayClubWeb, :live_view

  alias PukllayClub.Accounts
  alias PukllayClub.Accounts.User
  alias PukllayClubWeb.AdminComponents
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
       |> assign(:selected_staff, nil)
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
  def handle_event("open-staff-sheet", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_staff, Accounts.get_user!(id))}
  end

  @impl true
  def handle_event("close-staff-sheet", _params, socket) do
    {:noreply, assign(socket, :selected_staff, nil)}
  end

  @impl true
  def handle_event("ask-remove", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_staff, nil)
     |> assign(:confirm_remove, Accounts.get_user!(id))}
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

  # Drives both the row's status_dot AND the options-sheet subtitle —
  # one source, per D-19h ("a status is a dot + text, never a pill").
  defp staff_status(%{role: :owner}), do: :owner
  defp staff_status(%{role: :staff, confirmed_at: nil}), do: :pending
  defp staff_status(%{role: :staff}), do: :active

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse admin_chrome>
      <div class="mx-auto w-full max-w-3xl space-y-6">
        <AdminComponents.back_row to={~p"/admin"} />
        <h1 class="pk-admin-page-title">Staff</h1>

        <p :if={@other_count == 0} class="pk-admin-empty-note">
          Todavía no invitaste a nadie más.
        </p>

        <form id="invite-staff-form" phx-submit="invite" class="pk-admin-invite-form">
          <div class="pk-admin-invite-form__field">
            <AdminComponents.field
              type="email"
              id="invite-staff-email"
              name="email"
              value={@email_input}
              label="Email"
              errors={if @email_error, do: [@email_error], else: []}
              required
            />
          </div>
          <AdminComponents.action anatomy="a1" role="principal" type="submit">
            Invitar
          </AdminComponents.action>
        </form>

        <div id="staff-list" phx-update="stream">
          <AdminComponents.list_row
            :for={{dom_id, user} <- @streams.staff}
            id={dom_id}
            name={user.email}
            phx-click={if user.role == :staff, do: "open-staff-sheet"}
            phx-value-id={user.id}
          >
            <:trailing>
              <AdminComponents.status_dot status={staff_status(user)} />
            </:trailing>
          </AdminComponents.list_row>
        </div>
      </div>

      <AdminComponents.sheet
        :if={@selected_staff}
        id="staff-options-sheet"
        title={@selected_staff.email}
        open
        on_close={JS.push("close-staff-sheet")}
      >
        <AdminComponents.action
          anatomy="a4"
          role="peligro"
          phx-click="ask-remove"
          phx-value-id={@selected_staff.id}
        >
          Quitar del staff
        </AdminComponents.action>
      </AdminComponents.sheet>

      <AdminComponents.dialog
        :if={@confirm_remove}
        id="confirm-remove-dialog"
        question={"¿Quitar a #{@confirm_remove.email} del staff?"}
        consequence="Va a perder acceso al panel de inmediato."
        verb="Quitar"
        open
        on_confirm={JS.push("confirm-remove")}
        on_cancel={JS.push("cancel-remove")}
      />
    </Layouts.app>
    """
  end
end
