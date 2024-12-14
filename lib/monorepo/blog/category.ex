defmodule Monorepo.Blog.Category do
  use Ash.Resource, otp_app: :monorepo, domain: Monorepo.Blog, data_layer: AshPostgres.DataLayer

  actions do
    defaults([:read])
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
    table("categories")
    repo(Monorepo.Repo)
  end
end
