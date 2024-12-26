defmodule Monorepo.Terms.TermRelationships do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_relationships"
    repo(Monorepo.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :term_order, :integer do
      allow_nil? false
      default 0
    end

    timestamps()
  end

  relationships do
    belongs_to :term_taxonomy, Monorepo.Terms.TermTaxonomy
    belongs_to :post, Monorepo.Contents.Post
  end
end
