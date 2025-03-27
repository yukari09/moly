defmodule Moly.Accounts.Emails do
  @moduledoc """
  Delivers emails.
  """

  import Swoosh.Email

  def deliver_email_confirmation_instructions(user, url) do
    if !url do
      raise "Cannot deliver confirmation instructions without a url"
    end

    deliver(user.email, :email_confirmation, "Confirm your email address", """
      <p>
        Hi #{user.email},
      </p>

      <p>
        Someone has tried to register a new account using this email address.
        If it was you, then please click the link below to confirm your identity. If you did not initiate this request then please ignore this email.
      </p>

      <p>
        <a href="#{url}">Click here to confirm your account</a>
      </p>
    """)
  end

  def deliver_reset_password_instructions(user, url) do
    if !url do
      raise "Cannot deliver password reset email without a url"
    end

    deliver(user.email, :reset_password, "Reset your password", """
      <p>
        Hi #{user.email},
      </p>

      <p>
        You have requested to reset your password. If this was you, please click the link below to reset your password.
        If you did not request this, please ignore this email.
      </p>

      <p>
        <a href="#{url}">Click here to reset your password</a>
      </p>
    """)
  end

  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, send_type, subject, body) do
    key = "sender:#{to}:#{send_type}"

    deliver_email = fn ->
      IO.puts("Sending email to #{to} with subject #{subject} and body #{body}")

      from_email_name = Application.get_env(:moly, :email_name)
      from_email_address = Application.get_env(:moly, :email_address)

      new()
      |> from({from_email_name, from_email_address})
      |> to(to_string(to))
      |> subject(subject)
      |> put_provider_option(:track_links, "None")
      |> html_body(body)
      |> Moly.Mailer.deliver!()
    end

    Moly.Utilities.cache_get_or_put(key, deliver_email, :timer.minutes(5))
  end
end
