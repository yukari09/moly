defmodule MonorepoWeb.UserLive.Index do
  use MonorepoWeb, :live_view

  @context  %{private: %{ash_authentication?: true}}

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Users
      <:actions>
        <.link patch={~p"/users/new"}>
          <.button>New User</.button>
        </.link>
      </:actions>
    </.header>

    <.table>
      <.table_header>
      <.table_row>
        <.table_head class="w-[100px]">&nbsp;</.table_head>
        <.table_head>Email</.table_head>
        <.table_head>ConfirmedAt</.table_head>
        <.table_head class="text-right">Action</.table_head>
      </.table_row>
      </.table_header>
      <.table_body>
        <.table_row :for={{id, row} <- @streams.users} id={id}>
          <.table_cell>
            <div class="flex">
              <.avatar>
                <.avatar_image src="https://github.com/shadcn.png" />
                <.avatar_fallback class="bg-primary text-white">CN</.avatar_fallback>
              </.avatar>
            </div>
          </.table_cell>
          <.table_cell>{row.email}</.table_cell>
          <.table_cell>{row.confirmed_at}</.table_cell>
          <.table_cell class="text-right">{row.profile}</.table_cell>
        </.table_row>
      </.table_body>
    </.table>


    """
  end

  @impl true
  def mount(_params, _session, socket) do
    data =
      Ash.read!(Monorepo.Accounts.User, context: @context)
      |> Ash.load!([:profile])

    {:ok,
     socket
     |> stream(:users, data)
     |> assign_new(:current_user, fn -> nil end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Ash.get!(Monorepo.Accounts.User, id, actor: socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({MonorepoWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    {:noreply, stream_insert(socket, :users, user)}
  end
end
