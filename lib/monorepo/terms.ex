defmodule Monorepo.Terms do
  use Ash.Domain

  resources do
    resource Monorepo.Terms.Term do
      define :read_by_term_taxonomy, action: :read, args: [:taxonomy_name, :parent]
    end

    resource Monorepo.Terms.TermRelationships
    resource Monorepo.Terms.TermMeta

    resource Monorepo.Terms.TermTaxonomy do
      define :read_term_taxonomy, action: :read, args: [:taxonomy_name, :parent]
    end
  end
end
