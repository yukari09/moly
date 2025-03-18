defmodule MolyWeb.Affiliate.AffiliatesLive do
  use MolyWeb, :live_view

  require Ash.Query

  @per_page 20

  def handle_params(params, _uri, socket) do
    term =
      Moly.Terms.read_by_term_slug!(params["slug"], actor: %{roles: [:user]})
      |> List.first()

    page_title =
      "Best highest paying #{term.name} affiliate marketing programs in #{Timex.now() |> Timex.format!("{YYYY}")}"

    socket =
      assign(socket, term: term, page_title: page_title)
      |> get_posts(params)

    {:noreply, socket}
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

    cache_function = fn ->
      query =
        Ash.Query.filter(
          Moly.Contents.Post,
          post_type == :affiliate and post_status in [:publish]
        )
        |> Ash.Query.sort(inserted_at: :desc)

      query =
        if slug do
          Ash.Query.filter(query, term_taxonomy.term.slug == ^slug)
        else
          query
        end

      query_result =
        Ash.Query.load(query, [
          :affiliate_tags,
          :affiliate_categories,
          author: :user_meta,
          post_meta: :children
        ])
        |> Ash.read!(opts)

      page_meta = Moly.Helper.pagination_meta(query_result.count, @per_page, page, 8)

      {query_result, page_meta}
    end

    {query_result, page_meta} =
      Moly.Utilities.cache_get_or_put(
        "affiliate.category.#{slug}.#{page}",
        cache_function,
        :timer.hours(1)
      )

    socket =
      assign(socket,
        post: query_result.results,
        page_meta: page_meta,
        params: %{page: page, slug: slug}
      )

    socket
  end

  defp live_url(params) do
    ~p"/affiliates?#{params}"
  end
end
