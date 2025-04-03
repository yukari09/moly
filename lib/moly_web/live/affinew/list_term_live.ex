defmodule MolyWeb.Affinew.ListTermLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components
  import MolyWeb.Affinew.QueryEs

  @per_page 12

  def mount(_params, _session, socket) do
    industry_options =
      Moly.Utilities.cache_get_or_put("#{__MODULE__}:industries", &industries/0, :timer.hours(1))
      |> Enum.map(&{&1.term.slug, &1.term.name})

    socket =
      assign(
        socket,
        industry_options: industry_options,
        sort_options: sort_options()
      )

    {:ok, socket, layout: {MolyWeb.Layouts, :affinew}}
  end

  def handle_params(%{"slug" => slug} = params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    sort = Map.get(params, "sort", "created_at_desc")

    {count, posts} = MolyWeb.Affinew.QueryEs.list_query_by_category(slug, sort, page, @per_page)
    page_meta = Moly.Helper.pagination_meta(count, @per_page, page, 8)

    current_params = %{"page" => page, "sort" => sort}

    socket =
      assign(socket, posts: posts, params: current_params, page_meta: page_meta, slug: slug)

    {:noreply, socket}
  end


end
