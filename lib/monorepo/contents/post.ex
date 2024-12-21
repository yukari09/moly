defmodule Monorepo.Contents.Post do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Contents,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAdmin.Resource, AshRbac],
    data_layer: AshPostgres.DataLayer


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
  end


  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :subject, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute(:cover_image, :string)

    attribute :excerpt, :string do
      allow_nil?(false)
    end

    attribute :post_status, :atom do
      allow_nil?(false)
      default(:draft)
      validations(one_of: [:draft, :published, :archived])
    end

    attribute :post_type, :atom do
      allow_nil?(false)
      default(:post)
      validations(one_of: [:post, :page])
    end

    timestamps()
  end

  relationships do
    belongs_to :category, Monorepo.Categories.Category
    belongs_to :user, Monorepo.Accounts.User
    many_to_many :tags, Monorepo.Tags.Tag, through: Monorepo.Contents.PostTag
  end

  postgres do
    table("posts")
    repo(Monorepo.Repo)
  end

  identities do
    identity :unique_title, [:title]
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
