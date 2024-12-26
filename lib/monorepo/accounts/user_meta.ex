defmodule Monorepo.Accounts.UserMeta do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Accounts,
    # authorizers: [Ash.Policy.Authorizer],
    # extensions: [AshAdmin.Resource, AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "user_meta"
    repo(Monorepo.Repo)
  end

  actions do
    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :meta_key, :string do
      length(min: 1, max: 255)
      allow_nil? false
    end

    attribute :meta_value, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :user, Monorepo.Accounts.User
  end

  # rbac do
  #   role :guest do
  #     fields([:meta_key, :meta_value, :inserted_at, :updated_at])
  #     actions([:read])
  #   end

  #   role :user do
  #     fields([:meta_key, :meta_value, :inserted_at, :updated_at])
  #     actions([:read])
  #   end

  #   role :admin do
  #     fields([:meta_key, :meta_value, :inserted_at, :updated_at])
  #     actions([:read, :create, :update, :destroy])
  #   end
  # end
end
