defmodule Moly.Repo do
  use AshPostgres.Repo,
    otp_app: :moly

  import Ecto.Query, only: [from: 2]

  def installed_extensions do
    # Add extensions here, and the migration generator will install them.
    ["ash-functions", "citext"]
  end

  # Don't open unnecessary transactions
  # will default to `false` in 4.0
  def prefer_transaction? do
    false
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def all_tenants do
    all(from(row in "organizations", select: fragment("? || ?", "org_", row.id)))
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
