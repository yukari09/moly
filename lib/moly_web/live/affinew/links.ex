defmodule MolyWeb.Affinew.Links do
  use MolyWeb, :html

  def under_construction, do: ~p"/under-construction"
  def programs(params \\ %{}) when is_map(params), do: ~p"/browse?#{params}"
  def submit(), do: ~p"/affiliate/submit"
  def term(slug) when is_binary(slug), do: ~p"/affiliates/#{slug}"
  def term(slug, params \\ %{}) when is_binary(slug), do: ~p"/affiliates/#{slug}?#{params}"
  def results(params), do: ~p"/results?#{params}"
  def view(post_name), do: ~p"/affiliate/#{post_name}"

  def user(%Moly.Accounts.User{} = user) do
    username = Moly.Utilities.Account.user_username(user)
    ~p"/user/@#{username}"
  end
end
