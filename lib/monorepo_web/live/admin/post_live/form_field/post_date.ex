defmodule MonorepoWeb.AdminPostLive.FormField.PostDate do
  use MonorepoWeb.Admin, :live_component

  def render(assigns) do
    ~H"""
    <div id="post-date" class="flex items-center" phx-update="ignore">
      <span class="font-medium w-32">Publish</span>
      <label class="text-gray-600 hover:underline cursor-pointer flex items-center gap-1" for="post-date-input-picker">
        <span data-id="post-date-immediately" class={[!@form[:post_date].value && "flex items-center" || "hidden"]}>Immediately&nbsp;<Lucideicons.calendar class="w-4 h-4 text-gray-500" /></span>
        <span data-id="post-date-schedule" class={[!@form[:post_date].value && "hidden"]}>{@form[:post_date].value}</span>
      </label>
      <.input
        field={@form[:post_date]}
        label={nil}
        class="!w-0 !h-0 !border-0 !m-0 !!ring-0 !p-0 hidden"
        data-id="post-date-input"
        type="hidden"
      />
      <input
        id="post-date-input-picker"
        type="hidden"
        data-id="post-date-input-picker"
        phx-hook="PostDatetimePicker"
        class="text-gray-500 !w-0 !h-0 !border-0 !m-0 !!ring-0 !p-0"
        value={@form[:post_date].value}
      />
    </div>
    """
  end
end
