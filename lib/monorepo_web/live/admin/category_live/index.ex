defmodule MonorepoWeb.AdminCategoryLive.Index do
  use MonorepoWeb.Admin, :live_view

  @per_page "10"
  @model Monorepo.Terms.Term

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_event("search", %{"q" => _} = params, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  # @impl true
  # def handle_event("delete", %{"id" => id}, socket) do
  #   Ash.get!(@model, id, actor: socket.assigns.current_user)
  #   |> Ash.destroy!(action: :destroy_post, actor: socket.assigns.current_user)

  #   socket = push_patch(socket, to: live_url(socket.assigns.params))
  #   {:noreply, socket}
  # end

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
      |> Ash.Query.filter(term_taxonomy.taxonomy=="category")
      |> Ash.Query.load([:term_taxonomy])

    query =
      if is_nil(q) do
        query
      else
        query
        |> Ash.Query.filter(expr(contains(name, ^q)))
      end

    data = Ash.read!(query, opts)

    socket =
      socket
      |> assign(:categories, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/categories?#{query_params}"
  end
end
