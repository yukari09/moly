defmodule MonorepoWeb.Affiliate.PageIndexAlert do
  use MonorepoWeb, :live_component

  def update(assigns, socket) do
    socket =
      assign(socket,
        id: assigns.id,
        current_user: assigns.current_user,
        email_alread_send: already_send?(assigns.current_user)
      )

    {:ok, socket}
  end

  def handle_event("resend_email", _, socket) do
    socket =
      case already_send?(socket.assigns.current_user) do
        nil ->
          send(socket.assigns.current_user)

          socket
          |> assign(:email_alread_send, already_send?(socket.assigns.current_user))

        _ ->
          socket
      end

    {:noreply, socket}
  end

  defp already_send?(nil), do: nil

  defp already_send?(%Monorepo.Accounts.User{id: user_id}),
    do: Cachex.get!(:cache, cache_id(user_id))

  defp cache_id(user_id), do: "resend-email-#{user_id}"

  defp send(%Monorepo.Accounts.User{id: user_id} = user) do
    Ash.update(user, %{updated_at: DateTime.utc_now()},
      action: :resend_confirmation,
      context: %{private: %{ash_authentication?: true}}
    )
    |> case do
      {:ok, _user} ->
        Cachex.put(:cache, cache_id(user_id), 1, expire: :timer.hours(24))

      error ->
        error
    end
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div :if={!@email_alread_send} class="bg-red-50 p-4 lg:px-8">
        <div class="flex items-center">
          <.icon name="hero-exclamation-circle-solid" class="size-5  text-red-400" />
          <div class="ml-3 flex-1 md:flex md:justify-between">
            <p class="text-sm text-red-700">Your email address {@current_user.email} has not been verified.</p>
            <p class="mt-3 text-sm md:mt-0 md:ml-6">
              <.link phx-click="resend_email" phx-target={@myself} class="font-medium whitespace-nowrap text-red-700 hover:text-red-600">
                Resend
              </.link>
            </p>
          </div>
        </div>
      </div>
      <div :if={@email_alread_send} class="bg-green-50 p-4  lg:px-8">
        <div class="flex items-center">
          <.icon name="hero-exclamation-circle-solid" class="size-5  text-green-400" />
          <div class="ml-3 flex-1 md:flex md:justify-between">
            <p class="text-sm text-green-700">Your confirmation email has been sent to {@current_user.email}.</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
