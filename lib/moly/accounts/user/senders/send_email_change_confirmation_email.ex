defmodule Moly.Accounts.User.Senders.SendEmailChangeConfirmationEmail do
  @moduledoc """
  Sends an email change confirmation email.
  """

  use AshAuthentication.Sender
  use MolyWeb, :verified_routes

  @impl true
  def send(user, token, _) do
    if !Moly.Utilities.Account.is_active_user(user) do
      email = user.email
      url = url(~p"/auth/user/confirm_change?#{[confirm: token]}")
      %{deliver_type: "deliver_email_change_confirmation_instructions", deliver_args: [email, url]}
      |> Moly.Accounts.Emails.new()
      |>  Oban.insert()
    end
    :ok
  end
end
