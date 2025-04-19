defmodule Moly.Accounts.Emails do
  @moduledoc """
  Delivers emails.
  """
  use Oban.Worker, queue: :mailers

  import Swoosh.Email

  require Logger

  @interval 60
  @max_send_count 3
  @remove_limited_time :timer.minutes(30)

  def perform(%Oban.Job{args: %{"deliver_type" => deliver_type, "deliver_args" => deliver_args}}) do
    deliver_type = String.to_atom(deliver_type)
    apply(__MODULE__, deliver_type, deliver_args)
    :ok
  end

  def deliver_email_confirmation_instructions(email, url) do
    if !url do
      raise "Cannot deliver confirmation instructions without a url"
    end

    deliver(email, "Confirm your email address", """
      <p>
        Hi #{email},
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

  def deliver_reset_password_instructions(email, url) do
    if !url do
      raise "Cannot deliver password reset email without a url"
    end

    deliver(email, "Reset your password", """
      <p>
        Hi #{email},
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

  def deliver_email_change_confirmation_instructions(email, url) do
    if !url do
      raise "Cannot deliver confirmation instructions without a url"
    end

    deliver(email, "Confirm your new email address", """
      <p>
        Hi #{email},
      </p>

      <p>
        You recently changed your email address. Please confirm it.
      </p>

      <p>
        <a href="#{url}">Click here to confirm your new email address</a>
      </p>
    """)
  end

  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, subject, body) do
    case get_send_args(to) do
      [true, true, _, _] ->
        set_send_args(to)
        _deliver(to, subject, body)
      [false | _] ->
        Logger.debug("Email send limit reached for #{to}. Not sending email.")
      [true, _, send_count, last_send_datetime] ->
        set_send_args(to)
        case last_send_datetime do
          nil -> nil
          last_send_datetime ->
            now = DateTime.utc_now()
            diff = DateTime.diff(now, last_send_datetime, :second)
            if diff < @interval do
              sleep_time = @interval * send_count
              Logger.debug("Email send limit reached for #{to}, waiting #{sleep_time} seconds")
              :timer.sleep(sleep_time * 1000)
            end
            Logger.debug("Email send limit reached for #{to}, waiting #{diff} seconds")
            :timer.sleep(diff * 1000)
        end
        _deliver(to, subject, body)
    end
  end

  defp _deliver(to, subject, body) do
    [from_email_name, from_email_address] = _get_email_config()
    new()
    |> from({from_email_name, from_email_address})
    |> to(to_string(to))
    |> subject(subject)
    |> put_provider_option(:track_links, "None")
    |> html_body(body)
    |> Moly.Mailer.deliver!()
  end

  defp _get_email_config() do

    email_group_config =
      Application.get_env(:moly, :email_group)

    if email_group_config not in [nil, "", false] do
      [name, address, api_key] =
        String.split(email_group_config, ",")
        |> Enum.map(&String.split(&1, ":"))
        |> Enum.random()

      new_config =
        Application.get_env(:moly, Moly.Mailer)
        |> Keyword.put(:api_key, api_key)

      Application.put_env(:moly, Moly.Mailer, new_config)
      [name, address]
    else
      [
        Application.get_env(:moly, :email_name),
        Application.get_env(:moly, :email_address)
      ]
    end
  end

  defp get_send_args(email) do
    sc = send_count(email)
    lct = last_send_time(email)
    arg1 = sc < @max_send_count
    arg2 = if lct do
      DateTime.diff(DateTime.utc_now(), lct, :second) > @interval
    else
      true
    end
    [arg1, arg2, sc, lct]
  end

  defp set_send_args(email), do: send_count(email, true) && last_send_time(email,true)

  defp send_count(email, only_set \\ false) do
    key = "count:send:email:#{email}"
    value = Moly.Utilities.cache_get!(key) || 0
    if only_set do
      if not Moly.Utilities.cache_exists?(key) do
        Moly.Utilities.cache_put(key, 1, expire: @remove_limited_time)
      else
        Moly.Utilities.cache_inc(key, 1)
      end
    end
    value
  end

  defp last_send_time(email, only_set \\ false) do
    key = "last:send:email:#{email}:dattime"
    value = Moly.Utilities.cache_get!(key)
    if only_set do
      ttl = Moly.Utilities.cache_ttl(key) || @remove_limited_time
      Moly.Utilities.cache_put(key, DateTime.utc_now(), expire: ttl)
    end
    value
  end
end
