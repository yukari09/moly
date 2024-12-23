defmodule Monorepo.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """

  use AshAuthentication.Sender
  use MonorepoWeb, :verified_routes

  @impl true
  def send(user, token, _) do
    Monorepo.Accounts.Emails.deliver_reset_password_instructions(
      user,
      url(~p"/password-reset/#{token}")
    )
  end
end
