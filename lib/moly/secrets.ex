defmodule Moly.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Moly.Accounts.User, _opts) do
    Application.fetch_env(:moly, :token_signing_secret)
  end

  def secret_for(
        [:authentication, :strategies, :google, :client_id],
        Moly.Accounts.User,
        _opts
      ),
      do: Application.fetch_env(:moly, :google_oauth2_client_id)

  def secret_for(
        [:authentication, :strategies, :google, :client_secret],
        Moly.Accounts.User,
        _opts
      ),
      do: Application.fetch_env(:moly, :google_oauth2_client_secret)

  def secret_for(
        [:authentication, :strategies, :google, :redirect_uri],
        Moly.Accounts.User,
        _opts
      ),
      do: Application.fetch_env(:moly, :google_oauth2_redirect_uri)
end
