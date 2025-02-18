defmodule MonorepoWeb.Affiliate.ProductBrowseLive do
  use MonorepoWeb, :live_view

  require Ash.Query

  @per_page 20

  def mount(_params, _session, socket) do
    industry_category = Monorepo.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()
    {:ok, socket, temporary_assigns: [industry_category: industry_category]}
  end

  def handle_params(unsigned_params, uri, socket) do
    socket = assign(socket, :post, get_posts(1))
    {:noreply, socket}
  end

  defp get_posts(page, industry_category_slug \\ nil) do
    offset = (page - 1) * @per_page

    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    Ash.Query.filter(Monorepo.Contents.Post, post_type == :affiliate and post_status in [:publish])
    |> Ash.Query.load([:post_tags, :post_categories, author: :user_meta, post_meta: :children])
    |> Ash.read!(opts)
    |> Map.get(:results)
  end
end
