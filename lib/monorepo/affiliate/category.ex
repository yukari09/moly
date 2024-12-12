defmodule Monorepo.Affiliate.Category do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Affiliate,
    extensions: [AshGraphql.Resource],
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key(:id)

    attribute :category_name, :string do
      allow_nil?(false)
    end

    attribute(:description, :string)
    timestamps()
  end

  graphql do
    type(:category)
  end

  postgres do
    table("ah_categories")
    repo(Monorepo.Repo)
  end
end
