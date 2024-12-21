defmodule Monorepo.Tags.Tag do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Tags,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tags"
    repo(Monorepo.Repo)
  end

  actions do
    read :read do
      primary?(true)
      prepare(build(sort: [inserted_at: :desc]))

      pagination do
        required?(false)
        offset?(true)
        keyset?(true)
        countable(true)
      end
    end

    create :create do
      argument :tag_name, :string do
        allow_nil?(false)
        constraints(min_length: 2)
        sensitive?(false)
      end

      change(set_attribute(:tag_name, arg(:tag_name)))
    end

    update :update do
      accept [:tag_name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :tag_name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    many_to_many :posts, Monorepo.Contents.Post, through: Monorepo.Contents.PostTag
  end

  aggregates do
    count :count_of_posts, :posts do
      filter expr(post_status == :published)
    end
  end

  identities do
    identity :unique_tag_name, [:tag_name]
  end

  rbac do
    role :user do
      fields [:tag_name, :inserted_at, :updated_at]
      actions [:read]
    end

    role :admin do
      fields [:tag_name, :inserted_at, :updated_at, :is_deleted]
      actions [:read, :create]
    end
  end
end
