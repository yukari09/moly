defmodule MolyWeb.Affinew.UnderConstructionLive do
  use MolyWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col  gap-x-12 items-center pt-10 h-full">
      <div class="md:flex px-4 sm:px-8 xl:px-0 items-center md:mt-36">
        <div class="max-w-sm order-2"><img src="/images/8447284.svg" /></div>
        <div class="max-w-md  order-1">
          <div class="text-2xl md:text-4xl font-medium">Under Construction</div>
          <p class="text-base-content/80 mt-4">
            We're currently working hard to bring you something amazing! Our team is building and refining this space to ensure the best experience for you. Stay tuned for updates, and thank you for your patience.
          </p>
          <div class="mt-8 mb-8 lg:mb-0">
            <.link
              phx-click={JS.dispatch("app:historyback")}
              class="btn btn-neutral w-full md:btn-wide"
            >
              Go back
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
