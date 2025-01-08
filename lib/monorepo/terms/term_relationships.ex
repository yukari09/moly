defmodule Monorepo.Terms.TermRelationships do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_relationships"
    repo(Monorepo.Repo)
  end

  actions do
    read :read, primary?: true
    create :create, primary?: true
    update :update, primary?: true
    destroy :destroy, primary?: true

    create :create_term_relationships do
      accept [:term_taxonomy_id, :term_order]
    end
  end


  attributes do
    uuid_primary_key :id

    attribute :term_order, :integer do
      allow_nil? true
      default 0
    end

    timestamps()
  end

  relationships do
    belongs_to :term_taxonomy, Monorepo.Terms.TermTaxonomy
    belongs_to :post, Monorepo.Contents.Post
  end
end
