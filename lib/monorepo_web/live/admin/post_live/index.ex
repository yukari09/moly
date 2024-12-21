defmodule MonorepoWeb.PostLive.Index do
  use MonorepoWeb, :live_view

  require Ash.Query

  import Monorepo.Helper
  import Ash.Expr

  @model Monorepo.Contents.Post
  @per_page "10"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-end mt-4">
      <.button
        variant="outline"
        phx-click={JS.patch(~p"/admin/posts/new")}
        class="flex items-center gap-1"
      >
        <Lucideicons.plus class="w-4 h-4" />Add New
      </.button>

      <.form :let={f} for={%{}} phx-change="search" phx-submit="search" phx-throttle="500">
        <% f = %{f | data: @params} %>
        <.form_item class="relative">
          <.input
            field={f[:q]}
            type="text"
            placeholder="Search..."
            phx-debounce="500"
            autocomplete="off"
            class="!pr-6"
            phx-focus={
              JS.toggle_class("text-muted-foreground", to: "#icon-luci-sear")
            }
            phx-blur={
              JS.toggle_class("text-muted-foreground", to: "#icon-luci-sear")
            }
          />
          <Lucideicons.search id="icon-luci-sear" class="w-4 h-4 absolute top-1/2 right-2 transform -translate-y-1/2 !mt-0 text-muted-foreground" />
        </.form_item>
      </.form>
    </div>

    <.table class="border">
      <.table_header>
      <.table_row>
        <.table_head class="min-w-min">Title</.table_head>
        <.table_head>Author</.table_head>
        <.table_head>Published</.table_head>
        <.table_head>Comments</.table_head>
        <.table_head>InsertedAt</.table_head>
        <.table_head class="text-right">Action</.table_head>
      </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={post <- @posts.results} id={post.id}>
          <.table_cell class="font-medium">{post.title}</.table_cell>
          <.table_cell>{Monorepo.Accounts.Helper.get_user_name(post.user)}</.table_cell>
          <.table_cell>
            <.badge variant={post.published && "published" || "draft"}>
              {post.is_deleted && "published" || "draft"}
            </.badge>
          </.table_cell>
          <.table_cell>
            0
          </.table_cell>
          <.table_cell>
            {post.inserted_at && Timex.format!(post.inserted_at, "{h24}:{m} {Mshort} {D}, {YYYY}")}
          </.table_cell>
          <.table_cell class="text-right">
            <.dropdown_menu>
              <.dropdown_menu_trigger>
                <Lucideicons.ellipsis_vertical class="w-4 h-4 text-muted-foreground" />
              </.dropdown_menu_trigger>
              <.dropdown_menu_content align="end">
                <.menu class="w-[160px]">
                  <.menu_label class="text-left">Actions</.menu_label>
                  <.menu_separator />
                  <.menu_item  phx-click="edit" phx-value-id={post.id} class="flex items-center gap-2">
                    <Lucideicons.pencil class="w-4 h-4 text-muted-foreground" />
                    Edit
                  </.menu_item>
                  <.menu_item :if={not post.is_deleted} phx-click="delete" phx-value-id={post.id} class="flex items-center gap-2">
                    <Lucideicons.trash class="w-4 h-4 text-muted-foreground" />
                    Trash
                  </.menu_item>
                  <.menu_item :if={post.is_deleted} phx-click="restore" phx-value-id={post.id} class="flex items-center gap-2">
                    <Lucideicons.rotate_cw class="w-4 h-4 text-muted-foreground" />
                    Restore
                  </.menu_item>
                  <.menu_item :if={post.is_deleted} phx-click="destroy_forever" phx-value-id={post.id}  class="flex items-center gap-2">
                    <Lucideicons.circle_alert class="w-4 h-4 text-muted-foreground" />
                    Destroy forever
                  </.menu_item>
                </.menu>
              </.dropdown_menu_content>
            </.dropdown_menu>
          </.table_cell>
        </.table_row>
      </.table_body>
    </.table>

    <div class="flex items-center justify-between px-1 mb-12">
      <div class="text-sm text-muted-foreground">
        Showing {@pagination_meta.start_row} to {@pagination_meta.end_row} of {@pagination_meta.total} entries
      </div>
      <div :if={@pagination_meta.total_pages > 1}>
        <.pagination>
          <.pagination_content>
            <.pagination_item :if={@pagination_meta.prev}>
              <.pagination_previous patch={~p"/admin/posts?#{%{@params | page: @pagination_meta.prev}}"} />
            </.pagination_item>
            <.pagination_item :for={page <- @pagination_meta.page_range}>
              <.pagination_link
                is-active={page == @pagination_meta.current_page}
                patch={~p"/admin/posts?#{%{@params | page: page}}"}
              >{page}</.pagination_link>
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.ellipsis}>
              <.pagination_ellipsis />
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.next}>
              <.pagination_next patch={~p"/admin/posts?#{%{@params | page: @pagination_meta.next}}"}  />
            </.pagination_item>
          </.pagination_content>
        </.pagination>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %{role: :admin, status: :active}}} = socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/sign-in")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event(event, params, socket) do
    live_action = String.to_atom(event)
    {:noreply, apply_action(socket, live_action, params)}
  end


  defp apply_action(socket, :edit, %{"id" => id}) do
    resource = Ash.get!(@model, id, actor: %{roles: [socket.assigns.current_user.role]})

    form =
      AshPhoenix.Form.for_update(resource, :update, forms: [auto?: true])
      |> to_form()

    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:form, form)
    |> assign(:live_action, :edit)
  end

  defp apply_action(socket, :new, _params) do
    form =
      @model
      |> AshPhoenix.Form.for_create(:create, forms: [auto?: true])
      |> to_form()
    socket
    |> assign(:page_title, "New Post")
    |> assign(:form, form)
    |> assign(:live_action, :new)
  end

  defp apply_action(socket, :index, params) do
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
      actor: %{roles: [socket.assigns.current_user.role]},
      page: [limit: limit, offset: offset, count: true]
    ]

    query =
      if is_nil(q) do
        @model
      else
        Ash.Query.filter(@model, expr(contains(category_name, ^q)))
      end

    data =
      query
      |> Ash.read!(opts)

    socket
    |> assign(:posts, data)
    |> assign(:pagination_meta, pagination_meta(data.count, per_page, page, 9))
    |> assign(:params, %{page: page, per_page: per_page, q: q})
    |> assign(:page_title, "Listing Post")
  end

  defp apply_action(socket, :validate, %{"form" => params}) do
    socket
    |> assign(form: AshPhoenix.Form.validate(socket.assigns.form, params))
  end

  defp apply_action(socket, :save, %{"form" => params}) do
    case AshPhoenix.Form.submit(
      socket.assigns.form,
      params: params,
      action_opts: [actor: %{roles: [socket.assigns.current_user.role]}]
    ) do
      {:ok, post} ->
         socket
         |> put_flash(:info, "Saved post for #{post.title}!")
         |> push_navigate(to: ~p"/admin/posts?#{%{socket.assigns.params | page: 1}}", replace: true)
         |> assign(:live_action, :index)

      {:error, form} ->
        socket
        |> assign(form: form)
    end
  end

  defp apply_action(socket, :search, %{"q" => q} = _params) do
    apply_action(socket, :index, %{"q" => q})
  end

  defp apply_action(socket, :delete, %{"id" => id}) do
    Ash.get!(@model, id, actor: %{roles: [socket.assigns.current_user.role]})
    |> Ash.update!(%{is_deleted: true}, action: :is_deleted, actor: %{roles: [socket.assigns.current_user.role]})

    socket
    |> push_navigate(to: ~p"/admin/posts?#{socket.assigns.params}")
  end

  defp apply_action(socket, :restore, %{"id" => id}) do
    Ash.get!(@model, id, actor: %{roles: [socket.assigns.current_user.role]})
    |> Ash.update!(%{is_deleted: false}, action: :is_deleted, actor: %{roles: [socket.assigns.current_user.role]})

    socket
    |> push_navigate(to: ~p"/admin/posts?#{socket.assigns.params}")
  end

  defp apply_action(socket, :destroy_forever, %{"id" => id}) do
    Ash.get!(@model, id, actor: %{roles: [socket.assigns.current_user.role]})
    |> Ash.destroy!(action: :destroy_forever, actor: %{roles: [socket.assigns.current_user.role]})

    socket
    |> push_navigate(to: ~p"/admin/posts?#{socket.assigns.params}")
  end




end
