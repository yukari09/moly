defmodule Moly do
  @moduledoc """
  Moly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Ash.Query

  require Logger
  alias Moly.Terms.TermMeta


  @website_name "Moly"
  @website_title "New Moly Website"
  @website_logo "/images/logo.png"
  @website_favicon "/favicon.ico"
  @website_description "A Moly powered WebSite"
  @website_auth_background "/images/auth-background-bg.webp"

  @cache_key_pattern "moly:{{slug_or_name}}:cached:term:data"

  def default_website_term_data() do
    [
      %{name: "WebSite Status", slug: "website-status", term_taxonomy: [%{taxonomy: "website", description: "Current status of this website, offline, pending, maintain, online"}], term_meta: [%{term_key: "name", term_value: "pending"}]},
      %{name: "WebSite Name", slug: "website-name", term_taxonomy: [%{taxonomy: "website", description: "The name of this website."}], term_meta: [%{term_key: "name", term_value: @website_name}]},
      %{name: "WebSite Title", slug: "website-title", term_taxonomy: [%{taxonomy: "website", description: "The title of this website."}], term_meta: [%{term_key: "name", term_value: @website_title}]},
      %{name: "WebSite Logo", slug: "website-logo", term_taxonomy: [%{taxonomy: "website", description: "The logo url of this website."}], term_meta: [%{term_key: "name", term_value: @website_logo}]},
      %{name: "WebSite Favicon", slug: "website-favicon", term_taxonomy: [%{taxonomy: "website", description: "The favicon.ico url of this website."}], term_meta: [%{term_key: "name", term_value: @website_favicon}]},
      %{name: "WebSite Description", slug: "website-description", term_taxonomy: [%{taxonomy: "website", description: "The description of this website."}], term_meta: [%{term_key: "name", term_value: @website_description}]},
      %{name: "WebSite Auth Background", slug: "website-auth-background", term_taxonomy: [%{taxonomy: "website", description: "The auth page background image url."}], term_meta: [%{term_key: "name", term_value: @website_auth_background}]},
      %{name: "WebSite Social Links", slug: "website-social-links", term_taxonomy: [%{taxonomy: "website", description: "Social links."}], term_meta: []},
      %{name: "WebSite Blog List Title", slug: "website-blog-list-title", term_taxonomy: [%{taxonomy: "website", description: "WebSite Blog List Title."}], term_meta: [%{term_key: "name", term_value: "WebSite Blog List Title"}]},
      %{name: "WebSite Blog List Description", slug: "website-blog-list-description", term_taxonomy: [%{taxonomy: "website", description: "WebSite Blog List Description."}], term_meta: [%{term_key: "name", term_value: "WebSite Blog List Description"}]},

      %{name: "WebSite Footer Column1", slug: "website-footer-column-1", term_taxonomy: [%{taxonomy: "website", description: "Footer Column1"}], term_meta: []},
      %{name: "WebSite Footer Column2", slug: "website-footer-column-2", term_taxonomy: [%{taxonomy: "website", description: "Footer Column2"}], term_meta: []},
      %{name: "WebSite Footer Column3", slug: "website-footer-column-3", term_taxonomy: [%{taxonomy: "website", description: "Footer Column3"}], term_meta: []},
      %{name: "WebSite Footer Column4", slug: "website-footer-column-4", term_taxonomy: [%{taxonomy: "website", description: "Footer Column4"}], term_meta: []},

      %{name: "WebSite Footer Column1 Keyword", slug: "website-footer-column-1-keyword", term_taxonomy: [%{taxonomy: "website", description: "Footer Column1 Keyword"}], term_meta: []},
      %{name: "WebSite Footer Column2 Keyword", slug: "website-footer-column-2-keyword", term_taxonomy: [%{taxonomy: "website", description: "Footer Column2 Keyword"}], term_meta: []},
      %{name: "WebSite Footer Column3 Keyword", slug: "website-footer-column-3-keyword", term_taxonomy: [%{taxonomy: "website", description: "Footer Column3 Keyword"}], term_meta: []},
      %{name: "WebSite Footer Column4 Keyword", slug: "website-footer-column-4-keyword", term_taxonomy: [%{taxonomy: "website", description: "Footer Column4 Keyword"}], term_meta: []},

      %{name: "WebSite Assigns", slug: "website-assigns", term_taxonomy: [%{taxonomy: "website", description: "Extra website assigns"}], term_meta: []},
    ]
  end

  def website_status(), do: website_term("website-status", true, nil)
  def website_logo(), do: website_term("website-logo", true, @website_logo)
  def website_favicon(), do: website_term("website-favicon", true, @website_favicon)
  def website_title(), do: website_term("website-title", true,  @website_title)
  def website_name(), do: website_term("website-name", true, @website_name)
  def website_auth_background(), do: website_term("website-auth-background", true, @website_auth_background)
  def website_description(), do: website_term("website-description", true, @website_description)
  def social_links(), do: website_term("social-links")
  def website_links(), do: website_term("website-links")
  def website_blog_list_title(), do: website_term("website-blog-list-title", true)
  def website_blog_list_description(), do: website_term("website-blog-list-description", true)
  def website_footer_column(level), do: website_term("website-footer-column-#{level}")
  def website_footer_column_keyword(level), do: website_term("website-footer-column-#{level}-keyword", true)

  def website_assigns(), do: website_term("website-assigns", true, [])

  def delete_website_cache(), do: cache_key("website") |> Moly.Utilities.cache_del()

  defp website_term(slug, first_term_value \\ false, default \\ nil) do
    get_terms_by_taxonomy("website", [term_slug: slug, first_term_value: first_term_value, default: default])
  end

  @doc """
  Get terms by taxonomy
  taxonomy:
  - website
  - config
  - notification
  - system
  - application
  - node
  opts:
  - data_from_chace: using data from cache if true
  - term_slug: filter data by term slug
  - first_term_value: return first term_meta.term_value if true
  """
  def get_terms_by_taxonomy(taxonomy, opts \\ []) do
    fetch_term_by_taxonomy_fun = fn taxonomy ->
      Ash.Query.filter(Moly.Terms.Term, term_taxonomy.taxonomy == ^taxonomy)
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
    end

    default = opts[:default]
    term_slug = opts[:term_slug]
    data_from_cache = if opts[:data_from_chace] == nil, do: true, else: opts[:data_from_chace]
    first_term_value = if opts[:first_term_value] == nil, do: true, else: opts[:first_term_value]

    term_data =
      if data_from_cache do
        key = cache_key(taxonomy)
        Moly.Utilities.cache_get_or_put(key, fn -> fetch_term_by_taxonomy_fun.(taxonomy) end, :timer.hours(1))
      else
        fetch_term_by_taxonomy_fun.(taxonomy)
      end

    if term_slug do
      filtered_term = Map.get(term_data, term_slug)
      if first_term_value do
        Moly.Helper.get_in_from_keys(filtered_term, [0, :term_value]) || default
      else
        filtered_term
      end
    else
      term_data
    end
  end

  defp cache_key(name), do: String.replace(@cache_key_pattern, "{{slug_or_name}}", name)

  defp parse_term_meta(%TermMeta{term_key: term_key, term_value: term_value}) do
    case JSON.decode(term_value) do
      {:ok, value} -> %{term_key: term_key, term_value: value}
      {:error, _} -> %{term_key: term_key, term_value: term_value}
    end
  end
end
