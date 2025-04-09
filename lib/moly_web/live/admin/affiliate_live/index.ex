defmodule MolyWeb.AdminAffiliateLive.Index do
  use MolyWeb.Admin, :live_view

  @per_page "10"
  @model Moly.Contents.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.destroy!(action: :destroy_post, actor: socket.assigns.current_user)

    socket = push_patch(socket, to: ~p"/admin/affiliates?#{socket.assigns.params}")
    {:noreply, socket}
  end

  def handle_event("publish", %{"id" => id}, socket) do
    Ash.get!(Moly.Contents.Post, id, actor: socket.assigns.current_user)
    |> Ash.update!(%{post_status: :publish},
      action: :update_post_status,
      actor: socket.assigns.current_user
    )

    socket = push_patch(socket, to: ~p"/admin/affiliates?#{socket.assigns.params}")
    {:noreply, socket}
  end

  def handle_event("rebuild-index", %{"id" => id}, socket) do
    Moly.Contents.Notifiers.Post.build_post_document(id)
    socket =
      socket
      |> push_event("exec-el", %{target: "#rebuild-index-btn-#{id}", attr: "data-show"})
      |> push_event("exec-el", %{target: "#rebuild-index-loading-#{id}", attr: "data-hide"})
      |> put_flash_info("This post has been rebuild index.")
    {:noreply, socket}
  end

  def handle_event("edit-action", %{"id" => _id}, socket) do
    socket = assign(socket, :live_action, :edit)
    {:noreply, socket}
  end

  def handle_event("modify-tag", %{"id" => id}, socket) do
    tag_form =
      Ash.Query.filter(Moly.Contents.Post, id==^id)
      |> Ash.Query.load([term_taxonomy: :term])
      |> Ash.read_first!(actor: %{roles: [:admin]})
      |> AshPhoenix.Form.for_update(:update_post, actor: socket.assigns.current_user)
      |> to_form()
    socket =
      socket
      |> assign(:live_action, :modify_tag)
      |> assign(:tag_form, tag_form)
    {:noreply, socket}
  end

  def handle_event("modify-category", %{"post-id" => post_id, "category-id" => category_id}, socket) do
    categories =
      Ash.Query.filter(Moly.Terms.TermTaxonomy, parent.slug == "industries")
      |> Ash.Query.load([:term])
      |> Ash.read!(actor: %{roles: [:user]})

    data =
      Ash.Query.filter(Moly.Terms.TermRelationships, post_id==^post_id and term_taxonomy_id==^category_id)
      |> Ash.read_first!(actor: %{roles: [:admin]})

    category_form =
      AshPhoenix.Form.for_update(data, :update_relation, actor: socket.assigns.current_user)
      |> to_form()

    socket =
      socket
      |> assign(:live_action, :modify_category)
      |> assign(:categories, categories)
      |> assign(:category_form, category_form)

    {:noreply, socket}
  end

  def handle_event("save-category", %{"form" => form} = _params, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.category_form, params: form, action_opts: [actor: socket.assigns.current_user]) do
        {:ok, _} ->
          put_flash_info(socket, "Category has been updated ,don't forget rebuild index.")
          |> push_patch(to: live_url(socket.assigns.params))
          |> assign(:live_action, :index)
        {:error, form} ->
          put_flash_info(socket, "#{form.errors}")
          |> assign(:live_action, :index)
      end
    {:noreply, socket}
  end

  @impl true
  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  def put_flash_info(socket, info) do
    Process.send_after(self(), :clear_flash, 1500)
    put_flash(socket, :info, info)
  end

  def put_flash_error(socket, error) do
    Process.send_after(self(), :clear_flash, 1500)
    put_flash(socket, :info, error)
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
      Ash.Query.filter(data, post_type == :affiliate)
      |> Ash.Query.load([:post_meta, term_taxonomy: :term])
      |> Ash.read!(opts)

    calc_status = [:publish, :pending, :trash]

    status_count =
      Enum.reduce(calc_status, %{}, fn post_status, acc ->
        count =
          Ash.Query.filter(@model, post_status == ^post_status and post_type == :affiliate)
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
      |> assign(:live_action, :index)

    socket
  end

  defp live_url(query_params) when is_map(query_params) do
    ~p"/admin/affiliates?#{query_params}"
  end
end
