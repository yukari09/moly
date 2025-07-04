defmodule Moly.Terms do
  use Ash.Domain,
    extensions: [
      AshGraphql.Domain
    ]

  resources do
    resource Moly.Terms.Term do
      define :read_by_term_taxonomy, action: :read, args: [:taxonomy_name, :parent]
      define :read_by_term_slug, action: :read, args: [:slug]
    end

    resource Moly.Terms.TermRelationships
    resource Moly.Terms.TermMeta

    resource Moly.Terms.TermTaxonomy do
      define :read_term_taxonomy, action: :read, args: [:taxonomy_name, :parent]
    end
  end

  graphql do
    queries do
      list Moly.Terms.Term, :list_terms, :read, paginate_with: :keyset, relay?: true
    end
  end


end
