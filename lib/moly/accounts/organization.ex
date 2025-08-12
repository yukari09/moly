defmodule Moly.Accounts.Organization do
  use Ash.Resource,
    domain: Moly.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo Moly.Repo
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end
  end

  postgres do
    manage_tenant do
      template ["org_", :id]
    end
  end


  defimpl Ash.ToTenant do
    def to_tenant(%{id: id}, resource) do
      if Ash.Resource.Info.data_layer(resource) == AshPostgres.DataLayer
        && Ash.Resource.Info.multitenancy_strategy(resource) == :context do
        "org_#{id}"
      else
        id
      end
    end
  end
end
