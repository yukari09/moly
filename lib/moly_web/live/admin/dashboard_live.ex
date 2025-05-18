defmodule MolyWeb.AdminDashboardLive do
  use MolyWeb.Admin, :live_view


  @impl true
  def handle_event("clean-website-cache", _unsigned_params, socket) do
    Moly.clean_website_cache()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.card>Analytics</.card>
    <div class="flex mt-4 gap-4">
      <div class="w-2/3"></div>
      <div class="w-1/3">
        <.card>
          <:header>Server</:header>
          <.link phx-click="clean-website-cache" class="text-sm">Clean Website Cache</.link>
        </.card>
      </div>
    </div>
    """
  end
end
