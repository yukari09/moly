defmodule Monorepo.Contents.Changes.Post do
  require Ash.Query

  def create_term_relationships(%{arguments: arguments}, post, _context) do
    post_id = post.id
    old_term_relationships =
      Monorepo.Terms.TermRelationships
      |> Ash.Query.filter(post_id == ^post.id)
      |> Ash.read!(actor: %{roles: [:admin]})

    Ash.bulk_destroy!(old_term_relationships, :destroy, %{}, actor: %{roles: [:admin]})

    categories = Map.get(arguments, :categories, [])
    tags = Map.get(arguments, :tags, [])

    %{status: :success, records: records} = Ash.bulk_create!(tags, Monorepo.Terms.Term, :create, actor: %{roles: [:admin]}, upsert_fields: [:slug], upsert?: true, upsert_identity: :unique_slug, return_records?: true)

    term_relationships =
      Enum.reduce(categories, [], &([%{term_taxonomy_id: &1, post_id: post_id} | &2]))

    term_relationships =
      Enum.reduce(records, term_relationships, fn %{term_taxonomy: term_taxonomy}, acc ->
        new_items = Enum.reduce(term_taxonomy, [], &([%{term_taxonomy_id: &1.id, post_id: post_id} | &2]))
        acc ++ new_items
      end)

    %{status: :success, records: records} =  Ash.bulk_create!(term_relationships, Monorepo.Terms.TermRelationships, :create_term_relationships_by_relation_id, actor: %{roles: [:admin]}, return_records?: true, return_errors?: true)

    Enum.map(records, fn %{term_taxonomy_id: term_taxonomy_id} ->
      count =
        Monorepo.Terms.TermRelationships
        |> Ash.Query.filter(term_taxonomy_id == ^term_taxonomy_id)
        |> Ash.count!(actor: %{roles: [:user]})
      Ash.update!(%Monorepo.Terms.TermTaxonomy{id: term_taxonomy_id}, %{count: count}, actor: %{roles: [:admin]})
    end)

    {:ok, post}
  end


  def update_term_relationships(changeset, post, context) do
    create_term_relationships(changeset, post, context)
  end
end
