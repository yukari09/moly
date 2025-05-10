defmodule Moly do
  @moduledoc """
  Moly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Ash.Query

  alias Moly.Terms.TermMeta


  @website_name "Moly"
  @website_title "New Moly Website"
  @website_logo "/images/logo.png"
  @website_favicon "/favicon.ico"
  @website_description "A Moly powered WebSite"
  @website_auth_background "/images/auth-background-bg.webp"

  def website_cache_key, do: "moly:website:cache:data:params"
  def config_cache_key, do: "moly:config:cache:data:params"

  def default_website_term_data() do
    [
      %{name: "WebSite Status", slug: "website-status", term_taxonomy: [%{taxonomy: "website", description: "Current status of this website, pending, maintain, running"}], term_meta: [%{term_key: "name", term_value: "pending"}]},
      %{name: "WebSite Name", slug: "website-name", term_taxonomy: [%{taxonomy: "website", description: "The name of this website."}], term_meta: [%{term_key: "name", term_value: @website_name}]},
      %{name: "WebSite Title", slug: "website-title", term_taxonomy: [%{taxonomy: "website", description: "The title of this website."}], term_meta: [%{term_key: "name", term_value: @website_title}]},
      %{name: "WebSite Logo", slug: "website-logo", term_taxonomy: [%{taxonomy: "website", description: "The logo url of this website."}], term_meta: [%{term_key: "name", term_value: @website_logo}]},
      %{name: "WebSite Favicon", slug: "website-favicon", term_taxonomy: [%{taxonomy: "website", description: "The favicon.ico url of this website."}], term_meta: [%{term_key: "name", term_value: @website_favicon}]},
      %{name: "WebSite Description", slug: "website-description", term_taxonomy: [%{taxonomy: "website", description: "The description of this website."}], term_meta: [%{term_key: "name", term_value: @website_description}]},
      %{name: "WebSite Auth Background", slug: "website-auth-background", term_taxonomy: [%{taxonomy: "website", description: "The auth page background image url."}], term_meta: [%{term_key: "name", term_value: @website_auth_background}]},
      %{name: "WebSite Social Links", slug: "website-social-links", term_taxonomy: [%{taxonomy: "website", description: "Social links."}], term_meta: []},
      %{name: "WebSite Blog List Title", slug: "website-blog-list-title", term_taxonomy: [%{taxonomy: "website", description: "WebSite Blog List Title."}], term_meta: [%{term_key: "name", term_value: "WebSite Blog List Title"}]},
      %{name: "WebSite Blog List Description", slug: "website-blog-list-description", term_taxonomy: [%{taxonomy: "website", description: "WebSite Blog List Description."}], term_meta: [%{term_key: "name", term_value: "WebSite Blog List Description"}]}
    ]
  end

  def default_config_term_data() do
    [
      %{
        name: "Config Mailer",
        slug: "config-mailer",
        term_taxonomy: [%{taxonomy: "config", description: "Mailer Config, supported Adapters are: Swoosh.Adapters.Local, Resend.Swoosh.Adapter, Swoosh.Adapters.Brevo, Swoosh.Adapters.SMTP"}],
        term_meta: [
          %{term_key: "adapter", term_value: "0"},
          %{term_key: "address", term_value: "0"},
          %{term_key: "host", term_value: "0"},
          %{term_key: "encryption", term_value: "0"},
          %{term_key: "port", term_value: "0"},
          %{term_key: "username", term_value: "0"},
          %{term_key: "password/api_key", term_value: "0"}
        ]
      },
      %{
        name: "Config Auth Google",
        slug: "config-auth-google",
        term_taxonomy: [%{taxonomy: "config", description: "Google Auth Config"}],
        term_meta: [
          %{term_key: "google_oauth2_client_id", term_value: "0"},
          %{term_key: "google_oauth2_redirect_uri", term_value: "0"},
          %{term_key: "google_oauth2_client_secret", term_value: "0"},
        ]
      },
      %{
        name: "Config Imagor",
        slug: "config-imagor",
        term_taxonomy: [%{taxonomy: "config", description: "Google Auth Config"}],
        term_meta: [
          %{term_key: "imagor_endpoint", term_value: "0"},
          %{term_key: "imagor_secret", term_value: "0"}
        ]
      },
      %{
        name: "Config Cloudflare Turnstile",
        slug: "config-cloudflare-turnstile",
        term_taxonomy: [%{taxonomy: "config", description: "Cloudflare Turnstile Config"}],
        term_meta: [
          %{term_key: "imagor_endpoint", term_value: "0"},
          %{term_key: "imagor_secret", term_value: "0"}
        ]
      },
      %{
        name: "Config Object Storage",
        slug: "config-object-storage",
        term_taxonomy: [%{taxonomy: "config", description: "Object Storage Config"}],
        term_meta: [
          %{term_key: "scheme", term_value: "0"},
          %{term_key: "host", term_value: "0"},
          %{term_key: "port", term_value: "0"},
          %{term_key: "bucket", term_value: "0"},
          %{term_key: "region", term_value: "0"},
          %{term_key: "access_key_id", term_value: "0"},
          %{term_key: "secret_access_key", term_value: "0"},
        ]
      },
    ]
  end

  def website_logo(), do: website_terms("website-logo", true) || @website_logo
  def website_favicon(), do: website_terms("website-favicon", true) || @website_favicon
  def website_name(), do: website_terms("website-name", true) || @website_name
  def website_auth_background(), do: website_terms("website-auth-background", true) || @website_auth_background
  def website_description(), do: website_terms("website-description", true) || @website_description
  def social_links(), do: website_terms("social-links")
  def website_links(), do: website_terms("website-links")

  def config_google(), do: config_terms("config-auth-google")

  def website_terms(term_slug \\ nil, first_term_value \\ false) do
    all_website_terms =
      Moly.Utilities.cache_get_or_put(
        website_cache_key(),
        &get_all_terms_by_taxonomy/0,
        :timer.hours(1)
      )

    result = if term_slug, do: Map.get(all_website_terms, term_slug, []), else: all_website_terms
    if first_term_value, do: Moly.Helper.get_in_from_keys(result, [0, :term_value]), else: result
  end

  def config_terms(term_slug \\ nil, first_term_value \\ false) do
    all_config_terms =
      Moly.Utilities.cache_get_or_put(
        website_cache_key(),
        &get_all_terms_by_taxonomy/0,
        :timer.hours(1)
      )

    result = if term_slug, do: Map.get(all_config_terms, term_slug, []), else: all_config_terms
    if first_term_value, do: Moly.Helper.get_in_from_keys(result, [0, :term_value]), else: result
  end

  # website,config,notification,system,application,node are reserved typies.
  defp get_all_terms_by_taxonomy(taxonomy \\ "website") do
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

  defp parse_term_meta(%TermMeta{term_key: term_key, term_value: term_value}) do
    case JSON.decode(term_value) do
      {:ok, value} -> %{term_key: term_key, term_value: value}
      {:error, _} -> %{term_key: term_key, term_value: term_value}
    end
  end
end
