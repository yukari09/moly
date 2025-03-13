defmodule Moly.Options.Option do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Options,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshRbac],
    data_layer: AshPostgres.DataLayer

  postgres do
    table "options"
    repo(Moly.Repo)
  end

  actions do
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

    attribute :option_name, :string do
      allow_nil? false
      length(min: 1, max: 255)
    end

    attribute :option_value, :string do
      allow_nil? false
    end

    attribute :autoload, :boolean do
      allow_nil? false
      default false
    end

    timestamps()
  end
end
