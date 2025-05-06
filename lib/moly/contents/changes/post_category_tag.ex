defmodule Moly.Contents.Changes.PostCategoryTag do
  require Ash.Query

  require Logger

  @actor %{roles: [:admin]}

  def term_relationships(%{arguments: arguments}, post, _context) do
    post_id = post.id

    [old_categories, old_tags] = delete_term_relationships_by_post_id(post_id)

    categories = Map.get(arguments, :categories, [])
    tags = Map.get(arguments, :tags, [])

    term_relationships = []

    term_relationships =
      if categories != [] do
        if old_categories,
          do: elem(old_categories, 1) |> Ash.bulk_destroy!(:destroy, %{},  actor: @actor)

        Enum.reduce(categories, [], &[%{term_taxonomy_id: &1, post_id: post_id} | &2])
      else
        term_relationships
      end

    term_relationships =
      if tags != [] do
        if old_tags, do: elem(old_tags,1) |>  Ash.bulk_destroy!(:destroy, %{}, actor: @actor)

        %{status: :success, records: records} =
          Ash.bulk_create!(tags, Moly.Terms.Term, :create,
            actor: @actor,
            upsert_fields: [:slug],
            upsert?: true,
            upsert_identity: :unique_slug,
            return_records?: true,
            return_errors?: true
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
        actor: @actor,
        return_records?: true,
        return_errors?: true
      )

    Enum.map(records, fn %{term_taxonomy_id: term_taxonomy_id} ->
      count =
        Moly.Terms.TermRelationships
        |> Ash.Query.filter(term_taxonomy_id == ^term_taxonomy_id)
        |> Ash.count!(actor: %{roles: [:user]})

      Ash.update!(%Moly.Terms.TermTaxonomy{id: term_taxonomy_id}, %{count: count},
        actor: @actor
      )
    end)

    {:ok, post}
  end

  def delete_term_relationships(changeset, _context) do
    post_id = Ash.Changeset.get_attribute(changeset, :id)
    term_taxonomy_ids =
      delete_term_relationships_by_post_id(post_id, false)
      |> Enum.reduce([], fn {_, items}, acc ->
        Enum.reduce(items, acc, fn item, acc ->
          [item.term_taxonomy_id | acc]
        end)
      end)
    Moly.Terms.TermTaxonomy
    |> Ash.Query.filter(id in ^term_taxonomy_ids)
    |>Ash.bulk_update!(:inc_count, %{amount: -1}, actor: @actor, return_errors?: true)
    changeset
  end

  defp delete_term_relationships_by_post_id(post_id, classified \\ true) do
    old_term_relationships =
      Moly.Terms.TermRelationships
      |> Ash.Query.filter(post_id == ^post_id)
      |> Ash.Query.load(:term_taxonomy)
      |> Ash.read!(actor: @actor)
      |> Enum.group_by(& &1.term_taxonomy.taxonomy)

      old_categories =
        Enum.find(old_term_relationships, fn {k, _} ->
          String.contains?(k, "category")
        end)


      old_tags =
        Enum.find(old_term_relationships, fn {k, _} ->
          String.contains?(k, "tag")
        end)
    if classified, do: [old_categories, old_tags], else: old_term_relationships
  end
end
