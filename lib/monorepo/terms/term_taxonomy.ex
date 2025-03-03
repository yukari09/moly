defmodule Monorepo.Terms.TermTaxonomy do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_taxonomies"
    repo(Monorepo.Repo)
  end

  rbac do
    role :user do
      fields([:read])
      actions([:read])
    end

    role :admin do
      fields([:taxonomy, :description, :count])
      actions([:create, :read, :update, :destroy])
    end
  end

  actions do
    default_accept [:taxonomy, :description, :count]

    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end

      argument :parent, :uuid do
        allow_nil? true
      end

      argument :taxonomy_name, :string do
        allow_nil? true
      end

      filter expr(is_nil(^arg(:parent)) or parent_id == ^arg(:parent))
      filter expr(is_nil(^arg(:taxonomy_name)) or taxonomy == ^arg(:taxonomy_name))
    end

    create :create do
      primary? true
      upsert? true
      upsert_identity :taxonomy_term_id
      argument :parent_id, :uuid do
        allow_nil? true
      end

      change manage_relationship(:parent_id, :parent, type: :append_and_remove)
    end

    update :update do
      primary? true
      require_atomic? false

      argument :parent_id, :uuid do
        allow_nil? true
      end

      change manage_relationship(:parent_id, :parent, type: :append_and_remove)
    end

    # update :update, primary?: true
    destroy :destroy, primary?: true
  end

  attributes do
    uuid_primary_key :id

    attribute :taxonomy, :string do
      allow_nil? false
    end

    attribute :description, :string do
      allow_nil? true
      default ""
    end

    attribute :count, :integer do
      allow_nil? false
      default 0
    end

    timestamps()
  end

  relationships do
    belongs_to :term, Monorepo.Terms.Term

    belongs_to :parent, Monorepo.Terms.Term do
      source_attribute :parent_id
      destination_attribute :id
    end

    many_to_many :posts, Monorepo.Contents.Post, through: Monorepo.Terms.TermRelationships
  end

  identities do
    identity :taxonomy_term_id, [:term_id, :taxonomy]
  end

end
