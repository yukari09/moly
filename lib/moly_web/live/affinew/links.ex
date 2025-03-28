defmodule MolyWeb.Affinew.Links do
  use MolyWeb, :html

  def under_construction, do: ~p"/under-construction"
  def programs(params \\ %{}) when is_map(params), do: ~p"/programs?#{params}"
  def submit(), do: ~p"/program/submit"
  def term(slug) when is_binary(slug), do: ~p"/programs/#{slug}"
  def view(post_name),  do: ~p"/program/#{post_name}"
  def user(%Moly.Accounts.User{} = user) do
    username = Moly.Utilities.Account.user_username(user)
    ~p"/user/@#{username}"
  end
end
