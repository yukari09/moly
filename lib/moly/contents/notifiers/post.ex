defmodule Moly.Contents.Notifiers.Post do
  use Ash.Notifier

  require Ash.Query
  require Logger

  def notify(%Ash.Notifier.Notification{resource: resource, action: %{type: :create}, actor: actor}) do
    if actor do
      Logger.debug("#{actor.id} created a #{resource}")
    else
      Logger.debug("A non-logged in user created a #{resource}")
    end
  end

  def notify(%Ash.Notifier.Notification{resource: resource, action: %{type: :update}, actor: actor}) do
    if actor do
      Logger.debug("#{actor.id} update a #{resource}")
    else
      Logger.debug("A non-logged in user update a #{resource}")
    end
  end

  def notify(%Ash.Notifier.Notification{resource: resource, action: %{type: :destroy}, actor: actor} = a) do
    if actor do
      IO.inspect(a)
      Logger.debug("#{actor.id} destroy a #{resource}")
    else
      Logger.debug("A non-logged in user destroy a #{resource}")
    end
  end

  def create_post_document(post_id) do
    post =
      Ash.get!(Moly.Contents.Post, post_id, actor: %{roles: [:user]})
      |> Ash.load!([:post_meta, term_taxonomy: :term], actor: %{roles: [:user]})
    attrs = attributes(Moly.Contents.Post)
    build_post_meta(post.post_meta)
    # post_map =  Map.take(post, attrs)
    # post_map = Enum.reduce(post.post_meta, post_map, fn %{meta_key: key, meta_value: value}, acc ->
    #   key = String.to_atom(key)
    #   value = convert_post_meta_value(key, value)
    #   Map.put(acc, key, value)
    # end)
    # taxonomy = Enum.reduce(post.term_taxonomy, [], fn %{taxonomy: taxonomy, term: %{name: name, slug: slug}}, acc ->
    #   [%{taxonomy: taxonomy, name: name, slug: slug} | acc]
    # end)
    # Map.put(post_map, :taxonomy, taxonomy)
  end

  def build_post_meta(post_meta) do
    Enum.group_by(post_meta, fn %{meta_key: k} ->
      splited = String.split(k, "_")
      if Regex.match?(~r/\d+/, Enum.at(splited, -1)) do
        Enum.at(splited, 0)
      else
        k
      end
    end)
    |> Enum.reduce(%{}, fn {k, items}, a1 ->
      if Enum.count(items) == 1 do
        item = List.first(items)
        key = String.to_atom(item.meta_key)
        value = convert_post_meta_value(key, item.meta_value)
        Map.put(a1, key, value)
      else
        k = String.to_atom(k)
        v =
          Enum.group_by(items, fn %{meta_key: meta_key} -> String.split(meta_key, "_") |> Enum.at(-1)  end)
          |> Enum.reduce([], fn {_, child_items}, a2 ->
            new_item =
              Enum.reduce(child_items, %{}, fn %{meta_key: meta_key, meta_value: meta_value}, a3 ->
                key = String.split(meta_key, "_") |> Enum.slice(0..-2//1) |> Enum.join("_") |> String.to_atom()
                value = convert_post_meta_value(key, meta_value)
                Map.put(a3, key, value)
              end)
            [new_item | a2]
          end)
        Map.put(a1, k, v)
      end
    end)
  end

  defp convert_post_meta_value(:commission_amount, value) do
    Float.parse(value)
    |>case do
      :error -> 0
      {float_part, _} -> float_part
    end
  end

  defp convert_post_meta_value(key, value)
    when key in [:cookie_duration, :duration_months, :min_payout_threshold, :commission_amount] do
      Integer.parse(value)
      |> case do
        :error -> 0
        {int_part, _} -> int_part
      end
  end

  defp convert_post_meta_value(_, value), do: value

  defp attributes(resource) do
    Ash.Resource.Info.attributes(resource)
    |> Enum.map(&(&1.name))
  end
end
