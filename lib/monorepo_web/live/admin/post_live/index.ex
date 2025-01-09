defmodule MonorepoWeb.AdminPostLive.Index do
  use MonorepoWeb.Admin, :live_view

  @per_page "10"
  @model Monorepo.Contents.Post

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end




  defp get_list_by_params(socket, params) do
    current_user = socket.assigns.current_user

    page =
      Map.get(params, "page", "1")
      |> String.to_integer()

    per_page =
      Map.get(params, "per_page", @per_page)
      |> String.to_integer()

    q =
      Map.get(params, "q", "")
      |> case do
        "" -> nil
        q -> q
      end

    limit = per_page
    offset = (page - 1) * per_page

    opts = [
      actor: current_user,
      page: [limit: limit, offset: offset, count: true]
    ]

    data =
      if is_nil(q) do
        @model
      else
        @model
        |> Ash.Query.filter(expr(contains(email, ^q)))
      end

    data = Ash.Query.filter(data, post_type == :post)

    data =
      data
      |> Ash.read!(opts)
      |> Ash.load!([:post_meta])

    socket =
      socket
      |> assign(:posts, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end

  defp generate_live_url(query_params) when is_map(query_params) do
    ~p"/admin/posts?#{query_params}"
  end
end
