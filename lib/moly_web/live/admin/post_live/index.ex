defmodule MolyWeb.AdminPostLive.Index do
  use MolyWeb.Admin, :live_view

  @per_page "10"
  @model Moly.Contents.Post

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.destroy!(action: :destroy_post, actor: socket.assigns.current_user)

    socket = push_patch(socket, to: ~p"/admin/posts?#{socket.assigns.params}")
    {:noreply, socket}
  end

  def handle_event("draft", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.update!(%{post_status: :draft}, actor: socket.assigns.current_user, action: :update_post_status)

    socket = push_patch(socket, to: ~p"/admin/posts?#{socket.assigns.params}")
    {:noreply, socket}
  end

  def handle_event("publish", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.update!(%{post_status: :publish}, actor: socket.assigns.current_user, action: :update_post_status)

    socket = push_patch(socket, to: ~p"/admin/posts?#{socket.assigns.params}")
    {:noreply, socket}
  end

  def handle_event("rebuild-index", %{"id" => id, "spin-id" => spin_id}, socket) do
    Moly.Contents.PostEs.build_document_index_by_id(id)

    socket =
      socket
      |> push_event("js-exec", %{to: spin_id, attr: "data-loaded"})

    :timer.sleep(500)

    {:noreply, socket}
  end

  def handle_event("delete-forever", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.Changeset.for_destroy(:destroy_forever, %{}, actor: socket.assigns.current_user)
    |> Ash.destroy!()

    socket = push_patch(socket, to: ~p"/admin/posts?#{socket.assigns.params}")
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
      |> Ash.Query.load([post_meta: [:children], term_taxonomy: :term])
      |> Ash.read!(opts)


    calc_status = [:publish, :draft, :future, :trash]

    status_count =
      Enum.reduce(calc_status, %{}, fn post_status, acc ->
        count =
          Ash.Query.filter(@model, post_status == ^post_status and post_type == :post)
          |> Ash.count!(actor: current_user)

        Map.put(acc, post_status, count)
      end)

    all_posts =
      Enum.reduce(status_count, 0, &(&2 + elem(&1, 1)))

    socket =
      socket
      |> assign(:posts, data)
      |> assign(:page_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q, post_status: post_status})
      |> assign(:status_count, Map.put(status_count, :all, all_posts))

    socket
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/posts?#{query_params}"
  end
end
