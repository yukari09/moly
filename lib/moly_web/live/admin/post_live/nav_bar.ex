defmodule MolyWeb.AdminPostLive.NavBar do
  use MolyWeb.Admin, :live_component

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 sm:gap-x-6 sm:px-6 lg:px-8"
    >
      <.link patch={~p"/admin/posts"} class="flex flex-shrink-0 items-center">
        <img class="h-8 w-auto" src="/images/logo.svg" alt="Your Company" />
      </.link>

    <!-- Separator -->
      <div class="h-6 w-px bg-gray-200 lg:hidden" aria-hidden="true"></div>

      <div class="flex items-center">
        <.link class="editor-action-btn" data-id="undo-button" phx-click={JS.dispatch("undo")}>
          <Lucideicons.undo_2 class="size-5" />
        </.link>
        <.link class="editor-action-btn" data-id="redo-button" phx-click={JS.dispatch("redo")}>
          <Lucideicons.redo_2 class="size-5" />
        </.link>
      </div>

      <div class="flex flex-1 gap-x-4 self-stretch items-center lg:gap-x-6">
        <.link
          class={["text-sm ml-auto pointer-events-none opacity-50"]}
          data-id="save-draft"
          phx-click={
            JS.set_attribute({"value", "draft"}, to: "[data-id='post-status-input']")
            |> JS.set_attribute({"type", "submit"}, to: "[data-id='post-submit-btn']")
            |> JS.dispatch("app:click-el", to: "[data-id='post-submit-btn']")
            |> JS.set_attribute({"type", "button"}, to: "[data-id='post-submit-btn']")
          }
        >
          Save draft
        </.link>
        <.link
          class={["text-sm flex items-center gap-x-1 pointer-events-none opacity-50"]}
          data-confirm="Are you sure you want to clear the editor?"
          data-id="clear-editor"
          phx-click={JS.dispatch("clear_editor")}
        >
          <Lucideicons.eraser class="w-4 h-4" /> Clear editor
        </.link>
        <div class="flex items-center gap-x-4 lg:gap-x-6">
          <.button
            size="sm"
            class={["pointer-events-none opacity-50"]}
            data-id="publish-button"
            phx-click={
              JS.set_attribute({"value", "publish"}, to: "[data-id='post-status-input']")
              |> JS.set_attribute({"type", "submit"}, to: "[data-id='post-submit-btn']")
              |> JS.dispatch("app:click-el", to: "[data-id='post-submit-btn']")
              |> JS.set_attribute({"type", "button"}, to: "[data-id='post-submit-btn']")
            }
          >
            Publish
          </.button>
        </div>
        <.link class="text-sm text-primary text-gray-500" phx-click={toggle_sidebar("#side-bar")}>
          <Lucideicons.panel_right class="w-4 h-4" />
        </.link>
      </div>
    </div>
    """
  end

  def is_valid?(form) do
    form.source.valid? && form.erros == []
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
