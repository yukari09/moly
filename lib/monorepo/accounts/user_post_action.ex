defmodule Monorepo.Accounts.UserPostAction do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Accounts,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshRbac]

  postgres do
    table "user_post_actions"
    repo(Monorepo.Repo)
  end

  rbac do
    role :user do
      actions([:read])
    end
    role :owner do
      actions([:read, :create, :destroy])
    end
    role :admin do
      actions([:read, :create, :destroy])
    end
  end

  actions do
    # Define create action
    create :create do
      accept [
        :action
      ]

      upsert? true
      upsert_identity :unique_user_id_post_id_action

      argument :post, :uuid, allow_nil?: false

      change manage_relationship(:post, :post, on_lookup: :relate)
      change relate_actor(:user)
    end

    # Define read action
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

    # Define destroy action
    destroy :destroy do
      argument :id, :uuid
    end
  end

  identities do
    identity :unique_user_id_post_id_action, [:user_id, :post_id, :action]
  end

  attributes do
    # Primary key for the UserPostAction resource, using UUID for uniqueness
    uuid_primary_key :id

    # Action performed by the user, e.g., :favorite, :history, :saved
    attribute :action, :atom, allow_nil?: false
    # Timestamp indicating when the action was performed, defaults to current UTC time
    attribute :created_at, :utc_datetime, allow_nil?: false, default: &DateTime.utc_now/0
    timestamps()
  end

  relationships do
    # Relationship to the User resource, indicating the user who performed the action
    belongs_to :user, Monorepo.Accounts.User, allow_nil?: false
    # Relationship to the Post resource, indicating the post that was acted upon
    belongs_to :post, Monorepo.Contents.Post, allow_nil?: false
  end
end
