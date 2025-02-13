defmodule Monorepo.Contents.Relations.PostCategories do
  use Ash.Resource.ManualRelationship
  require Ash.Query

  def load(records, _opts, %{query: query} = context) do
    post_ids = Enum.map(records, & &1.id)

    opts = Ash.Context.to_opts(context)

    result =
      query
      |> Ash.Query.filter(term_taxonomy.taxonomy == "category")
      |> Ash.Query.filter(term_taxonomy.posts.id in ^post_ids)
      |> Ash.read!(opts)
      |> Ash.load!([:term_taxonomy], opts)

    return_result =
      Monorepo.Terms.TermRelationships
      |> Ash.Query.filter(post_id in ^post_ids)
      |> Ash.read!(opts)
      |> Enum.group_by(& &1.post_id)
      |> Enum.reduce(%{}, fn {post_id, relationships}, acc ->
        term_taxonomy_ids = Enum.map(relationships, & &1.term_taxonomy_id)

        terms =
          Enum.filter(result, fn r ->
            new_term_taxonomy_ids = Enum.map(r.term_taxonomy, & &1.id)
            term_taxonomy_ids -- new_term_taxonomy_ids != term_taxonomy_ids
          end)

        Map.put(acc, post_id, terms)
      end)

    {:ok, return_result}
  end
end
