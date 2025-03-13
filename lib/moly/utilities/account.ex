defmodule Moly.Utilities.Account do
  use MolyWeb, :html

  @bucket_prefix "user_meta"

  def generate_avatar_from_url(url) do
    hashed_path = Moly.Helper.put_object_from_url(url, @bucket_prefix)

    sizes = [16, 32, 64, 128]

    Enum.reduce(sizes, %{}, fn size, acc ->
      Map.put(acc, size, Moly.Helper.image_resize(hashed_path, size, size))
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
      |> Moly.Helper.put_object(path, @bucket_prefix)

    ratio =
      if keep_ratio do
        {_, _, ratio} =
          case Moly.Helper.ffprobe(path) do
            {:ok, data} ->
              video_stream = Enum.find(data["streams"], &(&1["codec_type"] == "video"))
              width = video_stream["width"]
              height = video_stream["height"]
              {width, height, width / height}

            _ ->
              1
          end

        ratio
      else
        1
      end

    Enum.reduce(sizes, %{}, fn {size_key, size_width}, acc ->
      size_height = (size_width / ratio) |> trunc()
      Map.put(acc, size_key, Moly.Helper.image_resize(filename, size_width, size_height))
    end)
    |> Map.put(:filename, filename)
    |> JSON.encode!()
  end

  def link_profile(user), do: ~p"/user/page/@#{user_username(user)}"

  def user_banner(user, size), do: load_meta_value_by_meta_key(user, :banner, &Map.get(&1, size))
  def user_avatar(user, size), do: load_meta_value_by_meta_key(user, :avatar, &Map.get(&1, size))

  def user_name(user, string_length \\ 0),
    do:
      load_meta_value_by_meta_key(
        user,
        :name,
        &((string_length == 0 && &1) || String.slice(&1, 0, string_length))
      )

  def user_username(user, string_length \\ 0),
    do:
      load_meta_value_by_meta_key(
        user,
        :username,
        &((string_length == 0 && &1) || String.slice(&1, 0, string_length))
      )

  def is_active_user(%Moly.Accounts.User{confirmed_at: nil}), do: false
  def is_active_user(%Moly.Accounts.User{status: :inactive}), do: false
  def is_active_user(%Moly.Accounts.User{status: :active, confirmed_at: _}), do: true
  def is_active_user(nil), do: nil

  def load_meta_value_by_meta_key(
        %Moly.Accounts.User{user_meta: user_meta},
        meta_key,
        after_callback \\ nil
      )
      when is_atom(meta_key) do
    meta_value =
      Enum.find(user_meta, &(&1.meta_key == meta_key))
      |> format_meta_value()

    case meta_value do
      nil ->
        nil

      meta_value_result ->
        (after_callback && after_callback.(meta_value_result)) || meta_value_result
    end
  end

  attr(:user, Moly.Accounts.User, required: true)
  attr(:size, :integer, required: true)

  def avatar_html(assigns) do
    ~H"""
    <img :if={user_avatar(@user, "#{@size}")} class="inline-block w-full h-full rounded-full" src={user_avatar(@user, "#{@size}")} alt={user_username(@user)}>
    <span :if={!user_avatar(@user, "#{@size}")} class="inline-flex w-full h-full items-center justify-center rounded-full bg-primary border-2 border-white">
      <span class="font-medium text-white uppercase text-sm">{user_name(@user, 1)}</span>
    </span>
    """
  end

  defp format_meta_value(nil), do: nil
  defp format_meta_value(%{meta_value: nil}), do: nil

  defp format_meta_value(%{meta_key: :avatar, meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  defp format_meta_value(%{meta_key: :banner, meta_value: meta_value}),
    do: JSON.decode!(meta_value)

  defp format_meta_value(%{meta_value: meta_value}), do: meta_value
end
