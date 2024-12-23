defmodule Monorepo.Accounts.Profile do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Accounts,
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  rbac do
    role :admin do
      fields([
        :user_id,
        :first_name,
        :last_name,
        :profile_picture,
        :bio,
        :date_of_birth,
        :gender,
        :phone_number,
        :address,
        :social_links,
        :is_active,
        :last_login_at
      ])

      actions([:read, :create, :update, :delete])
    end

    role :user do
      fields([:user_id, :first_name, :last_name, :profile_picture, :bio])
      actions([:read])
    end
  end

  postgres do
    table "users_profiles"
    repo(Monorepo.Repo)
  end

  actions do
    defaults [:read, :update]

    read :get_profile_by_user_id do
      argument :user_id, :uuid, allow_nil?: false

      filter expr(user_id == ^arg(:user_id))

      get? true
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :user_id, :uuid do
      allow_nil? false
      public? false
    end

    attribute :username, :string do
      allow_nil? false
      public? true
    end

    attribute :name, :string
    attribute :profile_picture, :string

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :bio, :string
    attribute :date_of_birth, :date
    attribute :gender, :string
    attribute :phone_number, :string
    attribute :address, :string
    attribute :social_links, :map
    attribute :last_login_at, :naive_datetime
    timestamps()
  end

  relationships do
    belongs_to :user, Monorepo.Accounts.User
  end

  identities do
    identity :unique_username, [:username]
  end
end
