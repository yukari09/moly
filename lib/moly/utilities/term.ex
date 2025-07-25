defmodule Moly.Utilities.Term do
  require Ash.Query

  alias Moly.Terms.Term

   @actor %{roles: [:user]}

  def get_term_by_id(id) do
    Ash.get!(Moly.Terms.Term, id, actor: @actor)
    |> Ash.load!([:term_taxonomy, :term_meta], actor: @actor)
  end

  def get_terms_data_by_slug(slugs) when is_list(slugs) do
    Ash.Query.new(Term)
    |> Ash.Query.filter(slug in ^slugs)
    |> Ash.Query.load([:term_taxonomy, :term_meta])
    |> Ash.read!(actor: @actor)
  end

  def icon(%Term{} = term), do: term_meta_by_term_key_first_term_value(term, :icon)

  def term_meta_by_term_key(%Term{term_meta: term_meta}, term_key) when is_list(term_meta) do
    Enum.filter(term_meta, &(&1.term_key == term_key))
  end

  def term_meta_by_term_key_first_term_value(%Term{term_meta: term_meta} = term, term_key)
      when is_list(term_meta) do
    term_meta_by_term_key(term, term_key)
    |> List.first()
    |> case do
      nil -> nil
      %{term_value: term_value} -> term_value
    end
  end

  def get_first_and_return_by_keys(relation_data, taxonomy, keys, parent_id \\ nil) do
    get_taxonomy(relation_data, taxonomy, parent_id, 1)
    |> List.first()
    |> Moly.Helper.get_in_from_keys(keys)
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
