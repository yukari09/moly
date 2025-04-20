defmodule Moly.Affinew.Workers.Sitemap do
  use Oban.Worker, queue: :periodic, max_attempts: 10

  use MolyWeb, :verified_routes

  require Ash.Query

  @impl true
  def perform(_args) do
    generate_affiliate_sitemap()
    generate_affiliate_term_sitemap()
    generate_users_sitemap()
    :ok
  end

  defp get_config(name) do
    [
      name: name,
      store: Sitemapper.S3Store,
      store_config: [bucket: Application.get_env(:ex_aws, :s3) |> Keyword.get(:bucket), path: "/sitemaps"],
      sitemap_url: url(~p"/sitemaps"),
    ]
  end

  def generate_affiliate_sitemap() do
    config = get_config("affiliates")
    query =
      Ash.Query.filter(Moly.Contents.Post, post_status == :publish)
      |> Ash.Query.select([:updated_at, :post_name])
    Ash.stream!(query, actor: %{roles: [:admin]})
    |> Stream.map(fn post ->
      %Sitemapper.URL{
        loc: url(~p"/affiliate/#{post.post_name}"),
        changefreq: :daily,
        lastmod: post.updated_at
      }
    end)
    |> Sitemapper.generate(config)
    |> Sitemapper.persist(config)
    |> Stream.run()
  end

  def generate_affiliate_term_sitemap() do
    config = get_config("terms")
    query =
      Ash.Query.filter(Moly.Terms.Term, term_taxonomy.taxonomy in ["affiliate_tag", "affiliate_category"])
    Ash.stream!(query, actor: %{roles: [:admin]})
    |> Stream.map(fn term ->
      %Sitemapper.URL{
        loc: url(~p"/affiliates/#{term.slug}"),
        changefreq: :daily,
        lastmod: term.updated_at
      }
    end)
    |> Sitemapper.generate(config)
    |> Sitemapper.persist(config)
    |> Stream.run()
  end

  def generate_users_sitemap() do
    config = get_config("users")
    context = %{private: %{ash_authentication?: true}}
    query =
      Ash.Query.filter(Moly.Accounts.User, status == :active and not is_nil(confirmed_at))
      |> Ash.Query.load([:user_meta])
    Ash.stream!(query, context: context)
    |> Stream.map(fn user ->
      username = Moly.Utilities.Account.user_username(user)
      %Sitemapper.URL{
        loc: url(~p"/user/@#{username}"),
        changefreq: :daily,
        lastmod: user.updated_at
      }
    end)
    |> Sitemapper.generate(config)
    |> Sitemapper.persist(config)
    |> Stream.run()
  end

end
