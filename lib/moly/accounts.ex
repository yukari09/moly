defmodule Moly.Accounts do
  use Ash.Domain, extensions: [AshAdmin.Domain]

  resources do
    resource Moly.Accounts.Token
    resource Moly.Accounts.User
    resource Moly.Accounts.UserMeta
    resource Moly.Accounts.UserPostAction
  end
end
