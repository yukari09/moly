defmodule MolyWeb.AdminDashboardLive do
  use MolyWeb.Admin, :live_view


  @impl true
  def handle_event("clean-website-cache", _unsigned_params, socket) do
    :timer.sleep(200)
    Moly.clean_website_cache()
    {:noreply, socket}
  end

  @impl true
  def handle_event("test-email", _unsigned_params, socket) do
    :timer.sleep(200)
    email = socket.assigns.current_user.email
    url = ~p"/"
    %{deliver_type: "deliver_email_for_test", deliver_args: [email, url]}
    |> Moly.Accounts.Emails.new()
    |>  Oban.insert()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.card>Analytics</.card>
    <div class="flex mt-4 gap-4">
      <div class="w-2/3"></div>
      <div class="w-1/3 space-y-4">
        <.card header="WebSite">
          <.link phx-click={
            JS.push("clean-website-cache")
          } class="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700">
            <Lucideicons.loader_circle id="clean-website-cache-loader-circle" class="size-4 animate-spin hidden phx-click-loading:block" />
            <Lucideicons.eraser id="clean-website-cache-loader-eraser" class="size-4 block phx-click-loading:hidden" />
            Clean Website Cache
          </.link>
        </.card>

        <.card header="Services">
          <ul class="text-sm divide-y divide-gray-200">
            <li class="space-y-2">
              <%!-- <div class="font-medium flex items-center gap-2">Email</div> --%>
              <div class="text-gray-500">
                <ul class="space-y-4">
                  <li :if={is_binary(value) || is_atom(value)} class="flex items-center gap-2" :for={{key, value} <- Application.get_env(:moly, Moly.Mailer)}>
                    <span class="font-medium capitalize w-24">{key}:</span>
                    <span>{JSON.encode!(value)}</span>
                  </li>
                  <li class="flex items-center gap-2">
                    <span class="font-medium capitalize  w-24">Team Name:</span>
                    <span>{Application.get_env(:moly, :team_name)}</span>
                  </li>
                  <li class="flex items-center gap-2">
                    <span class="font-medium capitalize w-24">Support:</span>
                    <span>{Application.get_env(:moly, :support_email)}</span>
                  </li>
                  <li>
                    <.button size="xs" variant="gray" phx-click="test-email">
                      <Lucideicons.loader_circle id="clean-website-cache-loader-circle" class="size-3 animate-spin hidden phx-click-loading:block" />
                      <span class="inline phx-click-loading:hidden">Test Email</span>
                    </.button>
                  </li>
                </ul>
              </div>
            </li>
          </ul>
        </.card>
      </div>
    </div>
    """
  end
end
