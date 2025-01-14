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

    post_status =
      Map.get(params, "post_status", "")

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
        |> Ash.Query.filter(expr(contains(post_title, ^q)))
      end

    data =
      if post_status in [nil, ""] do
        data
      else
        Ash.Query.filter(data, post_status == ^post_status)
      end

    data =
      Ash.Query.filter(data, post_type == :post)
      |> Ash.read!(opts)
      |> Ash.load!([:post_meta])

    calc_status = [:publish, :draft, :future, :trash]

    status_count =
      Enum.reduce(calc_status, %{}, fn post_status, acc ->
        count =
          Ash.Query.filter(@model, post_status == ^post_status)
          |> Ash.count!([actor: current_user])
        Map.put(acc, post_status, count)
      end)

    all_posts =
      Ash.Query.filter(@model, post_status in ^calc_status)
      |> Ash.count!([actor: current_user])

    socket =
      socket
      |> assign(:posts, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q, post_status: post_status})
      |> assign(:status_count, status_count)

    socket
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/posts?#{query_params}"
  end
end
