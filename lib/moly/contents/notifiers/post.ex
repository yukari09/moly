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
    post_map =  Map.take(post, attrs)
    post_map = Enum.reduce(post.post_meta, post_map, fn %{meta_key: key, meta_value: value}, acc ->
      key = String.to_atom(key)
      value = convert_post_meta_value(key, value)
      Map.put(acc, key, value)
    end)
    taxonomy = Enum.reduce(post.term_taxonomy, [], fn %{taxonomy: taxonomy, term: %{name: name, slug: slug}}, acc ->
      [%{taxonomy: taxonomy, name: name, slug: slug} | acc]
    end)
    Map.put(post_map, :taxonomy, taxonomy)
  end

  defp convert_post_meta_value(_, value), do: value

  defp attributes(resource) do
    Ash.Resource.Info.attributes(resource)
    |> Enum.map(&(&1.name))
  end
end
