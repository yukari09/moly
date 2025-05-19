defmodule MolyWeb.AdminPostLive.EditorMedia do
  use MolyWeb.Admin, :live_component

  def mount(socket) do
    socket =
      assign(socket,
        modal_id: Moly.Helper.generate_random_id()
      )
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="editor-media-container" data-id="editor-media-container">
      <.modal
        id={@modal_id}
        data-id="modal"
        inner_class="sm:!max-w-[90vw] sm:!max-h-[90vh] overflow-hidden !p-0 !m-0 h-[90vh] h-[90vh]"
        data-show-modal={
            JS.set_attribute({"src", ~p"/admin/media?media_type=image&modal=true"},
              to: "[data-id='media-iframe']"
            )
            |> show_modal(@modal_id)
        }
        data-hide-modal={
          JS.set_attribute({"src", ""},
            to: "[data-id='media-iframe']"
          )
          |> hide_modal(@modal_id)
        }
      >
        <div class="flex flex-col h-full">
          <div class="flex justify-start px-4 py-2.5 gap-2 border-b border-gray-200 mb-1">
            <.button
              variant="outline"
              class="!text-gray-500"
              phx-click={JS.dispatch("app:historyback", to: "[data-id='media-iframe']")}
            >
              <Lucideicons.arrow_left class="w-4 h-4" />&nbsp;Back
            </.button>
          </div>

          <div class="px-4 lg:px-6 flex-1 overflow-y-scroll">
            <iframe
              id={generate_random_id()}
              class="w-full h-full"
              data-id="media-iframe"
            >
            </iframe>
          </div>

          <div class="flex justify-end px-4 pt-2.5 pb-4 gap-2 border-t border-gray-200 mt-1">
            <.button data-id="cancel-button" variant="gray" class="w-20">
              Cancel
            </.button>
            <.button data-id="confirm-button" variant="primary" class={"w-20"} disabled={true}>
              Insert
            </.button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end
