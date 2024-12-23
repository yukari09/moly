defmodule Monorepo.Categories.Category do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Categories,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "categories"
    repo(Monorepo.Repo)
  end

  rbac do
    role :user do
      fields([:category_name, :inserted_at, :updated_at])
      actions([:read])
    end

    role :admin do
      fields([:category_name, :inserted_at, :updated_at, :is_deleted])
      actions([:read, :create, :is_deleted, :destroy_forever, :update])
    end
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

    create :create do
      argument :category_name, :string do
        allow_nil? false
        constraints min_length: 2
        sensitive? false
      end

      change set_attribute(:category_name, arg(:category_name))
    end

    update :is_deleted do
      argument :is_deleted, :boolean do
        allow_nil? false
      end

      change set_attribute(:is_deleted, arg(:is_deleted))
    end

    update :update do
      accept [:category_name]
    end

    destroy :destroy_forever
  end

  attributes do
    uuid_primary_key :id

    attribute :category_name, :string do
      allow_nil? false
      public? true
    end

    attribute :is_deleted, :boolean do
      allow_nil? false
      default false
    end

    timestamps()
  end

  relationships do
    has_many :posts, Monorepo.Contents.Post
  end

  aggregates do
    count :count_of_posts, :posts do
      filter expr(post_status == :published)
    end
  end

  identities do
    identity :unique_category_name, [:category_name]
  end
end
