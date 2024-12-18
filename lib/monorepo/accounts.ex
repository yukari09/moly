defmodule Monorepo.Accounts do
  use Ash.Domain, extensions: [AshAdmin.Domain]

  resources do
    resource(Monorepo.Accounts.Token)
    resource(Monorepo.Accounts.User)
  end

  admin do
    show? true
  end
end
