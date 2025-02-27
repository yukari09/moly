defmodule Monorepo.Utilities.Post do
  alias Monorepo.Contents.Post
  @doc """
  See table post_meta meta_value
  """

  def test() do
    post =
      Ash.get!(Monorepo.Contents.Post, "8fd7455a-084f-494b-ad4b-140dd38e4d04", actor: %{roles: [:user]})
      |> Ash.load!([:post_categories, :post_tags, author: :user_meta, post_meta: :children], actor: %{roles: [:user]})

    post.post_tags

    # Monorepo.Utilities.Affiliate.affiliate_tags(post)


      # post_attachment_metadata_images(post, :attachment_affiliate_media_feature, ["xxlarge", "xlarge"], false)
  end

  def attachment_filesize(%Post{id: _id, post_meta: _} = post) do
    post_meta_value(post, :attachment_filesize)
  end

  def attachment_metadata(%Post{id: _id, post_meta: _} = post) do
    attachment_metadata_valaue = post_meta_value(post, :attachment_metadata)
    if attachment_metadata_valaue do
      JSON.decode!(attachment_metadata_valaue)
    else
      %{}
    end
  end

  def attachment_metadata_image(%Post{id: _id, post_meta: _post_meta} = post, sizes, only_first? \\ false) when is_list(sizes) do
    attachment_metadata_value = attachment_metadata(post)
    if only_first? do
      Enum.reduce_while(sizes, nil, fn size, _ ->
        file = Monorepo.Helper.get_in_from_keys(attachment_metadata_value, ["sizes", size, "file"])
        if file, do: {:halt, file}, else: {:cont, nil}
      end)
    else
      Enum.reduce(sizes, %{}, fn size, acc ->
        file = Monorepo.Helper.get_in_from_keys(attachment_metadata_value, ["sizes", size, "file"])
        if file, do: Map.put(acc, size, file), else: acc
      end)
    end
  end

  #For post_type :post
  #example :attachment_affiliate_media_feature
  def post_attachment_metadata_images(%Post{id: id, post_meta: _post_meta} = post, meta_key, sizes, return_all_sizes \\ false) when is_binary(id) and is_atom(meta_key) do
    filter_by_meta_key(post, meta_key)
    |> Enum.reduce([], fn
      %{children: children}, acc ->
        filter_by_meta_key(%{post_meta: children}, :attachment_metadata)
        |> case do
          post_meta when is_list(post_meta) ->
            acc ++ Enum.map(post_meta, &(post_attachment_metadata_image(&1, sizes, return_all_sizes)))
          _ -> []
        end
    end)
  end

  defp post_attachment_metadata_image(%{meta_key: :attachment_metadata, meta_value: meta_value}, sizes, return_all_sizes) do
    meta_value_decoded =  JSON.decode!(meta_value)
    result =
      if return_all_sizes do
        Enum.reduce(sizes, [], fn size, acc ->
          image_media = Monorepo.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])
          if image_media do
            image_media = Keyword.put([], String.to_atom(size), image_media)
            [image_media | acc]
          else
            acc
          end
        end)
      else
        Enum.reduce_while(sizes, nil, fn size, _ ->
          image_media = Monorepo.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])
          if image_media do
            {:halt, Keyword.put([], String.to_atom(size), image_media)}
          else
            {:cont, meta_value_decoded}
          end
        end)
      end
    result
  end

  def post_meta_value(%Post{id: id} = post, meta_key) when is_binary(id) do
    case filter_by_meta_key(post, meta_key) do
      post_meta when is_list(post_meta) ->
        List.first(post_meta)
        |> Map.get(:meta_value)
      _ -> nil
    end
  end

  defp filter_by_meta_key(%{post_meta: post_meta}, meta_key) when is_list(post_meta) and is_atom(meta_key) do
    Enum.filter(post_meta, &(&1.meta_key == meta_key))
  end
  defp filter_by_meta_key(_, _), do: []
end
