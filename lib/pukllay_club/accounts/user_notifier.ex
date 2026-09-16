defmodule PukllayClub.Accounts.UserNotifier do
  @moduledoc false
  import Swoosh.Email

  alias PukllayClub.Accounts.User
  alias PukllayClub.Mailer

  # Delivers the email using the application mailer. The sender is declared
  # exactly once, in config (:pukllay_club, :mail_from) — never a literal
  # here (D-36).
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from(Application.fetch_env!(:pukllay_club, :mail_from))
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  # Voseo Argentine Spanish (D-31, T-01.8.1-04). Both variants resolve to the
  # same 15-minute magic-link token (`@magic_link_validity_in_minutes` in the
  # generated `UserToken`) — the copy states that duration explicitly rather
  # than leaving it implicit, and both state that nothing happens if the
  # recipient didn't ask for the email.
  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Tu link para entrar a Pukllay Club", """

    ==============================

    Hola,

    Entrá a tu cuenta del panel de Pukllay Club visitando el link de abajo.
    El link vence en 15 minutos.

    #{url}

    Si no pediste este email, no hace falta que hagas nada.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Te invitaron al staff de Pukllay Club", """

    ==============================

    Hola,

    Te invitaron a formar parte del staff de Pukllay Club. Entrá al panel
    visitando el link de abajo. El link vence en 15 minutos.

    #{url}

    Si no esperabas esta invitación, no hace falta que hagas nada.

    ==============================
    """)
  end
end
