defmodule MonorepoWeb.Affiliate.PageIndexAlert do
  use MonorepoWeb, :live_component

  alias Monorepo.Accounts.Helper


  def handle_event("resend_email", _, socket) do
    IO.inspect(socket.assigns.current_user)
    case already_send?(socket.assigns.current_user) do
      nil ->
        # Monorepo.Accounts.User.Senders.SendNewUserConfirmationEmail()
        nil
      _ ->
        nil
    end

    {:noreply, socket}
  end

  defp already_send?(nil), do: nil
  defp already_send?(%Monorepo.Accounts.User{id: user_id}), do: Cachex.get!(:cache, "resend-email-#{user_id}")

  def render(assigns) do
    ~H"""
    <div>
      <div :if={Helper.is_active_user(@current_user) == false && !already_send?(@current_user)} class="bg-red-50 p-4 lg:px-8">
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
      <div :if={!Helper.is_active_user(@current_user) == false && already_send?(@current_user)} class="bg-green-50 p-4  lg:px-8">
        <div class="flex items-center">
          <.icon name="hero-exclamation-circle-solid" class="size-5  text-green-400" />
          <div class="ml-3 flex-1 md:flex md:justify-between">
            <p class="text-sm text-green-700">Your confirmation email has been sent to {@current_user.email} has not been verified.</p>
            <p class="mt-3 text-sm md:mt-0 md:ml-6">
              <.link navigate={Helper.get_mail_domain(@current_user.email)} phx-target={@myself} class="font-medium whitespace-nowrap text-green-700 hover:text-green-600">
                View
              </.link>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
