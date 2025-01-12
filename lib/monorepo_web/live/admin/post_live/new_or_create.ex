defmodule MonorepoWeb.AdminPostLive.NewOrEdit do
  use MonorepoWeb.Admin, :live_view

  @impl true
  def mount(_params, _session, socket) do
    temporary_assigns = [
      post_slug: generate_random_str(),
      create_category_modal_id: generate_random_id(),
    ]
    {:ok, resource_to_form(socket), layout: false, temporary_assigns: temporary_assigns}
  end

  @impl true
  def handle_params(_, uri, socket) do
    %{scheme: scheme, authority: authority} = URI.parse(uri)
    {:noreply, assign(socket, host: "#{scheme}://#{authority}/p/")}
  end


  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    socket =
      case AshPhoenix.Form.submit(socket.assigns.form, params: params, action_opts: [actor: socket.assigns.current_user]) do
        {:ok, post} ->
          socket
          |> put_flash(:info, "Saved post for #{post.post_title}!")
          |> push_patch(to: ~p"/admin/posts")
        {:error, form} ->
          socket
          |> assign(form: form)
      end

    {:noreply, socket}
  end

  defp resource_to_form(socket) do
    form =
      AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
        forms: [
          auto?: true
        ],
        actor: socket.assigns.current_user
      ])
      |> to_form()
    socket
    |> assign(:form, form)
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

  def accordion(icon_el, target_el) do
    JS.toggle_class("block hidden", to: target_el, transition: "easy-in-out duration-50", time: 50)
    |> JS.toggle_class("border-b", transition: "easy-in-out duration-50", time: 50)
    |> JS.toggle_class("rotate-180 text-gray-500 text-gray-400", transition: "easy-in-out duration-50", time: 50, to: icon_el)
  end
end
