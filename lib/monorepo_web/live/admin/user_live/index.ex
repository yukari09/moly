defmodule MonorepoWeb.UserLive.Index do
  use MonorepoWeb, :live_view

  require Ash.Query

  import Monorepo.Helper
  import Ash.Expr



  @per_page "10"
  @context  %{private: %{ash_authentication?: true}}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-between items-end mt-4">
      <%!-- <.button variant="outline" phx-click="new" class="flex items-center gap-1">
        <Lucideicons.plus class="w-4 h-4" /> Add User
      </.button> --%>
      <span class="text-sm text-muted-foreground">
        &nbsp;
      </span>
      <.form :let={f} for={%{}} phx-change="search" phx-throttle="500">
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
              JS.toggle_class("text-muted-foreground", to: "#user-luci-sear")
            }
            phx-blur={
              JS.toggle_class("text-muted-foreground", to: "#user-luci-sear")
            }
          />
          <Lucideicons.search id="user-luci-sear" class="w-4 h-4 absolute top-1/2 right-2 transform -translate-y-1/2 !mt-0 text-muted-foreground" />
        </.form_item>
      </.form>
    </div>

    <.table class="border">
      <.table_header>
      <.table_row>
        <.table_head class="w-[100px]">Avatar</.table_head>
        <.table_head>Email</.table_head>
        <.table_head>Role</.table_head>
        <.table_head>ConfirmedAt</.table_head>
        <.table_head>InsertedAt</.table_head>
        <.table_head class="text-right">Action</.table_head>
      </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={user <- @users.results} id={user.id}>
          <.table_cell>
            <div class="flex">
              <.avatar>
                <.avatar_image :if={user.profile} src={user.profile.avatar_url} />
                <.avatar_fallback class="bg-primary text-white">
                  {user.email |> to_string() |> String.slice(0, 2) |> String.upcase()}
                </.avatar_fallback>
              </.avatar>
            </div>
          </.table_cell>
          <.table_cell class="font-medium">{user.email}</.table_cell>
          <.table_cell>{user.role}</.table_cell>
          <.table_cell>{user.confirmed_at && Timex.format!(user.confirmed_at, "{h24}:{m} {Mshort} {D}, {YYYY}")}</.table_cell>
          <.table_cell>{user.inserted_at && Timex.format!(user.inserted_at, "{h24}:{m} {Mshort} {D}, {YYYY}")}</.table_cell>
          <.table_cell class="text-right">...</.table_cell>
        </.table_row>
      </.table_body>
    </.table>

    <div class="flex items-center justify-between px-1 mb-8">
      <div class="text-sm text-muted-foreground">
        Showing {@pagination_meta.start_row} to {@pagination_meta.end_row} of {@pagination_meta.total} entries
      </div>
      <div>
        <.pagination>
          <.pagination_content>
            <.pagination_item :if={@pagination_meta.prev}>
              <.pagination_previous patch={~p"/admin/users?#{%{@params | page: @pagination_meta.prev}}"} />
            </.pagination_item>
            <.pagination_item :for={page <- @pagination_meta.page_range}>
              <.pagination_link
                is-active={page == @pagination_meta.current_page}
                patch={~p"/admin/users?#{%{@params | page: page}}"}
              >{page}</.pagination_link>
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.ellipsis}>
              <.pagination_ellipsis />
            </.pagination_item>
            <.pagination_item :if={@pagination_meta.next}>
              <.pagination_next patch={~p"/admin/users?#{%{@params | page: @pagination_meta.next}}"}  />
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
    {:noreply, get_list_by_params(socket, params)}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, get_list_by_params(socket, %{"q" => q})}
  end


  defp get_list_by_params(socket, params) do
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
      context: @context,
      actor: %{roles: [socket.assigns.current_user.role]},
      page: [limit: limit, offset: offset, count: true]
    ]

    data = Monorepo.Accounts.User
    data = if is_nil(q) do
      data
    else
      data
      |> Ash.Query.filter(expr(contains(email, ^q)))
    end

    data =
      data
      |> Ash.read!(opts)
      |> Ash.load!([:profile])

    socket =
      socket
      |> assign(:users, data)
      |> assign(:pagination_meta, pagination_meta(data.count, per_page, page, 9))
      |> assign(:params, %{page: page, per_page: per_page, q: q})

    socket
  end


end
