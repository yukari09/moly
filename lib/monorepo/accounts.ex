defmodule Monorepo.Accounts do
  use Ash.Domain, extensions: [AshAdmin.Domain]

  resources do
    resource(Monorepo.Accounts.Token)
    resource(Monorepo.Accounts.User)
    resource(Monorepo.Accounts.Profile)
  end

end
