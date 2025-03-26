defmodule MolyWeb.Affinew.VerifyEmailLive do
  use MolyWeb, :live_view

  def mount(_params, session, socket) do
    IO.inspect(session)
    {:ok, socket, layout: false}
  end

  def handle_event("resend", _, socket) do
    socket = case send(socket.assigns.current_user) do
       :ok ->
          put_flash(socket, :info, "Your verification email has been sent to #{socket.assigns.current_user.email}.")
        :error->
          put_flash(socket, :error, "There was an error sending the email. Please try again later.")
    end
    {:noreply, socket}
  end

  def handle_event("go-back", _, socket) do
    socket = push_navigate(socket, to: ~p"/")
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-[100vh] bg-white">
      <MolyWeb.Affinew.Components.flash_group flash={@flash} id="app-flash" class="mt-8"/>
      <div class="flex flex-col  gap-x-12 items-center h-full">
          <div :if={!@current_user.confirmed_at || @current_user.status != :active} class="px-4 sm:px-8 xl:px-0 mt-8">
            <div class="max-w-sm order-2"><img src="/images/3459557.svg" /></div>
            <div class="max-w-md  order-1">
              <div class="text-2xl md:text-3xl font-medium text-center">Verify your email</div>
              <div class=" mt-4">Please go to your registered email address to verify whether your email address can be used.</div>
              <div class="mt-8 mb-8 lg:mb-0 text-center flex items-center justify-center gap-2 mx-atuo">
                <.link phx-click={JS.patch("app:historyback")} class="btn btn-neutral">Go Back</.link>
                <.link phx-click="resend" class="btn">Resend</.link>
              </div>
            </div>
          </div>
      </div>
      <div class="flex flex-col  gap-x-12 items-center h-full">
          <div :if={@current_user.confirmed_at && @current_user.status == :active} class="px-4 sm:px-8 xl:px-0 mt-8">
            <div class="max-w-sm order-2"><img src="/images/3459557.svg" /></div>
            <div class="max-w-md  order-1">
              <div class="text-2xl md:text-3xl font-medium text-center">Your email has been verified</div>
              <div class=" mt-4 ">Your email <span class="font-semibold">{@current_user.email}</span> has been successfully verified. Your account is now fully activated.</div>
              <div class="mt-8 mb-8 lg:mb-0 text-center flex items-center justify-center gap-2 mx-atuo">
                <.link phx-click="go-back" class="btn btn-neutral w-full md:btn-wide">Go Back</.link>
              </div>
            </div>
          </div>
      </div>
    </div>
    """
  end

  defp send(%Moly.Accounts.User{id: _user_id} = user) do
    Ash.update(user, %{updated_at: DateTime.utc_now()},
      action: :resend_confirmation,
      context: %{private: %{ash_authentication?: true}}
    )
    |> case do
      {:ok, _user} ->
        :ok
      _ ->
        :error
    end
  end
end
