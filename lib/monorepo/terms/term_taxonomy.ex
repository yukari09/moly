defmodule Monorepo.Terms.TermTaxonomy do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_taxonomy"
    repo(Monorepo.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :taxonomy, :string do
      allow_nil? false
    end

    attribute :description, :string do
      allow_nil? false
    end

    attribute :count, :integer do
      allow_nil? false
      default 0
    end

    timestamps()
  end

  relationships do
    belongs_to :term, Monorepo.Terms.Term
    belongs_to :parent, Monorepo.Terms.TermTaxonomy
    many_to_many :posts, Monorepo.Contents.Post, through: Monorepo.Terms.TermRelationships
  end
end
