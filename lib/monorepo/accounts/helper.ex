defmodule Monorepo.Accounts.Helper do
  # def current_user_name(%{display_name: nil} = user),
  #   do: user.email |> to_string() |> String.split("@") |> List.first()

  # def current_user_name(user), do: user.display_name


  # def current_user_short_name(user, upcase \\ true) do
  #   current_user_name(user)
  #   |> String.slice(0, 2)
  #   |> (fn s -> if upcase, do: String.upcase(s), else: s end).()
  # end

  def generate_avatar_from_url(url) do
    hashed_path = Monorepo.Helper.put_object_from_url(url)
    sizes = [16, 32, 64, 128]
    Enum.reduce(sizes, %{}, fn size, acc ->
      Map.put(acc, size, Monorepo.Helper.image_resize(hashed_path, size, size))
    end)
    |> Jason.encode!()
  end

  def load_meta_value_by_meta_key(%Monorepo.Accounts.User{user_meta: user_meta}, meta_key) when is_atom(meta_key) do
    Enum.find(user_meta, & &1.meta_key == meta_key)
    |> format_meta_value()
  end

  defp format_meta_value(nil), do: nil
  defp format_meta_value(%{meta_value: nil}), do: nil
  defp format_meta_value(%{meta_key: :avatar, meta_value: meta_value}), do: Jason.decode!(meta_value)
  defp format_meta_value(%{meta_value: meta_value}), do: meta_value


end
