defmodule Moly.Contents.Workers.Sitemap do
  use Oban.Worker, queue: :periodic, max_attempts: 10

  use MolyWeb, :verified_routes

  require Ash.Query

  @impl true
  def perform(_args) do
    generate_sitemap()
  end

  defp get_config(name) do
    [
      name: name,
      store: Sitemapper.S3Store,
      store_config: [bucket: Application.get_env(:ex_aws, :s3) |> Keyword.get(:bucket), path: "/sitemaps"],
      sitemap_url: url(~p"/sitemaps"),
    ]
  end

  def generate_sitemap() do
    config = get_config("posts")
    query =
      Ash.Query.filter(Moly.Contents.Post, post_status == :publish and post_type == :post)
      |> Ash.Query.select([:updated_at, :post_name])
    Ash.stream!(query, actor: %{roles: [:user]})
    |> Stream.map(fn post ->
      %Sitemapper.URL{
        loc: url(~p"/.#{post.post_name}"),
        changefreq: :daily,
        lastmod: post.updated_at
      }
    end)
    |> Sitemapper.generate(config)
    |> Sitemapper.persist(config)
    |> Stream.run()
  end

end
