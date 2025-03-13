defmodule Monorepo.Utilities.Page do
  use MonorepoWeb, :html

  require Ash.Query

  alias Monorepo.Terms.TermMeta

  def website_name() do
    website_terms("website-name")
    |> Monorepo.Helper.get_in_from_keys([0, :term_value])
  end
  def social_links(), do: website_terms("social-links")
  def website_links(), do: website_terms("website_links")

  def website_terms(term_slug \\ nil) do
    all_website_terms = Monorepo.Utilities.cache_get_or_put(
      :page_website_terms,
      fn ->
        Ash.Query.filter(Monorepo.Terms.Term, term_taxonomy.taxonomy == "website")
        |> Ash.Query.load([:term_meta])
        |> Ash.read!(actor: %{roles: [:user]})
        |> Enum.reduce(%{}, fn %{term_meta: term_meta, slug: slug}, acc ->
          parase_term_meta_result = Enum.reduce(term_meta, [], fn x, acc ->
            y = parse_term_meta(x)
            [y | acc]
          end)
          Map.put(acc, slug, parase_term_meta_result)
        end)
      end,
      :timer.minutes(5)
    )
    if term_slug, do: Map.get(all_website_terms, term_slug, []), else: all_website_terms
  end

  defp parse_term_meta(%TermMeta{term_key: term_key, term_value: term_value}) do
    case JSON.decode(term_value) do
      {:ok, value} -> %{term_key: term_key, term_value: value}
      {:error, _} ->  %{term_key: term_key, term_value: term_value}
    end
  end
end
