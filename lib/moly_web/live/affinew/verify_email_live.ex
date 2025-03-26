defmodule MolyWeb.Affinew.VerifyEmailLive do
  use MolyWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-[100vh] bg-white">
      <div class="flex flex-col  gap-x-12 items-center h-full">
          <div class="px-4 sm:px-8 xl:px-0 mt-20 md:mt-18">
            <div class="max-w-sm order-2"><img src="/images/3459557.svg" /></div>
            <div class="max-w-md  order-1">
              <div class="text-2xl md:text-3xl font-medium text-center">Verify your email</div>
              <div class=" mt-4">Please go to your registered email address to verify whether your email address can be used.</div>
              <div class="mt-8 mb-8 lg:mb-0 text-center">
                <.link id="go-back-link" phx-click={JS.dispatch("app:historyback")} class="btn btn-neutral w-full md:btn-wide">Go Back</.link>
              </div>
            </div>
          </div>
      </div>
    </div>
    """
  end
end
