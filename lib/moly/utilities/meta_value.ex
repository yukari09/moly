defmodule Moly.Utilities.MetaValue do
  # user meta
  def format_meta_value(nil), do: nil
  def format_meta_value(%{meta_value: nil}), do: nil

  def format_meta_value(%{meta_key: "avatar", meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  def format_meta_value(%{meta_key: "banner", meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  def format_meta_value(%{meta_key: "attachment_metadata", meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  def format_meta_value(%{meta_value: meta_value}), do: meta_value

  def format_meta_value(%Moly.Contents.Post{post_meta: _post_meta} = post, meta_key) do
    filter_meta_by_key_first(post, meta_key)
    |> format_meta_value()
  end

  def format_meta_value(Moly.Contents.Post, _), do: nil

  def filter_meta_by_key(%{post_meta: post_meta}, meta_key)
      when is_list(post_meta) and is_binary(meta_key) do
    Enum.filter(post_meta, &(&1.meta_key == meta_key))
  end

  def filter_meta_by_key(_, _), do: []

  def filter_meta_by_key_first(post, meta_key) when is_binary(meta_key) do
    filter_meta_by_key(post, meta_key)
    |> List.first()
  end

  def post_images(%{post_meta: post_meta} = post, key, size_label) when is_list(post_meta) do
    children =
      filter_meta_by_key(post, key)
      |> Enum.reduce([], fn %{children: children}, acc ->
        if children != [] do
          acc ++ children
        else
          acc
        end
      end)

    filter_meta_by_key(%{post_meta: children}, "attachment_metadata")
    |> Enum.map(fn post_meta ->
      new_meta_value = format_meta_value(post_meta)

      cond do
        is_list(size_label) ->
          size_label
          |> Enum.reduce_while(nil, fn size, _ ->
            result = Moly.Helper.get_in_from_keys(new_meta_value, ["sizes", size, "file"])
            if result, do: {:halt, result}, else: {:cont, nil}
          end)

        is_binary(size_label) ->
          Moly.Helper.get_in_from_keys(new_meta_value, ["sizes", size_label, "file"])

        true ->
          nil
      end
    end)
  end

  def post_feature_image(%{post_meta: post_meta} = post, key, size_label)
      when is_list(post_meta) do
    post_images(post, key, size_label)
    |> List.first()
  end
end
