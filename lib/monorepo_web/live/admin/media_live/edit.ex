defmodule MonorepoWeb.AdminMediaLive.Edit do
  use MonorepoWeb.Admin, :live_view

  import Monorepo.Contents.Helpers

  def mount(%{"id" =>id}, _session, socket) do
    media =
      Ash.get!(Monorepo.Contents.Post, id, actor: socket.assigns.current_user)
      |> Ash.load!([:post_meta])

    socket =
      socket
      |> assign(:media, media)
      |> assign(:form, for_update_form(media))

    {:ok, socket, layout: {MonorepoWeb.Layouts, :admin_modal}}
  end


  def update(%{id: id, current_user: current_user}, socket) do
    media =
      Ash.get!(Monorepo.Contents.Post, id, actor: current_user)
      |> Ash.load!([:post_meta])

    socket =
      socket
      |> assign(:media, media)
      |> assign(:form, for_update_form(media))
      |> assign(:current_user, current_user)

    {:ok, socket}
  end

  def handle_event("partial_update", %{"form" => params}, socket) do
    old_form = socket.assigns.form
    updated_media = AshPhoenix.Form.submit(old_form, params: params, action_opts: [actor: socket.assigns.current_user])

    socket =
      case updated_media do
        {:ok, media} ->
          media = Ash.load!(media, [:post_meta])

          socket
          |> assign(:media, media)
          |> assign(:form, for_update_form(media))

        {:error, form} ->
          socket
          |> assign(form: form)
      end
    {:noreply, socket}
  end


  def for_update_form(media) do
    AshPhoenix.Form.for_update(media, :update_media, forms: [
      post_meta: [
        type: :list,
        data: media.post_meta,
        resource: Monorepo.Contents.PostMeta,
        update_action: :update,
        create_action: :create
      ]
    ])
    |> to_form()
  end
end
