defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  def test() do
    # require Ash.Query

    # current_user = Ash.get!(Monorepo.Accounts.User, "d0faba77-88b2-4edc-b358-dbf6419a7351", context: %{private: %{ash_authentication?: true}})

    # term_names = []
    # Monorepo.Terms.TermTaxonomy
    # |> Ash.Query.filter(term.name in ^term_names and taxonomy == "post_tag")
    # |> Ash.read!(actor: current_user)
    # |> Ash.load!([:term])
  end


end
