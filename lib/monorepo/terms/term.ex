defmodule Monorepo.Terms.Term do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "terms"
    repo(Monorepo.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :slug, :string do
      allow_nil? false
    end

    attribute :term_group, :integer do
      allow_nil? false
      default 0
    end

    timestamps()
  end

  relationships do
    has_many :term_taxonomy, Monorepo.Terms.TermTaxonomy
    has_many :term_meta, Monorepo.Terms.TermMeta
  end

  identities do
    identity :unique_slug, [:slug]
  end
end
