defmodule Monorepo.Utilities.Page do
  use MonorepoWeb, :html

  require Ash.Query

  # alias Monorepo.Contents.Post
  # alias Monorepo.Terms.Term


  def website_terms() do
    Monorepo.Utilities.cache_get_or_put(:page_website_terms, fn ->
      Ash.Query.filter(Monorepo.Terms.Term, term_taxonomy.taxonomy == "website")
      |> Ash.Query.load([:term_meta])
      |> Ash.read!(actor: %{roles: [:user]})
      |> Enum.reduce(%{}, fn %{term_meta: term_meta, slug: slug}, acc ->
        Map.put(acc, slug, term_meta)
      end)
    end, :timer.sleep(2))
  end


end
