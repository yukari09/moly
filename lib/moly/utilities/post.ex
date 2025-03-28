defmodule Moly.Utilities.Post do
  alias Moly.Contents.Post

  @doc """
  See table post_meta meta_value
  """

  def attachment_filesize(%Post{id: _id, post_meta: _} = post) do
    post_meta_value(post, "attachment_filesize")
  end

  def attachment_metadata(%Post{id: _id, post_meta: _} = post) do
    attachment_metadata_valaue = post_meta_value(post, "attachment_metadata")

    if attachment_metadata_valaue do
      JSON.decode!(attachment_metadata_valaue)
    else
      %{}
    end
  end

  def attachment_metadata_image(
        %Post{id: _id, post_meta: _post_meta} = post,
        sizes,
        only_first? \\ false
      )
      when is_list(sizes) do
    attachment_metadata_value = attachment_metadata(post)

    if only_first? do
      Enum.reduce_while(sizes, nil, fn size, _ ->
        file =
          Moly.Helper.get_in_from_keys(attachment_metadata_value, ["sizes", size, "file"])

        if file, do: {:halt, file}, else: {:cont, nil}
      end)
    else
      Enum.reduce(sizes, %{}, fn size, acc ->
        file =
          Moly.Helper.get_in_from_keys(attachment_metadata_value, ["sizes", size, "file"])

        if file, do: Map.put(acc, size, file), else: acc
      end)
    end
  end

  @doc """
    Ash.Query.new(Moly.Contents.Post)
    |> Ash.Query.load([
      post_meta: :children
    ])
    |> Ash.read!()

    post_attachment_metadata_images([meta_key], ["medium"])
  """
  def post_attachment_metadata_images(
        %Post{id: id, post_meta: _post_meta} = post,
        meta_key,
        sizes,
        return_all_sizes \\ false
      )
      when is_binary(id) and is_binary(meta_key) do
    filter_by_meta_key(post, meta_key)
    |> Enum.reduce([], fn
      %{children: children}, acc ->
        filter_by_meta_key(%{post_meta: children}, "attachment_metadata")
        |> case do
          post_meta when is_list(post_meta) ->
            acc ++
              Enum.map(post_meta, &post_attachment_metadata_image(&1, sizes, return_all_sizes))

          _ ->
            []
        end
    end)
  end

  defp post_attachment_metadata_image(
         %{meta_key: "attachment_metadata", meta_value: meta_value},
         sizes,
         return_all_sizes
       ) do
    meta_value_decoded = JSON.decode!(meta_value)

    result =
      if return_all_sizes do
        Enum.reduce(sizes, [], fn size, acc ->
          image_media = Moly.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])

          if image_media do
            image_media = Keyword.put([], String.to_atom(size), image_media)
            [image_media | acc]
          else
            acc
          end
        end)
      else
        Enum.reduce_while(sizes, nil, fn size, _ ->
          image_media = Moly.Helper.get_in_from_keys(meta_value_decoded, ["sizes", size])

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
    filter_by_meta_key(post, meta_key)
    |> Moly.Helper.get_in_from_keys([0, :meta_value])
  end

  def post_meta_by_filter(%Post{id: id} = post, meta_key) when is_binary(id), do: filter_by_meta_key(post, meta_key)

  defp filter_by_meta_key(%{post_meta: post_meta}, meta_key)
       when is_list(post_meta) and is_binary(meta_key) do
    Enum.filter(post_meta, &(Regex.compile!(meta_key) |>  Regex.match?(&1.meta_key)))
  end

  defp filter_by_meta_key(_, _), do: []
end
