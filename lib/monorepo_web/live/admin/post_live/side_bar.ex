defmodule MonorepoWeb.AdminPostLive.SideBar do
  use MonorepoWeb.Admin, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
        id={@id}
        class="pointer-events-auto w-screen max-w-sm z-20 bg-white absolute right-0 xl:static xl:block border-l border-gray-200 h-[calc(100vh-4rem)] overflow-y-scroll overflow-x-visible"
        aria-expanded="true"
    >
      <div class="h-full overflow-y-scroll bg-white flex flex-col px-2 sm:px-4 space-y-4">
        <div class="flex items-start justify-between border-b pb-4 pt-6 sticky top-0 bg-white z-20">
          <h2 class="text-base font-semibold text-gray-900" id="slide-over-title">Post settings</h2>
        </div>
        <div class="space-y-5">
          <.live_component id="feature-image" module={MonorepoWeb.AdminPostLive.FormField.Thumbnail} form={@form} current_user={@current_user} />

          <div :if={@form.data} class="text-gray-600 text-sm mx-2">Last edited {Timex.Format.DateTime.Formatters.Relative.format!(@form.data.updated_at, "{relative}")}.</div>
          <ul class="space-y-4 mx-2 text-sm">
            <li id="post-status" class="flex items-center">
                <span class="font-medium w-32">Status</span>
                <span class="text-gray-600 capitalize">{@form[:post_status].value}</span>
                <.input data-id="post-status-input" field={@form[:post_status]} label={nil} class="hidden" />
            </li>
            <li>
              <.live_component id="form-field-post-date" module={MonorepoWeb.AdminPostLive.FormField.PostDate} form={@form} />
            </li>
            <li>
              <.live_component id="form-field-post-name" module={MonorepoWeb.AdminPostLive.FormField.PostName} form={@form} post_slug={@post_slug} host={@host} />
            </li>
            <li class="flex items-center">
              <span class="font-medium w-32">Discussion</span>
              <.toggle_switch id="comments_open_toggle"  label={nil} enabled={true} on_change={JS.toggle_attribute({"value", "1", "0"}, to: "[data-id='meta-value-comments-open']")} />
              <input data-id="meta-key-comments-open" name={"#{@form[:post_meta].name}[1][meta_key]"} value={:comments_open} type="hidden"/>
              <input data-id="meta-value-comments-open" name={"#{@form[:post_meta].name}[1][meta_value]"} value="1" type="hidden"/>
            </li>
            <li class="flex items-center">
              <span class="font-medium w-32">Author</span>
              <span class="text-gray-600">{Monorepo.Accounts.Helper.current_user_name(@current_user)}</span>
            </li>
          </ul>
        </div>
        <ul role="list" class="space-y-2">
          <li>
            <div>
                <button
                  type="button"
                  class="hover:bg-gray-50 border flex items-center justify-between w-full text-left rounded-md p-2 gap-x-3 text-sm/6 font-semibold text-gray-700 rounded-bl-none rounded-br-none" aria-controls="sub-menu-1"  aria-expanded="false"
                  phx-click={accordion("#sub-menu-1-icon", "#sub-menu-1")}
                >
                  Excerpt
                  <Lucideicons.chevron_up id="sub-menu-1-icon" class="w-4 h-4" />
                </button>
                <div class="bg-gray-50 p-2 border  border-t-0 rounded-br-md rounded-bl-md" id="sub-menu-1">
                  <.textarea field={@form[:post_excerpt]} placeholder="Add an excerpt" label={nil} rows="5"></.textarea>
                </div>
              </div>
            </li>
          <li>
            <.live_component id="form-field-post-categories" module={MonorepoWeb.AdminPostLive.FormField.PostCategories} current_user={@current_user} form={@form} />
          </li>
          <li>
            <div>
                <button
                  type="button"
                  class="hover:bg-gray-50 border flex items-center justify-between w-full text-left rounded-md p-2 gap-x-3 text-sm/6 font-semibold text-gray-700 rounded-bl-none rounded-br-none"
                  aria-controls="sub-menu-3"
                  aria-expanded="false"
                  phx-click={accordion("#sub-menu-3-icon", "#sub-menu-3")}
                >
                  Tags
                  <Lucideicons.chevron_up class="w-4 h-4" id="sub-menu-3-icon" />
                </button>
                <div  class="space-y-1  border px-4 py-2.5 rounded-sm border-t-0 rounded-br-md rounded-bl-md" id="sub-menu-3">
                  <div id="tagify-input-container" class="mt-2" phx-update="ignore">
                    <input class="w-full rounded-md" type="text" id="tagify-input" phx-hook="TagsTagify" data-target-name={"#{@form[:tags].name}"}  data-target-container="#tagify-input-target" value={@form.data && Enum.map_join(@form.data.post_tags,",", & &1.name) || []} />
                  </div>
                  <div class="mb-12 text-xs text-gray-500 py-2" id="tagify-input-target" phx-update="ignore">
                    <input :for={{tag, i} <- Enum.with_index(@form.data && @form.data.post_tags || [])} name={"#{@form[:tags].name}[#{i}][name]"} value={tag.name}  type="hidden"/>
                    <input :for={{tag, i} <- Enum.with_index(@form.data && @form.data.post_tags || [])} name={"#{@form[:tags].name}[#{i}][term_taxonomy][][taxonomy]"}  value={hd(tag.term_taxonomy) |> Map.get(:id)} type="hidden"/>
                    Separate with commas or the Enter key.
                  </div>
                </div>
              </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end


  def accordion(icon_el, target_el) do
    JS.toggle_class("block hidden", to: target_el, transition: "easy-in-out duration-50", time: 50)
    |> JS.toggle_class("border-b rounded-bl-none rounded-br-none", transition: "easy-in-out duration-50", time: 50)
    |> JS.toggle_class("rotate-180 text-gray-500 text-gray-400", transition: "easy-in-out duration-50", time: 50, to: icon_el)
  end
end
