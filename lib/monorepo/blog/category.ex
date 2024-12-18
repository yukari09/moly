defmodule Monorepo.Blog.Category do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Blog,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  actions do
    defaults([:read, create: [:category_name]])
  end

  attributes do
    uuid_primary_key(:id)

    attribute :category_name, :string do
      allow_nil?(false)
      public?(true)
    end

    timestamps()
  end

  postgres do
    table("posts_categories")
    repo(Monorepo.Repo)
  end

end
