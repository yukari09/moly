defmodule Monorepo.Contents.Helpers do
  def struct_meta(nil), do: %{}

  def struct_meta(metas) when is_list(metas) do
    Map.new(metas, &{&1.meta_key, &1.meta_value})
  end

  def media_file_meta(metas) do
    metas
    |> struct_meta()
    |> Map.get(:attachment_metadata)
    |> fetch_image_file_from_attachment_metadata()
  end

  def media_file_meta_image(post_meta, image_key)
      when is_list(post_meta) and is_list(image_key) do
    post_meta
    |> struct_meta()
    |> Map.get(:attachment_metadata)
    |> fetch_image_file_from_attachment_metadata(image_key)
  end

  def fetch_image_file_from_attachment_metadata(meta_value) when is_binary(meta_value) do
    meta_value
    |> Jason.decode()
    |> case do
      {:ok, meta_value} -> meta_value
      _ -> nil
    end
  end

  def fetch_image_file_from_attachment_metadata(meta_value, image_key)
      when is_binary(meta_value) and is_list(image_key) do
    case fetch_image_file_from_attachment_metadata(meta_value) do
      nil ->
        nil

      meta_value ->
        Enum.map(image_key, &get_in(meta_value, ["sizes", &1, "file"]))
        |> List.first()
    end
  end
end
