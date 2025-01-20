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

  def load_user_meta(%Monorepo.Accounts.User{} = user) do
    user = Ash.load!(user, [:user_meta])
    user_map = Map.take(user, [:email, :confirmed_at, :id, :roles, :status, :inserted_at, :updated_at])
    Enum.reduce(user.user_meta, user_map, &format_user_meta/2)
  end

  defp format_user_meta(%{meta_key: :avatar, meta_value: meta_value}, user_map) do
    Map.put(user_map, :avatar, Jason.decode!(meta_value))
  end

  defp format_user_meta(%{meta_key: meta_key, meta_value: meta_value}, user_map) do
    Map.put(user_map, meta_key, meta_value)
  end


end
