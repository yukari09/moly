defmodule MonorepoWeb.UserLive.Show do
  use MonorepoWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      User {@user.id}
      <:subtitle>This is a user record from your database.</:subtitle>

      <:actions>
        <.link patch={~p"/users/#{@user}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit user</.button>
        </.link>
      </:actions>
    </.header>


    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, Ash.get!(Monorepo.Accounts.User, id, actor: socket.assigns.current_user))}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
