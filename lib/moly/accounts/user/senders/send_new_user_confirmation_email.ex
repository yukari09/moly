defmodule Moly.Accounts.User.Senders.SendNewUserConfirmationEmail do
  @moduledoc """
  Sends an email for a new user to confirm their email address.
  """

  use AshAuthentication.Sender
  use MolyWeb, :verified_routes

  @impl true
  def send(user, token, _) do
    if !Moly.Utilities.Account.is_active_user(user) do
      :timer.sleep(120_000)
      Moly.Accounts.Emails.deliver_email_confirmation_instructions(
        user,
        url(~p"/auth/user/confirm_new_user?#{[confirm: token]}")
      )
    end
  end
end
