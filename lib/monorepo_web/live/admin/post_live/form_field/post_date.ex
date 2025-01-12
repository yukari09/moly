defmodule MonorepoWeb.AdminPostLive.FormField.PostDate do
  use MonorepoWeb.Admin, :live_component

  def render(assigns) do
    ~H"""
    <div id="post-date" class="flex items-center" phx-update="ignore">
      <span class="font-medium w-32">Publish</span>
      <label class="text-gray-600 hover:underline cursor-pointer flex items-center gap-1" for={@form[:post_date].id}>
        <span data-id="post-date-immediately" class="flex items-center">Immediately&nbsp;<Lucideicons.calendar class="w-4 h-4 text-gray-500" /></span>
        <span data-id="post-date-schedule"></span>
      </label>
      <.input
        field={@form[:post_date]}
        label={nil}
        class="!w-0 !h-0 !border-0 !m-0 !!ring-0 !p-0"
        phx-hook="PostDatetimePicker"
        data-id="post-date-input"
      />
    </div>
    """
  end
end
