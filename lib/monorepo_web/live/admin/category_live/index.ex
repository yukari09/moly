defmodule MonorepoWeb.CategoryLive.Index do
  use MonorepoWeb, :live_view

  require Ash.Query

  import Monorepo.Helper
  import Ash.Expr

  @model Monorepo.Categories.Category
  @per_page "10"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-end mt-4">
      <.button
        variant="outline"
        phx-click="new"
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
        <.table_head class="min-w-min">Name</.table_head>
        <.table_head>Status</.table_head>
        <.table_head>Posts</.table_head>
        <.table_head>InsertedAt</.table_head>
        <.table_head class="text-right">Action</.table_head>
      </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={category <- @categories.results} id={category.id}>
          <.table_cell class="font-medium">{category.category_name}</.table_cell>
          <.table_cell>
            <.badge variant={category.is_deleted && "destructive" || "default"}>
              {category.is_deleted && "Deleted" || "Active"}
            </.badge>
          </.table_cell>
          <.table_cell>
            {category.count_of_posts}
          </.table_cell>
          <.table_cell>
            {category.inserted_at && Timex.format!(category.inserted_at, "{h24}:{m} {Mshort} {D}, {YYYY}")}
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
                  <.menu_item  phx-click="edit" phx-value-id={category.id} class="flex items-center gap-2">
                    <Lucideicons.pencil class="w-4 h-4 text-muted-foreground" />
                    Edit
                  </.menu_item>
                  <.menu_item :if={not category.is_deleted} phx-click="delete" phx-value-id={category.id} class="flex items-center gap-2">
                    <Lucideicons.trash class="w-4 h-4 text-muted-foreground" />
                    Trash
                  </.menu_item>
                  <.menu_item :if={category.is_deleted} phx-click="restore" phx-value-id={category.id} class="flex items-center gap-2">
                    <Lucideicons.rotate_cw class="w-4 h-4 text-muted-foreground" />
                    Restore
                  </.menu_item>
                  <.menu_item :if={category.is_deleted} phx-click="destroy_forever" phx-value-id={category.id}  class="flex items-center gap-2">
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
              <.pagination_previous patch={~p"/admin/categories?#{%{@params | page: @pagination_meta.prev}}"} />
            </.pagination_item>
            <.pagination_item :for={page <- @pagination_meta.page_range}>
              <.pagination_link
                is-active={page == @pagination_meta.current_page}
                patch={~p"/admin/categories?#{%{@params | page: page}}"}
              >{page}</.pagination_link>
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.ellipsis}>
              <.pagination_ellipsis />
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.next}>
              <.pagination_next patch={~p"/admin/categories?#{%{@params | page: @pagination_meta.next}}"}  />
            </.pagination_item>
          </.pagination_content>
        </.pagination>
      </div>
    </div>

    <.dialog
      id="bc-modal"
      :if={@live_action in [:new, :edit]}
      on_cancel={JS.patch(~p"/admin/categories?#{@params}")}
      class="w-[500px]"
      show
    >
      <.dialog_header>
        <.dialog_title>Add new category</.dialog_title>
        <.dialog_description>
          Make changes to category here click save when you're done
        </.dialog_description>
      </.dialog_header>
        <.form for={@form} :let={f} class="space-y-6 mt-2" phx-submit="save" phx-change="validate">
          <.form_item calss="space-y-2">
            <.form_label error={not Enum.empty?(f[:category_name].errors)}>Category Name</.form_label>
            <.input
              id={f[:category_name].id}
              field={f[:category_name]}
              type="text"
              class="w-full"
              placeholder="Category Name"
              phx-debounce="500"
              value={f[:category_name].value}
              required />
            <.form_description class="text-xs text-muted-foreground">
              The blog category name.
            </.form_description>
            <.form_message field={f[:category_name]} class="text-xs" />
          </.form_item>
          <.dialog_footer>
            <.button type="submit" phx-disable-with="Saving..." disabled={not Enum.empty?(f[:category_name].errors)}>Save</.button>
          </.dialog_footer>
        </.form>
    </.dialog>
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
    |> assign(:page_title, "Edit Category")
    |> assign(:form, form)
    |> assign(:live_action, :edit)
  end

  defp apply_action(socket, :new, _params) do
    form =
      @model
      |> AshPhoenix.Form.for_create(:create, forms: [auto?: true])
      |> to_form()
    socket
    |> assign(:page_title, "New Category")
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
      |> Ash.load!([:count_of_posts])

    socket
    |> assign(:categories, data)
    |> assign(:pagination_meta, pagination_meta(data.count, per_page, page, 9))
    |> assign(:params, %{page: page, per_page: per_page, q: q})
    |> assign(:page_title, "Listing Category")
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
      {:ok, category} ->
         socket
         |> put_flash(:info, "Saved category for #{category.category_name}!")
         |> push_navigate(to: ~p"/admin/categories?#{%{socket.assigns.params | page: 1}}", replace: true)
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
    |> push_navigate(to: ~p"/admin/categories?#{socket.assigns.params}")
  end

  defp apply_action(socket, :restore, %{"id" => id}) do
    Ash.get!(@model, id, actor: %{roles: [socket.assigns.current_user.role]})
    |> Ash.update!(%{is_deleted: false}, action: :is_deleted, actor: %{roles: [socket.assigns.current_user.role]})

    socket
    |> push_navigate(to: ~p"/admin/categories?#{socket.assigns.params}")
  end

  defp apply_action(socket, :destroy_forever, %{"id" => id}) do
    Ash.get!(@model, id, actor: %{roles: [socket.assigns.current_user.role]})
    |> Ash.destroy!(action: :destroy_forever, actor: %{roles: [socket.assigns.current_user.role]})

    socket
    |> push_navigate(to: ~p"/admin/categories?#{socket.assigns.params}")
  end



end
