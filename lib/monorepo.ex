defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  # def test() do
  #   # current_user = Ash.get!(Monorepo.Accounts.User, "d0faba77-88b2-4edc-b358-dbf6419a7351", context: %{private: %{ash_authentication?: true}})
  #   # post = Ash.get!(Monorepo.Contents.Post, "03331276-0138-4ec3-add7-0cfb71b68623", actor: current_user)

  #   # # Monorepo.Contents.create_meta(%{meta_key: :test, meta_value: "test", post: post})
  #   # # |> Ash.Changeset.manage_relationship(:post, post)

  #   # Monorepo.Contents.PostMeta
  #   # |> Ash.Changeset.for_create(:create, %{meta_key: :test, meta_value: "test"})
  #   # |> Ash.Changeset.manage_relationship(:post, post, type: :append_and_remove)
  #   # |> Ash.create!(actor:  current_user)

  #   # IO.puts("Hello, World!")
  # end


end
