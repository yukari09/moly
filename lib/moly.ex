defmodule Moly do
  @moduledoc """
  Moly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def default_website_term_data() do
    [
      %{name: "WebSite Name", slug: "website-name", term_taxonomy: [%{taxonomy: "website", description: "The name of this website."}], term_meta: [%{term_key: "name", term_value: "Moly"}]},
      %{name: "WebSite Title", slug: "website-title", term_taxonomy: [%{taxonomy: "website", description: "The title of this website."}], term_meta: [%{term_key: "name", term_value: "New Moly Website"}]},
      %{name: "WebSite Logo", slug: "website-logo", term_taxonomy: [%{taxonomy: "website", description: "The logo url of this website."}], term_meta: [%{term_key: "name", term_value: "/images/logo.svg"}]},
      %{name: "WebSite Description", slug: "website-description", term_taxonomy: [%{taxonomy: "website", description: "The description of this website."}], term_meta: [%{term_key: "name", term_value: "A Moly powered WebSite."}]},
      %{name: "WebSite Social Links", slug: "website-social-links", term_taxonomy: [%{taxonomy: "website", description: "Social links."}], term_meta: []},
    ]
  end
end
