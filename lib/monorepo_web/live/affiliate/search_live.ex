defmodule MonorepoWeb.Affiliate.SearchLive do
  use MonorepoWeb, :live_view

  import Ash.Expr

  require Ash.Query

  @per_page 20

  def handle_params(%{"q" => q} = params, _uri, socket)
      when is_binary(q) and q not in [nil, "", false] do
    page_title = "Search #{q} affiliate marketing program results"

    socket =
      assign(socket, page_title: page_title)
      |> get_posts(params)

    {:noreply, socket}
  end

  defp get_posts(socket, params) do
    page = params["page"] || "1"
    page = String.to_integer(page)
    offset = (page - 1) * @per_page

    q = params["q"]

    opts = [
      action: :complex_search,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    query_result =
      Ash.Query.filter(
        Monorepo.Contents.Post,
        post_type == :affiliate and post_status in [:publish]
      )
      |> Ash.Query.set_argument(:search_text, q)
      |> Ash.Query.load([
        :affiliate_tags,
        :affiliate_categories,
        author: :user_meta,
        post_meta: :children
      ])
      |> Ash.read!(opts)

    page_meta = Monorepo.Helper.pagination_meta(query_result.count, @per_page, page, 8)

    socket =
      assign(socket,
        q: q,
        post: query_result.results,
        page_meta: page_meta,
        params: %{page: page, q: q}
      )

    socket
  end

  defp live_url(params) do
    ~p"/search?#{params}"
  end
end
