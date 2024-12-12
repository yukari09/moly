defmodule Monorepo.Affiliate do
  use Ash.Domain, extensions: [AshGraphql.Domain]

  resources do
    resource(Monorepo.Affiliate.Category)
  end
end
