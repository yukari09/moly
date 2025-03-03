defmodule MonorepoWeb.Affiliate.BrowseLive do
  use MonorepoWeb, :live_view

  require Ash.Query

  @per_page 20

  def mount(_params, _session, socket) do
    industry_category =
      Monorepo.Terms.read_by_term_slug!("industries", actor: %{roles: [:user]}) |> List.first()

    {:ok, socket, temporary_assigns: [industry_category: industry_category]}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, get_posts(socket, params)}
  end

  defp get_posts(socket, params) do
    page = params["page"] || "1"
    page = String.to_integer(page)
    offset = (page - 1) * @per_page

    slug = params["slug"]

    opts = [
      action: :read,
      actor: %{roles: [:user]},
      page: [limit: @per_page, offset: offset, count: true]
    ]

    query =
      Ash.Query.filter(
        Monorepo.Contents.Post,
        post_type == :affiliate and post_status in [:publish]
      )
      |> Ash.Query.sort([post_meta:  [meta_value: :desc]])

    query =
      if slug do
        Ash.Query.filter(query, term_taxonomy.term.slug == ^slug)
      else
        query
      end

    query_result =
      Ash.Query.load(query, [:affiliate_tags, :affiliate_categories, author: :user_meta, post_meta: :children])
      |> Ash.read!(opts)


    page_meta = Monorepo.Helper.pagination_meta(query_result.count, @per_page, page, 8)
    socket = assign(socket, post: query_result.results, page_meta: page_meta, params: %{page: page, slug: slug})

    socket
  end


  defp live_url(params) do
    url = ~p"/browse"
    url = if params[:slug] do
      "#{url}/#{params[:slug]}"
    else
      url
    end
    url = if params[:page] do
      "#{url}?page=#{params[:page]}"
    else
      url
    end
    url
  end
end
