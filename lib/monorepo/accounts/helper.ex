defmodule Monorepo.Accounts.Helper do

  @bucket_prefix "user_meta"

  def generate_avatar_from_url(url) do
    hashed_path = Monorepo.Helper.put_object_from_url(url, @bucket_prefix)

    sizes = [16, 32, 64, 128]

    Enum.reduce(sizes, %{}, fn size, acc ->
      Map.put(acc, size, Monorepo.Helper.image_resize(hashed_path, size, size))
    end)
    |> Map.put(:filename, hashed_path)
    |> JSON.encode!()
  end

  def generate_avatar_from_entry(entry, path) do
    sizes = [{:"16", 16}, {:"32", 32}, {:"64", 64}, {:"128", 128}]
    generate_meta_value_from_upload_entry(entry, path, sizes, false)
  end

  def generate_banner_from_entry(entry, path) do
    breakpoints = [
      {:sm, 640},
      {:md, 768},
      {:lg, 1024},
      {:xl, 1280},
      {:xxl, 1536}
    ]
    generate_meta_value_from_upload_entry(entry, path, breakpoints)
  end

  defp generate_meta_value_from_upload_entry(entry, path, sizes, keep_ratio \\ true) do
    filename =
      [entry.uuid <> Path.extname(entry.client_name)]
      |> Path.join()
      |> Monorepo.Helper.put_object(path, @bucket_prefix)

    ratio = if keep_ratio do
      {_, _, ratio} = case Monorepo.Helper.ffprobe(path) do
        {:ok, data} ->
          video_stream = Enum.find(data["streams"], &(&1["codec_type"] == "video"))
          width = video_stream["width"]
          height = video_stream["height"]
          {width, height, width/height}
        _ -> 1
      end
      ratio
    else
      1
    end

    Enum.reduce(sizes, %{}, fn {size_key, size_width}, acc ->
      size_height = (size_width / ratio) |> trunc()
      Map.put(acc, size_key, Monorepo.Helper.image_resize(filename, size_width, size_height))
    end)
    |> Map.put(:filename, filename)
    |> JSON.encode!()
  end

  def load_meta_value_by_meta_key(%Monorepo.Accounts.User{user_meta: user_meta}, meta_key)
      when is_atom(meta_key) do
    Enum.find(user_meta, &(&1.meta_key == meta_key))
    |> format_meta_value()
  end

  def is_active_user(%Monorepo.Accounts.User{confirmed_at: nil}), do: false
  def is_active_user(%Monorepo.Accounts.User{status: :inactive}), do: false
  def is_active_user(%Monorepo.Accounts.User{status: :active, confirmed_at: _}), do: true
  def is_active_user(nil), do: nil

  defp format_meta_value(nil), do: nil
  defp format_meta_value(%{meta_value: nil}), do: nil

  defp format_meta_value(%{meta_key: :avatar, meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  defp format_meta_value(%{meta_key: :banner, meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  defp format_meta_value(%{meta_value: meta_value}), do: meta_value
end
