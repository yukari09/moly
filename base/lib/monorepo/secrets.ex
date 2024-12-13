defmodule Monorepo.Secrets do
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], Monorepo.Accounts.User, _opts) do
    Application.fetch_env(:monorepo, :token_signing_secret)
  end
end
