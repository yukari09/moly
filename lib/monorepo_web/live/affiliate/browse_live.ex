defmodule MonorepoWeb.Affiliate.BrowseLive do
  use MonorepoWeb, :live_view

  require Ash.Query
  require Logger

  @per_page 20

  def mount(_params, _session, socket) do
    affiliate_industries_key = "aviable_affiliate_industries"
    affiliate_industries =
      Monorepo.Utilities.cache_get_or_put(affiliate_industries_key, fn ->
        Monorepo.Utilities.Affiliate.affiliate_industries()
        |> Enum.filter(fn term ->
          if !is_list(term.term_taxonomy) do
            false
          else
            Enum.reduce_while(term.term_taxonomy, false, fn %{count: count}, _ ->
              if count > 0, do: {:halt, true}, else: {:cont, false}
            end)
          end
        end)
      end, :timer.hours(1))
    {:ok, socket, temporary_assigns: [affiliate_industries: affiliate_industries, page_title: "Find website software high ticket best paying affiliate marketing programs for beginners experts."]}
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

    fetch_cache_function = fn ->
      query =
        Ash.Query.filter(
          Monorepo.Contents.Post,
          post_type == :affiliate and post_status in [:publish]
        )
        |> Ash.Query.sort(commission_avg: :desc, inserted_at: :desc)

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


      {query_result, page_meta}
    end

    {query_result, page_meta} = Monorepo.Utilities.cache_get_or_put("affiliate.browse.#{slug}.#{page}", fetch_cache_function, :timer.hours(1))


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
