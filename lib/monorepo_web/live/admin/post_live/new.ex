defmodule MonorepoWeb.PostLive.New do
  use MonorepoWeb, :live_view

  @model Monorepo.Contents.Post

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %{role: :admin, status: :active}}} = socket) do
    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: ~p"/sign-in")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>New Post</h1>
    </div>
    """
  end
end
