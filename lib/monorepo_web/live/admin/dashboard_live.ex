defmodule MonorepoWeb.AdminDashboardLive do
  use MonorepoWeb, :live_view

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: %{role: :admin, status: :active}}} = socket
      ) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/sign-in")}
  end

  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>...</div>
    """
  end
end
