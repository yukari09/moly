defmodule MolyWeb.Affinew.ListTermLive do
  use MolyWeb, :live_view

  import MolyWeb.Affinew.Components
  import MolyWeb.Affinew.QueryEs

  @per_page 18

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
    page_meta = Moly.Helper.pagination_meta(count, @per_page, page, 5)

    current_params = %{"page" => page, "sort" => sort}

    term_name = show_option_label(socket.assigns.industry_options, slug)

    keyword =
      (term_name || slug)
      |> String.replace("-", " ")
      |> String.capitalize()

    socket =
      if count == 0 do
        empty_map_params = %{
          "category" => nil, "commission" => nil, "cookie-duration"=> nil,
          "page"=>nil, "payment-cycle" => "novalue", "q" => nil, "sort" => nil
        }
        assign(socket, :canonical, ~p"/browse?#{empty_map_params}")
      else
        socket
      end

    socket =
      assign(socket,
        posts: posts,
        params: current_params,
        page_meta: page_meta,
        slug: slug,
        keyword: keyword
      )
      |> page_title()

    {:noreply, socket}
  end

  defp page_title(socket) do
    assign(socket, :page_title, "#{socket.assigns.keyword} High Ticket best Paying affiliate marketing program")
  end
end
