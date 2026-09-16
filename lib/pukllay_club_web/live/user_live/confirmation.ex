defmodule PukllayClubWeb.UserLive.Confirmation do
  @moduledoc false
  use PukllayClubWeb, :live_view

  alias PukllayClub.Accounts

  @impl true
  def render(%{user: nil} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto max-w-sm space-y-4 text-center">
        <.header>Ingresar al panel</.header>
        <p>El link venció o ya se usó. Pedí uno nuevo.</p>
        <.button navigate={~p"/admin/ingresar"} variant="primary" class="w-full">
          Enviarme otro link
        </.button>
      </div>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} bottom_collapse>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>Welcome {@user.email}</.header>
        </div>

        <.form
          for={@form}
          id="login_form"
          phx-submit="submit"
          phx-mounted={JS.focus_first()}
          action={~p"/admin/ingresar"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <input type="hidden" name={@form[:remember_me].name} value="true" />
          <.button variant="primary" phx-disable-with="Entrando..." class="w-full">
            Entrar
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # UI-SPEC E11: an expired/already-used token renders the error state
  # in-page (a "user: nil" render clause above) rather than the generator's
  # default flash-and-redirect — this is the D-31 in-page expired-link state.
  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Accounts.get_user_by_magic_link_token(token) do
      nil ->
        {:ok, assign(socket, user: nil, form: nil, trigger_submit: false)}

      user ->
        form = to_form(%{"token" => token}, as: "user")

        {:ok, assign(socket, user: user, form: form, trigger_submit: false), temporary_assigns: [form: nil]}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
