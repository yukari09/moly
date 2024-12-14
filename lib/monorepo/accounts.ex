defmodule Monorepo.Accounts do
  use Ash.Domain

  resources do
    resource(Monorepo.Accounts.Token)
    resource(Monorepo.Accounts.User)
  end

end
