defmodule MolyWeb.AdminPostLive.FormField.Thumbnail do
  use MolyWeb.Admin, :live_component

  import Moly.Utilities.Post, only: [attachment_metadata_image: 3]

  @impl true
  def update(%{current_user: current_user, form: form}, socket) do
    cur_feature_image =
      if form.data do
        form.data.post_meta
        |> Enum.find(&(&1.meta_key == "thumbnail_id"))
        |> case do
          nil ->
            nil

          %{meta_value: media_id} ->
            Moly.Contents.PostMeta
            |> Ash.Query.filter(post_id == ^media_id and meta_key == "attachment_metadata")
            |> Ash.read!(actor: current_user)
            |> List.first()
        end
      else
        nil
      end

    socket =
      socket
      |> assign(:modal_id, generate_random_id())
      |> assign(:current_user, current_user)
      |> assign(:form, form)
      |> assign(:cur_feature_image, cur_feature_image)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div id="container" data-id="container">
        <div
          class={["relative aspect-[10/7]", !@cur_feature_image && "hidden"]}
          data-id="image-container"
        >
          <img
            id="post-feature-image"
            data-id="image"
            src={
              @cur_feature_image &&
                attachment_metadata_image(
                  %Moly.Contents.Post{id: @cur_feature_image.id, post_meta: [@cur_feature_image]},
                  ["medium", "thumbnail"],
                  true
                )
            }
            alt="Featured image"
            class="w-full h-full object-cover rounded-md"
            phx-update="ignore"
          />
          <.button
            class="absolute top-2 right-2 !p-1 !size-6 bg-white !rounded-full shadow-md hover:bg-gray-100"
            variant="gray"
            data-id="remove-image-button"
          >
            <Lucideicons.x class="w-4 h-4 text-gray-500" />
          </.button>
        </div>

        <input
          id={generate_random_id()}
          data-id="meta-key-input"
          name={"#{@form[:post_meta].name}[0][meta_key]"}
          value={:thumbnail_id}
          type="hidden"
          disabled={!@cur_feature_image}
        />
        <input
          id={generate_random_id()}
          data-id="meta-value-input"
          name={"#{@form[:post_meta].name}[0][meta_value]"}
          value={(@cur_feature_image && @cur_feature_image.post_id) || nil}
          type="hidden"
          disabled={!@cur_feature_image}
        />

        <.button
          data-id="set-image-button"
          variant="secondary"
          class={"w-full my-4 #{@cur_feature_image && "hidden"}"}
          phx-click={
            JS.set_attribute({"src", ~p"/admin/media?media_type=image&modal=true"},
              to: "[data-id='iframe']"
            )
            |> show_modal(@modal_id)
          }
        >
          Set featured image
        </.button>
      </div>

      <.modal
        id={@modal_id}
        data-id="modal"
        inner_class="sm:!max-w-[90vw] sm:!max-h-[90vh] overflow-hidden !p-0 !m-0 h-[90vh] h-[90vh]"
      >
        <div class="flex flex-col h-full">
          <div class="flex justify-start px-4 py-2.5 gap-2 border-b border-gray-200 mb-1">
            <.button
              variant="outline"
              class="!text-gray-500"
              phx-click={JS.dispatch("app:historyback", to: "[data-id='iframe']")}
            >
              <Lucideicons.arrow_left class="w-4 h-4" />&nbsp;Back
            </.button>
          </div>

          <div class="px-4 lg:px-6 flex-1 overflow-y-scroll">
            <iframe
              id={generate_random_id()}
              class="w-full h-full"
              phx-hook="SetFeatureImage"
              data-id="iframe"
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
