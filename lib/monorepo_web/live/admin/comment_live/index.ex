defmodule MonorepoWeb.AdminCommentLive.Index do
  use MonorepoWeb.Admin, :live_view

  @per_page "10"
  @model Monorepo.Comments.Comment

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
    }
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket = get_list_by_params(socket, params)
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => q} = _params, socket) do
    socket = socket |> push_patch(to: live_url(%{page: 1, q: q}))
    {:noreply, socket}
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

    query =
      @model
      |> Ash.Query.filter(comment_type=="comment")
      |> Ash.Query.load([:comment_author])

    query =
      if is_nil(q) do
        query
      else
        query
        |> Ash.Query.filter(expr(contains(comment_content, ^q)))
      end

    data = Ash.read!(query, opts)

    socket =
      socket
      |> assign(:comments, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/comments?#{query_params}"
  end

end
