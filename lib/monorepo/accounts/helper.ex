defmodule Monorepo.Accounts.Helper do
  def current_user_name(%{display_name: nil} = user),
    do: user.email |> to_string() |> String.split("@") |> List.first()

  def current_user_name(user), do: user.display_name

  def current_user_short_name(user, upcase \\ true) do
    current_user_name(user)
    |> String.slice(0, 2)
    |> (fn s -> if upcase, do: String.upcase(s), else: s end).()
  end
end
