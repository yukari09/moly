defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def test() do
    require Ash.Query
    current_user = Ash.get!(Monorepo.Accounts.User, "8867319c-7951-4a59-b581-e5d4c6b751fe", context: %{private: %{ash_authentication?: true}})
    new_user_meta_party = [%{"meta_key" => "description", "meta_value" => "test for update or insert"}]
    # Ash.Changeset.new(current_user)
    # |> Ash.Changeset.manage_relationship(:user_meta, new_user_meta_party, type: :create)
    Ash.update(current_user, %{user_meta: new_user_meta_party}, action: :update_user_meta, context: %{private: %{ash_authentication?: true}})
  end
  # def test() do
    # require Ash.Query

    # current_user =
    #   Ash.get!(Monorepo.Accounts.User, "d0faba77-88b2-4edc-b358-dbf6419a7351", context: %{private: %{ash_authentication?: true}})
    #   |> Ash.load!([:user_meta], actor: :admin)
    # post =
    #   Ash.get!(Monorepo.Contents.Post, "9cadd9ea-8368-4b68-a5a3-aaf5b25eb0ec", actor: current_user)
    #   |> Ash.load!([:post_categories], actor: current_user)


    # IO.inspect(post.post_categories)
    # IO.inspect(post.term_taxonomy_tags)
    # IO.inspect(post.term_taxonomy_categories)

  # end


end
