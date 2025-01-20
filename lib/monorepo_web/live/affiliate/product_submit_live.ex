defmodule MonorepoWeb.Affiliate.ProductSubmitLive do
  use MonorepoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="relative min-h-[180px] bg-secondary">
      <button class="bg-base-100 size-8 rounded-md absolute top-2 right-2"><.icon name="hero-pencil-solid" class="size-4 text-gray-400" /></button>
    </div>
    <div class="px-4 -mt-12">
        <div class="avatar" role="button">
          <div class="size-24 rounded-full" :if={@current_user.avatar}>
            <img src={@current_user.avatar["128"]} />
          </div>
        </div>
        <div class="avatar placeholder" :if={!@current_user.avatar}>
          <div class="bg-primary text-base-100 size-24 rounded-full">
              <span class="capitalize text-5xl">{Monorepo.Accounts.Helper.current_user_name(@current_user) |> String.slice(0, 1)}</span>
          </div>
        </div>
      </div>
      <.form>
      <div class="flex items-start gap-8">
        <div class="w-64 p-4">
          <div class="space-y-2">
            <div class="text-2xl px-4 text-gray-900">
              <p><%= @current_user.name %></p>
              <p class="text-sm mt-1">@{@current_user.username}</p>
            </div>
            <div><input type="text" placeholder="Add a description" class="input input-sm w-full max-w-xs" /></div>
            <div><input type="text" placeholder="Add a location" class="input input-sm w-full max-w-xs" /></div>
            <div><input type="text" placeholder="Add a website URL" class="input input-sm w-full max-w-xs" /></div>
            <div><input type="text" placeholder="Add a X(twiiter)" class="input input-sm w-full max-w-xs" /></div>
            <div><input type="text" placeholder="Add a Instagram" class="input input-sm w-full max-w-xs" /></div>
          </div>
        </div>
        <div role="tablist" class="tabs tabs-bordered">
          <a role="tab" class="tab">Tab 1</a>
          <a role="tab" class="tab tab-active">Tab 2</a>
          <a role="tab" class="tab">Tab 3</a>
        </div>
      </div>
    </.form>
    """
  end
end
