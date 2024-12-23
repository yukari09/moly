defmodule Monorepo.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Monorepo.Accounts.User, _opts) do
    Application.fetch_env(:monorepo, :token_signing_secret)
  end

  def secret_for(
        [:authentication, :strategies, :google, :client_id],
        Monorepo.Accounts.User,
        _opts
      ),
      do: Application.fetch_env(:monorepo, :google_oauth2_client_id)

  def secret_for(
        [:authentication, :strategies, :google, :client_secret],
        Monorepo.Accounts.User,
        _opts
      ),
      do: Application.fetch_env(:monorepo, :google_oauth2_client_secret)

  def secret_for(
        [:authentication, :strategies, :google, :redirect_uri],
        Monorepo.Accounts.User,
        _opts
      ),
      do: Application.fetch_env(:monorepo, :google_oauth2_redirect_uri)
end
