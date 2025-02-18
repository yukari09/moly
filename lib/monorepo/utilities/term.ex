defmodule Monorepo.Utilities.Term do


  def get_first_and_return_by_keys(relation_data, taxonomy, keys, parent_id \\ nil) do
    get_taxonomy(relation_data, taxonomy, parent_id, 1)
    |> List.first()
    |> Monorepo.Helper.get_in_from_keys(keys)
  end

  def get_taxonomy(relation_data, taxonomy, parent_id \\ nil, amount \\ nil) do
    filtered =
      Enum.reduce(relation_data, [], fn
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
      Enum.slice(filtered, 0..amount)
    else
      filtered
    end
  end
end
