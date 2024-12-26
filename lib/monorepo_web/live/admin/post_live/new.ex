defmodule MonorepoWeb.AdminPostLive.New do
  use MonorepoWeb, :live_view

  import MonorepoWeb.TailwindUI

  def mount(params, session, socket) do
    {:ok, socket, layout: false}
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
