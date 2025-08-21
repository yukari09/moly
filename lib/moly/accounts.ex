defmodule Moly.Accounts do
  use Ash.Domain,
    extensions: [
      AshGraphql.Domain
    ]

  resources do
    resource Moly.Accounts.Token
    resource Moly.Accounts.User
    resource Moly.Accounts.UserMeta
    resource Moly.Accounts.UserPostAction
  end

  graphql do
    authorize? false
    mutations do
      create Moly.Accounts.User, :register_with_password, :register_with_password
    end

    queries do
      read_one Moly.Accounts.User, :sign_in_with_password, :sign_in_with_password,
        type_name: :user_with_token, as_mutation?: true
    end

  end
end
