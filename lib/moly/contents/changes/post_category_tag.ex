defmodule Moly.Contents.Changes.PostCategoryTag do
  require Ash.Query

  # def create_term_relationships(%{arguments: arguments}, post, _context) do
  #   post_id = post.id

  #   old_term_relationships =
  #     Moly.Terms.TermRelationships
  #     |> Ash.Query.filter(post_id == ^post.id)
  #     |> Ash.read!(actor: %{roles: [:admin]})

  #   Ash.bulk_destroy!(old_term_relationships, :destroy, %{}, actor: %{roles: [:admin]})

  #   categories = Map.get(arguments, :categories, [])
  #   tags = Map.get(arguments, :tags, [])

  #   %{status: :success, records: records} =
  #     Ash.bulk_create!(tags, Moly.Terms.Term, :create,
  #       actor: %{roles: [:admin]},
  #       upsert_fields: [:slug],
  #       upsert?: true,
  #       upsert_identity: :unique_slug,
  #       return_records?: true
  #     )

  #   term_relationships =
  #     Enum.reduce(categories, [], &[%{term_taxonomy_id: &1, post_id: post_id} | &2])

  #   term_relationships =
  #     Enum.reduce(records, term_relationships, fn %{term_taxonomy: term_taxonomy}, acc ->
  #       new_items =
  #         Enum.reduce(term_taxonomy, [], &[%{term_taxonomy_id: &1.id, post_id: post_id} | &2])

  #       acc ++ new_items
  #     end)

  #   %{status: :success, records: records} =
  #     Ash.bulk_create!(
  #       term_relationships,
  #       Moly.Terms.TermRelationships,
  #       :create_term_relationships_by_relation_id,
  #       actor: %{roles: [:admin]},
  #       return_records?: true,
  #       return_errors?: true
  #     )

  #   Enum.map(records, fn %{term_taxonomy_id: term_taxonomy_id} ->
  #     count =
  #       Moly.Terms.TermRelationships
  #       |> Ash.Query.filter(term_taxonomy_id == ^term_taxonomy_id)
  #       |> Ash.count!(actor: %{roles: [:user]})

  #     Ash.update!(%Moly.Terms.TermTaxonomy{id: term_taxonomy_id}, %{count: count},
  #       actor: %{roles: [:admin]}
  #     )
  #   end)

  #   {:ok, post}
  # end

  def term_relationships(%{arguments: arguments}, post, _context) do
    post_id = post.id

    old_term_relationships =
      Moly.Terms.TermRelationships
      |> Ash.Query.filter(post_id == ^post.id)
      |> Ash.Query.load(:term_taxonomy)
      |> Ash.read!(actor: %{roles: [:admin]})
      |> Enum.group_by(& &1.term_taxonomy.taxonomy)

    old_categories =
      Enum.find(old_term_relationships, fn {k, _} ->
        String.contains?(k, "category")
      end)

    old_tags =
      Enum.find(old_term_relationships, fn {k, _} ->
        String.contains?(k, "tag")
      end)

    categories = Map.get(arguments, :categories, [])
    tags = Map.get(arguments, :tags, [])

    term_relationships = []

    term_relationships =
      if categories != [] do
        if old_categories,
          do: Ash.bulk_destroy!(old_categories, :destroy, %{}, actor: %{roles: [:admin]})

        Enum.reduce(categories, [], &[%{term_taxonomy_id: &1, post_id: post_id} | &2])
      else
        term_relationships
      end

    term_relationships =
      if tags != [] do
        if old_tags, do: Ash.bulk_destroy!(old_tags, :destroy, %{}, actor: %{roles: [:admin]})

        %{status: :success, records: records} =
          Ash.bulk_create!(tags, Moly.Terms.Term, :create,
            actor: %{roles: [:admin]},
            upsert_fields: [:slug],
            upsert?: true,
            upsert_identity: :unique_slug,
            return_records?: true
          )

        Enum.reduce(records, term_relationships, fn %{term_taxonomy: term_taxonomy}, acc ->
          new_items =
            Enum.reduce(term_taxonomy, [], &[%{term_taxonomy_id: &1.id, post_id: post_id} | &2])

          acc ++ new_items
        end)
      else
        term_relationships
      end

    %{status: :success, records: records} =
      Ash.bulk_create!(
        term_relationships,
        Moly.Terms.TermRelationships,
        :create_term_relationships_by_relation_id,
        actor: %{roles: [:admin]},
        return_records?: true,
        return_errors?: true
      )

    Enum.map(records, fn %{term_taxonomy_id: term_taxonomy_id} ->
      count =
        Moly.Terms.TermRelationships
        |> Ash.Query.filter(term_taxonomy_id == ^term_taxonomy_id)
        |> Ash.count!(actor: %{roles: [:user]})

      Ash.update!(%Moly.Terms.TermTaxonomy{id: term_taxonomy_id}, %{count: count},
        actor: %{roles: [:admin]}
      )
    end)

    {:ok, post}
  end
end
