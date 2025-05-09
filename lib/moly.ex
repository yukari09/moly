defmodule Moly do
  @moduledoc """
  Moly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Ash.Query

  alias Moly.Terms.TermMeta

  def website_cache_key, do: "moly:website:cache:data:params"

  def default_website_term_data() do
    [
      %{name: "WebSite Name", slug: "website-name", term_taxonomy: [%{taxonomy: "website", description: "The name of this website."}], term_meta: [%{term_key: "name", term_value: "Moly"}]},
      %{name: "WebSite Title", slug: "website-title", term_taxonomy: [%{taxonomy: "website", description: "The title of this website."}], term_meta: [%{term_key: "name", term_value: "New Moly Website"}]},
      %{name: "WebSite Logo", slug: "website-logo", term_taxonomy: [%{taxonomy: "website", description: "The logo url of this website."}], term_meta: [%{term_key: "name", term_value: "/images/logo.svg"}]},
      %{name: "WebSite Description", slug: "website-description", term_taxonomy: [%{taxonomy: "website", description: "The description of this website."}], term_meta: [%{term_key: "name", term_value: "A Moly powered WebSite."}]},
      %{name: "WebSite Social Links", slug: "website-social-links", term_taxonomy: [%{taxonomy: "website", description: "Social links."}], term_meta: []},
      %{name: "WebSite Blog List Title", slug: "website-blog-list-title", term_taxonomy: [%{taxonomy: "website", description: "WebSite Blog List Title."}], term_meta: [%{term_key: "name", term_value: "WebSite Blog List Title"}]},
      %{name: "WebSite Blog List Description", slug: "website-blog-list-description", term_taxonomy: [%{taxonomy: "website", description: "WebSite Blog List Description."}], term_meta: [%{term_key: "name", term_value: "WebSite Blog List Description"}]},
    ]
  end

  def website_name() do
    website_terms("website-name")
    |> Moly.Helper.get_in_from_keys([0, :term_value])
  end

  def social_links(), do: website_terms("social-links")
  def website_links(), do: website_terms("website-links")

  def website_terms(term_slug \\ nil) do
    all_website_terms =
      Moly.Utilities.cache_get_or_put(
        website_cache_key(),
        fn ->
          Ash.Query.filter(Moly.Terms.Term, term_taxonomy.taxonomy == "website")
          |> Ash.Query.load([:term_meta])
          |> Ash.read!(actor: %{roles: [:user]})
          |> Enum.reduce(%{}, fn %{term_meta: term_meta, slug: slug}, acc ->
            parase_term_meta_result =
              Enum.reduce(term_meta, [], fn x, acc ->
                y = parse_term_meta(x)
                [y | acc]
              end)

            Map.put(acc, slug, parase_term_meta_result)
          end)
        end,
        :timer.hours(1)
      )

    if term_slug, do: Map.get(all_website_terms, term_slug, []), else: all_website_terms
  end

  defp parse_term_meta(%TermMeta{term_key: term_key, term_value: term_value}) do
    case JSON.decode(term_value) do
      {:ok, value} -> %{term_key: term_key, term_value: value}
      {:error, _} -> %{term_key: term_key, term_value: term_value}
    end
  end
end
