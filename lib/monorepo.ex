defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  def test() do
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

  end


end
