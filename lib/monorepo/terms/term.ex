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

  rbac do
    role :user do
      fields([:read])
      actions([:read])
    end

    role :admin do
      fields([:name, :slug, :term_group])
      actions([:create_category, :read, :update, :destroy])
    end
  end

  actions do
    default_accept [:name, :slug, :term_group]

    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])

      argument :parent, :uuid do
        allow_nil? true
      end

      argument :taxonomy_name, :string do
        allow_nil? true
      end

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end

      filter(expr(is_nil(^arg(:parent)) or term_taxonomy.parent_id == ^arg(:parent)))
      filter(expr(is_nil(^arg(:taxonomy_name)) or term_taxonomy.taxonomy == ^arg(:taxonomy_name)))
    end

    create :create_category do
      accept [:name, :slug]
      argument :term_taxonomy, {:array, :map}

      change manage_relationship(:term_taxonomy, :term_taxonomy, type: :create)
    end
    update :update, primary?: true
    destroy :destroy
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
