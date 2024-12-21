defmodule MonorepoWeb.TagLive.Index do
  use MonorepoWeb, :live_view

  require Ash.Query

  import Monorepo.Helper
  import Ash.Expr

  @model Monorepo.Tags.Tag
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
        <.table_head>Posts</.table_head>
        <.table_head>InsertedAt</.table_head>
      </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={tag <- @categories.results} id={tag.id}>
          <.table_cell class="font-medium">{tag.tag_name}</.table_cell>
          <.table_cell>
            {tag.count_of_posts}
          </.table_cell>
          <.table_cell>
            {tag.inserted_at && Timex.format!(tag.inserted_at, "{h24}:{m} {Mshort} {D}, {YYYY}")}
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
              <.pagination_previous patch={~p"/admin/tags?#{%{@params | page: @pagination_meta.prev}}"} />
            </.pagination_item>
            <.pagination_item :for={page <- @pagination_meta.page_range}>
              <.pagination_link
                is-active={page == @pagination_meta.current_page}
                patch={~p"/admin/tags?#{%{@params | page: page}}"}
              >{page}</.pagination_link>
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.ellipsis}>
              <.pagination_ellipsis />
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.next}>
              <.pagination_next patch={~p"/admin/tags?#{%{@params | page: @pagination_meta.next}}"}  />
            </.pagination_item>
          </.pagination_content>
        </.pagination>
      </div>
    </div>

    <.dialog
      id="bc-modal"
      :if={@live_action in [:new, :edit]}
      on_cancel={JS.patch(~p"/admin/tags?#{@params}")}
      class="w-[500px]"
      show
    >
      <.dialog_header>
        <.dialog_title>Add new Tag</.dialog_title>
        <.dialog_description>
          Make changes to Tag here click save when you're done
        </.dialog_description>
      </.dialog_header>
        <.form for={@form} :let={f} class="space-y-6 mt-2" phx-submit="save" phx-change="validate">
          <.form_item calss="space-y-2">
            <.form_label error={not Enum.empty?(f[:tag_name].errors)}>Tag Name</.form_label>
            <.input
              id={f[:tag_name].id}
              field={f[:tag_name]}
              type="text"
              class="w-full"
              placeholder="Tag Name"
              phx-debounce="500"
              value={f[:tag_name].value}
              required />
            <.form_description class="text-xs text-muted-foreground">
              The blog Tag name.
            </.form_description>
            <.form_message field={f[:tag_name]} class="text-xs" />
          </.form_item>
          <.dialog_footer>
            <.button type="submit" phx-disable-with="Saving..." disabled={not Enum.empty?(f[:tag_name].errors)}>Save</.button>
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
    |> assign(:page_title, "Edit Tag")
    |> assign(:form, form)
    |> assign(:live_action, :edit)
  end

  defp apply_action(socket, :new, _params) do
    form =
      @model
      |> AshPhoenix.Form.for_create(:create, forms: [auto?: true])
      |> to_form()
    socket
    |> assign(:page_title, "New Tag")
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
        Ash.Query.filter(@model, expr(contains(tag_name, ^q)))
      end

    data =
      query
      |> Ash.read!(opts)
      |> Ash.load!([:count_of_posts])

    socket
    |> assign(:categories, data)
    |> assign(:pagination_meta, pagination_meta(data.count, per_page, page, 9))
    |> assign(:params, %{page: page, per_page: per_page, q: q})
    |> assign(:page_title, "Listing Tag")
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
      {:ok, tag} ->
         socket
         |> put_flash(:info, "Saved Tag for #{tag.tag_name}!")
         |> push_navigate(to: ~p"/admin/tags?#{%{socket.assigns.params | page: 1}}", replace: true)
         |> assign(:live_action, :index)

      {:error, form} ->
        socket
        |> assign(form: form)
    end
  end

  defp apply_action(socket, :search, %{"q" => q} = _params) do
    apply_action(socket, :index, %{"q" => q})
  end







end
