defmodule MonorepoWeb.AdminPostLive.Edit do
  use MonorepoWeb.Admin, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do

    post =
      Ash.get!(Monorepo.Contents.Post, id, actor: socket.assigns.current_user)
      |> Ash.load!([:post_meta])

    form = resource_to_form(post)

    socket
    |> assign(form: form)
    |> assign(post: post)

    {:ok,
      socket,
      layout: {MonorepoWeb.Layouts, :admin_modal},
      temporary_assigns: [selected_media_id: nil]
    }
  end

  @impl true
  def handle_info({:broadcast_selected, id}, socket) do
    socket =
      socket
      |> assign(:selected_media_id, id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_selected_media", _, socket) do
    {:noreply, socket |> assign(:selected_media_id, nil)}
  end

  defp toggle_sidebar(toggle_el) do
    hide_el = "#{toggle_el}[aria-expanded='false']"
    show_el = "#{toggle_el}[aria-expanded='true']"

    JS.hide(
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "translate-x-full"},
      to: show_el,
      time: 300
    )
    |> JS.show(
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-full", "translate-x-0"},
      to: hide_el,
      time: 300
    )
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: toggle_el)
  end


  defp resource_to_form(post_or_changeset) do
    AshPhoenix.Form.for_update(post_or_changeset, :update_post,     forms: [
      post_meta: [
        type: :list,
        data: post_or_changeset.post_meta,
        resource: Monorepo.Contents.PostMeta,
        update_action: :update,
        create_action: :create
      ]
    ])
    |> to_form()
  end
end
