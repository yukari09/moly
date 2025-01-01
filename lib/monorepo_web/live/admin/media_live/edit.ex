defmodule MonorepoWeb.AdminMediaLive.Edit do
  use MonorepoWeb.Admin

  require Logger

  def mount(%{"id" =>id}, _session, socket) do
    media =
      Ash.get!(Monorepo.Contents.Post, id, actor: socket.assigns.current_user)
      |> Ash.load!([:post_meta])

    form =
      AshPhoenix.Form.for_update(media, :update_media, actor: socket.assigns.current_user)

    socket =
      socket
      |> assign(:media, media)
      |> assign(:form, form)

    {:ok, socket, layout: false}
  end


end
