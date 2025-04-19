defmodule Moly.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """

  use AshAuthentication.Sender
  use MolyWeb, :verified_routes

  @impl true
  def send(user, token, _) do
    email = user.email
    url = url(~p"/password-reset/#{token}")
    %{deliver_type: "deliver_reset_password_instructions", deliver_args: [email, url]}
    |> Moly.Accounts.Emails.new()
    |>  Oban.insert()
    :ok
  end
end
