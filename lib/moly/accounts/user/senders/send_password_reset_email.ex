defmodule Moly.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """

  use AshAuthentication.Sender
  use MolyWeb, :verified_routes

  @impl true
  def send(user, token, _) do
    :timer.sleep(10_000)
    Moly.Accounts.Emails.deliver_reset_password_instructions(
      user,
      url(~p"/password-reset/#{token}")
    )
  end
end
