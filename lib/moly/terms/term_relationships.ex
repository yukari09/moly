defmodule Moly.Terms.TermRelationships do
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Terms,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_relationships"
    repo(Moly.Repo)
  end

  actions do
    read :read do
      primary? true
      pagination offset?: true, keyset?: true, required?: false
    end

    create :create, primary?: true
    update :update, primary?: true
    destroy :destroy, primary?: true

    create :create_term_relationships do
      accept [:term_taxonomy_id, :term_order]
    end

    create :create_term_relationships_by_relation_id do
      argument :term_taxonomy_id, :uuid
      argument :post_id, :uuid

      change manage_relationship(:term_taxonomy_id, :term_taxonomy, type: :append_and_remove)
      change manage_relationship(:post_id, :post, type: :append_and_remove)
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
    belongs_to :term_taxonomy, Moly.Terms.TermTaxonomy
    belongs_to :post, Moly.Contents.Post
  end

  identities do
    identity :post_id_term_taxonomy_id, [:term_taxonomy_id, :post_id]
  end
end
