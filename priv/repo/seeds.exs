# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Moly.Repo.insert!(%Moly.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# defmodule Moly.Seed do
#   require Logger
#   require Ash.Query
#   require AshPostgres.DataLayer

#   alias Moly.Terms.Term

#   def term_upsert(inputs) when is_list(inputs) do
#     Enum.map(inputs, &term_upsert(&1))
#   end

#   def term_upsert(%{name: name, slug: slug} = input) when is_map(input) do
#     has_one? = Ash.Query.filter(Term, slug == ^ slug) |> Ash.exists?(actor: %{roles: [:admin]})
#     if has_one? do
#       Logger.warning("The record of slug about \"#{slug}\", is exitsed.")
#     else
#       Logger.info("Insert to Table<terms>: name \"#{name}\", slug: \"#{slug}\".")
#       Ash.Seed.upsert!(Term, input,
#         actor: %{roles: [:admin]},
#         action: :create,
#         identity: :unique_slug
#       )
#     end
#   end
# end

# #Insert website config default data
# Moly.default_website_term_data()
# |> Moly.Seed.term_upsert()

# Moly.default_config_term_data()
# |> Moly.Seed.term_upsert()
