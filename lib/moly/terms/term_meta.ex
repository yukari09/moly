defmodule Moly.Terms.TermMeta do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_meta"
    repo(Moly.Repo)
  end

  rbac do
    role :user do
      actions([:read])
    end

    role :admin do
      actions([:create, :read, :update, :destroy])
    end
  end

  actions do
    create :create do
      accept [:term_key, :term_value]
      primary? true
      upsert? true
      upsert_identity :term_key_value_with_id
    end

    update :update do
      primary? true
    end

    destroy :destroy do
      primary? true
    end

    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :term_key, :string do
      allow_nil? false
    end

    attribute :term_value, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :term, Moly.Terms.Term
  end

  identities do
    identity :term_key_value_with_id, [:term_id, :term_key, :term_value]
  end
end
