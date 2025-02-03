defmodule Monorepo.Accounts.Helper do

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

  def is_active_user(%Monorepo.Accounts.User{confirmed_at: nil}), do: false
  def is_active_user(%Monorepo.Accounts.User{status: "active", confirmed_at: _}), do: true
  def is_active_user(%Monorepo.Accounts.User{}), do: false

  defp format_meta_value(nil), do: nil
  defp format_meta_value(%{meta_value: nil}), do: nil
  defp format_meta_value(%{meta_key: :avatar, meta_value: meta_value}), do: Jason.decode!(meta_value)
  defp format_meta_value(%{meta_value: meta_value}), do: meta_value


end
