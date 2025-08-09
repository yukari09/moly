defmodule Moly.Accounts.UserMeta do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Accounts,
    # authorizers: [Ash.Policy.Authorizer],
    extensions: [AshGraphql.Resource, AshGraphql.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "user_meta"
    repo(Moly.Repo)
  end

  actions do
    default_accept [:meta_key, :meta_value]

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

    # create :create_by_user_ids do
    #   argument :user_id, :uuid, allow_nil?: false
    #   change manage_relationship :user_id, :user, on_match: :relate
    # end

    create :create, primary?: true
    update :update, primary?: true
    destroy :destroy
  end

  attributes do
    uuid_primary_key :id

    attribute :meta_key, :string do
      allow_nil? false
      public? true
    end

    attribute :meta_value, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :user, Moly.Accounts.User
  end

  identities do
    identity :meta_key_with_user_id, [:meta_key, :user_id]
  end

  graphql do
    type :user_meta
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
