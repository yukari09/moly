defmodule Monorepo.Blog.Post do
  use Ash.Resource, otp_app: :monorepo, domain: Monorepo.Blog, data_layer: AshPostgres.DataLayer

  actions do
    defaults([:read])
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
    timestamps()
  end

  relationships do
    belongs_to :category, Monorepo.Blog.Category
    belongs_to :user, Monorepo.Accounts.User
  end

  postgres do
    table("posts")
    repo(Monorepo.Repo)
  end
end
