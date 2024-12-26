defmodule Monorepo.Terms.TermMeta do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Terms,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "term_meta"
    repo(Monorepo.Repo)
  end

  attributes do
    uuid_primary_key :id

    attribute :term_key, :string do
      length(min: 1, max: 255)
      allow_nil? false
    end

    attribute :term_value, :string do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :term, Monorepo.Terms.Term
  end
end
