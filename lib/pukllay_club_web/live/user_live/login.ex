defmodule PukllayClubWeb.UserLive.Login do
  @moduledoc false
  use PukllayClubWeb, :live_view

  alias PukllayClub.Accounts
  alias PukllayClub.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>Ingresar al panel</.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/admin/ingresar"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button variant="primary" class="w-full">
            Enviarme el link
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  # T-01.8.1-04 (D-31, UI-SPEC E11): identical neutral copy whether the
  # address belongs to staff, a non-staff user, or nobody at all — response
  # shape must never reveal whether an address exists. Delivery is gated
  # server-side on `User.staff?/1` so a future Phase 2 member account never
  # receives a staff magic link either.
  @impl true
  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    user = Accounts.get_user_by_email(email)

    if user && User.staff?(user) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/admin/ingresar/#{&1}")
      )
    end

    info = "Si el email es del staff, te llegó un link para entrar. Revisá tu casilla."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/admin/ingresar")}
  end

  defp local_mail_adapter? do
    Application.get_env(:pukllay_club, PukllayClub.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
