defmodule MonorepoWeb.AdminPostLive.FormField.PostName do
  use MonorepoWeb.Admin, :live_component

  def render(assigns) do
    slug_dropdown_id = generate_random_id()

    assigns = assign(assigns, slug_dropdown_id: slug_dropdown_id)

    ~H"""
    <div class="flex items-center" id="post-name-container"  phx-hook="InputValueUpdater" phx-update="ignore">
      <span class="font-medium w-32">Slug</span>
      <.dropdown id={@slug_dropdown_id} data-id={@slug_dropdown_id} class="flex-1">
        <:button_slot class="text-gray-600 !p-0 !m-0">
          <span data-id="post-slug-label" class="hover:underline">{@form[:post_name].value || @post_slug}</span>
        </:button_slot>
        <:menu_slot class="p-3 w-80" data-id="post-slug-menu">
          <div class="pb-2">
            <span class="font-semibold text-sm">Slug</span>
          </div>
          <div class="space-y-4 py-2">
            <div>
              <.input
                field={@form[:post_name_2]}
                value={@form[:post_name_2].value || @post_slug}
                label="Unique slug"
                autocomplete="off"
                data-host={@host}
                type="text"
                data-id="post-slug-input"
                placeholder="slug min 8 characters"
                data-default={@form[:post_name].value || @post_slug}
              />
            </div>
            <div>
              <span class="font-medium text-sm/6">
                Permanent link: <span  class="font-normal" data-id="post-slug-text">{"#{@host}#{@form[:post_name].value || @post_slug}"}</span>
              </span>
            </div>
          </div>
        </:menu_slot>
      </.dropdown>
      <input data-id="post-post-name-oi" name={@form[:post_name].name} value={@form[:post_name].value || @post_slug} type="hidden" class="hidden" />
      <.input data-id="post-slug-guid" field={@form[:guid]} value={@form[:post_name].value || "#{@host}#{@post_slug}"} label={nil} class="hidden" />
    </div>
    """
  end
end
