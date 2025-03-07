defmodule Monorepo.Terms.Term do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  require Ash.Query

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
      actions([:create, :read, :update, :destroy])
    end
  end

  actions do
    default_accept [:name, :slug, :term_group]

    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])
      argument :parent, :uuid, do: allow_nil?(true)
      argument :slug, :string, do: allow_nil?(true)
      argument :taxonomy_name, :string, do: allow_nil?(true)

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end

      filter expr(is_nil(^arg(:parent)) or term_taxonomy.parent_id == ^arg(:parent))
      filter expr(is_nil(^arg(:taxonomy_name)) or term_taxonomy.taxonomy == ^arg(:taxonomy_name))
      filter expr(is_nil(^arg(:slug)) or slug == ^arg(:slug))
    end

    create :create do
      primary? true
      upsert? true
      upsert_identity :unique_slug
      argument :term_taxonomy, {:array, :map}
      argument :term_meta, {:array, :map}
      change manage_relationship(:term_taxonomy, :term_taxonomy, type: :create)
      change manage_relationship(:term_meta, :term_meta, type: :create)
    end

    update :update do
      primary? true
      require_atomic? false
      argument :term_taxonomy, {:array, :map}
      argument :term_meta, {:array, :map}
      change manage_relationship(:term_taxonomy, :term_taxonomy, type: :create)
      change manage_relationship(:term_meta, :term_meta, on_lookup: :relate, on_match: :ignore, on_no_match: :create, on_missing: :destroy)
    end

    destroy :destroy do
      primary? true

      change before_action(fn changeset, context ->
        Ash.Query.filter(
          Monorepo.Terms.TermTaxonomy,
          term_id == ^Ash.Changeset.get_attribute(changeset, :id)
        )
        |> Ash.bulk_destroy!(:destroy, %{}, actor: context.actor)

        Ash.Query.filter(
          Monorepo.Terms.TermMeta,
          term_id == ^Ash.Changeset.get_attribute(changeset, :id)
        )
        |> Ash.bulk_destroy!(:destroy, %{}, actor: context.actor)
        changeset
      end)
    end
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
