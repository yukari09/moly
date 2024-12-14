defmodule Monorepo.Accounts.User.Senders.SendNewUserConfirmationEmail do
  @moduledoc """
  Sends an email for a new user to confirm their email address.
  """

  use AshAuthentication.Sender
  use MonorepoWeb, :verified_routes

  @impl true
  def send(user, token, _) do
    Monorepo.Accounts.Emails.deliver_email_confirmation_instructions(
      user,
      url(~p"/auth/user/confirm_new_user?#{[confirm: token]}")
    )
  end
end
