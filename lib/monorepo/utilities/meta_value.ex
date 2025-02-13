defmodule Monorepo.Utilities.MetaValue do
  #user meta
  def format_meta_value(nil), do: nil
  def format_meta_value(%{meta_value: nil}), do: nil

  def format_meta_value(%{meta_key: :avatar, meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  def format_meta_value(%{meta_key: :banner, meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  def format_meta_value(%{meta_key: :attachment_metadata, meta_value: meta_value}),
  do: JSON.decode!(meta_value)

  def format_meta_value(%{meta_value: meta_value}), do: meta_value

  def filter_meta_by_key(%{post_meta: post_meta}, meta_key) when is_list(post_meta) and is_atom(meta_key) do
    Enum.filter(post_meta, & &1.meta_key == meta_key)
  end

  def filter_meta_by_key_first(post, meta_key) when is_atom(meta_key) do
    filter_meta_by_key(post, meta_key)
    |> List.first()
  end

  #key :attachment_affiliate_media_feature
  def post_feature_image(%{post_meta: post_meta} = post, key, size_label) when is_list(post_meta) do
    filter_meta_by_key_first(post, key)
    |> case do
      nil -> nil
      key_value ->
        children = key_value.children
        filter_meta_by_key_first(%{post_meta: children}, :attachment_metadata)
        |> case do
          nil -> nil
          meta_value ->
            format_meta_value(meta_value)
            |> case do
              nil -> nil
              new_meta_value ->
                Monorepo.Helper.get_in_from_keys(new_meta_value, ["sizes", size_label, "file"])
            end
        end
    end
  end

end
