defmodule Monorepo.Terms do
  use Ash.Domain

  resources do
    resource Monorepo.Terms.Term
    resource Monorepo.Terms.TermRelationships
    resource Monorepo.Terms.TermMeta
    resource Monorepo.Terms.TermTaxonomy
  end
end
