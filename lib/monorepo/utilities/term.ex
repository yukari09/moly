defmodule Monorepo.Utilities.Term do
  def get_categories(%{post_categories: post_categories}, taxonomy, parent_id \\ nil, amount \\ nil) do
    filtered_categories =
      Enum.reduce(post_categories, [], fn
        %{term_taxonomy: term_taxonomy} = post_category, acc ->
          Enum.filter(term_taxonomy, fn tt ->
            if Map.get(tt, :taxonomy) == taxonomy do
              if parent_id do
                Map.get(tt, :parent_id) == parent_id
              else
                true
              end
            end
          end)
          |> case do
            [] -> acc
            _ -> [post_category | acc]
          end
      end)

    if amount do
      Enum.slice(filtered_categories, 0..amount)
    else
      filtered_categories
    end
  end

  def get_first_category_and_return_by_keys(terms, taxonomy, keys, parent_id \\ nil) do
    get_categories(terms, taxonomy, parent_id, 1)
    |> List.first()
    |> Monorepo.Helper.get_in_from_keys(keys)
  end

end
