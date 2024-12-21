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
  def handle_params(params, _uri, socket) do
    socket =
      edit_or_new(socket, params)

    {:noreply, socket}
  end

  defp edit_or_new(socket, %{"id" => id}) do
    resource =
      Monorepo.Contents.Post
      |> Ash.get!(id, actor: %{roles: [socket.assigns.current_user.role]})

    form =
      AshPhoenix.Form.for_update(resource, :update, forms: [auto?: true])
      |> to_form()

    socket
    |> assign(form: form)
  end

  defp edit_or_new(socket, _params) do
    form =
      Monorepo.Contents.Post
      |> AshPhoenix.Form.for_create(:create, forms: [auto?: true])
      |> to_form()

    socket
    |> assign(form: form)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-semibold">Create new post</h1>
    </div>
    <div class="lg:grid lg:grid-cols-3 gap-4 my-4">
      <div class="col-span-2">
        <.form :let={f} for={@form} class="w-full space-y-6">
          <.form_item>
            <.input
              id={f[:title].id}
              field={f[:title]}
              type="text"
              class="w-full"
              placeholder="Title"
              phx-debounce="500"
              value={f[:title].value}
            />
            <.form_message field={f[:title]} class="text-xs" />
          </.form_item>

          <.form_item>
            <.textarea
              id={f[:subject].id}
              name={f[:subject].name}
              phx-hook="Editor"
              type="text"
              class="w-full"
              placeholder="Title"
              phx-debounce="500"
              value={f[:subject].value}
            ></.textarea>
            <.form_message field={f[:subject]} class="text-xs" />
          </.form_item>
        </.form>
      </div>

      <div class="col-span-1 space-y-4">
      <.card class="w-[350px]">
        <.card_header>
          <.card_title>Create your project</.card_title>
          <.card_description>Deploy your new project in one-click.</.card_description>
        </.card_header>
        <.card_content>
          <form>
            <div class="grid w-full items-center gap-4">
              <div class="flex flex-col space-y-1.5">
                <.label html-for="name">Name</.label>
                <.input id="name" placeholder="Name of your project" />
              </div>
            </div>
          </form>
        </.card_content>
        <.card_footer class="flex justify-between">
          <.button variant="outline">Cancel</.button>
          <.button>Deploy</.button>
        </.card_footer>
      </.card>
      </div>
    </div>
    """
  end
end
