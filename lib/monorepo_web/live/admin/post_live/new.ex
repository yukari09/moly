defmodule MonorepoWeb.AdminPostLive.New do
  use MonorepoWeb.Admin, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket,
      layout: {MonorepoWeb.Layouts, :admin_modal}
    }
  end

  @impl true
  def handle_event(event_name, params, socket) do
    socket =
      socket
      |> assign(:live_action, String.to_atom(event_name))
      |> handle_action(params)

    {:noreply, socket}
  end

  defp handle_action(%{assigns: %{live_action: :set_featured_image}}  = socket, _params) do
    socket
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
end
